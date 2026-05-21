const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  const Calculator = await hre.ethers.getContractFactory("Calculator");
  const calc = await Calculator.deploy();
  await calc.waitForDeployment();
  console.log("Calculator deployed to:", await calc.getAddress());

  const Greeter = await hre.ethers.getContractFactory("Greeter");
  const greeter = await Greeter.deploy("gm, Base!");
  await greeter.waitForDeployment();
  console.log("Greeter deployed to:", await greeter.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
