const { expect } = require("chai");

describe("SimpleStorage", function () {
  it("Should store and retrieve value", async function () {
    const Storage = await ethers.getContractFactory("SimpleStorage");
    const store = await Storage.deploy();
    await store.waitForDeployment();
    await store.store(42);
    expect(await store.retrieve()).to.equal(42);
  });

  it("Should update value", async function () {
    const Storage = await ethers.getContractFactory("SimpleStorage");
    const store = await Storage.deploy();
    await store.waitForDeployment();
    await store.store(100);
    expect(await store.retrieve()).to.equal(100);
    await store.store(200);
    expect(await store.retrieve()).to.equal(200);
  });
});
