// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SafeVault} from "./SafeVault.sol";
import {SafeShareVault} from "./SafeShareVault.sol";
import {MockERC20} from "../../src/ch04/MockERC20.sol";

/// @notice The same attacks from `test/ch04`, now defused. Run with:
///           forge test --profile solutions --match-path solutions/ch04
contract SafeVaultReentrancyAttacker {
    SafeVault public immutable vault;

    constructor(SafeVault _vault) {
        vault = _vault;
    }

    function attack() external {
        vault.deposit{value: 1 ether}();
        vault.withdrawAll();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdrawAll(); // reverts: nonReentrant guard
        }
    }
}

contract Ch04FixesTest is Test {
    address internal ownerEOA = address(0x0FFFF);
    address internal alice = address(0xA11CE);
    address internal attacker = address(0xBAD);
    address internal victim = address(0x1C71);

    // ---- Reentrancy is blocked ----
    function test_reentrancyReverts() public {
        vm.prank(ownerEOA);
        SafeVault vault = new SafeVault();
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        vault.deposit{value: 5 ether}();

        SafeVaultReentrancyAttacker atk = new SafeVaultReentrancyAttacker(vault);
        vm.deal(address(atk), 1 ether);

        // The reentrant call reverts, unwinding the whole attack.
        vm.expectRevert();
        atk.attack();

        assertEq(address(vault).balance, 5 ether, "honest funds untouched");
    }

    // ---- setOwner is now guarded ----
    function test_setOwnerRequiresOwner() public {
        vm.prank(ownerEOA);
        SafeVault vault = new SafeVault();

        vm.prank(alice);
        vm.expectRevert(bytes("not owner"));
        vault.setOwner(alice);
    }

    // ---- Inflation attack no longer zeroes the victim ----
    function test_inflationDefused() public {
        MockERC20 asset = new MockERC20();
        SafeShareVault vault = new SafeShareVault(asset);

        asset.mint(attacker, 10_000 ether + 1);
        asset.mint(victim, 10_000 ether);

        vm.startPrank(attacker);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(1);
        asset.transfer(address(vault), 10_000 ether); // donation
        vm.stopPrank();

        vm.startPrank(victim);
        asset.approve(address(vault), type(uint256).max);
        uint256 victimShares = vault.deposit(10_000 ether);
        vm.stopPrank();

        // With the virtual offset the victim mints real shares instead of 0.
        assertGt(victimShares, 0, "victim now receives shares");
    }
}
