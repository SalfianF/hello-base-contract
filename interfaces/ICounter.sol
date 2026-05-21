// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICounter
 * @notice Interface for Counter contract
 * @dev Defines the external functions for increment, decrement, reset, and read operations
 */
interface ICounter {
    /**
     * @notice Emitted when the counter is incremented
     * @param newCount The new count value
     */
    event CountIncremented(uint256 indexed newCount);

    /**
     * @notice Emitted when the counter is decremented
     * @param newCount The new count value
     */
    event CountDecremented(uint256 indexed newCount);

    /**
     * @notice Increment the counter by 1
     */
    function increment() external;

    /**
     * @notice Decrement the counter by 1
     * @dev Reverts if count is zero to prevent underflow
     */
    function decrement() external;

    /**
     * @notice Get the current count
     * @return uint256 The current count value
     */
    function count() external view returns (uint256);

    /**
     * @notice Reset the counter to zero
     */
    function reset() external;
}
