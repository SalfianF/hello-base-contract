// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISimpleStorage
 * @notice Interface for SimpleStorage contract
 * @dev Defines the external functions for storing and retrieving a uint256 value
 */
interface ISimpleStorage {
    /**
     * @notice Emitted when the stored value changes
     * @param newValue The new uint256 value
     */
    event ValueChanged(uint256 indexed newValue);

    /**
     * @notice Store a new value
     * @param newValue The uint256 value to store
     */
    function store(uint256 newValue) external;

    /**
     * @notice Retrieve the stored value
     * @return uint256 The current stored value
     */
    function retrieve() external view returns (uint256);
}
