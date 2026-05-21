// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Calculator
 * @notice On-chain calculator supporting add, subtract, multiply, and divide
 * @dev All operations emit events for off-chain indexing
 */
contract Calculator {
    event Operation(string indexed op, uint256 a, uint256 b, uint256 result);

    /**
     * @notice Add two unsigned integers
     * @param a First operand
     * @param b Second operand
     * @return uint256 Sum of a and b
     */
    function add(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a + b;
        emit Operation("add", a, b, result);
        return result;
    }

    /**
     * @notice Subtract b from a
     * @dev Reverts if b > a (underflow protection)
     * @param a First operand
     * @param b Second operand
     * @return uint256 Difference of a minus b
     */
    function sub(uint256 a, uint256 b) external returns (uint256) {
        require(b <= a, "Calculator: underflow");
        uint256 result = a - b;
        emit Operation("sub", a, b, result);
        return result;
    }

    /**
     * @notice Multiply two unsigned integers
     * @param a First operand
     * @param b Second operand
     * @return uint256 Product of a and b
     */
    function mul(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a * b;
        emit Operation("mul", a, b, result);
        return result;
    }

    /**
     * @notice Divide a by b
     * @dev Reverts if b is zero
     * @param a Dividend
     * @param b Divisor
     * @return uint256 Quotient of a divided by b
     */
    function div(uint256 a, uint256 b) external returns (uint256) {
        require(b > 0, "Calculator: division by zero");
        uint256 result = a / b;
        emit Operation("div", a, b, result);
        return result;
    }
}
