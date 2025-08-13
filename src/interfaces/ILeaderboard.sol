// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILeaderboard {
    event ScoreUpdated(uint256 indexed botId, uint256 value, int256 roiBps);

    function setQuoteToken(address token) external;
    function markInitial(uint256 botId, uint256 initialQuoteValue) external;
    function updateValue(uint256 botId, uint256 newQuoteValue) external;

    function botValue(uint256 botId) external view returns (uint256);
    function roiBpsOf(uint256 botId) external view returns (int256);
}
