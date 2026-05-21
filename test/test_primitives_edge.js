const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleStorage Edge Cases", function () {
  async function deployStorage() {
    const Storage = await ethers.getContractFactory("SimpleStorage");
    const store = await Storage.deploy();
    await store.waitForDeployment();
    return store;
  }

  it("Should store max uint256 value", async function () {
    const store = await deployStorage();
    const maxUint = ethers.MaxUint256;
    await store.store(maxUint);
    expect(await store.retrieve()).to.equal(maxUint);
  });

  it("Should store zero", async function () {
    const store = await deployStorage();
    await store.store(0);
    expect(await store.retrieve()).to.equal(0);
  });

  it("Should handle multiple stores in sequence", async function () {
    const store = await deployStorage();
    await store.store(10);
    expect(await store.retrieve()).to.equal(10);
    await store.store(20);
    expect(await store.retrieve()).to.equal(20);
    await store.store(30);
    expect(await store.retrieve()).to.equal(30);
  });
});

describe("Counter Edge Cases", function () {
  async function deployCounter() {
    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    return counter;
  }

  it("Should revert on decrement at zero", async function () {
    const counter = await deployCounter();
    await expect(counter.decrement()).to.be.revertedWith(
      "Counter: cannot go below zero"
    );
  });

  it("Should handle multiple increments", async function () {
    const counter = await deployCounter();
    for (let i = 1; i <= 5; i++) {
      await counter.increment();
      expect(await counter.count()).to.equal(i);
    }
  });

  it("Should reset to zero", async function () {
    const counter = await deployCounter();
    await counter.increment();
    await counter.increment();
    await counter.increment();
    expect(await counter.count()).to.equal(3);
    await counter.reset();
    expect(await counter.count()).to.equal(0);
  });
});

describe("Calculator Edge Cases", function () {
  async function deployCalculator() {
    const Calc = await ethers.getContractFactory("Calculator");
    const calc = await Calc.deploy();
    await calc.waitForDeployment();
    return calc;
  }

  it("Should revert on division by zero", async function () {
    const calc = await deployCalculator();
    await expect(calc.div.staticCall(5, 0)).to.be.revertedWith(
      "Calculator: division by zero"
    );
  });

  it("Should revert on subtraction underflow", async function () {
    const calc = await deployCalculator();
    await expect(calc.sub.staticCall(0, 1)).to.be.revertedWith(
      "Calculator: underflow"
    );
  });

  it("Should revert on addition overflow", async function () {
    const calc = await deployCalculator();
    const maxUint = ethers.MaxUint256;
    // Adding 1 to maxUint256 causes overflow in Solidity 0.8+
    await expect(calc.add.staticCall(maxUint, 1)).to.be.revertedWithPanic();
  });

  it("Should revert on multiplication overflow", async function () {
    const calc = await deployCalculator();
    const maxUint = ethers.MaxUint256;
    // Multiplying by 2 causes overflow
    await expect(calc.mul.staticCall(maxUint, 2)).to.be.revertedWithPanic();
  });

  it("Should handle large numbers correctly", async function () {
    const calc = await deployCalculator();
    const large = ethers.parseEther("1000000");
    const result = await calc.add.staticCall(large, large);
    expect(result).to.equal(large + large);
  });
});
