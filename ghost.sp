#pragma newdecls required
#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

enum struct PlayerData
{
    bool bGhost;
    float flTime;

    void Reset()
    {
        this.bGhost = false;
        this.flTime = -1.0;
    }
}

PlayerData g_playerData[MAXPLAYERS + 1];
StringMap g_hClassMap;

public Plugin myinfo =
{
    name = "Ghost",
    author = "koen",
    description = "Gives player noclip and makes them impervious to triggers",
    version = "0.1.1",
};

public void OnPluginStart()
{
    RegAdminCmd("sm_ghost", Command_Ghost, ADMFLAG_ROOT, "Toggle ghost mode");
    HookEvent("round_start", OnRoundStart, EventHookMode_Pre);

    delete g_hClassMap;

    g_hClassMap = new StringMap();
    g_hClassMap.SetValue("trigger_once", true);
    g_hClassMap.SetValue("trigger_teleport", true);
    g_hClassMap.SetValue("trigger_multiple", true);
    g_hClassMap.SetValue("trigger_hurt", true);
    g_hClassMap.SetValue("logic_relay", true);
}

public void OnPluginEnd()
{
    delete g_hClassMap;
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].Reset();
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsFakeClient(client) || !IsPlayerAlive(client))
            continue;

        g_playerData[client].Reset();
        SetEntityMoveType(client, MOVETYPE_WALK);
    }
}

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    bool check;
    if (g_hClassMap.GetValue(szClassname, check))
    {
        SDKHook(iEntity, SDKHook_Use, OnEntityTrigger);
        SDKHook(iEntity, SDKHook_StartTouch, OnEntityTrigger);
        SDKHook(iEntity, SDKHook_Touch, OnEntityTrigger);
        SDKHook(iEntity, SDKHook_EndTouch, OnEntityTrigger);
    }
}

public Action OnEntityTrigger(int iEntity, int client)
{
    if (!(client > 0 && client <= MaxClients) || IsFakeClient(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (!g_playerData[client].bGhost)
        return Plugin_Continue;

    if ((g_playerData[client].flTime + 4.0) < GetGameTime())
    {
        PrintToChat(client, "[Ghost] You are currently ghosted. Enter \"!ghost\" to exit ghost mode.");
        PrintHintText(client, "[Ghost] You are currently ghosted.");
        g_playerData[client].flTime = GetGameTime();
    }

    return Plugin_Handled;
}

public Action Command_Ghost(int client, int args)
{
    if (!client)
    {
        PrintToConsole(client, "[Ghost] You cannot use this command from the console.");
        return Plugin_Handled;
    }

    if (!g_playerData[client].bGhost)
    {
        g_playerData[client].bGhost = true;
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
    }
    else
    {
        g_playerData[client].bGhost = false;
        SetEntityMoveType(client, MOVETYPE_WALK);
    }

    LogAction(client, -1, "[Ghost] %N has %s ghost mode.", client, g_playerData[client].bGhost ? "entered" : "left");
    PrintToChatAll("[Ghost] %N has %s ghost mode.", client, g_playerData[client].bGhost ? "entered" : "left");

    return Plugin_Handled;
}