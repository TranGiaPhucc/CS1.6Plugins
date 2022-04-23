#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "BOT Random Weapons"
#define VERSION "1.0"
#define AUTHOR "Jonvigo"

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|
(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|
(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);

public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR)
}

public zp_user_humanized_post(id)
{
	if(is_user_bot(id))
	{
		new random = random_num(1,18)
		switch(random)
		{
			case 1: give_item(id, "weapon_mac10")
			case 2: give_item(id, "weapon_tmp")
			case 3: give_item(id, "weapon_mp5navy")
			case 4: give_item(id, "weapon_ump45")
			case 5: give_item(id, "weapon_p90")
			case 6: give_item(id, "weapon_m3")
			case 7: give_item(id, "weapon_xm1014")
			case 8: give_item(id, "weapon_galil")
			case 9: give_item(id, "weapon_famas")
			case 10: give_item(id, "weapon_ak47")
			case 11: give_item(id, "weapon_m4a1")
			case 12: give_item(id, "weapon_scout")
			case 13: give_item(id, "weapon_sg552")
			case 14: give_item(id, "weapon_aug")
			case 15: give_item(id, "weapon_sg550")
			case 16: give_item(id, "weapon_g3sg1")
			case 17: give_item(id, "weapon_awp")
			case 18: give_item(id, "weapon_m249")
		}
		drop_weapons(id);
	}
}

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