// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SecureTimelock} from "./SecureTimelock.sol";

contract Target {
    uint256 public number;

    function setNumber(uint256 n) external {
        number = n;
    }
}

/// @notice Proves the hardened timelock enforces the delay and expiry. Run with:
///           forge test --profile solutions --match-path solutions/ch06
contract SecureTimelockTest is Test {
    SecureTimelock internal timelock;
    Target internal target;

    address internal admin = address(0xA11);

    function setUp() public {
        // start at a realistic timestamp so subtraction/eta math is well-behaved
        vm.warp(1_000_000);
        timelock = new SecureTimelock(admin, 2 days);
        target = new Target();
    }

    function _call(uint256 n) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(Target.setNumber.selector, n);
    }

    /// The weakness is gone: you can no longer queue an action for immediate
    /// execution.
    function test_cannotQueueZeroDelay() public {
        uint256 eta = block.timestamp; // too soon
        vm.prank(admin);
        vm.expectRevert(bytes("eta before delay"));
        timelock.queue(address(target), 0, _call(1), eta);
    }

    /// A properly-delayed action still works.
    function test_delayedExecutionWorks() public {
        uint256 eta = block.timestamp + 2 days;
        bytes memory data = _call(42);

        vm.prank(admin);
        timelock.queue(address(target), 0, data, eta);

        vm.warp(eta);
        vm.prank(admin);
        timelock.execute(address(target), 0, data, eta);
        assertEq(target.number(), 42, "executed after real delay");
    }

    /// A stale action expires instead of lingering as a live privileged call.
    function test_staleActionExpires() public {
        uint256 eta = block.timestamp + 2 days;
        bytes memory data = _call(7);

        vm.prank(admin);
        timelock.queue(address(target), 0, data, eta);

        vm.warp(eta + 14 days + 1); // past the grace window
        vm.prank(admin);
        vm.expectRevert(bytes("stale"));
        timelock.execute(address(target), 0, data, eta);
    }
}
