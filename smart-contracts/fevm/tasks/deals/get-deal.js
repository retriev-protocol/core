const fs = require("fs")

task("get-deal", "Calls the Retriev contract to read the deal details.")
    .addParam("deal", "The index of the deal you want to read")
    .setAction(async (taskArgs) => {
        const network = await ethers.provider.getNetwork()
        console.log("Network:", network.name)
        const configs = JSON.parse(fs.readFileSync(`configs/${network.name}.json`))
        const contractAddr = configs.contract_address
        const Retriev = await ethers.getContractFactory("Retriev")
        // Get signer information
        const accounts = await ethers.getSigners()
        const signer = accounts[0]
        // Deal index
        const deal_index = taskArgs.deal
        // Get deal details
        const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
        let result = await RetrievContract.deals(deal_index)
        console.log("Deal is: ", result)
    })

module.exports = {}
