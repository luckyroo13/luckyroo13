// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Minimal ERC20 surface the vesting vault needs. `MockERC20` (from
///         ch04) satisfies it.
interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}
