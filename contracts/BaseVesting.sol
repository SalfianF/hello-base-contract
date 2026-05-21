// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BaseVesting
 * @notice Linear token vesting contract with cliff and revocation
 * @dev Beneficiary can withdraw vested tokens over time; owner can revoke unvested tokens
 */
contract BaseVesting {
    IERC20 public token;
    address public beneficiary;
    address public owner;
    uint256 public startTime;
    uint256 public cliffDuration;
    uint256 public totalDuration;
    uint256 public totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);
    event Revoked();

    modifier onlyOwner() {
        require(msg.sender == owner, "BaseVesting: only owner");
        _;
    }

    /**
     * @notice Set up a vesting schedule
     * @param _token Address of the ERC20 token being vested
     * @param _beneficiary Address that receives vested tokens
     * @param _startTime Unix timestamp when vesting begins
     * @param _cliffDuration Duration of cliff period (seconds)
     * @param _totalDuration Total vesting duration (seconds)
     */
    constructor(
        address _token,
        address _beneficiary,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _totalDuration
    ) {
        require(_token != address(0), "BaseVesting: zero token");
        require(_beneficiary != address(0), "BaseVesting: zero beneficiary");
        require(_cliffDuration <= _totalDuration, "BaseVesting: cliff exceeds total");
        token = IERC20(_token);
        beneficiary = _beneficiary;
        owner = msg.sender;
        startTime = _startTime;
        cliffDuration = _cliffDuration;
        totalDuration = _totalDuration;
    }

    /**
     * @notice Fund the vesting contract with tokens
     * @param _amount Amount of tokens to vest
     * @dev Must approve this contract first
     */
    function fund(uint256 _amount) external onlyOwner {
        require(totalAmount == 0, "BaseVesting: already funded");
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "BaseVesting: transfer failed"
        );
        totalAmount = _amount;
    }

    /**
     * @notice Calculate the amount of vested but unreleased tokens
     * @return uint256 Vested amount available to claim
     */
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) return 0;
        if (block.timestamp >= startTime + totalDuration) {
            return totalAmount - released;
        }
        uint256 elapsed = block.timestamp - startTime;
        return (totalAmount * elapsed) / totalDuration - released;
    }

    /**
     * @notice Release vested tokens to the beneficiary
     */
    function release() external {
        uint256 amount = vestedAmount();
        require(amount > 0, "BaseVesting: nothing to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "BaseVesting: transfer failed");
        emit TokensReleased(amount);
    }

    /**
     * @notice Revoke unvested tokens and return them to owner
     * @dev Only callable by owner before cliff ends
     */
    function revoke() external onlyOwner {
        require(
            block.timestamp < startTime + cliffDuration,
            "BaseVesting: cliff passed"
        );
        uint256 remaining = token.balanceOf(address(this));
        require(token.transfer(owner, remaining), "BaseVesting: revoke failed");
        emit Revoked();
    }
}
