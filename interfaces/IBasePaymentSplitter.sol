// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBasePaymentSplitter
 * @notice Interface for the BasePaymentSplitter ETH splitter contract
 */
interface IBasePaymentSplitter {
    /// @notice Emitted when a payee is added
    event PayeeAdded(address indexed payee, uint256 shares);
    /// @notice Emitted when a payment is released
    event PaymentReleased(address indexed payee, uint256 amount);

    /// @notice The contract owner
    function owner() external view returns (address);
    /// @notice Payee info by index
    function payees(uint256 index) external view returns (address addr, uint256 shares);
    /// @notice Total shares across all payees
    function totalShares() external view returns (uint256);
    /// @notice Amount released to each payee
    function released(address payee) external view returns (uint256);

    /**
     * @notice Calculate pending payment for a payee
     * @param _payee Address of the payee
     * @return uint256 Amount pending (in wei)
     */
    function pendingPayment(address _payee) external view returns (uint256);

    /**
     * @notice Release pending payment to a specific payee
     * @param _payee Address of the payee
     */
    function release(address _payee) external;

    /**
     * @notice Release payments to all payees at once
     */
    function releaseAll() external;

    /**
     * @notice Get the number of payees
     * @return uint256 Payee count
     */
    function payeeCount() external view returns (uint256);
}
