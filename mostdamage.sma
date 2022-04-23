#include <amxmodx>
#include <fun>
#include <cstrike>

new g_damage[33], g_name[2], highest, current, g_MaxPlayers

public plugin_init()
{
	register_plugin("Most Damage Done By", "1.0", "JonVigo")

	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("Damage","event_damage","b","2!0","3=0","4!0")

	register_clcmd("say !me", "show_damage")

	g_MaxPlayers = get_maxplayers()
}

public event_newround()
{
	highest = current = 0
	for(new i = 0; i < g_MaxPlayers; i++) g_damage[i] = 0
}

public show_damage(id) client_print(id, print_chat, ">>>> You did %i damage", g_damage[id])
public event_damage(id)
{
	new attacker = get_user_attacker(id)
	new dmg = read_data(2)

	g_damage[attacker] += dmg

	if(g_damage[attacker] >= highest)
	{
		current = attacker
		highest = g_damage[attacker]
	}
	g_name[1] = current
}

public zp_fw_gamemodes_end()
{
	new curid, Player_Name[64]
	curid = g_name[1]

	get_user_name(curid, Player_Name, sizeof(Player_Name))
	if(highest != 0) client_print(0,print_chat,">>>> Most damage done by: %s (%i damage)",Player_Name,highest)
}