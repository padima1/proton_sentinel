#!/bin/bash
sudo touch /var/swap.img
sudo chmod 600 /var/swap.img
sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
mkswap /var/swap.img
sudo swapon /var/swap.img
sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install nano htop git -y
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils software-properties-common -y
sudo apt-get install libboost-all-dev -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
mkdir /root/temp
sudo git clone https://github.com/protoncoin/protoncoin.git /root/temp
chmod -R 755 /root/temp
cd /root/temp
./autogen.sh
./configure
sudo make
sudo make install
cd
mkdir /root/proton
mkdir /root/.protoncore
cp /root/temp/src/protond /root/proton
cp /root/temp/src/proton-cli /root/proton
chmod -R 755 /root/proton
chmod -R 755 /root/.protoncore
sudo apt-get install -y pwgen
GEN_PASS=`pwgen -1 20 -n`
echo -e "rpcuser=protonuser\nrpcpassword=${GEN_PASS}\nrpcport=17866\nport=17817\nlisten=1\nmaxconnections=256" > /root/.protoncore/proton.conf
cd /root/proton
./protond -daemon
sleep 10
masternodekey=$(./proton-cli masternode genkey)
./proton-cli stop
echo -e "masternode=1\nmasternodeprivkey=$masternodekey" >> /root/.protoncore/proton.conf
./protond -daemon
cd /root/.protoncore
sudo apt-get install -y git python-virtualenv
sudo git clone https://github.com/protoncoin/proton_sentinel.git
cd proton_sentinel
export LC_ALL=C
sudo apt-get install -y virtualenv
virtualenv venv
venv/bin/pip install -r requirements.txt
echo "proton_conf=/root/.protoncore/proton.conf" >> /root/.protoncore/proton_sentinel/sentinel.conf
crontab -l > tempcron
echo "* * * * * cd /root/.protoncore/proton_sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log" >> tempcron
crontab tempcron
rm tempcron
echo "Masternode private key: $masternodekey"
echo "Job completed successfully"