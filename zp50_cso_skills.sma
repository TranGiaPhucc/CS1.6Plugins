#include <amxmodx>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <fakemeta>
#include <fun>
#include <cstrike>

#include <zp50_ammopacks>
#include <zp50_core>
#include <zp50_colorchat>

#define boot_cost 9000
#define dam_cost 8000
#define blade_cost 6500
#define deadrun_cost 4000 
#define ds_cost 14000
#define night_cost 1250
#define foot_cost 4000
#define ghost_cost 10000

#define sheild_cost 10000
#define wounds_cost 13000
#define emp_cost 9000

new Float:g_ospeed[33], bool:g_binded[33], Float:g_woundspeed[33], g_nums[33], bool:g_wounded[33] 

new boot[33], dam[33], blade[33], deadrun[33], deadly[33], ghost[33], sheild[33], wounds[33]

new using_deadrun[33], using_blade[33], using_deadly[33], using_ghost[33]

new is_in_cd_ds[33], is_in_cd_blade[33], is_in_cd_deadrun[33], is_in_cd_ghost[33] 

new cvar_ds_duration, cvar_blade_dam_multiplier, cvar_dmg_multiplier, cvar_boot_grav, cvar_deadrun_duration, cvar_blade_duration, cvar_ghost_duration, cvar_emp_duration

new cvar_one_round, cvar_sheild_damage

new cvar_ds_cd, cvar_deadrun_cd, cvar_blade_cd, cvar_ghost_cd

public plugin_init()
{
       register_plugin("[ZP50] Addon: CSO Skills", "1.2", "Catastrophe")

       register_event("HLTV", "event_newround", "a", "1=0", "2=0")

       register_clcmd("say /ds", "Skill1")
       register_clcmd("say /dr", "Skill2")
       register_clcmd("say /bb", "Skill3")
       register_clcmd("say /gf", "Skill4") 
       register_clcmd("say /csomenu", "CheckMenu") 
       register_clcmd("say /bindskills", "bindmenu") 
      
       RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
       RegisterHam(Ham_TraceAttack, "player", "fw_trace")

       RegisterHamBots(Ham_TakeDamage, "fw_takedamage")
       RegisterHamBots(Ham_TraceAttack, "fw_trace")

       cvar_ds_duration = register_cvar("cso_ds_duration","25.0") 
       cvar_blade_dam_multiplier = register_cvar("cso_blade_dam","2.0")     
       cvar_dmg_multiplier = register_cvar("cso_dam_multiplier","4.0")     
       cvar_boot_grav = register_cvar("cso_boot_gravity","0.5")     
       cvar_deadrun_duration = register_cvar("cso_deadrun_duration","10.0")     
       cvar_blade_duration = register_cvar("cso_blade_duation","30.0")
       cvar_ghost_duration = register_cvar("cso_ghost_duation","30.0")  
       
       cvar_one_round = register_cvar("cso_items_one_round","0")  

       cvar_ds_cd = register_cvar("cso_ds_cooldown","100.0")  
       cvar_deadrun_cd = register_cvar("cso_deadrun_cooldown","35.0")   
       cvar_blade_cd = register_cvar("cso_blade_cooldown","100.0") 
       cvar_ghost_cd = register_cvar("cso_ghost_cooldown","80.0")

       cvar_sheild_damage = register_cvar("cso_sheild_damage", "0.5")
       cvar_emp_duration = register_cvar("cso_emp_duration", "30.0")

       showadd()    
}

public showadd()
{
       zp_colored_print(0, "^x04[CSO Shop]^x01 Type^x03 /csomenu^x01 to buy CSO skills, and type^x03 /bindskills^x01 to bind your keys to the skills")
 
       set_task(45.0, "showadd")
}

//=============================== SKILL 1 =====================================

public Skill1(id)
{
    if(zp_core_is_zombie(id))
    {
    return
    }  

    if(!deadly[id]) 
    return;

    if(using_deadly[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Deadly shot skill in use Already !!") 
    return
    }
 
    if(is_in_cd_ds[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Deadly shot skill in cooldown!!") 
    return
    }
 
    using_deadly[id] = true   
    is_in_cd_ds[id] = true
 
    zp_colored_print(id, "^x04[CSO Shop]^x01 Deadly shot will end after^x03 %.f^x01 seconds !!", get_pcvar_float(cvar_ds_duration)) 

    set_task(get_pcvar_float(cvar_ds_duration), "removeds",id)
    set_task(get_pcvar_float(cvar_ds_cd), "removedscd",id)
}

public removeds(id)
{
       using_deadly[id] = false 
       zp_colored_print(id, "^x04[CSO Shop]^x01 Deadly Shot ended !!") 
}

public removedscd(id)
{
       is_in_cd_ds[id] = false 
       zp_colored_print(id, "^x04[CSO Shop]^x01 Deadly Shot Ready to use !!") 
}

//=============================== SKILL 2 =====================================

public Skill2(id)
{  
    if(zp_core_is_zombie(id))
    {
    return
    }  

    if(!deadrun[id]) 
    return;

    if(using_deadrun[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Dead run skill in use Already !!") 
    return
    }
 
    if(is_in_cd_deadrun[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Dead run skill in cooldown!!") 
    return
    }

    using_deadrun[id] = true 
    is_in_cd_deadrun[id] = true 
    checkdead(id)    

    zp_colored_print(id, "^x04[CSO Shop]^x01 Dead Run will end after^x03 %.f^x01 seconds !!", get_pcvar_float(cvar_deadrun_duration)) 

    set_task(get_pcvar_float(cvar_deadrun_cd), "removedeadcd",id)

}

public checkdead(id)
{
       if(!using_deadrun[id])
       return;

       g_ospeed[id] = get_user_maxspeed(id)  
       set_user_maxspeed(id, 0.0)   

       ScreenFade(id, get_pcvar_float(cvar_deadrun_duration), 100, 150, 0, 180)
       set_task(get_pcvar_float(cvar_deadrun_duration), "removedead", id)
}

public removedead(id)
{
       using_deadrun[id] = false  
       set_user_maxspeed(id, g_ospeed[id])
       zp_colored_print(id, "^x04[CSO Shop]^x01 Dead Run ended !!")
}

public removedeadcd(id)
{
       is_in_cd_deadrun[id] = false  
       zp_colored_print(id, "^x04[CSO Shop]^x01 Dead Run skill ready to use !!")
}

//=============================== SKILL 3 =====================================

public Skill3(id)
{
    if(zp_core_is_zombie(id))
    {
    return
    }  

    if(!blade[id]) 
    return;

    if(using_blade[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Bloody blade skill in use Already !!") 
    return
    }

    if(is_in_cd_blade[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Bloody blade skill in cooldown!!") 
    return
    }
 
    using_blade[id] = true
    is_in_cd_blade[id] = true  
 
    zp_colored_print(id, "^x04[CSO Shop]^x01 Bloody Blade will end after^x03 %.f^x01 seconds !!", get_pcvar_float(cvar_blade_duration)) 
  
    set_task(get_pcvar_float(cvar_blade_duration), "removeblade",id)
    set_task(get_pcvar_float(cvar_blade_cd), "removebladecd",id)

}

public removeblade(id)
{
       using_blade[id] = false
       zp_colored_print(id, "^x04[CSO Shop]^x01 Bloody blade ended !!")  
}

public removebladecd(id)
{
       is_in_cd_blade[id] = false
       zp_colored_print(id, "^x04[CSO Shop]^x01 Bloody blade Skill ready to use !!")  
}

//=============================== SKILL 4 =====================================

public Skill4(id)
{
    if(zp_core_is_zombie(id))
    {
    return
    }  

    if(!ghost[id]) 
    return;

    if(using_ghost[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Ghost form skill in use Already !!") 
    return
    }

    if(is_in_cd_ghost[id])
    {
    zp_colored_print(id, "^x04[CSO Shop]^x01 Ghost form skill in cooldown!!") 
    return
    }
 
    using_ghost[id] = true
    is_in_cd_ghost[id] = true  
 
    zp_colored_print(id, "^x04[CSO Shop]^x01 Ghost Form will end after^x03 %.f^x01 seconds !!", get_pcvar_float(cvar_ghost_duration)) 

    ScreenFade(id, get_pcvar_float(cvar_ghost_duration), 50, 50, 180, 180)
    set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
  
    set_task(get_pcvar_float(cvar_ghost_duration), "removeghost",id)
    set_task(get_pcvar_float(cvar_ghost_cd), "removeghostcd",id)

}

public removeghost(id)
{
       using_ghost[id] = false
       set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255)
       zp_colored_print(id, "^x04[CSO Shop]^x01 Ghost Form ended !!")  
}

public removeghostcd(id)
{
       is_in_cd_ghost[id] = false
       zp_colored_print(id, "^x04[CSO Shop]^x01 Ghost Form Skill ready to use !!")  
}

//===================================== End of skills ==========================

public CheckMenu(id)
{
       if(zp_core_is_zombie(id))
       {
       ShowMenuZM(id)
       }

       else
       {
       ShowMenuHM(id)
       }  
 
}

public ShowMenuHM(id)
{
       new menu_title[64], item_1[64], item_2[64], item_3[64], item_4[64], item_5[64], item_6[64], item_7[64], item_8[64]

       if(get_pcvar_num(cvar_one_round) == 1)
       {
       format(menu_title, charsmax(menu_title), "\y[CSO] SHOP :-")
       }
       else
       {
       format(menu_title, charsmax(menu_title), "\y[CSO] SHOP (Items stay one round) :-")
       }
       
       format(item_1, charsmax(item_1), "Heavenly Boots - \y[%d AP]", boot_cost )
       format(item_2, charsmax(item_2), "+%.f%% Damage - \y[%d AP]", (get_pcvar_float(cvar_dmg_multiplier) - 1)*100, dam_cost )
       format(item_3, charsmax(item_3), "Dead Run \r(Active skill) \y- [%d AP]", deadrun_cost )
       format(item_4, charsmax(item_4), "Bloody Blade \r(Active skill) \y- [%d AP]", blade_cost )
       format(item_5, charsmax(item_5), "Deadly Shot \r(Active skill) \y- [%d AP]", ds_cost )
       format(item_6, charsmax(item_6), "Nightvision - \y[%d AP]", night_cost )
       format(item_7, charsmax(item_7), "Silent Footsteps - \y[%d AP]", foot_cost) 
       format(item_8, charsmax(item_8), "Ghost Form \r(Active skill) \y- [%d AP]", ghost_cost )
       

       new mHandleID = menu_create(menu_title, "MenuHandlerHM")
       menu_additem(mHandleID, item_1, "1", 0)
       menu_additem(mHandleID, item_2, "2", 0) 
       menu_additem(mHandleID, item_3, "3", 0)
       menu_additem(mHandleID, item_4, "4", 0) 
       menu_additem(mHandleID, item_5, "5", 0) 
       menu_additem(mHandleID, item_6, "6", 0)
       menu_additem(mHandleID, item_7, "7", 0) 
       menu_additem(mHandleID, item_8, "8", 0) 
       
       menu_display(id, mHandleID, 0) 

       return PLUGIN_HANDLED	
}

public MenuHandlerHM(id, menu, item)
{
       
 
       if (item == MENU_EXIT || zp_core_is_zombie(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}



       switch (item)
	{
		case 0:
		{

                if(zp_ammopacks_get(id) < boot_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {
                boot[id] = true
                zp_ammopacks_set(id, zp_ammopacks_get(id) - boot_cost)
                set_user_gravity(id, get_pcvar_float(cvar_boot_grav)) 
                zp_colored_print(id, "^x04[CSO Shop]^x01 You now have^x03 0.%.fx^x01 gravity !!", get_user_gravity(id)*10)
                }
 
		}
		
                case 1:
		{

                if(zp_ammopacks_get(id) < dam_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {
                dam[id] = true
                zp_ammopacks_set(id, zp_ammopacks_get(id) - dam_cost)  
                zp_colored_print(id, "^x04[CSO Shop]^x01 You now have^x03 %fx Damage !!", get_pcvar_float(cvar_dmg_multiplier))        
		}

                }     

                case 2:
		{
                
                if(zp_ammopacks_get(id) < deadrun_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {  
                deadrun[id] = true
                zp_ammopacks_set(id, zp_ammopacks_get(id) - deadrun_cost) 
                zp_colored_print(id, "^x04[CSO Shop]^x01 To run very fast press^x03 F2 or type /dr !!" )  
		} 
      
                }

                case 3:
		{ 
              
                if(zp_ammopacks_get(id) < blade_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                { 
                blade[id] = true 
                zp_ammopacks_set(id, zp_ammopacks_get(id) - blade_cost) 
                zp_colored_print(id, "^x04[CSO Shop]^x01 To increase you melee damage press^x03 F3 or type /bb !!")         
		}

                }

                case 4: 
		{

                if(zp_ammopacks_get(id) < ds_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {  
                deadly[id] = true 
                zp_ammopacks_set(id, zp_ammopacks_get(id) - ds_cost) 
                zp_colored_print(id, "^x04[CSO Shop]^x01 To enable Head Shot mode press^x03 F1 or type /ds !!" )              
		}

                }
                
                case 5:
		{

                if(zp_ammopacks_get(id) < night_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {
                cs_set_user_nvg(id, 1)
                zp_ammopacks_set(id, zp_ammopacks_get(id) - night_cost)
                zp_colored_print(id, "^x04[CSO Shop]^x01 You now have^x03 Nightvision !!")                                     
		}
                
                }

                case 6:
                {

                if(zp_ammopacks_get(id) < foot_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {
                set_user_footsteps(id, 1)
                zp_ammopacks_set(id, zp_ammopacks_get(id) - foot_cost)
                zp_colored_print(id, "^x04[CSO Shop]^x01 You now have^x03 Silent Footsteps !!")                                     
		}
                
                }

                case 7: 
		{

                if(zp_ammopacks_get(id) < ghost_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {  
                ghost[id] = true 
                zp_ammopacks_set(id, zp_ammopacks_get(id) - ghost_cost) 
                zp_colored_print(id, "^x04[CSO Shop]^x01 To get^x03 Invisible^x01 press^x03 F4 or type /gf !!" )              
		}

                }


        }


       return PLUGIN_HANDLED
}

public ShowMenuZM(id)
{
       new menu_title[64], item_1[64], item_2[64], item_3[64]

       if(get_pcvar_num(cvar_one_round) == 1)
       {
       format(menu_title, charsmax(menu_title), "\y[CSO] SHOP :-")
       }
       else
       {
       format(menu_title, charsmax(menu_title), "\y[CSO] SHOP (Items stay one round) :-")
       }
       
       format(item_1, charsmax(item_1), "Damage Sheild - \y[%d AP]",sheild_cost)
       format(item_2, charsmax(item_2), "Open Wounds - \y[%d AP]", wounds_cost)
       format(item_3, charsmax(item_3), "EMP - \y[%d AP]", emp_cost )

       new mHandleID = menu_create(menu_title, "MenuHandlerZM")
       menu_additem(mHandleID, item_1, "1", 0)
       menu_additem(mHandleID, item_2, "2", 0) 
       menu_additem(mHandleID, item_3, "3", 0)
   
       menu_display(id, mHandleID, 0) 

       return PLUGIN_HANDLED	
}

public MenuHandlerZM(id, menu, item)
{
       
 
       if (item == MENU_EXIT || !zp_core_is_zombie(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}



       switch (item)
        {
		case 0:
		{

                if(zp_ammopacks_get(id) < sheild_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {
                sheild[id] = true
                zp_ammopacks_set(id, zp_ammopacks_get(id) - sheild_cost)
                zp_colored_print(id, "^x04[CSO Shop]^x01 You now have^x03 Damage sheild^x01, You will take 50%% less damage")
                }
 
		}
		
                case 1:
		{

                if(zp_ammopacks_get(id) < wounds_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {
                wounds[id] = true
                zp_ammopacks_set(id, zp_ammopacks_get(id) - wounds_cost)  
                zp_colored_print(id, "^x04[CSO Shop]^x01 Your Attacks will slow enemies and deal damage over time !! ")        
		}

                }     

                case 2:
		{
                
                if(zp_ammopacks_get(id) < emp_cost)
                {
                zp_colored_print(id, "^x04[CSO Shop]^x01 Not enough Ammo packs !!")
                return PLUGIN_HANDLED
                
                }
                else
                {  
                zp_ammopacks_set(id, zp_ammopacks_get(id) - emp_cost) 
                zp_colored_print(id, "^x04[CSO Shop]^x01 Human HUD going down !!" )  
                set_task(random_float(5.0,7.0),"doemp",id)
		} 
      
                }

        }
       return PLUGIN_HANDLED
}

public zp_fw_core_infect_post(id)
{
       using_deadly[id] = false           
       using_blade[id] = false 
       using_deadrun[id] = false 
       using_ghost[id] = false 

       is_in_cd_deadrun[id] = false
       is_in_cd_ds[id] = false
       is_in_cd_blade[id] = false 
       is_in_cd_ghost[id] = false   

}

public client_disconnect(id)
{
       reset_vars(id)
}      

public client_connect(id)
{
       if(!is_user_connected(id))
       return 

       reset_vars(id)

}

public bindmenu(id)
{

       new menu_title[64], item_1[64], item_2[64]
     
       format(menu_title, charsmax(menu_title), "\y[CSO] SHOP \rBind menu :-")
       
       format(item_1, charsmax(item_1), "Bind my keys to skills !!")
       format(item_2, charsmax(item_2), "Nah, dont bind me !!")

       new mHandleID = menu_create(menu_title, "BindHandler")
       menu_additem(mHandleID, item_1, "1", 0)
       menu_additem(mHandleID, item_2, "2", 0) 
       
       menu_display(id, mHandleID, 0) 

       return PLUGIN_HANDLED	

}

public BindHandler(id, menu, item)
{
       
 
        if (item == MENU_EXIT || zp_core_is_zombie(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}



        switch (item)
	{
		case 0:
		{
                g_binded[id] = true
                bind(id)
                zp_colored_print(id, "^x04[CSO Shop]^x01 Your keys F1, F2 ,F3 and F4 are now binded to CSO menu skills, type ^x03/csomenu")
                }
 		
                case 1:
		{

                return PLUGIN_HANDLED	

                } 

        }
        return PLUGIN_HANDLED	
}

public event_newround()
{
       for(new i = 1; i < get_maxplayers(); i++)
       {   
            if(!is_user_connected(i))
            {
            return
            }

            if(!g_binded[i])
            {
            set_task(7.0, "bindmenu", i)
            }

            if(g_binded[i])
            {
            bind(i)
            }

            if(get_pcvar_num(cvar_one_round) == 1)
            {
            reset_vars(i)
            }      
          
            using_deadly[i] = false
            using_blade[i] = false 
            using_deadrun[i] = false
            using_ghost[i] = false

            is_in_cd_deadrun[i] = false
            is_in_cd_ds[i] = false
            is_in_cd_blade[i] = false  
            is_in_cd_ghost[i] = false 

            stopwound(i) 
            g_wounded[i] = false 

            set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
           
            }
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
       if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
       return 

       if(zp_core_is_zombie(victim) && !zp_core_is_zombie(attacker) && using_blade[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
       {
       SetHamParamFloat(4, damage*get_pcvar_float(cvar_blade_dam_multiplier))
       }

       if(zp_core_is_zombie(victim) && !zp_core_is_zombie(attacker) && dam[attacker])
       {
       SetHamParamFloat(4, damage*get_pcvar_float(cvar_dmg_multiplier))
       }

       if(zp_core_is_zombie(victim) && !zp_core_is_zombie(attacker) && sheild[victim])
       {
       SetHamParamFloat(4, damage*get_pcvar_float(cvar_sheild_damage))
       }

       if(!zp_core_is_zombie(victim) && zp_core_is_zombie(attacker) && wounds[attacker] && !g_wounded[victim])
       {
       g_wounded[victim] = true
       g_woundspeed[victim] = get_user_maxspeed(victim)
       set_user_rendering(victim, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16)
       set_user_maxspeed(victim, get_user_maxspeed(victim) - 100.0)
       wound(victim, attacker) 
       }

}

public fw_trace(victim, attacker, Float:damage, direction[3],traceresult, dmgbits)
{
        if(using_deadly[attacker])
	{
		set_tr2(traceresult, TR_iHitgroup, HIT_HEAD)
	}

}

public bind(i)
{
       client_cmd(i, "bind ^"F1^" ^"say /ds^" ")
       client_cmd(i, "bind ^"F2^" ^"say /dr^" ")
       client_cmd(i, "bind ^"F3^" ^"say /bb^" ")
       client_cmd(i, "bind ^"F4^" ^"say /gf^" ")
}

public reset_vars(id)
{
                if(!is_user_connected(id))
                return

                boot[id] = false 
                dam[id] = false         
                deadrun[id] = false  
                blade[id] = false                                         
                deadly[id] = false 
                ghost[id] = false  
                sheild[id] = false
                wounds[id] = false
                cs_set_user_nvg(id, 0) 
                set_user_footsteps(id, 0) 
        
                using_deadly[id] = false           
                using_blade[id] = false 
                using_deadrun[id] = false   
                using_ghost[id] = false 
      
                is_in_cd_deadrun[id] = false
                is_in_cd_ds[id] = false
                is_in_cd_blade[id] = false 
                is_in_cd_ghost[id] = false                  
}

public wound(id, attacker)
{

       if(!is_user_connected(id) || !is_user_alive(id))
       return

       if(g_nums[id] > 10 || zp_core_is_zombie(id) || !g_wounded[id])
       {
       stopwound(id)
       return
       }
 
       g_nums[id]++
       ExecuteHam(Ham_TakeDamage, id, attacker, attacker, 5.0, DMG_SLASH)

       set_task(2.5, "wound", id)

}

public stopwound(id)
{

       if(!is_user_connected(id) || !is_user_alive(id))
       return

       set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
       set_user_maxspeed(id, g_woundspeed[id])

       g_wounded[id] = false
}

public doemp(id)
{    
    set_hudmessage(255, 10, 10, -1.0, -1.0, 2, 6.0, 12.0)
    show_hudmessage(0 , "EMP used ^nAll electronics going down for ^n%.f.0 seconds", get_pcvar_float(cvar_emp_duration))

    server_cmd("zp_triggered_lights 0")
    server_cmd("zp_nvg_hum_color_R 0")
    server_cmd("zp_nvg_hum_color_G 0")
    server_cmd("zp_nvg_hum_color_B 0")
    server_cmd("zp_flare_duration 0")
    server_cmd("zp_flare_size 0")
    server_cmd("zp_frost_duration 0")
    server_cmd("zp_ltm 0")  
    
    for(new i = 1; i < get_maxplayers(); i++)
    {
        if(is_user_connected(i) && is_user_alive(i) && !zp_core_is_zombie(i))   
        {
        client_cmd(i, "hud_draw 0")
        }
    }
    
    client_cmd(0, "spk sound/ambience/alien_hollow.wav");
    client_cmd(0, "spk sound/fvox/hev_shutdown.wav");

    set_task(get_pcvar_float(cvar_emp_duration), "emp_end");
}

public emp_end()
{
    server_cmd("zp_triggered_lights 1")
    server_cmd("zp_nvg_hum_color_R 100")
    server_cmd("zp_nvg_hum_color_G 100")
    server_cmd("zp_nvg_hum_color_B 100")
    server_cmd("zp_flare_duration 180")
    server_cmd("zp_flare_size 35")
    server_cmd("zp_frost_duration 3")
    server_cmd("zp_ltm 1")
    
    for(new i = 1; i < get_maxplayers(); i++)
    {
        if( is_user_connected(i) && is_user_alive(i) && !zp_core_is_zombie(i))   
        {
        client_cmd(i, "hud_draw 1")
        }
    }

    set_hudmessage(25, 255, 25, -1.0, -1.0, 2, 6.0, 12.0)
    show_hudmessage(0 , "Electronic is working now!")
    
    client_cmd(0, "spk sound/fvox/bell.wav")
    client_cmd(0, "spk sound/fvox/online.wav")
}

stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
    new i = plr ? plr : get_maxplayers();
    if( !i )
    {
        return 0;
    }
    
    message_begin(plr ? MSG_ONE : MSG_ALL, get_user_msgid( "ScreenFade"), {0, 0, 0}, plr);
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(4096);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
    
    return 1;
}