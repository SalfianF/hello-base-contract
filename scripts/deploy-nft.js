const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  const BaseNFT = await hre.ethers.getContractFactory("BaseNFT");
  const nft = await BaseNFT.deploy("BaseNFT", "BNFT", "https://api.base.com/metadata/");
  await nft.waitForDeployment();
  console.log("BaseNFT deployed to:", await nft.getAddress());

  const MultiSig = await hre.ethers.getContractFactory("MultiSig");
  const msig = await MultiSig.deploy([deployer.address], 1);
  await msig.waitForDeployment();
  console.log("MultiSig deployed to:", await msig.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
