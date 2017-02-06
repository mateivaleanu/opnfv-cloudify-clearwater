#!/bin/bash -e

ctx logger debug "${COMMAND}"

ctx logger info "Configure the APT software source"
if [ ! -f /etc/apt/sources.list.d/clearwater.list ]
  then
    echo 'deb http://repo.cw-ngv.com/~aarch64/repo binary/' | sudo tee --append /etc/apt/sources.list.d/clearwater.list
    curl -L http://repo.cw-ngv.com/repo_key | sudo apt-key add -
fi
sudo apt-get update

ctx logger info "Installing ellis packages and other clearwater packages"
sudo DEBIAN_FRONTEND=noninteractive apt-get install ellis libmysqlclient20 --yes --force-yes -o DPkg::options::=--force-confnew
sudo DEBIAN_FRONTEND=noninteractive apt-get install clearwater-management --yes --force-yes
ctx logger info "The installation packages is done correctly"

ctx logger info "Configure a new DNS server"
echo 'RESOLV_CONF=/etc/dnsmasq.resolv.conf' | sudo tee --append  /etc/default/dnsmasq
sudo service dnsmasq restart
sudo monit unmonitor -g etcd
sudo service clearwater-etcd start
echo -e "nameserver 127.0.0.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf > /dev/null
sudo mysql -u root -e "update mysql.user set plugin='mysql_native_password'; flush privileges;"
