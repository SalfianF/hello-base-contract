// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseDutchAuction
 * @notice A Dutch auction for an NFT on Base. The price starts high and decreases linearly over time.
 * @dev The owner lists an ERC-721 NFT with a start price, reserve price, and duration. The first
 *      caller to buy at the current price wins the auction. The NFT is transferred upon purchase.
 *      Supports ERC-721 via the IERC721 interface.
 */

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
}

contract BaseDutchAuction {
    /* ──────────────── State Variables ──────────────── */

    /// @notice The contract owner (administrator / seller).
    address public owner;

    /// @notice The address of the ERC-721 NFT contract.
    IERC721 public nft;

    /// @notice The token ID being auctioned.
    uint256 public tokenId;

    /// @notice The starting price of the auction (in wei).
    uint256 public startPrice;

    /// @notice The reserve / floor price (in wei). Auction never drops below this.
    uint256 public reservePrice;

    /// @notice The auction start timestamp.
    uint256 public startTime;

    /// @notice The auction duration in seconds.
    uint256 public duration;

    /// @notice Whether the auction has concluded (NFT sold or cancelled).
    bool public ended;

    /// @notice The address of the winning bidder, if sold.
    address public winner;

    /// @notice The final sale price, if sold.
    uint256 public finalPrice;

    /* ──────────────── Events ──────────────── */

    /**
     * @notice Emitted when the owner lists a new NFT for auction.
     * @param nft          The ERC-721 contract address.
     * @param tokenId      The token ID being auctioned.
     * @param startPrice   The starting price (in wei).
     * @param reservePrice The minimum price (in wei).
     * @param duration     The auction duration (in seconds).
     */
    event AuctionListed(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 duration
    );

    /**
     * @notice Emitted when a buyer purchases the NFT at the current price.
     * @param buyer      The address of the buyer.
     * @param pricePaid  The final price paid (in wei).
     * @param tokenId    The token ID purchased.
     */
    event Purchased(address indexed buyer, uint256 pricePaid, uint256 indexed tokenId);

    /**
     * @notice Emitted when the auction is cancelled by the owner before a purchase.
     */
    event AuctionCancelled();

    /* ──────────────── Modifiers ──────────────── */

    /// @notice Restricts a function to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseDutchAuction: caller is not the owner");
        _;
    }

    /* ──────────────── Constructor ──────────────── */

    /**
     * @notice Initializes the Dutch auction contract. Does not start an auction by default.
     * @dev Owner is set to the deployer. Use `listAuction` to begin an auction.
     */
    constructor() {
        owner = msg.sender;
    }

    /* ──────────────── Owner Functions ──────────────── */

    /**
     * @notice Lists an NFT for auction. The owner must have approved this contract to transfer the NFT.
     * @param _nft          The ERC-721 contract address.
     * @param _tokenId      The token ID to auction.
     * @param _startPrice   The starting price (in wei). Must be > reservePrice.
     * @param _reservePrice The floor price (in wei). Must be > 0.
     * @param _duration     The auction duration in seconds. Must be > 0.
     * @dev Reverts if an auction is already active or if the contract is not approved to transfer.
     */
    function listAuction(
        address _nft,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _reservePrice,
        uint256 _duration
    ) external onlyOwner {
        require(!_isActive(), "BaseDutchAuction: auction already active");
        require(!ended, "BaseDutchAuction: ended auction not cleared");
        require(_nft != address(0), "BaseDutchAuction: invalid NFT address");
        require(_startPrice > _reservePrice, "BaseDutchAuction: start price must exceed reserve");
        require(_reservePrice > 0, "BaseDutchAuction: reserve price must be > 0");
        require(_duration > 0, "BaseDutchAuction: duration must be > 0");

        nft = IERC721(_nft);
        tokenId = _tokenId;
        startPrice = _startPrice;
        reservePrice = _reservePrice;
        duration = _duration;
        startTime = block.timestamp;
        ended = false;
        winner = address(0);
        finalPrice = 0;

        // Verify the owner actually owns the NFT
        require(
            nft.ownerOf(_tokenId) == owner,
            "BaseDutchAuction: owner does not own the NFT"
        );

        emit AuctionListed(address(nft), _tokenId, _startPrice, _reservePrice, _duration);
    }

    /**
     * @notice Cancels an active auction before anyone buys. The NFT stays with the owner.
     * @dev Reverts if the auction has already ended (sold or cancelled).
     */
    function cancelAuction() external onlyOwner {
        require(_isActive(), "BaseDutchAuction: no active auction");
        require(!ended, "BaseDutchAuction: already ended");

        ended = true;

        emit AuctionCancelled();
    }

    /* ──────────────── Public Functions ──────────────── */

    /**
     * @notice Buy the NFT at the current Dutch auction price.
     * @dev The caller must send enough ETH to cover the current price. Excess is refunded.
     *      The contract must have been approved by the NFT owner to transfer the token.
     */
    function buy() external payable {
        require(_isActive(), "BaseDutchAuction: no active auction");
        require(!ended, "BaseDutchAuction: auction already ended");

        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= currentPrice, "BaseDutchAuction: insufficient ETH");

        // Refund excess
        uint256 excess = msg.value - currentPrice;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "BaseDutchAuction: refund failed");
        }

        ended = true;
        winner = msg.sender;
        finalPrice = currentPrice;

        // Transfer the NFT from the owner to the buyer
        nft.transferFrom(owner, msg.sender, tokenId);

        // Send proceeds to the owner
        (bool sent, ) = payable(owner).call{value: currentPrice}("");
        require(sent, "BaseDutchAuction: payment to owner failed");

        emit Purchased(msg.sender, currentPrice, tokenId);
    }

    /* ──────────────── View Functions ──────────────── */

    /**
     * @notice Returns the current price of the Dutch auction at this moment.
     * @return price The current price in wei. Returns the reserve price if the auction has expired.
     * @dev Price decreases linearly from `startPrice` to `reservePrice` over `duration` seconds.
     */
    function getCurrentPrice() public view returns (uint256 price) {
        if (!_isActive() || ended) {
            return ended ? finalPrice : reservePrice;
        }

        uint256 elapsed = block.timestamp - startTime;

        if (elapsed >= duration) {
            return reservePrice;
        }

        // Linear price decrease
        uint256 priceRange = startPrice - reservePrice;
        uint256 discount = (priceRange * elapsed) / duration;

        return startPrice - discount;
    }

    /**
     * @notice Returns whether an auction is currently active.
     * @return active True if an auction is listed and not yet ended.
     */
    function isAuctionActive() external view returns (bool active) {
        return _isActive();
    }

    /**
     * @notice Returns the full auction info as a struct-like set of values.
     * @return nftContract   The NFT contract address.
     * @return nftTokenId    The auctioned token ID.
     * @return auctionStart  The start timestamp.
     * @return auctionEnd    The end timestamp (start + duration).
     * @return currentPrice  The current price.
     * @return hasEnded      Whether the auction has ended.
     * @return auctionWinner The winning address (zero if not sold).
     * @return salePrice     The final sale price (zero if not sold).
     */
    function getAuctionInfo()
        external
        view
        returns (
            address nftContract,
            uint256 nftTokenId,
            uint256 auctionStart,
            uint256 auctionEnd,
            uint256 currentPrice,
            bool hasEnded,
            address auctionWinner,
            uint256 salePrice
        )
    {
        return (
            address(nft),
            tokenId,
            startTime,
            startTime + duration,
            getCurrentPrice(),
            ended,
            winner,
            finalPrice
        );
    }

    /// @dev Returns true if there is an auction listed and not ended, and startTime > 0.
    function _isActive() private view returns (bool) {
        return startTime > 0 && !ended && address(nft) != address(0);
    }
}
