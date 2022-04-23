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
#include <zp50_items.inc>

// PLUGIN, VERSION, AUTHOR
#define PLUGIN	"G-Virus Monster William Birkin"
#define VERSION	"1.0"
#define AUTHOR	"Jonvigo" 

/*	Do NOT modify here unless you know what you are doing!		*/

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_assassin_player[][] = { "fai_gmonster1" }
new const models_assassin_claw[][] = { "models/fai_zombie/v_knife_deimos_zombi.mdl" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_assassin_player_1
new Array:g_models_assassin_player_2
new Array:g_models_assassin_player_3
new Array:g_models_assassin_claw

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
new g_IsAssassin

new cvar_assassin_health, cvar_assassin_base_health_1, cvar_assassin_base_health_2, cvar_assassin_base_health_3, cvar_assassin_speed, cvar_assassin_gravity
new cvar_assassin_glow
new cvar_assassin_aura, cvar_assassin_aura_color_R, cvar_assassin_aura_color_G, cvar_assassin_aura_color_B
new cvar_assassin_kill_explode, cvar_assassin_damage
new cvar_assassin_grenade_frost, cvar_assassin_grenade_fire
new max_armor_1, max_armor_2
new evolution

new g_evolution[33], g_MsgSync

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("Damage","event_damage","b","2!0","3=0","4!0")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	register_forward(FM_CmdStart, "CmdStart" )
	
	g_MaxPlayers = get_maxplayers()

	g_MsgSync = CreateHudSyncObj()
	
	cvar_assassin_health = register_cvar("zp_assassin_health", "0")
	cvar_assassin_base_health_1 = register_cvar("zp_assassin_base_health_lv1", "1350")	//1050
	cvar_assassin_base_health_2 = register_cvar("zp_assassin_base_health_lv2", "1650")	//1250
	cvar_assassin_base_health_3 = register_cvar("zp_assassin_base_health_lv3", "1950")	//1450
	cvar_assassin_speed = register_cvar("zp_assassin_speed", "7.0")
	cvar_assassin_gravity = register_cvar("zp_assassin_gravity", "0.3")
	cvar_assassin_glow = register_cvar("zp_assassin_glow", "0")
	cvar_assassin_aura = register_cvar("zp_assassin_aura", "0")
	cvar_assassin_aura_color_R = register_cvar("zp_assassin_aura_color_R", "0")
	cvar_assassin_aura_color_G = register_cvar("zp_assassin_aura_color_G", "255")
	cvar_assassin_aura_color_B = register_cvar("zp_assassin_aura_color_B", "255")
	cvar_assassin_damage = register_cvar("zp_assassin_damage", "16.0")
	cvar_assassin_kill_explode = register_cvar("zp_assassin_kill_explode", "0")
	cvar_assassin_grenade_frost = register_cvar("zp_assassin_grenade_frost", "0")
	cvar_assassin_grenade_fire = register_cvar("zp_assassin_grenade_fire", "0")
	
}

public plugin_precache()
{
	// Initialize arrays
	g_models_assassin_player_1 = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_assassin_player_2 = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_assassin_player_3 = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_assassin_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ASSASIN_1", g_models_assassin_player_1)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ASSASIN_2", g_models_assassin_player_2)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ASSASIN_3", g_models_assassin_player_3)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ASSASSINO", g_models_assassin_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_assassin_player_1) == 0)
	{
		for (index = 0; index < sizeof models_assassin_player; index++)
			ArrayPushString(g_models_assassin_player_1, models_assassin_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ASSASIN_1", g_models_assassin_player_1)
	}
	if (ArraySize(g_models_assassin_player_2) == 0)
	{
		for (index = 0; index < sizeof models_assassin_player; index++)
			ArrayPushString(g_models_assassin_player_2, models_assassin_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ASSASIN_2", g_models_assassin_player_2)
	}
	if (ArraySize(g_models_assassin_player_3) == 0)
	{
		for (index = 0; index < sizeof models_assassin_player; index++)
			ArrayPushString(g_models_assassin_player_3, models_assassin_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ASSASIN_3", g_models_assassin_player_3)
	}
	if (ArraySize(g_models_assassin_claw) == 0)
	{
		for (index = 0; index < sizeof models_assassin_claw; index++)
			ArrayPushString(g_models_assassin_claw, models_assassin_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ASSASINO", g_models_assassin_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_assassin_player_1); index++)
	{
		ArrayGetString(g_models_assassin_player_1, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_assassin_player_2); index++)
	{
		ArrayGetString(g_models_assassin_player_2, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_assassin_player_3); index++)
	{
		ArrayGetString(g_models_assassin_player_3, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_assassin_claw); index++)
	{
		ArrayGetString(g_models_assassin_claw, index, model, charsmax(model))
		precache_model(model)
	}
}

public plugin_natives()
{
	register_library("zp50_class_assassin")
	register_native("zp_class_assassin_get", "native_class_assassin_get")
	register_native("zp_class_assassin_set", "native_class_assassin_set")
	register_native("zp_class_assassin_get_count", "native_class_assassin_get_count")
	
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
	flag_unset(g_IsAssassin, id)
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_ARREGEN)
	remove_task(id+TASK_HPREGEN)
	remove_task(id+TASK_ARHUD)
}

public Event_NewRound()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		flag_unset(g_IsAssassin, i)
		evolution = 0
	}
}

public event_damage(id, taskid)
{	
	if (!flag_get(g_IsAssassin, id))
		return;

	if (flag_get(g_IsAssassin, id))
	{
		new player_model[PLAYERMODEL_MAX_LENGTH]

		new damage = read_data(2)

		if(g_evolution[id] == 1 || g_evolution[id] == 2) evolution += damage / 15
		if(g_evolution[id] == 1 && evolution >= max_armor_1)
		{
			g_evolution[id] = 2
			evolution = 0
			set_user_health(id, get_user_health(id) + GetAliveCount() * get_pcvar_num(cvar_assassin_base_health_2))
			cs_set_user_armor(id, get_user_health(id) / 25, 1)
			set_user_maxspeed(id, 250.0)

			client_cmd(0, "spk sound/vz/Survivor_startup.wav")

			ArrayGetString(g_models_assassin_player_2, random_num(0, ArraySize(g_models_assassin_player_2) - 1), player_model, charsmax(player_model))
			cs_set_player_model(id, player_model)

			set_hudmessage(0, 255, 0, -1.0, 0.17, 1, 6.0, 3.0, 0.1, 0.2, -1)
			ShowSyncHudMsg(0, g_MsgSync, "G-2 Detected !!!")
		}
		if(g_evolution[id] == 2 && evolution >= max_armor_2)
		{
			g_evolution[id] = 3
			evolution = 0
			set_user_health(id, get_user_health(id) + GetAliveCount() * get_pcvar_num(cvar_assassin_base_health_3))
			cs_set_user_armor(id, get_user_health(id) / 25, 1)
			set_user_maxspeed(id, 260.0)

			client_cmd(0, "spk sound/vz/Survivor_startup.wav")

			ArrayGetString(g_models_assassin_player_3, random_num(0, ArraySize(g_models_assassin_player_3) - 1), player_model, charsmax(player_model))
			cs_set_player_model(id, player_model)

			set_hudmessage(0, 0, 255, -1.0, 0.17, 1, 6.0, 3.0, 0.1, 0.2, -1)
			ShowSyncHudMsg(0, g_MsgSync, "G-3 Detected !!!")
		}
	}
}

public armor_hud(id)
{
	id -= TASK_ARHUD
	if(is_user_alive(id))
	{
		set_hudmessage(0, 255, 0, 0.42, 0.9275, 0, 6.0, 1.1, 0.0, 0.0, -1)
		if(g_evolution[id] == 1)
		{
			new energy = evolution*100/max_armor_1
			if(0<=energy<10) ShowSyncHudMsg(0, g_MsgSync, "G1 [----------] %i%%", energy)
			else if(10<=energy<20) ShowSyncHudMsg(0, g_MsgSync, "G1 [|---------] %i%%", energy)
			else if(20<=energy<30) ShowSyncHudMsg(0, g_MsgSync, "G1 [||--------] %i%%", energy)
			else if(30<=energy<40) ShowSyncHudMsg(0, g_MsgSync, "G1 [|||-------] %i%%", energy)
			else if(40<=energy<50) ShowSyncHudMsg(0, g_MsgSync, "G1 [||||------] %i%%", energy)
			else if(50<=energy<60) ShowSyncHudMsg(0, g_MsgSync, "G1 [|||||-----] %i%%", energy)
			else if(60<=energy<70) ShowSyncHudMsg(0, g_MsgSync, "G1 [||||||----] %i%%", energy)
			else if(70<=energy<80) ShowSyncHudMsg(0, g_MsgSync, "G1 [|||||||---] %i%%", energy)
			else if(80<=energy<90) ShowSyncHudMsg(0, g_MsgSync, "G1 [||||||||--] %i%%", energy)
			else if(90<=energy<100) ShowSyncHudMsg(0, g_MsgSync, "G1 [|||||||||-] %i%%", energy)
			else ShowSyncHudMsg(0, g_MsgSync, "G1 [||||||||||] 100%")
		}
		if(g_evolution[id] == 2)
		{
			new energy = evolution*100/max_armor_2
			if(0<=energy<10) ShowSyncHudMsg(0, g_MsgSync, "G2 [----------] %i%%", energy)
			else if(10<=energy<20) ShowSyncHudMsg(0, g_MsgSync, "G2 [|---------] %i%%", energy)
			else if(20<=energy<30) ShowSyncHudMsg(0, g_MsgSync, "G2 [||--------] %i%%", energy)
			else if(30<=energy<40) ShowSyncHudMsg(0, g_MsgSync, "G2 [|||-------] %i%%", energy)
			else if(40<=energy<50) ShowSyncHudMsg(0, g_MsgSync, "G2 [||||------] %i%%", energy)
			else if(50<=energy<60) ShowSyncHudMsg(0, g_MsgSync, "G2 [|||||-----] %i%%", energy)
			else if(60<=energy<70) ShowSyncHudMsg(0, g_MsgSync, "G2 [||||||----] %i%%", energy)
			else if(70<=energy<80) ShowSyncHudMsg(0, g_MsgSync, "G2 [|||||||---] %i%%", energy)
			else if(80<=energy<90) ShowSyncHudMsg(0, g_MsgSync, "G2 [||||||||--] %i%%", energy)
			else if(90<=energy<100) ShowSyncHudMsg(0, g_MsgSync, "G2 [|||||||||-] %i%%", energy)
			else ShowSyncHudMsg(0, g_MsgSync, "G2 [||||||||||] 100%")
		}
		else if(g_evolution[id] == 3) ShowSyncHudMsg(0, g_MsgSync, "G3 [%i]", get_user_health(id))
	}
}

public health_increased(id)
{
	id -= TASK_HPREGEN
	if (!flag_get(g_IsAssassin, id))
		return;
	if(g_evolution[id] == 1) set_user_health(id, get_user_health(id) + 20)
	if(g_evolution[id] == 2) set_user_health(id, get_user_health(id) + 25)
	if(g_evolution[id] == 3) set_user_health(id, get_user_health(id) + 30)
}

public armor_increased(id)
{
	id -= TASK_ARREGEN
	if (!flag_get(g_IsAssassin, id))
		return;
	cs_set_user_armor(id, get_user_armor(id) + 7, 1)
	evolution += 7
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Assassin attacking human
	if (flag_get(g_IsAssassin, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore assassin damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set assassin damage(killing)
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_assassin_damage))
			//ExecuteHamB(Ham_Killed, victim, attacker, 0)
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsAssassin, victim))
	{
		// Assassin explodes!
		if (get_pcvar_num(cvar_assassin_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove assassin aura
		if (get_pcvar_num(cvar_assassin_aura))
			remove_task(victim+TASK_AURA)
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Assassin
	if (flag_get(g_IsAssassin, id) && !get_pcvar_num(cvar_assassin_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Assassin
	if (flag_get(g_IsAssassin, id) && !get_pcvar_num(cvar_assassin_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_user_humanized_post(id) 
{
	remove_task(id+TASK_ARREGEN)
	remove_task(id+TASK_HPREGEN)
	remove_task(id+TASK_ARHUD)
	g_evolution[id] = 0
	flag_unset(g_IsAssassin, id)
	set_user_maxspeed(id, 220.0)
}
public zp_user_infected_post(id)
{
	if (!flag_get(g_IsAssassin, id))
		return;

	set_task(1.0, "armor_increased", id+TASK_ARREGEN, _, _, "b")
	set_task(0.5, "health_increased", id+TASK_HPREGEN, _, _, "b")
	set_task(0.1, "armor_hud", id+TASK_ARHUD, _, _, "b")
	if (flag_get(g_IsAssassin, id)) g_evolution[id] = 1
	if (!flag_get(g_IsAssassin, id)) g_evolution[id] = 0
	set_user_maxspeed(id, 240.0)
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsAssassin, id))
	{
		// Remove assassin glow
		if (get_pcvar_num(cvar_assassin_glow))
			set_user_rendering(id)
		
		// Remove assassin aura
		if (get_pcvar_num(cvar_assassin_aura))
			remove_task(id+TASK_AURA)
		
		// Remove assassin flag
		flag_unset(g_IsAssassin, id)
	}
}
public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	if(flag_get(g_IsAssassin, id))
	{			
		return ZP_ITEM_DONT_SHOW;
	}
	//return HAM_IGNORED;
	return PLUGIN_CONTINUE
}
public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsAssassin, id))
	{
		// Remove assassin glow
		if (get_pcvar_num(cvar_assassin_glow))
			set_user_rendering(id)
		
		// Remove assassin aura
		if (get_pcvar_num(cvar_assassin_aura))
			remove_task(id+TASK_AURA)
		
		// Remove assassin flag
		flag_unset(g_IsAssassin, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply Assassin attributes?
	if (!flag_get(g_IsAssassin, id))
		return;

	// Set Evolution
	g_evolution[id] = 1

	// Health
	if (get_pcvar_num(cvar_assassin_health) == 0)
	{
		set_user_health(id, get_pcvar_num(cvar_assassin_base_health_1) * GetAliveCount())
		max_armor_1 = get_pcvar_num(cvar_assassin_base_health_1) * GetAliveCount() / 15
		max_armor_2 = get_pcvar_num(cvar_assassin_base_health_2) * GetAliveCount() / 15
	}
	else
	{
		set_user_health(id, get_pcvar_num(cvar_assassin_health))
		max_armor_1 = get_pcvar_num(cvar_assassin_health) / 15
		max_armor_2 = get_pcvar_num(cvar_assassin_health) / 15
	}
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_assassin_gravity))
	
	// Speed
	set_task(2.0,"velocidade",id)
	
	// Apply assassin player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	if(g_evolution[id] == 1) ArrayGetString(g_models_assassin_player_1, random_num(0, ArraySize(g_models_assassin_player_1) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply assassin claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_assassin_claw, random_num(0, ArraySize(g_models_assassin_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Assassin glow
	if (get_pcvar_num(cvar_assassin_glow))
		set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, 25)
	
	// Assassin aura task
	if (get_pcvar_num(cvar_assassin_aura))
		set_task(0.1, "assassin_aura", id+TASK_AURA, _, _, "b")
}
public velocidade(id)
{
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_assassin_speed))
}

public native_class_assassin_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsAssassin, id);
}

public native_class_assassin_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsAssassin, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a assassin (%d)", id)
		return false;
	}
	
	flag_set(g_IsAssassin, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_assassin_get_count(plugin_id, num_params)
{
	return GetAssassinCount();
}
public CmdStart( const id, const uc_handle, random_seed )
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	if(flag_get(g_IsAssassin, id))
		return FMRES_IGNORED;
		
	return FMRES_IGNORED
}
// Assassin aura task
public assassin_aura(taskid)
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
	write_byte(get_pcvar_num(cvar_assassin_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_assassin_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_assassin_aura_color_B)) // b
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

// Get Assassin Count -returns alive assassin number-
GetAssassinCount()
{
new iAssassin, id

for (id = 1; id <= g_MaxPlayers; id++)
{
	if (is_user_alive(id) && flag_get(g_IsAssassin, id))
		iAssassin++
	}
	
return iAssassin;
}