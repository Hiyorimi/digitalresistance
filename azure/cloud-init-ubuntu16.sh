#!/bin/bash
set -xeuo pipefail

apt-get update
apt-get install -y libltdl7 apt-transport-https ca-certificates curl gnupg2 software-properties-common
wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_18.03.0~ce-0~ubuntu_amd64.deb
dpkg -i docker-ce_18.03.0~ce-0~ubuntu_amd64.deb
apt-get update
apt-get install -y docker-ce
systemctl enable docker
systemctl start docker

docker pull $DIGITAL_RESISTANCE_IMAGE
docker run -d --restart always --net=host $DIGITAL_RESISTANCE_IMAGE
