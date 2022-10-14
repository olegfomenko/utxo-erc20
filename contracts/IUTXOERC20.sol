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

    /// @notice Depositing ERC20 token to the contract. You should approve the transfer on token contract before.
    /// @param _token ERC20 token address to deposit
    /// @param _amount total amount to deposit
    /// @param _version payload version
    /// @param _payloads array of payloads that contains amount and information to unlock that tokens
    function deposit(address _token, uint256 _amount, uint16 _version, bytes[] memory _payloads) external;

    /// @notice Withdraw ERC20 token from the contract balance.
    /// @param _utxoId UTXO id to withdraw
    /// @param _payload bytes array that contains information to unlock that tokens. Should satisfy UTXO payload and its version.
    function withdraw(uint256 _amount, uint256 _utxoId, bytes memory _payload) external;

    /// @notice Transfer token from one UTXO to another
    /// @param _ids input UTXO id
    /// @param _payloads array that contains paylodas to unlock that tokens. Should satisfy corresponsing UTXO payload and its version.
    /// @param _outPayloads output UTXO paylods
    function transfer(uint256[] memory _ids, bytes[] memory _payloads,  bytes[] memory _outPayloads) external;

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
        uint256 amount
    );

    event Withdraw(
        address indexed token,
        address indexed to,
        uint256 amount
    );
}