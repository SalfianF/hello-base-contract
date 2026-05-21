// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMultiSig
 * @notice Interface for MultiSig contract
 * @dev Defines the external functions for an N-of-M multi-signature wallet
 */
interface IMultiSig {
    /**
     * @notice Represents a submitted transaction
     * @param to Target address
     * @param value ETH value to send (in wei)
     * @param data Calldata for the target call
     * @param executed Whether the transaction has been executed
     * @param confirmations Number of confirmations received
     */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    /**
     * @notice Emitted when a new transaction is submitted
     * @param txIndex Index of the new transaction
     * @param to Target address
     * @param value ETH value to send
     */
    event TransactionSubmitted(uint256 indexed txIndex, address indexed to, uint256 value);

    /**
     * @notice Emitted when a signer confirms a transaction
     * @param txIndex Index of the confirmed transaction
     * @param signer Address of the confirming signer
     */
    event TransactionConfirmed(uint256 indexed txIndex, address indexed signer);

    /**
     * @notice Emitted when a transaction is executed
     * @param txIndex Index of the executed transaction
     */
    event TransactionExecuted(uint256 indexed txIndex);

    /**
     * @notice Get a signer address by index
     * @param index Index in the signers array
     * @return address The signer address
     */
    function signers(uint256 index) external view returns (address);

    /**
     * @notice Get the number of confirmations required to execute
     * @return uint256 Required confirmations
     */
    function required() external view returns (uint256);

    /**
     * @notice Get a transaction by index
     * @param txIndex Index of the transaction
     * @return Transaction The transaction details
     */
    function transactions(uint256 txIndex) external view returns (Transaction memory);

    /**
     * @notice Check if a signer confirmed a specific transaction
     * @param txIndex Index of the transaction
     * @param signer Address of the signer
     * @return bool True if confirmed
     */
    function confirmed(uint256 txIndex, address signer) external view returns (bool);

    /**
     * @notice Check if an address is a signer
     * @param account Address to check
     * @return bool True if the account is a signer
     */
    function isSigner(address account) external view returns (bool);

    /**
     * @notice Submit a new transaction for signers to confirm
     * @param to Target address
     * @param value ETH value to send (in wei)
     * @param data Calldata for the target call
     */
    function submitTransaction(address to, uint256 value, bytes calldata data) external;

    /**
     * @notice Confirm a pending transaction
     * @param txIndex Index of the transaction in the array
     */
    function confirmTransaction(uint256 txIndex) external;

    /**
     * @notice Execute a confirmed transaction
     * @param txIndex Index of the transaction to execute
     */
    function executeTransaction(uint256 txIndex) external;
}
