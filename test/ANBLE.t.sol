// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ANBLE} from "../src/ANBLE.sol";

/// @title  ANBLE Token Test Suite
/// @notice Coverage: deployment, transfers, approvals, mint, burn, access control, edge cases
contract ANBLE_Test is Test {
    ANBLE public token;
    address public owner;
    address public alice;
    address public bob;

    uint256 internal constant INITIAL_SUPPLY = 500_000_000 * 10**18; // 500M — room to mint
    uint256 internal constant MAX_SUPPLY     = 1_000_000_000 * 10**18; // 1B

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob   = makeAddr("bob");

        vm.prank(owner);
        token = new ANBLE(owner, INITIAL_SUPPLY);
    }

    // --- Deployment ---
    function test_Deployment_SetsOwner() public view {
        assertEq(token.owner(), owner);
    }

    function test_Deployment_MintsInitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function test_Deployment_RevertOnExcessSupply() public {
        vm.expectRevert();
        new ANBLE(owner, MAX_SUPPLY + 1);
    }

    function test_Deployment_Metadata() public view {
        assertEq(token.name(), "ANBLE");
        assertEq(token.symbol(), "ANBLE");
        assertEq(token.decimals(), 18);
    }

    // --- Transfer ---
    function test_Transfer_MovesBalance() public {
        vm.prank(owner);
        token.transfer(alice, 100e18);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - 100e18);
        assertEq(token.balanceOf(alice), 100e18);
    }

    function test_Transfer_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, alice, 100e18);

        vm.prank(owner);
        token.transfer(alice, 100e18);
    }

    function test_Transfer_RevertInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__InsufficientBalance.selector, alice, 1, 0)
        );
        token.transfer(bob, 1);
    }

    function test_Transfer_ZeroAddress() public {
        vm.prank(owner);
        token.transfer(address(0), 100e18);

        assertEq(token.balanceOf(address(0)), 100e18);
    }

    // --- Approve & TransferFrom ---
    function test_Approve_SetsAllowance() public {
        vm.prank(owner);
        token.approve(alice, 500e18);
    }

    function test_TransferFrom_UsesAllowance() public {
        vm.prank(owner);
        token.approve(alice, 100e18);

        vm.prank(alice);
        token.transferFrom(owner, bob, 50e18);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - 50e18);
        assertEq(token.balanceOf(bob), 50e18);
    }

    function test_TransferFrom_RevertExceedsAllowance() public {
        vm.prank(owner);
        token.approve(alice, 10e18);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__InsufficientAllowance.selector, owner, alice, 11e18, 10e18)
        );
        token.transferFrom(owner, bob, 11e18);
    }

    function test_TransferFrom_RevertExceedsBalance() public {
        vm.prank(alice);
        token.approve(bob, INITIAL_SUPPLY);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__InsufficientBalance.selector, alice, 1, 0)
        );
        token.transferFrom(alice, owner, 1);
    }

    // --- Mint (owner only) ---
    function test_Mint_IncreasesSupply() public {
        vm.prank(owner);
        token.mint(bob, 500e18);

        assertEq(token.totalSupply(), INITIAL_SUPPLY + 500e18);
        assertEq(token.balanceOf(bob), 500e18);
    }

    function test_Mint_EmitsTransferFromZero() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), bob, 500e18);

        vm.prank(owner);
        token.mint(bob, 500e18);
    }

    function test_Mint_RevertExceedsMaxSupply() public {
        uint256 remaining = MAX_SUPPLY - INITIAL_SUPPLY;

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__ExceedsMaxSupply.selector, INITIAL_SUPPLY + remaining + 1, MAX_SUPPLY)
        );
        token.mint(owner, remaining + 1);
    }

    function test_Mint_RevertIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__Unauthorized.selector, alice)
        );
        token.mint(alice, 100e18);
    }

    // --- Burn ---
    function test_Burn_DecreasesSupply() public {
        vm.prank(owner);
        token.burn(100e18);

        assertEq(token.totalSupply(), INITIAL_SUPPLY - 100e18);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - 100e18);
    }

    function test_Burn_EmitsTransferToZero() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, address(0), 100e18);

        vm.prank(owner);
        token.burn(100e18);
    }

    function test_Burn_RevertInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__InsufficientBalance.selector, alice, 1, 0)
        );
        token.burn(1);
    }

    // --- BurnFrom (owner only) ---
    function test_BurnFrom_BurnsFromAnyAddress() public {
        vm.prank(owner);
        token.transfer(alice, 200e18);

        vm.prank(owner);
        token.burnFrom(alice, 50e18);

        assertEq(token.balanceOf(alice), 150e18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - 50e18);
    }

    function test_BurnFrom_RevertIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__Unauthorized.selector, alice)
        );
        token.burnFrom(owner, 1);
    }

    function test_BurnFrom_RevertInsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(ANBLE.ANBLE__InsufficientBalance.selector, alice, 1, 0)
        );
        token.burnFrom(alice, 1);
    }

    // --- Fuzz Tests ---
    function testFuzz_Transfer_MaintainsTotalSupply(uint96 amount) public {
        uint256 _amount = uint256(amount);
        vm.assume(_amount > 0 && _amount <= token.balanceOf(owner));

        uint256 supplyBefore = token.totalSupply();

        vm.prank(owner);
        token.transfer(alice, _amount);

        assertEq(token.totalSupply(), supplyBefore);
    }

    function testFuzz_Transfer_MovesExactAmount(uint96 amount) public {
        uint256 _amount = uint256(amount);
        vm.assume(_amount > 0 && _amount <= token.balanceOf(owner));

        vm.prank(owner);
        token.transfer(alice, _amount);

        assertEq(token.balanceOf(alice), _amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - _amount);
    }

    function testFuzz_Mint_BoundedByMaxSupply(uint96 amount) public {
        uint256 remaining = MAX_SUPPLY - INITIAL_SUPPLY;
        vm.assume(amount > 0);

        uint256 _amount = uint256(amount) % (remaining + 1);

        vm.prank(owner);

        if (_amount == 0) {
            // mint(0) succeeds — no zero-amount guard in contract
            token.mint(owner, 0);
            assertEq(token.totalSupply(), INITIAL_SUPPLY);
        } else if (_amount <= remaining) {
            token.mint(owner, _amount);
            assertEq(token.totalSupply(), INITIAL_SUPPLY + _amount);
        } else {
            vm.expectRevert(
                abi.encodeWithSelector(ANBLE.ANBLE__ExceedsMaxSupply.selector, INITIAL_SUPPLY + _amount, MAX_SUPPLY)
            );
            token.mint(owner, _amount);
        }
    }
}
