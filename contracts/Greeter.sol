// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Greeter {
    string private _greeting;
    address public owner;

    event GreetingChanged(string oldGreeting, string newGreeting);

    constructor(string memory greeting_) {
        _greeting = greeting_;
        owner = msg.sender;
    }

    function greet() external view returns (string memory) {
        return _greeting;
    }

    function setGreeting(string calldata greeting_) external {
        require(msg.sender == owner, "Only owner");
        emit GreetingChanged(_greeting, greeting_);
        _greeting = greeting_;
    }

    function ownerGreet() external view returns (string memory) {
        return string.concat("Owner says: ", _greeting);
    }
}