// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVault
 * @notice Interface for Vault contract
 * @dev Defines the external functions for depositing and withdrawing ETH
 */
interface IVault {
    /**
     * @notice Emitted when a user deposits ETH
     * @param user Address of the depositor
     * @param amount Amount of ETH deposited
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @notice Emitted when a user withdraws ETH
     * @param user Address of the withdrawer
     * @param amount Amount of ETH withdrawn
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Get the contract owner
     * @return address The owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Deposit ETH into the vault
     */
    function deposit() external payable;

    /**
     * @notice Withdraw ETH from the vault
     * @param amount Amount of ETH to withdraw (in wei)
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Check the balance of a user
     * @param user Address of the user
     * @return uint256 The balance of the user
     */
    function balanceOf(address user) external view returns (uint256);
}
