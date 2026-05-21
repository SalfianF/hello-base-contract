// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseAirdrop
 * @notice Interface for the BaseAirdrop Merkle tree-based token airdrop contract
 */
interface IBaseAirdrop {
    /// @notice Emitted when a user claims tokens
    event Claimed(address indexed user, uint256 amount);
    /// @notice Emitted when the Merkle root is updated
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    /// @notice The contract owner
    function owner() external view returns (address);
    /// @notice The token being distributed
    function token() external view returns (address);
    /// @notice The Merkle root of the claim tree
    function merkleRoot() external view returns (bytes32);
    /// @notice The claim period end timestamp
    function claimPeriodEnd() external view returns (uint256);
    /// @notice Whether an address has claimed
    function claimed(address user) external view returns (bool);

    /**
     * @notice Claim airdrop tokens
     * @param _amount Amount of tokens to claim
     * @param _proof Merkle proof verifying the claim
     */
    function claim(uint256 _amount, bytes32[] calldata _proof) external;

    /**
     * @notice Check if an address has claimed
     * @param user Address to check
     * @return bool True if already claimed
     */
    function hasClaimed(address user) external view returns (bool);

    /**
     * @notice Check if claim period is still active
     * @return bool True if claiming is still open
     */
    function isClaimActive() external view returns (bool);
}
