// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title BridgingToBase
 * @notice Simple on-chain proof of bridging to Base network with secure ownership
 * @dev Uses OpenZeppelin Ownable2Step for two-step ownership transfers
 */
contract BridgingToBase is Ownable2Step {
    string public message;
    uint256 public deployTime;

    event MessageUpdated(address indexed updater, string indexed oldMessage, string indexed newMessage);

    /**
     * @notice Deploy with a welcome message
     * @param _message Initial message (e.g., "Bridged to Base!")
     * @dev Sets deployer as owner via Ownable2Step, records deployment timestamp
     */
    constructor(string memory _message) Ownable2Step() Ownable(msg.sender) {
        require(bytes(_message).length > 0, "BridgingToBase: empty message");
        message = _message;
        deployTime = block.timestamp;
    }

    /**
     * @notice Update the stored message
     * @dev Only callable by the contract owner
     * @param _message New message to store
     */
    function setMessage(string calldata _message) external onlyOwner {
        require(bytes(_message).length > 0, "BridgingToBase: empty message");
        emit MessageUpdated(msg.sender, message, _message);
        message = _message;
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
        return (message, owner(), deployTime);
    }
}
