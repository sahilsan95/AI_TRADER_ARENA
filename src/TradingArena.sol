// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import {IBotRegistry} from "./interfaces/IBotRegistry.sol";
import {ILeaderboard} from "./interfaces/ILeaderboard.sol";
import {IAMM} from "./interfaces/IAMM.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {ITradingArena} from "./interfaces/ITradingArena.sol";
import {IValuationView} from "./interfaces/IValuationView.sol";
import {Errors} from "./libraries/Errors.sol";

contract TradingArena is ITradingArena, IValuationView, Ownable2Step {
    using SafeERC20 for IERC20;

    IBotRegistry public immutable registry;
    ILeaderboard public immutable board;
    IAMM public immutable amm;

    address public override quoteToken;
    uint256 public minBlocksBetweenTrades = 1;
    uint256 public maxTradeBps = 2000;

    address public override tokenA;
    address public override tokenB;

    event QuoteTokenUpdated(address indexed oldQuoteToken, address indexed newQuoteToken);

    constructor(
        IBotRegistry _reg,
        ILeaderboard _board,
        IAMM _amm,
        address _quote
    ) Ownable(msg.sender) {
        registry = _reg;
        board = _board;
        amm = _amm;
        quoteToken = _quote;
    }

    /// --- New function to update quoteToken post-deployment
    function setQuoteToken(address _newQuoteToken) external onlyOwner {
        require(_newQuoteToken != address(0), "Invalid address");
        address old = quoteToken;
        quoteToken = _newQuoteToken;
        emit QuoteTokenUpdated(old, _newQuoteToken);
    }

    function ammAddress() external view override returns (address) {
        return address(amm);
    }

    function setLimits(uint256 blocksDelay, uint256 maxBps) external onlyOwner {
        minBlocksBetweenTrades = blocksDelay;
        maxTradeBps = maxBps;
    }

    function executeTrade(
        uint256 botId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public override {
        IBotRegistry.BotInfo memory info = registry.getBot(botId);
        require(block.number > info.lastTradeBlock + minBlocksBetweenTrades, Errors.TradeTooSoon);

        uint256 bal = registry.balanceOfToken(botId, tokenIn);
        uint256 maxAmt = (bal * maxTradeBps) / 10000;
        if (amountIn > maxAmt) amountIn = maxAmt;
        require(amountIn > 0, Errors.NothingToDo);

        registry.subBalanceFromArena(botId, tokenIn, amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(address(amm), amountIn);
        uint256 outAmt = amm.swap(tokenIn, tokenOut, amountIn);
        registry.addBalanceFromArena(botId, tokenOut, outAmt);

        emit TradeExecuted(botId, tokenIn, tokenOut, amountIn, outAmt);

        _updateValuationInternal(botId);
    }

    function tick(uint256 botId) external override {
        IBotRegistry.BotInfo memory info = registry.getBot(botId);
        require(info.strategy != address(0), "NO_STRATEGY");
        (bool doTrade, address tin, address tout, uint256 amt) = IStrategy(info.strategy).decide(botId);
        if (doTrade) executeTrade(botId, tin, tout, amt);
        else _updateValuationInternal(botId);
    }

    function tickMany(uint256[] calldata botIds) external override {
        for (uint256 i = 0; i < botIds.length; i++) {
            try this.tick(botIds[i]) {} catch {}
        }
    }

    function setValuationTokens(address _a, address _b) external onlyOwner {
        tokenA = _a;
        tokenB = _b;
    }

    function refreshValue(uint256 botId) external {
        _updateValuationInternal(botId);
    }

    function _updateValuationInternal(uint256 botId) internal {
        uint256 qa = registry.balanceOfToken(botId, tokenA);
        uint256 qb = registry.balanceOfToken(botId, tokenB);
        uint256 qq = registry.balanceOfToken(botId, quoteToken);

        uint256 quoteFromA = tokenA == quoteToken ? qa : (qa == 0 ? 0 : amm.getAmountOut(tokenA, quoteToken, qa));
        uint256 quoteFromB = tokenB == quoteToken ? qb : (qb == 0 ? 0 : amm.getAmountOut(tokenB, quoteToken, qb));
        uint256 total = qq + quoteFromA + quoteFromB;

        if (board.botValue(botId) == 0) {
            board.markInitial(botId, total);
            registry.setInitialValue(botId, uint96(total));
        } else {
            board.updateValue(botId, total);
        }
    }

    function initializeBot(uint256 botId, uint256 value) external onlyOwner {
        registry.setInitialValue(botId, uint96(value));
        board.markInitial(botId, value);
    }
}
