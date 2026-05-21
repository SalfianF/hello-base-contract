// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseGovernor
 * @notice Interface for the BaseGovernor DAO contract
 */
interface IBaseGovernor {
    enum ProposalState { Pending, Active, Defeated, Succeeded, Timelocked, Executed, Cancelled }

    function votingToken() external view returns (address);
    function votingPeriod() external view returns (uint256);
    function quorum() external view returns (uint256);
    function timelockDelay() external view returns (uint256);
    function proposalCount() external view returns (uint256);
    function getProposalState(uint256 proposalId) external view returns (ProposalState);
    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
    function propose(
        string calldata title,
        string calldata description,
        address[] calldata targets,
        bytes[] calldata calldatas
    ) external returns (uint256);
    function castVote(uint256 proposalId, bool support) external;
    function execute(uint256 proposalId) external;
    function cancel(uint256 proposalId) external;
}
