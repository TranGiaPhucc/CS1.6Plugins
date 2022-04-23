/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Nemesis -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_nemesis_player[][] = { "fai_nemesis1" }
new const models_nemesis_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_nemesis_player_1
new Array:g_models_nemesis_player_2
new Array:g_models_nemesis_claw

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

#define TASK_ARREGEN 1
#define TASK_HPREGEN 2
#define TASK_ARHUD 3

new g_MaxPlayers
new g_IsNemesis

new cvar_nemesis_health, cvar_nemesis_base_health_1, cvar_nemesis_base_health_2, cvar_nemesis_speed, cvar_nemesis_gravity
new cvar_nemesis_glow
new cvar_nemesis_aura, cvar_nemesis_aura_color_R, cvar_nemesis_aura_color_G, cvar_nemesis_aura_color_B
new cvar_nemesis_damage, cvar_nemesis_kill_explode
new cvar_nemesis_grenade_frost, cvar_nemesis_grenade_fire
new g_evolution[33], g_MsgSync
new max_armor, evolution
new g_regen[33]

public plugin_init()
{
	register_plugin("[ZP] Class: Nemesis", ZP_VERSION_STRING, "ZP Dev Team")

	register_event("Damage","event_damage","b","2!0","3=0","4!0")

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	g_MsgSync = CreateHudSyncObj()
	
	cvar_nemesis_health = register_cvar("zp_nemesis_health", "0")
	cvar_nemesis_base_health_1 = register_cvar("zp_nemesis_base_health_lv1", "1500")	//1200
	cvar_nemesis_base_health_2 = register_cvar("zp_nemesis_base_health_lv2", "2150")	//1650
	cvar_nemesis_speed = register_cvar("zp_nemesis_speed", "1.0")
	cvar_nemesis_gravity = register_cvar("zp_nemesis_gravity", "0.5")
	cvar_nemesis_glow = register_cvar("zp_nemesis_glow", "1")
	cvar_nemesis_aura = register_cvar("zp_nemesis_aura", "1")
	cvar_nemesis_aura_color_R = register_cvar("zp_nemesis_aura_color_R", "150")
	cvar_nemesis_aura_color_G = register_cvar("zp_nemesis_aura_color_G", "0")
	cvar_nemesis_aura_color_B = register_cvar("zp_nemesis_aura_color_B", "0")
	cvar_nemesis_damage = register_cvar("zp_nemesis_damage", "10.0")
	cvar_nemesis_kill_explode = register_cvar("zp_nemesis_kill_explode", "0")
	cvar_nemesis_grenade_frost = register_cvar("zp_nemesis_grenade_frost", "0")
	cvar_nemesis_grenade_fire = register_cvar("zp_nemesis_grenade_fire", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_nemesis_player_1 = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_nemesis_player_2 = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_nemesis_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS_1", g_models_nemesis_player_1)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS_2", g_models_nemesis_player_2)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS", g_models_nemesis_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_nemesis_player_1) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_player; index++)
			ArrayPushString(g_models_nemesis_player_1, models_nemesis_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS_1", g_models_nemesis_player_1)
	}
	if (ArraySize(g_models_nemesis_player_2) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_player; index++)
			ArrayPushString(g_models_nemesis_player_2, models_nemesis_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS_2", g_models_nemesis_player_2)
	}
	if (ArraySize(g_models_nemesis_claw) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_claw; index++)
			ArrayPushString(g_models_nemesis_claw, models_nemesis_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS", g_models_nemesis_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_nemesis_player_1); index++)
	{
		ArrayGetString(g_models_nemesis_player_1, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_nemesis_player_2); index++)
	{
		ArrayGetString(g_models_nemesis_player_2, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_nemesis_claw); index++)
	{
		ArrayGetString(g_models_nemesis_claw, index, model, charsmax(model))
		precache_model(model)
	}
}

public plugin_natives()
{
	register_library("zp50_class_nemesis")
	register_native("zp_class_nemesis_get", "native_class_nemesis_get")
	register_native("zp_class_nemesis_set", "native_class_nemesis_set")
	register_native("zp_class_nemesis_get_count", "native_class_nemesis_get_count")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(id+TASK_AURA)
	}
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was nemesis before disconnecting)
	flag_unset(g_IsNemesis, id)
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Nemesis attacking human
	if (flag_get(g_IsNemesis, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore nemesis damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set nemesis damage
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_nemesis_damage))
			return HAM_HANDLED;
		}
	}
	return HAM_IGNORED;
}

public Event_NewRound()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		flag_unset(g_IsNemesis, i)
		evolution = 0
	}
}

public event_damage(id, taskid)
{
	if (!flag_get(g_IsNemesis, id))
		return;

	if (flag_get(g_IsNemesis, id))
	{
		new player_model[PLAYERMODEL_MAX_LENGTH]

		new damage = read_data(2)

		if(g_evolution[id] == 1) evolution += damage / 15
		if(g_evolution[id] == 1 && evolution >= max_armor)
		{
			g_evolution[id] = 2
			evolution = 0
			set_user_health(id, get_user_health(id) + GetAliveCount() * get_pcvar_num(cvar_nemesis_base_health_2))
			cs_set_user_armor(id, get_user_health(id) / 25, 1)
			set_user_maxspeed(id, 270.0)

			client_cmd(0, "spk sound/vz/Survivor_startup.wav")
			//client_cmd(0, "mp3 play sound/vz/n2_ambience.mp3")

			ArrayGetString(g_models_nemesis_player_2, random_num(0, ArraySize(g_models_nemesis_player_2) - 1), player_model, charsmax(player_model))
			cs_set_player_model(id, player_model)

			set_hudmessage(255, 0, 0, -1.0, 0.17, 1, 6.0, 3.0, 0.1, 0.2, -1)
			ShowSyncHudMsg(0, g_MsgSync, "N-2 Detected !!!")
		}
	}
}

public armor_hud(id)
{
	id -= TASK_ARHUD
	if(is_user_alive(id))
	{
		set_hudmessage(0, 255, 0, 0.22, 0.9275, 0, 6.0, 1.1, 0.0, 0.0, -1)
		if(g_evolution[id] == 1)
		{
			new energy = evolution*100/max_armor
			if(0<=energy<10) ShowSyncHudMsg(0, g_MsgSync, "N1 [----------] %i%%", energy)
			else if(10<=energy<20) ShowSyncHudMsg(0, g_MsgSync, "N1 [|---------] %i%%", energy)
			else if(20<=energy<30) ShowSyncHudMsg(0, g_MsgSync, "N1 [||--------] %i%%", energy)
			else if(30<=energy<40) ShowSyncHudMsg(0, g_MsgSync, "N1 [|||-------] %i%%", energy)
			else if(40<=energy<50) ShowSyncHudMsg(0, g_MsgSync, "N1 [||||------] %i%%", energy)
			else if(50<=energy<60) ShowSyncHudMsg(0, g_MsgSync, "N1 [|||||-----] %i%%", energy)
			else if(60<=energy<70) ShowSyncHudMsg(0, g_MsgSync, "N1 [||||||----] %i%%", energy)
			else if(70<=energy<80) ShowSyncHudMsg(0, g_MsgSync, "N1 [|||||||---] %i%%", energy)
			else if(80<=energy<90) ShowSyncHudMsg(0, g_MsgSync, "N1 [||||||||--] %i%%", energy)
			else if(90<=energy<100) ShowSyncHudMsg(0, g_MsgSync, "N1 [|||||||||-] %i%%", energy)
			else ShowSyncHudMsg(0, g_MsgSync, "N1 [||||||||||] 100%")
		}
		else if(g_evolution[id] == 2) ShowSyncHudMsg(0, g_MsgSync, "N2 [%i]", get_user_health(id))
	}
}

public health_increased(id)
{
	id -= TASK_HPREGEN
	if (!flag_get(g_IsNemesis, id))
		set_user_health(id, get_user_health(id) + 5)
	else
	{
		if(g_evolution[id] == 1) set_user_health(id, get_user_health(id) + 23)
		if(g_evolution[id] == 2) set_user_health(id, get_user_health(id) + 35)
	}
}

public armor_increased(id)
{
	id -= TASK_ARREGEN
	if (!flag_get(g_IsNemesis, id))
		cs_set_user_armor(id, get_user_armor(id) + 1, 1)
	else
	{
		cs_set_user_armor(id, get_user_armor(id) + 7, 1)
		evolution += 7
	}
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsNemesis, victim))
	{
		// Nemesis explodes!
		if (get_pcvar_num(cvar_nemesis_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(victim+TASK_AURA)
	}
}

public zp_user_humanized_post(id) 
{
	remove_task(id+TASK_ARREGEN)
	remove_task(id+TASK_HPREGEN)
	remove_task(id+TASK_ARHUD)
	g_evolution[id] = 0
	flag_unset(g_IsNemesis, id)
	set_user_maxspeed(id, 220.0)
	g_regen[id] = 0
}

public zp_user_infected_post(id)
{
	if (g_regen[id] == 0)
	{
		set_task(1.0, "armor_increased", id+TASK_ARREGEN, _, _, "b")
		set_task(0.5, "health_increased", id+TASK_HPREGEN, _, _, "b")

		g_regen[id] = 1
	}

	if (!flag_get(g_IsNemesis, id))
		return;

	set_task(0.1, "armor_hud", id+TASK_ARHUD, _, _, "b")
	if (flag_get(g_IsNemesis, id)) g_evolution[id] = 1
	if (!flag_get(g_IsNemesis, id)) g_evolution[id] = 0
	set_user_maxspeed(id, 240.0)
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Nemesis
	if (flag_get(g_IsNemesis, id) && !get_pcvar_num(cvar_nemesis_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Nemesis
	if (flag_get(g_IsNemesis, id) && !get_pcvar_num(cvar_nemesis_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(id+TASK_AURA)
		
		// Remove nemesis flag
		flag_unset(g_IsNemesis, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(id+TASK_AURA)
		
		// Remove nemesis flag
		flag_unset(g_IsNemesis, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply Nemesis attributes?
	if (!flag_get(g_IsNemesis, id))
		return;
	
	// Set Evolution
	g_evolution[id] = 1

	// Health
	if (get_pcvar_num(cvar_nemesis_health) == 0)
	{
		set_user_health(id, get_pcvar_num(cvar_nemesis_base_health_1) * GetAliveCount())
		max_armor = get_pcvar_num(cvar_nemesis_base_health_1) * GetAliveCount() / 15
	}
	else
	{
		set_user_health(id, get_pcvar_num(cvar_nemesis_health))
		max_armor = get_pcvar_num(cvar_nemesis_health) / 15
	}
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_nemesis_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_nemesis_speed))
	
	// Apply nemesis player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	if(g_evolution[id] == 1) ArrayGetString(g_models_nemesis_player_1, random_num(0, ArraySize(g_models_nemesis_player_1) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply nemesis claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_claw, random_num(0, ArraySize(g_models_nemesis_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Nemesis glow
	if (get_pcvar_num(cvar_nemesis_glow))
		set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
	
	// Nemesis aura task
	if (get_pcvar_num(cvar_nemesis_aura))
		set_task(0.1, "nemesis_aura", id+TASK_AURA, _, _, "b")
}

public native_class_nemesis_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsNemesis, id);
}

public native_class_nemesis_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsNemesis, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a nemesis (%d)", id)
		return false;
	}
	
	flag_set(g_IsNemesis, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_nemesis_get_count(plugin_id, num_params)
{
	return GetNemesisCount();
}

// Nemesis aura task
public nemesis_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

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

// Get Nemesis Count -returns alive nemesis number-
GetNemesisCount()
{
	new iNemesis, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsNemesis, id))
			iNemesis++
	}
	
	return iNemesis;
}
