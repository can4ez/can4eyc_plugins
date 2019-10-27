// File:   knifetop.inc
// Author: Otstrel.ru Team

#if defined _knifetop_included_
  #endinput
#endif
#define _knifetop_included_

public SharedPlugin:__pl_knifetop = 
{
    name = "knifetop", 
    file = "knifetop.smx", 
#if defined REQUIRE_PLUGIN
    required = 1 
#else
    required = 0
#endif
};

#define STAT_SCORE       0
#define STAT_KILLS       1
#define STAT_DEATHS      2

#define MAX_STATS        3

#define ERROR_PLAYER_NOT_FOUND 1

public Handle:stats_db;

public __pl_knifetop_SetNTVOptional()
{
    MarkNativeAsOptional("KnifeTop_GetTopPlayers");
}

funcenum StatsCallback
{
    public(const String:name[], const String:steamid[], any:stats[], any:data, retval),
    public(rank, delta, any:data, error)
};

/**
 * Retrieve player's stats, starting at 'rank' and continuing down 
 * 'count' players.  Callback is called once for each player, in 
 * order of best (lowest) rank to highest (worst) rank.  Once all 
 * players are processed, calls callback with a blank steamid.  
 * (One SQL query)
 * 
 *
 * @param rank          Starting rank to fetch.
 * @param count         Number of players to fetch.
 * @param callback      Callback to return stats (uses first StatsCallback definition).
 * @param data          Data to pass to callback.
 * @return              NULL
 */
native bool:KnifeTop_GetTopPlayers(rank, count, StatsCallback:callback, any:data = 0);
