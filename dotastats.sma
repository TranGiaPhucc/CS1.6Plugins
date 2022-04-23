#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <xs>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "Dota-like stats"
#define VERSION "1.0"
#define AUTHOR "Jonvigo"

/*	Do NOT modify here unless you know what you are doing!		*/

#define TASK 11

//new g_MaxPlayers
new dmg[33], require[33], bonus_health[33], dam[33]
new hp[33], ad[33], ar[33], lvl[33], d, r
new g_MsgSync, cvar_botquota, g_hamczbots

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

	register_event("Damage","event_damage","b","2!0","3=0","4!0")
	//register_event("HLTV", "event_newround", "a", "1=0", "2=0")

	//g_MaxPlayers = get_maxplayers()
	g_MsgSync = CreateHudSyncObj()

	register_clcmd("add_stats", "add_stats")

	cvar_botquota = get_cvar_pointer("bot_quota")
}

public event_damage(id)
{
	new attacker = get_user_attacker(id)

	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	dam[attacker] = read_data(2)

	if(!zp_get_user_zombie(attacker) || !zp_get_user_nemesis(attacker))
	{
		dmg[attacker] += read_data(2)
		if(dmg[attacker] >= require[attacker])
		{
			new rd
			new rn = random_num(2,4)
			hp[attacker] += rn
			switch(rn)
			{
				case 2: rd = random_num(3,4)
				case 3:
				{
					rd = random_num(2,3)
					if(rd == 3) rd = 4
				}
				case 4: rd = random_num(2,3)
			}
			ad[attacker] += rd
			ar[attacker] += 9-rn-rd
			require[attacker] += require[attacker]/5
			lvl[attacker] += 1
		}
	}
	return HAM_IGNORED
}

public add_stats(id)
{
	hp[id] += 10
	ad[id] += 10
	ar[id] += 10
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_hamczbots && cvar_botquota) set_task(0.1, "register_ham_czbots", id)
	set_task(0.1, "show", id+TASK, _, _, "b")
	hp[id] = 0
	ad[id] = 0
	ar[id] = 0
	dmg[id] = 0
	lvl[id] = 1
	require[id] = 1000
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_connected(id) || !get_pcvar_num(cvar_botquota)) return
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	
	g_hamczbots = true
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	d = ad[attacker] + 100
	r = ar[victim] + 100
	SetHamParamFloat(4, damage * d / r)

	//client_print(attacker, print_center, "%i (+%i) (-%i)", dam[attacker], ad[attacker]*3/4, armor[victim])
	return HAM_IGNORED
}

public zp_user_humanized_post(id)
{
	bonus_health[id] = hp[id]
	set_user_health(id, get_user_health(id) + bonus_health[id])
}

public zp_user_infected_post(id)
{
	bonus_health[id] = hp[id] * 9
	set_user_health(id, get_user_health(id) + bonus_health[id])
}

public show(id)
{
	id -= TASK
	if(is_user_alive(id))
	{
		set_hudmessage(255, 255, 0, 0.9, -0.15, 0, 6.0, 1.1, 0.0, 0.0, -1)	//-1.0(0.8725)
		ShowSyncHudMsg(id, g_MsgSync, "HP: %i^nAD: %i^nAR: %i^nLevel: %i  (%i%%)", hp[id], ad[id], ar[id],lvl[id],dmg[id]*100/require[id])
	}
	else return
}