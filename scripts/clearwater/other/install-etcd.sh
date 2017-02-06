#!/bin/bash -e

ctx logger debug "${COMMAND}"

ctx logger info "Configure the APT software source"
if [ ! -f /etc/apt/sources.list.d/clearwater.list ]
  then
    echo 'deb http://repo.cw-ngv.com/~aarch64/repo binary/' | sudo tee --append /etc/apt/sources.list.d/clearwater.list
    curl -L http://repo.cw-ngv.com/repo_key | sudo apt-key add -
fi
sudo apt-get update

ctx logger info "Now install the software"
sudo   DEBIAN_FRONTEND=noninteractive apt-get install clearwater-config-manager --yes --force-yes
ctx logger info "The software is installed"

/usr/share/clearwater/clearwater-etcd/scripts/wait_for_etcd
sudo /usr/share/clearwater/clearwater-config-manager/scripts/upload_shared_config
#sudo /usr/share/clearwater/clearwater-config-manager/scripts/apply_shared_config

sudo monit unmonitor -g etcd
sudo service clearwater-etcd start
ctx logger info "Installation is done"
