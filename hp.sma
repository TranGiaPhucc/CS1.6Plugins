#include <amxmodx>
#include <fun>
#include <cstrike>

public plugin_init()
{
	register_plugin("Show Victim HP On Damage", "1.0", "JonVigo")
	register_event("Damage","event_damage","b","2!0","3=0","4!0")
}
public event_damage(id)
{
	new attacker = get_user_attacker(id)
	new damage = read_data(2)
	client_print(attacker,print_center,"HP:%i %i AP:%i",get_user_health(id),damage,get_user_armor(id))
	client_print(id,print_center,"HP:%i %i AP:%i",get_user_health(id),damage,get_user_armor(id))
	set_user_armor(id, get_user_armor(id) + damage / 4)
	set_user_armor(attacker, get_user_armor(attacker) + damage / 16)
}