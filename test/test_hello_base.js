const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HelloBase", function () {
  let hello;
  let owner, addr1, addr2;

  const GREETING = "gm Base!";

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const HelloBase = await ethers.getContractFactory("HelloBase");
    hello = await HelloBase.deploy(GREETING);
    await hello.waitForDeployment();
  });

  // ── Deployment ───────────────────────────────────────────────────
  describe("Deployment", function () {
    it("should set the initial message", async function () {
      expect(await hello.message()).to.equal(GREETING);
    });

    it("should record the deployer as owner", async function () {
      expect(await hello.owner()).to.equal(owner.address);
    });

    it("should set deployTime within a reasonable range", async function () {
      const deployTime = await hello.deployTime();
      const now = Math.floor(Date.now() / 1000);
      expect(deployTime).to.be.closeTo(now, 60);
    });

    it("should revert on empty message", async function () {
      const HelloBase = await ethers.getContractFactory("HelloBase");
      await expect(HelloBase.deploy(""))
        .to.be.revertedWithCustomError(hello, "HelloBase__EmptyMessage");
    });
  });

  // ── getInfo ──────────────────────────────────────────────────────
  describe("getInfo", function () {
    it("should return message, owner, and deployTime", async function () {
      const [msg, own, time] = await hello.getInfo();
      expect(msg).to.equal(GREETING);
      expect(own).to.equal(owner.address);
      expect(time).to.equal(await hello.deployTime());
    });
  });

  // ── setMessage ───────────────────────────────────────────────────
  describe("setMessage", function () {
    it("should update the message", async function () {
      const tx = await hello.setMessage("gm gm!");
      await tx.wait();

      expect(await hello.message()).to.equal("gm gm!");
    });

    it("should emit MessageUpdated with old and new values", async function () {
      const oldMsg = GREETING;
      const newMsg = "gm gm!";

      await expect(hello.setMessage(newMsg))
        .to.emit(hello, "MessageUpdated")
        .withArgs(owner.address, oldMsg, newMsg);
    });

    it("should revert when called by non-owner", async function () {
      await expect(hello.connect(addr1).setMessage("nope"))
        .to.be.revertedWithCustomError(hello, "HelloBase__Unauthorized")
        .withArgs(addr1.address, owner.address);
    });

    it("should revert on empty message", async function () {
      await expect(hello.setMessage(""))
        .to.be.revertedWithCustomError(hello, "HelloBase__EmptyMessage");
    });

    it("should allow multiple updates", async function () {
      await hello.setMessage("update 1");
      expect(await hello.message()).to.equal("update 1");

      await hello.setMessage("update 2");
      expect(await hello.message()).to.equal("update 2");

      await hello.setMessage("update 3");
      expect(await hello.message()).to.equal("update 3");
    });

    it("should emit MessageUpdated on each update", async function () {
      await expect(hello.setMessage("round 2"))
        .to.emit(hello, "MessageUpdated")
        .withArgs(owner.address, GREETING, "round 2");

      await expect(hello.setMessage("round 3"))
        .to.emit(hello, "MessageUpdated")
        .withArgs(owner.address, "round 2", "round 3");
    });

    it("should emit events with indexed fields for off-chain filtering", async function () {
      const tx = await hello.setMessage("gm gm!");
      const receipt = await tx.wait();

      // Verify event signature
      const event = receipt.logs[0];
      const iface = new ethers.Interface([
        "event MessageUpdated(address indexed updater, string indexed oldMessage, string indexed newMessage)",
      ]);
      const parsed = iface.parseLog({
        topics: event.topics,
        data: event.data,
      });

      expect(parsed.name).to.equal("MessageUpdated");
      expect(parsed.args.updater).to.equal(owner.address);
    });
  });

  // ── Access Control ───────────────────────────────────────────────
  describe("Access Control", function () {
    it("should only allow owner to call setMessage", async function () {
      const signers = [addr1, addr2];
      for (const signer of signers) {
        await expect(hello.connect(signer).setMessage("hack"))
          .to.be.revertedWithCustomError(hello, "HelloBase__Unauthorized")
          .withArgs(signer.address, owner.address);
      }
    });

    it("should retain owner after message updates", async function () {
      await hello.setMessage("still me");
      expect(await hello.owner()).to.equal(owner.address);
    });
  });

  // ── Edge Cases ───────────────────────────────────────────────────
  describe("Edge Cases", function () {
    it("should handle very long messages", async function () {
      const longMsg = "A".repeat(10000);
      await hello.setMessage(longMsg);
      expect(await hello.message()).to.equal(longMsg);
      expect((await hello.message()).length).to.equal(10000);
    });

    it("should handle special characters and emoji", async function () {
      const special = "Hello 🌍! Café ñoño 中文 日本語 👋🔥";
      await hello.setMessage(special);
      expect(await hello.message()).to.equal(special);
    });

    it("should handle single-character message", async function () {
      await hello.setMessage("!");
      expect(await hello.message()).to.equal("!");
    });
  });
});
