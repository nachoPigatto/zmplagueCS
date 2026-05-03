#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new g_bot_id

public plugin_init()
{
    register_plugin("ZE Test Bot", "1.0", "server")
    register_clcmd("ze_addbot",    "cmd_addbot",    ADMIN_RCON, "Spawn a test bot")
    register_clcmd("ze_removebot", "cmd_removebot", ADMIN_RCON, "Remove test bot")
}

public cmd_addbot(id)
{
    if(g_bot_id && is_user_connected(g_bot_id))
    {
        console_print(id, "[TestBot] Bot ya esta en el servidor.")
        return PLUGIN_HANDLED
    }

    new ent = engfunc(EngFunc_CreateFakeClient, "TestBot")
    if(!ent)
    {
        console_print(id, "[TestBot] Error: no se pudo crear el bot.")
        return PLUGIN_HANDLED
    }

    new szRejectReason[128]
    dllfunc(DLLFunc_ClientConnect, ent, "TestBot", "127.0.0.1", "", szRejectReason, 127)
    dllfunc(DLLFunc_ClientPutInServer, ent)

    g_bot_id = ent
    set_task(0.5, "bot_join_team", ent)
    console_print(id, "[TestBot] Bot creado (id %d).", ent)
    return PLUGIN_HANDLED
}

public bot_join_team(ent)
{
    if(!is_user_connected(ent)) return
    engclient_cmd(ent, "jointeam", "2")
    set_task(0.5, "bot_join_class", ent)
}

public bot_join_class(ent)
{
    if(!is_user_connected(ent)) return
    engclient_cmd(ent, "joinclass", "1")
}

public cmd_removebot(id)
{
    if(!g_bot_id || !is_user_connected(g_bot_id))
    {
        console_print(id, "[TestBot] No hay bot activo.")
        return PLUGIN_HANDLED
    }
    server_cmd("kick #%d", get_user_userid(g_bot_id))
    g_bot_id = 0
    console_print(id, "[TestBot] Bot removido.")
    return PLUGIN_HANDLED
}

public client_disconnected(id)
{
    if(id == g_bot_id) g_bot_id = 0
}
