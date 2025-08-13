// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAMM} from "./interfaces/IAMM.sol";

contract AMMMock is IAMM, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => uint256)) public reserves;

    constructor() Ownable(msg.sender) {}

    function addLiquidity(address token0, address token1, uint256 amt0, uint256 amt1) external override {
        require(token0 != token1 && token0 != address(0) && token1 != address(0), "BAD_PAIR");
        IERC20(token0).transferFrom(msg.sender, address(this), amt0);
        IERC20(token1).transferFrom(msg.sender, address(this), amt1);

        reserves[token0][token1] += amt0;
        reserves[token1][token0] += amt1;

        emit LiquidityAdded(token0, token1, amt0, amt1);
    }

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view override returns (uint256) {
        uint256 rIn  = reserves[tokenIn][tokenOut];
        uint256 rOut = reserves[tokenOut][tokenIn];
        require(rIn > 0 && rOut > 0, "NO_POOL");
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        return (amountInWithFee * rOut) / (rIn + amountInWithFee);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256 amountOut) {
        amountOut = getAmountOut(tokenIn, tokenOut, amountIn);
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        reserves[tokenIn][tokenOut] += amountIn;
        reserves[tokenOut][tokenIn] -= amountOut;

        IERC20(tokenOut).transfer(msg.sender, amountOut);
        emit Swap(tokenIn, tokenOut, amountIn, amountOut);
    }
}
