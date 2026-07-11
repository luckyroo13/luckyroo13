// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Timelock — queue/execute governance delay, with a planted weakness.
/// @notice A timelock exists so that privileged actions (upgrades, parameter
///         changes, treasury moves) are announced and cannot take effect for a
///         fixed delay — giving users time to see them coming and exit if they
///         object. This implementation *looks* like a timelock and compiles, but
///         it forgets to enforce the one thing that makes a timelock a timelock.
///         Your job (Chapter 6 exercise) is to find and fix it.
///
/// @dev See `test/ch06/Timelock.t.sol` — the weakness lets the admin execute a
///      queued action with zero delay, defeating the entire purpose.
contract Timelock {
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
        // WEAKNESS: no `require(eta >= block.timestamp + delay)`. Nothing forces
        // the action to actually wait for the delay. The admin can queue with an
        // eta of "now" and execute in the same block.
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
        // WEAKNESS: no upper bound. A stale action queued long ago can still be
        // executed forever; there is no window after which it expires.
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
