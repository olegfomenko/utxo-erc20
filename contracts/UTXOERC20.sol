pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUTXOERC20.sol";
import "./IChecker.sol";

contract UTXOERC20 is IUTXOERC20, Ownable {
    UTXO[] public utxos;
    mapping (uint16 => address) public checkers;

    function deposit(address _token, uint256 _amount, uint16 _version, bytes[] memory _payloads) public override {
        require(checkers[_version] != address(0), "unsupported version");
        require(IChecker(checkers[_version]).validateUTXO(_amount, _payloads), "invalid UTXO");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        for (uint i = 0; i < _payloads.length; i++) {
            UTXO memory _utxo = UTXO(_token, _version, _payloads[i], false);
            utxos.push(_utxo);
            emit UTXOCreated(utxos.length - 1, msg.sender);
        }

        emit Deposit(_token, msg.sender, _amount);
    }

    function withdraw(uint256 _amount, uint256 _utxoId, bytes memory _payload) public override {
        require(_utxoId < utxos.length, "UTXO id out of bound");

        UTXO memory _utxo = utxos[_utxoId];
        require(!_utxo._spent, "UTXO has been spent");
        require(IChecker(checkers[_utxo._version]).validateUTXO(_amount, _utxo._payload), "invalid UTXO");

        bytes memory _payloadWithSender = bytes.concat(abi.encodePacked(msg.sender), _payload);
        require(IChecker(checkers[_utxo._version]).check(_utxo._payload, _payloadWithSender), "UTXO conditions is not satisfied");

        utxos[_utxoId]._spent = true;
        IERC20(_utxo._token).transfer(msg.sender, _amount);

        emit UTXOSpent(_utxoId, msg.sender);
        emit Withdraw(_utxo._token, msg.sender, _amount);
    }

    function transfer(uint256[] memory _ids, bytes[] memory _payloads, bytes[] memory _out) public override {
        require(_out.length != 0, "invalid out: can not be empty");
        require(_ids.length != 0, "invalid in: can not be empty");
        require(_ids.length == _payloads.length, "every input utxo should have payload to allow spending");


        bytes[] memory _in = new bytes[](_ids.length);
        uint16 _version = utxos[_ids[0]]._version;
        address _token = utxos[_ids[0]]._token;

        for(uint _i = 0; _i < _ids.length; _i++) {
            require(_ids[_i] < utxos.length, "UTXO id out of bound");
            UTXO memory _utxo = utxos[_ids[_i]];
            require(!_utxo._spent, "UTXO has been spent");
            require(_utxo._version == _version, "all UTXO should have the same version");

            _in[_i] = _utxo._payload;

            bytes memory _payloadWithSender = bytes.concat(abi.encodePacked(msg.sender), _payloads[_i]);
            require(IChecker(checkers[_utxo._version]).check(_utxo._payload, _payloadWithSender), "UTXO conditions is not satisfied");

            utxos[_ids[_i]]._spent = true;
            emit UTXOSpent(_ids[_i], msg.sender);
        }

        require(IChecker(checkers[_version]).validateTransfer(_in, _out), "invalide in-out paylods");

        uint256 _utxoSz = utxos.length;
        for (uint _i = 0; _i < _out.length; _i++) {
            UTXO memory _newUtxo = UTXO(_token, _version, _out[_i], false);
            utxos.push(_newUtxo);
            emit UTXOCreated(_utxoSz, msg.sender);
            _utxoSz += 1;
        }
    }

    function getUTXO(uint256 _id) public override view returns (UTXO memory) {
        require(_id < utxos.length, "UTXO id out of bound");
        return utxos[_id];
    }

    function setVersion(uint16 _id, address _checker) public onlyOwner {
        checkers[_id] = _checker;
    }

    function version(uint16 _id) public view returns (address) {
        return checkers[_id];
    }
}
