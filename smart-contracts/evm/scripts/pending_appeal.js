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
  const wallet = new ethers.Wallet(configs.referees[0].key).connect(provider);
  const contract = new ethers.Contract(
    configs.contract_address,
    ABI.abi,
    wallet
  );

  // Working always with last deal
  const deal_index = await contract.totalDeals();

  try {
    const cid =
      "ipfs://bafkreidlrmxrhd45dljz34f54txu7affj27xv2fmbqv7oumpnlptljpcuu";
    const appealId = await contract.pending_appeals(cid);
    console.log(appealId);
    const appeal = await contract.appeals(appealId);
    console.log("Appeal is:", appeal);
    const round = await contract.getRound(appealId);
    console.log("Round is:", round.toString());
  } catch (e) {
    console.log(e.message);
    console.log("Can't get appeal, check transaction.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
