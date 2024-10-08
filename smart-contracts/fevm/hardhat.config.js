require("@nomicfoundation/hardhat-toolbox")
require("hardhat-deploy")
require("hardhat-deploy-ethers")
require("./tasks")
require("dotenv").config()

const PRIVATE_KEY = process.env.PRIVATE_KEY
const PROVIDER_KEY = process.env.PROVIDER_KEY
const REFEREE_KEY = process.env.REFEREE_KEY

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
                details: { yul: false },
            },
        },
    },
    defaultNetwork: "calibrationnet",
    networks: {
        localnet: {
            chainId: 31415926,
            url: "http://127.0.0.1:1234/rpc/v1",
            accounts: [PRIVATE_KEY],
        },
        calibrationnet: {
            chainId: 314159,
            url: "https://api.calibration.node.glif.io/rpc/v1",
            accounts: [PRIVATE_KEY, PROVIDER_KEY, REFEREE_KEY],
            verify: {
                url: "https://calibration.filfox.info/api/v1/tools/verifyContract",
                apiKey: "glif-calibration",
            },
        },
        filecoinmainnet: {
            chainId: 314,
            url: "https://api.node.glif.io",
            accounts: [PRIVATE_KEY],
            verify: {
                url: "https://calibration.filfox.info/api/v1/tools/verifyContract",
                apiKey: "glif-calibration",
            },
        },
    },
    etherscan: {
        apiKey: {
            calibrationnet: "glif-calibration",
        },
        customChains: [
            {
                network: "calibrationnet",
                chainId: 314159,
                urls: {
                    apiURL: "https://calibration.filfox.info/api/v1/tools/verifyContract",
                    browserURL: "https://calibration.filfox.info",
                },
                apiKey: "glif-calibration",
            },
        ],
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
}
