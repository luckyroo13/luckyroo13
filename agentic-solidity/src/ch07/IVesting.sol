// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IVesting — the capstone specification.
/// @notice A linear token-vesting vault. A grantor locks ERC20 tokens for a
///         beneficiary; the tokens vest linearly from `start` over `duration`
///         seconds; the beneficiary claims whatever has vested but not yet been
///         claimed. This interface is the *spec you hand the agent*. The
///         properties an implementation MUST satisfy live in
///         `test/ch07/VestingGrading.t.sol` and are summarized in the chapter.
///
/// REQUIRED BEHAVIOR
///  - createGrant pulls exactly `amount` tokens from the caller (the grantor).
///  - vestedAmount(id, t): 0 before start; granted at/after start+duration;
///    granted * (t - start) / duration in between (linear).
///  - claimable(id) == vestedAmount(id, now) - claimed(id).
///  - claim(id) transfers claimable to the beneficiary and only the beneficiary.
///  - Grant ids are unique; a used id cannot be overwritten.
///
/// REQUIRED INVARIANTS
///  - SOLVENCY: token balance held >= totalLiabilities() (granted - claimed, all
///    grants). The vault can always pay what it still owes.
///  - MONOTONIC: claimed(id) only increases and never exceeds granted(id).
interface IVesting {
    function createGrant(uint256 grantId, address beneficiary, uint256 amount, uint64 start, uint64 duration)
        external;
    function claim(uint256 grantId) external;

    function vestedAmount(uint256 grantId, uint64 timestamp) external view returns (uint256);
    function claimable(uint256 grantId) external view returns (uint256);

    function grantedOf(uint256 grantId) external view returns (uint256);
    function claimedOf(uint256 grantId) external view returns (uint256);
    function beneficiaryOf(uint256 grantId) external view returns (address);

    function totalLiabilities() external view returns (uint256);
}
