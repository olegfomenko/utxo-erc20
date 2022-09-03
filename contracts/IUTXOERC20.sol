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

    /// @notice Depositing ERC20 token to the contract. You should approve the transfer on token contract before.
    /// @param _token ERC20 token address to deposit
    /// @param _amount amount to deposit
    /// @param _version payload version
    /// @param _payload bytes array that contains amount and information to unlock that tokens
    function deposit(address _token, uint256 _amount, uint16 _version, bytes memory _payload) external returns (bool);

    /// @notice Withdraw ERC20 token from the contract balance.
    /// @param _to receiver address
    /// @param _utxo_id UTXO id to withdraw
    /// @param _payload bytes array that contains information to unlock that tokens. Should satisfy UTXO payload and its version.
    function withdraw(address _to, uint256 _utxo_id, bytes memory _payload) external returns (bool);

    /// @notice Transfer token from one UTXO to another
    /// @param _id UTXO id
    /// @param _payload bytes array that contains information to unlock that tokens. Should satisfy UTXO payload and its version.
    /// @param _outs OUT array that contains information about where to send tokens.
    function transfer(uint16 _id, bytes memory _payload, OUT[] memory _outs) external returns (bool);

    /// @notice Get UTXO by id
    /// @param _id UTXO id
    function getUTXO(uint256 _id) external view returns (UTXO memory);

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