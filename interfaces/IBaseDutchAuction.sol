// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseDutchAuction
 * @notice Interface for the BaseDutchAuction NFT Dutch auction contract
 */
interface IBaseDutchAuction {
    /// @notice Emitted when the owner lists a new NFT for auction
    event AuctionListed(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 duration
    );
    /// @notice Emitted when a buyer purchases the NFT
    event Purchased(address indexed buyer, uint256 pricePaid, uint256 indexed tokenId);
    /// @notice Emitted when the auction is cancelled
    event AuctionCancelled();

    /// @notice The contract owner (seller)
    function owner() external view returns (address);
    /// @notice The ERC-721 NFT contract address
    function nft() external view returns (address);
    /// @notice The token ID being auctioned
    function tokenId() external view returns (uint256);
    /// @notice The starting price in wei
    function startPrice() external view returns (uint256);
    /// @notice The reserve/floor price in wei
    function reservePrice() external view returns (uint256);
    /// @notice The auction start timestamp
    function startTime() external view returns (uint256);
    /// @notice The auction duration in seconds
    function duration() external view returns (uint256);
    /// @notice Whether the auction has ended
    function ended() external view returns (bool);
    /// @notice The winning bidder address
    function winner() external view returns (address);
    /// @notice The final sale price
    function finalPrice() external view returns (uint256);

    /**
     * @notice Lists an NFT for auction (owner only)
     * @param _nft          The ERC-721 contract address
     * @param _tokenId      The token ID to auction
     * @param _startPrice   The starting price in wei
     * @param _reservePrice The floor price in wei
     * @param _duration     The auction duration in seconds
     */
    function listAuction(
        address _nft,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _reservePrice,
        uint256 _duration
    ) external;

    /**
     * @notice Cancels an active auction before anyone buys (owner only)
     */
    function cancelAuction() external;

    /**
     * @notice Buy the NFT at the current Dutch auction price
     */
    function buy() external payable;

    /**
     * @notice Returns the current price of the Dutch auction
     * @return price The current price in wei
     */
    function getCurrentPrice() external view returns (uint256 price);

    /**
     * @notice Returns whether an auction is currently active
     * @return active True if an auction is listed and not yet ended
     */
    function isAuctionActive() external view returns (bool active);

    /**
     * @notice Returns the full auction info
     * @return nftContract   The NFT contract address
     * @return nftTokenId    The auctioned token ID
     * @return auctionStart  The start timestamp
     * @return auctionEnd    The end timestamp (start + duration)
     * @return currentPrice  The current price
     * @return hasEnded      Whether the auction has ended
     * @return auctionWinner The winning address
     * @return salePrice     The final sale price
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
        );
}
