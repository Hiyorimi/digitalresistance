#!/usr/bin/env node
import B from 'bluebird'
import path from 'path'
import chalk from 'chalk'
import config from './config'
import { listAllIPs, execLogLive, azureJson, execLogLiveAsync } from './utils'

const { resourceGroup } = config

const getVMInfo = vm => azureJson(`az vm show -g ${resourceGroup} -n ${vm}`)
const getNicInfo = nic =>
  azureJson(`az network nic show -g ${resourceGroup} -n ${nic}`)

const findNic = ({
  networkProfile: {
    networkInterfaces: [nic],
  },
}) => nic

const findNameFromId = id => id.split(/\//g).slice(-1)[0]

const getNextName = name => name.replace(/(\d+)$/, n => parseInt(n, 10) + 1)

const changeIp = vmInfo => {
  const currentNic = findNic(vmInfo)
  const currentNicName = findNameFromId(currentNic.id)
  const nicInfo = getNicInfo(currentNicName)
  const ipConfigId = nicInfo.ipConfigurations[0].id
  const publicIpId = nicInfo.ipConfigurations[0].publicIpAddress.id
  const publicIpName = findNameFromId(publicIpId)
  const ipName = getNextName(publicIpName)

  // Allocate new Static IP
  execLogLive(
    `
azure network public-ip create \\
  --name ${ipName} \\
  --resource-group ${resourceGroup} \\
  --allocation-method Static \\
  --location ${vmInfo.location.toLowerCase()}
`
  )

  // Attach new IP to VM
  execLogLive(`
  az network nic ip-config update \\
    --nic-name ${currentNicName} \\
    --ids ${ipConfigId} \\
    --resource-group ${resourceGroup} \\
    --public-ip-address ${ipName}
  `)

  // Remove old IP
  execLogLive(`
  az network public-ip delete \\
    --ids ${publicIpId} \\
    --resource-group ${resourceGroup}
  `)

  // Restart machine
  execLogLive(`
  az vm restart \\
    --name ${vmInfo.name} \\
    --resource-group ${resourceGroup} \\
    --no-wait
  `)
}

const checkIsBanned = ip =>
  execLogLiveAsync(`./is_banned.py ${ip}`).then(result => result.trim() === '1')

const downloadBanLists = () => execLogLive(path.join(__dirname, 'download-banlist.sh'))

const main = async () => {
  while (true) {
    console.log('Upading RKN lists')
    downloadBanLists()
    console.log('Fetching current VM public IP list')
    const vms = listAllIPs()

    for (const [vm, { ipAddress }] of vms) {
      console.log(`${vm} ${ipAddress}`)
      if (await checkIsBanned(ipAddress)) {
        console.log(chalk.bgRed.inverse(`VM ${vm} is banned, changing IP...`))
        changeIp(getVMInfo(vm))
      } else {
        console.log(chalk.bgGreen.inverse(`VM ${vm} is not banned`))
      }
    }

    console.log(`waiting 1hr from ${new Date()}`)
    await B.delay(60 * 60 * 1000)
  }
}

main().catch(err => {
  console.error(err)
  process.exit(1)
})
