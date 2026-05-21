// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseLendingPool
 * @notice Interface for the BaseLendingPool contract
 */
interface IBaseLendingPool {
    function totalDeposits() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function deposits(address user) external view returns (uint256 amount, uint256 timestamp);
    function borrows(address user) external view returns (uint256 amount, uint256 timestamp);
    function hasActiveBorrow(address user) external view returns (bool);
    function isHealthy(address user) external view returns (bool);
    function maxBorrowable(address user) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay() external payable;
    function liquidate(address user) external;
}
