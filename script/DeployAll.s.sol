
// pragma solidity ^0.8.24;

// import "forge-std/Script.sol";
// import {Token} from "../src/Token.sol";
// import {PriceOracleMock} from "../src/PriceOracleMock.sol";
// import {AMMMock} from "../src/AMMMock.sol";
// import {BotRegistry} from "../src/BotRegistry.sol";
// import {Leaderboard} from "../src/Leaderboard.sol";
// import {TradingArena} from "../src/TradingArena.sol";
// import {TournamentManager} from "../src/TournamentManager.sol";
// import {SimpleMomentumStrategy} from "../src/strategies/SimpleMomentumStrategy.sol";
// import {IBotRegistry} from "../src/interfaces/IBotRegistry.sol";
// import {IValuationView} from "../src/interfaces/IValuationView.sol";
// import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// contract DeployAll is Script {
//     function run() external {
//         uint256 pk = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(pk);

//         Token tokenA = new Token("Arena Token A", "TKNA");
//         Token tokenB = new Token("Arena Token B", "TKNB");
//         Token quote  = new Token("Arena USD", "aUSD");

//         tokenA.mint(msg.sender, 1_000_000 ether);
//         tokenB.mint(msg.sender, 1_000_000 ether);
//         quote.mint(msg.sender,  1_000_000 ether);

//         AMMMock amm = new AMMMock();
//         tokenA.approve(address(amm), type(uint256).max);
//         tokenB.approve(address(amm), type(uint256).max);
//         quote.approve(address(amm), type(uint256).max);

//         amm.addLiquidity(address(tokenA), address(tokenB), 200_000 ether, 200_000 ether);
//         amm.addLiquidity(address(tokenA), address(quote),  200_000 ether, 200_000 ether);
//         amm.addLiquidity(address(tokenB), address(quote),  200_000 ether, 200_000 ether);

//         BotRegistry reg = new BotRegistry();
//         console.log("Reg: %s", address(reg));

//         Leaderboard board = new Leaderboard();
//         console.log("Board: %s", address(board));

//         TradingArena arena = new TradingArena(IBotRegistry(address(reg)), board, amm, address(quote));
//         console.log("Arena: %s", address(arena));
//         arena.setValuationTokens(address(tokenA), address(tokenB));

//         reg.setArena(address(arena));
//         board.setArena(address(arena));
//         board.setQuoteToken(address(quote));

//         TournamentManager tm = new TournamentManager(board, address(quote));
//         console.log("TM: %s", address(tm));

//         SimpleMomentumStrategy strat = new SimpleMomentumStrategy(IBotRegistry(address(reg)), IValuationView(address(arena)));
//         console.log("Strategy: %s", address(strat));

//         uint256 b1 = reg.mintBot(msg.sender, address(strat), "ipfs://bot1");
//         uint256 b2 = reg.mintBot(msg.sender, address(strat), "ipfs://bot2");
//         uint256 b3 = reg.mintBot(msg.sender, address(strat), "ipfs://bot3");

//         _fundBot(reg, address(tokenA), b1, 10_000 ether);
//         _fundBot(reg, address(tokenB), b1, 10_000 ether);
//         _fundBot(reg, address(quote),  b1, 10_000 ether);

//         _fundBot(reg, address(tokenA), b2,  8_000 ether);
//         _fundBot(reg, address(tokenB), b2, 12_000 ether);
//         _fundBot(reg, address(quote),  b2, 10_000 ether);

//         _fundBot(reg, address(tokenA), b3, 12_000 ether);
//         _fundBot(reg, address(tokenB), b3,  8_000 ether);
//         _fundBot(reg, address(quote),  b3, 10_000 ether);

//         arena.refreshValue(b1);
//         arena.refreshValue(b2);
//         arena.refreshValue(b3);

//         uint64 start = uint64(block.timestamp);
//         uint64 end   = uint64(block.timestamp + 3600);
//         tm.startTournament(start, end, 2);

//         quote.approve(address(tm), 3_000 ether);
//         tm.addToPrizePool(tm.currentTournamentId(), 3_000 ether);

//         console.log("export REGISTRY=%s", address(reg));
//         console.log("export ARENA=%s", address(arena));
//         console.log("export BOARD=%s", address(board));
//         console.log("export TM=%s", address(tm));

//         vm.stopBroadcast();
//     }

//     function _fundBot(BotRegistry reg, address token, uint256 botId, uint256 amount) internal {
//         IERC20(token).approve(address(reg), amount);
//         reg.deposit(botId, token, amount);
//     }
// }


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {PriceOracleMock} from "../src/PriceOracleMock.sol";
import {AMMMock} from "../src/AMMMock.sol";
import {BotRegistry} from "../src/BotRegistry.sol";
import {Leaderboard} from "../src/Leaderboard.sol";
import {TradingArena} from "../src/TradingArena.sol";
import {TournamentManager} from "../src/TournamentManager.sol";
import {SimpleMomentumStrategy} from "../src/strategies/SimpleMomentumStrategy.sol";
import {IBotRegistry} from "../src/interfaces/IBotRegistry.sol";
import {IValuationView} from "../src/interfaces/IValuationView.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Deploy tokens
        Token tokenA = new Token("Arena Token A", "TKNA");
        Token tokenB = new Token("Arena Token B", "TKNB");
        Token quote  = new Token("Arena USD", "aUSD");

        tokenA.mint(msg.sender, 1_000_000 ether);
        tokenB.mint(msg.sender, 1_000_000 ether);
        quote.mint(msg.sender, 1_000_000 ether);

        // Deploy AMM and provide liquidity
        AMMMock amm = new AMMMock();
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        quote.approve(address(amm), type(uint256).max);

        amm.addLiquidity(address(tokenA), address(tokenB), 200_000 ether, 200_000 ether);
        amm.addLiquidity(address(tokenA), address(quote),  200_000 ether, 200_000 ether);
        amm.addLiquidity(address(tokenB), address(quote),  200_000 ether, 200_000 ether);

        // Deploy registry and leaderboard
        BotRegistry reg = new BotRegistry();
        console.log("BotRegistry deployed at:", address(reg));

        Leaderboard board = new Leaderboard();
        console.log("Leaderboard deployed at:", address(board));

        // Deploy arena
        TradingArena arena = new TradingArena(IBotRegistry(address(reg)), board, amm, address(quote));
        arena.setValuationTokens(address(tokenA), address(tokenB));
        console.log("TradingArena deployed at:", address(arena));

        reg.setArena(address(arena));
        board.setArena(address(arena));
        board.setQuoteToken(address(quote));

        // Deploy tournament manager
        TournamentManager tm = new TournamentManager(board, address(quote));
        console.log("TournamentManager deployed at:", address(tm));

        // Deploy strategy
        SimpleMomentumStrategy strat = new SimpleMomentumStrategy(IBotRegistry(address(reg)), IValuationView(address(arena)));
        console.log("Strategy deployed at:", address(strat));

        // Mint bots and fund them
        uint256 b1 = reg.mintBot(msg.sender, address(strat), "ipfs://bot1");
        uint256 b2 = reg.mintBot(msg.sender, address(strat), "ipfs://bot2");
        uint256 b3 = reg.mintBot(msg.sender, address(strat), "ipfs://bot3");

        _fundBot(msg.sender, reg, tokenA, b1, 10_000 ether);
        _fundBot(msg.sender, reg, tokenB, b1, 10_000 ether);
        _fundBot(msg.sender, reg, quote,  b1, 10_000 ether);

        _fundBot(msg.sender, reg, tokenA, b2, 8_000 ether);
        _fundBot(msg.sender, reg, tokenB, b2, 12_000 ether);
        _fundBot(msg.sender, reg, quote,  b2, 10_000 ether);

        _fundBot(msg.sender, reg, tokenA, b3, 12_000 ether);
        _fundBot(msg.sender, reg, tokenB, b3, 8_000 ether);
        _fundBot(msg.sender, reg, quote,  b3, 10_000 ether);

        // Refresh bot values in arena
        arena.refreshValue(b1);
        arena.refreshValue(b2);
        arena.refreshValue(b3);

        // Start a tournament
        uint64 start = uint64(block.timestamp);
        uint64 end   = uint64(block.timestamp + 3600);
        tm.startTournament(start, end, 2);

        quote.approve(address(tm), 3_000 ether);
        tm.addToPrizePool(tm.currentTournamentId(), 3_000 ether);

        // Export addresses for scripts
        console.log("export REGISTRY=%s", address(reg));
        console.log("export ARENA=%s", address(arena));
        console.log("export BOARD=%s", address(board));
        console.log("export TM=%s", address(tm));

        vm.stopBroadcast();
    }

    function _fundBot(
        address sender,
        BotRegistry reg,
        IERC20 token,
        uint256 botId,
        uint256 amount
    ) internal {
        token.approve(address(reg), amount);
        reg.deposit(botId, address(token), amount);
    }
}
