// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BaseStaking
 * @notice ETH staking contract with fixed APR rewards
 * @dev Users stake ETH and earn rewards proportional to time staked
 */
contract BaseStaking is ReentrancyGuard {
    address public owner;
    uint256 public aprBps;
    uint256 public totalStaked;
    uint256 public rewardPool;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);
    event AprUpdated(uint256 oldApr, uint256 newApr);

    modifier onlyOwner() {
        require(msg.sender == owner, "BaseStaking: only owner");
        _;
    }

    /**
     * @notice Initialize staking contract
     * @param _aprBps Initial APR in basis points (e.g., 1000 = 10%)
     */
    constructor(uint256 _aprBps) {
        owner = msg.sender;
        aprBps = _aprBps;
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user Address to check
     * @return uint256 Pending reward in wei
     */
    function pendingReward(address user) public view returns (uint256) {
        Stake storage s = stakes[user];
        if (s.amount == 0 || s.timestamp == 0) return 0;
        uint256 duration = block.timestamp - s.timestamp;
        return (s.amount * aprBps * duration) / (10000 * 365 days);
    }

    /**
     * @notice Stake ETH into the contract
     * @dev Must stake at least 0.001 ETH
     */
    function stake() external payable {
        require(msg.value >= 0.001 ether, "BaseStaking: minimum 0.001 ETH");
        Stake storage s = stakes[msg.sender];
        if (s.amount > 0) {
            uint256 reward = pendingReward(msg.sender);
            if (reward > 0) rewardPool -= reward;
        }
        s.amount += msg.value;
        s.timestamp = block.timestamp;
        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @notice Unstake all ETH and claim rewards
     * @dev Non-reentrant for safety
     */
    function unstake() external nonReentrant {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "BaseStaking: nothing staked");
        uint256 reward = pendingReward(msg.sender);
        uint256 total = s.amount + reward;
        require(address(this).balance >= total, "BaseStaking: insufficient balance");
        s.amount = 0;
        s.timestamp = 0;
        totalStaked -= s.amount;
        if (reward > 0) rewardPool -= reward;
        (bool success, ) = payable(msg.sender).call{value: total}("");
        require(success, "BaseStaking: transfer failed");
        emit Unstaked(msg.sender, s.amount, reward);
    }

    /**
     * @notice Claim rewards without unstaking
     */
    function claimRewards() external nonReentrant {
        Stake storage s = stakes[msg.sender];
        uint256 reward = pendingReward(msg.sender);
        require(reward > 0, "BaseStaking: no rewards");
        s.timestamp = block.timestamp;
        rewardPool -= reward;
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "BaseStaking: transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @notice Fund the reward pool
     */
    function fundRewards() external payable {
        rewardPool += msg.value;
    }

    /**
     * @notice Update the APR
     * @param _newAprBps New APR in basis points
     */
    function setApr(uint256 _newAprBps) external onlyOwner {
        emit AprUpdated(aprBps, _newAprBps);
        aprBps = _newAprBps;
    }
}
