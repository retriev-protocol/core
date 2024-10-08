const fs = require("fs")

task("create-deal", "Calls the Retriev contract to create a deal.").setAction(async (taskArgs) => {
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
    const signer = accounts[0]
    const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
    console.log("Signer address:", signer.address)
    // Deal specs
    const collateral = 0
    const duration = 60 * 60 * 24 * 7
    const data_uri = "ipfs://bafkreiggmczdon4znkypijng5rb7zcgftkzsy3spsyoqaigvszrdf6ck5i"
    const providers = [configs.providers[0].address]
    const appeal_addresses = [signer.address]
    const tx = await RetrievContract.createDealProposal(
        data_uri,
        duration,
        collateral,
        providers,
        appeal_addresses
    )
    console.log("Pending transaction at: " + tx.hash)
    await tx.wait()
    console.log("Deal created at " + tx.hash + "!")
})

module.exports = {}
