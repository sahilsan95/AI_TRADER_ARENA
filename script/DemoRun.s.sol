// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {TradingArena} from "../src/TradingArena.sol";
import {BotRegistry} from "../src/BotRegistry.sol";
import {Leaderboard} from "../src/Leaderboard.sol";
import {TournamentManager} from "../src/TournamentManager.sol";

contract DemoRun is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        TradingArena arena = TradingArena(payable(vm.envAddress("ARENA")));
        BotRegistry  reg   = BotRegistry(payable(vm.envAddress("REGISTRY")));
        Leaderboard  board = Leaderboard(payable(vm.envAddress("BOARD")));
        TournamentManager tm = TournamentManager(payable(vm.envAddress("TM")));

        // ✅ Declare and initialize bots array (3 bot IDs)
        uint256[] memory bots = new uint256[](3);
        bots[0] = 1;
        bots[1] = 2;
        bots[2] = 3;

        // 📈 Run multiple ticks to simulate trades for these bots
        for (uint256 i = 0; i < 10; i++) {
            arena.tickMany(bots);
        }

        // 🔄 Refresh value for each bot
        for (uint256 i = 0; i < bots.length; i++) {
            arena.refreshValue(bots[i]);
        }

        vm.stopBroadcast();
    }
}
