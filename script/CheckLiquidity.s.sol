// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AMMMock} from "../src/AMMMock.sol";

contract CheckLiquidity is Script {
    function run() external {
        // Replace with your deployed AMM and token addresses
        address ammAddress = 0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389;
        address tokenA = 0x729b67AA1B2F740DA96D445c365Fc07369600EBb; // STT
        address tokenB = 0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782; // TokenB

        vm.startBroadcast();

        uint256 reserveA = IERC20(tokenA).balanceOf(ammAddress);
        uint256 reserveB = IERC20(tokenB).balanceOf(ammAddress);

        console.log("AMM Liquidity Reserves:");
        console.log("TokenA (STT):", reserveA);
        console.log("TokenB:", reserveB);

        vm.stopBroadcast();
    }
}
