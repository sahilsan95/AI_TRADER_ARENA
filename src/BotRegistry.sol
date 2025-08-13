// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IBotRegistry} from "./interfaces/IBotRegistry.sol";
import {Errors} from "./libraries/Errors.sol";

contract BotRegistry is ERC721URIStorage, Ownable2Step, IBotRegistry {
    using SafeERC20 for IERC20;

    uint256 public botCount;
    address public arena;

    mapping(uint256 => BotInfo) private _bots;
    mapping(uint256 => mapping(address => uint256)) private _balances;

    modifier onlyOwnerOf(uint256 botId) {
        require(ownerOf(botId) == msg.sender, Errors.NotOwner);
        _;
    }

    modifier onlyArena() {
        require(msg.sender == arena, Errors.NotArena);
        _;
    }

    constructor() ERC721("TraderBot", "TBOT")  Ownable(msg.sender){
        
    }

    function setArena(address a) external onlyOwner {
        arena = a;
    }

    function mintBot(address to, address strategy, string calldata uri) external override returns (uint256) {
        uint256 botId = ++botCount;
        _mint(to, botId);
        _setTokenURI(botId, uri);

        _bots[botId] = BotInfo({
            owner: to,
            strategy: strategy,
            createdAt: uint64(block.timestamp),
            lastTradeBlock: 0,
            initialValue: 0,
            metadataURI: uri
        });

        emit BotCreated(botId, to, strategy, uri);
        return botId;
    }

    function setStrategy(uint256 botId, address strategy) external override onlyOwnerOf(botId) {
        address old = _bots[botId].strategy;
        _bots[botId].strategy = strategy;
        emit StrategyUpdated(botId, old, strategy);
    }

    function getBot(uint256 botId) external view override returns (BotInfo memory) {
        return _bots[botId];
    }

    function deposit(uint256 botId, address token, uint256 amount) external override onlyOwnerOf(botId) {
        require(token != address(0), Errors.InvalidToken);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _balances[botId][token] += amount;
        emit Deposit(botId, token, amount);
    }

    function withdraw(uint256 botId, address token, uint256 amount) external override onlyOwnerOf(botId) {
        require(_balances[botId][token] >= amount, Errors.InsufficientBalance);
        _balances[botId][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(botId, token, amount);
    }

    function balanceOfToken(uint256 botId, address token) external view override returns (uint256) {
        return _balances[botId][token];
    }

    function addBalanceFromArena(uint256 botId, address token, uint256 amount) external override onlyArena {
        _balances[botId][token] += amount;
    }

    function subBalanceFromArena(uint256 botId, address token, uint256 amount) external override onlyArena {
        require(_balances[botId][token] >= amount, Errors.InsufficientBalance);
        _balances[botId][token] -= amount;
    }

    function setInitialValue(uint256 botId, uint96 value) external override onlyArena {
        _bots[botId].initialValue = value;
    }

    function ownerOf(uint256 botId) public view override(IBotRegistry, ERC721, IERC721) returns (address) {
        return super.ownerOf(botId);
    }
}
