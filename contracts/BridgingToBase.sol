// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BridgingToBase {
    string public message;
    address public owner;
    uint256 public deployTime;

    constructor(string memory _message) {
        message = _message;
        owner = msg.sender;
        deployTime = block.timestamp;
    }

    function setMessage(string calldata _message) external {
        require(msg.sender == owner, "Only owner");
        message = _message;
    }

    function getInfo() external view returns (string memory, address, uint256) {
        return (message, owner, deployTime);
    }
}
