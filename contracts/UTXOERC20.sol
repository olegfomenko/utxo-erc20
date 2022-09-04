pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUTXOERC20.sol";
import "./IChecker.sol";

contract UTXOERC20 is IUTXOERC20, Ownable {
    UTXO[] public utxos;
    mapping (uint16 => address) public checkers;

    constructor() public {}

    function deposit(address _token, uint256 _amount, uint16 _version, bytes[] memory _payloads) public override {
        require(checkers[_version] != address(0), "unsupported version");

        IChecker(checkers[_version]).validateUTXOs(_amount, _payloads);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        for (uint i = 0; i < _payloads.length; i++) {
            UTXO memory utxo = UTXO(_token, _version, _payloads[i], false);
            utxos.push(utxo);
            emit UTXOCreated(utxos.length - 1, msg.sender);
        }

        emit Deposit(_token, msg.sender, _amount);
    }

    function withdraw(uint256 _amount, uint256 _utxoId, bytes memory _payload) public override {
        require(_utxoId < utxos.length, "UTXO id out of bound");

        UTXO memory utxo = utxos[_utxoId];
        require(!utxo._spent, "UTXO has been spent");

        IChecker(checkers[utxo._version]).validateUTXO(_amount, utxo._payload);
        IChecker(checkers[utxo._version]).check(msg.sender, utxo._payload, _payload);

        utxos[_utxoId]._spent = true;
        IERC20(utxo._token).transfer(msg.sender, _amount);

        emit UTXOSpent(_utxoId, msg.sender);
        emit Withdraw(utxo._token, msg.sender, _amount);
    }

    function transfer(uint16 _id, bytes memory _payload, OUT[] memory _outs) public override {
        require(_id < utxos.length, "UTXO id out of bound");
        require(_outs.length != 0, "invalid outs: can not be empty");

        UTXO memory utxo = utxos[_id];
        require(!utxo._spent, "UTXO has been spent");

        IChecker(checkers[utxo._version]).check(msg.sender, utxo._payload, _payload);

        bytes[] memory _payloads = new bytes[](_outs.length);
        for (uint i = 0; i < _outs.length; i++) {
            require(_outs[i]._version == utxo._version, "invalide OUT version");
            _payloads[i] = _outs[i]._payload;
        }

        IChecker(checkers[utxo._version]).validateTransfer(utxo._payload, _payloads);

        utxos[_id]._spent = true;
        emit UTXOSpent(_id, msg.sender);

        for (uint i = 0; i < _outs.length; i++) {
            UTXO memory newUtxo = UTXO(utxo._token, utxo._version, _outs[i]._payload, false);
            utxos.push(newUtxo);
            emit UTXOCreated(utxos.length - 1, msg.sender);
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
