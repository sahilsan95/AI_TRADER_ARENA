// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import {AMMMock} from "../src/AMMMock.sol";

contract DeployAMMMock is Script {
    function run() external returns (AMMMock amm) {
        vm.startBroadcast();
        amm = new AMMMock();
        vm.stopBroadcast();
    }
}
