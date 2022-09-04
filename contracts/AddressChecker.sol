pragma solidity ^0.8.0;

import "./IChecker.sol";

contract AddressChecker is IChecker {
    uint public constant AMOUNT_BUF_SIZE = 32;
    uint public constant ADDRESS_BUF_SIZE = 20;

    function check(address _caller, bytes memory _utxoPayload, bytes memory /*_proofPayload*/) public pure override {
        require(_caller == address(bytes20(_getSlice(_utxoPayload, AMOUNT_BUF_SIZE, _utxoPayload.length))), "UTXO conditions is not satisfied");
    }

     function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external pure override {
        bytes[] memory toValidate = new bytes[](1);
        toValidate[0] = _utxoPayload;
        validateUTXOs(_amount, toValidate);
    }

    function validateUTXOs(uint256 _amount, bytes[] memory _utxoPayloads) public pure override {
        uint256 sum = 0;
        for (uint i = 0; i < _utxoPayloads.length; i++){
            require(_utxoPayloads[i].length == AMOUNT_BUF_SIZE + ADDRESS_BUF_SIZE, "invalid payload size");
            require(address(bytes20(_getSlice(_utxoPayloads[i], AMOUNT_BUF_SIZE, _utxoPayloads[i].length))) != address(0), "invalid address");
            sum = sum + uint256(bytes32(_getSlice(_utxoPayloads[i], 0, AMOUNT_BUF_SIZE)));
        }

        require(sum == _amount, "invalid amount");
    }

    function validateTransfer(bytes memory _utxoPayload, bytes[] memory _payloads) public pure override {
        uint256 sum = 0;
        for (uint i = 0; i < _payloads.length; i++) {
            sum = sum + uint256(bytes32(_getSlice(_payloads[i], 0, AMOUNT_BUF_SIZE)));
        }
        require(sum == uint256(bytes32(_getSlice(_utxoPayload, 0, AMOUNT_BUF_SIZE))), "invalid payload amount sum");
    }

    function _getSlice(bytes memory _payload, uint _start, uint _end) internal pure returns (bytes memory) {
        require(_start < _payload.length && _end <= _payload.length && _start < _end, "invalid indexes");
        bytes memory result = new bytes(_end - _start);

        for (uint i = _start; i < _end; i++) {
            result[i - _start] = _payload[i];
        }

        return result;
    }
}
