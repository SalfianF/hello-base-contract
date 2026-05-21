// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITokenSwap
 * @notice Interface for TokenSwap contract
 * @dev Defines the external functions for a peer-to-peer token swap order book
 */
interface ITokenSwap {
    /**
     * @notice Represents a swap order
     * @param maker Address of the order creator
     * @param tokenIn Address of the token the maker provides
     * @param tokenOut Address of the token the maker wants
     * @param amountIn Amount of tokenIn to swap
     * @param amountOut Amount of tokenOut expected in return
     * @param filled Whether the order has been filled
     */
    struct SwapOrder {
        address maker;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        bool filled;
    }

    /**
     * @notice Emitted when a new order is created
     * @param orderId Index of the new order
     * @param maker Address of the order creator
     * @param tokenIn Address of the token provided
     * @param tokenOut Address of the token desired
     * @param amountIn Amount of tokenIn
     * @param amountOut Amount of tokenOut
     */
    event OrderCreated(
        uint256 indexed orderId,
        address indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @notice Emitted when an order is filled
     * @param orderId Index of the filled order
     * @param filler Address of the filler
     */
    event OrderFilled(uint256 indexed orderId, address indexed filler);

    /**
     * @notice Emitted when an order is cancelled
     * @param orderId Index of the cancelled order
     */
    event OrderCancelled(uint256 indexed orderId);

    /**
     * @notice Get the contract owner
     * @return address The owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Get a swap order by index
     * @param orderId Index of the order
     * @return SwapOrder The order details
     */
    function orders(uint256 orderId) external view returns (SwapOrder memory);

    /**
     * @notice Create a new swap order
     * @param tokenIn Address of the token the maker provides
     * @param tokenOut Address of the token the maker wants
     * @param amountIn Amount of tokenIn to swap
     * @param amountOut Amount of tokenOut expected in return
     */
    function createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external;

    /**
     * @notice Fill an existing swap order
     * @param orderId Index of the order to fill
     */
    function fillOrder(uint256 orderId) external;

    /**
     * @notice Get total number of orders
     * @return uint256 Order count
     */
    function orderCount() external view returns (uint256);
}
