// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAMM {
    event LiquidityAdded(address indexed token0, address indexed token1, uint256 amount0, uint256 amount1);
    event Swap(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    function addLiquidity(address token0, address token1, uint256 amt0, uint256 amt1) external;
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut);
}
