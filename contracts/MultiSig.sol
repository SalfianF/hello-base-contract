// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    modifier onlySigner() {
        require(isSigner(msg.sender), "MultiSig: not a signer");
        _;
    }

    constructor(address[] memory signers_, uint256 required_) {
        require(signers_.length >= required_, "MultiSig: insufficient signers");
        require(required_ > 0, "MultiSig: required must be > 0");
        signers = signers_;
        required = required_;
    }

    function isSigner(address account) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == account) return true;
        }
        return false;
    }

    function submitTransaction(address to, uint256 value, bytes calldata data) external onlySigner {
        transactions.push(Transaction(to, value, data, false, 1));
        confirmed[transactions.length - 1][msg.sender] = true;
    }

    function confirmTransaction(uint256 txIndex) external onlySigner {
        require(txIndex < transactions.length, "MultiSig: invalid index");
        require(!confirmed[txIndex][msg.sender], "MultiSig: already confirmed");
        confirmed[txIndex][msg.sender] = true;
        transactions[txIndex].confirmations++;
    }

    function executeTransaction(uint256 txIndex) external {
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "MultiSig: already executed");
        require(txn.confirmations >= required, "MultiSig: not enough confirmations");
        txn.executed = true;
        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        require(success, "MultiSig: execution failed");
    }
}