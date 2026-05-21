// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BaseGovernor
 * @notice Minimal on-chain DAO governance with token-weighted voting and timelock execution
 * @dev Uses an ERC20 token for voting power; proposals need quorum to pass
 */
contract BaseGovernor is Ownable, ReentrancyGuard {
    IERC20 public votingToken;

    /// @notice Duration of voting period in blocks
    uint256 public votingPeriod;
    /// @notice Minimum votes (in token units) required for quorum
    uint256 public quorum;
    /// @notice Timelock delay in blocks before execution
    uint256 public timelockDelay;
    /// @notice Counter for proposal IDs
    uint256 public proposalCount;

    /// @notice State machine for proposals
    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Timelocked,
        Executed,
        Cancelled
    }

    /// @notice A single vote
    struct Vote {
        uint256 weight;
        bool support;
        address voter;
    }

    /// @notice A governance proposal
    struct Proposal {
        address proposer;
        string title;
        string description;
        address[] targets;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool cancelled;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 startBlock,
        uint256 endBlock
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event TimelockDelayUpdated(uint256 newDelay);
    event QuorumUpdated(uint256 newQuorum);
    event VotingPeriodUpdated(uint256 newPeriod);

    /**
     * @param _votingToken Address of the ERC20 token used for voting
     * @param _votingPeriod Duration in blocks
     * @param _quorum Minimum votes required
     * @param _timelockDelay Delay in blocks before execution
     */
    constructor(
        address _votingToken,
        uint256 _votingPeriod,
        uint256 _quorum,
        uint256 _timelockDelay
    ) Ownable(msg.sender) {
        require(_votingToken != address(0), "BaseGovernor: invalid token address");
        require(_votingPeriod > 0, "BaseGovernor: voting period must be > 0");
        votingToken = IERC20(_votingToken);
        votingPeriod = _votingPeriod;
        quorum = _quorum;
        timelockDelay = _timelockDelay;
    }

    /**
     * @notice Create a new proposal
     * @param title Short title
     * @param description Full description
     * @param targets Array of target addresses
     * @param calldatas Array of calldata for each target
     */
    function propose(
        string calldata title,
        string calldata description,
        address[] calldata targets,
        bytes[] calldata calldatas
    ) external returns (uint256) {
        require(targets.length == calldatas.length, "BaseGovernor: array length mismatch");
        require(bytes(title).length > 0, "BaseGovernor: title required");
        require(targets.length > 0, "BaseGovernor: at least one action required");

        // Check proposer has voting power
        uint256 proposerPower = votingToken.balanceOf(msg.sender);
        require(proposerPower > 0, "BaseGovernor: must hold tokens to propose");

        uint256 proposalId = ++proposalCount;
        Proposal storage p = proposals[proposalId];
        p.proposer = msg.sender;
        p.title = title;
        p.description = description;
        p.targets = targets;
        p.calldatas = calldatas;
        p.startBlock = block.number;
        p.endBlock = block.number + votingPeriod;

        emit ProposalCreated(proposalId, msg.sender, title, block.number, block.number + votingPeriod);
        return proposalId;
    }

    /**
     * @notice Cast a vote on an active proposal
     * @param proposalId The proposal ID
     * @param support True = for, False = against
     */
    function castVote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(proposalId <= proposalCount && proposalId > 0, "BaseGovernor: invalid proposal");
        require(block.number >= p.startBlock, "BaseGovernor: voting not started");
        require(block.number <= p.endBlock, "BaseGovernor: voting ended");
        require(!p.hasVoted[msg.sender], "BaseGovernor: already voted");
        require(!p.cancelled, "BaseGovernor: proposal cancelled");

        uint256 weight = votingToken.balanceOf(msg.sender);
        require(weight > 0, "BaseGovernor: no voting power");

        p.hasVoted[msg.sender] = true;
        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }
        emit VoteCast(proposalId, msg.sender, support, weight);
    }

    /**
     * @notice Get the state of a proposal
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[proposalId];
        require(proposalId <= proposalCount && proposalId > 0, "BaseGovernor: invalid proposal");

        if (p.cancelled) return ProposalState.Cancelled;
        if (p.executed) return ProposalState.Executed;

        if (block.number <= p.endBlock) {
            if (block.number >= p.startBlock) return ProposalState.Active;
            return ProposalState.Pending;
        }

        // Voting ended
        if (p.forVotes <= p.againstVotes || p.forVotes < quorum) {
            return ProposalState.Defeated;
        }

        if (block.number < p.endBlock + timelockDelay) {
            return ProposalState.Timelocked;
        }

        return ProposalState.Succeeded;
    }

    /**
     * @notice Execute a succeeded proposal after timelock delay
     */
    function execute(uint256 proposalId) external nonReentrant {
        Proposal storage p = proposals[proposalId];
        require(getProposalState(proposalId) == ProposalState.Succeeded, "BaseGovernor: proposal not ready");

        p.executed = true;
        for (uint256 i = 0; i < p.targets.length; i++) {
            (bool success, ) = p.targets[i].call(p.calldatas[i]);
            require(success, "BaseGovernor: action failed");
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancel a proposal (only proposer or owner)
     */
    function cancel(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(msg.sender == p.proposer || msg.sender == owner(), "BaseGovernor: not authorised");
        require(!p.executed, "BaseGovernor: already executed");
        p.cancelled = true;
        emit ProposalCancelled(proposalId);
    }

    /**
     * @notice Get vote details for a voter
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }

    // --- Admin setters ---

    function setVotingPeriod(uint256 _votingPeriod) external onlyOwner {
        require(_votingPeriod > 0, "BaseGovernor: must be > 0");
        votingPeriod = _votingPeriod;
        emit VotingPeriodUpdated(_votingPeriod);
    }

    function setQuorum(uint256 _quorum) external onlyOwner {
        quorum = _quorum;
        emit QuorumUpdated(_quorum);
    }

    function setTimelockDelay(uint256 _timelockDelay) external onlyOwner {
        timelockDelay = _timelockDelay;
        emit TimelockDelayUpdated(_timelockDelay);
    }
}
