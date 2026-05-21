const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BaseNFT", function () {
  let nft, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const BaseNFT = await ethers.getContractFactory("BaseNFT");
    nft = await BaseNFT.deploy("BaseNFT", "BNFT", "https://base.example.com/nft/");
    await nft.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set correct name, symbol and base URI", async function () {
      expect(await nft.name()).to.equal("BaseNFT");
      expect(await nft.symbol()).to.equal("BNFT");
      expect(await nft.baseURI()).to.equal("https://base.example.com/nft/");
    });

    it("Should start with token ID 0", async function () {
      expect(await nft.nextTokenId()).to.equal(0);
    });

    it("Should set owner correctly", async function () {
      expect(await nft.owner()).to.equal(owner.address);
    });
  });

  describe("Minting", function () {
    it("Should mint sequentially from ID 0", async function () {
      await nft.mint(addr1.address);
      expect(await nft.ownerOf(0)).to.equal(addr1.address);
      expect(await nft.nextTokenId()).to.equal(1);
    });

    it("Should increment token IDs on each mint", async function () {
      await nft.mint(addr1.address);
      await nft.mint(addr2.address);
      expect(await nft.ownerOf(0)).to.equal(addr1.address);
      expect(await nft.ownerOf(1)).to.equal(addr2.address);
      expect(await nft.nextTokenId()).to.equal(2);
    });

    it("Should reject mint from non-owner", async function () {
      await expect(
        nft.connect(addr1).mint(addr1.address)
      ).to.be.revertedWithCustomError(nft, "OwnableUnauthorizedAccount");
    });

    it("Should return correct token URI", async function () {
      await nft.mint(addr1.address);
      expect(await nft.tokenURI(0)).to.equal("https://base.example.com/nft/0");
    });
  });

  describe("Base URI", function () {
    it("Should allow owner to update base URI", async function () {
      await nft.setBaseURI("https://new-uri.example.com/");
      expect(await nft.baseURI()).to.equal("https://new-uri.example.com/");
    });

    it("Should reject base URI update from non-owner", async function () {
      await expect(
        nft.connect(addr1).setBaseURI("https://evil.example.com/")
      ).to.be.revertedWithCustomError(nft, "OwnableUnauthorizedAccount");
    });
  });

  describe("Transfers", function () {
    beforeEach(async function () {
      await nft.mint(addr1.address);
    });

    it("Should allow token holder to transfer", async function () {
      await nft.connect(addr1).transferFrom(addr1.address, addr2.address, 0);
      expect(await nft.ownerOf(0)).to.equal(addr2.address);
    });

    it("Should reject transfer by non-owner", async function () {
      await expect(
        nft.transferFrom(addr1.address, addr2.address, 0)
      ).to.be.revertedWithCustomError(nft, "ERC721InsufficientApproval");
    });
  });
});
