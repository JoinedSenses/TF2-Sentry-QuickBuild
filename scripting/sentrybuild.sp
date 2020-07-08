#pragma newdecls required
#pragma semicolon 1
#define PLUGIN_VERSION "2.3.2"
#include <sourcemod>
#include <sdktools>

enum {
	OBJ_DISPENSER,
	OBJ_TELEPORTER,
	OBJ_SENTRY
}

ConVar
	  cvarEnabled
	, cvarSentryLevel
	, cvarDispenserLevel
	, cvarTeleportLevel
	, cvarDisableTeleCollision;
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

// --------------- SM API

public void OnPluginStart() {
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/buildings.txt");
	if(!FileExists(sFilePath)) {
		SetFailState("Gamedata file not found. Expected gamedata/buildings.txt");
	}

	GameData data = new GameData("buildings");
	if (!data) {
		SetFailState("Failed to open gamedata.buildings.txt. Unable to load plugin");
	}

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "CBaseObject::StartBuilding");
	g_hSDKStartBuilding = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "CBaseObject::FinishedBuilding");
	g_hSDKFinishBuilding = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "CBaseObject::StartUpgrading");
	g_hSDKStartUpgrading = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "CBaseObject::FinishUpgrading");
	g_hSDKFinishUpgrading = EndPrepSDKCall();
	
	delete data;

	bool error;
	if (!g_hSDKStartBuilding) {
		LogError("Failed to load gamedata for CBaseObject::StartBuilding");
		error = true;
	}

	if (!g_hSDKFinishBuilding) {
		LogError("Failed to load gamedata for CBaseObject::FinishedBuilding");
		error = true;
	}

	if (!g_hSDKStartUpgrading) {
		LogError("Failed to load gamedata for CBaseObject::StartUpgrading");
		error = true;
	}

	if (!g_hSDKFinishUpgrading) {
		LogError("Failed to load gamedata for CBaseObject::FinishUpgrading");
		error = true;
	}

	if (error) {
		SetFailState("Gamedata failure detected. Unable to load plugin.");
	}

	// ConVars
	CreateConVar("sm_quickbuild_version", PLUGIN_VERSION, "Sentry Quickbuild Version",  FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_quickbuild_enable", "1", "Enables/disables engineer quick build", FCVAR_NOTIFY);
	cvarSentryLevel = CreateConVar("qb_sentrylevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	cvarDispenserLevel = CreateConVar("qb_dispenserlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	cvarTeleportLevel = CreateConVar("qb_teleportlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	cvarDisableTeleCollision = CreateConVar("qb_disabletelecollision", "1", "Prevents other players from colliding with teles", FCVAR_NOTIFY);

	cvarEnabled.AddChangeHook(cvarEnableChanged);
	cvarSentryLevel.AddChangeHook(cvarChanged);
	cvarDispenserLevel.AddChangeHook(cvarChanged);
	cvarTeleportLevel.AddChangeHook(cvarChanged);

	FindConVar("tf_cheapobjects").SetInt(1);

	// Commands
	RegAdminCmd("sm_quickbuild", cmdQuickBuild, ADMFLAG_ROOT);
	RegAdminCmd("sm_sentrylevel", cmdSentryLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_dispenserlevel", cmdDispenserLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_teleportlevel", cmdTeleportLevel, ADMFLAG_ROOT);

	// Hooks
	HookEvent("player_builtobject", eventObjectBuilt);
	HookEvent("player_upgradedobject", eventUpgradedObject);
}

// --------------- CVAR Hook

public void cvarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	int value = StringToInt(newValue);
	if (value < 0 || value > 1) {
		convar.SetInt(0);
	}
}

public void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	int value = StringToInt(newValue);
	if (value < 1 || value > 3) {
		convar.SetInt(1);
	}
}

// --------------- Commands

public Action cmdQuickBuild(int client, int args) {
	if (!args) {
		cvarEnabled.SetBool(!cvarEnabled.BoolValue);
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	if (StrEqual(sArg, "enable") || StrEqual(sArg, "enabled") || StrEqual(sArg, "1")) {
		cvarEnabled.SetInt(1);
	}
	else if (StrEqual(sArg, "disable") || StrEqual(sArg, "disabled") || StrEqual(sArg, "0")) {
		cvarEnabled.SetInt(0);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Try enable, disable, 0, or 1");
	}

	return Plugin_Handled;
}

public Action cmdSentryLevel(int client, int args) {
	if (!args) {
		ReplyToCommand(client, "Usage: sm_sentrylevel <1, 2, 3>");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if (0 < iArg < 4) {
		cvarSentryLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}

	return Plugin_Handled;
}

public Action cmdDispenserLevel(int client, int args) {
	if (!args) {
		ReplyToCommand(client, "Usage: sm_dispenserlevel <1, 2, 3>");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if (0 < iArg < 4) {
		cvarDispenserLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}

	return Plugin_Handled;
}

public Action cmdTeleportLevel(int client, int args) {
	if (!args) {
		ReplyToCommand(client, "Usage: sm_teleportlevel <1, 2, 3>");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if (0 < iArg < 4) {
		cvarTeleportLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}

	return Plugin_Handled;
}

// --------------- Events

public Action eventObjectBuilt(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarEnabled.BoolValue) {
		return Plugin_Continue;
	}
		
	int obj = event.GetInt("object");
	int entity = event.GetInt("index");
	int entRef = EntIndexToEntRef(entity);

	RequestFrame(frame_StartAndFinishBuild, entity);
	
	int maxupgradelevel = GetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel");
	switch (obj) {
		case OBJ_DISPENSER: {
			if (maxupgradelevel >  cvarDispenserLevel.IntValue) {
				SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
				RequestFrame(frame_FinishUpgrade, entity);
			}
			else if(cvarDispenserLevel.IntValue != 1) {
				SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", cvarDispenserLevel.IntValue-1);
				SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", cvarDispenserLevel.IntValue-1);
				RequestFrame(frame_StartAndFinishUpgrade, entRef);
			}
		}
		case OBJ_TELEPORTER: {
			if (maxupgradelevel >  cvarTeleportLevel.IntValue) {
				SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
				RequestFrame(frame_FinishUpgrade, entRef);
			}
			else if(cvarTeleportLevel.IntValue != 1) {
				SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", cvarTeleportLevel.IntValue-1);
				SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", cvarTeleportLevel.IntValue-1);
				RequestFrame(frame_StartAndFinishUpgrade, entRef);
			}

			if (cvarDisableTeleCollision.BoolValue) {
				SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);	
			}
		}
		case OBJ_SENTRY: {
			int mini = GetEntProp(entity, Prop_Send, "m_bMiniBuilding");
			if (mini == 1) {
				return Plugin_Continue;
			}

			if (maxupgradelevel >  cvarSentryLevel.IntValue) {
				SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
				RequestFrame(frame_FinishUpgrade, entRef);
			}
			else if(cvarSentryLevel.IntValue != 1) {
				SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", cvarSentryLevel.IntValue-1);
				SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", cvarSentryLevel.IntValue-1);
				RequestFrame(frame_StartAndFinishUpgrade, entRef);
			}
		}
	}

	SetEntProp(entity, Prop_Send, "m_iUpgradeMetalRequired", 0);
	SetVariantInt(GetEntProp(entity, Prop_Data, "m_iMaxHealth"));
	AcceptEntityInput(entity, "SetHealth");
	return Plugin_Continue;
}

public Action eventUpgradedObject(Event event, const char[] sName, bool bDontBroadcast) {
	if (cvarEnabled.BoolValue) {
		RequestFrame(frame_FinishUpgrade, EntIndexToEntRef(event.GetInt("index")));
	}

	return Plugin_Continue;
}

// --------------- VFunction Callbacks

public void frame_StartAndFinishBuild(int entRef) {
	int entity = EntRefToEntIndex(entRef);
	if (entity > 0) {
		SDKCall(g_hSDKStartBuilding, entity);
		SDKCall(g_hSDKFinishBuilding, entity);
	}
}

public void frame_StartAndFinishUpgrade(int entRef) {
	int entity = EntRefToEntIndex(entRef);
	if (entity > 0) {
		SDKCall(g_hSDKStartUpgrading, entity);
		SDKCall(g_hSDKFinishUpgrading, entity);
	}
}

public void frame_FinishUpgrade(int entRef) {
	int entity = EntRefToEntIndex(entRef);
	if (entity > 0) {
		SDKCall(g_hSDKFinishUpgrading, entity);
	}
}