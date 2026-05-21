const { expect } = require("chai");

describe("Counter", function () {
  it("Should start at 0", async function () {
    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    expect(await counter.count()).to.equal(0);
  });

  it("Should increment", async function () {
    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    await counter.increment();
    expect(await counter.count()).to.equal(1);
  });

  it("Should decrement", async function () {
    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    await counter.increment();
    await counter.decrement();
    expect(await counter.count()).to.equal(0);
  });

  it("Should not go below zero", async function () {
    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    await expect(counter.decrement()).to.be.revertedWith("Counter: cannot go below zero");
  });
});
