pragma solidity ^0.8.0;

/**
 * @title UTXO ERC20 Spend conditions checker interface
 */
interface IChecker {
    /// @notice Depositing ERC20 token to the contract. You should approve the transfer on token contract before.
    /// @param _utxoPayload payload stored on UTXO
    /// @param _proofPayload concatenation msg.sender || payload sent by caller
    function check(bytes memory _utxoPayload, bytes memory _proofPayload) external pure returns (bool);

    /// @notice Validate UTXO deposit payload
    /// @param _amount deposit amount
    /// @param _utxoPayload payload to create UTXOs with
    function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external pure returns (bool);

    /// @notice Validate UTXO deposit payloads
    /// @param _amount toltal deposit amount
    /// @param _utxoPayloads list of payloads to create UTXOs with
    function validateUTXO(uint256 _amount, bytes[] memory _utxoPayloads) external pure returns (bool);

    /// @notice Validate token transfer OUTs' payloads.
    /// @param _in UTXO payload
    /// @param _out OUTs' paloads
    function validateTransfer(bytes[] memory _in, bytes[] memory _out) external pure returns (bool);
}