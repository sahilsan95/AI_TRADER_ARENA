// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/BotRegistry.sol";

contract DeployBotRegistry is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy BotRegistry
        BotRegistry botRegistry = new BotRegistry();
        console.log("BotRegistry deployed at:", address(botRegistry));

        vm.stopBroadcast();
    }
}
