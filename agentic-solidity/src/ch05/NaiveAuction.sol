// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title NaiveAuction — a "correct" auction with an economic flaw.
/// @notice There is no reentrancy here (state is updated before the refund),
///         no access-control gap, no arithmetic bug. Every unit test you'd write
///         passes. And it can still be captured for the price of one low bid,
///         because of how it *pays refunds*: it pushes ETH back to the previous
///         highest bidder inside `bid`. A bidder whose `receive` reverts can
///         never be refunded, so nobody can ever outbid them. The auction is
///         frozen with the griefer in the lead. See `test/ch05/AuctionGrief.t.sol`.
///
/// @dev This is the Chapter 5 lesson in one contract: the bug is not in the code,
///      it's in the *incentive and control-flow design*. No amount of
///      line-level correctness or gas micro-optimization saves you.
contract NaiveAuction {
    address public immutable seller;
    uint256 public immutable endTime;

    address public highestBidder;
    uint256 public highestBid;
    bool public settled;

    constructor(uint256 duration) {
        seller = msg.sender;
        endTime = block.timestamp + duration;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "auction over");
        require(msg.value > highestBid, "bid too low");

        address previousBidder = highestBidder;
        uint256 previousBid = highestBid;

        // Effects first (so this is NOT a reentrancy bug)...
        highestBidder = msg.sender;
        highestBid = msg.value;

        // ...but the PUSH refund is the economic flaw: if the previous bidder is
        // a contract that rejects ETH, this reverts and the new bid fails. The
        // griefer, once in the lead, can never be displaced.
        if (previousBidder != address(0)) {
            (bool ok,) = previousBidder.call{value: previousBid}("");
            require(ok, "refund failed");
        }
    }

    function settle() external {
        require(block.timestamp >= endTime, "not over");
        require(!settled, "settled");
        settled = true;
        (bool ok,) = seller.call{value: highestBid}("");
        require(ok, "payout failed");
    }
}
