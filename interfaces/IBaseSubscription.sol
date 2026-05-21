// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseSubscription
 * @notice Interface for the BaseSubscription subscription manager contract
 */
interface IBaseSubscription {
    /// @notice Emitted when a user subscribes or renews
    event Subscribed(address indexed subscriber, uint256 amountPaid, uint256 newExpiry, uint256 periods);
    /// @notice Emitted when the owner cancels a user's subscription
    event Cancelled(address indexed subscriber);
    /// @notice Emitted when the subscription price changes
    event PriceChanged(uint256 oldPrice, uint256 newPrice);
    /// @notice Emitted when the subscription duration changes
    event DurationChanged(uint256 oldDuration, uint256 newDuration);
    /// @notice Emitted when the contract is paused or unpaused
    event Paused(bool isPaused);

    /// @notice The contract owner
    function owner() external view returns (address);
    /// @notice The subscription price in wei
    function price() external view returns (uint256);
    /// @notice The subscription duration in seconds
    function durationSeconds() external view returns (uint256);
    /// @notice Whether the contract is paused
    function paused() external view returns (bool);
    /// @notice Subscription expiry timestamp for a user
    function expiresAt(address subscriber) external view returns (uint256);
    /// @notice Whether a user has been cancelled by the owner
    function cancelled(address subscriber) external view returns (bool);

    /**
     * @notice Subscribe or renew a subscription by paying ETH
     * @param periods The number of subscription periods to purchase
     */
    function subscribe(uint256 periods) external payable;

    /**
     * @notice Convenience function to subscribe for a single period
     */
    function subscribeOne() external payable;

    /**
     * @notice Cancels a user's subscription (owner only)
     * @param subscriber The address to cancel
     */
    function cancelSubscription(address subscriber) external;

    /**
     * @notice Reinstates a previously cancelled user (owner only)
     * @param subscriber The address to reinstate
     */
    function reinstate(address subscriber) external;

    /**
     * @notice Updates the subscription price (owner only)
     * @param newPrice The new price in wei
     */
    function setPrice(uint256 newPrice) external;

    /**
     * @notice Updates the subscription duration (owner only)
     * @param newDurationSeconds The new duration in seconds
     */
    function setDuration(uint256 newDurationSeconds) external;

    /**
     * @notice Pauses or unpauses the contract (owner only)
     * @param _paused Whether to pause (true) or unpause (false)
     */
    function setPaused(bool _paused) external;

    /**
     * @notice Withdraws accumulated ETH to the owner (owner only)
     * @param amount The amount to withdraw (0 for full balance)
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Returns whether a user's subscription is currently active
     * @param subscriber The address to check
     * @return active True if the subscription is active
     */
    function isActive(address subscriber) external view returns (bool active);

    /**
     * @notice Returns the time remaining on a user's subscription
     * @param subscriber The address to check
     * @return secondsRemaining Seconds until expiry
     */
    function timeRemaining(address subscriber) external view returns (uint256 secondsRemaining);

    /**
     * @notice Returns the current contract balance
     * @return balance The total ETH held by the contract
     */
    function contractBalance() external view returns (uint256 balance);
}
