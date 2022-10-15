pragma solidity ^0.8.0;

import "./IChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/**
 * @title UTXO ERC20 Spend conditions checker implementation
 * Address checker defines the following UTXO payload format: amount_32_bytes | address_20_bytes | index_32_bytes.
 * Every address can have only one UTXO for certain index.
 * Proof payload contains the ECDSA signature of index and outs array.
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

    function check(bytes memory _utxoPayload, bytes memory _proofPayload, bytes[] memory _out) public pure override returns (bool) {
        if (_proofPayload.length == ADDRESS_BUF_SIZE) {
            return _getAddress(_utxoPayload) == address(bytes20(_proofPayload));
        }

        bytes memory _toHash = abi.encodePacked(_getIndex(_utxoPayload));
        for (uint _i = 0; _i < _out.length; _i++) {
            _toHash = abi.encodePacked(_toHash, _out[_i]);
        }
    
        return _getAddress(_utxoPayload) == keccak256(_toHash).toEthSignedMessageHash().recover(_getSignature(_proofPayload));
    }

    function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external override returns (bool){
        bytes[] memory _toValidate = new bytes[](1);
        _toValidate[0] = _utxoPayload;
        return validateUTXO(_amount, _toValidate);
    }

    function validateUTXO(uint256 _amount, bytes[] memory _payloads) public override returns (bool){
        (uint256 _sum, bool _validated) = _getSumAndValidate(_payloads);
        return _validated && _sum == _amount;
    }

    function validateTransfer(bytes[] memory _in, bytes[] memory _out) public override returns (bool) {
        uint256 _sumIn  = _getSum(_in);
        return validateUTXO(_sumIn, _out);
    }

    function _getSum(bytes[] memory _payloads) internal pure returns (uint256) {
        uint256 _sum = 0;

        for (uint256 _i = 0; _i <  _payloads.length; _i++) {
            _sum = _sum + _getAmount(_payloads[_i]);
        }

        return _sum;
    }

    function _getSumAndValidate(bytes[] memory _payloads) internal returns (uint256, bool) {
        uint256 _sum = 0;

        for (uint256 _i = 0; _i < _payloads.length; _i++) {
            if(_getAddress(_payloads[_i]) == address(0) || _payloads[_i].length != FULL_SIZE) {
                return (0, false);
            }

            address _addr = _getAddress(_payloads[_i]);
            uint256 _index = _getIndex(_payloads[_i]);

            if (used[_addr][_index]) {
                return (0, false);
            }

            used[_addr][_index] = true;
            _sum = _sum + _getAmount(_payloads[_i]);
        }

        return (_sum, true);
    }

    function _getIndex(bytes memory _payload) internal pure returns (uint256) {
        return uint256(bytes32(_getSlice(_payload, ID_STARTS, ID_STARTS + ID_BUF_SIZE)));
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
        for (uint _i = _start; _i < _start + _length && _i < _payload.length; _i++) {
            _result[_i - _start] = _payload[_i];
        }

        return _result;
    }
}
