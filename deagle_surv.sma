#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Survivor Deagle + AK47"
#define VERSION "1.0"
#define AUTHOR "Jonvigo"


/*	Do NOT modify here unless you know what you are doing!		*/

new cvar_botquota, g_hamczbots
new g_deagle[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHam(Ham_TakeDamage, "player", "fw_damage")

	register_clcmd("/deagle", "get_deagle")

	cvar_botquota = get_cvar_pointer("bot_quota")
}

public client_connect(id)
{
	if(is_user_bot(id) && !g_hamczbots && cvar_botquota) set_task(0.1, "register_ham_czbots", id)
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_connected(id) || !get_pcvar_num(cvar_botquota)) return
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_damage")
	
	g_hamczbots = true
}

public zp_user_humanized_post(id)
{
	if(zp_get_user_survivor(id)) get_deagle(id)
	else g_deagle[id] = 0
}

public zp_user_infected_post(id) g_deagle[id] = 0
public get_deagle(id)
{	
	g_deagle[id] = 1
	give_item(id, "weapon_deagle")
	give_item(id, "weapon_ak47")
	cs_set_user_bpammo(id, CSW_DEAGLE, 1)
	cs_set_user_bpammo(id, CSW_AK47, 480)
}

public fw_damage(victim, inflictor, attacker, Float:damage)
{
	if(g_deagle[attacker] && zp_get_user_survivor(attacker))
	{
		if(get_user_weapon(attacker) == CSW_DEAGLE)
			SetHamParamFloat(4, damage * 4)
		if(get_user_weapon(attacker) == CSW_AK47)
			SetHamParamFloat(4, damage * 2)
		if(get_user_weapon(attacker) == CSW_KNIFE)
			SetHamParamFloat(4, damage * 15)
	}
	return HAM_IGNORED
}