// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseStaking
 * @notice Interface for the BaseStaking ETH staking contract with fixed APR rewards
 */
interface IBaseStaking {
    /// @notice Emitted when a user stakes ETH
    event Staked(address indexed user, uint256 amount);
    /// @notice Emitted when a user unstakes ETH and claims rewards
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    /// @notice Emitted when rewards are claimed
    event RewardClaimed(address indexed user, uint256 reward);
    /// @notice Emitted when the APR is updated
    event AprUpdated(uint256 oldApr, uint256 newApr);

    /// @notice The contract owner
    function owner() external view returns (address);
    /// @notice The APR in basis points (e.g., 1000 = 10%)
    function aprBps() external view returns (uint256);
    /// @notice Total ETH staked
    function totalStaked() external view returns (uint256);
    /// @notice The reward pool balance
    function rewardPool() external view returns (uint256);
    /// @notice Stake info for a user
    function stakes(address user) external view returns (uint256 amount, uint256 timestamp);

    /**
     * @notice Calculate pending rewards for a user
     * @param user Address to check
     * @return uint256 Pending reward in wei
     */
    function pendingReward(address user) external view returns (uint256);

    /**
     * @notice Stake ETH into the contract
     * @dev Must stake at least 0.001 ETH
     */
    function stake() external payable;

    /**
     * @notice Unstake all ETH and claim rewards
     */
    function unstake() external;

    /**
     * @notice Claim rewards without unstaking
     */
    function claimRewards() external;

    /**
     * @notice Fund the reward pool
     */
    function fundRewards() external payable;

    /**
     * @notice Update the APR
     * @param _newAprBps New APR in basis points
     */
    function setApr(uint256 _newAprBps) external;
}
