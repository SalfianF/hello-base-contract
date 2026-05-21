// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseDonation
 * @notice Interface for the BaseDonation ETH donation contract
 */
interface IBaseDonation {
    /// @notice Emitted when a donation is made
    event Donated(address indexed donor, uint256 amount);
    /// @notice Emitted when the owner withdraws funds
    event Withdrawn(address indexed owner, uint256 amount);
    /// @notice Emitted when the minimum donation amount changes
    event MinimumDonationChanged(uint256 oldMin, uint256 newMin);

    /// @notice The contract owner
    function owner() external view returns (address);
    /// @notice The minimum donation amount in wei
    function minimumDonation() external view returns (uint256);
    /// @notice Total ETH raised
    function totalRaised() external view returns (uint256);
    /// @notice Donation amount by donor address
    function donations(address donor) external view returns (uint256);
    /// @notice Donor address by index
    function donorList(uint256 index) external view returns (address);

    /**
     * @notice Donate ETH to the contract
     * @dev Reverts if donation is below minimum
     */
    function donate() external payable;

    /**
     * @notice Withdraw all collected funds to owner
     * @dev Only callable by owner
     */
    function withdraw() external;

    /**
     * @notice Update the minimum donation amount
     * @param _newMinimum New minimum donation in wei
     */
    function setMinimumDonation(uint256 _newMinimum) external;

    /**
     * @notice Get total number of unique donors
     * @return uint256 Donor count
     */
    function donorCount() external view returns (uint256);
}
