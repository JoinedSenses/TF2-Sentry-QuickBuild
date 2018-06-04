#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#pragma newdecls required

ConVar g_hEnabled;
ConVar g_hSentryLevel;
ConVar g_hDispenserLevel;
ConVar g_hTeleportLevel;
Handle newWrench;

public Plugin myinfo = {
	name = "Sentry Quick Build", 
	author = "JoinedSenses", 
	description = "Enable quick build of sentries", 
	version = "1.2.0", 
	url = "https://github.com/JoinedSenses"
};
public void OnPluginStart(){
	g_hEnabled = CreateConVar("sm_quickbuild_enable", "1", "Enables/disables engineer quick build", FCVAR_NOTIFY);
	g_hSentryLevel = CreateConVar("qb_sentrylevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	g_hDispenserLevel = CreateConVar("qb_dispenserlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	g_hTeleportLevel = CreateConVar("qb_teleportlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	
	RegAdminCmd("sm_quickbuild", cmdQuickBuild, ADMFLAG_ROOT);
	RegAdminCmd("sm_sentrylevel", cmdSentryLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_dispenserlevel", cmdDispenserLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_teleportlevel", cmdTeleportLevel, ADMFLAG_ROOT);
	// RegAdminCmd("sm_testt", cmdTestt, ADMFLAG_ROOT);
	
	HookConVarChange(g_hEnabled, cvarEnableChanged);
	HookConVarChange(g_hSentryLevel, cvarChanged);
	HookConVarChange(g_hDispenserLevel, cvarChanged);
	HookConVarChange(g_hTeleportLevel, cvarChanged);
	
	HookEvent("player_builtobject", eventObjectBuilt);
	
	if (newWrench != null) delete newWrench;
	
	newWrench = TF2Items_CreateItem(PRESERVE_ATTRIBUTES|OVERRIDE_ATTRIBUTES);
	TF2Items_SetAttribute(newWrench, 0, 464, 100.0);
	TF2Items_SetAttribute(newWrench, 1, 465, 100.0);
	TF2Items_SetAttribute(newWrench, 2, 2043, 10.0);
	TF2Items_SetNumAttributes(newWrench, 3);
	
	if (GetConVarInt(g_hEnabled) == 1 )
		SetConVarInt(FindConVar("tf_fastbuild"), 1);
}
// public Action cmdTestt(int client, int args){
	// PrintToChat(client, "%i %i %i %i", g_hEnabled.IntValue, g_hSentryLevel.IntValue, g_hDispenserLevel.IntValue, g_hTeleportLevel.IntValue);
	// return Plugin_Handled;
// }
public void cvarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int i = 1; i <= MaxClients; i++){
		if (IsValidClient(i) && (TF2_GetPlayerClass(i) == TFClass_Engineer)){
			TF2_RemoveWeaponSlot(i, TFWeaponSlot_Melee)
			TF2_RegeneratePlayer(i)
		}
	}
	if (StringToInt(newValue)  == 1){
		SetConVarInt(FindConVar("tf_fastbuild"), 1);
		return;
	}
	else{
		SetConVarInt(FindConVar("tf_fastbuild"), 0);
		SetConVarInt(convar, 0);
	}
}
public void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	int iValue = StringToInt(newValue);
	if (0 < iValue <=3)
		return;
	else
		SetConVarInt(convar, 1);
}
public Action cmdQuickBuild(int client, int args){
	if (args == 0){
		bool status = GetConVarBool(g_hEnabled);
		if (status)
			SetConVarInt(g_hEnabled, 0);
		else
			SetConVarInt(g_hEnabled, 1);
		return Plugin_Handled;
	}
	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));
	if (StrEqual(sArg, "enable") || StrEqual(sArg, "enabled") || StrEqual(sArg, "1"))
		SetConVarInt(g_hEnabled, 1);
	else if (StrEqual(sArg, "disable") || StrEqual(sArg, "disabled") ||StrEqual(sArg, "0"))
		SetConVarInt(g_hEnabled, 0);
	else{
		ReplyToCommand(client, "Incorrect parameters. Try enable, disable, 0, or 1");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action cmdSentryLevel(int client, int args){
	if (args == 0){
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}
	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));
	int iArg = StringToInt(sArg);
	if ( 0 < iArg <= 3)
		SetConVarInt(g_hSentryLevel, iArg);
	else
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	return Plugin_Handled;
}
public Action cmdDispenserLevel(int client, int args){
	if (args == 0){
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}
	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));
	int iArg = StringToInt(sArg);
	if ( 0 < iArg <= 3)
		SetConVarInt(g_hDispenserLevel, iArg);
	else
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	return Plugin_Handled;
}
public Action cmdTeleportLevel(int client, int args){
	if (args == 0){
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}
	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));
	int iArg = StringToInt(sArg);
	if ( 0 < iArg <= 3)
		SetConVarInt(g_hTeleportLevel, iArg);
	else
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	return Plugin_Handled;
}
public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int defindex, Handle &item) {
	if (GetConVarInt(g_hEnabled) == 0 ) return Plugin_Continue;
	
	if (!StrContains(classname, "tf_weapon_wrench") || !StrContains(classname, "tf_weapon_robot_arm")){
		item = newWrench;
		return Plugin_Changed;
	}
	return Plugin_Continue;
} 
public Action eventObjectBuilt(Event event, const char[] name, bool dontBroadcast){
	if (GetConVarInt(g_hEnabled) == 0 ) 
		return Plugin_Continue;
	char sValue[8];
	int obj = GetEventInt(event, "object"), index = GetEventInt(event, "index");
	if (obj == 0){
		IntToString(g_hDispenserLevel.IntValue -1, sValue, sizeof(sValue));
	}
	else if (obj == 1){
		IntToString(g_hTeleportLevel.IntValue -1, sValue, sizeof(sValue));
		SetEntProp(index, Prop_Send, "m_CollisionGroup", 1);
	}	
	else if (obj == 2){
		int mini = GetEntProp(index, Prop_Send, "m_bMiniBuilding");
		if (mini == 1) return Plugin_Continue;
		
		IntToString(g_hSentryLevel.IntValue -1, sValue, sizeof(sValue));
	}
	DispatchKeyValue(index, "defaultupgrade", sValue);
	return Plugin_Continue;
}
bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client))
		return false;
	return true;
}