// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Calculator {
    event Operation(string op, uint256 a, uint256 b, uint256 result);

    function add(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a + b;
        emit Operation("add", a, b, result);
        return result;
    }

    function sub(uint256 a, uint256 b) external returns (uint256) {
        require(b <= a, "Calculator: underflow");
        uint256 result = a - b;
        emit Operation("sub", a, b, result);
        return result;
    }

    function mul(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a * b;
        emit Operation("mul", a, b, result);
        return result;
    }

    function div(uint256 a, uint256 b) external returns (uint256) {
        require(b > 0, "Calculator: division by zero");
        uint256 result = a / b;
        emit Operation("div", a, b, result);
        return result;
    }
}