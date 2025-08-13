// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITradingArena {
    event TradeExecuted(
        uint256 indexed botId,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    function executeTrade(
        uint256 botId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external;

    function tick(uint256 botId) external;
    function tickMany(uint256[] calldata botIds) external;
}
