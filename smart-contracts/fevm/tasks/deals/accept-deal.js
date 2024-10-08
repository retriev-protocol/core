const fs = require("fs")

task("accept-deal", "Calls the Retriev contract to accept a deal.").setAction(async (taskArgs) => {
    const network = await ethers.provider.getNetwork()
    console.log("Network:", network.name)
    const configs = JSON.parse(fs.readFileSync(`configs/${network.name}.json`))
    const contractAddr = configs.contract_address
    const account = configs.owner_address
    const networkId = network.name
    console.log("Creating deal for", account, " on network ", networkId)
    const Retriev = await ethers.getContractFactory("Retriev")
    // Get signer information
    const accounts = await ethers.getSigners()
    const signer = accounts[1]
    // Get contract
    const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
    console.log("Signer address:", signer.address)
    console.log("Contract address:", contractAddr)
    // Get last deal
    const lastDeal = await RetrievContract.totalDeals()
    console.log("Deal index:", lastDeal)
    // Check if provider is in deal
    const canAccept = await RetrievContract.isProviderInDeal(lastDeal, signer.address)
    console.log("Can accept:", canAccept)
    if (canAccept) {
        // Accept deal
        const tx = await RetrievContract.acceptDealProposal(lastDeal)
        console.log("Pending transaction at: " + tx.hash)
        await tx.wait()
    } else {
        console.log("Can't accept deal, not listed as provider in deal.")
    }
})

module.exports = {}
