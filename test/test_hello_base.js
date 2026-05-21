const { expect } = require("chai");

describe("HelloBase", function () {
  it("Should deploy with correct message", async function () {
    const HelloBase = await ethers.getContractFactory("HelloBase");
    const hello = await HelloBase.deploy("Hello Base!");
    await hello.waitForDeployment();
    expect(await hello.message()).to.equal("Hello Base!");
  });

  it("Should update message", async function () {
    const [owner] = await ethers.getSigners();
    const HelloBase = await ethers.getContractFactory("HelloBase");
    const hello = await HelloBase.deploy("Hi");
    await hello.waitForDeployment();
    await hello.setMessage("Updated!");
    expect(await hello.message()).to.equal("Updated!");
  });

  it("Should reject non-owner", async function () {
    const [, addr1] = await ethers.getSigners();
    const HelloBase = await ethers.getContractFactory("HelloBase");
    const hello = await HelloBase.deploy("Hi");
    await hello.waitForDeployment();
    await expect(hello.connect(addr1).setMessage("nope")).to.be.revertedWith("Only owner");
  });
});
