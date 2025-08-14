// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {IBotRegistry} from "../interfaces/IBotRegistry.sol";
import {IValuationView} from "../interfaces/IValuationView.sol";

interface IAMMView {
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);
}

contract MeanReversionStrategy is IStrategy {
    IBotRegistry public immutable registry;
    IValuationView public immutable arena;

    uint256 public movingAvgX18; // store moving average price
    uint256 public tradeBps = 2000; // 20% of holdings

    constructor(IBotRegistry _registry, IValuationView _arena) {
        registry = _registry;
        arena = _arena;
    }

    function setTradeBps(uint256 bps) external {
        require(bps <= 5000, "MAX_50%");
        tradeBps = bps;
    }

    function _spotPriceX18() internal view returns (uint256) {
        address a = arena.tokenA();
        address b = arena.tokenB();
        uint256 out = IAMMView(arena.ammAddress()).getAmountOut(a, b, 1e18);
        if (out == 0) out = 1;
        return out;
    }

    function decide(uint256 botId)
        external
        view
        override
        returns (bool useTrade, address tokenIn, address tokenOut, uint256 amountIn)
    {
        address a = arena.tokenA();
        address b = arena.tokenB();
        address q = arena.quoteToken();

        uint256 px = _spotPriceX18();

        // Mean reversion logic: if price > moving average, sell; if below, buy
        bool priceHigh = px > movingAvgX18 && movingAvgX18 != 0;

        uint256 balA = registry.balanceOfToken(botId, a);
        uint256 balB = registry.balanceOfToken(botId, b);

        if (priceHigh) {
            // Sell A → B
            tokenIn = a;
            tokenOut = b;
            amountIn = (balA * tradeBps) / 10000;
        } else {
            // Buy A ← B
            tokenIn = b;
            tokenOut = a;
            amountIn = (balB * tradeBps) / 10000;
        }

        // Fallback: if both are empty, buy with quote
        if (amountIn == 0) {
            uint256 balQ = registry.balanceOfToken(botId, q);
            if (balQ > 0) {
                tokenIn = q;
                tokenOut = a;
                amountIn = (balQ * tradeBps) / 10000;
            }
        }

        useTrade = amountIn > 0;
    }
}
