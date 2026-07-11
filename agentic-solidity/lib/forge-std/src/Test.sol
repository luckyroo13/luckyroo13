// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Vm} from "./Vm.sol";
import {console} from "./console.sol";

/// @notice Minimal vendored `Test` base (subset of forge-std/Test).
/// @dev Provides `vm`, the common assertions, and `StdInvariant`'s
///      `targetContract` plumbing used by the invariant chapters. It is a
///      faithful, trimmed reimplementation — the public surface matches
///      upstream forge-std so swapping in the real library needs no code
///      changes. Run `forge install foundry-rs/forge-std` when using Foundry.
abstract contract StdInvariant {
    address[] internal _targetedContracts;
    bytes4[] internal _excludedSelectors;

    function targetContract(address newTargetedContract) internal {
        _targetedContracts.push(newTargetedContract);
    }

    function targetContracts() public view returns (address[] memory) {
        return _targetedContracts;
    }
}

abstract contract Test is StdInvariant {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // Test failure flag read by the Foundry runner.
    bool private _failed;

    function failed() public view returns (bool) {
        return _failed;
    }

    function fail() internal {
        _failed = true;
    }

    // ---- Assertions (subset) ----
    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: assertion failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    function assertFalse(bool condition) internal {
        assertTrue(!condition);
    }

    function assertFalse(bool condition, string memory err) internal {
        assertTrue(!condition, err);
    }

    function assertEq(uint256 a, uint256 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("      Left", a);
            emit log_named_uint("     Right", b);
            fail();
        }
    }

    function assertEq(uint256 a, uint256 b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            emit log_named_uint("      Left", a);
            emit log_named_uint("     Right", b);
            fail();
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            fail();
        }
    }

    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            fail();
        }
    }

    function assertEq(bool a, bool b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bool]");
            fail();
        }
    }

    function assertEq(bool a, bool b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    function assertLt(uint256 a, uint256 b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    function assertLe(uint256 a, uint256 b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    function assertGt(uint256 a, uint256 b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    function assertGe(uint256 a, uint256 b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            fail();
        }
    }

    // ---- Logs consumed by the Foundry runner ----
    event log(string);
    event log_named_uint(string key, uint256 val);
    event log_named_string(string key, string val);
    event log_named_address(string key, address val);
}
