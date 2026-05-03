// ZE Bazooka — lanzado como una granada (flashbang slot)
// El nemesis recibe flashbangs segun cantidad de jugadores.
// Se recarga acumulando daño recibido como Nemesis.
// Cuchillo no se toca, no se cambia ningun viewmodel.
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>

#define PLUGIN "ZE Bazooka (grenade)"
#define VERSION "1.3"
#define AUTHOR "djp"

#define TASK_SEEK_CATCH 9000

// ZE natives
native zp_get_user_zombie(id)
native zp_get_user_nemesis(id)
native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id, amount)

static const mrocket[]  = "models/zombie_plague/rpgrocket_vechta.mdl"
static const mrpg_w[]   = "models/zombie_plague/w_rpg_vechta.mdl"

static const sfire[]    = "weapons/rocketfire1.wav"
static const sfly[]     = "weapons/nuke_fly.wav"
static const shit[]     = "weapons/mortarhit.wav"
static const spickup[]  = "items/gunpickup2.wav"

new pcvar_maxdmg, pcvar_radius, pcvar_speed
new pcvar_speed_homing, pcvar_award, pcvar_dmgthreshold
new pcvar_charge_perplayer  // daño-por-jugador necesario para 1 recarga (escala igual que HP del Nemesis)

new rocketsmoke, white

new dmgcount[33]
new bool:g_hasbazooka[33]
new g_bazooka_ammo[33]              // cargas actuales
new g_bazooka_max_ammo[33]          // maximo segun jugadores al inicio
new g_bazooka_charge[33]            // daño acumulado hacia proxima carga
new g_bazooka_charge_threshold[33]  // threshold calculado al inicio de ronda
new mode[33]   // 1=normal, 2=homing

new gmsg_death, gmsg_damage, Saytxt

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	pcvar_maxdmg       = register_cvar("zp_bazooka_damage",      "650")
	pcvar_radius       = register_cvar("zp_bazooka_radius",      "250")
	pcvar_award        = register_cvar("zp_bazooka_awardpacks",  "1")
	pcvar_speed        = register_cvar("zp_bazooka_speed",       "900")
	pcvar_speed_homing = register_cvar("zp_bazooka_homing_speed","350")
	pcvar_dmgthreshold   = register_cvar("zp_bazooka_dmgthreshold",   "500")
	// Daño por jugador que el Nemesis debe recibir para recargar 1 cohete
	// Escala igual que su vida (1250 * jugadores). Default 250 = 20% de una vida por carga
	pcvar_charge_perplayer = register_cvar("zp_bazooka_charge_perplayer", "250")

	// Interceptar el lanzamiento de la granada → convertirla en cohete
	register_forward(FM_SetModel, "fw_set_model")
	register_forward(FM_Touch, "fw_touch")

	// Daño recibido como Nemesis carga la bazooka
	RegisterHam(Ham_TakeDamage, "player", "fw_take_damage")

	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")

	register_concmd("ze_bazooka", "cmd_give_bazooka", ADMIN_BAN, "<name/@all>")
	register_clcmd("ze_bazooka_homing", "cmd_toggle_homing", ADMIN_BAN, "Toggle homing mode")

	gmsg_death  = get_user_msgid("DeathMsg")
	gmsg_damage = get_user_msgid("Damage")
	Saytxt      = get_user_msgid("SayText")
}

public plugin_cfg()
{
	new cfgdir[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	server_cmd("exec %s/zp_bazooka_modes.cfg", cfgdir)
}

public plugin_precache()
{
	precache_model(mrocket)
	precache_model(mrpg_w)
	precache_sound(sfire)
	precache_sound(sfly)
	precache_sound(shit)
	precache_sound(spickup)
	rocketsmoke = precache_model("sprites/smoke.spr")
	white       = precache_model("sprites/white.spr")
}

public client_putinserver(id)
{
	reset_bazooka(id)
	mode[id] = 1
}

public client_connect(id)
{
	reset_bazooka(id)
	mode[id] = 1
}

reset_bazooka(id)
{
	g_hasbazooka[id]               = false
	g_bazooka_ammo[id]             = 0
	g_bazooka_max_ammo[id]         = 0
	g_bazooka_charge[id]           = 0
	g_bazooka_charge_threshold[id] = 0
}

// ---- Calcular ammo inicial segun jugadores ----
// <10 = deshabilitada, 10-20 = 1 carga, 21-32 = 2 cargas
bazooka_calc_max_ammo()
{
	new players = get_playersnum()
	if(players >= 21) return 2
	if(players >= 10) return 1
	return 0
}

// ---- Dar bazooka al Nemesis al iniciar ronda ----
public zp_round_started(mode_id, player_id)
{
	if(!player_id || !zp_get_user_nemesis(player_id)) return
	if(!is_user_alive(player_id)) return

	new players   = get_playersnum()
	new start_ammo = bazooka_calc_max_ammo()

	// Threshold escala igual que la vida del Nemesis: 1250 * jugadores
	// pcvar_charge_perplayer es el factor por jugador (default 250 = 20% de la vida por carga)
	new raw_threshold = get_pcvar_num(pcvar_charge_perplayer) * players
	new threshold = raw_threshold < 500 ? 500 : raw_threshold

	g_bazooka_max_ammo[player_id]         = start_ammo
	g_bazooka_ammo[player_id]             = start_ammo
	g_bazooka_charge[player_id]           = 0
	g_bazooka_charge_threshold[player_id] = threshold

	if(start_ammo <= 0)
	{
		g_hasbazooka[player_id] = false
		bazooka_msg(player_id, "^x04[Z-Evil]^x01 Necesitas al menos 10 jugadores para usar la Bazooka.")
		return
	}

	g_hasbazooka[player_id] = true
	mode[player_id] = 1

	give_bazooka_grenade(player_id)

	emit_sound(player_id, CHAN_WEAPON, spickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	bazooka_msg(player_id, "^x04[Z-Evil]^x01 Bazooka lista! Cargas: ^x04%d/%d^x01 — Recarga: %d danio por carga.", start_ammo, start_ammo, threshold)
}

// Dar la granada flashbang que actua como bazooka
give_bazooka_grenade(id)
{
	if(!is_user_alive(id)) return
	give_item(id, "weapon_flashbang")
	cs_set_user_bpammo(id, CSW_FLASHBANG, 1)
}

// ---- Daño recibido como Nemesis carga la bazooka ----
public fw_take_damage(victim, inflictor, attacker, Float:damage, damagetype)
{
	if(!g_hasbazooka[victim]) return HAM_IGNORED
	if(!zp_get_user_nemesis(victim)) return HAM_IGNORED
	if(g_bazooka_ammo[victim] >= g_bazooka_max_ammo[victim]) return HAM_IGNORED

	g_bazooka_charge[victim] += floatround(damage)
	new threshold = g_bazooka_charge_threshold[victim]
	if(threshold < 1) threshold = 500

	while(g_bazooka_charge[victim] >= threshold && g_bazooka_ammo[victim] < g_bazooka_max_ammo[victim])
	{
		g_bazooka_ammo[victim]++
		g_bazooka_charge[victim] -= threshold

		if(g_bazooka_ammo[victim] == 1)
		{
			// Tenia 0, ahora tiene 1: dar flashbang
			give_bazooka_grenade(victim)
			emit_sound(victim, CHAN_WEAPON, spickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			bazooka_msg(victim, "^x04[Z-Evil]^x01 Bazooka recargada! (%d/%d cargas)", g_bazooka_ammo[victim], g_bazooka_max_ammo[victim])
		}
		else
		{
			bazooka_msg(victim, "^x04[Z-Evil]^x01 Bazooka +1 carga (%d/%d)", g_bazooka_ammo[victim], g_bazooka_max_ammo[victim])
		}
	}
	return HAM_IGNORED
}

// ---- Interceptar lanzamiento de granada → convertir en cohete ----
public fw_set_model(ent, const model[])
{
	if(!pev_valid(ent)) return FMRES_IGNORED

	static cls[32]
	pev(ent, pev_classname, cls, 31)
	if(!equal(cls, "grenade")) return FMRES_IGNORED

	new owner = pev(ent, pev_owner)
	if(owner < 1 || owner > 32) return FMRES_IGNORED
	if(!g_hasbazooka[owner] || g_bazooka_ammo[owner] <= 0) return FMRES_IGNORED

	// Consumir una carga
	g_bazooka_ammo[owner]--

	// Convertir la granada en cohete
	engfunc(EngFunc_SetModel, ent, mrocket)
	set_pev(ent, pev_classname, "rpgrocket")
	set_pev(ent, pev_mins, {-1.0,-1.0,-1.0})
	set_pev(ent, pev_maxs, { 1.0, 1.0, 1.0})
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)

	// Velocidad segun aim del owner
	new Float:vel[3]
	if(mode[owner] == 2)
		velocity_by_aim(owner, get_pcvar_num(pcvar_speed_homing), vel)
	else
		velocity_by_aim(owner, get_pcvar_num(pcvar_speed), vel)
	set_pev(ent, pev_velocity, vel)

	// Angulo del cohete alineado al aim
	new Float:angles[3]
	pev(owner, pev_v_angle, angles)
	set_pev(ent, pev_angles, angles)

	// Efecto visual — rastro de humo
	entity_set_int(ent, EV_INT_effects, entity_get_int(ent, EV_INT_effects) | EF_BRIGHTLIGHT)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(22)  // TE_BEAMFOLLOW
	write_short(ent)
	write_short(rocketsmoke)
	write_byte(50)
	write_byte(3)
	write_byte(255); write_byte(255); write_byte(255); write_byte(200)
	message_end()

	emit_sound(ent, CHAN_WEAPON, sfire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	emit_sound(ent, CHAN_VOICE,  sfly,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	if(mode[owner] == 2)
		set_task(0.5, "rpg_seek_follow", ent + TASK_SEEK_CATCH, _, _, "b")

	// Si todavia tiene cargas, dar otra flashbang de inmediato
	if(g_bazooka_ammo[owner] > 0)
	{
		give_bazooka_grenade(owner)
		bazooka_msg(owner, "^x04[Z-Evil]^x01 Disparado! Cargas restantes: ^x04%d", g_bazooka_ammo[owner])
	}
	else
	{
		// Sin cargas — esperando recarga por daño
		bazooka_msg(owner, "^x04[Z-Evil]^x01 Sin cargas — recargando con danio recibido (%d por carga).", g_bazooka_charge_threshold[owner])
	}

	return FMRES_SUPERCEDE
}

// ---- Impacto del cohete ----
public fw_touch(ent, touched)
{
	if(!pev_valid(ent)) return FMRES_IGNORED

	static cls[32]
	pev(ent, pev_classname, cls, 31)
	if(!equali(cls, "rpgrocket")) return FMRES_IGNORED

	// Ignorar si toca el owner (evita autoimpacto al lanzar)
	new owner = pev(ent, pev_owner)
	if(touched == owner) return FMRES_IGNORED

	new Float:EndOrigin[3]
	pev(ent, pev_origin, EndOrigin)
	new iOrigin[3]
	iOrigin[0] = floatround(EndOrigin[0])
	iOrigin[1] = floatround(EndOrigin[1])
	iOrigin[2] = floatround(EndOrigin[2])

	// Parar homing task
	if(task_exists(ent + TASK_SEEK_CATCH))
		remove_task(ent + TASK_SEEK_CATCH)

	emit_sound(ent, CHAN_WEAPON, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	make_explosion(iOrigin)

	new maxdmg  = get_pcvar_num(pcvar_maxdmg)
	new radius  = get_pcvar_num(pcvar_radius)

	new PlayerPos[3]
	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_alive(i)) continue

		// Nemesis/zombie daña solo a humanos
		if(zp_get_user_zombie(owner))
		{
			if(zp_get_user_zombie(i)) continue
		}
		else
		{
			if(!zp_get_user_zombie(i)) continue
		}

		get_user_origin(i, PlayerPos)
		new dist = get_distance(PlayerPos, iOrigin)
		if(dist > radius) continue

		make_explosion(iOrigin)
		new dmg = maxdmg - floatround(float(maxdmg) * float(dist) / float(radius))
		baz_damage(i, owner, dmg, "bazooka")
	}

	// Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	write_coord(iOrigin[0]); write_coord(iOrigin[1]); write_coord(iOrigin[2])
	write_coord(iOrigin[0]); write_coord(iOrigin[1]); write_coord(iOrigin[2] + 320)
	write_short(white)
	write_byte(0); write_byte(0); write_byte(16); write_byte(128); write_byte(0)
	write_byte(255); write_byte(255); write_byte(192); write_byte(128); write_byte(0)
	message_end()

	remove_entity(ent)
	return FMRES_HANDLED
}

baz_damage(id, attacker, damage, const weapon[])
{
	if(pev(id, pev_takedamage) == DAMAGE_NO || damage <= 0) return

	new hp = get_user_health(id)

	if(hp - damage <= 0)
	{
		set_msg_block(gmsg_death, BLOCK_SET)
		ExecuteHamB(Ham_Killed, id, attacker, 2)
		set_msg_block(gmsg_death, BLOCK_NOT)

		message_begin(MSG_BROADCAST, gmsg_death)
		write_byte(attacker); write_byte(id); write_byte(0)
		write_string(weapon)
		message_end()

		set_pev(attacker, pev_frags, float(get_user_frags(attacker) + 1))
		dmgcount[attacker] += hp
	}
	else
	{
		dmgcount[attacker] += damage
		new origin[3]
		get_user_origin(id, origin)
		message_begin(MSG_ONE, gmsg_damage, {0,0,0}, id)
		write_byte(21); write_byte(20); write_long(DMG_BLAST)
		write_coord(origin[0]); write_coord(origin[1]); write_coord(origin[2])
		message_end()
		set_pev(id, pev_health, pev(id, pev_health) - float(damage))
	}

	if(!get_pcvar_num(pcvar_award)) return
	new threshold = get_pcvar_num(pcvar_dmgthreshold)
	if(threshold < 1) return
	if(dmgcount[attacker] >= threshold)
	{
		new reward = dmgcount[attacker] / threshold
		dmgcount[attacker] -= reward * threshold
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + reward)
	}
}

// ---- Homing ----
public rpg_seek_follow(ent)
{
	ent -= TASK_SEEK_CATCH
	if(!pev_valid(ent)) return

	static cls[32]
	pev(ent, pev_classname, cls, 31)
	if(!equali(cls, "rpgrocket")) return

	new id_owner = pev(ent, pev_owner)
	new Float:shortest = 500.0
	new nearest = 0

	new iClients[32], num
	get_players(iClients, num, "a")

	for(new i = 0; i < num; i++)
	{
		new c = iClients[i]
		new Float:pOrigin[3], Float:rOrigin[3], Float:dist
		if(!is_user_alive(c) || c == id_owner) continue
		// Homing busca el equipo opuesto
		if(zp_get_user_zombie(id_owner)) { if(zp_get_user_zombie(c)) continue; }
		else { if(!zp_get_user_zombie(c)) continue; }
		pev(c, pev_origin, pOrigin)
		pev(ent, pev_origin, rOrigin)
		dist = get_distance_f(pOrigin, rOrigin)
		if(dist < shortest) { shortest = dist; nearest = c; }
	}
	if(nearest > 0) entity_set_follow(ent, nearest, float(get_pcvar_num(pcvar_speed_homing)))
}

stock entity_set_follow(entity, target, Float:speed)
{
	if(!pev_valid(entity) || !pev_valid(target)) return 0
	new Float:eo[3], Float:to[3], Float:diff[3]
	pev(entity, pev_origin, eo)
	pev(target,  pev_origin, to)
	diff[0]=to[0]-eo[0]; diff[1]=to[1]-eo[1]; diff[2]=to[2]-eo[2]
	new Float:len = floatsqroot(floatpower(diff[0],2.0)+floatpower(diff[1],2.0)+floatpower(diff[2],2.0))
	if(len == 0.0) return 0
	new Float:vel[3]
	vel[0]=diff[0]*(speed/len); vel[1]=diff[1]*(speed/len); vel[2]=diff[2]*(speed/len)
	set_pev(entity, pev_velocity, vel)
	return 1
}

// ---- Limpieza ----
public event_new_round()
{
	new ent = engfunc(EngFunc_FindEntityByString, -1, "classname", "rpgrocket")
	while(ent > 0)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		ent = engfunc(EngFunc_FindEntityByString, -1, "classname", "rpgrocket")
	}
	for(new id = 1; id <= 32; id++)
		reset_bazooka(id)
}

// ---- Drop bazooka al infectarse ----
public zp_user_infected_post(id, infector)
{
	reset_bazooka(id)
}

// ---- Admin: dar bazooka ----
public cmd_give_bazooka(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1)) return

	new arg[32]
	read_argv(1, arg, charsmax(arg))

	new players    = get_playersnum()
	new adm_ammo   = bazooka_calc_max_ammo()
	new raw_th     = get_pcvar_num(pcvar_charge_perplayer) * players
	new adm_thresh = raw_th < 500 ? 500 : raw_th
	if(adm_ammo <= 0) adm_ammo = 1  // admin force-grants: garantizar al menos 1

	if(arg[0] == '@')
	{
		for(new i = 1; i <= 32; i++)
		{
			if(is_user_alive(i) && !zp_get_user_zombie(i))
			{
				g_hasbazooka[i]               = true
				g_bazooka_max_ammo[i]         = adm_ammo
				g_bazooka_ammo[i]             = adm_ammo
				g_bazooka_charge[i]           = 0
				g_bazooka_charge_threshold[i] = adm_thresh
				give_bazooka_grenade(i)
				emit_sound(i, CHAN_WEAPON, spickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			}
		}
	}
	else
	{
		new target = cmd_target(id, arg, 10)
		if(!target || zp_get_user_zombie(target)) return
		g_hasbazooka[target]               = true
		g_bazooka_max_ammo[target]         = adm_ammo
		g_bazooka_ammo[target]             = adm_ammo
		g_bazooka_charge[target]           = 0
		g_bazooka_charge_threshold[target] = adm_thresh
		give_bazooka_grenade(target)
		emit_sound(target, CHAN_WEAPON, spickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}

// ---- Toggle homing ----
public cmd_toggle_homing(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1)) return
	new arg[32]; read_argv(1, arg, charsmax(arg))
	new target = arg[0] ? cmd_target(id, arg, 0) : id
	if(!target) return
	mode[target] = (mode[target] == 1) ? 2 : 1
	client_print(target, print_center, "Bazooka modo: %s", (mode[target]==2) ? "Teleguiado" : "Normal")
}

// ---- Utilidades ----
stock make_explosion(const iOrigin[3])
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(iOrigin[0]); write_coord(iOrigin[1]); write_coord(iOrigin[2])
	write_short(rocketsmoke)
	write_byte(65); write_byte(10); write_byte(0)
	message_end()

	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_TAREXPLOSION)
	write_coord(iOrigin[0]); write_coord(iOrigin[1]); write_coord(iOrigin[2])
	message_end()
}

stock bazooka_msg(id, const input[], any:...)
{
	new msg[192]
	vformat(msg, charsmax(msg), input, 3)
	message_begin(MSG_ONE_UNRELIABLE, Saytxt, _, id)
	write_byte(id)
	write_string(msg)
	message_end()
}
