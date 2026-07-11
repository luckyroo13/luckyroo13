// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IEscrow — the spec, expressed as an interface.
/// @notice A minimal two-party escrow. A buyer deposits ETH against a deal id
///         naming a seller. The buyer may `release` the funds to the seller, or
///         the seller may `refund` them to the buyer. Each deal resolves once.
///
/// @dev The interface is the easy part — an agent writes it in seconds. The
///      *specification that matters* is the invariant that no correct
///      implementation may ever break:
///
///        SOLVENCY:  address(escrow).balance == escrow.totalEscrowed()
///
///      i.e. the contract's declared liabilities always equal the ETH it
///      actually holds. Chapter 3 is about writing that property down and making
///      it the acceptance test the agent's code has to pass.
interface IEscrow {
    function deposit(uint256 dealId, address seller) external payable;
    function release(uint256 dealId) external;
    function refund(uint256 dealId) external;

    function totalEscrowed() external view returns (uint256);
    function amountOf(uint256 dealId) external view returns (uint256);
    function buyerOf(uint256 dealId) external view returns (address);
    function sellerOf(uint256 dealId) external view returns (address);
}
