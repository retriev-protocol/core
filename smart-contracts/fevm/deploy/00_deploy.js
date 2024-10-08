require("hardhat-deploy")
require("hardhat-deploy-ethers")
const fs = require("fs")

const private_key = network.config.accounts[0]
const wallet = new ethers.Wallet(private_key, ethers.provider)

module.exports = async ({ deployments }) => {
    const { deploy } = deployments
    console.log("Using Ethereum Address:", wallet.address)
    const network = await ethers.provider.getNetwork()
    console.log("Network:", network.name)
    const configs = JSON.parse(fs.readFileSync(`configs/${network.name}.json`))

    const Render = await deploy("TokenRender", {
        from: wallet.address,
        args: [],
        log: true,
    })
    console.log("TokenRender deployed at:", Render.address)
    configs.token_render = Render.address
    // deploy Retriev
    const Retriev = await deploy("Retriev", {
        from: wallet.address,
        args: [wallet.address, Render.address],
        log: true,
    })
    console.log("Retriev deployed at:", Retriev.address)
    configs.contract_address = Retriev.address
    fs.writeFileSync(`configs/${network.name}.json`, JSON.stringify(configs, null, 2))
}
