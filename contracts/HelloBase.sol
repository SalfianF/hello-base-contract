// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HelloBase
 * @notice Simple contract to prove deployment on Base mainnet
 * @dev Built for Base Builders guild role verification
 */
contract HelloBase {
    string public message;
    address public owner;
    uint256 public deployTime;

    event MessageUpdated(address indexed updater, string newMessage);

    /**
     * @notice Deploy with a welcome message
     * @param _message Initial message (e.g., "Hello Base!")
     * @dev Records the deployer as owner and current block timestamp
     */
    constructor(string memory _message) {
        message = _message;
        owner = msg.sender;
        deployTime = block.timestamp;
    }

    /**
     * @notice Update the stored message
     * @dev Only callable by the contract owner
     * @param _message New message to store
     */
    function setMessage(string calldata _message) external {
        require(msg.sender == owner, "HelloBase: only owner");
        message = _message;
        emit MessageUpdated(msg.sender, _message);
    }

    /**
     * @notice Get all contract info at once
     * @return string Current message
     * @return address Owner address
     * @return uint256 Deployment timestamp
     */
    function getInfo()
        external
        view
        returns (string memory, address, uint256)
    {
        return (message, owner, deployTime);
    }
}
