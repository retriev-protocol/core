#!/bin/bash

if [ $1 == "hardhat" ]
then
yarn task deploy $1
yarn task setup $1
yarn task tune_tests $1
yarn task render $1
fi

yarn task deal_propose $1
yarn task deposit $1
yarn task deal_accept $1
yarn task appeal_create $1
yarn task appeal_start $1
yarn task appeal_slash_signatures $1
yarn task vault $1