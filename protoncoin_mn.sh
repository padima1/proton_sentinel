echo "=================================================================="
echo "Protoncoin MN Install"
echo "=================================================================="

#read -p 'Enter your masternode genkey you created in windows, then hit [ENTER]: ' GENKEY

echo -n "Installing pwgen..."
sudo apt-get install -y pwgen

echo -n "Installing dns utils..."
sudo apt-get install -y dnsutils

WALLET_VERSION='1.1.0'
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PORT='17817'
RPCPORT='17866'
PASSWORD=`pwgen -1 20 -n`
if [ "x$PASSWORD" = "x" ]; then
    PASSWORD=${WANIP}-`date +%s`
fi

#begin optional swap section
echo "Setting up disk swap..."
free -h
sudo fallocate -l 4G /swapfile
ls -lh /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h
echo "SWAP setup complete..."
#end optional swap section

echo "Installing packages and updates..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install nano -y
sudo apt-get install build-essential libtool automake autoconf -y
sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -y
sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libdb5.3-dev libdb5.3++-dev -y

echo "Packages complete..."

wget https://github.com/protoncoin/protoncoin/releases/download/v${WALLET_VERSION}/protoncoin-linux-no-qt-v${WALLET_VERSION}.tar.gz

rm -rf proton
mkdir proton
tar -zxvf protoncoin-linux-no-qt-v${WALLET_VERSION}.tar.gz -C proton

echo "Loading and syncing wallet"

echo "If you see *error: Could not locate RPC credentials* message, do not worry"
~/proton/proton-cli stop
sleep 10
echo ""
echo "=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT 5 MINUTES UNTIL YOU SEE THE RELOADING WALLET MESSAGE"
echo "=================================================================="
echo ""
~/proton/protond -daemon
sleep 250
~/proton/proton-cli stop
sleep 20

cat <<EOF > ~/.protoncore/proton.conf
rpcuser=protoncoin
rpcpassword=${PASSWORD}
EOF

echo "Reloading wallet..."
~/proton/protond -daemon
sleep 30

echo "Making genkey..."
GENKEY=$(~/proton/proton-cli masternode genkey)

echo "Mining info..."
~/proton/proton-cli getmininginfo
~/proton/proton-cli stop

echo "Creating final config..."

cat <<EOF > ~/.protoncore/proton.conf
rpcuser=protoncoin
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
server=1
daemon=1
listen=1
rpcport=${RPCPORT}
port=${PORT}
maxconnections=256
masternode=1
masternodeprivkey=$GENKEY
EOF

echo "Setting basic security..."
sudo apt-get install systemd -y
sudo apt-get install fail2ban -y
sudo apt-get install ufw -y
sudo apt-get update -y

#fail2ban:
#sudo systemctl enable fail2ban
#sudo systemctl start fail2ban

#add a firewall
#sudo ufw default allow outgoing
#sudo ufw default deny incoming
#sudo ufw allow ssh/tcp
#sudo ufw limit ssh/tcp
#sudo ufw allow 17866/tcp
#sudo ufw allow 17817/tcp
#sudo ufw logging on
#sudo ufw status
#echo y | sudo ufw enable
echo "Basic security completed..."

echo "Restarting wallet with new configs, 30 seconds..."
~/proton/protond -daemon
sleep 30

echo "Installing sentinel..."
cd /root/.protoncore
sudo apt-get install -y git python-virtualenv

sudo git clone https://github.com/protoncoin/proton_sentinel.git

cd proton_sentinel

export LC_ALL=C
sudo apt-get install -y virtualenv

virtualenv ./venv
./venv/bin/pip install -r requirements.txt

echo "proton_conf=/root/.protoncore/proton.conf" >> /root/.protoncore/proton_sentinel/sentinel.conf

echo "Adding crontab jobs..."
crontab -l > tempcron
#echo new cron into cron file
echo "* * * * * cd /root/.protoncore/proton_sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> tempcron
echo "@reboot /bin/sleep 20 ; /root/proton/protond -daemon &" >> tempcron

#install new cron file
crontab tempcron
rm tempcron

SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py
echo "Sentinel Installed"

echo "proton-cli getmininginfo:"
~/proton/proton-cli getmininginfo

sleep 15

echo "Masternode status:"
~/proton/proton-cli masternode status

echo "INSTALLED WITH VPS IP: $WANIP:$PORT"
sleep 1
echo "INSTALLED WITH GENKEY: $GENKEY"
sleep 1
echo "rpcuser=protoncoin\nrpcpassword=$PASSWORD"
