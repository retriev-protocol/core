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

  // Adding referees to contract
  for (let k in configs.referees) {
    if (
      configs.referees[k].active !== undefined &&
      configs.referees[k].active === false
    ) {
      console.log(
        "Removing " + configs.referees[k].address + " from referees.."
      );
      try {
        const gasPrice = await provider.getGasPrice();
        const tx = await contract.setRefereeStatus(
          configs.referees[k].address,
          false,
          configs.referees[k].endpoint,
          { gasPrice, gasLimit: "5000000" }
        );
        await tx.wait();
        console.log("Referee added at " + tx.hash + "!");
      } catch (e) {
        console.log(e);
        console.log("Can't add refeeree, check transaction.");
      }
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
