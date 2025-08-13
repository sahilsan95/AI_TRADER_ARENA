// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IValuationView {
    function tokenA() external view returns (address);
    function tokenB() external view returns (address);
    function quoteToken() external view returns (address);
    /// renamed to avoid name clash with `iam` state variable in TradingArena
    function ammAddress() external view returns (address);
}
