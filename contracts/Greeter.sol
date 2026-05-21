// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title Greeter
 * @notice A simple greeting contract with two-step ownership transfer
 * @dev Uses OpenZeppelin Ownable2Step for secure ownership management
 */
contract Greeter is Ownable2Step {
    string private _greeting;

    event GreetingChanged(address indexed updater, string indexed oldGreeting, string indexed newGreeting);

    /**
     * @notice Set the initial greeting
     * @param greeting_ The initial greeting string
     * @dev Sets the deployer as owner via Ownable2Step constructor
     */
    constructor(string memory greeting_) Ownable2Step() Ownable(msg.sender) {
        require(bytes(greeting_).length > 0, "Greeter: empty greeting");
        _greeting = greeting_;
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
    function setGreeting(string calldata greeting_) external onlyOwner {
        require(bytes(greeting_).length > 0, "Greeter: empty greeting");
        emit GreetingChanged(msg.sender, _greeting, greeting_);
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
