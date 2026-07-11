// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title SecureTimelock — Timelock with the delay actually enforced.
/// @notice Two fixes turn the fiction into a real guarantee:
///           1. `queue` requires `eta >= block.timestamp + delay` (and bounds the
///              configured delay), so a queued action genuinely cannot execute
///              before the delay elapses.
///           2. `execute` requires `block.timestamp <= eta + GRACE_PERIOD`, so a
///              stale action expires instead of lingering as a live privileged
///              call forever.
contract SecureTimelock {
    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    uint256 public delay;
    mapping(bytes32 => bool) public queued;

    event Queued(bytes32 indexed id, address target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 indexed id, address target, uint256 value, bytes data, uint256 eta);
    event Canceled(bytes32 indexed id);

    constructor(address _admin, uint256 _delay) {
        require(_admin != address(0), "zero admin");
        require(_delay >= MINIMUM_DELAY && _delay <= MAXIMUM_DELAY, "bad delay");
        admin = _admin;
        delay = _delay;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    function txId(address target, uint256 value, bytes memory data, uint256 eta)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(target, value, data, eta));
    }

    function queue(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
        returns (bytes32 id)
    {
        // FIX 1: the action must genuinely wait at least `delay`.
        require(eta >= block.timestamp + delay, "eta before delay");
        id = txId(target, value, data, eta);
        queued[id] = true;
        emit Queued(id, target, value, data, eta);
    }

    function execute(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        payable
        onlyAdmin
        returns (bytes memory)
    {
        bytes32 id = txId(target, value, data, eta);
        require(queued[id], "not queued");
        require(block.timestamp >= eta, "too early");
        // FIX 2: actions expire; they can't sit executable indefinitely.
        require(block.timestamp <= eta + GRACE_PERIOD, "stale");
        queued[id] = false;
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        require(ok, "exec failed");
        emit Executed(id, target, value, data, eta);
        return ret;
    }

    function cancel(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
    {
        bytes32 id = txId(target, value, data, eta);
        queued[id] = false;
        emit Canceled(id);
    }
}
