// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseTimelock
 * @notice A timelock controller contract on Base that enforces a delay on transaction execution.
 * @dev Owner schedules transactions (target, value, data). After the minimum delay, anyone may execute.
 *      Includes cancellation and an optional grace period after which transactions expire.
 */
contract BaseTimelock {
    /* ──────────────── State Variables ──────────────── */

    /// @notice The minimum delay (in seconds) before a scheduled transaction can be executed.
    uint256 public immutable delay;

    /// @notice The maximum delay plus buffer after which a scheduled transaction expires.
    uint256 public immutable gracePeriod;

    /// @notice Address of the contract owner (the scheduler).
    address public owner;

    /// @notice Nonce used to generate unique transaction IDs.
    uint256 private _nonce;

    /// @notice Mapping from transaction hash (keccak256 of the struct) to its scheduled timestamp.
    /// @dev A transaction is pending if its timestamp > 0 and block.timestamp >= timestamp + delay.
    mapping(bytes32 => uint256) private _timestamps;

    /// @notice Whether a transaction has been cancelled.
    mapping(bytes32 => bool) private _cancelled;

    /// @notice Whether a transaction has been executed.
    mapping(bytes32 => bool) private _executed;

    /* ──────────────── Structs ──────────────── */

    /**
     * @notice Describes a scheduled transaction.
     * @param target  The contract address to call.
     * @param value   The amount of ETH to send (in wei).
     * @param data    The calldata to forward.
     * @param nonce   Unique nonce to distinguish identical calls.
     * @param salt    Optional salt for extra uniqueness.
     */
    struct Transaction {
        address target;
        uint256 value;
        bytes data;
        uint256 nonce;
        bytes32 salt;
    }

    /* ──────────────── Events ──────────────── */

    /**
     * @notice Emitted when a new transaction is scheduled.
     * @param txHash      Unique identifier (keccak256 hash) of the transaction.
     * @param target      The address that will be called.
     * @param value       The ETH value to send.
     * @param data        The calldata to forward.
     * @param nonce       Nonce used for uniqueness.
     * @param scheduledAt The block timestamp when the transaction was scheduled.
     */
    event Scheduled(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 nonce,
        uint256 scheduledAt
    );

    /**
     * @notice Emitted when a scheduled transaction is executed.
     * @param txHash      Unique identifier of the executed transaction.
     * @param target      The address that was called.
     * @param value       The ETH value sent.
     * @param data        The calldata forwarded.
     */
    event Executed(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data
    );

    /**
     * @notice Emitted when a scheduled transaction is cancelled.
     * @param txHash Unique identifier of the cancelled transaction.
     */
    event Cancelled(bytes32 indexed txHash);

    /* ──────────────── Modifiers ──────────────── */

    /// @notice Restricts a function to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseTimelock: caller is not the owner");
        _;
    }

    /* ──────────────── Constructor ──────────────── */

    /**
     * @notice Initializes the timelock with a delay and optional grace period.
     * @param _delay        Minimum seconds to wait before a transaction can be executed.
     * @param _gracePeriod  Seconds after (scheduledTime + delay) beyond which the transaction expires.
     *                      Use 0 for no expiry (infinite grace).
     * @dev The delay must be greater than zero.
     */
    constructor(uint256 _delay, uint256 _gracePeriod) {
        require(_delay > 0, "BaseTimelock: delay must be > 0");
        delay = _delay;
        gracePeriod = _gracePeriod;
        owner = msg.sender;
    }

    /* ──────────────── Owner Functions ──────────────── */

    /**
     * @notice Schedules a new transaction for future execution.
     * @param target The address to call.
     * @param value  The amount of ETH (wei) to forward.
     * @param data   The calldata to send.
     * @param salt   An optional salt to guarantee uniqueness.
     * @return txHash The unique keccak256 identifier for the scheduled transaction.
     * @dev Reverts if the target is the zero address.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) external onlyOwner returns (bytes32 txHash) {
        require(target != address(0), "BaseTimelock: invalid target");

        _nonce++;
        txHash = _computeHash(target, value, data, _nonce, salt);

        require(_timestamps[txHash] == 0, "BaseTimelock: already scheduled");
        require(!_executed[txHash], "BaseTimelock: already executed");
        require(!_cancelled[txHash], "BaseTimelock: already cancelled");

        _timestamps[txHash] = block.timestamp;

        emit Scheduled(txHash, target, value, data, _nonce, block.timestamp);
    }

    /**
     * @notice Cancels a previously scheduled transaction.
     * @param txHash The unique identifier of the transaction to cancel.
     * @dev Reverts if the transaction does not exist, is already executed, or already cancelled.
     */
    function cancel(bytes32 txHash) external onlyOwner {
        require(_timestamps[txHash] > 0, "BaseTimelock: not scheduled");
        require(!_executed[txHash], "BaseTimelock: already executed");
        require(!_cancelled[txHash], "BaseTimelock: already cancelled");

        _cancelled[txHash] = true;
        delete _timestamps[txHash];

        emit Cancelled(txHash);
    }

    /* ──────────────── Public Functions ──────────────── */

    /**
     * @notice Executes a previously scheduled transaction after the delay has passed.
     * @param target The address to call.
     * @param value  The amount of ETH (wei) to forward.
     * @param data   The calldata to send.
     * @param nonce  The nonce used when scheduling.
     * @param salt   The salt used when scheduling.
     * @return result The raw bytes returned by the target call.
     * @dev Anyone can call this once the delay has elapsed. Reverts if the delay has not passed
     *      or if the grace period has been exceeded.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 nonce,
        bytes32 salt
    ) external payable returns (bytes memory result) {
        bytes32 txHash = _computeHash(target, value, data, nonce, salt);

        require(_timestamps[txHash] > 0, "BaseTimelock: not scheduled");
        require(!_cancelled[txHash], "BaseTimelock: cancelled");
        require(!_executed[txHash], "BaseTimelock: already executed");

        uint256 scheduledAt = _timestamps[txHash];
        require(block.timestamp >= scheduledAt + delay, "BaseTimelock: delay not met");

        // Grace period expiry check
        if (gracePeriod > 0) {
            require(
                block.timestamp <= scheduledAt + delay + gracePeriod,
                "BaseTimelock: expired"
            );
        }

        _executed[txHash] = true;
        delete _timestamps[txHash];

        (bool success, bytes memory ret) = target.call{value: value}(data);
        require(success, "BaseTimelock: call failed");

        emit Executed(txHash, target, value, data);

        return ret;
    }

    /* ──────────────── Query Functions ──────────────── */

    /**
     * @notice Returns the status of a transaction by its hash.
     * @param txHash The unique identifier of the transaction.
     * @return scheduledAt The timestamp when the transaction was scheduled (0 if never scheduled).
     * @return isExecuted  Whether the transaction has been executed.
     * @return isCancelled Whether the transaction has been cancelled.
     */
    function getTransactionStatus(bytes32 txHash)
        external
        view
        returns (uint256 scheduledAt, bool isExecuted, bool isCancelled)
    {
        return (_timestamps[txHash], _executed[txHash], _cancelled[txHash]);
    }

    /**
     * @notice Computes the unique hash for a transaction.
     * @param target The target address.
     * @param value  The ETH value.
     * @param data   The calldata.
     * @param nonce  The nonce.
     * @param salt   The salt.
     * @return txHash The keccak256 hash uniquely identifying the transaction.
     */
    function computeHash(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 nonce,
        bytes32 salt
    ) external pure returns (bytes32 txHash) {
        return _computeHash(target, value, data, nonce, salt);
    }

    /// @dev Internal function to compute the transaction hash.
    function _computeHash(
        address target,
        uint256 value,
        bytes memory data,
        uint256 nonce,
        bytes32 salt
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(target, value, data, nonce, salt));
    }
}
