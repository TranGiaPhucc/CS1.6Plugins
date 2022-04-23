#include < Amx_Mod_X >
#include < SQL_X >
#include < Level_System >
#include < Dhud_Message >

#define PLUG_IN_VERSION			"4.2.0"
#define PLUG_IN_NAME			"Lvl ( Times )"		/*   Level System ( for any mod's )   */
#define PLUG_IN_AUTHOR			"[cfn]"

#define SQL_USER_HOST			"123.45.67.89"		/*   InterNet Protocol Addres   */
#define SQL_USER_LOGIN			"Login"			/*   Log-In   */
#define SQL_USER_PASSWORD		"Password"		/*   PassWord DB   */
#define SQL_USER_DATABASE		"Database"		/*   SQL Base   */

#define ADD_EXP				1.0			/*   Сколько секунд требуется для получения следующего Exp   */
#define MAX_EXP				10			/*   Сколько требуется Exp для перехода на следующий уровень   */
#define MAX_LEVEL			100			/*   Максимальный уровень   */

#define DHUD_RGB_LEVEL			0, 255, 0		/*   RGB цвета показа уровня & опыта   */
#define DHUD_RGB_MAXLEVEL		255, 0, 0		/*   RGB цвета показа макс. уровня   */
#define DHUD_FLOAT_X			-1.0			/*   Положение по -X-   */
#define DHUD_FLOAT_Y			0.85			/*   Положение по -Y-   */

#define TIME_TASK1			3.0
#define TIME_TASK2			1.0
#define TIME_TASK3			0.5

#define MAX_CLIENTS			32
#define MAX_SZ				33
#define MAX_BT				512

new Handle:G_SQLTP, G_ERROR[ MAX_BT ], G_PlLEVEL[ MAX_SZ ], G_PlEXP[ MAX_SZ ], G_PlMAXLEVEL[ MAX_SZ ], G_PlLEVELUP, G_LOAD[ MAX_SZ ];

public plugin_init( )
{
	register_plugin( PLUG_IN_NAME, PLUG_IN_VERSION, PLUG_IN_AUTHOR );
	G_PlLEVELUP = CreateMultiForward( "_UpGrade_", ET_IGNORE, FP_CELL );
	set_task( TIME_TASK1, "Dhud_Show_Level", _, _, _, "b" );
	set_task( TIME_TASK2, "MySQL_Init" );
}

public Dhud_Show_Level( )
{
	new iMaxLevel;
	new Show_Exp;
	new Show_Level;
	for( new iPlayer = 0; iPlayer < MAX_SZ; iPlayer++ )
	if( is_user_connected( iPlayer ) )
	{
		Show_Exp = _Get_User_Exp_( iPlayer );
		Show_Level = _Get_User_Level_( iPlayer );
		iMaxLevel = _Get_User_MaxLevel_( iPlayer );
		if( Show_Level < iMaxLevel )
		{
			set_dhudmessage( DHUD_RGB_LEVEL, DHUD_FLOAT_X, DHUD_FLOAT_Y, 0, 2.0, 3.1, 0.2, 0.2, false );
			show_dhudmessage( iPlayer, "|Level: [%d]| - |Exp: [%d] / [%d]|", Show_Level, Show_Exp, MAX_EXP );
		}
		else
		{
			set_dhudmessage( DHUD_RGB_MAXLEVEL, DHUD_FLOAT_X, DHUD_FLOAT_Y, 0, 2.0, 3.1, 0.2, 0.2, false );
			show_dhudmessage( iPlayer, "[Maximum Level] - (%d)", Show_Level );
		}
	}
}

public plugin_natives( )
{
	register_native( "_Get_User_Level_", "Native_Get_User_Level", 1 );
	register_native( "_Set_User_Level_", "Native_Set_User_Level", 1 );
	register_native( "_Get_User_Exp_", "Native_Get_User_Exp", 1 );
	register_native( "_Get_User_MaxLevel_", "Native_Get_User_MaxLevel", 1 );
}

public Native_Get_User_Level( iPlayer )
{
	if( is_user_connected( iPlayer ) && iPlayer > 0 )
	{
		return G_PlLEVEL[ iPlayer ];
	}
	return -1;
}

public Native_Set_User_Level( iPlayer, Level )
{
	if( is_user_connected( iPlayer ) && iPlayer > 0 )
	{
		if( Level < 1)
		{
			Level = 1;
		}
		else
		{
			if( Level > G_PlMAXLEVEL[ iPlayer ] )
			{
				Level = G_PlMAXLEVEL[ iPlayer ];
			}
			G_PlLEVEL[ iPlayer ] = Level;
			Save_MySQL( iPlayer );
		}
	}
}

public Native_Get_User_Exp( iPlayer )
{
	if( is_user_connected( iPlayer ) && iPlayer > 0 )
	{
		return G_PlEXP[ iPlayer ];
	}
	return -1;
}

public Native_Get_User_MaxLevel( iPlayer )
{
	return G_PlMAXLEVEL[ iPlayer ];
}

public MySQL_Init( )
{
	G_SQLTP = SQL_MakeDbTuple( SQL_USER_HOST, SQL_USER_LOGIN, SQL_USER_PASSWORD, SQL_USER_DATABASE );
	new UnAct_CODE;
	new Handle:QUERY;
	new Handle:CONNECT = SQL_Connect( G_SQLTP, UnAct_CODE, G_ERROR, charsmax( G_ERROR ) );
	if( CONNECT == Empty_Handle )
	{
		set_fail_state(G_ERROR);
	}	
	QUERY = SQL_PrepareQuery( CONNECT, "CREATE TABLE IF NOT EXISTS level_test9 ( Steamid varchar( 32 ), Exp INT( 5 ), Level INT( 5 ), MaxLevel INT( 5 ) )" );
	if( !SQL_Execute( QUERY ) )
	{
		SQL_QueryError( QUERY, G_ERROR, charsmax( G_ERROR ) );
		set_fail_state( G_ERROR );
	}
	SQL_FreeHandle( QUERY );
	SQL_FreeHandle( CONNECT );
	set_task( ADD_EXP, "Add_Exp", _, _, _, "b" );
}

public Add_Exp( )
{
	new BACK;
	for( new iPlayer = 0; iPlayer < MAX_SZ; iPlayer++ )
	if( is_user_connected( iPlayer ) && G_PlLEVEL[ iPlayer ] < G_PlMAXLEVEL[ iPlayer ] )
	{
		G_PlEXP[ iPlayer ]++;
		if( G_PlEXP[ iPlayer ] >= MAX_EXP )
		{
			G_PlEXP[ iPlayer ] -= MAX_EXP;
			G_PlLEVEL[ iPlayer ]++;
			ExecuteForward( G_PlLEVELUP, BACK, iPlayer );
		}
		Save_MySQL( iPlayer );
	}
}

public plugin_end( )
{
	SQL_FreeHandle( G_SQLTP );
}

public client_putinserver( iPlayer )
{
	G_LOAD[ iPlayer ] = 0;
	G_PlEXP[ iPlayer ] = 0;
	G_PlLEVEL[ iPlayer ] = 1;
	G_PlMAXLEVEL[ iPlayer ] = MAX_LEVEL;
	Load_MySQL( iPlayer );
}

public Load_MySQL( iPlayer )
{
	new STEAMID[ MAX_CLIENTS ];
	new TEMP[ MAX_BT ];
	new DATA[ 1 ];
	get_user_authid( iPlayer, STEAMID, charsmax( STEAMID ) );
	DATA[ 0 ] = iPlayer;
	format( TEMP, charsmax( TEMP ), "SELECT * FROM `level_test9` WHERE ( `level_test9`.`Steamid` = '%s' )", STEAMID );
	SQL_ThreadQuery( G_SQLTP, "Add_in_Base", TEMP, DATA, 1 );
	set_task( TIME_TASK3, "Loading", iPlayer );
}

public Loading( iPlayer )
{
	G_LOAD[ iPlayer ] = 1;
}

public Add_in_Base( FAIL, Handle:NUMBER, ERROR[ ], UnActCODE, DATA[ ], DATA_SZ )
{
	if( FAIL == TQUERY_CONNECT_FAILED )
	{
		log_amx( "Load - Could not connect to SQL database.  [%d] %s", UnActCODE, ERROR );
	}
	else
	{
		if( FAIL == TQUERY_QUERY_FAILED )
		{
			log_amx( "Load Query failed. [%d] %s", UnActCODE, ERROR );
		}
		new iPlayer = DATA[ 0 ];
		if( SQL_NumResults( NUMBER ) < 1 )
		{
			new STEAMID[ MAX_CLIENTS ];
			get_user_authid( iPlayer, STEAMID, charsmax( STEAMID ) );
			if ( equal( STEAMID, "ID_PENDING" ) || equal( STEAMID, "STEAM_ID_LAN" ) || equal( STEAMID, "VALVE_ID_LAN" ) || equal( STEAMID, "BOT" ) )
			{
				return PLUGIN_HANDLED;
			}
			new TEMP[ MAX_BT ];
			format( TEMP,charsmax( TEMP ), "INSERT INTO `level_test9` ( `Steamid` , `Exp` , `Level` , `MaxLevel` ) VALUES ('%s','0','1','%d');", STEAMID, MAX_LEVEL );
			SQL_ThreadQuery( G_SQLTP, "IgnoreHandle", TEMP );
		}
		else
		{
			G_PlEXP[ iPlayer ] = SQL_ReadResult( NUMBER, 1 );
			G_PlLEVEL[ iPlayer ] = SQL_ReadResult( NUMBER, 2 );
			G_PlMAXLEVEL[ iPlayer ] = SQL_ReadResult( NUMBER, 3 );
			if( G_PlMAXLEVEL[ iPlayer ] < MAX_LEVEL )
			{
				G_PlMAXLEVEL[ iPlayer ] = MAX_LEVEL;
			}
		}
		if( G_PlLEVEL[ iPlayer ] < 1 )
		{
			G_PlLEVEL[ iPlayer ] = 1;
		}
	}
	return PLUGIN_HANDLED;
}

public Save_MySQL( iPlayer )
{
	if( !G_LOAD[ iPlayer ] )
	{
		return;
	}
	new STEAMID[ MAX_CLIENTS ];
	new TEMP[ MAX_BT ];
	get_user_authid( iPlayer, STEAMID, charsmax( STEAMID ) );
	format( TEMP, charsmax( TEMP ),"UPDATE `level_test9` SET `Exp` = '%d' , `Level` = '%d' , `MaxLevel` = '%d' WHERE `level_test9`.`Steamid` = '%s';", G_PlEXP[ iPlayer ], G_PlLEVEL[ iPlayer ], G_PlMAXLEVEL[ iPlayer ], STEAMID );
	SQL_ThreadQuery( G_SQLTP, "IgnoreHandle", TEMP );
}

public IgnoreHandle( FAIL, Handle:NUMBER, ERROR[ ], UnActCODE, DATA[ ], DATA_SZ )
{
	SQL_FreeHandle( NUMBER );
	return PLUGIN_HANDLED;
}

public client_disconnect( iPlayer )
{
	Save_MySQL( iPlayer );
	G_LOAD[ iPlayer ] = 0;
}