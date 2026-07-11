// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title EIP1967Proxy — the fix for NaiveProxy's storage collision.
/// @notice The proxy stores its bookkeeping at *pseudo-random* slots defined by
///         EIP-1967, chosen so no sequentially-laid-out logic contract will ever
///         land on them. The implementation lives at
///         keccak256("eip1967.proxy.implementation") - 1, the admin at
///         keccak256("eip1967.proxy.admin") - 1. Now the logic contract owns
///         slots 0, 1, 2, ... freely, and the proxy's state is out of reach.
contract EIP1967Proxy {
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address implementation_) {
        _setSlot(_ADMIN_SLOT, msg.sender);
        _setSlot(_IMPLEMENTATION_SLOT, implementation_);
    }

    function implementation() external view returns (address) {
        return _getSlot(_IMPLEMENTATION_SLOT);
    }

    function admin() external view returns (address) {
        return _getSlot(_ADMIN_SLOT);
    }

    function upgradeTo(address newImplementation) external {
        require(msg.sender == _getSlot(_ADMIN_SLOT), "not admin");
        _setSlot(_IMPLEMENTATION_SLOT, newImplementation);
    }

    function _getSlot(bytes32 slot) private view returns (address a) {
        assembly {
            a := sload(slot)
        }
    }

    function _setSlot(bytes32 slot, address value) private {
        assembly {
            sstore(slot, value)
        }
    }

    fallback() external payable {
        address impl = _getSlot(_IMPLEMENTATION_SLOT);
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

/// @notice Same logic contract as before, unchanged. The point of the fix is
///         that the *logic contract does not need to change* — the proxy simply
///         stops parking its own state where the logic contract lives.
contract LogicV1Fixed {
    address public owner; // slot 0 — now safely the logic's own
    uint256 public value; // slot 1 — now safely the logic's own

    function initialize(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        require(msg.sender == owner, "not owner");
        value = _value;
    }
}
