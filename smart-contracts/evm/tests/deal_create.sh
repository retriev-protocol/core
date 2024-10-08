#!/bin/bash

if [ $1 == "hardhat" ]
then
yarn task deploy $1
yarn task setup $1
yarn task render $1
fi

yarn task deal_create $1
yarn task appeal_create $1