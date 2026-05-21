// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BaseNFT
 * @notice Base-native ERC721 NFT with sequential minting and configurable base URI
 * @dev Uses OpenZeppelin's ERC721 and Ownable for access control
 */
contract BaseNFT is ERC721, Ownable {
    uint256 public nextTokenId;
    string public baseURI;

    /**
     * @notice Create a new NFT collection
     * @param name_ Full collection name
     * @param symbol_ Collection ticker symbol
     * @param uri_ Base URI for token metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        baseURI = uri_;
    }

    /**
     * @notice Mint a new token to a recipient
     * @dev Only callable by owner, assigns the next sequential token ID
     * @param to Address receiving the NFT
     */
    function mint(address to) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        nextTokenId++;
    }

    /**
     * @notice Return the base URI for token metadata
     * @dev Overrides ERC721._baseURI
     * @return string The current base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Update the base URI for all tokens
     * @dev Only callable by owner
     * @param uri_ The new base URI string
     */
    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }
}
