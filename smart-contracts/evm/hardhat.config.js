require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-verify");

let provider = 'http://localhost:8545'
let hardhatConfigs = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      mining: {
        auto: false,
        interval: 500
      }
    },
    mainnet: {
      url: provider
    },
    polygon: {
      url: provider
    },
    'base-sepolia': {
      url: "https://sepolia.base.org",
    },
    'base-mainnet': {
      url: "https://base.org"
    },
  },
  solidity: {
    version: "0.8.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    }
  },
}

if (process.env.ACCOUNTS !== undefined) {
  for (let k in hardhatConfigs.networks) {
    hardhatConfigs.networks[k].accounts = []
    for (let a in process.env.ACCOUNTS.split(',')) {
      if (k === 'hardhat') {
        hardhatConfigs.networks[k].accounts.push({
          privateKey: process.env.ACCOUNTS.split(',')[a],
          balance: "1000000000000000000000"
        })
      } else {
        hardhatConfigs.networks[k].accounts.push(process.env.ACCOUNTS.split(',')[a])
      }
    }
  }
}

if (process.env.PROVIDER !== undefined) {
  for (let k in hardhatConfigs.networks) {
    if (k !== 'hardhat') {
      hardhatConfigs.networks[k].url = process.env.PROVIDER
    }
  }
}
hardhatConfigs.etherscan = {
  apiKey: {
    mainnet: process.env.ETHERSCAN,
    'base-mainnet': process.env.ETHERSCAN,
    'base-sepolia': process.env.ETHERSCAN
  },
  customChains: [
    {
      network: "base-mainnet",
      chainId: 8453,
      urls: {
        apiURL: "https://api.basescan.org/api",
        browserURL: "https://basescan.org"
      }
    },
    {
      network: "base-sepolia",
      chainId: 84532,
      urls: {
        apiURL: "https://api-sepolia.basescan.org/api",
        browserURL: "https://sepolia.basescan.org"
      }
    },
  ]
}

module.exports = hardhatConfigs;
