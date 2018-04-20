#!/usr/local/bin/python3
import json

import sys
from aliyunsdkcore.client import AcsClient
from aliyunsdkecs.request.v20140526 import DescribeInstancesRequest
from aliyunsdkecs.request.v20140526.AllocateEipAddressRequest import AllocateEipAddressRequest
from aliyunsdkecs.request.v20140526.AssociateEipAddressRequest import AssociateEipAddressRequest
from aliyunsdkecs.request.v20140526.DescribeEipAddressesRequest import DescribeEipAddressesRequest
from aliyunsdkecs.request.v20140526.ReleaseEipAddressRequest import ReleaseEipAddressRequest

import alibaba
from alibaba.credentionals import ACCESS_KEY, SECRET_KEY

try:
    from alibaba.local_credentionals import ACCESS_KEY, SECRET_KEY
except ImportError:
    pass

try:
    path_to_rkn_db = sys.argv[1]
    region = sys.argv[2]
except IndexError:
    print("Usage python main.py path/to/rkn_dump.xml alibaba-region-id")
    exit(1)

alibaba.RKN_DB_PATH = path_to_rkn_db

from alibaba import rkn

REGION_ID = region.strip()

client = AcsClient(
    ACCESS_KEY,
    SECRET_KEY,
    REGION_ID
)


def fetch_available_vms():
    instances = {}
    request = DescribeInstancesRequest.DescribeInstancesRequest()
    request.set_PageSize(50)
    response = client.do_action_with_exception(request)
    response = json.loads(response)

    for instance in response['Instances']['Instance']:
        if instance['Status'] == "Running":
            if instance['PublicIpAddress']['IpAddress']:
                print(
                    "Instance: {} has PublicIpAddress, we need Elastic IP, create instance without public ip OR with Elastic IP, skiping....".format(
                        instance['InstanceId']))
                continue
            instances[instance['InstanceId']] = instance

    return instances


def release_eip(allocation_id):
    request = ReleaseEipAddressRequest()
    request.set_AllocationId(allocation_id)
    response = client.do_action_with_exception(request)
    response = json.loads(response)

    return response


def allocate_new_eip():
    while True:
        request = AllocateEipAddressRequest()
        request.set_Bandwidth(200)
        request.set_InternetChargeType("PayByTraffic")
        response = client.do_action_with_exception(request)
        response = json.loads(response)

        print("Trying to allocate: {}".format(response['EipAddress']))

        if rkn.is_banned(response['EipAddress']):
            print("IP Address: {} banned, release...".format(response['EipAddress']))
            release_eip(response['AllocationId'])
        else:
            print("Trying to allocate: {} -- Done".format(response['EipAddress']))
            return response


def assign_eip_to_instance(allocation_id, instance_id):
    request = AssociateEipAddressRequest()
    request.set_AllocationId(allocation_id)
    request.set_InstanceId(instance_id)
    response = client.do_action_with_exception(request)
    response = json.loads(response)
    return response


def get_allocated_ips():
    request = DescribeEipAddressesRequest()
    request.set_PageSize(50)
    response = client.do_action_with_exception(request)
    response = json.loads(response)
    return response


if __name__ == '__main__':
    print("Fetching instances from {}".format(REGION_ID))
    instances = fetch_available_vms()
    print("Ok, found {} instances".format(len(instances)))
    for instance_id, instance in instances.items():
        if not instance['EipAddress']['IpAddress']:
            new_ip = allocate_new_eip()
            assign_eip_to_instance(new_ip['AllocationId'], instance_id)
        else:
            print("Checking instance: {} ip: {}".format(instance_id, instance['EipAddress']['IpAddress']))
            if rkn.is_banned(instance['EipAddress']['IpAddress']):
                print("Old IP is banned")
                new_ip = allocate_new_eip()
                print("Assing new IP: {}".format(new_ip['EipAddress']))
                assign_eip_to_instance(new_ip['AllocationId'], instance_id)
            else:
                print("IP: {} is still alive, continue...".format(instance['EipAddress']['IpAddress']))
    instances = fetch_available_vms()

    print("Final Actual Stat")
    servers_ips = map(lambda x: "root@{}".format(x['EipAddress']['IpAddress']), instances.values())
    print("\n".join(servers_ips))
