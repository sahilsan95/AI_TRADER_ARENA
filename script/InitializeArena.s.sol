// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import {TradingArena} from "../src/TradingArena.sol";

contract UpdateArenaToken is Script {
    function run() external {
        address arenaAddress = 0xDa0b11d93728Fa7F2d0bd2E154b8107FCAFd5B28;

        address tokenA = 0x729b67AA1B2F740DA96D445c365Fc07369600EBb; // new STT
        address tokenB = 0xB2614c8E833ef0Caafccc4978D366378ae383169; // USDC

        vm.startBroadcast();

        TradingArena(arenaAddress).setValuationTokens(tokenA, tokenB);

        vm.stopBroadcast();
    }
}
