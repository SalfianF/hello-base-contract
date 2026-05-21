// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICalculator
 * @notice Interface for Calculator contract
 * @dev Defines the external functions for on-chain arithmetic operations
 */
interface ICalculator {
    /**
     * @notice Emitted when any arithmetic operation is performed
     * @param op The operation name (add, sub, mul, div)
     * @param a First operand
     * @param b Second operand
     * @param result The computed result
     */
    event Operation(string indexed op, uint256 a, uint256 b, uint256 result);

    /**
     * @notice Add two unsigned integers
     * @param a First operand
     * @param b Second operand
     * @return uint256 Sum of a and b
     */
    function add(uint256 a, uint256 b) external returns (uint256);

    /**
     * @notice Subtract b from a
     * @dev Reverts if b > a (underflow protection)
     * @param a First operand
     * @param b Second operand
     * @return uint256 Difference of a minus b
     */
    function sub(uint256 a, uint256 b) external returns (uint256);

    /**
     * @notice Multiply two unsigned integers
     * @param a First operand
     * @param b Second operand
     * @return uint256 Product of a and b
     */
    function mul(uint256 a, uint256 b) external returns (uint256);

    /**
     * @notice Divide a by b
     * @dev Reverts if b is zero
     * @param a Dividend
     * @param b Divisor
     * @return uint256 Quotient of a divided by b
     */
    function div(uint256 a, uint256 b) external returns (uint256);
}
