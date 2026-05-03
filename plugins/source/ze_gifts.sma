// ZE Gifts Event — solo el owner (ADMIN_RCON) puede tirarlos
// ze_gift_event [cantidad] — dispersa regalos por el mapa que se mueven solos
#include <amxmodx>
#include <fakemeta>
#include <engine>

#define PLUGIN "ZE Gifts Event"
#define VERSION "1.0"
#define AUTHOR "djp"

// ZE natives
native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id, amount)
native zp_add_user_points(id, team, amount)    // TEAM_HUMAN=0, TEAM_ZOMBIE=1

#define GIFT_CLASS      "ze_gift"
#define KICK_INTERVAL   3.0      // segundos entre impulsos de velocidad
#define KICK_SPEED      280.0    // velocidad horizontal del impulso
#define MAX_GIFTS       30

new const g_models[][] = { "models/eqbiggift.mdl", "models/eqsmallgift.mdl" }

new g_maxplayers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("ze_gift_event", "cmd_gifts", ADMIN_RCON, "[count] Lanza regalos por el mapa")

	register_forward(FM_Touch, "fw_touch")
	register_think(GIFT_CLASS, "think_gift")

	// Limpia regalos al inicio de cada ronda
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")

	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
	for(new i = 0; i < sizeof g_models; i++)
		precache_model(g_models[i])
}

// ---- Comando ----
public cmd_gifts(id)
{
	new arg[8]
	read_argv(1, arg, charsmax(arg))
	new count = (arg[0]) ? clamp(str_to_num(arg), 1, MAX_GIFTS) : 10

	new spawned = 0
	new players[32], num
	get_players(players, num, "a")

	if(num == 0)
	{
		console_print(id, "[Z-Evil] No hay jugadores vivos para spawnear regalos cerca.")
		return PLUGIN_HANDLED
	}

	for(new i = 0; i < count; i++)
	{
		// Base: posicion aleatoria cerca de un jugador aleatorio
		new base_id = players[random_num(0, num-1)]
		new Float:origin[3]
		pev(base_id, pev_origin, origin)
		origin[0] += random_float(-600.0, 600.0)
		origin[1] += random_float(-600.0, 600.0)
		origin[2] += 50.0

		if(spawn_gift(origin))
			spawned++
	}

	if(spawned > 0)
	{
		client_cmd(0, "spk items/gunpickup2.wav")
		client_print(0, print_chat, "[Z-Evil] El owner tiro %d regalos en el mapa!", spawned)
	}
	return PLUGIN_HANDLED
}

// ---- Spawn de un regalo ----
bool:spawn_gift(Float:origin[3])
{
	new ent = create_entity("info_target")
	if(!pev_valid(ent)) return false

	new model = random_num(0, sizeof g_models - 1)
	entity_set_string(ent, EV_SZ_classname, GIFT_CLASS)
	engfunc(EngFunc_SetModel, ent, g_models[model])
	engfunc(EngFunc_SetOrigin, ent, origin)

	entity_set_size(ent, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,25.0})
	set_pev(ent, pev_solid,   SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)

	// Velocidad inicial aleatoria
	new Float:vel[3]
	vel[0] = random_float(-KICK_SPEED, KICK_SPEED)
	vel[1] = random_float(-KICK_SPEED, KICK_SPEED)
	vel[2] = random_float(150.0, 300.0)
	set_pev(ent, pev_velocity, vel)

	// Primer think
	set_pev(ent, pev_nextthink, get_gametime() + KICK_INTERVAL)

	return true
}

// ---- Think: impulso periodico para que sigan moviendose ----
public think_gift(ent)
{
	if(!pev_valid(ent)) return

	new Float:vel[3]
	vel[0] = random_float(-KICK_SPEED, KICK_SPEED)
	vel[1] = random_float(-KICK_SPEED, KICK_SPEED)
	vel[2] = random_float(80.0, 200.0)
	set_pev(ent, pev_velocity, vel)

	set_pev(ent, pev_nextthink, get_gametime() + KICK_INTERVAL)
}

// ---- Touch: jugador agarra regalo ----
public fw_touch(ent, other)
{
	// ent puede ser el regalo o el jugador segun quien se mueve
	new gift, player

	if(pev_valid(ent) && other >= 1 && other <= g_maxplayers)
	{
		static cls[32]
		pev(ent, pev_classname, cls, 31)
		if(equal(cls, GIFT_CLASS)) { gift = ent; player = other; }
	}

	if(!gift && ent >= 1 && ent <= g_maxplayers && pev_valid(other))
	{
		static cls[32]
		pev(other, pev_classname, cls, 31)
		if(equal(cls, GIFT_CLASS)) { gift = other; player = ent; }
	}

	if(!gift || !player) return FMRES_IGNORED
	if(!is_user_alive(player)) return FMRES_IGNORED

	give_gift_reward(player)
	engfunc(EngFunc_RemoveEntity, gift)
	return FMRES_IGNORED
}

// ---- Recompensa aleatoria ----
give_gift_reward(id)
{
	switch(random_num(0, 2))
	{
		case 0:  // Ammo Packs
		{
			new ap = random_num(5, 20)
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + ap)
			client_print(id, print_chat, "[Z-Evil] Regalo: +%d Ammo Packs!", ap)
		}
		case 1:  // Puntos zombie
		{
			new pts = random_num(1, 3)
			zp_add_user_points(id, 1, pts)
			client_print(id, print_chat, "[Z-Evil] Regalo: +%d puntos zombie!", pts)
		}
		case 2:  // Puntos humano
		{
			new pts = random_num(1, 3)
			zp_add_user_points(id, 0, pts)
			client_print(id, print_chat, "[Z-Evil] Regalo: +%d puntos humano!", pts)
		}
	}
	emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// ---- Limpieza al iniciar ronda ----
public event_new_round()
{
	new ent = -1
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", GIFT_CLASS)) > 0)
		engfunc(EngFunc_RemoveEntity, ent)
}
