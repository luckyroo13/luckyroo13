// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StorageLayout} from "../../src/ch02/StorageLayout.sol";

/// @notice Proves the *actual* storage layout of `StorageLayout` by reading raw
///         slots with `vm.load`. Compare these assertions against the prediction
///         you wrote in exercises.md. If your prediction disagrees with a passing
///         test, the test is right and your mental model has a gap to close —
///         that gap is the whole point of the exercise.
contract StorageLayoutTest is Test {
    StorageLayout internal s;

    function setUp() public {
        s = new StorageLayout();
    }

    /// slot 0 packs three values: a (uint128, bytes 0..15),
    /// b (uint64, bytes 16..23), c (uint64, bytes 24..31).
    function test_slot0_packs_a_b_c() public {
        uint256 slot0 = uint256(vm.load(address(s), bytes32(uint256(0))));

        uint128 a = uint128(slot0); // low 16 bytes
        uint64 b = uint64(slot0 >> 128); // next 8 bytes
        uint64 c = uint64(slot0 >> 192); // top 8 bytes

        assertEq(uint256(a), 0x1111, "a should sit at slot 0 offset 0");
        assertEq(uint256(b), 0x2222, "b should sit at slot 0 offset 16");
        assertEq(uint256(c), 0x3333, "c should sit at slot 0 offset 24");
    }

    /// slot 1 packs owner (address, bytes 0..19) and paused (bool, byte 20).
    function test_slot1_packs_owner_and_paused() public {
        uint256 slot1 = uint256(vm.load(address(s), bytes32(uint256(1))));

        address owner = address(uint160(slot1));
        bool paused = ((slot1 >> 160) & 1) == 1;

        assertEq(owner, address(0xBEEF), "owner should sit at slot 1 offset 0");
        assertTrue(paused, "paused should sit at slot 1 offset 20");
    }

    /// `big` is a full uint256 that cannot share slot 1's remaining 11 bytes,
    /// so it takes slot 2 alone.
    function test_slot2_is_big_alone() public {
        uint256 slot2 = uint256(vm.load(address(s), bytes32(uint256(2))));
        assertEq(slot2, 0xABCDEF, "big should occupy slot 2 entirely");
    }

    /// The mapping `balances` reserves slot 3 as a placeholder; the value for a
    /// key lives at keccak256(abi.encode(key, slot)). Nothing is stored at slot 3
    /// itself.
    function test_slot3_mapping_value_location() public {
        address who = address(0xCAFE);
        s.setBalance(who, 777);

        // Slot 3 (the placeholder) stays zero.
        assertEq(uint256(vm.load(address(s), bytes32(uint256(3)))), 0, "mapping slot itself is empty");

        // The real entry lives at the hashed location.
        bytes32 entrySlot = keccak256(abi.encode(who, uint256(3)));
        assertEq(uint256(vm.load(address(s), entrySlot)), 777, "balances[who] lives at keccak256(key, 3)");
    }

    /// slot 4 packs x and y (two uint128s) back together.
    function test_slot4_packs_x_and_y() public {
        uint256 slot4 = uint256(vm.load(address(s), bytes32(uint256(4))));
        uint128 x = uint128(slot4);
        uint128 y = uint128(slot4 >> 128);
        assertEq(uint256(x), 0x4444, "x should sit at slot 4 offset 0");
        assertEq(uint256(y), 0x5555, "y should sit at slot 4 offset 16");
    }
}
