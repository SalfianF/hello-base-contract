// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBaseFlashLoan
 * @notice Interface for the BaseFlashLoan contract
 */
interface IBaseFlashLoan {
    function flashLoanFee() external view returns (uint256);
    function totalFeesCollected() external view returns (uint256);
    function flashLoan(address receiver, uint256 amount, bytes calldata data) external;
    function withdrawFees(address payable to) external;
    function setFlashLoanFee(uint256 _newFee) external;
}

/**
 * @title IBaseFlashLoanReceiver
 * @notice Interface for contracts receiving flash loans
 */
interface IBaseFlashLoanReceiver {
    function executeOperation(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool);
}
