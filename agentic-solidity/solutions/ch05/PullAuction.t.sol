// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {PullAuction} from "./PullAuction.sol";

/// @notice A would-be griefer that rejects direct ETH. Against PullAuction it is
///         powerless: its refund is credited, not pushed, so it can be outbid
///         freely. It simply forfeits a refund it refuses to withdraw.
contract RefundRejector {
    PullAuction public immutable auction;

    constructor(PullAuction _auction) {
        auction = _auction;
    }

    function placeBid() external payable {
        auction.bid{value: msg.value}();
    }

    receive() external payable {
        revert("I never accept ETH");
    }
}

/// @notice Proves the griefing capture is gone. Run with:
///           forge test --profile solutions --match-path solutions/ch05
contract PullAuctionTest is Test {
    PullAuction internal auction;
    address internal honest = address(0xB0B);

    function setUp() public {
        auction = new PullAuction(1 days);
    }

    function test_grieferCannotFreezeAuction() public {
        RefundRejector griefer = new RefundRejector(auction);
        vm.deal(address(griefer), 1 ether);
        griefer.placeBid{value: 1 ether}();
        assertEq(auction.highestBidder(), address(griefer), "griefer leads for now");

        // The honest whale outbids without trouble — no push refund to block.
        vm.deal(honest, 100 ether);
        vm.prank(honest);
        auction.bid{value: 100 ether}();

        assertEq(auction.highestBidder(), honest, "honest bidder took the lead");
        // The griefer's refund is merely credited; refusing to withdraw hurts
        // only the griefer.
        assertEq(auction.refunds(address(griefer)), 1 ether, "griefer's refund is waiting, unclaimed");
    }

    function test_honestBidderCanWithdrawRefund() public {
        address a = address(0xA);
        vm.deal(a, 1 ether);
        vm.prank(a);
        auction.bid{value: 1 ether}();

        vm.deal(honest, 2 ether);
        vm.prank(honest);
        auction.bid{value: 2 ether}();

        uint256 before = a.balance;
        vm.prank(a);
        auction.withdrawRefund();
        assertEq(a.balance, before + 1 ether, "outbid bidder pulls their refund");
    }
}
