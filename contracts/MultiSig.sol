// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IMultiSig.sol";

/**
 * @title MultiSig
 * @notice Multi-signature wallet with dynamic signer management
 * @dev Requires N-of-M signers to confirm before execution;
 *      supports adding/removing signers and revoking confirmations.
 *      Implements ERC-165 for interface detection.
 */
contract MultiSig is ERC165 {
    address[] public signers;
    uint256 public required;
    uint256 public signerCount;

    mapping(address => bool) public isSigner;

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
    event TransactionRevoked(uint256 indexed txIndex, address indexed signer);
    event TransactionExecuted(uint256 indexed txIndex);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    modifier onlySigner() {
        require(isSigner[msg.sender], "MultiSig: not a signer");
        _;
    }

    /**
     * @notice Create the multi-signature wallet
     * @param signers_ Array of initial signer addresses
     * @param required_ Number of confirmations needed to execute
     */
    constructor(address[] memory signers_, uint256 required_) {
        require(signers_.length >= required_, "MultiSig: insufficient signers");
        require(required_ > 0, "MultiSig: required must be > 0");

        for (uint256 i = 0; i < signers_.length; i++) {
            address signer = signers_[i];
            require(signer != address(0), "MultiSig: zero address");
            require(!isSigner[signer], "MultiSig: duplicate signer");
            signers.push(signer);
            isSigner[signer] = true;
        }
        signerCount = signers_.length;
        required = required_;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IMultiSig).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Add a new signer
     * @dev Only callable by existing signers
     * @param signer Address of the new signer
     */
    function addSigner(address signer) external onlySigner {
        require(signer != address(0), "MultiSig: zero address");
        require(!isSigner[signer], "MultiSig: already a signer");
        signers.push(signer);
        isSigner[signer] = true;
        signerCount++;
        emit SignerAdded(signer);
    }

    /**
     * @notice Remove an existing signer
     * @dev Only callable by existing signers; cannot reduce below required threshold
     * @param signer Address of the signer to remove
     */
    function removeSigner(address signer) external onlySigner {
        require(isSigner[signer], "MultiSig: not a signer");
        require(signerCount - 1 >= required, "MultiSig: would fall below required");

        isSigner[signer] = false;
        signerCount--;

        // Remove from the signers array by swapping with the last element
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(signer);
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
        require(to != address(0), "MultiSig: zero target");
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
        require(!transactions[txIndex].executed, "MultiSig: already executed");
        confirmed[txIndex][msg.sender] = true;
        transactions[txIndex].confirmations++;
        emit TransactionConfirmed(txIndex, msg.sender);
    }

    /**
     * @notice Revoke a previous confirmation
     * @dev Allows a signer to undo a mistaken confirmation before execution
     * @param txIndex Index of the transaction
     */
    function revokeConfirmation(uint256 txIndex) external onlySigner {
        require(txIndex < transactions.length, "MultiSig: invalid index");
        require(confirmed[txIndex][msg.sender], "MultiSig: not confirmed");
        require(!transactions[txIndex].executed, "MultiSig: already executed");
        confirmed[txIndex][msg.sender] = false;
        transactions[txIndex].confirmations--;
        emit TransactionRevoked(txIndex, msg.sender);
    }

    /**
     * @notice Execute a confirmed transaction
     * @dev Anyone can call this once the confirmation threshold is met
     * @param txIndex Index of the transaction to execute
     */
    function executeTransaction(uint256 txIndex) external {
        require(txIndex < transactions.length, "MultiSig: invalid index");
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "MultiSig: already executed");
        require(txn.confirmations >= required, "MultiSig: not enough confirmations");
        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "MultiSig: execution failed");
        emit TransactionExecuted(txIndex);
    }

    /**
     * @notice Get signer list (for off-chain queries)
     * @return address[] Array of current signers
     */
    function getSigners() external view returns (address[] memory) {
        return signers;
    }
}
