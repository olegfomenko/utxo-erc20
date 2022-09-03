pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IUTXOERC20.sol";

contract UTXOERC20 is IUTXOERC20 {
    UTXO[] utxos;

    mapping (uint16 => bool) supportedVersions;

    uint16 public constant VERSION_0 = 0;
    uint public constant AMOUNT_BUF_SIZE = 32;
    uint public constant ADDRESS_BUF_SIZE = 20;

    constructor() public {
        supportedVersions[VERSION_0] = true;
    }

    function deposit(address _token, uint256 _amount, uint16 _version, bytes memory _payload) external override {
        require(supportedVersions[_version], "unsupported version");
        if (_version == VERSION_0) {
            require(_payload.length == AMOUNT_BUF_SIZE + ADDRESS_BUF_SIZE, "invalid payload for version 0");
            require(uint256(bytes32(_getSlice(_payload, 0, AMOUNT_BUF_SIZE))) == _amount, "invalid amount");
            require(address(bytes20(_getSlice(_payload, AMOUNT_BUF_SIZE, ADDRESS_BUF_SIZE))) != address(0), "invalid address");
        }

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        UTXO memory utxo = UTXO(_token, _version, _payload, false);
        utxos.push(utxo);

        emit UTXOCreated(utxos.length - 1, msg.sender);
        emit Deposit(_token, msg.sender, utxos.length - 1, _amount);
    }

    function withdraw(address _to, uint256 _utxoId, bytes memory _payload) external override {
        require(_utxoId < utxos.length, "UTXO id out of bound");

        UTXO memory utxo = utxos[_utxoId];
        require(!utxo._spent, "UTXO has been spent");

        if (utxo._version == VERSION_0) {
            bytes32 message = keccak256(abi.encodePacked(_utxoId, _to));
            require(_recoverAddress(message, _payload) == address(bytes20(_getSlice(utxo._payload, AMOUNT_BUF_SIZE, ADDRESS_BUF_SIZE))), "payload does not satisfy UTXO conditions");

            uint256 _amount = uint256(bytes32(_getSlice(_payload, 0, AMOUNT_BUF_SIZE)));

            utxos[_utxoId]._spent = true;
            IERC20(utxo._token).transfer(_to, _amount);

            emit UTXOSpent(_utxoId, msg.sender);
            emit Withdraw(utxo._token, _to, _utxoId, _amount);
        }
    }

    function transfer(uint16 _id, bytes memory _payload, OUT[] memory _outs) external override {
        require(_id < utxos.length, "UTXO id out of bound");
        require(_outs.length != 0, "invalid outs: can not be empty");

        UTXO memory utxo = utxos[_id];
        require(!utxo._spent, "UTXO has been spent");

        if (utxo._version == VERSION_0) {
            bytes memory rawMessage = abi.encodePacked(_id);
            for (uint i = 0; i < _outs.length; i++) {
                rawMessage = abi.encodePacked(rawMessage, _outs[i]._payload);
            }

            bytes32 message = keccak256(rawMessage);
            require(_recoverAddress(message, _payload) == address(bytes20(_getSlice(utxo._payload, AMOUNT_BUF_SIZE, ADDRESS_BUF_SIZE))), "payload does not satisfy UTXO conditions");

            utxos[_id]._spent = true;
            emit UTXOSpent(_id, msg.sender);

            for (uint i = 0; i < _outs.length; i++) {
                UTXO memory newUtxo = UTXO(utxo._token, utxo._version, _payload, false);
                utxos.push(newUtxo);
                emit UTXOCreated(utxos.length - 1, msg.sender);
            }
        }
    }

    function getUTXO(uint256 _id) external override view returns (UTXO memory) {
        require(_id < utxos.length, "UTXO id out of bound");
        return utxos[_id];
    }

    function _recoverAddress(
        bytes32 message,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length != 65) {
            revert("invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return _getSigner(message, v, r, s);
    }

    function _getSigner(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");
        require(v == 27 || v == 28, "invalid signature 'v' value");

        address signer = ecrecover(message, v, r, s);
        require(signer != address(0), "invalid signature");

        return signer;
    }

    function _getSlice(bytes memory _payload, uint _start, uint _end) internal pure returns (bytes memory) {
        require(_start < _payload.length && _end < _payload.length && _start < _end, "invalid indexes");
        bytes memory result = new bytes(_end - _start);

        for (uint i = _start; i < _end; i++) {
            result[i - _start] = _payload[i];
        }

        return result;
    }
}
