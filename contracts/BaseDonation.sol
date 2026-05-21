// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseDonation
 * @notice ETH donation contract with donor tracking and minimum contribution
 * @dev Owner can withdraw collected funds; donors can view their contributions
 */
contract BaseDonation {
    address public owner;
    uint256 public minimumDonation;
    uint256 public totalRaised;

    mapping(address => uint256) public donations;
    address[] public donorList;

    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event MinimumDonationChanged(uint256 oldMin, uint256 newMin);

    modifier onlyOwner() {
        require(msg.sender == owner, "BaseDonation: only owner");
        _;
    }

    /**
     * @notice Initialize the donation contract
     * @param _minimumDonation Minimum ETH amount required to donate (in wei)
     */
    constructor(uint256 _minimumDonation) {
        owner = msg.sender;
        minimumDonation = _minimumDonation;
    }

    /**
     * @notice Donate ETH to the contract
     * @dev Reverts if donation is below minimum
     */
    function donate() external payable {
        require(msg.value >= minimumDonation, "BaseDonation: below minimum");
        if (donations[msg.sender] == 0) {
            donorList.push(msg.sender);
        }
        donations[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw all collected funds to owner
     * @dev Only callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "BaseDonation: nothing to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "BaseDonation: withdraw failed");
        emit Withdrawn(owner, balance);
    }

    /**
     * @notice Update the minimum donation amount
     * @param _newMinimum New minimum donation in wei
     */
    function setMinimumDonation(uint256 _newMinimum) external onlyOwner {
        emit MinimumDonationChanged(minimumDonation, _newMinimum);
        minimumDonation = _newMinimum;
    }

    /**
     * @notice Get total number of unique donors
     * @return uint256 Donor count
     */
    function donorCount() external view returns (uint256) {
        return donorList.length;
    }
}
