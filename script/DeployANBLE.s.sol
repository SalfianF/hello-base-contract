// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ANBLE} from "../src/ANBLE.sol";

/// @title  ANBLE Token Deployment Script
/// @notice Foundry broadcast script for deploying ANBLE to any EVM chain.
///         Usage: forge script script/DeployANBLE.s.sol --rpc-url <chain> --broadcast
/// @dev    Reads OWNER_ADDRESS and INITIAL_SUPPLY from environment (with defaults).
contract DeployANBLE is Script {
    function run() external {
        // --- Configuration ---
        address deployer = vm.envOr("DEPLOYER", msg.sender);
        address owner     = vm.envOr("OWNER_ADDRESS", deployer);
        uint256 supply    = vm.envOr("INITIAL_SUPPLY", 500_000_000 * 10**18); // default 500M

        console2.log("=== ANBLE Token Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Owner:   ", owner);
        console2.log("Supply:  ", supply);

        // --- Deploy ---
        vm.startBroadcast(deployer);
        ANBLE token = new ANBLE(owner, supply);
        vm.stopBroadcast();

        console2.log("ANBLE deployed at:", address(token));
        console2.log("===============================");
    }
}
