// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseTimelock
 * @notice Interface for the BaseTimelock timelock controller contract
 */
interface IBaseTimelock {
    /// @notice Emitted when a new transaction is scheduled
    event Scheduled(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 nonce,
        uint256 scheduledAt
    );
    /// @notice Emitted when a scheduled transaction is executed
    event Executed(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data
    );
    /// @notice Emitted when a scheduled transaction is cancelled
    event Cancelled(bytes32 indexed txHash);

    /// @notice The minimum delay in seconds before a scheduled transaction can be executed
    function delay() external view returns (uint256);
    /// @notice The grace period after which a scheduled transaction expires
    function gracePeriod() external view returns (uint256);
    /// @notice The contract owner (scheduler)
    function owner() external view returns (address);

    /**
     * @notice Schedules a new transaction for future execution
     * @param target The address to call
     * @param value  The amount of ETH (wei) to forward
     * @param data   The calldata to send
     * @param salt   An optional salt to guarantee uniqueness
     * @return txHash The unique keccak256 identifier for the scheduled transaction
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) external returns (bytes32 txHash);

    /**
     * @notice Cancels a previously scheduled transaction
     * @param txHash The unique identifier of the transaction to cancel
     */
    function cancel(bytes32 txHash) external;

    /**
     * @notice Executes a previously scheduled transaction after the delay has passed
     * @param target The address to call
     * @param value  The amount of ETH (wei) to forward
     * @param data   The calldata to send
     * @param nonce  The nonce used when scheduling
     * @param salt   The salt used when scheduling
     * @return result The raw bytes returned by the target call
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 nonce,
        bytes32 salt
    ) external payable returns (bytes memory result);

    /**
     * @notice Returns the status of a transaction by its hash
     * @param txHash The unique identifier of the transaction
     * @return scheduledAt The timestamp when the transaction was scheduled
     * @return isExecuted  Whether the transaction has been executed
     * @return isCancelled Whether the transaction has been cancelled
     */
    function getTransactionStatus(bytes32 txHash)
        external
        view
        returns (uint256 scheduledAt, bool isExecuted, bool isCancelled);

    /**
     * @notice Computes the unique hash for a transaction
     * @param target The target address
     * @param value  The ETH value
     * @param data   The calldata
     * @param nonce  The nonce
     * @param salt   The salt
     * @return txHash The keccak256 hash uniquely identifying the transaction
     */
    function computeHash(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 nonce,
        bytes32 salt
    ) external pure returns (bytes32 txHash);
}
