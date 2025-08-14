// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {IBotRegistry} from "../interfaces/IBotRegistry.sol";
import {IValuationView} from "../interfaces/IValuationView.sol";

contract BuyAndHoldStrategy is IStrategy {
    IBotRegistry public immutable registry;
    IValuationView public immutable arena;

    constructor(IBotRegistry _registry, IValuationView _arena) {
        registry = _registry;
        arena = _arena;
    }

    function decide(uint256 botId)
        external
        view
        override
        returns (bool useTrade, address tokenIn, address tokenOut, uint256 amountIn)
    {
        // Only buy TokenA with QuoteToken at the start, then do nothing
        uint256 balQ = registry.balanceOfToken(botId, arena.quoteToken());
        if (balQ > 0) {
            tokenIn = arena.quoteToken();
            tokenOut = arena.tokenA();
            amountIn = balQ;
            return (true, tokenIn, tokenOut, amountIn);
        }

        return (false, address(0), address(0), 0);
    }
}
