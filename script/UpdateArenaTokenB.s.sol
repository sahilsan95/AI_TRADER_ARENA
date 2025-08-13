// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import {TradingArena} from "../src/TradingArena.sol";

contract UpdateArenaTokenB is Script {
    function run() external {
        address arenaAddress = 0x3b44b8d6FD3826842D0D6d5C0b35b19da57a1C3c;
        address tokenB = 0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782;

        vm.startBroadcast();

        // Update TokenB in the TradingArena
        TradingArena(arenaAddress).setValuationTokens(
            TradingArena(arenaAddress).tokenA(), // keep existing TokenA
            tokenB
        );

        vm.stopBroadcast();
    }
}
