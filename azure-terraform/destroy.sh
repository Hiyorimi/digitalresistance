#!/bin/bash -e

az account show 2>/dev/null || az login

cd ../terraform
terraform destroy -var ssh_key_data="$(cat ../tg_rsa.pub)"
