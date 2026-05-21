const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  // Primitives
  const SimpleStorage = await hre.ethers.getContractFactory("SimpleStorage");
  const storage = await SimpleStorage.deploy();
  await storage.waitForDeployment();
  console.log("SimpleStorage:", await storage.getAddress());

  const Counter = await hre.ethers.getContractFactory("Counter");
  const counter = await Counter.deploy();
  await counter.waitForDeployment();
  console.log("Counter:", await counter.getAddress());

  // Utilities
  const Calculator = await hre.ethers.getContractFactory("Calculator");
  const calc = await Calculator.deploy();
  await calc.waitForDeployment();
  console.log("Calculator:", await calc.getAddress());

  const Greeter = await hre.ethers.getContractFactory("Greeter");
  const greeter = await Greeter.deploy("gm, Base!");
  await greeter.waitForDeployment();
  console.log("Greeter:", await greeter.getAddress());

  // DeFi
  const BaseToken = await hre.ethers.getContractFactory("BaseToken");
  const token = await BaseToken.deploy("BaseToken", "BTK");
  await token.waitForDeployment();
  console.log("BaseToken:", await token.getAddress());

  const TokenSwap = await hre.ethers.getContractFactory("TokenSwap");
  const swap = await TokenSwap.deploy();
  await swap.waitForDeployment();
  console.log("TokenSwap:", await swap.getAddress());

  const Vault = await hre.ethers.getContractFactory("Vault");
  const vault = await Vault.deploy();
  await vault.waitForDeployment();
  console.log("Vault:", await vault.getAddress());

  // NFT & Governance
  const BaseNFT = await hre.ethers.getContractFactory("BaseNFT");
  const nft = await BaseNFT.deploy("BaseNFT", "BNFT", "https://api.base.com/metadata/");
  await nft.waitForDeployment();
  console.log("BaseNFT:", await nft.getAddress());

  const MultiSig = await hre.ethers.getContractFactory("MultiSig");
  const msig = await MultiSig.deploy([deployer.address], 1);
  await msig.waitForDeployment();
  console.log("MultiSig:", await msig.getAddress());

  // Bridge & Hello
  const BridgingToBase = await hre.ethers.getContractFactory("BridgingToBase");
  const bridge = await BridgingToBase.deploy("Connected to Base! Bridged 🌉");
  await bridge.waitForDeployment();
  console.log("BridgingToBase:", await bridge.getAddress());

  const HelloBase = await hre.ethers.getContractFactory("HelloBase");
  const hello = await HelloBase.deploy("Hello Base! Built on Ethereum 🛡️");
  await hello.waitForDeployment();
  console.log("HelloBase:", await hello.getAddress());

  console.log("\n✅ All 11 contracts deployed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
