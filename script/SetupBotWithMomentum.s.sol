// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../src/Strategies/SimpleMomentumStrategy.sol";
import "../src/BotRegistry.sol";
import "../src/TradingArena.sol";

contract SetupBotWithMomentum is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        BotRegistry botRegistry = BotRegistry(payable(vm.envAddress("BOT_REGISTRY")));
        TradingArena arena = TradingArena(payable(vm.envAddress("TRADING_ARENA")));

        // Deploy the SimpleMomentumStrategy
        SimpleMomentumStrategy strategy = new SimpleMomentumStrategy(botRegistry, arena);
        console.log("SimpleMomentumStrategy deployed at:", address(strategy));

        // Check if botId 1 exists, else mint
        uint256 botId;
        try botRegistry.ownerOf(1) {
            botId = 1;
            console.log("Bot already exists with botId:", botId);
        } catch {
            botId = botRegistry.mintBot(deployer, address(strategy), "Momentum Bot #1");
            console.log("New bot minted with botId:", botId);
        }

        // Set strategy for the bot
        botRegistry.setStrategy(botId, address(strategy));
        console.log("Strategy set for bot:", botId);

        // Get tokens addresses used in arena
        address tokenA = arena.tokenA();
        address tokenB = arena.tokenB();
        address quoteToken = arena.quoteToken();

        // Define funding amounts
        uint256 fundA = 100 ether;
        uint256 fundB = 50 ether;
        uint256 fundQ = 20 ether;

        // Fund tokenA if address not zero
        if (tokenA != address(0)) {
            require(IERC20(tokenA).balanceOf(deployer) >= fundA, "Not enough tokenA balance");
            IERC20(tokenA).approve(address(botRegistry), fundA);
            IERC20(tokenA).transfer(address(botRegistry), fundA);
            console.log("Funded tokenA to BotRegistry");
        }

        // Fund tokenB if address not zero
        if (tokenB != address(0)) {
            require(IERC20(tokenB).balanceOf(deployer) >= fundB, "Not enough tokenB balance");
            IERC20(tokenB).approve(address(botRegistry), fundB);
            IERC20(tokenB).transfer(address(botRegistry), fundB);
            console.log("Funded tokenB to BotRegistry");
        }

        // Fund quoteToken if set
        if (quoteToken != address(0)) {
            require(IERC20(quoteToken).balanceOf(deployer) >= fundQ, "Not enough quoteToken balance");
            IERC20(quoteToken).approve(address(botRegistry), fundQ);
            IERC20(quoteToken).transfer(address(botRegistry), fundQ);
            console.log("Funded quoteToken to BotRegistry");
        } else {
            fundQ = 0;
            console.log("No quoteToken set; skipped funding quoteToken");
        }

        // Set initial bot value as sum of funded tokens
        uint96 totalValue = uint96(fundA + fundB + fundQ);
        arena.initializeBot(botId, totalValue);
        console.log("Initialized bot initial value:", totalValue);

        // Execute first tick (trade)
        arena.tick(botId);
        console.log("Executed first tick for bot:", botId);

        vm.stopBroadcast();
    }
}
