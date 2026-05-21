// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITokenSwap
 * @notice Interface for TokenSwap contract with cancelOrder and deadline
 * @dev Defines the external functions with security-hardened features
 */
interface ITokenSwap {
    struct SwapOrder {
        address maker;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 deadline;
        bool filled;
        bool cancelled;
    }

    event OrderCreated(
        uint256 indexed orderId,
        address indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    );
    event OrderFilled(uint256 indexed orderId, address indexed filler);
    event OrderCancelled(uint256 indexed orderId, address indexed maker);
    event EmergencyWithdrawn(address indexed token, address indexed to, uint256 amount);

    function owner() external view returns (address);
    function orders(uint256 orderId) external view returns (SwapOrder memory);
    function orderCount() external view returns (uint256);

    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    ) external;

    function fillOrder(uint256 orderId) external;
    function cancelOrder(uint256 orderId) external;
    function getOrder(uint256 orderId) external view returns (
        address maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline,
        bool filled,
        bool cancelled
    );
    function emergencyWithdraw(address token, address to, uint256 amount) external;
}
