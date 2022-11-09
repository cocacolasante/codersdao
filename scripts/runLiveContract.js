const hre = require("hardhat");

const CODERS_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
const deployerAccount = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

async function main() {

    const CodersNFT = await hre.ethers.getContractAt("CodersNFT", CODERS_ADDRESS)
    console.log(`Contract Fetched from ${CodersNFT.address}`)


  
    let txn = await CodersNFT.connect(deployerAccount).unpauseContract()
    await txn.wait()
    console.log("----------------------")
  
  
  
  }
  
  
  
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  