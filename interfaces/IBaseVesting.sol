// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseVesting
 * @notice Interface for the BaseVesting linear token vesting contract
 */
interface IBaseVesting {
    /// @notice Emitted when tokens are released to the beneficiary
    event TokensReleased(uint256 amount);
    /// @notice Emitted when the vesting is revoked
    event Revoked();

    /// @notice The ERC20 token being vested
    function token() external view returns (address);
    /// @notice The beneficiary address
    function beneficiary() external view returns (address);
    /// @notice The contract owner
    function owner() external view returns (address);
    /// @notice Vesting start timestamp
    function startTime() external view returns (uint256);
    /// @notice Cliff duration in seconds
    function cliffDuration() external view returns (uint256);
    /// @notice Total vesting duration in seconds
    function totalDuration() external view returns (uint256);
    /// @notice Total amount of tokens being vested
    function totalAmount() external view returns (uint256);
    /// @notice Amount of tokens already released
    function released() external view returns (uint256);

    /**
     * @notice Fund the vesting contract with tokens
     * @param _amount Amount of tokens to vest
     * @dev Must approve this contract first
     */
    function fund(uint256 _amount) external;

    /**
     * @notice Calculate the amount of vested but unreleased tokens
     * @return uint256 Vested amount available to claim
     */
    function vestedAmount() external view returns (uint256);

    /**
     * @notice Release vested tokens to the beneficiary
     */
    function release() external;

    /**
     * @notice Revoke unvested tokens and return them to owner
     * @dev Only callable by owner before cliff ends
     */
    function revoke() external;
}
