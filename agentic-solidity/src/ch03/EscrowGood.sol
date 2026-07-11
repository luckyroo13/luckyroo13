// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEscrow} from "./IEscrow.sol";

/// @title EscrowGood — a correct implementation of IEscrow.
/// @notice Keeps `totalEscrowed` exactly in sync with the ETH held, on every
///         path. This is the implementation your invariant suite should accept.
contract EscrowGood is IEscrow {
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

        // Checks-Effects-Interactions: clear accounting before paying out.
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
        _totalEscrowed -= amt;

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
