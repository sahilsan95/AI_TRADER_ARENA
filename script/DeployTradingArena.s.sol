// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import {TradingArena} from "../src/TradingArena.sol";
import {IBotRegistry} from "../src/interfaces/IBotRegistry.sol";
import {ILeaderboard} from "../src/interfaces/ILeaderboard.sol";
import {IAMM} from "../src/interfaces/IAMM.sol";

contract DeployTradingArena is Script {
    function run() external returns (TradingArena arena) {
        vm.startBroadcast();

        arena = new TradingArena(
            IBotRegistry(0x5751727946F90eA235feF74AA989b8145b7b62aE),  // BotRegistry
            ILeaderboard(0x581c414663bbaf0257c024433da937B3431EDe68), // Leaderboard
            IAMM(0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389),       // AMM
            0x53269f744a67dCd869be483C3805DE87903d8545              // QuoteToken
        );

        vm.stopBroadcast();
    }
}
