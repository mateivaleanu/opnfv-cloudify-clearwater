#!/bin/bash -e

ctx logger debug "${COMMAND}"

sudo mkdir -p /etc/chronos

echo '
[http]
bind-address = $(hostname -I)
bind-port = 7253
threads = 50

[logging]
folder = /var/log/chronos
level = 2

[alarms]
enabled = true

[exceptions]
max_ttl = 600' | sudo tee --append /etc/chronos/chronos.conf

ctx logger info "Configure the APT software source"
if [ ! -f /etc/apt/sources.list.d/clearwater.list ]
  then
    echo 'deb http://repo.cw-ngv.com/~aarch64/repo binary/' | sudo tee --append /etc/apt/sources.list.d/clearwater.list
    curl -L http://repo.cw-ngv.com/repo_key | sudo apt-key add -
fi
sudo apt-get update

ctx logger info "Installing ralf packages and other clearwater packages"
set +e
sudo DEBIAN_FRONTEND=noninteractive apt-get install libsnmp30=5.7.2~dfsg-clearwater4 --yes --force-yes
sudo DEBIAN_FRONTEND=noninteractive apt-get install clearwater-snmpd=1.0-160214.201323 snmpd=5.7.2~dfsg-clearwater4 snmp=5.7.2~dfsg-clearwater4 --yes --force-yes
sudo DEBIAN_FRONTEND=noninteractive apt-get install memcached --yes --force-yes
set -e
sudo DEBIAN_FRONTEND=noninteractive apt-get install chronos --yes --force-yes
sudo DEBIAN_FRONTEND=noninteractive apt-get install sprout --yes --force-yes -o DPkg::options::=--force-confnew
sudo DEBIAN_FRONTEND=noninteractive apt-get install clearwater-management --yes --force-yes
sudo systemctl daemon-reload
ctx logger info "The installation packages is done correctly"

ctx logger info "Use the DNS server"
echo 'RESOLV_CONF=/etc/dnsmasq.resolv.conf' | sudo tee --append  /etc/default/dnsmasq
sudo service dnsmasq restart
sudo monit unmonitor -g etcd
sudo service clearwater-etcd start
echo -e "nameserver 127.0.0.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf > /dev/null

ctx logger info "Installation is done"
