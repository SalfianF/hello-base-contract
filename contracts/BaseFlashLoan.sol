// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IBaseFlashLoanReceiver
 * @notice Interface for contracts that receive flash loans
 */
interface IBaseFlashLoanReceiver {
    /**
     * @notice Callback after flash loan is executed
     * @param initiator Address that initiated the flash loan
     * @param amount Amount of ETH borrowed
     * @param fee Fee charged for the loan
     * @param data Arbitrary data passed by caller
     */
    function executeOperation(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool);
}

/**
 * @title BaseFlashLoan
 * @notice Flash loan contract — borrow ETH without collateral, repay in same tx with 0.09% fee
 * @dev Borrower must implement IBaseFlashLoanReceiver and have the repayment ready by callback end
 */
contract BaseFlashLoan is Ownable {
    /// @notice Fee in basis points (9 bps = 0.09%)
    uint256 public flashLoanFee;
    /// @notice Maximum flash loan fee in basis points (1%)
    uint256 public constant MAX_FEE = 100;
    /// @notice Tracks total fees collected
    uint256 public totalFeesCollected;

    event FlashLoan(
        address indexed receiver,
        address indexed initiator,
        uint256 amount,
        uint256 fee,
        bool success
    );
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(uint256 amount, address indexed to);

    constructor(uint256 _flashLoanFee) Ownable(msg.sender) {
        require(_flashLoanFee <= MAX_FEE, "BaseFlashLoan: fee exceeds max");
        flashLoanFee = _flashLoanFee;
    }

    /**
     * @notice Execute a flash loan
     * @param receiver Address of the contract implementing IBaseFlashLoanReceiver
     * @param amount Amount of ETH to borrow (in wei)
     * @param data Arbitrary data to pass to the receiver
     */
    function flashLoan(
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external {
        require(receiver != address(0), "BaseFlashLoan: invalid receiver");
        require(amount > 0, "BaseFlashLoan: amount must be > 0");
        require(address(this).balance >= amount, "BaseFlashLoan: insufficient balance");

        uint256 fee = (amount * flashLoanFee) / 10000;
        uint256 totalOwed = amount + fee;

        // Transfer ETH to receiver
        payable(receiver).transfer(amount);

        // Execute callback
        bool success = IBaseFlashLoanReceiver(receiver).executeOperation(
            msg.sender,
            amount,
            fee,
            data
        );
        require(success, "BaseFlashLoan: callback failed");

        // Verify repayment
        require(
            address(this).balance >= totalOwed,
            "BaseFlashLoan: loan not repaid"
        );

        totalFeesCollected += fee;
        emit FlashLoan(receiver, msg.sender, amount, fee, true);
    }

    /**
     * @notice Withdraw accumulated fees (owner only)
     * @param to Address to send fees to
     */
    function withdrawFees(address payable to) external onlyOwner {
        require(to != address(0), "BaseFlashLoan: invalid address");
        uint256 balance = address(this).balance;
        require(balance > 0, "BaseFlashLoan: no fees to withdraw");
        totalFeesCollected = 0;
        to.transfer(balance);
        emit FeesWithdrawn(balance, to);
    }

    /**
     * @notice Update flash loan fee (owner only)
     * @param _newFee New fee in basis points
     */
    function setFlashLoanFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_FEE, "BaseFlashLoan: fee exceeds max");
        uint256 oldFee = flashLoanFee;
        flashLoanFee = _newFee;
        emit FeeUpdated(oldFee, _newFee);
    }

    receive() external payable {}
}
