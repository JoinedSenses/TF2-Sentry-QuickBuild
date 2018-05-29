#include <sourcemod>
#include <tf2attributes>
#include <tf2_stocks>

Handle g_hSentryLevel;

public Plugin myinfo = {
	name = "Sentry Quick Build", 
	author = "JoinedSenses", 
	description = "Enable quick build of sentries", 
	version = "1.0.0", 
	url = "https://github.com/JoinedSenses"
};
public void OnPluginStart(){
    g_hSentryLevel = CreateConVar("ja_sglevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
    HookConVarChange(g_hSentryLevel, cvarSentryLevelChanged);
    HookEvent("player_builtobject", eventObjectBuilt);
}
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, entity)
{
    char szClassname[128];
    GetEntityClassname(entity, szClassname, sizeof(szClassname));
    
    if (!StrContains(szClassname, "tf_weapon_wrench") || !StrContains(szClassname, "tf_weapon_robot_arm")){
        switch (index){
            default:{
                TF2Attrib_SetByDefIndex(entity, 464, 100.0);
                TF2Attrib_SetByDefIndex(entity, 465, 100.0);
                TF2Attrib_SetByDefIndex(entity, 321, 100.0);
                TF2Attrib_SetByDefIndex(entity, 2043, 100.0);
            }
        }
    }
} 
public cvarSentryLevelChanged(Handle convar, const char[] oldValue, const char[] newValue){
    if (StringToInt(newValue) == 0)
        SetConVarBool(g_hSentryLevel, false);
    else
        SetConVarBool(g_hSentryLevel, true);
}

public Action eventObjectBuilt(Event event, const char[] name, bool dontBroadcast){
    int obj = GetEventInt(event, "object"), index = GetEventInt(event, "index");
    if (obj == 2) {
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