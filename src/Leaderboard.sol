// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ILeaderboard} from "./interfaces/ILeaderboard.sol";
import {Errors} from "./libraries/Errors.sol";

contract Leaderboard is ILeaderboard, Ownable2Step {
    address public quoteToken;
    mapping(uint256 => uint256) public initial;
    mapping(uint256 => uint256) public value;
    mapping(uint256 => int256)  public roiBps;
    address public arena;

    modifier onlyArena() {
        require(msg.sender == arena, Errors.NotArena);
        _;
    }

    constructor() Ownable(msg.sender)  {
        
    }

    function setArena(address a) external onlyOwner {
        arena = a;
    }

    function setQuoteToken(address token) external override onlyOwner {
        quoteToken = token;
    }

    function markInitial(uint256 botId, uint256 initialQuoteValue) external override onlyArena {
        if (initial[botId] == 0) {
            initial[botId] = initialQuoteValue;
        }
        value[botId] = initialQuoteValue;
        roiBps[botId] = 0;
        emit ScoreUpdated(botId, initialQuoteValue, 0);
    }

    function updateValue(uint256 botId, uint256 newQuoteValue) external override onlyArena {
        value[botId] = newQuoteValue;
        int256 init = int256(uint256(initial[botId] == 0 ? 1 : initial[botId]));
        int256 roi = int256(int256(int256(newQuoteValue) * 10000) / init) - 10000;
        roiBps[botId] = roi;
        emit ScoreUpdated(botId, newQuoteValue, roi);
    }

    function botValue(uint256 botId) external view override returns (uint256) { return value[botId]; }
    function roiBpsOf(uint256 botId) external view override returns (int256) { return roiBps[botId]; }
}
