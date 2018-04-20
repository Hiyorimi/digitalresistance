#!/bin/bash -e

if [ ! -f tg_rsa ]; then
  ssh-keygen -f tg_rsa -N ''
fi

az account show 2>/dev/null || az login

cd ansible
ansible-playbook generate.yml

cd ../terraform
terraform init
terraform apply -var ssh_key_data="$(cat ../tg_rsa.pub)"
