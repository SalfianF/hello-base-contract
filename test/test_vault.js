const { expect } = require("chai");

describe("Vault", function () {
  it("Should accept deposits", async function () {
    const [owner] = await ethers.getSigners();
    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy();
    await vault.waitForDeployment();
    await vault.deposit({ value: ethers.parseEther("1.0") });
    expect(await vault.balanceOf(owner.address)).to.equal(ethers.parseEther("1.0"));
  });

  it("Should allow withdrawal", async function () {
    const [owner] = await ethers.getSigners();
    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy();
    await vault.waitForDeployment();
    await vault.deposit({ value: ethers.parseEther("2.0") });
    await vault.withdraw(ethers.parseEther("1.0"));
    expect(await vault.balanceOf(owner.address)).to.equal(ethers.parseEther("1.0"));
  });
});
