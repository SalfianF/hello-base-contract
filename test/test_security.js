const { expect } = require("chai");
const { ethers } = require("hardhat");

// ─── Vault Reentrancy ──────────────────────────────────────────────
describe("Vault — Reentrancy Protection", function () {
  let vault;
  let attacker;
  let owner, attackerSigner;

  beforeEach(async function () {
    [owner, attackerSigner] = await ethers.getSigners();

    const Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy();
    await vault.waitForDeployment();
  });

  it("should prevent reentrancy via ReentrancyAttacker", async function () {
    // Deploy attacker
    const ReentrancyAttacker = await ethers.getContractFactory("ReentrancyAttacker");
    attacker = await ReentrancyAttacker.deploy(await vault.getAddress());
    await attacker.waitForDeployment();

    // Fund vault first
    await owner.sendTransaction({
      to: await vault.getAddress(),
      value: ethers.parseEther("10"),
    });

    // Attacker deposits then tries to re-enter on withdraw
    await expect(
      attacker.connect(attackerSigner).attack({ value: ethers.parseEther("1") })
    ).to.be.revertedWith("Vault: withdrawal failed");

    // Vault balance should remain intact
    expect(await ethers.provider.getBalance(await vault.getAddress())).to.equal(
      ethers.parseEther("10")
    );
  });

  it("should handle multiple deposits and withdrawals safely", async function () {
    const amounts = [
      ethers.parseEther("1"),
      ethers.parseEther("5"),
      ethers.parseEther("0.5"),
    ];

    for (const amt of amounts) {
      await owner.sendTransaction({
        to: await vault.getAddress(),
        value: amt,
      });
    }

    const total = amounts.reduce((a, b) => a + b, 0n);
    expect(await vault.balanceOf(owner.address)).to.equal(total);

    // Withdraw partial
    await vault.withdraw(ethers.parseEther("3"));
    expect(await vault.balanceOf(owner.address)).to.equal(total - ethers.parseEther("3"));
  });
});

// ─── TokenSwap Security ────────────────────────────────────────────
describe("TokenSwap — Cancel, Deadline & Access Control", function () {
  let tokenIn, tokenOut;
  let swap;
  let maker, filler, other;

  beforeEach(async function () {
    [maker, filler, other] = await ethers.getSigners();

    const ERC20 = await ethers.getContractFactory("BaseToken");
    tokenIn = await ERC20.deploy("TokenIn", "TIN");
    await tokenIn.waitForDeployment();
    tokenOut = await ERC20.deploy("TokenOut", "TOUT");
    await tokenOut.waitForDeployment();

    const TokenSwap = await ethers.getContractFactory("TokenSwap");
    swap = await TokenSwap.deploy();
    await swap.waitForDeployment();

    // Fund maker with tokens
    await tokenIn.transfer(maker.address, ethers.parseEther("1000"));
    await tokenOut.transfer(filler.address, ethers.parseEther("1000"));

    // Approve
    await tokenIn.connect(maker).approve(await swap.getAddress(), ethers.parseEther("1000"));
    await tokenOut.connect(filler).approve(await swap.getAddress(), ethers.parseEther("1000"));
  });

  it("should allow maker to cancel an unfilled order and reclaim tokens", async function () {
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    await swap.connect(maker).createOrder(
      await tokenIn.getAddress(),
      await tokenOut.getAddress(),
      ethers.parseEther("10"),
      ethers.parseEther("5"),
      deadline
    );

    const makerBalBefore = await tokenIn.balanceOf(maker.address);

    await swap.connect(maker).cancelOrder(0);

    expect(await tokenIn.balanceOf(maker.address)).to.equal(makerBalBefore + ethers.parseEther("10"));
    const order = await swap.getOrder(0);
    expect(order.cancelled).to.be.true;
  });

  it("should revert fill for expired orders", async function () {
    const deadline = Math.floor(Date.now() / 1000) - 1; // Already expired
    await swap.connect(maker).createOrder(
      await tokenIn.getAddress(),
      await tokenOut.getAddress(),
      ethers.parseEther("10"),
      ethers.parseEther("5"),
      deadline
    );

    // Advance time if possible (Hardhat)
    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine", []);

    await expect(
      swap.connect(filler).fillOrder(0)
    ).to.be.revertedWith("TokenSwap: order expired");
  });

  it("should reject filling own order", async function () {
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    await swap.connect(maker).createOrder(
      await tokenIn.getAddress(),
      await tokenOut.getAddress(),
      ethers.parseEther("10"),
      ethers.parseEther("5"),
      deadline
    );

    await expect(
      swap.connect(maker).fillOrder(0)
    ).to.be.revertedWith("TokenSwap: cannot fill own order");
  });

  it("should not allow non-maker to cancel an order", async function () {
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    await swap.connect(maker).createOrder(
      await tokenIn.getAddress(),
      await tokenOut.getAddress(),
      ethers.parseEther("10"),
      ethers.parseEther("5"),
      deadline
    );

    await expect(
      swap.connect(other).cancelOrder(0)
    ).to.be.revertedWith("TokenSwap: only maker");
  });

  it("should reject createOrder with past deadline", async function () {
    const pastDeadline = Math.floor(Date.now() / 1000) - 100;

    await expect(
      swap.connect(maker).createOrder(
        await tokenIn.getAddress(),
        await tokenOut.getAddress(),
        ethers.parseEther("10"),
        ethers.parseEther("5"),
        pastDeadline
      )
    ).to.be.revertedWith("TokenSwap: deadline in the past");
  });
});

// ─── Ownable2Step (Greeter) ────────────────────────────────────────
describe("Greeter — Ownable2Step Transfer", function () {
  it("should transfer ownership in two steps (propose + accept)", async function () {
    const [owner, newOwner] = await ethers.getSigners();

    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello!");
    await greeter.waitForDeployment();

    expect(await greeter.owner()).to.equal(owner.address);

    // Step 1: current owner starts transfer
    await greeter.connect(owner).transferOwnership(newOwner.address);
    expect(await greeter.pendingOwner()).to.equal(newOwner.address);
    expect(await greeter.owner()).to.equal(owner.address); // Not yet transferred

    // Step 2: new owner accepts
    await greeter.connect(newOwner).acceptOwnership();
    expect(await greeter.owner()).to.equal(newOwner.address);
  });

  it("should not allow setGreeting from non-owner after transfer", async function () {
    const [owner, newOwner] = await ethers.getSigners();

    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello!");
    await greeter.waitForDeployment();

    // Transfer fully
    await greeter.connect(owner).transferOwnership(newOwner.address);
    await greeter.connect(newOwner).acceptOwnership();

    // Old owner can no longer set greeting
    await expect(
      greeter.connect(owner).setGreeting("hacked")
    ).to.be.revertedWith("OwnableUnauthorizedAccount");
  });

  it("should revert on empty greeting constructor", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    await expect(
      Greeter.deploy("")
    ).to.be.revertedWith("Greeter: empty greeting");
  });
});

// ─── BridgingToBase — Ownable2Step ─────────────────────────────────
describe("BridgingToBase — Ownable2Step", function () {
  it("should transfer ownership in two steps", async function () {
    const [owner, newOwner] = await ethers.getSigners();

    const Bridge = await ethers.getContractFactory("BridgingToBase");
    const bridge = await Bridge.deploy("Bridged!");
    await bridge.waitForDeployment();

    expect(await bridge.owner()).to.equal(owner.address);

    // Propose
    await bridge.connect(owner).transferOwnership(newOwner.address);
    expect(await bridge.pendingOwner()).to.equal(newOwner.address);

    // Accept
    await bridge.connect(newOwner).acceptOwnership();
    expect(await bridge.owner()).to.equal(newOwner.address);
  });

  it("should revert on empty message in constructor", async function () {
    const Bridge = await ethers.getContractFactory("BridgingToBase");
    await expect(
      Bridge.deploy("")
    ).to.be.revertedWith("BridgingToBase: empty message");
  });
});

// ─── MultiSig — Signer Management ──────────────────────────────────
describe("MultiSig — Signer Management & Revoke", function () {
  let msig;
  let signers;

  beforeEach(async function () {
    signers = await ethers.getSigners();
    const initialSigners = [signers[0].address, signers[1].address, signers[2].address];
    const MultiSig = await ethers.getContractFactory("MultiSig");
    msig = await MultiSig.deploy(initialSigners, 2);
    await msig.waitForDeployment();
  });

  it("should add a new signer", async function () {
    const newSigner = signers[3].address;
    await msig.connect(signers[0]).addSigner(newSigner);
    expect(await msig.isSigner(newSigner)).to.be.true;
    expect(await msig.signerCount()).to.equal(4);
  });

  it("should remove a signer and enforce minimum threshold", async function () {
    const signerToRemove = signers[2].address;

    // Add a 4th signer first so removal doesn't break threshold
    await msig.connect(signers[0]).addSigner(signers[3].address);

    await msig.connect(signers[0]).removeSigner(signerToRemove);
    expect(await msig.isSigner(signerToRemove)).to.be.false;
    expect(await msig.signerCount()).to.equal(3);
  });

  it("should prevent removal if it would go below required", async function () {
    await expect(
      msig.connect(signers[0]).removeSigner(signers[2].address)
    ).to.be.revertedWith("MultiSig: would fall below required");
  });

  it("should allow revoking a confirmation before execution", async function () {
    // Submit tx
    await msig.connect(signers[0]).submitTransaction(signers[9].address, 0, "0x");

    // Confirm by second signer
    await msig.connect(signers[1]).confirmTransaction(0);

    // Revoke by second signer
    await msig.connect(signers[1]).revokeConfirmation(0);

    // Now only 1 confirmation, should not execute
    await expect(
      msig.executeTransaction(0)
    ).to.be.revertedWith("MultiSig: not enough confirmations");
  });

  it("should reject duplicate signers in constructor", async function () {
    const MultiSig = await ethers.getContractFactory("MultiSig");
    await expect(
      MultiSig.deploy([signers[0].address, signers[0].address], 1)
    ).to.be.revertedWith("MultiSig: duplicate signer");
  });

  it("should reject zero-address signer", async function () {
    const MultiSig = await ethers.getContractFactory("MultiSig");
    await expect(
      MultiSig.deploy([ethers.ZeroAddress], 1)
    ).to.be.revertedWith("MultiSig: zero address");
  });
});
