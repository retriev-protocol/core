#!/bin/bash
echo "INSTALLING DEPENDENCIES FOR PROJECT"

#INSTALL NODEJS
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install pm2 -g
npm install yarn -g

#INSTALL GO
wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile

# INSTALL IPFS
wget https://github.com/ipfs/kubo/releases/download/v0.28.0/kubo_v0.28.0_linux-386.tar.gz
tar -xvzf kubo_v0.28.0_linux-386.tar.gz
bash kubo/install.sh
rm -rf kubo
rm kubo_v0.28.0_linux-386.tar.gz

#INIT IPFS
ipfs init

#SETTING UP NGINX
sudo apt update
sudo apt install nginx -y
sudo ufw allow 'Nginx Full'

#INSTALL CERTBOT
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

#SETTING UP FIREWALL
ufw allow 22
ufw allow 9000
ufw allow 4001
ufw --force enable

#INSTALL SHARED DEPENDENCIES
cd shared
yarn