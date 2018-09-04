#pragma newdecls required
#pragma semicolon 1
#define PLUGIN_VERSION "2.2.0"
#include <sourcemod>
#include <sdktools>

ConVar
	  g_hEnabled
	, g_hSentryLevel
	, g_hDispenserLevel
	, g_hTeleportLevel;
Handle
	  g_hSDKStartBuilding
	, g_hSDKFinishBuilding
	, g_hSDKStartUpgrading
	, g_hSDKFinishUpgrading;

public Plugin myinfo = {
	name = "Sentry Quick Build", 
	author = "JoinedSenses", 
	description = "Enable quick build of sentries", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/JoinedSenses"
};

public void OnPluginStart() {
	CreateConVar("sm_quickbuild_version", PLUGIN_VERSION, "Sentry Quickbuild Version",  FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_quickbuild_enable", "1", "Enables/disables engineer quick build", FCVAR_NOTIFY);
	g_hSentryLevel = CreateConVar("qb_sentrylevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	g_hDispenserLevel = CreateConVar("qb_dispenserlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	g_hTeleportLevel = CreateConVar("qb_teleportlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	
	RegAdminCmd("sm_quickbuild", cmdQuickBuild, ADMFLAG_ROOT);
	RegAdminCmd("sm_sentrylevel", cmdSentryLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_dispenserlevel", cmdDispenserLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_teleportlevel", cmdTeleportLevel, ADMFLAG_ROOT);
	
	g_hEnabled.AddChangeHook(cvarEnableChanged);
	g_hSentryLevel.AddChangeHook(cvarChanged);
	g_hDispenserLevel.AddChangeHook(cvarChanged);
	g_hTeleportLevel.AddChangeHook(cvarChanged);
	
	HookEvent("player_builtobject", eventObjectBuilt);
	HookEvent("player_upgradedobject", eventUpgradedObject);
	
	FindConVar("tf_cheapobjects").SetInt(1);
	
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/buildings.txt");
	if(FileExists(sFilePath)) {
		Handle hGameConf = LoadGameConfigFile("buildings");
		if(hGameConf != INVALID_HANDLE ) {
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartBuilding");
			g_hSDKStartBuilding = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::FinishedBuilding");
			g_hSDKFinishBuilding = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartUpgrading");
			g_hSDKStartUpgrading = EndPrepSDKCall();
			
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::FinishUpgrading");
			g_hSDKFinishUpgrading = EndPrepSDKCall();
			
			delete hGameConf;
		}
		if (g_hSDKStartBuilding == null ||g_hSDKFinishBuilding == null || g_hSDKStartUpgrading == null || g_hSDKFinishUpgrading == null) {
			LogError("Failed to load buildings gamedata.  Instant building and upgrades will not be available.");
		}
	}
}

public void cvarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (StringToInt(newValue) == 1) {
		return;
	}
	convar.SetInt(0);
}

public void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (0 < StringToInt(newValue) <= 3) {
		return;
	}
	convar.SetInt(1);
}

public Action cmdQuickBuild(int client, int args) {
	if (args == 0) {
		g_hEnabled.SetInt(g_hEnabled.BoolValue ? 0 : 1);
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	if (StrEqual(sArg, "enable") || StrEqual(sArg, "enabled") || StrEqual(sArg, "1")) {
		g_hEnabled.SetInt(1);
	}
	else if (StrEqual(sArg, "disable") || StrEqual(sArg, "disabled") ||StrEqual(sArg, "0")) {
		g_hEnabled.SetInt(0);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Try enable, disable, 0, or 1");
	}
	return Plugin_Handled;
}

public Action cmdSentryLevel(int client, int args) {
	if (args == 0) {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if ( 0 < iArg <= 3) {
		g_hSentryLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}
	return Plugin_Handled;
}

public Action cmdDispenserLevel(int client, int args) {
	if (args == 0) {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if ( 0 < iArg <= 3) {
		g_hDispenserLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}
	return Plugin_Handled;
}

public Action cmdTeleportLevel(int client, int args) {
	if (args == 0) {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if ( 0 < iArg <= 3) {
		g_hTeleportLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}
	return Plugin_Handled;
}

public Action eventObjectBuilt(Event event, const char[] name, bool dontBroadcast) {
	if (GetConVarInt(g_hEnabled) == 0 ) {
		return Plugin_Continue;
	}
		
	int obj = event.GetInt("object");
	int index = event.GetInt("index");
	
	if (g_hSDKStartBuilding == null ||g_hSDKFinishBuilding == null || g_hSDKStartUpgrading == null || g_hSDKFinishUpgrading == null) {
		return Plugin_Continue;
	}
		
	RequestFrame(FrameCallback_StartBuilding, index);
	RequestFrame(FrameCallback_FinishBuilding, index);
	
	int maxupgradelevel = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");
	
	if (obj == 0) {
		if (maxupgradelevel >  g_hDispenserLevel.IntValue) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
		else if(g_hDispenserLevel.IntValue != 1) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", g_hDispenserLevel.IntValue-1);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", g_hDispenserLevel.IntValue-1);
			RequestFrame(FrameCallback_StartUpgrading, index);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
	}
	else if (obj == 1) {
		if (maxupgradelevel >  g_hTeleportLevel.IntValue) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
		else if(g_hTeleportLevel.IntValue != 1) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", g_hTeleportLevel.IntValue-1);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", g_hTeleportLevel.IntValue-1);
			RequestFrame(FrameCallback_StartUpgrading, index);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
		SetEntProp(index, Prop_Send, "m_CollisionGroup", 2);
	}	
	else if (obj == 2) {
		int mini = GetEntProp(index, Prop_Send, "m_bMiniBuilding");
		if (mini == 1) {
			return Plugin_Continue;
		}
		if (maxupgradelevel >  g_hSentryLevel.IntValue) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
		else if(g_hSentryLevel.IntValue != 1) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", g_hSentryLevel.IntValue-1);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", g_hSentryLevel.IntValue-1);
			RequestFrame(FrameCallback_StartUpgrading, index);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
	}
	SetEntProp(index, Prop_Send, "m_iUpgradeMetalRequired", 0);
	SetVariantInt(GetEntProp(index, Prop_Data, "m_iMaxHealth"));
	AcceptEntityInput(index, "SetHealth");
	return Plugin_Continue;
}

public Action eventUpgradedObject(Event event, const char[] sName, bool bDontBroadcast) {
	if (g_hSDKFinishUpgrading != null) {
		int entity = event.GetInt("index");
		RequestFrame(FrameCallback_FinishUpgrading, entity);
	}
	return Plugin_Continue;
}

public void FrameCallback_StartBuilding(any entity) {
	SDKCall(g_hSDKStartBuilding, entity);
}

public void FrameCallback_FinishBuilding(any entity) {
	SDKCall(g_hSDKFinishBuilding, entity);
}

public void FrameCallback_StartUpgrading(any entity) {
	SDKCall(g_hSDKStartUpgrading, entity);
}

public void FrameCallback_FinishUpgrading(any entity) {
	SDKCall(g_hSDKFinishUpgrading, entity);
}