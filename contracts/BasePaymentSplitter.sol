// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BasePaymentSplitter
 * @notice Split received ETH among multiple payees by predefined shares
 * @dev Similar to OpenZeppelin PaymentSplitter, redistributes proportionally
 */
contract BasePaymentSplitter {
    address public owner;

    struct Payee {
        address addr;
        uint256 shares;
    }

    Payee[] public payees;
    uint256 public totalShares;
    mapping(address => uint256) public released;

    event PayeeAdded(address indexed payee, uint256 shares);
    event PaymentReleased(address indexed payee, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "BasePaymentSplitter: only owner");
        _;
    }

    /**
     * @notice Create a payment splitter
     * @param _payees Array of payee addresses
     * @param _shares Array of corresponding share weights
     * @dev Arrays must have same length and at least one payee
     */
    constructor(address[] memory _payees, uint256[] memory _shares) {
        require(_payees.length == _shares.length, "BasePaymentSplitter: length mismatch");
        require(_payees.length > 0, "BasePaymentSplitter: no payees");
        owner = msg.sender;
        for (uint256 i = 0; i < _payees.length; i++) {
            require(_payees[i] != address(0), "BasePaymentSplitter: zero address");
            require(_shares[i] > 0, "BasePaymentSplitter: zero shares");
            payees.push(Payee(_payees[i], _shares[i]));
            totalShares += _shares[i];
            emit PayeeAdded(_payees[i], _shares[i]);
        }
    }

    /**
     * @notice Calculate pending payment for a payee
     * @param _payee Address of the payee
     * @return uint256 Amount pending (in wei)
     */
    function pendingPayment(address _payee) public view returns (uint256) {
        uint256 totalReceived = address(this).balance;
        for (uint256 i = 0; i < payees.length; i++) {
            totalReceived += released[payees[i].addr];
        }
        uint256 shares = 0;
        for (uint256 i = 0; i < payees.length; i++) {
            if (payees[i].addr == _payee) {
                shares = payees[i].shares;
                break;
            }
        }
        require(shares > 0, "BasePaymentSplitter: not a payee");
        uint256 owed = (totalReceived * shares) / totalShares;
        return owed - released[_payee];
    }

    /**
     * @notice Release pending payment to a specific payee
     * @param _payee Address of the payee
     */
    function release(address _payee) external onlyOwner {
        uint256 amount = pendingPayment(_payee);
        require(amount > 0, "BasePaymentSplitter: nothing to release");
        released[_payee] += amount;
        (bool success, ) = payable(_payee).call{value: amount}("");
        require(success, "BasePaymentSplitter: transfer failed");
        emit PaymentReleased(_payee, amount);
    }

    /**
     * @notice Release payments to all payees at once
     */
    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            uint256 amount = pendingPayment(payees[i].addr);
            if (amount > 0) {
                released[payees[i].addr] += amount;
                (bool success, ) = payable(payees[i].addr).call{value: amount}("");
                require(success, "BasePaymentSplitter: transfer failed");
                emit PaymentReleased(payees[i].addr, amount);
            }
        }
    }

    /**
     * @notice Get the number of payees
     * @return uint256 Payee count
     */
    function payeeCount() external view returns (uint256) {
        return payees.length;
    }
}
