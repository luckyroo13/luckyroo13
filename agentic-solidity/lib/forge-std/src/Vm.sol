// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @notice Minimal vendored subset of Foundry's `Vm` cheatcode interface.
/// @dev This is a trimmed copy of foundry-rs/forge-std sufficient to compile and
///      run the exercises in this tutorial. When you use real Foundry, run
///      `forge install foundry-rs/forge-std` to replace `lib/forge-std` with the
///      full, upstream version. Nothing here is invented — every function below
///      exists in upstream forge-std with the same selector.
interface Vm {
    // ---- Environment / time ----
    function warp(uint256 newTimestamp) external;
    function roll(uint256 newHeight) external;
    function fee(uint256 newBasefee) external;
    function chainId(uint256 newChainId) external;

    // ---- Accounts / balances ----
    function deal(address to, uint256 give) external;
    function prank(address msgSender) external;
    function prank(address msgSender, address txOrigin) external;
    function startPrank(address msgSender) external;
    function startPrank(address msgSender, address txOrigin) external;
    function stopPrank() external;
    function label(address account, string calldata newLabel) external;
    function addr(uint256 privateKey) external pure returns (address keyAddr);

    // ---- Storage ----
    function load(address target, bytes32 slot) external view returns (bytes32 data);
    function store(address target, bytes32 slot, bytes32 value) external;

    // ---- Expectations ----
    function expectRevert() external;
    function expectRevert(bytes4 revertData) external;
    function expectRevert(bytes calldata revertData) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;

    // ---- Signing ----
    function sign(uint256 privateKey, bytes32 digest)
        external
        pure
        returns (uint8 v, bytes32 r, bytes32 s);

    // ---- Invariant testing configuration ----
    function assume(bool condition) external pure;

    // ---- Mock / expectCall ----
    function mockCall(address callee, bytes calldata data, bytes calldata returnData) external;
    function expectCall(address callee, bytes calldata data) external;

    // ---- Snapshots ----
    function snapshotState() external returns (uint256 snapshotId);
    function revertToState(uint256 snapshotId) external returns (bool success);
}
