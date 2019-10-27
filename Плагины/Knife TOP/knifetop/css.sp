// File:   css.sp
// Author: Otstrel.ru Team

public Event_CSS_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    Trace("Player death hooked");
    if (g_iswarmup)
    {
        Trace("Warmup");
        return;
    }    
    // Read relevant event data
    new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if(g_initialized[attacker] && 
       g_initialized[userid] && 
       IsClientInGame(attacker) && 
       IsClientInGame(userid))
    {
        Trace("Players are initialized");
        new user_team = GetClientTeam(userid);
        new attacker_team = GetClientTeam(attacker);
        
        // Check for knife
        decl String: weapon[64];
        GetEventString(event, "weapon", weapon, 64);
        Trace("Weapon is...");
        Trace(weapon);
        if(!StrEqual(weapon,"knife"))
        {
            Trace("Weapon is not a knife");
        }
        // Check for suicide
        else if(userid == attacker)
        {
            Trace("Suicide detected");
        }
        // Otherwise it's a legitimate kill!
        else if(user_team != attacker_team)
        {
            Trace("Knifekill detected");
            if (isPlayerAfk(userid))
            {
                Trace("Player is AFK");
                return;
            } 
            
            if ( !g_kills[attacker] && !g_deaths[attacker] ) 
            {
                g_player_count++;
            }
            if ( !g_kills[userid] && !g_deaths[userid] ) 
            {
                g_player_count++;
            }
            
            g_kills[attacker]++;
            g_deaths[userid]++;
            
            g_score[attacker]++;
            g_score[userid]--;
            
            SavePlayer(attacker);
            SavePlayer(userid);
        }
    }
}
