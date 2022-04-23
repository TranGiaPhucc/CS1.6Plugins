#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>

#define PLUGIN "Ladder weapon block"
#define VERSION "0.7"
#define AUTHOR "Atrocraz"

new oldweapon[33], bool:g_blocked[33]

public plugin_init() 
	register_plugin(PLUGIN, VERSION, AUTHOR)

public client_PreThink(id)
{
	if(!is_user_alive(id))	return

	static movetype, weapon
	movetype = pev(id, pev_movetype)
	weapon = get_user_weapon(id)

	if(movetype != MOVETYPE_FLY)
	{
		if(g_blocked[id])
		{
			static Temp_String[28]
			get_weaponname(weapon, Temp_String, 27)
			static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, Temp_String, id)
			if(pev_valid(weapon_ent))	ExecuteHam(Ham_Item_Deploy, weapon_ent)
			g_blocked[id] = false
		}else return
	}
	
	if(weapon != oldweapon[id])
	{
		set_pev(id, pev_viewmodel2, "")
		set_pev(id, pev_weaponmodel2, "")
		oldweapon[id] = weapon
	}

	if(!g_blocked[id])
	{
		new name[1]
		find_sphere_class(id, "func_ladder", 18.0, name, 1)
		if(name[0] != 0)
		{
			set_pev(id, pev_viewmodel2, "")
			set_pev(id, pev_weaponmodel2, "")
			set_pdata_float(id, 83, 999.9, 5)
			g_blocked[id] = true
		}
	}
}
	