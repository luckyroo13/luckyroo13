// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {EIP1967Proxy, LogicV1Fixed} from "./EIP1967Proxy.sol";

/// @notice Proves the fix: the same `initialize` call that hijacked NaiveProxy is
///         now harmless, and the proxy keeps working. Run with:
///           forge test --profile solutions --match-path solutions/ch02
contract EIP1967ProxyTest is Test {
    EIP1967Proxy internal proxy;
    LogicV1Fixed internal logic;

    address internal deployer = address(this);
    address internal user = address(0xA11CE);

    function setUp() public {
        logic = new LogicV1Fixed();
        proxy = new EIP1967Proxy(address(logic));
    }

    function test_pointerSurvivesInitialize() public {
        address implBefore = proxy.implementation();

        // The exact call that took over NaiveProxy.
        vm.prank(user);
        LogicV1Fixed(payable(address(proxy))).initialize(user);

        // Implementation pointer is untouched — no collision.
        assertEq(proxy.implementation(), implBefore, "implementation pointer is safe");
        assertEq(proxy.admin(), deployer, "admin is safe");
    }

    function test_logicActuallyWorksThroughProxy() public {
        vm.prank(user);
        LogicV1Fixed(payable(address(proxy))).initialize(user);

        // owner was written to the logic's slot 0, in the proxy's storage.
        assertEq(LogicV1Fixed(payable(address(proxy))).owner(), user, "owner set via delegatecall");

        vm.prank(user);
        LogicV1Fixed(payable(address(proxy))).setValue(42);
        assertEq(LogicV1Fixed(payable(address(proxy))).value(), 42, "state reads/writes work");
    }

    function test_onlyAdminCanUpgrade() public {
        vm.prank(user);
        vm.expectRevert(bytes("not admin"));
        proxy.upgradeTo(address(0xBEEF));
    }
}
