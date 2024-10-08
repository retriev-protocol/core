#!/bin/bash

if [ $1 == "hardhat" ]
then
yarn task deploy $1
yarn task setup $1
yarn task render $1
fi

yarn task deal_propose $1
sleep 5
yarn task deposit $1
sleep 5
yarn task deal_accept $1
sleep 5
yarn task collection $1
sleep 5
yarn task deal_status $1
echo "Waiting 3600s before redeem deal"
sleep 3600
yarn task deal_redeem $1