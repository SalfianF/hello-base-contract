// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/ITokenSwap.sol";

/**
 * @title TokenSwap
 * @notice Peer-to-peer token swap order book with security hardening
 * @dev Uses ReentrancyGuard, Ownable2Step, ERC-165; includes cancelOrder + deadline features
 */
contract TokenSwap is ReentrancyGuard, Ownable2Step, ERC165 {
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

    SwapOrder[] public orders;

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

    /**
     * @notice Deploy the TokenSwap contract
     * @dev Sets deployer as owner via Ownable2Step
     */
    constructor() Ownable2Step() Ownable(msg.sender) {}

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ITokenSwap).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Create a new swap order
     * @dev Transfers tokenIn from maker to this contract
     * @param tokenIn Address of the token the maker provides
     * @param tokenOut Address of the token the maker wants
     * @param amountIn Amount of tokenIn to swap (in wei)
     * @param amountOut Amount of tokenOut expected in return (in wei)
     * @param deadline Unix timestamp after which the order expires
     */
    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    ) external {
        require(tokenIn != address(0), "TokenSwap: invalid tokenIn");
        require(tokenOut != address(0), "TokenSwap: invalid tokenOut");
        require(tokenIn != tokenOut, "TokenSwap: same token");
        require(amountIn > 0, "TokenSwap: zero amountIn");
        require(amountOut > 0, "TokenSwap: zero amountOut");
        require(deadline > block.timestamp, "TokenSwap: deadline in the past");

        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "TokenSwap: transferIn failed"
        );

        orders.push(SwapOrder({
            maker: msg.sender,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOut: amountOut,
            deadline: deadline,
            filled: false,
            cancelled: false
        }));

        uint256 orderId = orders.length - 1;
        emit OrderCreated(orderId, msg.sender, tokenIn, tokenOut, amountIn, amountOut, deadline);
    }

    /**
     * @notice Fill an existing swap order
     * @dev Transfers tokenOut from filler to maker, then tokenIn from contract to filler
     * @param orderId Index of the order to fill
     */
    function fillOrder(uint256 orderId) external nonReentrant {
        require(orderId < orders.length, "TokenSwap: invalid orderId");
        SwapOrder storage order = orders[orderId];

        require(!order.filled, "TokenSwap: already filled");
        require(!order.cancelled, "TokenSwap: order cancelled");
        require(block.timestamp <= order.deadline, "TokenSwap: order expired");
        require(order.maker != msg.sender, "TokenSwap: cannot fill own order");

        // Output token from filler to maker
        require(
            IERC20(order.tokenOut).transferFrom(msg.sender, order.maker, order.amountOut),
            "TokenSwap: output transfer failed"
        );

        // Input token from contract to filler
        require(
            IERC20(order.tokenIn).transfer(msg.sender, order.amountIn),
            "TokenSwap: input transfer failed"
        );

        order.filled = true;
        emit OrderFilled(orderId, msg.sender);
    }

    /**
     * @notice Cancel an unfilled order and reclaim tokens
     * @dev Only the maker can cancel their own order
     * @param orderId Index of the order to cancel
     */
    function cancelOrder(uint256 orderId) external {
        require(orderId < orders.length, "TokenSwap: invalid orderId");
        SwapOrder storage order = orders[orderId];

        require(msg.sender == order.maker, "TokenSwap: only maker");
        require(!order.filled, "TokenSwap: already filled");
        require(!order.cancelled, "TokenSwap: already cancelled");

        order.cancelled = true;

        require(
            IERC20(order.tokenIn).transfer(order.maker, order.amountIn),
            "TokenSwap: reclaim failed"
        );

        emit OrderCancelled(orderId, msg.sender);
    }

    /**
     * @notice Get total number of orders
     * @return uint256 Order count
     */
    function orderCount() external view returns (uint256) {
        return orders.length;
    }

    /**
     * @notice View order details
     * @param orderId Index of the order
     * @return maker TokenIn tokenOut amountIn amountOut deadline filled cancelled
     */
    function getOrder(uint256 orderId) external view returns (
        address maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline,
        bool filled,
        bool cancelled
    ) {
        require(orderId < orders.length, "TokenSwap: invalid orderId");
        SwapOrder storage order = orders[orderId];
        return (
            order.maker,
            order.tokenIn,
            order.tokenOut,
            order.amountIn,
            order.amountOut,
            order.deadline,
            order.filled,
            order.cancelled
        );
    }

    /**
     * @notice Emergency withdraw stuck tokens (non-order tokens)
     * @dev Only owner, for tokens accidentally sent to this contract
     * @param token Address of the token to withdraw
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        require(token != address(0), "TokenSwap: invalid token");
        require(to != address(0), "TokenSwap: invalid recipient");
        require(amount > 0, "TokenSwap: zero amount");
        IERC20(token).transfer(to, amount);
        emit EmergencyWithdrawn(token, to, amount);
    }
}
