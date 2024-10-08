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
  // Setting up provider's wallet
  let wallet = new ethers.Wallet(configs.providers[0].key).connect(provider);
  const contract = new ethers.Contract(
    configs.contract_address,
    ABI.abi,
    wallet
  );

  try {
    let finised = false;
    let p = 0;
    while (!finised) {
      const provider = await contract.active_providers(p);
      console.log("Provider:", provider);
      p++;
    }
  } catch (e) {
    console.log("Providers ended.");
  }

  try {
    let finised = false;
    let p = 0;
    while (!finised) {
      const referee = await contract.active_referees(p);
      console.log("Referee:", referee);
      p++;
    }
  } catch (e) {
    console.log("Referees ended.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
