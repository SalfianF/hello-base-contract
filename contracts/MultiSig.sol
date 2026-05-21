// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MultiSig
 * @notice Multi-signature wallet for collective transaction approval
 * @dev Requires N-of-M signers to confirm before execution; uses call pattern
 */
contract MultiSig {
    address[] public signers;
    uint256 public required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    event TransactionSubmitted(uint256 indexed txIndex, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txIndex, address indexed signer);
    event TransactionExecuted(uint256 indexed txIndex);

    modifier onlySigner() {
        require(isSigner(msg.sender), "MultiSig: not a signer");
        _;
    }

    /**
     * @notice Create the multi-signature wallet
     * @param signers_ Array of addresses that are signers
     * @param required_ Number of confirmations needed to execute
     * @dev Reverts if signers_.length < required_ or required_ == 0
     */
    constructor(address[] memory signers_, uint256 required_) {
        require(signers_.length >= required_, "MultiSig: insufficient signers");
        require(required_ > 0, "MultiSig: required must be > 0");
        signers = signers_;
        required = required_;
    }

    /**
     * @notice Check if an address is a signer
     * @param account Address to check
     * @return bool True if the account is a signer
     */
    function isSigner(address account) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == account) return true;
        }
        return false;
    }

    /**
     * @notice Submit a new transaction for signers to confirm
     * @dev The submitter auto-confirms on submission
     * @param to Target address
     * @param value ETH value to send (in wei)
     * @param data Calldata for the target call
     */
    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlySigner {
        transactions.push(Transaction(to, value, data, false, 1));
        confirmed[transactions.length - 1][msg.sender] = true;
        emit TransactionSubmitted(transactions.length - 1, to, value);
    }

    /**
     * @notice Confirm a pending transaction
     * @param txIndex Index of the transaction in the array
     */
    function confirmTransaction(uint256 txIndex) external onlySigner {
        require(txIndex < transactions.length, "MultiSig: invalid index");
        require(!confirmed[txIndex][msg.sender], "MultiSig: already confirmed");
        confirmed[txIndex][msg.sender] = true;
        transactions[txIndex].confirmations++;
        emit TransactionConfirmed(txIndex, msg.sender);
    }

    /**
     * @notice Execute a confirmed transaction
     * @dev Anyone can call this once the confirmation threshold is met
     * @param txIndex Index of the transaction to execute
     */
    function executeTransaction(uint256 txIndex) external {
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "MultiSig: already executed");
        require(txn.confirmations >= required, "MultiSig: not enough confirmations");
        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "MultiSig: execution failed");
        emit TransactionExecuted(txIndex);
    }
}
