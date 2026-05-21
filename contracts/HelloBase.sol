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

    constructor(string memory _message) {
        message = _message;
        owner = msg.sender;
        deployTime = block.timestamp;
    }

    function setMessage(string calldata _message) external {
        require(msg.sender == owner, "Only owner");
        message = _message;
        emit MessageUpdated(msg.sender, _message);
    }

    function getInfo() external view returns (string memory, address, uint256) {
        return (message, owner, deployTime);
    }
}
