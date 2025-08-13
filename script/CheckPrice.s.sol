// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import {AMMMock} from "../src/AMMMock.sol";

contract CheckPrice is Script {
    function run() external {
        address ammAddress = 0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389;
        address tokenA = 0x729b67AA1B2F740DA96D445c365Fc07369600EBb;
        address tokenB = 0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782;

        uint256 amountIn = 1e18; // 1 tokenA

        AMMMock amm = AMMMock(ammAddress);
        uint256 estimatedOut = amm.getAmountOut(tokenA, tokenB, amountIn);

        console.log("Estimated swap:", amountIn, "of tokenA for tokenB =", estimatedOut);
    }
}
