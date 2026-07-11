// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC20} from "./MockERC20.sol";

/// @notice A DEX pool whose reserves can be moved — a stand-in for the state a
///         real AMM exposes and that a flash loan can shove around within a
///         single transaction.
contract MockPool {
    uint256 public reserveToken;
    uint256 public reserveETH;

    function setReserves(uint256 token_, uint256 eth_) external {
        reserveToken = token_;
        reserveETH = eth_;
    }
}

/// @title SpotOracleLoan — a lender that trusts a spot price.
/// @notice Lets users borrow ETH against a collateral token, valuing the
///         collateral at the pool's *instantaneous* reserve ratio. That single
///         design choice is the bug: the price is whatever the pool says right
///         now, and the pool can be manipulated in the same transaction (classic
///         flash-loan oracle attack). See `test/ch04/OracleExploit.t.sol`.
contract SpotOracleLoan {
    MockPool public immutable pool;
    MockERC20 public immutable collateral;

    mapping(address => uint256) public collateralOf;
    mapping(address => uint256) public debtOf;

    constructor(MockPool _pool, MockERC20 _collateral) payable {
        pool = _pool;
        collateral = _collateral;
    }

    /// BUG (oracle manipulation): price is the raw spot reserve ratio. No TWAP,
    /// no sanity bounds, no staleness. wei per 1e18 collateral token.
    function price() public view returns (uint256) {
        return (pool.reserveETH() * 1e18) / pool.reserveToken();
    }

    function depositCollateral(uint256 amount) external {
        collateral.transferFrom(msg.sender, address(this), amount);
        collateralOf[msg.sender] += amount;
    }

    function borrow(uint256 ethAmount) external {
        uint256 maxDebt = (collateralOf[msg.sender] * price()) / 1e18;
        require(debtOf[msg.sender] + ethAmount <= maxDebt, "undercollateralized");
        debtOf[msg.sender] += ethAmount;
        (bool ok,) = msg.sender.call{value: ethAmount}("");
        require(ok, "transfer failed");
    }

    receive() external payable {}
}
