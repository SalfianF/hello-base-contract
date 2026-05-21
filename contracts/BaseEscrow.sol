// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseEscrow
 * @notice A tri-party escrow contract on Base with a buyer, seller, and arbiter.
 * @dev The buyer deposits ETH into escrow. If satisfied, the buyer confirms receipt and funds
 *      are released to the seller. If a dispute arises, the arbiter can decide which party
 *      receives the funds. Each escrow instance handles a single transaction.
 */
contract BaseEscrow {
    /* ──────────────── State Variables ──────────────── */

    /// @notice The buyer (depositor) of the escrow.
    address public buyer;

    /// @notice The seller (beneficiary) of the escrow.
    address public seller;

    /// @notice The arbiter who resolves disputes.
    address public arbiter;

    /// @notice The amount of ETH (in wei) deposited in escrow.
    uint256 public amount;

    /// @notice Whether the buyer has confirmed receipt, releasing funds to the seller.
    bool public confirmed;

    /// @notice Whether a dispute has been raised.
    bool public disputed;

    /// @notice Whether the escrow has been resolved (funds released to either party).
    bool public resolved;

    /// @notice Whether the escrow has been cancelled (buyer refunded).
    bool public cancelled;

    /* ──────────────── Events ──────────────── */

    /**
     * @notice Emitted when the buyer deposits funds into escrow.
     * @param buyer  The address of the buyer.
     * @param amount The amount deposited (in wei).
     */
    event Deposited(address indexed buyer, uint256 amount);

    /**
     * @notice Emitted when the buyer confirms receipt, releasing funds to the seller.
     * @param seller The address of the seller receiving the funds.
     * @param amount The amount released (in wei).
     */
    event Released(address indexed seller, uint256 amount);

    /**
     * @notice Emitted when a dispute is raised by either the buyer or seller.
     * @param raisedBy The address that raised the dispute.
     */
    event DisputeRaised(address indexed raisedBy);

    /**
     * @notice Emitted when the arbiter resolves a dispute.
     * @param recipient The address that receives the escrowed funds.
     * @param amount    The amount awarded (in wei).
     */
    event DisputeResolved(address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when the escrow is cancelled and the buyer is refunded.
     * @param buyer  The address of the refunded buyer.
     * @param amount The refunded amount (in wei).
     */
    event Cancelled(address indexed buyer, uint256 amount);

    /* ──────────────── Modifiers ──────────────── */

    /// @notice Restricts a function to the buyer.
    modifier onlyBuyer() {
        require(msg.sender == buyer, "BaseEscrow: caller is not the buyer");
        _;
    }

    /// @notice Restricts a function to the seller.
    modifier onlySeller() {
        require(msg.sender == seller, "BaseEscrow: caller is not the seller");
        _;
    }

    /// @notice Restricts a function to the arbiter.
    modifier onlyArbiter() {
        require(msg.sender == arbiter, "BaseEscrow: caller is not the arbiter");
        _;
    }

    /* ──────────────── Constructor ──────────────── */

    /**
     * @notice Initializes the escrow contract with buyer, seller, and arbiter addresses.
     * @param _buyer   The address of the buyer.
     * @param _seller  The address of the seller.
     * @param _arbiter The address of the arbiter.
     * @dev All three addresses must be non-zero and distinct from each other (buyer != seller).
     */
    constructor(address _buyer, address _seller, address _arbiter) {
        require(_buyer != address(0), "BaseEscrow: invalid buyer");
        require(_seller != address(0), "BaseEscrow: invalid seller");
        require(_arbiter != address(0), "BaseEscrow: invalid arbiter");
        require(_buyer != _seller, "BaseEscrow: buyer and seller must differ");

        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
    }

    /* ──────────────── External Functions ──────────────── */

    /**
     * @notice Deposit ETH into escrow. Must be called by the buyer.
     * @dev Reverts if escrow has already been resolved or cancelled, or if the caller is not the buyer.
     *      The deposited amount is fixed — a second deposit overwrites.
     */
    function deposit() external payable onlyBuyer {
        require(!resolved, "BaseEscrow: already resolved");
        require(!cancelled, "BaseEscrow: already cancelled");
        require(!disputed, "BaseEscrow: dispute active — resolve first");
        require(msg.value > 0, "BaseEscrow: must deposit > 0");

        amount = msg.value;

        emit Deposited(buyer, amount);
    }

    /**
     * @notice Buyer confirms receipt of goods/services, releasing funds to the seller.
     * @dev Reverts if there is no deposit, a dispute is active, or escrow is already resolved/cancelled.
     */
    function confirmReceipt() external onlyBuyer {
        require(amount > 0, "BaseEscrow: no funds deposited");
        require(!confirmed, "BaseEscrow: already confirmed");
        require(!disputed, "BaseEscrow: dispute active — resolve first");
        require(!resolved, "BaseEscrow: already resolved");
        require(!cancelled, "BaseEscrow: already cancelled");

        confirmed = true;
        resolved = true;
        uint256 payout = amount;
        amount = 0;

        (bool sent, ) = payable(seller).call{value: payout}("");
        require(sent, "BaseEscrow: transfer to seller failed");

        emit Released(seller, payout);
    }

    /**
     * @notice Raise a dispute. Can be called by either the buyer or the seller.
     * @dev Reverts if already disputed, resolved, or cancelled.
     */
    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "BaseEscrow: only buyer or seller");
        require(amount > 0, "BaseEscrow: no funds deposited");
        require(!disputed, "BaseEscrow: already disputed");
        require(!resolved, "BaseEscrow: already resolved");
        require(!cancelled, "BaseEscrow: already cancelled");

        disputed = true;

        emit DisputeRaised(msg.sender);
    }

    /**
     * @notice Arbiter resolves the dispute by awarding funds to either the buyer or seller.
     * @param recipient The address that should receive the escrowed funds (buyer or seller).
     * @dev Can only be called by the arbiter. Reverts if no dispute is active.
     *      The recipient must be either the buyer or the seller.
     */
    function resolveDispute(address recipient) external onlyArbiter {
        require(disputed, "BaseEscrow: no active dispute");
        require(!resolved, "BaseEscrow: already resolved");
        require(!cancelled, "BaseEscrow: already cancelled");
        require(recipient == buyer || recipient == seller, "BaseEscrow: recipient must be buyer or seller");
        require(amount > 0, "BaseEscrow: no funds to release");

        disputed = false;
        resolved = true;
        uint256 payout = amount;
        amount = 0;

        (bool sent, ) = payable(recipient).call{value: payout}("");
        require(sent, "BaseEscrow: transfer failed");

        emit DisputeResolved(recipient, payout);
    }

    /**
     * @notice Cancels the escrow and refunds the buyer. Only the buyer can cancel.
     * @dev Can only be called before a deposit is confirmed or a dispute is resolved.
     *      Reverts if already resolved or cancelled.
     */
    function cancel() external onlyBuyer {
        require(!confirmed, "BaseEscrow: already confirmed");
        require(!resolved, "BaseEscrow: already resolved");
        require(!cancelled, "BaseEscrow: already cancelled");
        require(amount > 0, "BaseEscrow: no funds to refund");

        cancelled = true;
        uint256 refund = amount;
        amount = 0;

        (bool sent, ) = payable(buyer).call{value: refund}("");
        require(sent, "BaseEscrow: refund failed");

        emit Cancelled(buyer, refund);
    }

    /* ──────────────── View Functions ──────────────── */

    /**
     * @notice Returns the full escrow status.
     * @return buyerAddr    The buyer's address.
     * @return sellerAddr   The seller's address.
     * @return arbiterAddr  The arbiter's address.
     * @return escrowAmount The amount currently held in escrow (wei).
     * @return isConfirmed  Whether the buyer has confirmed receipt.
     * @return isDisputed   Whether a dispute is active.
     * @return isResolved   Whether the escrow has been resolved.
     * @return isCancelled  Whether the escrow has been cancelled.
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
        )
    {
        return (buyer, seller, arbiter, amount, confirmed, disputed, resolved, cancelled);
    }
}
