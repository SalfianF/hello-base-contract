// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    event OrderCreated(uint256 indexed orderId, address maker, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event OrderFilled(uint256 indexed orderId, address filler);

    constructor() {
        owner = msg.sender;
    }

    function createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external {
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        orders.push(SwapOrder(msg.sender, tokenIn, tokenOut, amountIn, amountOut, false));
        emit OrderCreated(orders.length - 1, msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function fillOrder(uint256 orderId) external {
        SwapOrder storage order = orders[orderId];
        require(!order.filled, "Already filled");
        require(IERC20(order.tokenOut).transferFrom(msg.sender, order.maker, order.amountOut), "Transfer failed");
        require(IERC20(order.tokenIn).transfer(msg.sender, order.amountIn), "Transfer failed");
        order.filled = true;
        emit OrderFilled(orderId, msg.sender);
    }
}