#!/bin/bash

set -e 

VBOX_PASS=$1
VBOX_USER=$(cat /etc/passwd|grep 1000|cut -d ':' -f 1)

echo "PASSWORD FOR UID 1000:"
echo "INFO: VBOX_USER: $VBOX_USER"

# replace sources.list
sudo tee /etc/apt/sources.list <<-'EOF' # end with "EOF", tee for display on the terminal
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
EOF

apt update

#===============
# prequisite
#===============
echo "Installing essentials..."

# install virtualbox and docker
apt install -y virtualbox virtualbox-ext-pack docker.io docker-compose net-tools

# increase docker timeout limit
export DOCKER_CLIENT_TIMEOUT=600
export DOCKER_HTTP_TIMEOUT=600

# set up user cuckoo with uid 1000 if no user with uid 1000
if [[ -z $VBOX_USER ]]; then
    adduser cuckoo # deluser --remove-home cuckoo to remove it
    passwd cuckoo $VBOX_PASS
    usermod -aG sudo cuckoo
    usermod -u 1000 cuckoo
    VBOX_USER=cuckoo
fi

if [[ ! -e /home/$VBOX_USER/.ssh ]]; then
    ssh-keygen # to clone from github
fi


#==================
# vboxwebsrv
#==================
echo "Installing vboxwebsrv..."

echo "VBOX_USER=$VBOX_USER\nVBOX_PASS=$VBOX_PASS" >> /etc/default/virtualbox 
su - $VBOX_USER -c "vboxwebsrv --background --host 0.0.0.0" # su - <username> -c "<command>"" # run <command> as <username>

# create hostonlyif vboxnet0
if [[ -z $(vboxmanage list hostonlyifs|grep 'vboxnet0') ]]; then
    vboxmanage hostonlyif create # create a hostonly interface
fi
vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 # config ip for vboxnet0 on host
sed -i "$ a vboxwebsrv --background --host 0.0.0.0" /home/$VBOX_USER/.profile

# enable ip forward
sysctl -w net.ipv4.ip_forward=1
echo 1 > /proc/sys/net/ipv4/ip_forward 
sudo sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf # persistent 

#===================
# docker-cukoo
#==================
echo "Installing docker-cuckoo..."

if [[ ! -e /mnt/cuckoo-storage ]]; then 
    mkdir /mnt/cuckoo-storage
fi

chown -R $VBOX_USER /mnt/cuckoo-storage # accessible to vbox_user

# install docker-cuckoo
cd ~
if [[ ! -e docker-cuckoo ]]; then
    git clone https://github.com/dagrons/docker-cuckoo
fi
cd docker-cuckoo && chown -R $VBOX_USER cuckoo-tmp # accessible to vbox_user
external_ip=$(ifconfig ens33|grep inet|awk '{print $2}'|head -n 1) 
sed -i "s/url.*/url = http:\/\/$external_ip:18083/; s/user.*/user = $VBOX_USER/; s/password.*/password = $VBOX_PASS/" vbox/conf/virtualbox_websrv.conf # replace external ip for vboxwebsrv # # modify virtualbox_websrv.conf

sysctl -w vm.max_map_count=262144 # increase ulimit for elastic
sed -i "$ a vm.max_map_count=262144"  /etc/sysctl.conf # persistent

docker-compose down  
docker-compose -f docker-compose.vbox.yml up -d
