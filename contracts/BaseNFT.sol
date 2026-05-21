// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseNFT is ERC721, Ownable {
    uint256 public nextTokenId;
    string public baseURI;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_) Ownable(msg.sender) {
        baseURI = uri_;
    }

    function mint(address to) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        nextTokenId++;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }
}