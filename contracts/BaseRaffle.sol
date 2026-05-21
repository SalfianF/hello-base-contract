// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseRaffle
 * @notice A raffle (lottery) contract on Base where users buy tickets with ETH.
 * @dev The owner picks a winner using block hash as randomness once the ticket cap is reached or
 *      the deadline expires. Winners call getPrize() to withdraw their ETH prize.
 */
contract BaseRaffle {
    /* ──────────────── State Variables ──────────────── */

    /// @notice Address of the raffle owner/administrator.
    address public owner;

    /// @notice Price per ticket (in wei).
    uint256 public ticketPrice;

    /// @notice Maximum number of tickets that can be sold.
    uint256 public maxTickets;

    /// @notice The UNIX timestamp after which no more tickets can be bought.
    uint256 public deadline;

    /// @notice Total number of tickets sold so far.
    uint256 public totalTickets;

    /// @notice The index of the winning ticket (0-indexed). Set when pickWinner() is called.
    uint256 public winningTicketIndex;

    /// @notice Whether the raffle has concluded (winner has been picked).
    bool public raffleEnded;

    /// @notice Whether the winner has claimed their prize.
    bool public prizeClaimed;

    /// @notice The total prize pool (accumulated ETH).
    uint256 public prizePool;

    /// @notice The address of the winner.
    address public winner;

    /// @notice Mapping from user address to the number of tickets they hold.
    mapping(address => uint256) public tickets;

    /// @notice Array of all ticket holder addresses (for winner lookup).
    address[] private _participants;

    /// @notice Whether a participant address has already been recorded in `_participants`.
    mapping(address => bool) private _isParticipant;

    /* ──────────────── Events ──────────────── */

    /**
     * @notice Emitted when a user buys one or more tickets.
     * @param buyer    The address that purchased the tickets.
     * @param quantity The number of tickets bought.
     * @param cost     The total ETH paid (in wei).
     */
    event Entered(address indexed buyer, uint256 quantity, uint256 cost);

    /**
     * @notice Emitted when the raffle ends and a winner is selected.
     * @param winner          The address of the winning participant.
     * @param winningTicket   The index of the winning ticket.
     * @param randomValue     The pseudo-random value used for selection.
     */
    event WinnerPicked(address indexed winner, uint256 winningTicket, uint256 randomValue);

    /**
     * @notice Emitted when the winner claims their prize.
     * @param winner The address that claimed the prize.
     * @param amount The amount of ETH withdrawn.
     */
    event PrizeClaimed(address indexed winner, uint256 amount);

    /* ──────────────── Modifiers ──────────────── */

    /// @notice Restricts a function to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseRaffle: caller is not the owner");
        _;
    }

    /* ──────────────── Constructor ──────────────── */

    /**
     * @notice Initializes a new raffle.
     * @param _ticketPrice  Price per ticket in wei.
     * @param _maxTickets   Maximum number of tickets that can be sold.
     * @param _duration     Duration in seconds from now until the raffle deadline.
     * @dev Owner is set to the deployer.
     */
    constructor(uint256 _ticketPrice, uint256 _maxTickets, uint256 _duration) {
        require(_ticketPrice > 0, "BaseRaffle: ticket price must be > 0");
        require(_maxTickets > 0, "BaseRaffle: max tickets must be > 0");
        require(_duration > 0, "BaseRaffle: duration must be > 0");

        owner = msg.sender;
        ticketPrice = _ticketPrice;
        maxTickets = _maxTickets;
        deadline = block.timestamp + _duration;
    }

    /* ──────────────── Public Functions ──────────────── */

    /**
     * @notice Buys one or more raffle tickets by sending ETH.
     * @dev Reverts if the raffle has ended, deadline passed, or max tickets would be exceeded.
     *      The sent ETH must equal `ticketPrice * quantity`.
     */
    function enter() external payable {
        require(!raffleEnded, "BaseRaffle: raffle already ended");
        require(block.timestamp < deadline, "BaseRaffle: deadline passed");
        require(totalTickets < maxTickets, "BaseRaffle: max tickets reached");

        uint256 quantity = msg.value / ticketPrice;
        require(quantity > 0, "BaseRaffle: insufficient ETH for any ticket");

        // Cap quantity to remaining tickets
        uint256 remaining = maxTickets - totalTickets;
        if (quantity > remaining) {
            quantity = remaining;
        }

        uint256 cost = quantity * ticketPrice;
        require(msg.value >= cost, "BaseRaffle: insufficient ETH");

        // Refund excess ETH
        uint256 excess = msg.value - cost;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "BaseRaffle: refund failed");
        }

        tickets[msg.sender] += quantity;
        prizePool += cost;

        // Track participant if not already tracked
        if (!_isParticipant[msg.sender]) {
            _isParticipant[msg.sender] = true;
            _participants.push(msg.sender);
        }

        totalTickets += quantity;

        emit Entered(msg.sender, quantity, cost);

        // Auto-end if max tickets reached
        if (totalTickets >= maxTickets) {
            _pickWinner();
        }
    }

    /**
     * @notice Manually triggers winner selection (owner only). Uses block hash as randomness.
     * @dev Can be called after the deadline even if max tickets were not sold.
     *      Also called automatically when maxTickets is reached via enter().
     */
    function pickWinner() external onlyOwner {
        require(!raffleEnded, "BaseRaffle: raffle already ended");
        require(block.timestamp >= deadline || totalTickets >= maxTickets, "BaseRaffle: raffle still active");
        _pickWinner();
    }

    /**
     * @notice Allows the winner to withdraw their prize.
     * @dev Reverts if called before raffle ends, or if the caller is not the winner,
     *      or if the prize has already been claimed.
     */
    function getPrize() external {
        require(raffleEnded, "BaseRaffle: raffle not yet ended");
        require(msg.sender == winner, "BaseRaffle: caller is not the winner");
        require(!prizeClaimed, "BaseRaffle: prize already claimed");

        prizeClaimed = true;
        uint256 amount = prizePool;

        (bool sent, ) = payable(winner).call{value: amount}("");
        require(sent, "BaseRaffle: prize transfer failed");

        emit PrizeClaimed(winner, amount);
    }

    /* ──────────────── Internal Functions ──────────────── */

    /**
     * @notice Internal function to select a winner using block hash as pseudo-randomness.
     * @dev Sets `winner`, `winningTicketIndex`, `raffleEnded`, and emits WinnerPicked.
     *      Uses `keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, totalTickets))`
     *      as a pseudo-random source. Not fully tamper-proof but sufficient for a standard raffle.
     */
    function _pickWinner() internal {
        raffleEnded = true;

        // Pseudo-random number using previous block hash
        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp, totalTickets)
            )
        );

        winningTicketIndex = randomValue % totalTickets;

        // Find which participant owns the winning ticket
        uint256 cumulative;
        for (uint256 i = 0; i < _participants.length; i++) {
            address participant = _participants[i];
            cumulative += tickets[participant];
            if (winningTicketIndex < cumulative) {
                winner = participant;
                break;
            }
        }

        emit WinnerPicked(winner, winningTicketIndex, randomValue);
    }

    /* ──────────────── View Functions ──────────────── */

    /**
     * @notice Returns the number of unique participants in the raffle.
     * @return count The number of distinct addresses that bought tickets.
     */
    function participantCount() external view returns (uint256 count) {
        return _participants.length;
    }

    /**
     * @notice Returns the current raffle state as a single struct.
     * @return active          Whether the raffle is still accepting entries.
     * @return ticketsSold     Total tickets sold.
     * @return currentPrize    Current prize pool in wei.
     */
    function getRaffleInfo()
        external
        view
        returns (bool active, uint256 ticketsSold, uint256 currentPrize)
    {
        return (!raffleEnded && block.timestamp < deadline && totalTickets < maxTickets, totalTickets, prizePool);
    }
}
