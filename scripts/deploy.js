const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH");

  const HelloBase = await hre.ethers.getContractFactory("HelloBase");
  const contract = await HelloBase.deploy("Hello Base! Built on Ethereum 🛡️");

  await contract.waitForDeployment();
  const addr = await contract.getAddress();

  console.log("\n✅ HelloBase deployed to:", addr);
  console.log("🔗 Explorer: https://basescan.org/address/" + addr);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
