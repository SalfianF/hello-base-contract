// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IGreeter
 * @notice Interface for Greeter contract
 * @dev Defines the external functions for a greeting contract with owner-only updates
 */
interface IGreeter {
    /**
     * @notice Emitted when the greeting is changed
     * @param oldGreeting The previous greeting string
     * @param newGreeting The new greeting string
     */
    event GreetingChanged(string indexed oldGreeting, string indexed newGreeting);

    /**
     * @notice Get the current greeting
     * @return string The current greeting message
     */
    function greet() external view returns (string memory);

    /**
     * @notice Update the greeting message
     * @dev Only callable by the contract owner
     * @param greeting_ The new greeting string
     */
    function setGreeting(string calldata greeting_) external;

    /**
     * @notice Get a formatted owner greeting
     * @return string The greeting prefixed with "Owner says: "
     */
    function ownerGreet() external view returns (string memory);

    /**
     * @notice Get the contract owner address
     * @return address The owner address
     */
    function owner() external view returns (address);
}
