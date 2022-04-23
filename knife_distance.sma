#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

#include <xs>

#pragma semicolon 0

#define VERSION "1.1"

new Float:g_c_zombie_swing_range = 0.5,Float:g_c_zombie_stab_range = 1.4

public plugin_init() {
	register_plugin("Swing Range", VERSION, "m4m3ts")
	
	register_forward(FM_TraceLine, "fwTraceline")
	register_forward(FM_TraceHull, "fwTracehull", 1)
}

public fwTraceline(Float:fStart[3], Float:fEnd[3], conditions, id, ptr){
	return vTrace(id, ptr,fStart,fEnd,conditions)
}

public fwTracehull(Float:fStart[3], Float:fEnd[3], conditions, hull, id, ptr){
	return vTrace(id, ptr,fStart,fEnd,conditions,true,hull)
}

vTrace(id, ptr,Float:fStart[3],Float:fEnd[3],iNoMonsters,bool:hull = false,iHull = 0)
{	
	if(is_user_alive(id) && zp_get_user_zombie(id) && get_user_weapon(id) == CSW_KNIFE){
		static buttons
		buttons = pev(id, pev_button)
		
		new Float:scalar
		
		if (buttons & IN_ATTACK)
			scalar = g_c_zombie_swing_range
		else if (buttons & IN_ATTACK2)
			scalar = g_c_zombie_stab_range

		
		xs_vec_sub(fEnd,fStart,fEnd)
		xs_vec_mul_scalar(fEnd,scalar,fEnd);
		xs_vec_add(fEnd,fStart,fEnd);
		
		hull ? engfunc(EngFunc_TraceHull,fStart,fEnd,iNoMonsters,iHull,id,ptr) : engfunc(EngFunc_TraceLine,fStart,fEnd,iNoMonsters, id,ptr)
	}
	
	return FMRES_IGNORED;
}