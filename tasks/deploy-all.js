const { task } = require("hardhat/config");

task("deploy:all", "Deploy all 11 contracts to Base")
  .setAction(async (_, hre) => {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    console.log("Balance:", hre.ethers.formatEther(
      await hre.ethers.provider.getBalance(deployer.address)
    ), "ETH\n");

    const SimpleStorage = await hre.ethers.getContractFactory("SimpleStorage");
    console.log("SimpleStorage:", await (await SimpleStorage.deploy()).waitForDeployment().then(c => c.getAddress()));

    const Counter = await hre.ethers.getContractFactory("Counter");
    console.log("Counter:", await (await Counter.deploy()).waitForDeployment().then(c => c.getAddress()));

    const Calculator = await hre.ethers.getContractFactory("Calculator");
    console.log("Calculator:", await (await Calculator.deploy()).waitForDeployment().then(c => c.getAddress()));

    const Greeter = await hre.ethers.getContractFactory("Greeter");
    console.log("Greeter:", await (await Greeter.deploy("gm, Base!")).waitForDeployment().then(c => c.getAddress()));

    const BaseToken = await hre.ethers.getContractFactory("BaseToken");
    console.log("BaseToken:", await (await BaseToken.deploy("BaseToken", "BTK")).waitForDeployment().then(c => c.getAddress()));

    const TokenSwap = await hre.ethers.getContractFactory("TokenSwap");
    console.log("TokenSwap:", await (await TokenSwap.deploy()).waitForDeployment().then(c => c.getAddress()));

    const Vault = await hre.ethers.getContractFactory("Vault");
    console.log("Vault:", await (await Vault.deploy()).waitForDeployment().then(c => c.getAddress()));

    const BaseNFT = await hre.ethers.getContractFactory("BaseNFT");
    console.log("BaseNFT:", await (await BaseNFT.deploy("BaseNFT", "BNFT", "https://api.base.com/metadata/")).waitForDeployment().then(c => c.getAddress()));

    const MultiSig = await hre.ethers.getContractFactory("MultiSig");
    console.log("MultiSig:", await (await MultiSig.deploy([], 0)).waitForDeployment().then(c => c.getAddress()));

    const BridgingToBase = await hre.ethers.getContractFactory("BridgingToBase");
    console.log("BridgingToBase:", await (await BridgingToBase.deploy("Connected to Base! Bridged 🌉")).waitForDeployment().then(c => c.getAddress()));

    const HelloBase = await hre.ethers.getContractFactory("HelloBase");
    console.log("HelloBase:", await (await HelloBase.deploy("Hello Base! Built on Ethereum 🛡️")).waitForDeployment().then(c => c.getAddress()));

    console.log("\n✅ All 11 contracts deployed!");
  });

task("deploy:primitives", "Deploy SimpleStorage and Counter")
  .setAction(async (_, hre) => {
    const SimpleStorage = await hre.ethers.getContractFactory("SimpleStorage");
    const storage = await SimpleStorage.deploy();
    await storage.waitForDeployment();
    console.log("SimpleStorage:", await storage.getAddress());

    const Counter = await hre.ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    console.log("Counter:", await counter.getAddress());
  });

task("deploy:utilities", "Deploy Calculator and Greeter")
  .setAction(async (_, hre) => {
    const Calculator = await hre.ethers.getContractFactory("Calculator");
    const calc = await Calculator.deploy();
    await calc.waitForDeployment();
    console.log("Calculator:", await calc.getAddress());

    const Greeter = await hre.ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("gm, Base!");
    await greeter.waitForDeployment();
    console.log("Greeter:", await greeter.getAddress());
  });

task("deploy:defi", "Deploy BaseToken, TokenSwap, and Vault")
  .setAction(async (_, hre) => {
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
  });

task("deploy:nft", "Deploy BaseNFT and MultiSig")
  .setAction(async (_, hre) => {
    const BaseNFT = await hre.ethers.getContractFactory("BaseNFT");
    const nft = await BaseNFT.deploy("BaseNFT", "BNFT", "https://api.base.com/metadata/");
    await nft.waitForDeployment();
    console.log("BaseNFT:", await nft.getAddress());

    const MultiSig = await hre.ethers.getContractFactory("MultiSig");
    const msig = await MultiSig.deploy([], 0);
    await msig.waitForDeployment();
    console.log("MultiSig:", await msig.getAddress());
  });

task("deploy:bridge", "Deploy BridgingToBase")
  .setAction(async (_, hre) => {
    const BridgingToBase = await hre.ethers.getContractFactory("BridgingToBase");
    const bridge = await BridgingToBase.deploy("Connected to Base! Bridged 🌉");
    await bridge.waitForDeployment();
    console.log("BridgingToBase:", await bridge.getAddress());
  });

task("deploy:hello", "Deploy HelloBase")
  .setAction(async (_, hre) => {
    const HelloBase = await hre.ethers.getContractFactory("HelloBase");
    const hello = await HelloBase.deploy("Hello Base! Built on Ethereum 🛡️");
    await hello.waitForDeployment();
    console.log("HelloBase:", await hello.getAddress());
  });
