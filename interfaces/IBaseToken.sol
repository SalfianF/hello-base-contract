// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseToken
 * @notice Interface for BaseToken contract
 * @dev Defines the external functions for an ERC20 token with mint capabilities and pausable transfers
 */
interface IBaseToken {
    /**
     * @notice Emitted when tokens are minted
     * @param to Recipient address
     * @param amount Amount of tokens minted
     */
    event Minted(address indexed to, uint256 amount);

    /**
     * @notice Get the maximum token supply cap
     * @return uint256 The max supply (1 billion tokens)
     */
    function MAX_SUPPLY() external view returns (uint256);

    /**
     * @notice Mint new tokens
     * @dev Only callable by owner, respects MAX_SUPPLY cap
     * @param to Recipient address
     * @param amount Amount of tokens to mint (in wei)
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Pause all token transfers
     * @dev Only callable by owner, emergency use
     */
    function pause() external;

    /**
     * @notice Unpause token transfers
     * @dev Only callable by owner
     */
    function unpause() external;
}
