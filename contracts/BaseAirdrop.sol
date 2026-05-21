// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title BaseAirdrop
 * @notice Merkle tree-based token airdrop claim contract
 * @dev Users claim tokens by providing a valid Merkle proof
 */
contract BaseAirdrop {
    address public owner;
    address public token;
    bytes32 public merkleRoot;
    uint256 public claimPeriodEnd;

    mapping(address => bool) public claimed;

    event Claimed(address indexed user, uint256 amount);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    modifier onlyOwner() {
        require(msg.sender == owner, "BaseAirdrop: only owner");
        _;
    }

    /**
     * @notice Initialize the airdrop
     * @param _token Address of the ERC20 token to distribute
     * @param _merkleRoot Root of the Merkle tree
     * @param _claimPeriodEnd Unix timestamp when claiming ends
     */
    constructor(address _token, bytes32 _merkleRoot, uint256 _claimPeriodEnd) {
        owner = msg.sender;
        token = _token;
        merkleRoot = _merkleRoot;
        claimPeriodEnd = _claimPeriodEnd;
    }

    /**
     * @notice Claim airdrop tokens
     * @param _amount Amount of tokens to claim
     * @param _proof Merkle proof verifying the claim
     */
    function claim(uint256 _amount, bytes32[] calldata _proof) external {
        require(block.timestamp <= claimPeriodEnd, "BaseAirdrop: claim period ended");
        require(!claimed[msg.sender], "BaseAirdrop: already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(
            MerkleProof.verify(_proof, merkleRoot, leaf),
            "BaseAirdrop: invalid proof"
        );

        claimed[msg.sender] = true;

        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount)
        );
        require(success, "BaseAirdrop: transfer failed");

        emit Claimed(msg.sender, _amount);
    }

    /**
     * @notice Check if an address has claimed
     * @param user Address to check
     * @return bool True if already claimed
     */
    function hasClaimed(address user) external view returns (bool) {
        return claimed[user];
    }

    /**
     * @notice Check if claim period is still active
     * @return bool True if claiming is still open
     */
    function isClaimActive() external view returns (bool) {
        return block.timestamp <= claimPeriodEnd;
    }
}
