# INSTALL IPFS
wget https://github.com/ipfs/kubo/releases/download/v0.28.0/kubo_v0.28.0_linux-386.tar.gz
tar -xvzf kubo_v0.28.0_linux-386.tar.gz
bash kubo/install.sh
rm -rf kubo
rm kubo_v0.28.0_linux-386.tar.gz

ipfs init
ipfs daemon &