const fs = require("fs")

task("start-appeal", "Calls the Retriev contract to process an appeal.").setAction(
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
        const signer = accounts[2]
        const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
        console.log("Signer address:", signer.address)
        // Create appeal
        const lastAppeal = await RetrievContract.totalAppeals()
        console.log("Appeal index:", lastAppeal)
        const tx = await RetrievContract.startAppeal(lastAppeal)
        console.log("Pending transaction at: " + tx.hash)
        await tx.wait()
        console.log("Deal created at " + tx.hash + "!")
    }
)

module.exports = {}
