// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Counter
 * @notice Simple increment/decrement counter contract
 * @dev Supports increment, decrement, reset, and read operations
 */
contract Counter {
    uint256 private _count;

    event CountIncremented(uint256 indexed newCount);
    event CountDecremented(uint256 indexed newCount);

    /**
     * @notice Increment the counter by 1
     * @dev Emits CountIncremented with new value
     */
    function increment() external {
        _count++;
        emit CountIncremented(_count);
    }

    /**
     * @notice Decrement the counter by 1
     * @dev Reverts if count is zero to prevent underflow
     */
    function decrement() external {
        require(_count > 0, "Counter: cannot go below zero");
        _count--;
        emit CountDecremented(_count);
    }

    /**
     * @notice Get the current count
     * @return uint256 The current count value
     */
    function count() external view returns (uint256) {
        return _count;
    }

    /**
     * @notice Reset the counter to zero
     * @dev No event emitted for gas efficiency
     */
    function reset() external {
        _count = 0;
    }
}
