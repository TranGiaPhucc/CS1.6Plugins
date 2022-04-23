#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "ATK System"
#define VERSION "1.0"
#define AUTHOR "Jonvigo"

#define TASKHUD 20
#define TASKSYS 13

new g_MsgSync, g_maxplayers
new atk[33], dmg[33]
new cvar_botquota, g_hamczbots
new cvar_atk_glow
new cvar_atk

public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR)

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")

	RegisterHam(Ham_TakeDamage, "player", "fw_damage")

	register_clcmd("atk_max","max_atk")

	cvar_atk = register_cvar("zp_atk","1")
	cvar_atk_glow = register_cvar("zp_atk_glow","0")
	cvar_botquota = get_cvar_pointer("bot_quota")

	g_MsgSync = CreateHudSyncObj()
	g_maxplayers = get_maxplayers()
}

public client_connect(id)
{
	dmg[id] = 0
	if(get_pcvar_num(cvar_atk) == 0)
	{
		atk[id] = 100
	}
	else atk[id] = 95
	
	if(is_user_bot(id) && !g_hamczbots && cvar_botquota) set_task(0.1, "register_ham_czbots", id)

	set_task(4.0, "system", id+TASKSYS, _, _, "b")
	set_task(1.0, "hud", id+TASKHUD, _, _, "b")
}

public client_disconnect(id)
{
	remove_task(id+TASKSYS)
	remove_task(id+TASKHUD)
}

public max_atk(id)
{
	if(atk[id] + 100 < 270) atk[id] = 270
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_connected(id) || !get_pcvar_num(cvar_botquota)) return
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_damage")
	
	g_hamczbots = true
}

public Event_NewRound()
{
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(is_user_bot(i)) atk[i] = 270
		else if(get_pcvar_num(cvar_atk) == 0)
			atk[i] = 95
		else atk[i] = 100
		dmg[i] = 0
	}
}

public system(id) 
{
	id -= TASKSYS
	if(get_pcvar_num(cvar_atk) == 1)
	{
		if(atk[id] < 270) atk[id] +=1
	}
}

public fw_damage(victim, inflictor, attacker, Float:damage)
{
	if(!zp_get_user_zombie(attacker) && !zp_get_user_nemesis(attacker) && !zp_get_user_survivor(attacker))
	{
		if(atk[attacker] < 270) dmg[attacker] += floatround(damage * atk[attacker]*10/1000)
		new attack = atk[attacker] * 10 / 10
		SetHamParamFloat(4, damage * attack/100)
		if(get_user_weapon(attacker) == CSW_P90 || get_user_weapon(attacker) == CSW_UMP45 || get_user_weapon(attacker) == CSW_MAC10 || get_user_weapon(attacker) == CSW_TMP || get_user_weapon(attacker) == CSW_MP5NAVY)
			SetHamParamFloat(4, damage * attack/85)
		if(get_user_weapon(attacker) == CSW_USP || get_user_weapon(attacker) == CSW_GLOCK18 || get_user_weapon(attacker) == CSW_ELITE || get_user_weapon(attacker) == CSW_FIVESEVEN)
			SetHamParamFloat(4, damage * attack/77)
		if(get_user_weapon(attacker) == CSW_M249 || get_user_weapon(attacker) == CSW_DEAGLE || get_user_weapon(attacker) == CSW_SG550 || get_user_weapon(attacker) == CSW_G3SG1 || get_user_weapon(attacker) == CSW_M3 || get_user_weapon(attacker) == CSW_XM1014)
			SetHamParamFloat(4, damage * attack/130)
	
		if(dmg[attacker] >= 300 && atk[attacker] < 270)
		{
			new a = dmg[attacker]/300
			dmg[attacker] -= a*300
			if(get_pcvar_num(cvar_atk) == 1)
			{
				if(atk[attacker]+a < 270) atk[attacker] += a
				else atk[attacker] = 270
			}
		} 
		
	}
	return HAM_IGNORED
}

public hud(id)
{
	id -= TASKHUD
	if(!zp_get_user_nemesis(id) && !zp_get_user_survivor(id) && !zp_get_user_zombie(id) && get_pcvar_num(cvar_atk) == 1)
	{
		if(is_user_alive(id))
		{
			if(80<=atk[id]<=100)
			{
				set_hudmessage(1000-10*atk[id], 255, 1000-10*atk[id], -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
				if(get_pcvar_num(cvar_atk_glow) == 1) set_user_rendering(id, kRenderFxGlowShell, 1000-10*atk[id], 255, 1000-10*atk[id], kRenderNormal, 25)
				//set_hudmessage(0, 0, 255, -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
				ShowSyncHudMsg(id, g_MsgSync, "[----------] %i%%", atk[id])
			}
			if(100<atk[id]<=270)
			{
				if(atk[id]<=185)
				{
					set_hudmessage(3*atk[id]-300, 255, 0, -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
					if(get_pcvar_num(cvar_atk_glow) == 1) set_user_rendering(id, kRenderFxGlowShell, 3*atk[id]-300, 255, 0, kRenderNormal, 25)
				}
				else if(atk[id]<=236)
				{
					set_hudmessage(255, 1180-5*atk[id], 0, -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
					if(get_pcvar_num(cvar_atk_glow) == 1) set_user_rendering(id, kRenderFxGlowShell, 255, 1180-5*atk[id], 0, kRenderNormal, 25)
				}
				else if(atk[id]<=270)
				{
					set_hudmessage(255, 0, 5*atk[id]-1180, -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
					if(get_pcvar_num(cvar_atk_glow) == 1) set_user_rendering(id, kRenderFxGlowShell, 255, 0, 5*atk[id]-1180, kRenderNormal, 25)
				}
				else
				{
					set_hudmessage(255, 0, 6*atk[id]-1620, -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
					if(get_pcvar_num(cvar_atk_glow) == 1) set_user_rendering(id, kRenderFxGlowShell, 255, 0, 6*atk[id]-1620, kRenderNormal, 25)
				}
				//set_hudmessage(255,255, 0, -1.0, 0.85, 0, 6.0, 1.1, 0.0, 0.0, -1)
		
				if(100<=atk[id]<117) ShowSyncHudMsg(id, g_MsgSync, "[----------] %i%%", atk[id])
				else if(117<=atk[id]<134) ShowSyncHudMsg(id, g_MsgSync, "[|---------] %i%%", atk[id])
				else if(134<=atk[id]<151) ShowSyncHudMsg(id, g_MsgSync, "[||--------] %i%%", atk[id])
				else if(151<=atk[id]<168) ShowSyncHudMsg(id, g_MsgSync, "[|||-------] %i%%", atk[id])
				else if(168<=atk[id]<185) ShowSyncHudMsg(id, g_MsgSync, "[||||------] %i%%", atk[id])
				else if(185<=atk[id]<202) ShowSyncHudMsg(id, g_MsgSync, "[|||||-----] %i%%", atk[id])
				else if(202<=atk[id]<219) ShowSyncHudMsg(id, g_MsgSync, "[||||||----] %i%%", atk[id])
				else if(219<=atk[id]<236) ShowSyncHudMsg(id, g_MsgSync, "[|||||||---] %i%%", atk[id])
				else if(236<=atk[id]<253) ShowSyncHudMsg(id, g_MsgSync, "[||||||||--] %i%%", atk[id])
				else if(253<=atk[id]<270) ShowSyncHudMsg(id, g_MsgSync, "[|||||||||-] %i%%", atk[id])
				else ShowSyncHudMsg(id, g_MsgSync, "[||||||||||] %i%%", atk[id])
			}
		}	
	}	
}