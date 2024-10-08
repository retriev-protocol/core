const fs = require("fs")

task("get-appeal", "Calls the Retriev contract to get an appeal.").setAction(async (taskArgs) => {
    const network = await ethers.provider.getNetwork()
    console.log("Network:", network.name)
    const configs = JSON.parse(fs.readFileSync(`configs/${network.name}.json`))
    const contractAddr = configs.contract_address
    const account = configs.owner_address
    const networkId = network.name
    console.log("Creating appeal for", account, " on network ", networkId)
    const Retriev = await ethers.getContractFactory("Retriev")
    // Get signer information
    const accounts = await ethers.getSigners()
    const signer = accounts[0]
    const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
    console.log("Signer address:", signer.address)
    // Create appeal
    const lastAppeal = await RetrievContract.totalAppeals()
    console.log("Appeal index:", lastAppeal)
    const appeal = await RetrievContract.appeals(lastAppeal)
    console.log("Appeal:", appeal)
    const round = await RetrievContract.getRound(lastAppeal)
    console.log("Round:", round)
})

module.exports = {}
