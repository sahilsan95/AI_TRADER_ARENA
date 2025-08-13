// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import "../src/Token.sol";

contract DeployTokenB is Script {
    function run() external returns (Token tokenB) {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy a new ERC20 token for TokenB
        tokenB = new Token("TokenB", "TKB");
        console.log("TokenB deployed at:", address(tokenB));

        // Mint some initial supply to yourself for testing/liquidity
        tokenB.mint(msg.sender, 1_000_000 * 1e18);
        console.log("Minted 1,000,000 TKB to deployer");

        vm.stopBroadcast();
    }
}
