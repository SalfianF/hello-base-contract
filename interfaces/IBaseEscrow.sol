// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseEscrow
 * @notice Interface for the BaseEscrow tri-party escrow contract
 */
interface IBaseEscrow {
    /// @notice Emitted when the buyer deposits funds
    event Deposited(address indexed buyer, uint256 amount);
    /// @notice Emitted when the buyer confirms receipt
    event Released(address indexed seller, uint256 amount);
    /// @notice Emitted when a dispute is raised
    event DisputeRaised(address indexed raisedBy);
    /// @notice Emitted when the arbiter resolves a dispute
    event DisputeResolved(address indexed recipient, uint256 amount);
    /// @notice Emitted when the escrow is cancelled
    event Cancelled(address indexed buyer, uint256 amount);

    /// @notice The buyer address
    function buyer() external view returns (address);
    /// @notice The seller address
    function seller() external view returns (address);
    /// @notice The arbiter address
    function arbiter() external view returns (address);
    /// @notice The escrowed amount in wei
    function amount() external view returns (uint256);
    /// @notice Whether the buyer has confirmed receipt
    function confirmed() external view returns (bool);
    /// @notice Whether a dispute is active
    function disputed() external view returns (bool);
    /// @notice Whether the escrow has been resolved
    function resolved() external view returns (bool);
    /// @notice Whether the escrow has been cancelled
    function cancelled() external view returns (bool);

    /**
     * @notice Deposit ETH into escrow
     * @dev Must be called by the buyer
     */
    function deposit() external payable;

    /**
     * @notice Buyer confirms receipt of goods/services, releasing funds to the seller
     */
    function confirmReceipt() external;

    /**
     * @notice Raise a dispute. Can be called by either the buyer or the seller
     */
    function raiseDispute() external;

    /**
     * @notice Arbiter resolves the dispute by awarding funds to either buyer or seller
     * @param recipient The address that should receive the escrowed funds
     */
    function resolveDispute(address recipient) external;

    /**
     * @notice Cancels the escrow and refunds the buyer
     * @dev Only the buyer can cancel
     */
    function cancel() external;

    /**
     * @notice Returns the full escrow status
     * @return buyerAddr    The buyer's address
     * @return sellerAddr   The seller's address
     * @return arbiterAddr  The arbiter's address
     * @return escrowAmount The amount currently held in escrow (wei)
     * @return isConfirmed  Whether the buyer has confirmed receipt
     * @return isDisputed   Whether a dispute is active
     * @return isResolved   Whether the escrow has been resolved
     * @return isCancelled  Whether the escrow has been cancelled
     */
    function getStatus()
        external
        view
        returns (
            address buyerAddr,
            address sellerAddr,
            address arbiterAddr,
            uint256 escrowAmount,
            bool isConfirmed,
            bool isDisputed,
            bool isResolved,
            bool isCancelled
        );
}
