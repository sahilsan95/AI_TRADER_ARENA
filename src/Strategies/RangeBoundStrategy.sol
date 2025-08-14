// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {IBotRegistry} from "../interfaces/IBotRegistry.sol";
import {IValuationView} from "../interfaces/IValuationView.sol";

interface IAMMView {
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);
}

contract RangeBoundStrategy is IStrategy {
    IBotRegistry public immutable registry;
    IValuationView public immutable arena;

    uint256 public lowerPxX18;
    uint256 public upperPxX18;
    uint256 public tradeBps = 2000;

    constructor(IBotRegistry _registry, IValuationView _arena, uint256 _lower, uint256 _upper) {
        registry = _registry;
        arena = _arena;
        lowerPxX18 = _lower;
        upperPxX18 = _upper;
    }

    function _spotPriceX18() internal view returns (uint256) {
        uint256 out = IAMMView(arena.ammAddress()).getAmountOut(arena.tokenA(), arena.tokenB(), 1e18);
        return out == 0 ? 1 : out;
    }

    function decide(uint256 botId)
        external
        view
        override
        returns (bool useTrade, address tokenIn, address tokenOut, uint256 amountIn)
    {
        uint256 px = _spotPriceX18();

        uint256 balA = registry.balanceOfToken(botId, arena.tokenA());
        uint256 balB = registry.balanceOfToken(botId, arena.tokenB());

        if (px <= lowerPxX18) {
            tokenIn = arena.tokenB();
            tokenOut = arena.tokenA();
            amountIn = (balB * tradeBps) / 1e4;
        } else if (px >= upperPxX18) {
            tokenIn = arena.tokenA();
            tokenOut = arena.tokenB();
            amountIn = (balA * tradeBps) / 1e4;
        }

        useTrade = amountIn > 0;
    }
}
