#include <amxmodx>
#include <fun>
#include <cstrike>
#include <zombieplague>

#define ZM_HP_PER_POINT 50

//#define TASK 12
//#define TASK1 13

//new g_MsgSync
//new shield[33]
public plugin_init()
{
	register_plugin("Health value's HUD", "1.0", "JonVigo")

	register_message(get_user_msgid("Health"), "Message_Health")

	//register_event("Damage","event_damage","b","2!0","3=0","4!0")

	//g_MsgSync = CreateHudSyncObj()
}
public zp_user_humanized_post(id) cs_set_user_armor(id, 200, 2)
public zp_user_infected_post(id) cs_set_user_armor(id, get_user_health(id) / 25, 1)
/*
public zp_user_humanized_post(id) shield[id] = 0
public zp_user_infected_post(id) shield[id] = 1000
public event_damage(id)
{
	new damage = read_data(2)
	if(damage >= shield[id])
	{
		set_user_health(id, get_user_health(id) + shield[id])
		shield[id] = 0
	}
	if(damage < shield[id])
	{
		set_user_health(id, get_user_health(id) + damage)
		shield[id] -= damage
	}
}	

public client_connect(id)
{
	set_task(0.1, "show", id+TASK, _, _, "b")
	//set_task(0.1, "shield_regen", id+TASK1, _, _, "b")
}

public client_disconnect(id)
{
	remove_task(id+TASK)
	//remove_task(id+TASK1)
}

public shield_regen(id)
{
	id -= TASK1
	if(zp_get_user_zombie(id))
	{
		if(shield[id] >= 999) shield[id] = 1000
		if(shield[id] < 999) shield[id] += 2
	}
}

public show(id)
{
	id -= TASK
	if(is_user_alive(id))
	{
		set_hudmessage(255, 255, 0, 0.02, 0.9275, 0, 6.0, 1.1, 0.0, 0.0, -1)
		//if(!zp_get_user_zombie(id)) ShowSyncHudMsg(id, g_MsgSync, "Health: %i", get_user_health(id))
		//if(zp_get_user_zombie(id)) ShowSyncHudMsg(id, g_MsgSync, "Health: %i (%i)", get_user_health(id), shield[id])
		ShowSyncHudMsg(id, g_MsgSync, "Health: %i", get_user_health(id))
	}
}
*/

public Message_Health(msg_id, msg_dest, id)
{
	static health
	health = get_user_health(id)
		
	if(zp_get_user_zombie(id))
	{
		if(health > ZM_HP_PER_POINT) set_msg_arg_int(1, get_msg_argtype(1), health/ZM_HP_PER_POINT)
		if(health <= ZM_HP_PER_POINT) set_msg_arg_int(1, get_msg_argtype(1), health/ZM_HP_PER_POINT+1)
	}
}