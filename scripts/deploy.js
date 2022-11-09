
const hre = require("hardhat");

async function main() {

  const nftContractFactory = await hre.ethers.getContractFactory("CodersNFT")
  const CodersNFT = await nftContractFactory.deploy()
  await CodersNFT.deployed()

  const deployer = await CodersNFT.admin()

  console.log(`Coders NFT Deployed to ${CodersNFT.address}`)
  console.log("----------------------")
  console.log(`Contract Deployed by ${deployer}`)



}




main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
