#!/bin/bash
set -xeuo pipefail

tg_shared_pub='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDuw+ZBdVIMkIhWs9DBXp1qrkNojeJI9JEbXcUOyriy5T6/8P/w2tgskV9yGYsY16m/ooUyYAPQ5xM0qlqcMVh/gbvVfkPRUxd1NxDN7MZRe6wUXCgesECGEPo0mfw1MEnPWqOMuKSFebAhCld1zBep8KpSjUsKb8bXn83hybxMC78qk/7mWImIFGN9anPQRtq2Q+MCJyn1v5rSPmlpEBDh9kK6zgt/KJyRb/AxB15ZefXAs8m/Wz3Vnkb2rjfJZYL4ama6/G2nnXGgZQoHW/gUor7mqiRk08KYz9X4QsaebFsGYTAu07WQGX3QxXzOw2UrDvAsnJzo+TEfFUR6aT0D root@dr'
echo $tg_shared_pub >> ~/.ssh/authorized_keys

apt-get update
apt-get install -y libltdl7 apt-transport-https ca-certificates curl gnupg2 software-properties-common
wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_18.03.0~ce-0~ubuntu_amd64.deb
dpkg -i docker-ce_18.03.0~ce-0~ubuntu_amd64.deb
apt-get update
apt-get install -y docker-ce
systemctl enable docker
systemctl start docker

workers=$(grep processor /proc/cpuinfo | wc -l)
docker_container=$1
docker pull $docker_container
docker run -d --restart always --net=host -p53:8088 -p443:443 -p5222:5222 -e WORKERS=$workers $docker_container
