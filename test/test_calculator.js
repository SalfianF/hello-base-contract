const { expect } = require("chai");

describe("Calculator", function () {
  it("Should add correctly", async function () {
    const Calc = await ethers.getContractFactory("Calculator");
    const calc = await Calc.deploy();
    await calc.waitForDeployment();
    expect(await calc.add.staticCall(2, 3)).to.equal(5);
  });

  it("Should subtract correctly", async function () {
    const Calc = await ethers.getContractFactory("Calculator");
    const calc = await Calc.deploy();
    await calc.waitForDeployment();
    expect(await calc.sub.staticCall(5, 3)).to.equal(2);
  });

  it("Should multiply correctly", async function () {
    const Calc = await ethers.getContractFactory("Calculator");
    const calc = await Calc.deploy();
    await calc.waitForDeployment();
    expect(await calc.mul.staticCall(4, 5)).to.equal(20);
  });

  it("Should divide correctly", async function () {
    const Calc = await ethers.getContractFactory("Calculator");
    const calc = await Calc.deploy();
    await calc.waitForDeployment();
    expect(await calc.div.staticCall(10, 3)).to.equal(3);
  });

  it("Should revert on division by zero", async function () {
    const Calc = await ethers.getContractFactory("Calculator");
    const calc = await Calc.deploy();
    await calc.waitForDeployment();
    await expect(calc.div.staticCall(5, 0)).to.be.revertedWith("division by zero");
  });
});
