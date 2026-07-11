// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title NaiveProxy — the proxy an agent writes when you ask for "an upgradeable
///        contract" without telling it how to place its own storage.
/// @notice This code compiles, deploys, and *looks* completely reasonable. It is
///         also fatally broken. The bug is a storage collision: the proxy keeps
///         its own bookkeeping (`implementation`, `admin`) in slots 0 and 1, and
///         `delegatecall` runs the logic contract's code against the *proxy's*
///         storage — where the logic contract also thinks slots 0 and 1 are its
///         own state. See `test/ch02/ProxyCollision.t.sol` for the exploit.
contract NaiveProxy {
    // slot 0 and slot 1 — the proxy's own state.
    address public implementation;
    address public admin;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function upgradeTo(address newImplementation) external {
        require(msg.sender == admin, "not admin");
        implementation = newImplementation;
    }

    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/// @title LogicV1 — a perfectly ordinary implementation contract.
/// @notice On its own this is fine. Run it *behind NaiveProxy* and its `owner`
///         variable lands on slot 0 — the same slot the proxy uses for
///         `implementation`. Calling `initialize` through the proxy overwrites
///         the proxy's implementation pointer with an address derived from the
///         caller, bricking (or hijacking) the whole contract.
contract LogicV1 {
    // slot 0 — collides with NaiveProxy.implementation
    address public owner;
    // slot 1 — collides with NaiveProxy.admin
    uint256 public value;

    function initialize(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        require(msg.sender == owner, "not owner");
        value = _value;
    }
}
