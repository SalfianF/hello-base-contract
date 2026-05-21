// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleStorage
 * @notice Basic contract to store and retrieve a single uint256 value
 * @dev Minimal storage pattern, emits events on value change
 */
contract SimpleStorage {
    uint256 private _value;

    event ValueChanged(uint256 indexed newValue);

    /**
     * @notice Store a new value
     * @param newValue The uint256 value to store
     * @dev Emits ValueChanged event
     */
    function store(uint256 newValue) external {
        _value = newValue;
        emit ValueChanged(newValue);
    }

    /**
     * @notice Retrieve the stored value
     * @return uint256 The current stored value
     */
    function retrieve() external view returns (uint256) {
        return _value;
    }
}
