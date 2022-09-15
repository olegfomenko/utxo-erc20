# UTXO ERC20 contract

---
    author: Oleg Fomenko, Oleksandr Kurbatov from Distributed Lab 
    date: 15 Sep 2022 
---

## [Main contract](../contracts/IUTXOERC20.sol)

The UTXO ERC20 contract intended to be universal contact for all types of UTXO.
We decided to follow the most flexible schema,
where we are storing the UTXO data in next format: **<token_address,version,payload,is_spent>**.

In the payload we can store any information about amounts and spending requirements.
Because we are using bytes array for payload, the data can be stored clear or encrypted, depending on UTXO's version.

We also defined the another one data struct that holds transfer outputs and spawn new UTXOs: **<version,payload>**

Also, there are the following events defined and emitted by contract operations:

```solidity
// Emitted when new UTXO created
event UTXOCreated(uint256 indexed id, address indexed creator);

// Emitted when UTXO is marked as 'spent' (during transfer or withdraw)
event UTXOSpent(uint256 indexed id, address indexed spender);

// Emitted when contract receives the new deposit
event Deposit(address indexed token, address indexed from, uint256 amount);

// Emitted when contract withdraws tokens and spend UTXO
event Withdraw(address indexed token, address indexed to, uint256 amount);
```

The version parameter in UTXO is responsible for defining what type of payload we UTXO is using. 
Contract implementation manages the versions and the corresponding [Checker contract](../contracts/IChecker.sol), 
that will validate UTXO while deposit, transfer and withdrawal operations.  

## [Checker](../contracts/IChecker.sol)

Checker contract defines the certain version UTXO payload meaning. 
It is responsible for payload validation and payload requirements check before spending. 

Currently, only [Address Checker](../contracts/AddressChecker.sol) is available.
That checker encodes amount and address bytes in payload as it is. 
The check method will return __true__ only if msg.sender is equal to stored address in payload.  