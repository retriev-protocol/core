const fs = require("fs")
const path = require("path")

function saveMetadata() {
    const deployment = fs.readFileSync(
        path.join(__dirname, "..", "deployments", "calibrationnet", "Retriev.json"),
        "utf8"
    )
    const metadata = JSON.parse(JSON.parse(deployment).metadata)
    fs.writeFileSync(
        path.join(__dirname, "..", "deployments", "calibrationnet", "metadata.json"),
        JSON.stringify(metadata, null, 4)
    )
    console.log(metadata)
}

saveMetadata()
