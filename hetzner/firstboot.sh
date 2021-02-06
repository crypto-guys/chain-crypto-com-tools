#!/bin/bash

# Wait for cloud-init to finish installing packages and configuring
sleep 180

# Settings
MONIKER="philalmaian"
apt -q -y install jq

# Create Paths and Copy Files
cd /home/crypto-solutions/firstboot


# Download any required files
wget https://github.com/crypto-com/chain-main/releases/download/v0.9.1-crossfire/chain-main_0.9.1-crossfire_Linux_x86_64.tar.gz -O /home/crypto-solutions/firstboot/

# Extract the files and place them in the correct locations
tar -xf /home/crypto-solutions/firstboot/chain-main_0.9.1-crossfire_Linux_x86_64.tar.gz -C /home/crypto-solutions/firstboot/chain-main_0.9.1-crossfire/
cp /home/crypto-solutions/firstboot/chain-main_0.9.1-crossfire/chain-maind /usr/local/bin/chain-maind

# Init
chain-maind init $MONIKER --chain-id crossfire

# Replace genesis
curl https://raw.githubusercontent.com/crypto-com/testnets/main/crossfire/genesis.json > /home/crypto-solutions/.chain-maind/config/genesis.json

# Validate the data
 if [[ $(sha256sum /home/crypto-solutions/.chain-maind/config/genesis.json | awk '{print $1}') = "074d99565111844edf1e9eb62069b7ad429484c41adcab1062447948b215c3c8" ]]; then echo "OK"; else echo "PANIC!!!  Checksum did not match exiting..."; fi;

# Set min tx fee
sed -i.bak -E 's#^(minimum-gas-prices[[:space:]]+=[[:space:]]+)""$#\1"0.025basetcro"#' /home/crypto-solutions/.chain-maind/config/app.toml

# Set Persistent Peers
sed -i.bak -E 's#^(persistent_peers[[:space:]]+=[[:space:]]+).*$#\1"1c43083bc3ed408a20ecd1738200e9ab48026b6b@54.251.113.42:26656,b8f999e37d8446e24862a71b6d4a004400947fe5@3.0.217.55:26656,9e9173fbdfe8d8ee84038782eec0777ee5f33548@3.0.188.186:26656"# ; s#^(create_empty_blocks_interval[[:space:]]+=[[:space:]]+).*$#\1"5s"#' /home/crypto-solutions/.chain-maind/config/config.toml

LASTEST_HEIGHT=$(curl -s https://crossfire.crypto.com/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LASTEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "https://crossfire.crypto.com/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"https://crossfire.crypto.com:443,https://crossfire.crypto.com:443\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" /home/crypto-solutions/.chain-maind/config/config.toml

git clone https://github.com/crypto-com/chain-main.git /home/crypto-solutions/firstboot/chain-main 
/home/crypto-solutions/firstboot/chain-main/networks/create-service.sh
sudo systemctl start chain-maind
