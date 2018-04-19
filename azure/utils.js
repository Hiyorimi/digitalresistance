import { execSync, exec } from 'child_process'
import config from './config'

const { resourceGroup } = config

export const execLog = cmd => {
  console.log(`+ ${cmd}`)
  return execSync(cmd, { encoding: 'utf8' })
}

export const execLogLive = cmd => {
  console.log(`+ ${cmd}`)
  return execSync(cmd, { encoding: 'utf8', stdio: 'inherit' })
}

export const execLogLiveAsync = cmd => {
  console.log(`+ ${cmd}`)
  return new Promise((resolve, reject) => {
    exec(cmd, { encoding: 'utf8', stdio: 'inherit' }, (err, stdout) => {
      if (err) {
        reject(err)
      } else {
        resolve(stdout)
      }
    })
  })
}

export const azureJson = command => JSON.parse(execLog(`${command} -o json`))

export const listAllIPs = () =>
  azureJson(`az vm list-ip-addresses -g ${resourceGroup}`).map(
    ({
      virtualMachine: {
        name,
        network: {
          publicIpAddresses: [ipAddress],
        },
      },
    }) => [name, ipAddress]
  )
