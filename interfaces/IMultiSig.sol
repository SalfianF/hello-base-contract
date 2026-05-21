// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMultiSig
 * @notice Interface for MultiSig contract with dynamic signer management
 * @dev Defines the external functions for an N-of-M multi-signature wallet
 */
interface IMultiSig {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    event TransactionSubmitted(uint256 indexed txIndex, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txIndex, address indexed signer);
    event TransactionRevoked(uint256 indexed txIndex, address indexed signer);
    event TransactionExecuted(uint256 indexed txIndex);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    // Getters
    function signers(uint256 index) external view returns (address);
    function required() external view returns (uint256);
    function signerCount() external view returns (uint256);
    function transactions(uint256 txIndex) external view returns (Transaction memory);
    function confirmed(uint256 txIndex, address signer) external view returns (bool);
    function isSigner(address account) external view returns (bool);
    function getSigners() external view returns (address[] memory);

    // Signer management
    function addSigner(address signer) external;
    function removeSigner(address signer) external;

    // Transaction lifecycle
    function submitTransaction(address to, uint256 value, bytes calldata data) external;
    function confirmTransaction(uint256 txIndex) external;
    function revokeConfirmation(uint256 txIndex) external;
    function executeTransaction(uint256 txIndex) external;
}
