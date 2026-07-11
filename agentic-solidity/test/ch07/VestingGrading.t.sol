// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IVesting} from "../../src/ch07/IVesting.sol";
import {IToken} from "../../src/ch07/IToken.sol";
import {VestingVault} from "../../src/ch07/VestingVault.sol";
import {MockERC20} from "../../src/ch04/MockERC20.sol";

/// @notice Drives the vault with randomized grants, claims, and time jumps so the
///         invariant runner can hunt for an insolvent state. It uses the vm
///         cheatcode directly to move time — the vesting curve only becomes
///         interesting once the clock advances.
contract VestingHandler {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    IVesting public immutable vault;
    MockERC20 public immutable token;
    address public immutable grantor;

    uint256 internal constant GRANTS = 4;

    constructor(IVesting _vault, MockERC20 _token, address _grantor) {
        vault = _vault;
        token = _token;
        grantor = _grantor;
    }

    function createGrant(uint256 id, uint256 amount, uint64 duration) external {
        id = id % GRANTS;
        if (vault.beneficiaryOf(id) != address(0)) return; // id taken
        amount = (amount % 1_000 ether) + 1;
        duration = uint64((uint256(duration) % 365 days) + 1);
        if (token.balanceOf(grantor) < amount) return;

        vm.prank(grantor);
        token.approve(address(vault), amount);
        vm.prank(grantor);
        vault.createGrant(id, address(this), amount, uint64(block.timestamp), duration);
    }

    function claim(uint256 id) external {
        id = id % GRANTS;
        if (vault.beneficiaryOf(id) != address(this)) return;
        if (vault.claimable(id) == 0) return;
        vault.claim(id);
    }

    function advanceTime(uint256 secs) external {
        vm.warp(block.timestamp + (secs % 120 days) + 1);
    }
}

/// @notice The capstone grading suite. Any implementation of `IVesting` must pass
///         every test here. Swap `VestingVault` in `_deploy()` for an agent's
///         implementation and re-run — this suite is the acceptance gate.
contract VestingGradingTest is Test {
    MockERC20 internal token;
    IVesting internal vault;
    VestingHandler internal handler;

    address internal grantor = address(0x6AA);
    address internal beneficiary = address(0xBEEF);
    address internal stranger = address(0xBAD);

    // The single seam an agent's implementation plugs into.
    function _deploy(MockERC20 _token) internal returns (IVesting) {
        return new VestingVault(IToken(address(_token)));
    }

    function setUp() public {
        vm.warp(1_000_000);
        token = new MockERC20();
        vault = _deploy(token);

        token.mint(grantor, 1_000_000 ether);
        handler = new VestingHandler(vault, token, grantor);
        // fund the grantor path used by the invariant handler
        token.mint(grantor, 1_000_000 ether);

        targetContract(address(handler));
    }

    // ---- Vesting curve correctness (Chapter 2/3: get the math exactly right) ----

    function test_vestingCurveIsLinear() public {
        uint64 start = uint64(block.timestamp);
        uint64 duration = 100 days;
        _grant(1, 1_000 ether, start, duration);

        assertEq(vault.vestedAmount(1, start - 1), 0, "nothing before start");
        assertEq(vault.vestedAmount(1, start), 0, "nothing at start");
        assertEq(vault.vestedAmount(1, start + 25 days), 250 ether, "25% at quarter");
        assertEq(vault.vestedAmount(1, start + 50 days), 500 ether, "50% at half");
        assertEq(vault.vestedAmount(1, start + duration), 1_000 ether, "100% at end");
        assertEq(vault.vestedAmount(1, start + duration + 999 days), 1_000 ether, "capped after end");
    }

    // ---- Claim mechanics ----

    function test_claimBeforeStartReverts() public {
        uint64 start = uint64(block.timestamp) + 10 days;
        _grant(1, 1_000 ether, start, 100 days);

        vm.prank(beneficiary);
        vm.expectRevert(bytes("nothing to claim"));
        vault.claim(1);
    }

    function test_claimReleasesVestedPortion() public {
        uint64 start = uint64(block.timestamp);
        _grant(1, 1_000 ether, start, 100 days);

        vm.warp(start + 50 days);
        vm.prank(beneficiary);
        vault.claim(1);

        assertEq(token.balanceOf(beneficiary), 500 ether, "got half");
        assertEq(vault.claimedOf(1), 500 ether, "claimed tracked");
    }

    function test_noDoubleClaimAtSameTime() public {
        uint64 start = uint64(block.timestamp);
        _grant(1, 1_000 ether, start, 100 days);

        vm.warp(start + 50 days);
        vm.prank(beneficiary);
        vault.claim(1);

        // Second claim at the same instant vests nothing more.
        vm.prank(beneficiary);
        vm.expectRevert(bytes("nothing to claim"));
        vault.claim(1);
    }

    function test_fullyVestedClaimsEverything() public {
        uint64 start = uint64(block.timestamp);
        _grant(1, 1_000 ether, start, 100 days);

        vm.warp(start + 100 days);
        vm.prank(beneficiary);
        vault.claim(1);
        assertEq(token.balanceOf(beneficiary), 1_000 ether, "all claimed");
        assertEq(vault.claimedOf(1), vault.grantedOf(1), "claimed == granted");
    }

    // ---- Access control (Chapter 4) ----

    function test_onlyBeneficiaryCanClaim() public {
        uint64 start = uint64(block.timestamp);
        _grant(1, 1_000 ether, start, 100 days);
        vm.warp(start + 50 days);

        vm.prank(stranger);
        vm.expectRevert(bytes("only beneficiary"));
        vault.claim(1);
    }

    function test_grantIdCannotBeOverwritten() public {
        uint64 start = uint64(block.timestamp);
        _grant(1, 1_000 ether, start, 100 days);

        vm.startPrank(grantor);
        token.approve(address(vault), 500 ether);
        vm.expectRevert(bytes("grant exists"));
        vault.createGrant(1, stranger, 500 ether, start, 100 days);
        vm.stopPrank();
    }

    // ---- Invariants (Chapter 3) ----

    /// SOLVENCY: the vault can always cover what it still owes.
    function invariant_solvency() public {
        assertGe(
            token.balanceOf(address(vault)),
            vault.totalLiabilities(),
            "vault must hold at least its outstanding liabilities"
        );
    }

    // ---- helper ----

    function _grant(uint256 id, uint256 amount, uint64 start, uint64 duration) internal {
        vm.startPrank(grantor);
        token.approve(address(vault), amount);
        vault.createGrant(id, beneficiary, amount, start, duration);
        vm.stopPrank();
    }
}
