#!/usr/local/bin/python3
import ipaddress
import sys
from xml.dom import minidom


if len(sys.argv) > 1:
  ia = ipaddress.ip_address(sys.argv[1].strip())

  x = minidom.parse('rkn/dump.xml')

  ad = lambda q: ipaddress.ip_address(q.childNodes[0].data.strip()) if len(q.childNodes) > 0 else None
  nd = lambda q: ipaddress.ip_network(q.childNodes[0].data.strip()) if len(q.childNodes) > 0 else None

  ips = list(filter(None, map(ad, set(x.getElementsByTagName('ip')))))
  iprs = list(filter(None, map(nd, set(x.getElementsByTagName('ipSubnet')))))

  if ia in ips:
    print (1)
    exit()

  for r in iprs:
    if ia in r:
     print (1)
     exit()

  print (0)

else:
  print ("Please input ip or subnet")
