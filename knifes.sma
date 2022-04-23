#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <nvault>
#include <zombieplague>

#define PLUGIN 	"[ZP] Knifes"
#define VERSION "2.0"
#define AUTHOR 	"heka"

new iKnife[ 33 ]
new iAttack[ 33 ]

enum { AXE = 0 , STRONG }
new const Knife_View_Models[ ] [ ] = { "models/knifes/v_axe.mdl" , "models/knifes/v_strong.mdl" }
new const Knife_Player_Models[ ] [ ] = { "models/knifes/p_axe.mdl" , "models/knifes/p_strong.mdl" }
new const Knife_Sounds[ ] [ ] [ ]  = 
{
	{ "knifes/axe/draw.wav" , "knifes/axe/hit_normal_1.wav" , "knifes/axe/hit_normal_2.wav" , "knifes/axe/hit_wall.wav" , "knifes/axe/miss.wav" , "knifes/axe/hit_stab.wav" },
	{ "knifes/strong/draw.wav" , "knifes/strong/hit_normal_1.wav" , "knifes/strong/hit_normal_2.wav" , "knifes/strong/hit_wall.wav" , "knifes/strong/miss.wav" , "knifes/strong/hit_stab.wav" }
}

new const Knife_WeaponList[ ] [ ] = { "knife_axe_cso" , "knife_strong_cso" }
new const Knife_WeaponListFiles[ ] [ ] = { "sprites/knife_axe_cso.txt" , "sprites/knife_strong_cso.txt" }
new const Knife_Sprites[ ] [ ] = { "sprites/cso/640hud38.spr" , "sprites/cso/640hud23.spr" }

new cvar_jump[ 4 ]
new cvar_damage[ 4 ]
new cvar_knockback[ 4 ]
new cvar_attack1_distance[ 4 ]
new cvar_attack2_distance[ 4 ]
new cvar_attack2_delay[ 4 ]
new cvar_attack1_delay[ 4 ]

public plugin_init( ) 
{
	register_plugin( PLUGIN , VERSION , AUTHOR )
	
	register_event("CurWeapon","SetKnifeModel","be","1=1");
	RegisterHam( Ham_Weapon_PrimaryAttack , "weapon_knife" , "CBaseWeapon_PrimaryAttack_Post" , .Post = true )
	RegisterHam( Ham_TakeDamage , "player" , "CBasePlayer_TakeDamage_Post" , .Post = true )
	RegisterHam( Ham_Weapon_SecondaryAttack , "weapon_knife" , "CBaseWeapon_SecAttack_Post" , .Post = true )

	RegisterHam( Ham_TakeDamage , "player" , "CBasePlayer_TakeDamage" )
	RegisterHam( Ham_Weapon_PrimaryAttack , "weapon_knife" , "CBaseWeapon_PrimaryAttack" )
	RegisterHam( Ham_Weapon_SecondaryAttack , "weapon_knife" , "CBaseWeapon_SecondaryAttack" )

	RegisterHam(Ham_Spawn, "player", "CBasePlayer_Spawn")

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")

	register_forward( FM_EmitSound , "Fw_EmitSound" )
	register_forward( FM_PlayerPreThink , "Fw_PreThink" );
	register_forward( FM_TraceLine , "Fw_TraceLine" )
	register_forward( FM_TraceHull , "Fw_TraceHull" )

	cvar_jump[ 0 ] = register_cvar( "zp_jump_axe" , "250.0" )
	cvar_jump[ 1 ] = register_cvar( "zp_jump_strong" , "250.0" )
	
	cvar_damage[ 0 ] = register_cvar( "zp_damage_axe" , "5.0" )
	cvar_damage[ 1 ] = register_cvar( "zp_damage_strong" , "12.0" )
	
	cvar_knockback[ 0 ] = register_cvar( "zp_knockback_axe" , "10.0" )
	cvar_knockback[ 1 ] = register_cvar( "zp_knockback_strong" , "2.0" )
	
	cvar_attack1_distance[ 0 ] = register_cvar( "zp_attack1_distance_axe" , "96.0" )
	cvar_attack1_distance[ 1 ] = register_cvar( "zp_attack1_distance_strong" , "96.0" )
	
	cvar_attack2_distance[ 0 ] = register_cvar( "zp_attack2_distance_axe" , "64.0" )
	cvar_attack2_distance[ 1 ] = register_cvar( "zp_attack2_distance_strong" , "64.0" )

	cvar_attack2_delay[ 0 ] = register_cvar( "zp_attack2_delay_axe" , "1.2" )
	cvar_attack2_delay[ 1 ] = register_cvar( "zp_attack2_delay_strong" , "1.2" )
	
	cvar_attack1_delay[ 0 ] = register_cvar( "zp_attack1_delay_axe" , "1.3" )
	cvar_attack1_delay[ 1 ] = register_cvar( "zp_attack1_delay_strong" , "2.0" )

	register_clcmd("say /knife", "ClCmd_KnifeMenu")

	register_clcmd( "knife_axe_cso" , "Hook_WeaponList" );
	register_clcmd( "knife_strong_cso" , "Hook_WeaponList" );
}

public plugin_precache( )
{
	new i;

	for(i = 0; i < 4; i++) {
		precache_model( Knife_Player_Models[ i ] )
		precache_model( Knife_View_Models[ i ] )
	}

	for( i = 0; i < 4; i++ ) 
	{
		precache_sound( Knife_Sounds[ i ] [ 0 ] )
		precache_sound( Knife_Sounds[ i ] [ 1 ] )
		precache_sound( Knife_Sounds[ i ] [ 2 ] )
		precache_sound( Knife_Sounds[ i ] [ 3 ] )
		precache_sound( Knife_Sounds[ i ] [ 4 ] )
		precache_sound( Knife_Sounds[ i ] [ 5 ] )
	}

	for( i = 0; i < sizeof Knife_Sprites; i++ )
	{
		precache_generic( Knife_Sprites[ i ] );
	}

	for(i = 0; i < 4; i++) 
	{
		precache_generic( Knife_WeaponListFiles[ i ] )
		precache_generic( Knife_WeaponListFiles[ i ] )
	}
}

public Hook_WeaponList( iPlayer )
{
	engclient_cmd( iPlayer, "weapon_knife" )
	return PLUGIN_HANDLED
}

public client_putinserver( iPlayer ) 
{
	iKnife [ iPlayer ] = AXE
}

public zp_user_humanized_post( iPlayer )
{
	if( zp_get_user_survivor( iPlayer ) )
		Set_Sprite( iPlayer, "knife_axe_cso" )
}

public zp_user_infected_post( iPlayer )
{
	Set_Sprite( iPlayer, "weapon_knife" )
}

public CBasePlayer_Spawn( iPlayer )
{
	Set_Sprite( iPlayer, Knife_WeaponList[ iKnife[ iPlayer ] ] )
}

public ClCmd_KnifeMenu( iPlayer ) 
{
	if( ! is_user_alive( iPlayer ) ) return 
	if( zp_get_user_zombie( iPlayer ) ) return
	if( zp_has_round_started( ) ) return

	static buffer[ 512 ]
	new iKnife_Menu = menu_create( "\yChoose knife" , "ClCmd_KnifeMenu_Handler" )
	
	formatex( buffer , charsmax( buffer ) , iKnife[ iPlayer ] == AXE ? "Axe" : "Axe" )
	menu_additem( iKnife_Menu , buffer , "1" )
	formatex( buffer , charsmax( buffer ) , iKnife[ iPlayer ] == STRONG ? "Strong" : "Strong" )
	menu_additem( iKnife_Menu , buffer , "2" )	
	
	menu_setprop( iKnife_Menu , MPROP_EXIT , MEXIT_ALL )
	menu_display( iPlayer , iKnife_Menu , 0 )	
}

public ClCmd_KnifeMenu_Handler( iPlayer , iMenu , iItem ) 
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu )
		return PLUGIN_HANDLED
	}

	if( zp_has_round_started( ) ) return PLUGIN_HANDLED

	new iData[ 6 ] , iName[ 64 ]
	new iAccess, iCallBack
	menu_item_getinfo( iMenu , iItem , iAccess , iData , 5 , iName , 63 , iCallBack )
	new iKey = str_to_num( iData )
	
	switch( iKey )
	{
		case 1: iKnife[ iPlayer ] = AXE
		case 2: iKnife[ iPlayer ] = STRONG
	}
	
	message_begin( MSG_ONE , get_user_msgid("WeapPickup") , _, iPlayer )
	write_byte( CSW_KNIFE )
	message_end( )	

	if( get_user_weapon ( iPlayer ) != CSW_KNIFE ) return PLUGIN_HANDLED;

	ExecuteHamB( Ham_Item_Deploy , get_pdata_cbase( iPlayer , 373 ) )	

	SetKnifeModel( iPlayer )
	Set_Sprite( iPlayer, Knife_WeaponList[ iKnife[ iPlayer ] ] )
	
	return PLUGIN_HANDLED
}

public SetKnifeModel(id)
{
        if(get_user_weapon(id) != CSW_KNIFE || zp_get_user_zombie(id))
                return;
                
	set_pev( id , pev_viewmodel2 , Knife_View_Models[ iKnife[ id ] ] );
	set_pev( id , pev_weaponmodel2 , Knife_Player_Models[ iKnife[ id ] ] );
       
        return;
}

public Fw_EmitSound( iPlayer , iChannel , iSample[] , Float:flVolume , Float:flAttn , iFlag , iPitch )
{	
	if( ! is_user_connected( iPlayer ) ) return FMRES_IGNORED;
	if( zp_get_user_zombie( iPlayer ) ) return FMRES_IGNORED

	if( iSample[ 8 ] == 'k' && iSample[ 9 ] == 'n' && iSample[ 10 ] == 'i' ) {
		if( iSample[ 14 ] == 'd' ) 
		{
			emit_sound( iPlayer , iChannel , Knife_Sounds[ iKnife [ iPlayer ] ] [ 0 ] , flVolume , flAttn , iFlag , iPitch )
		}
		else if(iSample[ 14 ] == 'h')
		{
			if(iSample[ 17 ] == 'w') 
			{
				emit_sound(iPlayer , iChannel , Knife_Sounds[ iKnife[ iPlayer ] ] [ 3 ] , flVolume , flAttn , iFlag , iPitch )
			} 
			else 
			{
				emit_sound(iPlayer , iChannel , Knife_Sounds[ iKnife[ iPlayer ] ] [ random_num( 1 , 2 ) ] , flVolume , flAttn , iFlag , iPitch )
			}
		} 
		else 
		{
			if( iSample[ 15 ] == 'l' )
			{
				emit_sound( iPlayer , iChannel , Knife_Sounds[ iKnife[ iPlayer ] ] [ 4 ] , flVolume , flAttn , iFlag , iPitch )
			} 
			else 
			{
				emit_sound( iPlayer , iChannel , Knife_Sounds[ iKnife[ iPlayer ] ] [ 5 ] , flVolume , flAttn , iFlag , iPitch )
			}
		}

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public CBasePlayer_TakeDamage( iVictim , iInflector , iAttacker , Float:flDamage , bitsDamageType )
{
	if(!is_user_connected(iAttacker) || iVictim == iAttacker)
		return;

	if(get_user_weapon(iAttacker) != CSW_KNIFE || ~bitsDamageType & (DMG_BULLET | DMG_NEVERGIB))
		return;

	if(zp_get_user_zombie(iAttacker))
		return;
	
	SetHamParamFloat( 4 , flDamage * get_pcvar_float( cvar_damage[ iKnife[ iAttacker ] ] ) )
}

public CBasePlayer_TakeDamage_Post( iVictim , iInflector, iAttacker , Float:flDamage , bitsDamageType , Float:velocity[ 3 ] )
{
	if( ! is_user_connected( iAttacker ) || iVictim == iAttacker ) return
        if( get_user_weapon( iAttacker ) != CSW_KNIFE ) return
	if( zp_get_user_zombie( iAttacker ) ) return

	new Float:newvelocity[ 3 ]
	entity_get_vector( iVictim , EV_VEC_velocity , velocity )
	
	new Float:victim_origin[ 3 ], Float:attacker_origin[ 3 ]
	entity_get_vector( iVictim , EV_VEC_origin , victim_origin )
	entity_get_vector( iAttacker , EV_VEC_origin , attacker_origin )
	
	newvelocity[ 0 ] = victim_origin[ 0 ] - attacker_origin[ 0 ]
	newvelocity[ 1 ] = victim_origin[ 1 ] - attacker_origin[ 1 ]
	
	new Float:largestnum = 0.0
	
	if ( 0 <= floatcmp( floatabs( newvelocity[ 0 ] ) , floatabs( newvelocity[ 1 ] ) ) <= 1 )
	{
		if ( floatabs( newvelocity[ 0 ] ) > 0 ) largestnum = floatabs( newvelocity[ 0 ] )
	} 
	else 
	{
		if ( floatabs( newvelocity[ 1 ]) > 0 ) largestnum = floatabs( newvelocity[ 1 ] )
	}

	newvelocity[ 0 ] /= largestnum
	newvelocity[ 1 ] /= largestnum
	
	velocity[ 0 ] = newvelocity[ 0 ] * get_pcvar_float( cvar_knockback[ iKnife[ iAttacker ] ] )  * 3000 / get_distance_f( victim_origin , attacker_origin )
	velocity[ 1 ] = newvelocity[ 1 ] * get_pcvar_float( cvar_knockback[ iKnife[ iAttacker ] ] )  * 3000 / get_distance_f( victim_origin , attacker_origin )
	
	if( newvelocity[ 0 ] <= 20.0 || newvelocity[ 1 ] <= 20.0 ) newvelocity[ 2 ] = random_float( 200.0 , 275.0 )
	
	newvelocity[ 0 ] += velocity[ 0 ]
	newvelocity[ 1 ] += velocity[ 1 ]
	entity_set_vector( iVictim , EV_VEC_velocity , newvelocity )

	set_pdata_float( iVictim , 108 , 1.0 )
}

public Fw_PreThink( iPlayer )
{
        if( ! is_user_alive( iPlayer ) ) return PLUGIN_CONTINUE
	if( zp_get_user_zombie( iPlayer ) ) return PLUGIN_CONTINUE

        new temp[ 2 ], weapon = get_user_weapon( iPlayer , temp[ 0 ] , temp[ 1 ] )

        if( weapon == CSW_KNIFE )
        {
                if ( ( pev( iPlayer , pev_button ) & IN_JUMP ) && ! ( pev( iPlayer , pev_oldbuttons) & IN_JUMP ) )
                {
                        new flags = pev( iPlayer , pev_flags )
                        new waterlvl = pev( iPlayer , pev_waterlevel )
                        
                        if ( ! ( flags & FL_ONGROUND ) ) return PLUGIN_CONTINUE;
                        if ( flags & FL_WATERJUMP ) return PLUGIN_CONTINUE;
                        if ( waterlvl > 1 ) return PLUGIN_CONTINUE;
                        
                        new Float:fVelocity[ 3 ]
                        pev( iPlayer , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += get_pcvar_float( cvar_jump[ iKnife[ iPlayer ] ] )

                        set_pev( iPlayer , pev_velocity , fVelocity )
                        set_pev( iPlayer , pev_gaitsequence , 6 )
                }
	}
        return PLUGIN_CONTINUE
}

public CBaseWeapon_PrimaryAttack( iEntity )
{
	if ( ! pev_valid( iEntity ) ) return;
	
	// Get owner
	static iOwner
	iOwner = pev( iEntity , pev_owner)
	
	if ( ! is_user_connected( iOwner ) ) return;
	if( zp_get_user_zombie( iOwner ) ) return ;
	
	iAttack[ iOwner ] = 1
}

public CBaseWeapon_SecondaryAttack( iEntity )
{
	if ( ! pev_valid( iEntity ) ) return;
	
	// Get owner
	static iOwner
	iOwner = pev( iEntity , pev_owner)
	
	if ( ! is_user_connected( iOwner ) ) return;
	if( zp_get_user_zombie( iOwner ) ) return ;
	
	iAttack[ iOwner ] = 1
}

public CBaseWeapon_PrimaryAttack_Post( iEntity )
{
	if ( ! pev_valid( iEntity ) ) return;
	
	// Get owner
	static iOwner
	iOwner = pev( iEntity , pev_owner)
	
	if ( ! is_user_connected( iOwner ) ) return;
	if( zp_get_user_zombie( iOwner ) ) return ;
	
	iAttack[ iOwner ] = 0

	new Float:fDelay1

	fDelay1 = get_pcvar_float(cvar_attack1_delay[ iKnife[ iOwner ] ] )

	set_pdata_float( iEntity , 46 , fDelay1 , 4)
	set_pdata_float( iEntity , 47 , fDelay1 , 4)
	set_pdata_float( iEntity , 48 , fDelay1 , 4)
}

public CBaseWeapon_SecAttack_Post( iEntity )
{
	if ( ! pev_valid( iEntity ) ) return;
	
	// Get owner
	static iOwner
	iOwner = pev( iEntity , pev_owner)
	
	if ( ! is_user_connected( iOwner ) ) return;
	if( zp_get_user_zombie( iOwner ) ) return ;
	
	iAttack[ iOwner ] = 0

	new Float:fDelay

	fDelay = get_pcvar_float(cvar_attack2_delay[ iKnife[ iOwner ] ] )

	set_pdata_float( iEntity , 46 , fDelay , 4)
	set_pdata_float( iEntity , 47 , fDelay , 4)
	set_pdata_float( iEntity , 48 , fDelay , 4)
}

public Fw_TraceLine( Float:vector_start[3] , Float:vector_end[3] , ignored_monster , iPlayer , handle )
{
	if ( ! is_user_connected ( iPlayer ) ) return FMRES_IGNORED;
	if ( ! is_user_alive( iPlayer ) ) return FMRES_IGNORED;
	if ( get_user_weapon( iPlayer ) != CSW_KNIFE) return FMRES_IGNORED;
	if ( !iAttack[ iPlayer ] ) return FMRES_IGNORED;
	if( zp_get_user_zombie( iPlayer ) ) return FMRES_IGNORED;
	
	pev( iPlayer , pev_v_angle , vector_end )
	angle_vector( vector_end , ANGLEVECTOR_FORWARD , vector_end )
	
	if ( iAttack[ iPlayer ] == 1 )
		xs_vec_mul_scalar( vector_end , get_pcvar_float( cvar_attack1_distance[ iKnife[ iPlayer ] ] ), vector_end )
	else
		xs_vec_mul_scalar( vector_end , get_pcvar_float( cvar_attack2_distance[ iKnife[ iPlayer ] ] ) , vector_end )
	
	xs_vec_add( vector_start , vector_end , vector_end )
	engfunc( EngFunc_TraceLine , vector_start , vector_end , ignored_monster , iPlayer , handle )
	
	return FMRES_SUPERCEDE;
}

public Fw_TraceHull( Float:vector_start[3] , Float:vector_end[3] , ignored_monster , iPlayer , handle )
{
	if ( ! is_user_connected ( iPlayer ) ) return FMRES_IGNORED;
	if ( ! is_user_alive( iPlayer ) ) return FMRES_IGNORED;
	if ( get_user_weapon( iPlayer ) != CSW_KNIFE) return FMRES_IGNORED;
	if ( !iAttack[ iPlayer ] ) return FMRES_IGNORED;
	if( zp_get_user_zombie( iPlayer ) ) return FMRES_IGNORED;
	
	pev( iPlayer , pev_v_angle , vector_end )
	angle_vector( vector_end , ANGLEVECTOR_FORWARD , vector_end )
	
	if ( iAttack[ iPlayer ] == 1 )
		xs_vec_mul_scalar( vector_end , get_pcvar_float( cvar_attack1_distance[ iKnife[ iPlayer ] ] ), vector_end )
	else
		xs_vec_mul_scalar( vector_end , get_pcvar_float( cvar_attack2_distance[ iKnife[ iPlayer ] ] ) , vector_end )
	
	xs_vec_add( vector_start , vector_end , vector_end )
	engfunc( EngFunc_TraceHull , vector_start , vector_end , ignored_monster , iPlayer , handle )
	
	return FMRES_SUPERCEDE;
}

Set_Sprite( iPlayer, const Weapon[ ] )
{
	if( ! pev_valid( iPlayer ) )
                return;

	message_begin( MSG_ONE , get_user_msgid( "WeaponList" ) , _, iPlayer )
	write_string( Weapon )
	write_byte( -1 )
	write_byte( -1)
	write_byte( -1 )
	write_byte( -1 )
	write_byte( 2 )
	write_byte( 1 )
	write_byte( 29 )
	write_byte( 0 )
	message_end( )
}