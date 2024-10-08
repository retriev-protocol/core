npx hardhat create-appeal --network calibrationnet
npx hardhat start-appeal --network calibrationnet
npx hardhat process-appeal --network calibrationnet
for i in {1..12}
do
    npx hardhat process-appeal --network calibrationnet
    sleep 60
done