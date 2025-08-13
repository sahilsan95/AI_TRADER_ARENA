// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {SimpleMomentumStrategy} from "../src/strategies/SimpleMomentumStrategy.sol";
import {IBotRegistry} from "../src/interfaces/IBotRegistry.sol";
import {IValuationView} from "../src/interfaces/IValuationView.sol";

contract DeploySimpleMomentumStrategy is Script {
    function run() external {
        // Read addresses directly from .env variables
        address botRegistry = vm.envAddress("BOT_REGISTRY");
        address arena = vm.envAddress("TRADING_ARENA");

        vm.startBroadcast();

        SimpleMomentumStrategy strategy = new SimpleMomentumStrategy(
            IBotRegistry(botRegistry),
            IValuationView(arena)
        );

        vm.stopBroadcast();

        console.log("SimpleMomentumStrategy deployed at:", address(strategy));
    }
}
