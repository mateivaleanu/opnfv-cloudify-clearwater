#!/bin/bash -e

ctx logger debug "${COMMAND}"

ctx logger info "Configure the APT software source"
if [ ! -f /etc/apt/sources.list.d/clearwater.list ]
  then
    echo 'deb http://repo.cw-ngv.com/~aarch64/repo binary/' | sudo tee --append /etc/apt/sources.list.d/clearwater.list
    curl -L http://repo.cw-ngv.com/repo_key | sudo apt-key add -
fi
sudo apt-get update

ctx logger info "Installing homestead packages and other clearwater packages"
set +e
sudo DEBIAN_FRONTEND=noninteractive  apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install homestead homestead-prov clearwater-prov-tools libsnmp30=5.7.2~dfsg-clearwater4 --yes --allow-unauthenticated
sudo DEBIAN_FRONTEND=noninteractive  apt-get install clearwater-management --yes --allow-unauthenticated
sudo DEBIAN_FRONTEND=noninteractive  apt-get install default-jre openjdk-8-jre python-pip --yes
sudo wget http://launchpadlibrarian.net/109052632/python-support_1.0.15_all.deb && sudo dpkg -i python-support_1.0.15_all.deb && sudo rm -f python-support_1.0.15_all.deb
sudo wget http://openjdk.linaro.org/releases/jdk9-server-release-1605.tar.xz && sudo tar xJf jdk9-server-release-1605.tar.xz && sudo mkdir -p /usr/jdk && sudo mv -n jdk9-server-release-1605 /usr/jdk/ && sudo chown -R root.root /usr/jdk && sudo chmod -R 755 /usr/jdk/ && sudo cp -R /usr/jdk/jdk9-server-release-1605 /usr/lib/jvm/java9-openjdk-1605 && sudo rm -f jdk9-server-release-1605.tar.xz
sudo apt-get install libjemalloc1
sudo wget http://repo.cw-ngv.com/~ubuntu/repo/binary/cassandra_2.1.15_all.deb && sudo dpkg -i cassandra_2.1.15_all.deb && sudo rm -f cassandra_2.1.15_all.deb
sudo pip install cassandra-driver
sudo systemctl daemon-reload
set -e
ctx logger info "The installation packages is done correctly"

ctx logger info "Use the DNS server"
echo 'RESOLV_CONF=/etc/dnsmasq.resolv.conf' | sudo tee --append  /etc/default/dnsmasq
sudo service dnsmasq force-reload
sudo monit unmonitor -g etcd
sudo service clearwater-etcd start

ctx logger info "Installation is done"
