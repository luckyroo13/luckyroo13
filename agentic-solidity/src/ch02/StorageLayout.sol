// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title StorageLayout — a packing puzzle
/// @notice The variables below are deliberately ordered so the compiler packs
///         several of them into a single 32-byte slot. Your job (see
///         `chapters/02-.../exercises.md`) is to predict, for each variable, the
///         slot number and byte offset the compiler assigns — *before* running
///         the test. The test reads the real layout with `vm.load` and proves it.
///
/// @dev No agent can reliably tell you this from reading the source. The layout
///      is a property of the *compiler's rules applied to declaration order*, and
///      it's exactly the kind of thing that silently breaks an upgradeable
///      contract. You have to be able to derive it yourself.
contract StorageLayout {
    // ---- Predict the slot & offset of each of these ----
    uint128 public a; // ?
    uint64 public b; // ?
    uint64 public c; // ?
    address public owner; // ?
    bool public paused; // ?
    uint256 public big; // ?
    mapping(address => uint256) public balances; // ? (and where does balances[k] live?)
    uint128 public x; // ?
    uint128 public y; // ?

    constructor() {
        a = 0x1111;
        b = 0x2222;
        c = 0x3333;
        owner = address(0xBEEF);
        paused = true;
        big = 0xABCDEF;
        x = 0x4444;
        y = 0x5555;
    }

    function setBalance(address who, uint256 amount) external {
        balances[who] = amount;
    }
}
