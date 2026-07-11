// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title VulnerableVault — an "agent-style" ETH vault to audit.
/// @notice Reads cleanly, compiles, happy path works. It contains at least three
///         planted bugs from the Chapter 4 taxonomy. Find them by review first;
///         `test/ch04/VaultExploits.t.sol` then proves each one with a working
///         attack. Do NOT copy this contract into anything real.
contract VulnerableVault {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // BUG (access control): uses tx.origin, not msg.sender. Any contract the
    // owner is tricked into calling can invoke owner-only functions, because
    // tx.origin is still the owner two calls deep.
    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // BUG (reentrancy / CEI): the external call happens BEFORE the balance is
    // cleared. A malicious recipient re-enters withdrawAll while its recorded
    // balance is still non-zero and drains the whole vault. The `= 0` after the
    // call is idempotent, so unlike a `-= amount` pattern there is no underflow
    // to accidentally save you — the drain completes cleanly.
    function withdrawAll() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "nothing to withdraw");
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
        balances[msg.sender] = 0;
    }

    // BUG (access control): no modifier at all. Anyone can change the owner and
    // then sweep. The name suggests it's protected; it is not.
    function setOwner(address newOwner) external {
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
