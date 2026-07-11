// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title PullAuction — the griefing-resistant redesign.
/// @notice The fix is not a line edit; it's a change of *payment model*. Instead
///         of pushing a refund to the outbid party inside `bid` (where they can
///         block it), we credit them a balance they withdraw themselves. One
///         account's refusal to accept ETH can no longer stop anyone else. This
///         is the pull-over-push pattern, and it exists precisely to remove the
///         griefing incentive.
contract PullAuction {
    address public immutable seller;
    uint256 public immutable endTime;

    address public highestBidder;
    uint256 public highestBid;
    bool public settled;

    mapping(address => uint256) public refunds;

    constructor(uint256 duration) {
        seller = msg.sender;
        endTime = block.timestamp + duration;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "auction over");
        require(msg.value > highestBid, "bid too low");

        if (highestBidder != address(0)) {
            // Credit, don't send. The previous bidder pulls their own refund.
            refunds[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdrawRefund() external {
        uint256 amount = refunds[msg.sender];
        require(amount > 0, "nothing to withdraw");
        refunds[msg.sender] = 0; // effect before interaction
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function settle() external {
        require(block.timestamp >= endTime, "not over");
        require(!settled, "settled");
        settled = true;
        (bool ok,) = seller.call{value: highestBid}("");
        require(ok, "payout failed");
    }
}
