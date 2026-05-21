// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenSwap
 * @notice Peer-to-peer token swap order book
 * @dev Users create fill-or-kill swap orders; counterparties fill them atomically
 */
contract TokenSwap {
    address public owner;

    struct SwapOrder {
        address maker;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        bool filled;
    }

    SwapOrder[] public orders;

    event OrderCreated(
        uint256 indexed orderId,
        address indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event OrderFilled(uint256 indexed orderId, address indexed filler);
    event OrderCancelled(uint256 indexed orderId);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Create a new swap order
     * @dev Transfers tokenIn from maker to this contract
     * @param tokenIn Address of the token the maker provides
     * @param tokenOut Address of the token the maker wants
     * @param amountIn Amount of tokenIn to swap
     * @param amountOut Amount of tokenOut expected in return
     */
    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external {
        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "TokenSwap: transfer failed"
        );
        orders.push(
            SwapOrder(msg.sender, tokenIn, tokenOut, amountIn, amountOut, false)
        );
        emit OrderCreated(orders.length - 1, msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @notice Fill an existing swap order
     * @dev Transfers tokenOut from filler to maker, then tokenIn from contract to filler
     * @param orderId Index of the order to fill
     */
    function fillOrder(uint256 orderId) external {
        SwapOrder storage order = orders[orderId];
        require(!order.filled, "TokenSwap: already filled");
        require(
            IERC20(order.tokenOut).transferFrom(msg.sender, order.maker, order.amountOut),
            "TokenSwap: output transfer failed"
        );
        require(
            IERC20(order.tokenIn).transfer(msg.sender, order.amountIn),
            "TokenSwap: input transfer failed"
        );
        order.filled = true;
        emit OrderFilled(orderId, msg.sender);
    }

    /**
     * @notice Get total number of orders
     * @return uint256 Order count
     */
    function orderCount() external view returns (uint256) {
        return orders.length;
    }
}
