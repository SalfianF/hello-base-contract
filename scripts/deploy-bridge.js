const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  const BridgingToBase = await hre.ethers.getContractFactory("BridgingToBase");
  const bridge = await BridgingToBase.deploy("Connected to Base! Bridged 🌉");
  await bridge.waitForDeployment();
  console.log("BridgingToBase deployed to:", await bridge.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
