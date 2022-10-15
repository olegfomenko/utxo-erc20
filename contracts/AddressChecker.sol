pragma solidity ^0.8.0;

import "./IChecker.sol";

/**
 * @title UTXO ERC20 Spend conditions checker implementation
 * Address checker defines the following UTXO payload format: amount_32_bytes | address_20_bytes.
 * Only if message sender is equal to payload address utxo will be spent.
 */
contract AddressChecker is IChecker {
    uint8 public constant AMOUNT_BUF_SIZE = 32;
    uint8 public constant ADDRESS_BUF_SIZE = 20;

    uint8 public constant AMOUNT_STARTS = 0;
    uint8 public constant ADDRESS_STARTS = AMOUNT_BUF_SIZE;

    uint8 public constant FULL_SIZE = AMOUNT_BUF_SIZE + ADDRESS_BUF_SIZE;

    function check(bytes memory _utxoPayload, bytes memory _proofPayload, bytes[] memory) public pure override returns (bool) {
        return address(bytes20(_proofPayload)) == _getAddress(_utxoPayload);
    }

    function validateUTXO(uint256 _amount, bytes memory _utxoPayload) external pure override returns (bool){
        bytes[] memory _toValidate = new bytes[](1);
        _toValidate[0] = _utxoPayload;
        return validateUTXO(_amount, _toValidate);
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

        for (uint256 _i = 0; _i <  _payloads.length; _i++) {
            _sum = _sum + _getAmount(_payloads[_i]);
        }

        return _sum;
    }

    function _getSumAndValidate(bytes[] memory _payloads) internal pure returns (uint256, bool) {
        uint256 _sum = 0;

        for (uint256 _i = 0; _i < _payloads.length; _i++) {
            if(_getAddress(_payloads[_i]) == address(0) || _payloads[_i].length != FULL_SIZE) {
                return (0, false);
            }

            _sum = _sum + _getAmount(_payloads[_i]);
        }

        return (_sum, true);
    }


    function _getAddress(bytes memory _payload) internal pure returns (address) {
        return address(bytes20(_getSlice(_payload, ADDRESS_STARTS, ADDRESS_STARTS + ADDRESS_BUF_SIZE)));
    }

    function _getAmount(bytes memory _payload) internal pure returns (uint256) {
        return uint256(bytes32(_getSlice(_payload, AMOUNT_STARTS, AMOUNT_STARTS + AMOUNT_BUF_SIZE)));
    }

    function _getSlice(bytes memory _payload, uint _start, uint _length) internal pure returns (bytes memory) {
        bytes memory _result = new bytes(_length);
        for (uint _i = _start; _i < _start + _length && _i < _payload.length; _i++) {
            _result[_i - _start] = _payload[_i];
        }

        return _result;
    }
}
