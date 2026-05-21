// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseSubscription
 * @notice A subscription manager on Base allowing users to subscribe for a fixed duration by paying ETH.
 * @dev The owner can set the subscription price and duration. Users subscribe and are tracked by expiry.
 *      Subscriptions can be cancelled (refunding unused time is not supported — owner may implement a separate
 *      refund policy off-chain). Emits events for all key state changes.
 */
contract BaseSubscription {
    /* ──────────────── State Variables ──────────────── */

    /// @notice The contract owner/administrator.
    address public owner;

    /// @notice The subscription price in wei per duration unit (1 unit = `durationSeconds`).
    uint256 public price;

    /// @notice The duration of a single subscription period in seconds.
    uint256 public durationSeconds;

    /// @notice Whether the contract is paused (new subscriptions disabled).
    bool public paused;

    /// @notice Mapping from user address to their subscription expiry timestamp.
    /// @dev A value of 0 means the user has never subscribed or has been cancelled.
    mapping(address => uint256) public expiresAt;

    /// @notice Mapping from user address to whether they have been manually cancelled by the owner.
    mapping(address => bool) public cancelled;

    /* ──────────────── Events ──────────────── */

    /**
     * @notice Emitted when a user subscribes or renews a subscription.
     * @param subscriber  The address that subscribed.
     * @param amountPaid  The ETH amount paid (in wei).
     * @param newExpiry   The UNIX timestamp when the subscription expires.
     * @param periods     The number of periods subscribed.
     */
    event Subscribed(
        address indexed subscriber,
        uint256 amountPaid,
        uint256 newExpiry,
        uint256 periods
    );

    /**
     * @notice Emitted when the owner cancels a user's subscription.
     * @param subscriber The address whose subscription was cancelled.
     */
    event Cancelled(address indexed subscriber);

    /**
     * @notice Emitted when the owner changes the subscription price.
     * @param oldPrice The previous price (in wei).
     * @param newPrice The new price (in wei).
     */
    event PriceChanged(uint256 oldPrice, uint256 newPrice);

    /**
     * @notice Emitted when the subscription duration is changed.
     * @param oldDuration The previous duration (in seconds).
     * @param newDuration The new duration (in seconds).
     */
    event DurationChanged(uint256 oldDuration, uint256 newDuration);

    /**
     * @notice Emitted when the contract is paused or unpaused.
     * @param isPaused Whether the contract is now paused.
     */
    event Paused(bool isPaused);

    /* ──────────────── Modifiers ──────────────── */

    /// @notice Restricts a function to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseSubscription: caller is not the owner");
        _;
    }

    /// @notice Reverts if the contract is paused.
    modifier whenNotPaused() {
        require(!paused, "BaseSubscription: contract is paused");
        _;
    }

    /* ──────────────── Constructor ──────────────── */

    /**
     * @notice Initializes the subscription manager with a price, duration, and owner.
     * @param _price           The subscription price in wei.
     * @param _durationSeconds The duration of a single subscription period in seconds.
     * @dev Both price and duration must be greater than zero.
     */
    constructor(uint256 _price, uint256 _durationSeconds) {
        require(_price > 0, "BaseSubscription: price must be > 0");
        require(_durationSeconds > 0, "BaseSubscription: duration must be > 0");

        owner = msg.sender;
        price = _price;
        durationSeconds = _durationSeconds;
    }

    /* ──────────────── Public Functions ──────────────── */

    /**
     * @notice Subscribe or renew a subscription by paying ETH.
     * @param periods The number of subscription periods to purchase (each = `durationSeconds`).
     * @dev The sent ETH must equal `price * periods`. The new expiry extends from the current expiry
     *      (or block.timestamp if expired) by `periods * durationSeconds`.
     */
    function subscribe(uint256 periods) external payable whenNotPaused {
        require(periods > 0, "BaseSubscription: periods must be > 0");
        require(!cancelled[msg.sender], "BaseSubscription: subscription was cancelled by owner");

        uint256 cost = price * periods;
        require(msg.value >= cost, "BaseSubscription: insufficient ETH");

        // Refund excess ETH
        uint256 excess = msg.value - cost;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "BaseSubscription: refund failed");
        }

        uint256 currentExpiry = expiresAt[msg.sender];
        uint256 newExpiry;
        if (currentExpiry < block.timestamp) {
            // Expired or first time — start from now
            newExpiry = block.timestamp + (periods * durationSeconds);
        } else {
            // Renew — extend from current expiry
            newExpiry = currentExpiry + (periods * durationSeconds);
        }

        expiresAt[msg.sender] = newExpiry;

        emit Subscribed(msg.sender, cost, newExpiry, periods);
    }

    /**
     * @notice Convenience function to subscribe for a single period. Sends `price` wei.
     * @dev Equivalent to `subscribe(1)`.
     */
    function subscribeOne() external payable whenNotPaused {
        require(msg.value >= price, "BaseSubscription: insufficient ETH");

        uint256 excess = msg.value - price;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "BaseSubscription: refund failed");
        }

        uint256 currentExpiry = expiresAt[msg.sender];
        uint256 newExpiry;
        if (currentExpiry < block.timestamp) {
            newExpiry = block.timestamp + durationSeconds;
        } else {
            newExpiry = currentExpiry + durationSeconds;
        }

        expiresAt[msg.sender] = newExpiry;

        emit Subscribed(msg.sender, price, newExpiry, 1);
    }

    /* ──────────────── Owner Functions ──────────────── */

    /**
     * @notice Cancels a user's subscription. The user will no longer be able to subscribe again
     *         (unless the owner removes the cancellation flag via `reinstate`).
     * @param subscriber The address whose subscription should be cancelled.
     * @dev Does not refund any funds. Does not change the expiry timestamp — it only prevents
     *      the user from calling `subscribe` in the future.
     */
    function cancelSubscription(address subscriber) external onlyOwner {
        require(subscriber != address(0), "BaseSubscription: invalid address");
        require(!cancelled[subscriber], "BaseSubscription: already cancelled");

        cancelled[subscriber] = true;

        emit Cancelled(subscriber);
    }

    /**
     * @notice Reinstates a previously cancelled user so they can subscribe again.
     * @param subscriber The address to reinstate.
     */
    function reinstate(address subscriber) external onlyOwner {
        require(cancelled[subscriber], "BaseSubscription: not cancelled");
        cancelled[subscriber] = false;
    }

    /**
     * @notice Updates the subscription price.
     * @param newPrice The new price in wei. Must be greater than zero.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "BaseSubscription: price must be > 0");
        uint256 oldPrice = price;
        price = newPrice;

        emit PriceChanged(oldPrice, newPrice);
    }

    /**
     * @notice Updates the subscription duration.
     * @param newDurationSeconds The new duration in seconds. Must be greater than zero.
     */
    function setDuration(uint256 newDurationSeconds) external onlyOwner {
        require(newDurationSeconds > 0, "BaseSubscription: duration must be > 0");
        uint256 oldDuration = durationSeconds;
        durationSeconds = newDurationSeconds;

        emit DurationChanged(oldDuration, newDurationSeconds);
    }

    /**
     * @notice Pauses or unpauses the contract. When paused, new subscriptions are not accepted.
     * @param _paused Whether to pause (true) or unpause (false).
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;

        emit Paused(_paused);
    }

    /**
     * @notice Withdraws accumulated ETH from subscriptions to the owner.
     * @param amount The amount to withdraw (in wei). Use 0 for the full balance.
     */
    function withdraw(uint256 amount) external onlyOwner {
        if (amount == 0 || amount >= address(this).balance) {
            amount = address(this).balance;
        }
        require(amount > 0, "BaseSubscription: nothing to withdraw");

        (bool sent, ) = payable(owner).call{value: amount}("");
        require(sent, "BaseSubscription: withdrawal failed");
    }

    /* ──────────────── View Functions ──────────────── */

    /**
     * @notice Returns whether a user's subscription is currently active.
     * @param subscriber The address to check.
     * @return active True if the subscription is active (not expired).
     */
    function isActive(address subscriber) external view returns (bool active) {
        return expiresAt[subscriber] >= block.timestamp && !cancelled[subscriber];
    }

    /**
     * @notice Returns the time remaining on a user's subscription.
     * @param subscriber The address to check.
     * @return secondsRemaining Seconds until expiry. Returns 0 if expired or cancelled.
     */
    function timeRemaining(address subscriber) external view returns (uint256 secondsRemaining) {
        if (expiresAt[subscriber] <= block.timestamp || cancelled[subscriber]) {
            return 0;
        }
        return expiresAt[subscriber] - block.timestamp;
    }

    /**
     * @notice Returns the current contract balance.
     * @return balance The total ETH held by the contract.
     */
    function contractBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }
}
