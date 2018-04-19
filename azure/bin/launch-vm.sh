#!/bin/bash
set -xeuo pipefail


#######
## Prepare script
##
## 1) set pub_key_path - path to ssh public key
## 2) set rg - azure resource group name
## 3) setup region and region_short
## possible regions: westus,eastus,northeurope,westeurope,eastasia,southeastasia,northcentralus,southcentralus,centralus,eastus2,japaneast,japanwest,brazilsouth,australiaeast,australiasoutheast,centralindia,southindia,westindia,canadacentral,canadaeast,westcentralus,westus2,ukwest,uksouth,koreacentral,koreasouth,francecentral
#####


#######
## Usage
##
## ./launch-vm.sh <vm-index>
## Example: ./launch-vm.sh 1 - start vm with '1' name suffix
#####

# vm index
num=$1
rg=tg
region=eastus2
region_short=eastus2
pub_key_path=/Users/ndelitski/.ssh/id_rsa.pub
# region=westeurope
# region_short=westeu
nic_name="nic-${region_short}-tg-${num}"
ip_name="ip-${region_short}-tg-${num}"
vm_size=Standard_D16s_v3
image=Canonical:UbuntuServer:16.04-LTS:latest
vnet="vnet-${region_short}-tg"
nsg="nsg-${region_short}-tg"
subnet="subnet-${region_short}-tg-01"
vm="vm-${region_short}-tg-${num}"
vm_nic_list="${nic_name}-1"

function create_nic() {
  azure network public-ip create \
    --name ${ip_name}-$1 \
    --resource-group $rg \
    --allocation-method Dynamic \
    --location $region

  azure network nic create \
    --name $nic_name-$1 \
    --subnet-name $subnet \
    --subnet-vnet-name $vnet \
    --resource-group $rg \
    --enable-accelerated-networking \
    --location $region \
    --network-security-group-name $nsg \
    --public-ip-name ${ip_name}-$1
}

function create_network() {
  azure network vnet create \
    --name $vnet \
    --resource-group $rg \
    --location $region

  azure network nsg create \
    --name $nsg \
    --resource-group $rg \
    --location $region

  azure network nsg rule create \
   --name proxy \
   --nsg-name $nsg \
   --priority 110 \
   --resource-group $rg \
   --access Allow \
   --destination-port-ranges 53,80,443,5222\
   --direction Inbound \
   --protocol "*"

   azure network nsg rule create \
   --name allowSSH \
   --nsg-name $nsg \
   --priority 100 \
   --resource-group $rg \
   --access Allow \
   --destination-port-ranges 22 \
   --direction Inbound \
   --protocol "*"

  azure network vnet subnet create \
   --address-prefix 10.0.0.0/24 \
   --name $subnet \
   --resource-group $rg \
   --vnet-name $vnet
}

function create_vm() {
  azure vm create \
    --resource-group $rg \
    --name $vm \
    --os-type Linux \
    --vm-size $vm_size \
    --location $region \
    --vnet-name $vnet \
    --nic-names $vm_nic_list \
    --image-urn $image \
    --custom-data cloud-init-tg-proxy-ubuntu16.sh \
    --admin-username nick \
    --ssh-publickey-file $pub_key_path
}

# create network if not exists for desired region
create_network || true

create_nic 1
# Можнно добавить несколько интерфейсов на одну VM
# create_nic 2

create_vm &>/dev/null &

