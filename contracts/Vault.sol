// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Vault
 * @notice Simple ETH vault for depositing and withdrawing funds
 * @dev Uses ReentrancyGuard to protect against reentrancy attacks on withdrawals
 */
contract Vault is ReentrancyGuard {
    mapping(address => uint256) private _balances;
    address public owner;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Deposit ETH into the vault
     * @dev Increments user balance by the sent value
     */
    function deposit() external payable {
        _balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH from the vault
     * @dev Uses nonReentrant modifier and call pattern instead of transfer for safety
     * @param amount Amount of ETH to withdraw (in wei)
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(_balances[msg.sender] >= amount, "Vault: insufficient balance");
        _balances[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Vault: withdrawal failed");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Check the balance of a user
     * @param user Address of the user
     * @return uint256 The balance of the user
     */
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /**
     * @notice Receive ETH directly and credit the sender
     * @dev Falls back to deposit logic
     */
    receive() external payable {
        _balances[msg.sender] += msg.value;
    }
}
