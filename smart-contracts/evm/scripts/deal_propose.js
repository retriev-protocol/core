const { ethers, utils } = require("ethers");
const fs = require("fs");
const { generate, derive } = require("../libs/address_generator");

async function main() {
  const configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString());
  const ABI = JSON.parse(
    fs
      .readFileSync(
        "./artifacts/contracts/" +
          configs.contract_name +
          ".sol/" +
          configs.contract_name +
          ".json"
      )
      .toString()
  );
  const provider = new ethers.providers.StaticJsonRpcProvider(configs.provider);
  let wallet = new ethers.Wallet(configs.owner_key).connect(provider);
  const contract = new ethers.Contract(
    configs.contract_address,
    ABI.abi,
    wallet
  );

  // Getting last deal and add a number to IPFS hash, just for test of course.
  const deal_index = await contract.totalDeals();

  let value = "100"; // Amount to pay for deal in gwei
  const ipfs_providers = [
    configs.providers[0].address,
    configs.providers[1].address,
  ]; // Adding two providers
  let data_uri =
    "ipfs://bafkreiggzxkhpj6m6vkzzwvzst4tv6kng3pgma67ukcrzwzyh5b54eben4";
  if (configs.network === "hardhat") {
    console.log("Adding index for test in localhost..");
    data_uri =
      "ipfs://bafkreiggzxkhpj6m6vkzzwvzst4tv6kng3pgma67ukcrzwzyh5b54eben4-" +
      deal_index; // Public readme folder
  }
  const max_duration = await contract.max_duration();
  const duration = max_duration; // Duration of the deal
  const collateral = ethers.utils.parseUnits(value, "gwei"); // Setting 0 if you need minimum one
  const appeal_addresses = [wallet.address];

  const contract_protected = await contract.contract_protected();
  if (contract_protected) {
    value = "0";
  }
  try {
    console.log("Creating new deal with URI: " + data_uri);
    const tx = await contract.createDealProposal(
      data_uri,
      duration,
      collateral,
      ipfs_providers,
      appeal_addresses,
      { value: ethers.utils.parseUnits(value, "gwei") }
    );
    console.log("Pending transaction at: " + tx.hash);
    await tx.wait();
    console.log("Deal created at " + tx.hash + "!");
  } catch (e) {
    console.log(e);
    console.log("Can't create deal, check transaction.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
