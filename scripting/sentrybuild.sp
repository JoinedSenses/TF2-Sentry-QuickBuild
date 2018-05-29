#include <sourcemod>
#include <tf2attributes>
#include <tf2_stocks>

ConVar g_hSentryLevel;
ConVar g_hDispenserLevel;
ConVar g_hTeleportLevel;

public Plugin myinfo = {
	name = "Sentry Quick Build", 
	author = "JoinedSenses", 
	description = "Enable quick build of sentries", 
	version = "1.0.0", 
	url = "https://github.com/JoinedSenses"
};
public void OnPluginStart(){
	g_hSentryLevel = CreateConVar("sm_sentrylevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	g_hDispenserLevel = CreateConVar("sm_dispenserlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	g_hTeleportLevel = CreateConVar("sm_teleportlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	
	HookEvent("player_builtobject", eventObjectBuilt);
}
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, entity)
{
	char sClassName[128];
	GetEntityClassname(entity, sClassName, sizeof(sClassName));
	
	if (!StrContains(sClassName, "tf_weapon_wrench") || !StrContains(sClassName, "tf_weapon_robot_arm")){
		TF2Attrib_SetByDefIndex(entity, 464, 100.0);
		TF2Attrib_SetByDefIndex(entity, 465, 100.0);
		TF2Attrib_SetByDefIndex(entity, 321, 100.0);
		TF2Attrib_SetByDefIndex(entity, 2043, 100.0);
	}
} 

public Action eventObjectBuilt(Event event, const char[] name, bool dontBroadcast){
	int obj = GetEventInt(event, "object"), index = GetEventInt(event, "index");
	if (obj == 0){
		if (GetConVarInt(g_hDispenserLevel) == 2)
			DispatchKeyValue(index, "defaultupgrade", "1");
		else if (GetConVarInt(g_hDispenserLevel) == 3)
			DispatchKeyValue(index, "defaultupgrade", "2");
		else 
			DispatchKeyValue(index, "defaultupgrade", "0");
	}
	else if (obj == 1){
		if (GetConVarInt(g_hTeleportLevel) == 2)
			DispatchKeyValue(index, "defaultupgrade", "1");
		else if (GetConVarInt(g_hTeleportLevel) == 3)
			DispatchKeyValue(index, "defaultupgrade", "2");
		else 
			DispatchKeyValue(index, "defaultupgrade", "0");
	}	
	else if (obj == 2){
		int mini = GetEntProp(index, Prop_Send, "m_bMiniBuilding");
		if (mini == 1) return Plugin_Continue;
		
		if (GetConVarInt(g_hSentryLevel) == 2)
			DispatchKeyValue(index, "defaultupgrade", "1");
		else if (GetConVarInt(g_hSentryLevel) == 3)
			DispatchKeyValue(index, "defaultupgrade", "2");
		else 
			DispatchKeyValue(index, "defaultupgrade", "0");
	}
	else {
		DispatchKeyValue(index, "defaultupgrade", "2");
	}
	return Plugin_Continue;
}