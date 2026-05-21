const { expect } = require("chai");

describe("Greeter", function () {
  it("Should greet correctly", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("GM Base!");
    await greeter.waitForDeployment();
    expect(await greeter.greet()).to.equal("GM Base!");
  });

  it("Should update greeting", async function () {
    const [owner] = await ethers.getSigners();
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello");
    await greeter.waitForDeployment();
    await greeter.setGreeting("GM!");
    expect(await greeter.greet()).to.equal("GM!");
  });

  it("Should show owner greeting", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("WAGMI");
    await greeter.waitForDeployment();
    expect(await greeter.ownerGreet()).to.equal("Owner says: WAGMI");
  });
});
