// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title  HelloBase
/// @notice Simple message storage contract for Base mainnet deployment verification.
/// @dev    Part of the Base Builder Guild credential kit.
/// @custom:security-contact salfianf@github.com
contract HelloBase {
    // ────────────────────────────────────────────────────────────────────
    //  Errors
    // ────────────────────────────────────────────────────────────────────
    error HelloBase__Unauthorized(address caller, address owner);
    error HelloBase__EmptyMessage();

    // ────────────────────────────────────────────────────────────────────
    //  Events
    // ────────────────────────────────────────────────────────────────────
    /// @notice Emitted when the stored message is updated.
    /// @param  updater Address that performed the update.
    /// @param  oldMessage Previous message value.
    /// @param  newMessage New message value.
    event MessageUpdated(
        address indexed updater,
        string indexed oldMessage,
        string indexed newMessage
    );

    // ────────────────────────────────────────────────────────────────────
    //  State
    // ────────────────────────────────────────────────────────────────────
    /// @notice Current stored message.
    string public message;

    /// @notice Contract deployer / sole administrator.
    address public owner;

    /// @notice UNIX timestamp of contract deployment.
    uint256 public immutable deployTime;

    // ────────────────────────────────────────────────────────────────────
    //  Constructor
    // ────────────────────────────────────────────────────────────────────
    /// @param  _message Initial welcome message (e.g. "Hello Base!").
    constructor(string memory _message) {
        if (bytes(_message).length == 0) revert HelloBase__EmptyMessage();

        message    = _message;
        owner      = msg.sender;
        deployTime = block.timestamp;
    }

    // ────────────────────────────────────────────────────────────────────
    //  Mutating
    // ────────────────────────────────────────────────────────────────────
    /// @notice Replace the stored message.
    /// @dev    Reverts if caller is not the contract owner.
    /// @param  _message New message string. Must be non-empty.
    function setMessage(string calldata _message) external {
        if (msg.sender != owner) revert HelloBase__Unauthorized(msg.sender, owner);
        if (bytes(_message).length == 0) revert HelloBase__EmptyMessage();

        string memory old = message;
        message = _message;

        emit MessageUpdated(msg.sender, old, _message);
    }

    // ────────────────────────────────────────────────────────────────────
    //  Views
    // ────────────────────────────────────────────────────────────────────
    /// @notice Get all contract state in a single call.
    /// @return Current message.
    /// @return Owner address.
    /// @return Deployment timestamp.
    function getInfo()
        external
        view
        returns (string memory, address, uint256)
    {
        return (message, owner, deployTime);
    }
}
