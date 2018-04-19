import * as R from 'ramda'
import { listAllIPs } from './utils'

const REGION_MAP = {
  westeu: 'West Europe',
  cancent: 'Canada Central',
  ukwest: 'UK West',
  korcnt: 'Korea Central',
  korsth: 'Korea South',
  caneast: 'Canada East',
  eastasia: 'East Asia',
  indcent: 'India Central',
  uscent: 'US Central',
  eastus2: 'US East 2',
}

const sortyLinear = vms =>
  vms
    .map(([_, x]) => x.ipAddress)
    .sort()
    .join('\n')

const groupByRegion = R.pipe(
  R.groupBy(([name]) => name.match(/vm-(\S+)-tg/)[1]),
  R.toPairs,
  R.map(([reg, rows]) => [reg, rows.map(([_, x]) => x.ipAddress).sort()]),
  R.map(
    ([reg, ips]) => `${REGION_MAP[reg] || reg} (${ips.length})\n${ips.join('\n')}`
  ),
  R.join('\n')
)

console.log(groupByRegion(listAllIPs()))
