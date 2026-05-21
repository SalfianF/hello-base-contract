const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  const BaseToken = await hre.ethers.getContractFactory("BaseToken");
  const token = await BaseToken.deploy("BaseToken", "BTK");
  await token.waitForDeployment();
  console.log("BaseToken deployed to:", await token.getAddress());

  const TokenSwap = await hre.ethers.getContractFactory("TokenSwap");
  const swap = await TokenSwap.deploy();
  await swap.waitForDeployment();
  console.log("TokenSwap deployed to:", await swap.getAddress());

  const Vault = await hre.ethers.getContractFactory("Vault");
  const vault = await Vault.deploy();
  await vault.waitForDeployment();
  console.log("Vault deployed to:", await vault.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
