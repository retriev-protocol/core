const fs = require("fs")

task("create-appeal", "Calls the Retriev contract to create an appeal.").setAction(
    async (taskArgs) => {
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
        const lastDeal = await RetrievContract.totalDeals()
        console.log("Deal index:", lastDeal)
        const tx = await RetrievContract.createAppeal(lastDeal)
        console.log("Pending transaction at: " + tx.hash)
        await tx.wait()
        console.log("Deal created at " + tx.hash + "!")
    }
)

module.exports = {}
