// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseNFT
 * @notice Interface for BaseNFT contract
 * @dev Defines the external functions for a Base-native ERC721 NFT with sequential minting
 */
interface IBaseNFT {
    /**
     * @notice Get the next token ID to be minted
     * @return uint256 The next token ID
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @notice Get the base URI for token metadata
     * @return string The current base URI
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Mint a new token to a recipient
     * @dev Only callable by owner, assigns the next sequential token ID
     * @param to Address receiving the NFT
     */
    function mint(address to) external;

    /**
     * @notice Update the base URI for all tokens
     * @dev Only callable by owner
     * @param uri_ The new base URI string
     */
    function setBaseURI(string memory uri_) external;
}
