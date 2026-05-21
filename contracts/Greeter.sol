// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Greeter
 * @notice A simple greeting contract with owner-only updates
 * @dev Stores a greeting string with owner access control
 */
contract Greeter {
    string private _greeting;
    address public owner;

    event GreetingChanged(string indexed oldGreeting, string indexed newGreeting);

    /**
     * @notice Set the initial greeting
     * @param greeting_ The initial greeting string
     * @dev Sets the deployer as owner
     */
    constructor(string memory greeting_) {
        _greeting = greeting_;
        owner = msg.sender;
    }

    /**
     * @notice Get the current greeting
     * @return string The current greeting message
     */
    function greet() external view returns (string memory) {
        return _greeting;
    }

    /**
     * @notice Update the greeting message
     * @dev Only callable by the contract owner
     * @param greeting_ The new greeting string
     */
    function setGreeting(string calldata greeting_) external {
        require(msg.sender == owner, "Greeter: only owner");
        emit GreetingChanged(_greeting, greeting_);
        _greeting = greeting_;
    }

    /**
     * @notice Get a formatted owner greeting
     * @return string The greeting prefixed with "Owner says: "
     */
    function ownerGreet() external view returns (string memory) {
        return string.concat("Owner says: ", _greeting);
    }
}
