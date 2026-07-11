// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title SafeVault — VulnerableVault with the three bugs fixed.
/// @notice Fixes: (1) Checks-Effects-Interactions + a reentrancy guard;
///         (2) real access control with a proper modifier; (3) msg.sender, never
///         tx.origin.
contract SafeVault {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 private _locked = 1;

    constructor() {
        owner = msg.sender;
    }

    // FIX 3: authorize on msg.sender, not tx.origin.
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "reentrant");
        _locked = 2;
        _;
        _locked = 1;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // FIX 1: effects before interactions, plus a guard as defense in depth.
    function withdrawAll() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "nothing to withdraw");
        balances[msg.sender] = 0; // effect first
        (bool ok,) = msg.sender.call{value: amount}(""); // interaction last
        require(ok, "transfer failed");
    }

    // FIX 2: ownership transfer is a privileged action, guarded.
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        owner = newOwner;
    }

    function rescue(address to) external onlyOwner {
        (bool ok,) = to.call{value: address(this).balance}("");
        require(ok, "rescue failed");
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
