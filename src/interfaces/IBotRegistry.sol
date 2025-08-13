// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBotRegistry {
    struct BotInfo {
        address owner;
        address strategy;
        uint64  createdAt;
        uint64  lastTradeBlock;
        uint96  initialValue;
        string  metadataURI;
    }

    event BotCreated(uint256 indexed botId, address indexed owner, address strategy, string uri);
    event StrategyUpdated(uint256 indexed botId, address indexed oldStrategy, address indexed newStrategy);
    event Deposit(uint256 indexed botId, address indexed token, uint256 amount);
    event Withdraw(uint256 indexed botId, address indexed token, uint256 amount);

    function mintBot(address to, address strategy, string calldata uri) external returns (uint256);
    function setStrategy(uint256 botId, address strategy) external;
    function getBot(uint256 botId) external view returns (BotInfo memory);
    function ownerOf(uint256 botId) external view returns (address);

    // balances
    function deposit(uint256 botId, address token, uint256 amount) external;
    function withdraw(uint256 botId, address token, uint256 amount) external;
    function balanceOfToken(uint256 botId, address token) external view returns (uint256);

    // arena-only hooks
    function addBalanceFromArena(uint256 botId, address token, uint256 amount) external;
    function subBalanceFromArena(uint256 botId, address token, uint256 amount) external;

    function arena() external view returns (address);
    function setInitialValue(uint256 botId, uint96 value) external;
}
