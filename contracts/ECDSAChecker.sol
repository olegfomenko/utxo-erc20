pragma solidity ^0.8.0;

import "./IChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/**
 * @title UTXO ERC20 Spend conditions checker implementation
 * Address checker defines the following UTXO payload format: amount_32_bytes | address_20_bytes | index_32_bytes.
 * Every address can have only one UTXO for certain index.
 * Proof payload contains the ECDSA signature of index value.
 * Only if recovered address or message sender is equal to payload address utxo will be spent.
 */
contract ECDSAChecker is IChecker {
    using ECDSA for bytes32;

    uint8 public constant ID_BUF_SIZE = 32;
    uint8 public constant AMOUNT_BUF_SIZE = 32;
    uint8 public constant ADDRESS_BUF_SIZE = 20;

    uint8 public constant AMOUNT_STARTS = 0;
    uint8 public constant ADDRESS_STARTS = AMOUNT_BUF_SIZE;
    uint8 public constant ID_STARTS = AMOUNT_BUF_SIZE + ADDRESS_BUF_SIZE;

    uint8 public constant FULL_SIZE = ID_BUF_SIZE + AMOUNT_BUF_SIZE + ADDRESS_BUF_SIZE;

    uint8 public constant SIGNATURE_BUF_SIZE = 65;
    uint8 public constant SIGNATURE_STARTS = ADDRESS_BUF_SIZE;

    mapping(address => mapping(uint256 => bool)) public used;

    function check(bytes memory _utxoPayload, bytes memory _proofPayload) public pure override returns (bool) {
        bytes32 _id = _getIndex(_utxoPayload);

        if (_proofPayload.length == ADDRESS_BUF_SIZE) {
            return _getAddress(_utxoPayload) == address(bytes20(_proofPayload));
        }

        address _signer = _id.toEthSignedMessageHash().recover(_getSignature(_proofPayload));
        return _getAddress(_utxoPayload) == _signer;
    }

     function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external pure override returns (bool){
        bytes[] memory toValidate = new bytes[](1);
        toValidate[0] = _utxoPayload;
        return validateUTXO(_amount, toValidate);
    }

    function validateUTXO(uint256 _amount, bytes[] memory _payloads) public pure override returns (bool){
        (uint256 _sum, bool _validated) = _getSumAndValidate(_payloads);
        return _validated && _sum == _amount;
    }

    function validateTransfer(bytes[] memory _in, bytes[] memory _out) public pure override returns (bool) {
        uint256 _sumIn  = _getSum(_in);
        return validateUTXO(_sumIn, _out);
    }

    function _getSum(bytes[] memory _payloads) internal pure returns (uint256) {
        uint256 _sum = 0;

        for (uint256 i = 0; i <  _payloads.length; i++) {
            _sum = _sum + _getAmount(_payloads[i]);
        }

        return _sum;
    }

    function _getSumAndValidate(bytes[] memory _payloads) internal pure returns (uint256, bool) {
        uint256 _sum = 0;

        for (uint256 i = 0; i <  _payloads.length; i++) {
            _sum = _sum + _getAmount(_payloads[i]);
            if(_getAddress(_payloads[i]) == address(0) || _payloads[i].length != FULL_SIZE) {
                return (0, false);
            }

        }

        return (_sum, true);
    }

    function _getIndex(bytes memory _payload) internal pure returns (bytes32) {
        return bytes32(_getSlice(_payload, ID_STARTS, ID_STARTS + ID_BUF_SIZE));
    }

    function _getAddress(bytes memory _payload) internal pure returns (address) {
        return address(bytes20(_getSlice(_payload, ADDRESS_STARTS, ADDRESS_STARTS + ADDRESS_BUF_SIZE)));
    }

    function _getAmount(bytes memory _payload) internal pure returns (uint256) {
        return uint256(bytes32(_getSlice(_payload, AMOUNT_STARTS, AMOUNT_STARTS + AMOUNT_BUF_SIZE)));
    }

    function _getSignature(bytes memory _payload) internal pure returns (bytes memory) {
        return _getSlice(_payload, SIGNATURE_STARTS, SIGNATURE_STARTS + SIGNATURE_BUF_SIZE);
    }

    function _getSlice(bytes memory _payload, uint _start, uint _length) internal pure returns (bytes memory) {
        bytes memory _result = new bytes(_length);
        for (uint i = _start; i < _start + _length && i < _payload.length; i++) {
            _result[i - _start] = _payload[i];
        }

        return _result;
    }
}
