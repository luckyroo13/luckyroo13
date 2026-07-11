// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC20} from "./MockERC20.sol";

/// @title ShareVault — a naive ERC4626-style vault with the inflation bug.
/// @notice Mints shares proportional to assets, valuing the pool by its raw token
///         balance. Two planted defects that combine into the classic
///         "first-depositor / share inflation" theft:
///           1. `totalAssets()` reads `balanceOf(this)`, so a *donation* (a plain
///              transfer, not a deposit) moves the share price.
///           2. `deposit` floors shares to zero without a minimum-shares or
///              virtual-offset defense, so a later depositor can mint 0 shares
///              and lose their whole deposit.
///         See `test/ch04/ShareInflation.t.sol`.
contract ShareVault {
    MockERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public shares;

    constructor(MockERC20 _asset) {
        asset = _asset;
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets) external returns (uint256 mintedShares) {
        uint256 supply = totalShares;
        if (supply == 0) {
            mintedShares = assets; // bootstrap 1:1
        } else {
            // Price computed from current balance, BEFORE pulling this deposit.
            mintedShares = (assets * supply) / totalAssets();
        }
        // BUG: no `require(mintedShares > 0)` — a depositor can receive nothing.
        asset.transferFrom(msg.sender, address(this), assets);
        shares[msg.sender] += mintedShares;
        totalShares += mintedShares;
    }

    function redeem(uint256 sharesToBurn) external returns (uint256 assetsOut) {
        assetsOut = (sharesToBurn * totalAssets()) / totalShares;
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        asset.transfer(msg.sender, assetsOut);
    }
}
