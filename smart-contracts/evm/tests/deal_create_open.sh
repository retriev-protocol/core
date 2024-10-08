#!/bin/bash

if [ $1 == "hardhat" ]
then
yarn task deploy $1
cd ../appeal && yarn task sync hardhat && yarn task deploy $1 && cd ../main
yarn task setup $1
yarn task render $1
fi

yarn task deal_create_open $1
cd ../appeal && yarn task appeal_create $1