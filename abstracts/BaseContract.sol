// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title BaseContract
 * @notice Abstract base contract combining Ownable and ERC165 for all Base contracts
 * @dev Provides ERC-165 interface detection for all child contracts
 *
 * Interface IDs registrations:
 * - IBaseERC165: 0x01ffc9a7
 */
abstract contract BaseContract is Ownable, ERC165 {
    /// @dev ERC165 interface ID kept as a constant
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    constructor() Ownable(msg.sender) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     * Each child contract should override and register its own interface IDs.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == _INTERFACE_ID_ERC165 || super.supportsInterface(interfaceId);
    }
}
