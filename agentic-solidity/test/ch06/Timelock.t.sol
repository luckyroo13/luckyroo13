// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Timelock} from "../../src/ch06/Timelock.sol";

/// @notice A trivial target the timelock will act on.
contract Target {
    uint256 public number;

    function setNumber(uint256 n) external {
        number = n;
    }
}

/// @notice Shows the timelock's happy path working AND the planted weakness: an
///         action can be executed with no delay at all, so the "timelock" gives
///         users zero warning.
contract TimelockTest is Test {
    Timelock internal timelock;
    Target internal target;

    address internal admin = address(0xA11);

    function setUp() public {
        timelock = new Timelock(admin, 2 days);
        target = new Target();
    }

    function _call(uint256 n) internal view returns (bytes memory) {
        return abi.encodeWithSelector(Target.setNumber.selector, n);
    }

    /// The intended path: queue with a proper eta, wait, execute.
    function test_delayedExecutionWorks() public {
        uint256 eta = block.timestamp + 2 days;
        bytes memory data = _call(42);

        vm.prank(admin);
        timelock.queue(address(target), 0, data, eta);

        // Before the eta, execution is too early.
        vm.prank(admin);
        vm.expectRevert(bytes("too early"));
        timelock.execute(address(target), 0, data, eta);

        // After the delay, it executes.
        vm.warp(eta);
        vm.prank(admin);
        timelock.execute(address(target), 0, data, eta);
        assertEq(target.number(), 42, "action executed after delay");
    }

    /// THE WEAKNESS. The admin queues with eta = now and executes immediately —
    /// the delay is never enforced, so the timelock protects no one. This test
    /// passes, documenting that the "2 day" delay is a fiction.
    function test_weakness_zeroDelayExecution() public {
        uint256 eta = block.timestamp; // no wait at all
        bytes memory data = _call(1337);

        vm.startPrank(admin);
        timelock.queue(address(target), 0, data, eta);
        // Same timestamp, no warp: executes instantly.
        timelock.execute(address(target), 0, data, eta);
        vm.stopPrank();

        assertEq(target.number(), 1337, "WEAKNESS: executed with zero delay");
    }
}
