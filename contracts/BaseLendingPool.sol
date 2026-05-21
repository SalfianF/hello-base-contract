// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BaseLendingPool
 * @notice Collateralized lending pool — deposit ETH, borrow against it, repay, or get liquidated
 * @dev Max 75% LTV, liquidated at 80% threshold with 10% bonus for liquidators
 */
contract BaseLendingPool is Ownable, ReentrancyGuard {
    uint256 public totalDeposits;
    uint256 public totalBorrows;

    /// @notice Maximum loan-to-value ratio in basis points (75%)
    uint256 public constant MAX_LTV_BPS = 7500;
    /// @notice Liquidation threshold in percentage (80%)
    uint256 public constant LIQUIDATION_THRESHOLD = 80;
    /// @notice Bonus for liquidators in percentage (10%)
    uint256 public constant LIQUIDATION_BONUS = 10;
    /// @notice Minimum deposit amount in wei
    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;

    /// @notice User deposit info
    struct DepositInfo {
        uint256 amount;
        uint256 timestamp;
    }

    /// @notice User borrow info
    struct BorrowInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => DepositInfo) public deposits;
    mapping(address => BorrowInfo) public borrows;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 maxBorrow);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Deposit ETH as collateral
     */
    function deposit() external payable {
        require(msg.value >= MINIMUM_DEPOSIT, "BaseLendingPool: deposit too small");
        deposits[msg.sender].amount += msg.value;
        deposits[msg.sender].timestamp = block.timestamp;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw deposited collateral
     * @param amount Amount of ETH to withdraw (in wei)
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(deposits[msg.sender].amount >= amount, "BaseLendingPool: insufficient deposit");
        if (hasActiveBorrow(msg.sender)) {
            require(isHealthy(msg.sender), "BaseLendingPool: position unhealthy — repay or add collateral");
        }
        deposits[msg.sender].amount -= amount;
        totalDeposits -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Borrow ETH against deposited collateral (max 75% LTV)
     * @param amount Amount to borrow (in wei)
     */
    function borrow(uint256 amount) external nonReentrant {
        require(deposits[msg.sender].amount > 0, "BaseLendingPool: no collateral deposited");
        require(address(this).balance >= totalBorrows + amount, "BaseLendingPool: insufficient pool liquidity");
        uint256 maxBorrow = (deposits[msg.sender].amount * MAX_LTV_BPS) / 10000;
        uint256 totalOwed = borrows[msg.sender].amount + amount;
        require(totalOwed <= maxBorrow, "BaseLendingPool: exceeds max LTV");

        borrows[msg.sender].amount = totalOwed;
        borrows[msg.sender].timestamp = block.timestamp;
        totalBorrows += amount;
        payable(msg.sender).transfer(amount);
        emit Borrowed(msg.sender, amount, maxBorrow);
    }

    /**
     * @notice Repay an active borrow
     */
    function repay() external payable nonReentrant {
        require(borrows[msg.sender].amount > 0, "BaseLendingPool: no active borrow");
        require(msg.value > 0, "BaseLendingPool: repayment must be > 0");
        uint256 repayAmount = msg.value > borrows[msg.sender].amount
            ? borrows[msg.sender].amount
            : msg.value;
        borrows[msg.sender].amount -= repayAmount;
        totalBorrows -= repayAmount;
        emit Repaid(msg.sender, repayAmount);

        // Refund overpayment
        uint256 excess = msg.value - repayAmount;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    /**
     * @notice Liquidate an undercollateralized position
     * @param user The address to liquidate
     */
    function liquidate(address user) external nonReentrant {
        require(user != msg.sender, "BaseLendingPool: cannot self-liquidate");
        require(!isHealthy(user), "BaseLendingPool: position is still healthy");
        uint256 debt = borrows[user].amount;
        require(debt > 0, "BaseLendingPool: no debt to liquidate");

        uint256 collateral = deposits[user].amount;
        uint256 bonus = (debt * LIQUIDATION_BONUS) / 100;
        uint256 liquidatorReward = debt + bonus;
        require(collateral >= liquidatorReward, "BaseLendingPool: insufficient collateral for liquidation");

        // Clear user's position
        borrows[user].amount = 0;
        deposits[user].amount -= liquidatorReward;
        totalBorrows -= debt;
        totalDeposits -= liquidatorReward;

        payable(msg.sender).transfer(liquidatorReward);
        emit Liquidated(user, msg.sender, debt, liquidatorReward);
    }

    /// @notice Check if a user has an active borrow
    function hasActiveBorrow(address user) public view returns (bool) {
        return borrows[user].amount > 0;
    }

    /// @notice Check if a user's position is healthy (borrow < 80% of collateral)
    function isHealthy(address user) public view returns (bool) {
        if (borrows[user].amount == 0) return true;
        if (deposits[user].amount == 0) return false;
        uint256 ratio = (borrows[user].amount * 100) / deposits[user].amount;
        return ratio < LIQUIDATION_THRESHOLD;
    }

    /// @notice Calculate max borrowable amount for a user
    function maxBorrowable(address user) external view returns (uint256) {
        return (deposits[user].amount * MAX_LTV_BPS) / 10000;
    }

    receive() external payable {}
}
