// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import "../src/Leaderboard.sol";

contract DeployLeaderboard is Script {
    function run() external {
        vm.startBroadcast();

        Leaderboard leaderboard = new Leaderboard();
        console.log("Leaderboard deployed at:", address(leaderboard));

        vm.stopBroadcast();
    }
}
