#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Weapons Ammo"
#define VERSION "1.0"
#define AUTHOR "Jonvigo"

#define TASKHUD 10

new g_MsgSync

public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR)

	g_MsgSync = CreateHudSyncObj()
}

public client_putinserver(id) set_task(0.1, "hud", id+TASKHUD, _, _, "b")
public client_disconnect(id) remove_task(id+TASKHUD)
public zp_user_humanized_post(id)
{
	if(!is_user_bot(id))
	{
		cs_set_user_bpammo(id, CSW_GLOCK18, 750)
		cs_set_user_bpammo(id, CSW_USP, 750)
		cs_set_user_bpammo(id, CSW_P228, 130)
		cs_set_user_bpammo(id, CSW_FIVESEVEN, 800)
		cs_set_user_bpammo(id, CSW_DEAGLE, 105)
		cs_set_user_bpammo(id, CSW_M3, 96)
		cs_set_user_bpammo(id, CSW_GALIL, 600)
		cs_set_user_bpammo(id, CSW_AK47, 600)
		cs_set_user_bpammo(id, CSW_AWP, 40)
		cs_set_user_bpammo(id, CSW_M249, 1000)
	}
	else
	{
		cs_set_user_bpammo(id, CSW_GLOCK18, 1200)
		cs_set_user_bpammo(id, CSW_USP, 1200)
		cs_set_user_bpammo(id, CSW_P228, 130)
		cs_set_user_bpammo(id, CSW_FIVESEVEN, 1350)
		cs_set_user_bpammo(id, CSW_DEAGLE, 105)
		cs_set_user_bpammo(id, CSW_M3, 128)
		cs_set_user_bpammo(id, CSW_GALIL, 900)
		cs_set_user_bpammo(id, CSW_AK47, 900)
		cs_set_user_bpammo(id, CSW_AWP, 50)
		cs_set_user_bpammo(id, CSW_M249, 1500)
	}
}

public hud(id)
{
	id -= TASKHUD
	if(!is_user_alive(id))
		return;

	if (get_user_weapon(id) == CSW_KNIFE)
		return;
	
	new percent

	if (get_user_weapon(id) == CSW_GLOCK18 || get_user_weapon(id) == CSW_ELITE || get_user_weapon(id) == CSW_USP || get_user_weapon(id) == CSW_TMP || get_user_weapon(id) == CSW_MAC10 || get_user_weapon(id) == CSW_MP5NAVY || get_user_weapon(id) == CSW_UMP45)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 750
	if (get_user_weapon(id) == CSW_P228)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 130
	if (get_user_weapon(id) == CSW_DEAGLE)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 105
	if (get_user_weapon(id) == CSW_FIVESEVEN || get_user_weapon(id) == CSW_P90)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 800
	if(get_user_weapon(id) == CSW_M249)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 1000
	if (get_user_weapon(id) == CSW_M3 || get_user_weapon(id) == CSW_XM1014)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 96
	if (get_user_weapon(id) == CSW_GALIL || get_user_weapon(id) == CSW_FAMAS || get_user_weapon(id) == CSW_AK47 || get_user_weapon(id) == CSW_M4A1 || get_user_weapon(id) == CSW_SG552 || get_user_weapon(id) == CSW_SG550 || get_user_weapon(id) == CSW_AUG || get_user_weapon(id) == CSW_G3SG1 || get_user_weapon(id) == CSW_SCOUT)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 600
	if (get_user_weapon(id) == CSW_AWP)
		percent = cs_get_user_bpammo(id, get_user_weapon(id)) * 100 / 40
	

	set_hudmessage(200, 100, 0, 1.0 , 1.0, 0, 0.1, 0.1,0.1)
	//ShowSyncHudMsg(id, g_MsgSync, "Ammo: %i", cs_get_user_bpammo(id, get_user_weapon(id)))

	//if(0<=percent<5) ShowSyncHudMsg(id, g_MsgSync, "%i%% [--------------------]", percent)
	if(0<=percent<5) ShowSyncHudMsg(id, g_MsgSync, "%i [--------------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(5<=percent<10) ShowSyncHudMsg(id, g_MsgSync, "%i [|-------------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(10<=percent<15) ShowSyncHudMsg(id, g_MsgSync, "%i [||------------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(15<=percent<20) ShowSyncHudMsg(id, g_MsgSync, "%i [|||-----------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(20<=percent<25) ShowSyncHudMsg(id, g_MsgSync, "%i [||||----------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(25<=percent<30) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||---------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(30<=percent<35) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||--------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(35<=percent<40) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||-------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(40<=percent<45) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||------------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(45<=percent<50) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||||-----------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(50<=percent<55) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||||----------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(55<=percent<60) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||||||---------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(60<=percent<65) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||||||--------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(65<=percent<70) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||||||||-------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(70<=percent<75) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||||||||------]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(75<=percent<80) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||||||||||-----]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(80<=percent<85) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||||||||||----]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(85<=percent<90) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||||||||||||---]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(90<=percent<95) ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||||||||||||--]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else if(95<=percent<100) ShowSyncHudMsg(id, g_MsgSync, "%i [|||||||||||||||||||-]", cs_get_user_bpammo(id, get_user_weapon(id)))
	else ShowSyncHudMsg(id, g_MsgSync, "%i [||||||||||||||||||||]", cs_get_user_bpammo(id, get_user_weapon(id)))
}