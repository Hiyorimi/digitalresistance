/* eslint-disable no-restricted-syntax,no-await-in-loop */
import B from 'bluebird'
import chalk from 'chalk'
import fetch from 'node-fetch'
import SSH from 'node-ssh'
import * as R from 'ramda'
import config from './config'
import { listAllIPs, execLogLive, azureJson } from './utils'

const { resourceGroup } = config
const getVMInfo = vm =>
  azureJson(`az vm show -g ${resourceGroup} -n ${vm}`)

const getNicInfo = nic =>
  azureJson(`az network nic show -g ${resourceGroup} -n ${nic}`)

const findNic = ({
  networkProfile: {
    networkInterfaces: [nic],
  },
}) => nic

const findNameFromId = id => id.split(/\//g).slice(-1)[0]

const getNextName = name =>
  name.replace(/(\d+)$/, n => parseInt(n, 10) + 1)

const changeIp = vmInfo => {
  console.log(`changing IP ${vmInfo.name}`)
  const currentNic = findNic(vmInfo)
  const currentNicName = findNameFromId(currentNic.id)
  const nicInfo = getNicInfo(currentNicName)
  const ipConfigId = nicInfo.ipConfigurations[0].id
  const publicIpId = nicInfo.ipConfigurations[0].publicIpAddress.id
  const publicIpName = findNameFromId(publicIpId)
  const ipName = getNextName(publicIpName)

  // Allocate new Static IP
  execLogLive(`azure network public-ip create \\
  --name ${ipName} \\
  --resource-group ${resourceGroup} \\
  --allocation-method Static \\
  --location ${vmInfo.location.toLowerCase()}
`)

  // Attach new IP to VM
  execLogLive(`az network nic ip-config update \\
  --nic-name ${currentNicName} \\
  --ids ${ipConfigId} \\
  --resource-group ${resourceGroup} \\
  --public-ip-address ${ipName}
`)

  // Remove old IP
  execLogLive(`az network public-ip delete \\
  --ids ${publicIpId} \\
  --resource-group ${resourceGroup}
`)

  // Restart machine
  execLogLive(`az vm restart \\
  --name ${vmInfo.name} \\
  --resource-group ${resourceGroup} \\
  --no-wait
`)
}

const checkIsBanned = R.pipeP(
  ip => fetch(`https://tgproxy.me/rkn/backend.php?ip=${ip}`),
  res => res.json(),
  R.propEq('blocked', true)
)

const getTelegramStats = R.pipeP(
  ip =>
    new SSH().connect({
      host: ip,
      username: 'nick',
      privateKey: process.env.SSH_KEY,
      passphrase: '111222',
    }),
  ssh =>
    ssh
      .exec(
        'curl -4 -s "https://statistic-instance.appspot.com/info?tag=$(curl -4 -s https://statistic-instance.appspot.com/tag)"'
      )
      .then(async res => {
        try {
          const clients = res.match(
            /Has\s(\d+)\sconnected clients/
          )[1]
          const externalStatus = res.match(
            /External issues: (.*) \(last check/
          )[1]
          const internalStatus = res.match(
            /Internal issues: (.*) \(last check/
          )[1]
          return {
            users: parseInt(clients, 10),
            externalStatus,
            internalStatus,
          }
        } catch (err) {
          return res
        } finally {
          await ssh.dispose()
        }
      })
)

const printTelegramStatus = R.ifElse(
  R.is(String),
  R.identity,
  ({ externalStatus, internalStatus }) =>
    [
      `external status: ${externalStatus}`,
      `internal status ${internalStatus}`,
    ].join('\n')
)

const main = async () => {
  while (true) {
    console.log('Fetching current VM public IP list')
    const vms = listAllIPs()
    let totalUsers = 0
    for (const [vm, { ipAddress }] of vms) {
      if (await checkIsBanned(ipAddress)) {
        console.log(
          `${chalk.bgRed.inverse('[Ban]')}
             ${vm} ${ipAddress}`
        )
        changeIp(getVMInfo(vm))
      } else {
        const status = await getTelegramStats(ipAddress)
        if (
          typeof status === 'string' ||
          status.externalStatus.indexOf('Active') === -1
        ) {
          console.log(`
${chalk.bgRed.inverse('[Degraded]')} ${vm} ${ipAddress}
${printTelegramStatus(status)}
`)
          console.log('Restarting VM')
          // Restart machine
          execLogLive(`az vm restart \\
  --name ${vm} \\
  --resource-group ${resourceGroup} \\
  --no-wait
`)
        } else {
          totalUsers += status.users

          console.log(
            `${chalk.bgGreen.inverse(
              '[OK]'
            )} ${vm} ${ipAddress} – ${chalk.bold(
              status.users
            )} users online`
          )
        }
      }
    }

    console.log(`Total users: ${totalUsers}`)
    console.log(`Waiting 1 hr from ${new Date()}`)

    await B.delay(60 * 60 * 1000)
  }
}

main().catch(err => {
  console.error(err)
  process.exit(1)
})
