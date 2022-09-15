pragma solidity ^0.8.0;

import "./IChecker.sol";

contract AddressChecker is IChecker {
    uint8 public constant AMOUNT_BUF_SIZE = 32;
    uint8 public constant ADDRESS_BUF_SIZE = 20;

    function check(address _caller, bytes memory _utxoPayload, bytes memory /*_proofPayload*/) public pure override returns (bool) {
        return _caller == _bytesToAddress(_utxoPayload);
    }

     function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external pure override returns (bool){
        bytes[] memory toValidate = new bytes[](1);
        toValidate[0] = _utxoPayload;
        return validateUTXO(_amount, toValidate);
    }

    function validateUTXO(uint256 _amount, bytes[] memory _utxoPayloads) public pure override returns (bool){
        uint256 _sum = 0;
        for (uint i = 0; i < _utxoPayloads.length; i++){
            if (_utxoPayloads[i].length != AMOUNT_BUF_SIZE + ADDRESS_BUF_SIZE) {
                return false;
            }

            if (_bytesToAddress(_utxoPayloads[i]) == address(0)) {
                return false;
            }

            _sum = _sum + _bytesToUint256(_utxoPayloads[i]);
        }

        return _sum == _amount;
    }

    function validateTransfer(bytes memory _utxoPayload, bytes[] memory _payloads) public pure override returns (bool) {
        uint256 _sum = 0;
        for (uint i = 0; i < _payloads.length; i++) {
            _sum = _sum + _bytesToUint256(_payloads[i]);
            if(_bytesToAddress(_payloads[i]) == address(0)) {
                return false;
            }
        }
        return _sum == uint256(bytes32(_getSlice(_utxoPayload, 0, AMOUNT_BUF_SIZE)));
    }

    function _bytesToAddress(bytes memory _payload) internal pure returns (address) {
        return address(bytes20(_getSlice(_payload, AMOUNT_BUF_SIZE, ADDRESS_BUF_SIZE)));
    }

    function _bytesToUint256(bytes memory _payload) internal pure returns (uint256) {
        return uint256(bytes32(_getSlice(_payload, 0, AMOUNT_BUF_SIZE)));
    }

    function _getSlice(bytes memory _payload, uint _start, uint _length) internal pure returns (bytes memory) {
        bytes memory _result = new bytes(_length);
        for (uint i = _start; i < _start + _length && i < _payload.length; i++) {
            _result[i - _start] = _payload[i];
        }

        return _result;
    }
}
