// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IToken} from "./IToken.sol";
import {IVesting} from "./IVesting.sol";

/// @title VestingVault — a REFERENCE implementation of IVesting.
/// @notice This is the "known-good" contract that keeps the repo's grading suite
///         green out of the box. In the capstone exercise you replace this with
///         an agent's implementation of `IVesting` and re-run
///         `test/ch07/VestingGrading.t.sol` — your specification (the grading
///         suite), not the code, is what decides whether the agent got it right.
contract VestingVault is IVesting {
    struct Grant {
        address beneficiary;
        uint256 amount; // total granted
        uint256 claimed;
        uint64 start;
        uint64 duration;
    }

    IToken public immutable token;
    mapping(uint256 => Grant) private grants;
    uint256 private _totalLiabilities;

    constructor(IToken _token) {
        token = _token;
    }

    function createGrant(uint256 grantId, address beneficiary, uint256 amount, uint64 start, uint64 duration)
        external
    {
        Grant storage g = grants[grantId];
        require(g.beneficiary == address(0), "grant exists");
        require(beneficiary != address(0), "zero beneficiary");
        require(amount > 0, "zero amount");
        require(duration > 0, "zero duration");

        g.beneficiary = beneficiary;
        g.amount = amount;
        g.start = start;
        g.duration = duration;
        _totalLiabilities += amount;

        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
    }

    function vestedAmount(uint256 grantId, uint64 timestamp) public view returns (uint256) {
        Grant storage g = grants[grantId];
        if (g.amount == 0) return 0;
        if (timestamp < g.start) return 0;
        uint64 elapsed = timestamp - g.start;
        if (elapsed >= g.duration) return g.amount;
        return (g.amount * elapsed) / g.duration;
    }

    function claimable(uint256 grantId) public view returns (uint256) {
        return vestedAmount(grantId, uint64(block.timestamp)) - grants[grantId].claimed;
    }

    function claim(uint256 grantId) external {
        Grant storage g = grants[grantId];
        require(msg.sender == g.beneficiary, "only beneficiary");
        uint256 amount = claimable(grantId);
        require(amount > 0, "nothing to claim");

        // Effects before interaction; claimed only grows and stays <= amount.
        g.claimed += amount;
        _totalLiabilities -= amount;

        require(token.transfer(g.beneficiary, amount), "transfer failed");
    }

    function grantedOf(uint256 grantId) external view returns (uint256) {
        return grants[grantId].amount;
    }

    function claimedOf(uint256 grantId) external view returns (uint256) {
        return grants[grantId].claimed;
    }

    function beneficiaryOf(uint256 grantId) external view returns (address) {
        return grants[grantId].beneficiary;
    }

    function totalLiabilities() external view returns (uint256) {
        return _totalLiabilities;
    }
}
