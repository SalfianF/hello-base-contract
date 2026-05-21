const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  const HelloBase = await hre.ethers.getContractFactory("HelloBase");
  const hello = await HelloBase.deploy("Hello Base! Built on Ethereum 🛡️");
  await hello.waitForDeployment();
  console.log("HelloBase deployed to:", await hello.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
