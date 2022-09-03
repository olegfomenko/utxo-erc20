pragma solidity ^0.8.0;

/**
 * @title UTXO ERC20 Spend conditions checker interface
 */
interface IChecker {
    /// @notice Depositing ERC20 token to the contract. You should approve the transfer on token contract before.
    /// @param _caller who wants to spend tokens
    /// @param _utxoPayload payload stored on UTXO
    /// @param _proofPayload payload sent by caller
    function check(address _caller, bytes memory _utxoPayload, bytes memory _proofPayload) external pure;

    /// @notice Validate token deposit payload.
    /// @param _amount deposit ERC20 token amount
    /// @param _utxoPayload deposit UTXO payload
    function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external pure;

    /// @notice Validate token transfer OUTs' payloads.
    /// @param _utxoPayload UTXO payload
    /// @param _payloads OUTs' paloads
    function validateTransfer(bytes memory _utxoPayload, bytes[] memory _payloads) external pure ;
}