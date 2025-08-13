// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStrategy {
    function decide(uint256 botId) external view returns (bool useTrade, address tokenIn, address tokenOut, uint256 amountIn);
}
