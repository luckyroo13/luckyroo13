// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IEscrow} from "../../src/ch03/IEscrow.sol";
import {EscrowGood} from "../../src/ch03/EscrowGood.sol";
import {EscrowBuggy} from "../../src/ch03/EscrowBuggy.sol";

/// @notice Drives an escrow with bounded, randomized deposit/release/refund calls
///         so Foundry's invariant runner can search for a state that breaks
///         solvency. The handler is buyer and seller for every deal, so it can
///         exercise both resolution paths and keeps the ETH self-contained.
contract EscrowHandler {
    IEscrow public immutable escrow;
    uint256 internal constant DEALS = 5;

    constructor(IEscrow _escrow) {
        escrow = _escrow;
    }

    receive() external payable {}

    function deposit(uint256 id, uint256 amt) external {
        id = id % DEALS;
        if (escrow.buyerOf(id) != address(0)) return; // deal already open
        uint256 value = (amt % 10 ether) + 1;
        if (address(this).balance < value) return;
        escrow.deposit{value: value}(id, address(this));
    }

    function release(uint256 id) external {
        id = id % DEALS;
        if (escrow.amountOf(id) == 0) return;
        escrow.release(id);
    }

    function refund(uint256 id) external {
        id = id % DEALS;
        if (escrow.amountOf(id) == 0) return;
        escrow.refund(id);
    }
}

/// @notice Chapter 3's harness. `invariant_solvency` is the property you were
///         asked to write: the contract's ETH balance must always equal its
///         declared liabilities. It runs against the *correct* implementation and
///         holds. The deterministic tests below show the same property being
///         green on `EscrowGood`, invisible to a happy-path unit test on
///         `EscrowBuggy`, and violated the instant the bug executes.
contract EscrowInvariantTest is Test {
    EscrowGood internal escrow;
    EscrowHandler internal handler;

    address internal buyer = address(0xB0B);
    address internal seller = address(0x5E11E5);

    function setUp() public {
        escrow = new EscrowGood();
        handler = new EscrowHandler(IEscrow(address(escrow)));
        vm.deal(address(handler), 1_000 ether);
        targetContract(address(handler));
    }

    /// THE INVARIANT. This is the specification, made executable. Foundry will
    /// fire thousands of random deposit/release/refund sequences at the handler
    /// and assert this holds after every one.
    function invariant_solvency() public {
        assertEq(
            address(escrow).balance,
            escrow.totalEscrowed(),
            "SOLVENCY: ETH held must equal declared liabilities"
        );
    }

    // --- Deterministic demonstrations (also the green baseline) ---

    /// The correct implementation satisfies solvency after a full deposit->refund.
    function test_good_holdsSolvency() public {
        EscrowGood g = new EscrowGood();
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        g.deposit{value: 1 ether}(1, seller);
        assertEq(address(g).balance, g.totalEscrowed(), "solvent after deposit");

        vm.prank(seller);
        g.refund(1);
        assertEq(address(g).balance, g.totalEscrowed(), "solvent after refund (both zero)");
        assertEq(address(g).balance, 0, "ETH returned");
    }

    /// The trap: a unit test that only asks "did the buyer get refunded?" passes
    /// on the buggy contract. This is the false confidence invariants defeat.
    function test_buggy_passesNaiveHappyPathTest() public {
        EscrowBuggy b = new EscrowBuggy();
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        b.deposit{value: 1 ether}(1, seller);

        uint256 buyerBefore = buyer.balance;
        vm.prank(seller);
        b.refund(1);

        // Looks perfect. The buyer got their ETH back.
        assertEq(buyer.balance, buyerBefore + 1 ether, "buyer refunded");
    }

    /// The same buggy contract, judged by the solvency invariant instead: the
    /// books claim 1 ETH of liabilities while the contract holds nothing. This is
    /// the assertion the reader's invariant makes, and it fires immediately.
    function test_buggy_violatesSolvency() public {
        EscrowBuggy b = new EscrowBuggy();
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        b.deposit{value: 1 ether}(1, seller);

        vm.prank(seller);
        b.refund(1);

        assertEq(address(b).balance, 0, "all ETH has left the contract");
        assertEq(b.totalEscrowed(), 1 ether, "but the books still claim 1 ETH");
        assertTrue(
            address(b).balance != b.totalEscrowed(),
            "SOLVENCY VIOLATED: the invariant catches what the happy-path test missed"
        );
    }
}
