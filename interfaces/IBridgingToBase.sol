// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBridgingToBase
 * @notice Interface for BridgingToBase contract
 * @dev Defines the external functions for an on-chain proof of bridging to Base network
 */
interface IBridgingToBase {
    /**
     * @notice Emitted when the stored message is updated
     * @param updater Address that updated the message
     * @param newMessage The new message string
     */
    event MessageUpdated(address indexed updater, string newMessage);

    /**
     * @notice Get the stored message
     * @return string The current message
     */
    function message() external view returns (string memory);

    /**
     * @notice Get the contract owner
     * @return address The owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Get the deployment timestamp
     * @return uint256 The block timestamp of deployment
     */
    function deployTime() external view returns (uint256);

    /**
     * @notice Update the stored message
     * @dev Only callable by the contract owner
     * @param _message New message to store
     */
    function setMessage(string calldata _message) external;

    /**
     * @notice Get all contract info at once
     * @return string Current message
     * @return address Owner address
     * @return uint256 Deployment timestamp
     */
    function getInfo() external view returns (string memory, address, uint256);
}
