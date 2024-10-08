const fs = require("fs")

task("add-referees", "Add referees to protocol").setAction(async (taskArgs) => {
    const network = await ethers.provider.getNetwork()
    console.log("Network:", network.name)
    const configs = JSON.parse(fs.readFileSync(`configs/${network.name}.json`))

    const contractAddr = configs.contract_address
    const Retriev = await ethers.getContractFactory("Retriev")
    // Get signer information
    const accounts = await ethers.getSigners()
    const signer = accounts[0]

    const RetrievContract = new ethers.Contract(contractAddr, Retriev.interface, signer)
    for (const referee of configs.referees) {
        console.log(`Adding referee ${referee.address} to protocol..`)
        const isReferee = await RetrievContract.referees(referee.address)
        if (isReferee.active) {
            console.log("Referee already added")
            continue
        }
        const tx = await RetrievContract.setRefereeStatus(referee.address, true, referee.endpoint)
        console.log("Waiting at", tx.hash)
        const receipt = await tx.wait()
        console.log("Confirmation arrived:", receipt)
    }
})

module.exports = {}
