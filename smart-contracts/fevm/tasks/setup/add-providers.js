const fs = require("fs")

task("add-providers", "Add providers to protocol").setAction(async (taskArgs) => {
    const network = await ethers.provider.getNetwork()
    console.log("Network:", network.name)
    const configs = JSON.parse(fs.readFileSync(`configs/${network.name}.json`))

    const contractAddr = configs.contract_address
    const Retriev = await ethers.getContractFactory("Retriev")
    // Get signer information
    const accounts = await ethers.getSigners()
    const signer = accounts[0]
    console.log("Using account:", signer.address)
    console.log("Contract address:", contractAddr)
    const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
    for (const provider of configs.providers) {
        console.log(`Adding provider ${provider.address} to protocol..`)
        const isProvider = await RetrievContract.providers(provider.address)
        console.log("Is provider?", isProvider)
        if (isProvider.active) {
            console.log("Provider already added")
            continue
        }
        const tx = await RetrievContract.setProviderStatus(
            provider.address,
            true,
            provider.endpoint
        )
        console.log("Waiting at", tx.hash)
        const receipt = await tx.wait()
        console.log("Confirmation arrived:", receipt)
    }
})

module.exports = {}
