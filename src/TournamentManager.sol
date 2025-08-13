// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITournamentManager} from "./interfaces/ITournamentManager.sol";
import {ILeaderboard} from "./interfaces/ILeaderboard.sol";
import {Errors} from "./libraries/Errors.sol";

contract TournamentManager is ITournamentManager, Ownable2Step {
    using SafeERC20 for IERC20;

    ILeaderboard public immutable board;
    address public immutable prizeToken;

    uint256 public _currentId;
    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => uint256[]) public winnersOf;
    mapping(uint256 => uint256[]) public payoutsOf;

    constructor(ILeaderboard _board, address _prizeToken) Ownable(msg.sender) {
        board = _board;
        prizeToken = _prizeToken;
       
    }

    function currentTournamentId() external view override returns (uint256) { return _currentId; }

    function startTournament(uint64 startTime, uint64 endTime, uint32 maxWinners) external override onlyOwner returns (uint256) {
        require(endTime > startTime && maxWinners > 0, "BAD_PARAMS");
        _currentId += 1;
        tournaments[_currentId] = Tournament({ startTime: startTime, endTime: endTime, maxWinners: maxWinners, active: true, prizePool: 0 });
        emit TournamentStarted(_currentId, startTime, endTime, maxWinners);
        return _currentId;
    }

    function addToPrizePool(uint256 tournamentId, uint256 amount) external override {
        Tournament storage t = tournaments[tournamentId];
        require(t.active, Errors.TournamentInactive);
        IERC20(prizeToken).safeTransferFrom(msg.sender, address(this), amount);
        t.prizePool += uint96(amount);
    }

    function endTournament(uint256 tournamentId) external override onlyOwner {
        Tournament storage t = tournaments[tournamentId];
        require(t.active && block.timestamp >= t.endTime, "NOT_FINISHED");
        t.active = false;
    }

    function finalizeWinners(uint256 tournamentId, uint256[] calldata winnerIds) external onlyOwner {
        Tournament storage t = tournaments[tournamentId];
        require(!t.active, "STILL_ACTIVE");
        require(winnerIds.length > 0 && winnerIds.length <= t.maxWinners, "BAD_WINNERS");

        uint256 each = t.prizePool / winnerIds.length;
        uint256[] memory pays = new uint256[](winnerIds.length);

        for (uint256 i = 0; i < winnerIds.length; i++) {
            pays[i] = each;
        }

        winnersOf[tournamentId] = winnerIds;
        payoutsOf[tournamentId] = pays;

        emit TournamentEnded(tournamentId, winnerIds, pays);
    }
}
