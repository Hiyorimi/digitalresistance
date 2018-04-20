import ipaddress
from xml.dom import minidom

from alibaba import RKN_DB_PATH

reasons = False

print("Initializing RKN DB")

x = minidom.parse(RKN_DB_PATH)

ad = lambda q: ipaddress.ip_address(q.childNodes[0].data.strip()) if len(q.childNodes) > 0 else None
nd = lambda q: ipaddress.ip_network(q.childNodes[0].data.strip()) if len(q.childNodes) > 0 else None

ips = list(filter(None, map(ad, set(x.getElementsByTagName('ip')))))
iprs = list(filter(None, map(nd, set(x.getElementsByTagName('ipSubnet')))))

print("RKN DB is ready.")


def is_banned(ip):
    ia = ipaddress.ip_address(ip.strip())
    if ia in ips:
        if not reasons:
            print(ia)
        else:
            print("%s - direct ban" % (ia,))

    for r in iprs:
        if ia in r:
            if not reasons:
                print(ia)
            else:
                print("%s - net %s" % (ia, r))
