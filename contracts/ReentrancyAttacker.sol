// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancyAttacker
 * @notice Malicious contract used to test reentrancy protection in Vault
 * @dev Attempts to re-enter the Vault's withdraw function via receive fallback
 */
contract ReentrancyAttacker {
    address public vault;
    uint256 public attackAmount;

    constructor(address vault_) {
        vault = vault_;
    }

    /**
     * @notice Initiate the reentrancy attack
     * @dev First deposits ETH into the vault, then triggers withdraw
     */
    function attack() external payable {
        (bool depositSuccess, ) = vault.call{value: msg.value}("");
        require(depositSuccess, "deposit failed");
        (bool withdrawSuccess, ) = vault.call(
            abi.encodeWithSignature("withdraw(uint256)", msg.value)
        );
        require(withdrawSuccess, "withdraw should have succeeded");
    }

    /**
     * @notice Fallback that attempts reentrancy
     * @dev If the vault tries to send ETH here, we try to re-enter withdraw
     */
    receive() external payable {
        // Attempt reentrancy: call withdraw again
        (bool success, ) = vault.call(
            abi.encodeWithSignature("withdraw(uint256)", attackAmount)
        );
        // If the call somehow succeeded, the guard failed
        if (success) {
            // Force a revert to signal the test that reentrancy was possible
            revert("ReentrancyGuard FAILED");
        }
    }
}
