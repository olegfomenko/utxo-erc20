pragma solidity ^0.8.0;

/**
 * @title UTXO-ERC20 interface
 */
interface IUTXOERC20 {

    struct UTXO {
        address _token;
        uint16 _version;
        bytes _payload;
        bool _spent;
    }

    struct OUT {
        uint16 _version;
        bytes _payload;
    }

    function deposit(address _token, uint256 _amount, uint16 _version, bytes memory _payload) external returns (bool);

    function withdraw(address _to, uint256 _utxo_id, bytes memory _payload) external returns (bool);

    function transfer(uint16 _id, bytes memory _payload, OUT[] memory _outs) external returns (bool);

    function getUTXO(uint256 _utxo_id) external view returns (UTXO memory);

    event UTXOCreated(
        uint256 indexed id,
        address indexed creator
    );

    event UTXOSpent(
        uint256 indexed id,
        address indexed spender
    );

    event Deposit(
        address indexed token,
        address indexed from,
        uint256 indexed utxo_id,
        uint256 amount
    );

    event Withdraw(
        address indexed token,
        address indexed to,
        uint256 indexed utxo_id,
        uint256 amount
    );
}