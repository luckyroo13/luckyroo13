// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEscrow} from "./IEscrow.sol";

/// @title EscrowBuggy — passes every hand-written unit test, breaks the invariant.
/// @notice This is the kind of implementation an agent produces: it compiles,
///         the happy path works, `deposit`/`release` are perfect. The defect is a
///         single missing line in `refund` — it pays the buyer and zeroes the
///         deal, but forgets to decrement `_totalEscrowed`. The books now claim
///         the contract holds more than it does. No unit test that only checks
///         "did the buyer get their money back?" will ever catch it. The solvency
///         invariant catches it on the first refund.
contract EscrowBuggy is IEscrow {
    struct Deal {
        address buyer;
        address seller;
        uint256 amount;
    }

    mapping(uint256 => Deal) private deals;
    uint256 private _totalEscrowed;

    function deposit(uint256 dealId, address seller) external payable {
        Deal storage d = deals[dealId];
        require(d.buyer == address(0), "deal exists");
        require(seller != address(0), "bad seller");
        require(msg.value > 0, "no value");

        d.buyer = msg.sender;
        d.seller = seller;
        d.amount = msg.value;
        _totalEscrowed += msg.value;
    }

    function release(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(msg.sender == d.buyer, "only buyer");
        uint256 amt = d.amount;
        require(amt > 0, "nothing to release");

        d.amount = 0;
        _totalEscrowed -= amt;

        (bool ok,) = d.seller.call{value: amt}("");
        require(ok, "transfer failed");
    }

    function refund(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(msg.sender == d.seller, "only seller");
        uint256 amt = d.amount;
        require(amt > 0, "nothing to refund");

        d.amount = 0;
        // BUG: `_totalEscrowed -= amt;` is missing. The ETH leaves the contract
        // but the liability counter does not, so totalEscrowed() now overstates
        // the balance. Solvency invariant: balance == totalEscrowed() is broken.

        (bool ok,) = d.buyer.call{value: amt}("");
        require(ok, "transfer failed");
    }

    function totalEscrowed() external view returns (uint256) {
        return _totalEscrowed;
    }

    function amountOf(uint256 dealId) external view returns (uint256) {
        return deals[dealId].amount;
    }

    function buyerOf(uint256 dealId) external view returns (address) {
        return deals[dealId].buyer;
    }

    function sellerOf(uint256 dealId) external view returns (address) {
        return deals[dealId].seller;
    }
}
