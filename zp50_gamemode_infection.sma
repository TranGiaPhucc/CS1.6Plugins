/*================================================================================
	
	---------------------------------
	-*- [ZP] Game Mode: Infection -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zombieplague>
#include <zp50_class_nemesis>
#include <zp50_class_assassin>
#include <zp50_class_survivor>
#include <zp50_deathmatch>

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 0
#define HUD_EVENT_B 0

new g_MaxPlayers
new g_HudSync
new g_TargetPlayer

new cvar_infection_chance, cvar_infection_min_players
new cvar_infection_show_hud
new cvar_infection_allow_respawn, cvar_respawn_after_last_human
new cvar_zombie_first_hp_multiplier

new random_infect, random_gnem, has_nemesis, has_gmonster, first_zm
new count

new const num_to_flag[7][] = { "a", "b", "c", "d", "f", "m", "z" }

new pcvar_light_one, pcvar_light_two, pcvar_light_three, pcvar_light_four, pcvar_light_five, pcvar_light_six 
new pointer_lighting

new play_music, light_check

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Infection", ZP_VERSION_STRING, "ZP Dev Team")
	new game_mode_id = zp_gamemodes_register("Infection Mode")
	zp_gamemodes_set_default(game_mode_id)
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_infection_chance = register_cvar("zp_infection_chance", "1")
	cvar_infection_min_players = register_cvar("zp_infection_min_players", "0")
	cvar_infection_show_hud = register_cvar("zp_infection_show_hud", "1")
	cvar_infection_allow_respawn = register_cvar("zp_infection_allow_respawn", "1")
	cvar_respawn_after_last_human = register_cvar("zp_respawn_after_last_human", "1")
	cvar_zombie_first_hp_multiplier = register_cvar("zp_zombie_first_hp_multiplier", "3.4")

	pcvar_light_one = register_cvar("zp_infection_ext_lighting1", "6")
	pcvar_light_two = register_cvar("zp_infection_ext_lighting2", "5")
	pcvar_light_three = register_cvar("zp_infection_ext_lighting3", "4")
	pcvar_light_four = register_cvar("zp_infection_ext_lighting4", "3")
	pcvar_light_five = register_cvar("zp_infection_ext_lighting5", "2")
	pcvar_light_six = register_cvar("zp_infection_ext_lighting6", "1")

	pointer_lighting = get_cvar_pointer("zp_lighting")
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_infection_allow_respawn))
		return PLUGIN_HANDLED;
	
	// Respawn if only the last human is left?
	if (!get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_infection_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_infection_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
}

public zp_fw_gamemodes_start()
{
	// Allow infection for this game mode
	zp_gamemodes_set_allow_infect()
	
	// Turn player into the first zombie
	zp_core_infect(g_TargetPlayer, g_TargetPlayer) // victim = atttacker so that infection sound is played
	set_user_health(g_TargetPlayer, floatround(get_user_health(g_TargetPlayer) * get_pcvar_float(cvar_zombie_first_hp_multiplier)))
	
	// Remaining players should be humans (CTs)
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our first zombie
		if (zp_core_is_zombie(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	
	if (get_pcvar_num(cvar_infection_show_hud))
	{
		// Show First Zombie HUD notice
		new name[32]
		get_user_name(g_TargetPlayer, name, charsmax(name))
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_FIRST", name)
	}

	light_check = 0
	play_music = 0
	has_nemesis = 0
	has_gmonster = 0
	first_zm = 0
	count = 0
	server_cmd("zp_deathmatch 2")
	set_task(60.0, "respawn")
}

public zp_fw_gamemodes_end() server_cmd("zp_deathmatch 0")

public respawn()
{
	server_cmd("zp_deathmatch 0")
	client_print(0,print_center,"Zombies cannot respawn anymore due to the detoxin.")
}

/*
public zp_user_infected_post(id, last)
{
	first_zm += 1
	random_infect = random_num(1,100)
	if(random_infect <= 3 && first_zm > 2)
	{
		if(has_nemesis == 1 && has_gmonster == 0)
		{
			zp_class_assassin_set(id)
			has_gmonster = 1
			play_music += 1
			cs_set_user_armor(id, get_user_health(id) / 25, 1)
			client_cmd(0, "spk sound/vz/Nemesis_Startup.wav")
			get_human_count()
			server_cmd("zp_deathmatch 0")
			zp_gamemodes_set_allow_infect(false)
			if(light_check == 0)
			{
				set_task(7.0, "light1")
				set_task(13.0, "light2")
				set_task(14.0, "light3")
				set_task(17.8, "light4")
				set_task(18.5, "light5")
				set_task(19.0, "light6")
				light_check = 1
			}
		}
		else if(has_nemesis == 0 && has_gmonster == 1)
		{
			zp_class_nemesis_set(id)
			has_nemesis = 1
			play_music += 1
			cs_set_user_armor(id, get_user_health(id) / 25, 1)
			client_cmd(0, "spk sound/vz/Nemesis_Startup.wav")
			get_human_count()
			server_cmd("zp_deathmatch 0")
			zp_gamemodes_set_allow_infect(false)
			if(light_check == 0)
			{
				set_task(7.5, "light1")
				set_task(13.5, "light2")
				set_task(16.5, "light3")
				set_task(18.3, "light4")
				set_task(19.0, "light5")
				set_task(19.5, "light6")
				light_check = 1
			}
		}
		else if(has_nemesis == 0 && has_gmonster == 0)
		{
			random_gnem = random_num(1,2)
			if(random_gnem == 1)
			{
				zp_class_nemesis_set(id)
				has_nemesis = 1
			}
			else if(random_gnem == 2)
			{
				zp_class_assassin_set(id)
				has_gmonster = 1
			
			}
			play_music += 1
			cs_set_user_armor(id, get_user_health(id) / 25, 1)
			get_human_count()
			server_cmd("zp_deathmatch 0")
			zp_gamemodes_set_allow_infect(false)
			if(light_check == 0)
			{
				set_task(6.0, "light1")
				set_task(12.0, "light2")
				set_task(15.0, "light3")
				set_task(16.8, "light4")
				set_task(17.5, "light5")
				set_task(18.0, "light6")
				light_check = 1
			}
		}
		if(play_music == 1)
		{
			play_music += 1
			client_cmd(0, "mp3 play sound/vz/n2_ambience.mp3")
		}
	}
}

public light1() set_light(get_pcvar_num(pcvar_light_one))
public light2() set_light(get_pcvar_num(pcvar_light_two))
public light3() set_light(get_pcvar_num(pcvar_light_three))
public light4() set_light(get_pcvar_num(pcvar_light_four))
public light5() set_light(get_pcvar_num(pcvar_light_five))
public light6() set_light(get_pcvar_num(pcvar_light_six))

set_light(level)
    set_pcvar_string(pointer_lighting, level > 7 ? "z" : num_to_flag[level-1]);
*/

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}
/*
public get_human_count()
{
    if(count != 0)
	return;

    for(new i = 0; i < g_MaxPlayers; i++)
    {
        if(is_user_connected(i) && zp_get_user_survivor(i))
        {
		count = 1
		return;
	}
    }
    for(new i = 0; i < g_MaxPlayers; i++)
    {
	if(is_user_connected(i) && !zp_get_user_zombie(i) && !zp_get_user_nemesis(i) && !zp_get_user_survivor(i))
	{
		if(random_num(1,4) == 1)
		{
			zp_class_survivor_set(i)
			count = 1
		}
		if(i == (g_MaxPlayers - 1) && count == 0) zp_class_survivor_set(i)
	}
    }
}*/