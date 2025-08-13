// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract DeployScript is Script {
    function run() external {
        // Start broadcasting with your private key
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy STT Token
        Token stt = new Token("STT Token", "STT");
        console.log("STT Token deployed at:", address(stt));

        // Optionally, mint initial supply to yourself
        stt.mint(msg.sender, 200_000 * 1e18); 
        console.log("Minted 200k STT to deployer");

        vm.stopBroadcast();
    }
}
