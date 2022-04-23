/*
	================================================
	Counter-Strike Weapons System Mod v1.4.3 [CSWS1]
	================================================
	2017
	
	This source code falls under the GNU General Public License.
	(https://www.gnu.org/licenses/gpl-3.0.en.html)
	
	Additionally, you are allowed to modify, improve or build
	upon the code but under NO circumstances are you allowed to
	sell, trade, or receive any compensation for the source code
	whatsoever and should freely share said code to anyone,
	modified or otherwise.
	
	Description:
	============
	The CSWS script is built upon the endeavor
	of adding an extra weapon that behaves like
	a real CS 1.6 weapon in every way while
	providing optimum performance. If you want
	to improve the code feel free to do so and
	share it with everyone.
	
	Credits:
	========
	Sneaky.amxx	- original weapons code
	dias		- original weapons code
	MeRcyLeZZ	- price mechanic
	Arkshine	- HUD sprites replacement
	HamletEagle	- optimization
	edon1337	- optimization
*/

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#define DAMAGE 18
#define CLIP 64
#define BPAMMO 900
#define RATEOFIRE 0.98
#define RECOIL 1.5
#define RELOAD_TIME 2.4
#define RELOAD_POINT 1.4
#define WALKSPEED 240.0
#define PRICE 1400
#define BASEWPN_PRICE 1500
//#define BOT_BUY_CHANCE 2

#define SHOOT_ANIM random_num(3, 5)
#define DRAW_ANIM 2
#define RELOAD_ANIM 1
#define INSPECT_ANIM 6
#define BODY_NUM 0

#define WEAPON_SECRETCODE 296154

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new const PLUGIN[]	= "CS:GO PP-19 Bizon";
new const VERSION[] 	= "2.14.1";
new const CSWS_VER[] 	= "1.4.3";
new const DATE[] 	= "1 December 2017";

new const P_MODEL[] 	= "models/csgo_ports/bizon/p_bizon.mdl";
new const W_MODEL[] 	= "models/csgo_ports/bizon/w_bizon.mdl";
new const V_MODEL[] 	= "models/csgo_ports/bizon/v_bizon.mdl";
new const V_MODEL_ALT[]	= "models/csgo_ports/bizon/alt/v_bizon.mdl";

new const CSW_NEWPN = CSW_MP5NAVY;
new const weapon_newpn[] = "weapon_mp5navy";
new const WEAPON_EVENT[] = "events/mp5n.sc";
new const BASE_W_MODEL[] = "models/w_mp5.mdl";
new const FIRE_SOUND[] = "weapons/csgo_ports/bizon/bizon-1.wav";

new const NEWPN_NAME[] 	= "weapon_bizon";
new const PRI_AMMO_ID 	= 10;
new const SLOT_ID 	= 0;
new const NUM_IN_SLOT 	= 7;
new const ITEM_FLAGS 	= 0;

new const newpn_shortname[] 	= "bizon";
new const basewpn_shortname[] 	= "mp5navy";
new const basewpn_buynames[][] 	= {"mp5", "smg"}

new const weapon_classnames[][] =
{
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_galil",
	"weapon_famas",
	"weapon_sg552",
	"weapon_aug",
	"weapon_p90",	
	"weapon_mac10",
	"weapon_tmp",
	"weapon_scout",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_g3sg1",
	"weapon_sg550",
	"weapon_m249"
}

new const weapon_sprites[][] =
{
	"sprites/weapon_bizon.txt",
	"sprites/640csws01.spr",
	"sprites/640csws01_s.spr"
}

new Float:g_idletime[] =
{
	0.7,	// 0 draw
	2.6,	// 1 reload
	0.6,	// 2 shoot
	3.7	// 3 inspect
}

const m_pPlayer 		= 41;
const m_flNextPrimaryAttack  	= 46;
const m_flTimeWeaponIdle	= 48;
const m_iClip 			= 51;
const m_fInReload		= 54;
const m_flNextAttack		= 83;
const m_pActiveItem 		= 373;

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|
(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|
(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);

new g_hambot, g_has_weapon, g_weapon_event, g_buytime_expire, g_rebuy[32], g_restart_round;
new Float:g_recoil[33][3], g_clip[33], g_prev_weapon[33], shell_model, smoke_sprite;
new cvar_bot_allow_wpns, cvar_freezetime, cvar_buytime, cvar_decals, cvar_alteam;
new msg_Money, msg_BlinkAcct, msg_WeaponList;

new TASKID_BUYTIME = 100000;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Sneaky.amxx, dias, MeRcyLeZZ, Arkshine, hellmonja");
	
	//register_event("TextMsg", "Game_Commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event("HLTV", "Event_New_Round", "a", "1=0", "2=0");
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg");
	
	register_forward(FM_UpdateClientData, "Fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent, "Fw_PlaybackEvent");
	register_forward(FM_SetModel, "Fw_SetModel");
	
	RegisterHam(Ham_Item_Deploy, weapon_newpn, "Fw_ItemDeployPost", 1);
	RegisterHam(Ham_AddPlayerItem, "player", "Fw_AddItem");
	RegisterHam(Ham_RemovePlayerItem, "player", "Fw_RemoveItem");
	RegisterHam(Ham_TraceAttack, "worldspawn", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_breakable", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_wall", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_door", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_plat", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_rotating", "Fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "player", "Fw_TraceAttack_Player");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_newpn, "Fw_Weapon_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_newpn, "Fw_Weapon_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_newpn, "Fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_newpn, "Fw_Item_PostFrame");
	RegisterHam(Ham_Weapon_Reload, weapon_newpn, "Fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_newpn, "Fw_Weapon_Reload_Post", 1);
	RegisterHam(Ham_CS_Item_GetMaxSpeed, weapon_newpn, "Player_Weapon_Walkspeed");
	RegisterHam(Ham_Killed, "player", "Fw_Player_Death");
	
	msg_WeaponList 	= get_user_msgid("WeaponList");  
	msg_Money 	= get_user_msgid("Money");
	msg_BlinkAcct 	= get_user_msgid("BlinkAcct");
	
	new clcmd[24]; formatex(clcmd, 25, "say %s", newpn_shortname);
	for(new i = 0; i < sizeof basewpn_buynames - 1; i++)
		register_clcmd(basewpn_buynames[i], "ClientCommand_BuyBaseWpn");
	
	register_clcmd(clcmd, "Get_Weapon");
	register_clcmd("give_bizon", "Get_Weapon", ADMIN_BAN);
	register_clcmd(NEWPN_NAME, "ClientCommand_SelectWeapon");
	register_clcmd("inspect", "Inspect_Weapon");
	register_concmd("inspect", "Inspect_Weapon");
	register_concmd("repurchase", "ClientCommand_RePurchase");
	register_concmd(newpn_shortname, "Get_Weapon");
	register_concmd("ver_bizon", "Code_Version");
	
	//CVARS
	cvar_freezetime = get_cvar_pointer("mp_freezetime");
	cvar_buytime = get_cvar_pointer("mp_buytime");
	cvar_bot_allow_wpns = get_cvar_pointer("bot_allow_sub_machine_guns");
	cvar_alteam = register_cvar("armsw_team", "1");
	cvar_decals = register_cvar("csws_decals", "0");
}

public plugin_precache()
{
	for(new i = 1; i < sizeof weapon_sprites; i++)
		precache_generic(weapon_sprites[i]);
	
	precache_model(P_MODEL);
	precache_model(W_MODEL);
	precache_model(V_MODEL);
	precache_model(V_MODEL_ALT);
	precache_sound(FIRE_SOUND);
	
	smoke_sprite = engfunc(EngFunc_PrecacheModel, "sprites/gunsmoke.spr");
	shell_model = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")
	
	register_forward(FM_PrecacheEvent, "Fw_PrecacheEvent_Post", 1);
}

public Code_Version(id)
{
	console_print(id, "==============================");
	console_print(id, "%s v%s", PLUGIN, VERSION);
	console_print(id, "Counter-Strike Weapons System v%s", CSWS_VER);
	console_print(id, "%s", DATE);
	console_print(id, "==============================");
}

public Fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_weapon_event = get_orig_retval();
}

public client_putinserver(id)
{
	if(!g_hambot && is_user_bot(id))
	{
		g_hambot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "Fw_TraceAttack_Player");
	RegisterHamFromEntity(Ham_AddPlayerItem, id, "Fw_AddItem", 1);
	RegisterHamFromEntity(Ham_RemovePlayerItem, id, "Fw_RemoveItem", 1);
	RegisterHamFromEntity(Ham_Killed, id, "Fw_Player_Death");
}

public Game_Commencing()
{
	g_restart_round = 1;
}

public Event_New_Round()
{
	new freezetime = get_pcvar_num(cvar_freezetime);
	new buytime = floatround((get_pcvar_float(cvar_buytime) * 60));
	new Float:t;
	
	g_buytime_expire = 0;
		
	if(g_restart_round)
	{
		Remove_Weapon(0, 1);
		g_restart_round = 0;
	}

	remove_task(TASKID_BUYTIME);
	
	if(get_pcvar_num(cvar_bot_allow_wpns) && g_buytime_expire == 0)
		set_task(1.5, "Bot_Weapon");
	
	if(buytime > freezetime)
		t = float(buytime);
	else
		t = float(buytime+freezetime);
	
	set_task(t, "Buytime_Expired", TASKID_BUYTIME);
}

public Buytime_Expired()
{
	g_buytime_expire = 1;
}

/*
public Bot_Weapon()
{
	new players[32], pnum, wpn_id;
	get_players(players, pnum, "ad");
	
	for(new i = 0; i < pnum; i++)
		if(random_num(1,100) <= BOT_BUY_CHANCE && get_user_armor(players[i]) != 99 && !is_weapon_slot_empty(players[i], 1, wpn_id) && !Get_BitVar(g_has_weapon, players[i]))
		{	
			Get_Weapon(players[i]);
			cs_set_user_armor(players[i], 99, CS_ARMOR_VESTHELM);
		}
}
*/

public ClientCommand_BuyBaseWpn(id)
{
	if(purchase_check(id, BASEWPN_PRICE) && Get_BitVar(g_has_weapon, id))
	{
		drop_weapons(id);
		UnSet_BitVar(g_has_weapon,id);
		g_rebuy[id] = 0;
	}
}

public ClientCommand_RePurchase(id)
{
	if(g_rebuy[id] == 1 && !Get_BitVar(g_has_weapon, id))
		Get_Weapon(id);
	
	if(is_plugin_loaded("Weapon Price Editor", false) <= 0)
		client_cmd(id, "rebuy");
}

public zp_user_humanized_post(id)
{
	if(!zp_get_user_survivor(id))
	{
		new random = random_num(1,100)
		if(random <= 20) Get_Weapon(id)
	}
}

public Get_Weapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return

	// Player tries to buy the same gun
	if(Get_BitVar(g_has_weapon, id))
	{
		//client_print(id, print_center, "#Cstrike_Already_Own_Weapon");
		return
	}

	//if(purchase_check(id, PRICE))
	//{
	if(cs_get_user_shield(id))
	{
		engclient_cmd(id, "slot1");
		engclient_cmd(id, "drop");
	}
	else
		drop_weapons(id);
		
	Set_BitVar(g_has_weapon, id);
	g_rebuy[id] = 1;
	new weapon = give_item(id, weapon_newpn);
		
	// Set Ammo
	cs_set_weapon_ammo(weapon, CLIP);
	cs_set_user_bpammo(id, CSW_NEWPN, BPAMMO);
	
	/*// Calculate new money amount
	static newmoney;
	newmoney = cs_get_user_money(id) - PRICE;
	
	// Update money offset
	cs_set_user_money(id, newmoney);
	
	// Update money on HUD
	message_begin(MSG_ONE, msg_Money, _, id);
	write_long(newmoney); 	// amount
	write_byte(1); 		// flash
	message_end();
	}*/
}

public ClientCommand_SelectWeapon(id)
{  
	engclient_cmd(id, weapon_newpn);
	return PLUGIN_HANDLED
} 

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	static CSW_ID; CSW_ID = read_data(2);
	static weapon; weapon= find_ent_by_owner(-1, weapon_newpn, id);

	if((CSW_ID == CSW_NEWPN && g_prev_weapon[id] == CSW_NEWPN) && Get_BitVar(g_has_weapon, id))
	{
		if(!pev_valid(weapon))
		{
			g_prev_weapon[id] = get_user_weapon(id)
			return
		}
		set_pdata_float(weapon, m_flNextPrimaryAttack, get_pdata_float(weapon, m_flNextPrimaryAttack, 4) * RATEOFIRE, 4)
	}
	else if((CSW_ID != CSW_NEWPN && g_prev_weapon[id] == CSW_NEWPN) && Get_BitVar(g_has_weapon, id))
		draw_new_weapon(id, get_user_weapon(id));
		
	g_prev_weapon[id] = get_user_weapon(id);
}

public Fw_ItemDeployPost(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, 4);
	
	if(!is_user_alive(id))
		return
		
	if(Get_BitVar(g_has_weapon, id))
		arm_switch(id);
}

public Fw_AddItem(id, weapon)
{
	static classname[24];
	pev(weapon, pev_classname, classname, charsmax(classname));

	if(!Get_BitVar(g_has_weapon,id) && g_rebuy[id] == 1)
	{
		for(new i = 0; i < sizeof weapon_classnames; i++)
			if(equali(classname, weapon_classnames[i]))
			{
				g_rebuy[id] = 0;
				return
			}
	}
	else if(equali(classname, weapon_newpn) && Get_BitVar(g_has_weapon,id))
		g_rebuy[id] = 1;
}

public Fw_RemoveItem(id)
{
	set_task(0.01, "Fw_AddItem", id);
}

public Fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED

	if(get_user_weapon(id) == CSW_NEWPN && Get_BitVar(g_has_weapon, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public Fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED
		
	if(get_user_weapon(invoker) != CSW_NEWPN || !Get_BitVar(g_has_weapon, invoker))
		return FMRES_IGNORED
		
	if(eventid != g_weapon_event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
	set_weapon_anim(invoker, SHOOT_ANIM);
	emit_sound(invoker, CHAN_WEAPON, FIRE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	make_shell(invoker);
	
	return FMRES_SUPERCEDE
}

public Fw_SetModel(wpn_ent, model[])
{
	if(!pev_valid(wpn_ent))
		return FMRES_IGNORED
	
	static classname[32];
	pev(wpn_ent, pev_classname, classname, sizeof classname);
	
	if(!equal(classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id;
	id= pev(wpn_ent, pev_owner);
	
	if(equal(model, BASE_W_MODEL))
	{
		static weapon;
		weapon = find_ent_by_owner(-1, weapon_newpn, wpn_ent);

		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_has_weapon, id))
		{
			UnSet_BitVar(g_has_weapon,id)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, wpn_ent, W_MODEL)
			set_pev(wpn_ent, pev_body, BODY_NUM)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public Fw_TraceAttack_World(victim, attacker, Float:damage, Float:direction[3], prt, damage_bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED
		
	if(get_user_weapon(attacker) != CSW_NEWPN || !Get_BitVar(g_has_weapon, attacker))
		return HAM_IGNORED
		
	static Float:origin[3], Float:vecPlane[3];
	
	get_tr2(prt, TR_vecEndPos, origin);
	get_tr2(prt, TR_vecPlaneNormal, vecPlane);
	
	make_bullet_hole(victim, attacker, origin);
	make_bullet_smoke(attacker, prt);

	SetHamParamFloat(3, float(DAMAGE));
	
	return HAM_IGNORED
}

public Fw_TraceAttack_Player(victim, attacker, Float:damage, Float:direction[3], ptr, damage_bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED
		
	if(get_user_weapon(attacker) != CSW_NEWPN || !Get_BitVar(g_has_weapon, attacker))
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE))

	return HAM_IGNORED
}

public Fw_Weapon_PrimaryAttack(weapon)
{
	static id;
	id = pev(weapon, pev_owner);
	pev(id, pev_punchangle, g_recoil[id]);
	
	return HAM_IGNORED
}

public Fw_Weapon_PrimaryAttack_Post(weapon)
{
	static id;
	id = pev(weapon, pev_owner);
	
	if(Get_BitVar(g_has_weapon, id))
	{
		static Float:Push[3]
		pev(id, pev_punchangle, Push);
		xs_vec_sub(Push, g_recoil[id], Push);
		
		xs_vec_mul_scalar(Push, RECOIL, Push);
		xs_vec_add(Push, g_recoil[id], Push);
		set_pev(id, pev_punchangle, Push);
		
		set_pdata_float(weapon, m_flTimeWeaponIdle, g_idletime[2], 4);
	}
}

public Fw_Item_AddToPlayer_Post(weapon, id)
{
	if(!pev_valid(weapon))
		return HAM_IGNORED
		
	if(pev(weapon, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_has_weapon, id);
		set_pev(weapon, pev_impulse, 0);
		g_rebuy[id] = 1;
	}

	if(Get_BitVar(g_has_weapon,id))
	{
		message_begin(MSG_ONE, msg_WeaponList, .player = id);
		write_string(NEWPN_NAME); 	// WeaponName  
		write_byte(PRI_AMMO_ID);	// PrimaryAmmoID
		write_byte(BPAMMO);		// PrimaryAmmoMaxAmount  
		write_byte(-1);			// SecondaryAmmoID  
		write_byte(-1);			// SecondaryAmmoMaxAmount  
		write_byte(SLOT_ID);		// SlotID (0...N)  
		write_byte(NUM_IN_SLOT);	// NumberInSlot (1...N)  
		write_byte(CSW_NEWPN);  	// WeaponID  
		write_byte(ITEM_FLAGS);		// Flags  
		message_end();
	} else {
		message_begin(MSG_ONE, msg_WeaponList, .player = id);
		write_string(weapon_newpn); 	// WeaponName  
		write_byte(PRI_AMMO_ID);	// PrimaryAmmoID
		write_byte(BPAMMO);		// PrimaryAmmoMaxAmount  
		write_byte(-1);			// SecondaryAmmoID  
		write_byte(-1);			// SecondaryAmmoMaxAmount  
		write_byte(SLOT_ID);		// SlotID (0...N)  
		write_byte(NUM_IN_SLOT);	// NumberInSlot (1...N)  
		write_byte(CSW_NEWPN);		// WeaponID  
		write_byte(ITEM_FLAGS);		// Flags  
		message_end();
	}
	
	return HAM_HANDLED	
}

public Fw_Item_PostFrame(weapon)
{
	if(!pev_valid(weapon))
		return HAM_IGNORED
	
	static id
	id = pev(weapon, pev_owner)
	
	if(is_user_alive(id) && Get_BitVar(g_has_weapon, id))
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, m_flNextAttack, 5);
		static bpammo; bpammo = cs_get_user_bpammo(id, CSW_NEWPN);
		static i_clip; i_clip = get_pdata_int(weapon, m_iClip, 4);
		static fInReload; fInReload = get_pdata_int(weapon, m_fInReload, 4);
		
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1; temp1 = min(CLIP - i_clip, bpammo);

			set_pdata_int(weapon, m_iClip, i_clip + temp1, 4);
			cs_set_user_bpammo(id, CSW_NEWPN, bpammo - temp1);
			
			set_pdata_int(weapon, m_fInReload, 0, 4);
			
			fInReload = 0;
			
			set_pdata_float(weapon, m_flNextPrimaryAttack, RELOAD_TIME - RELOAD_POINT, 4);
		}		
	}
	
	return HAM_IGNORED	
}

public Fw_Weapon_Reload(weapon)
{
	static id; id = pev(weapon, pev_owner);
	
	if(!is_user_alive(id))
		return HAM_IGNORED
		
	if(!Get_BitVar(g_has_weapon, id))
		return HAM_IGNORED
	
	g_clip[id] = -1;
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_NEWPN);
	static i_clip; i_clip = get_pdata_int(weapon, m_iClip, 4);
	
	if(bpammo <= 0)
		return HAM_SUPERCEDE
	
	if(i_clip >= CLIP)
		return HAM_SUPERCEDE		
		
	g_clip[id] = i_clip;

	return HAM_HANDLED
}

public Fw_Weapon_Reload_Post(weapon)
{
	static id;
	id = pev(weapon, pev_owner);
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	if(!Get_BitVar(g_has_weapon, id))
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(weapon, m_iClip, g_clip[id], 4);
	set_pdata_int(weapon, m_fInReload, 1, 4);
	
	set_weapon_anim(id, RELOAD_ANIM);
	set_pdata_float(id, m_flNextAttack, RELOAD_POINT, 5);

	return HAM_HANDLED
}

public Fw_Player_Death(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED
	
	if(Get_BitVar(g_has_weapon, id))
	{
		set_task(0.1, "Remove_Weapon", id);
		g_rebuy[id] = 1;
	}
	
	return HAM_HANDLED
}

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static attacker, weapon[33];
	
	attacker = get_msg_arg_int(1);
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(!is_user_connected(attacker))
		return PLUGIN_CONTINUE
        
	if(equal(weapon, basewpn_shortname) && Get_BitVar(g_has_weapon, attacker))
		set_msg_arg_string(4, newpn_shortname);
	
	return PLUGIN_CONTINUE
}

public Player_Weapon_Walkspeed(weapon)
{
	new id = get_pdata_cbase(weapon, m_pPlayer, 4);
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	if(Get_BitVar(g_has_weapon,id))
		SetHamReturnFloat(WALKSPEED);
	else
		return HAM_IGNORED

	return HAM_SUPERCEDE
}

public Inspect_Weapon(id)
{
	if(!is_user_alive(id))
		return

	if(!Get_BitVar(g_has_weapon, id))
		return
	
	if(get_user_weapon(id) != CSW_NEWPN)
		return
		
	static weapon; weapon = get_pdata_cbase(id, m_pActiveItem);
	new current_anim = pev(get_pdata_cbase(weapon, m_pPlayer, 4), pev_weaponanim);
	
	if(!current_anim)
		set_weapon_anim(id, INSPECT_ANIM);
}

public Remove_Weapon(id, all)
{
	switch(all)
	{
		case 1:
		{
			new players[32], pnum;
			get_players(players, pnum, "a");
	
			for(new i = 0; i <= pnum; i++)
				UnSet_BitVar(g_has_weapon, players[i]);
		}
		default:
			UnSet_BitVar(g_has_weapon, id);
	}
}

bool:purchase_check(id, cost)
{
	if (!cs_get_user_buyzone(id))
		return false
	
	// Check for buy time
	if(g_buytime_expire)
	{
		client_print(id, print_center, "%d seconds have passed.^n You can't buy anything now!",floatround(get_cvar_float("mp_buytime") * 60));
		return false
	}
	
	// Check if player has enough money
	if (cs_get_user_money(id) < cost)
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money");
		
		// Blink money
		message_begin(MSG_ONE_UNRELIABLE, msg_BlinkAcct, _, id);
		write_byte(2); // times
		message_end();
		return false
	}
	return true
}

draw_new_weapon(id, CSW_ID)
{
	static weapon;
	weapon = find_ent_by_owner(-1, weapon_newpn, id);

	if(CSW_ID == CSW_NEWPN)
	{
		if(pev_valid(weapon) && Get_BitVar(g_has_weapon, id))
		{
			set_pev(weapon, pev_effects, pev(weapon, pev_effects) &~ EF_NODRAW);
			engfunc(EngFunc_SetModel, weapon, P_MODEL);
			set_pev(weapon, pev_body, BODY_NUM);
		}
	}
	else
		if(pev_valid(weapon))
			set_pev(weapon, pev_effects, pev(weapon, pev_effects) | EF_NODRAW);
}

make_bullet_smoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG;
	
	get_weapon_attachment(id, vecSrc);
	global_get(glb_v_forward, vecEnd);
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecEnd);

	get_tr2(TrResult, TR_vecEndPos, vecSrc);
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd);
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecEnd);
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS;
	TE_FLAG |= TE_EXPLFLAG_NOSOUND;
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES;
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0);
	write_short(smoke_sprite);
	write_byte(5);
	write_byte(50);
	write_byte(TE_FLAG);
	message_end();
}

make_bullet_hole(victim, attacker, Float:origin[3])
{
	static decal;

	if(!get_pcvar_num(cvar_decals))
		decal = random_num(41, 43);
	else
		decal = random_num(52, 55);
		
	if(victim)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord, origin[1])
		engfunc(EngFunc_WriteCoord, origin[2])
		write_byte(decal)
		write_short(victim)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord, origin[1])
		engfunc(EngFunc_WriteCoord, origin[2])
		write_byte(decal)
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(attacker)
	write_byte(decal)
	message_end()
}

make_shell(id)
{
	static Float:player_origin[3], Float:origin[3], Float:origin2[3], Float:gunorigin[3], Float:oldangles[3], Float:v_forward[3], Float:v_forward2[3], Float:v_up[3], Float:v_up2[3], Float:v_right[3], Float:v_right2[3], Float:viewoffsets[3];
	
	pev(id,pev_v_angle, oldangles); pev(id,pev_origin,player_origin); pev(id, pev_view_ofs, viewoffsets);

	engfunc(EngFunc_MakeVectors, oldangles)
	
	global_get(glb_v_forward, v_forward); global_get(glb_v_up, v_up); global_get(glb_v_right, v_right);
	global_get(glb_v_forward, v_forward2); global_get(glb_v_up, v_up2); global_get(glb_v_right, v_right2);
	
	xs_vec_add(player_origin, viewoffsets, gunorigin);
	
	xs_vec_mul_scalar(v_forward, 10.3, v_forward); xs_vec_mul_scalar(v_right, 2.9, v_right);
	xs_vec_mul_scalar(v_up, -3.7, v_up);
	xs_vec_mul_scalar(v_forward2, 10.0, v_forward2); xs_vec_mul_scalar(v_right2, 3.0, v_right2);
	xs_vec_mul_scalar(v_up2, -4.0, v_up2);
	
	xs_vec_add(gunorigin, v_forward, origin);
	xs_vec_add(gunorigin, v_forward2, origin2);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin2, v_right2, origin2);
	xs_vec_add(origin, v_up, origin);
	xs_vec_add(origin2, v_up2, origin2);

	static Float:velocity[3]
	get_speed_vector(origin2, origin, random_float(140.0, 160.0), velocity)

	static angle; angle = random_num(0, 360)

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2])
	engfunc(EngFunc_WriteCoord,velocity[0])
	engfunc(EngFunc_WriteCoord,velocity[1])
	engfunc(EngFunc_WriteCoord,velocity[2])
	write_angle(angle)
	write_short(shell_model)
	write_byte(1)
	write_byte(20)
	message_end()
}

get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] ;
	get_user_origin(id, viEnd, 3);
	IVecFVec(viEnd, vfEnd);
	
	static Float:fOrigin[3], Float:fAngle[3];
	
	pev(id, pev_origin, fOrigin);
	pev(id, pev_view_ofs, fAngle);
	
	xs_vec_add(fOrigin, fAngle, fOrigin);
	
	static Float:fAttack[3];
	
	xs_vec_sub(vfEnd, fOrigin, fAttack);
	xs_vec_sub(vfEnd, fOrigin, fAttack);
	
	static Float:fRate;
	
	fRate = fDis / vector_length(fAttack);
	xs_vec_mul_scalar(fAttack, fRate, fAttack);
	
	xs_vec_add(fOrigin, fAttack, output);
}

set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();
	
	static weapon;
	weapon = find_ent_by_owner(-1, weapon_newpn, id);
	
	new Float:idle;
	switch(anim)
	{
		case DRAW_ANIM:	   idle = g_idletime[0];
		case RELOAD_ANIM:  idle = g_idletime[1];
		case INSPECT_ANIM: idle = g_idletime[3];
	}
	
	set_pdata_float(weapon, m_flTimeWeaponIdle, idle, 4);
}

// Drop primary/secondary weapons
drop_weapons(id)
{
	// Get user weapons
	static weapons[32], num, i, wpn_id;
	num = 0; 	// reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num);
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		wpn_id = weapons[i];
		
		if(1<<wpn_id & PRIMARY_WEAPONS_BIT_SUM)
		{
			// Get weapon entity
			static wname[32];
			get_weaponname(wpn_id, wname, charsmax(wname));

			// Player drops the weapon
			engclient_cmd(id, "drop", wname);
		}
	}
}

arm_switch(id)
{
	if(get_user_team(id) == get_pcvar_num(cvar_alteam))
		set_pev(id, pev_viewmodel2, V_MODEL_ALT);
	else
		set_pev(id, pev_viewmodel2, V_MODEL);
	
	set_pev(id, pev_weaponmodel2, P_MODEL)
	set_weapon_anim(id, DRAW_ANIM)
	draw_new_weapon(id, CSW_NEWPN)
}

is_weapon_slot_empty( id , iSlot , &iEntity )
{
	if ( !( 1 <= iSlot <= 5 ) )
		return 0;
    
	iEntity = 0;
	const m_rgpPlayerItems_Slot0 = 367;
	const m_iId = 43;
	const EXTRAOFFSET_WEAPONS = 4;
    
	iEntity = get_pdata_cbase( id , m_rgpPlayerItems_Slot0 + iSlot , EXTRAOFFSET_WEAPONS );
    
	return ( iEntity > 0 ) ? get_pdata_int( iEntity , m_iId , EXTRAOFFSET_WEAPONS ) : 0;
}
