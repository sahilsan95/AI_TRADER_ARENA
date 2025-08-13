// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITournamentManager {
    struct Tournament {
        uint64 startTime;
        uint64 endTime;
        uint32 maxWinners;
        bool   active;
        uint96 prizePool;
    }

    event TournamentStarted(uint256 indexed id, uint64 start, uint64 end, uint32 maxWinners);
    event TournamentEnded(uint256 indexed id, uint256[] winners, uint256[] payouts);

    function startTournament(uint64 startTime, uint64 endTime, uint32 maxWinners) external returns (uint256);
    function endTournament(uint256 tournamentId) external;

    function addToPrizePool(uint256 tournamentId, uint256 amount) external;
    function currentTournamentId() external view returns (uint256);
}
