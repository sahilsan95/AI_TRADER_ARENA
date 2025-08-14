// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    string constant NotOwner            = "NOT_OWNER";
    string constant NotArena            = "NOT_ARENA";
    string constant InvalidToken        = "INVALID_TOKEN";
    string constant InsufficientBalance = "INSUFFICIENT_BAL";
    string constant TradeTooSoon        = "TRADE_TOO_SOON";
    string constant TournamentInactive  = "TOURNAMENT_INACTIVE";
    string constant NothingToDo         = "NOTHING_TO_DO";
    string constant Unauthorized        = "UNAUTHORIZED"; 
}
