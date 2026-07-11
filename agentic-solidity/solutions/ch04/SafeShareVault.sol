// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC20} from "../../src/ch04/MockERC20.sol";

/// @title SafeShareVault — ShareVault with the inflation bug closed.
/// @notice Uses the virtual-shares / virtual-assets offset (the defense
///         OpenZeppelin's ERC4626 adopted): every calculation behaves as if the
///         vault already holds 1 extra virtual share and 1 extra virtual asset.
///         This makes the price of the first share bounded, so a donation can no
///         longer round a later depositor down to zero — the attacker would have
///         to donate far more than they could ever steal.
contract SafeShareVault {
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
        // +1 virtual share and +1 virtual asset in the ratio.
        mintedShares = (assets * (totalShares + 1)) / (totalAssets() + 1);
        require(mintedShares > 0, "zero shares"); // belt and suspenders
        asset.transferFrom(msg.sender, address(this), assets);
        shares[msg.sender] += mintedShares;
        totalShares += mintedShares;
    }

    function redeem(uint256 sharesToBurn) external returns (uint256 assetsOut) {
        assetsOut = (sharesToBurn * (totalAssets() + 1)) / (totalShares + 1);
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        asset.transfer(msg.sender, assetsOut);
    }
}
