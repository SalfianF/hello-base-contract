// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseRaffle
 * @notice Interface for the BaseRaffle raffle (lottery) contract
 */
interface IBaseRaffle {
    /// @notice Emitted when a user buys tickets
    event Entered(address indexed buyer, uint256 quantity, uint256 cost);
    /// @notice Emitted when a winner is selected
    event WinnerPicked(address indexed winner, uint256 winningTicket, uint256 randomValue);
    /// @notice Emitted when the winner claims their prize
    event PrizeClaimed(address indexed winner, uint256 amount);

    /// @notice The raffle owner
    function owner() external view returns (address);
    /// @notice Price per ticket in wei
    function ticketPrice() external view returns (uint256);
    /// @notice Maximum number of tickets
    function maxTickets() external view returns (uint256);
    /// @notice The deadline timestamp
    function deadline() external view returns (uint256);
    /// @notice Total tickets sold
    function totalTickets() external view returns (uint256);
    /// @notice The winning ticket index
    function winningTicketIndex() external view returns (uint256);
    /// @notice Whether the raffle has ended
    function raffleEnded() external view returns (bool);
    /// @notice Whether the prize has been claimed
    function prizeClaimed() external view returns (bool);
    /// @notice The total prize pool
    function prizePool() external view returns (uint256);
    /// @notice The winner address
    function winner() external view returns (address);
    /// @notice Number of tickets held by a user
    function tickets(address user) external view returns (uint256);

    /**
     * @notice Buys one or more raffle tickets by sending ETH
     */
    function enter() external payable;

    /**
     * @notice Manually triggers winner selection (owner only)
     */
    function pickWinner() external;

    /**
     * @notice Allows the winner to withdraw their prize
     */
    function getPrize() external;

    /**
     * @notice Returns the number of unique participants
     * @return count The number of distinct addresses that bought tickets
     */
    function participantCount() external view returns (uint256 count);

    /**
     * @notice Returns the current raffle state
     * @return active       Whether the raffle is still accepting entries
     * @return ticketsSold  Total tickets sold
     * @return currentPrize Current prize pool in wei
     */
    function getRaffleInfo()
        external
        view
        returns (bool active, uint256 ticketsSold, uint256 currentPrize);
}
