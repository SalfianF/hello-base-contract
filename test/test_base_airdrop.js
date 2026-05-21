const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BaseAirdrop", function () {
  let airdrop, token, owner, user1, user2;
  let merkleRoot, proof;

  before(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy a mock ERC20
    const MockToken = await ethers.getContractFactory("BaseToken");
    token = await MockToken.deploy("AirdropToken", "ADR");
    await token.waitForDeployment();
    await token.mint(owner.address, ethers.parseEther("1000000"));
  });

  beforeEach(async function () {
    // Build a simple Merkle tree with 2 leaves: user1(100) and user2(200)
    const leaf1 = ethers.solidityPackedKeccak256(
      ["address", "uint256"],
      [user1.address, ethers.parseEther("100")]
    );
    const leaf2 = ethers.solidityPackedKeccak256(
      ["address", "uint256"],
      [user2.address, ethers.parseEther("200")]
    );
    const leaves = [leaf1, leaf2].sort((a, b) => (a < b ? -1 : 1));

    // Merkle root = keccak256(leaf1 + leaf2)
    merkleRoot = ethers.solidityPackedKeccak256(
      ["bytes32", "bytes32"],
      [leaves[0], leaves[1]]
    );

    const claimEnd = Math.floor(Date.now() / 1000) + 86400; // 24h from now
    const BaseAirdrop = await ethers.getContractFactory("BaseAirdrop");
    airdrop = await BaseAirdrop.deploy(
      await token.getAddress(),
      merkleRoot,
      claimEnd
    );
    await airdrop.waitForDeployment();

    // Fund the airdrop contract
    await token.transfer(await airdrop.getAddress(), ethers.parseEther("1000"));

    // Build proof for user1
    proof = [leaves[1]];
  });

  describe("Deployment", function () {
    it("Should set correct owner, token and merkle root", async function () {
      expect(await airdrop.owner()).to.equal(owner.address);
      expect(await airdrop.token()).to.equal(await token.getAddress());
      expect(await airdrop.merkleRoot()).to.equal(merkleRoot);
    });
  });

  describe("Claiming", function () {
    it("Should allow valid claim", async function () {
      await airdrop.connect(user1).claim(ethers.parseEther("100"), proof);
      expect(await airdrop.hasClaimed(user1.address)).to.equal(true);
    });

    it("Should reject double claim", async function () {
      await airdrop.connect(user1).claim(ethers.parseEther("100"), proof);
      await expect(
        airdrop.connect(user1).claim(ethers.parseEther("100"), proof)
      ).to.be.revertedWith("BaseAirdrop: already claimed");
    });

    it("Should reject invalid proof", async function () {
      const badProof = [ethers.ZeroHash];
      await expect(
        airdrop.connect(user1).claim(ethers.parseEther("100"), badProof)
      ).to.be.revertedWith("BaseAirdrop: invalid proof");
    });
  });

  describe("Query functions", function () {
    it("Should return correct claim status", async function () {
      expect(await airdrop.hasClaimed(user1.address)).to.equal(false);
    });

    it("Should return active claim period", async function () {
      expect(await airdrop.isClaimActive()).to.equal(true);
    });
  });
});
