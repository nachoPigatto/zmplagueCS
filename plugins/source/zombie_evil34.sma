#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <sqlx>
#include <orpheu_memory>
#include <orpheu>

#include "api_oldmenu.inc"

#define USANDO_EN_LAN
//#define _DEBUG_ON
#include "debug.inc"

new const PLUGIN_VERSION[] = "3.4.0"

// Class constants (CLASS_NONE comes from hlsdk_const.inc as 0)
const CLASS_ZOMBIE    = 1
// Admin flag for owner-only options (flag "l" = ADMIN_RCON)
const OWNER_FLAG = ADMIN_RCON
const CLASS_NEMESIS   = 2
const CLASS_ASSASSIN  = 3
const CLASS_HUMAN     = 1
const CLASS_SURVIVOR  = 2
const CLASS_SNIPER    = 3
const CLASS_CIVIL     = 4
const CLASS_UMBRELLA  = 5

const ACCESS_FLAG = ADMIN_BAN
const MIN_PLAYERS = 1
const AMMODAMAGE = 720
const ZOMBIE_DMG_PER_AP = 150

const MAX_LEVEL	= 140
const MAX_EXTRA_ITEMS = 25
const MAX_CSDM_SPAWNS = 45
const MAX_STATS_SAVED = 40
const MAX_PASSWORD_LEN = 20
const MAX_PARTY_MEMBER = 5

const Float:REMOVEDDROPPED_TIME = 10.0
const Float:SPAWNPROTECTION = 4.0

new const HOURS_HF[] = { 1, 4, 8 }

#if defined USANDO_EN_LAN
new const szHost[] = "localhost"
new const szUser[] = "servidores"
new const szPass[] = "servidoressql"
new const szDB[] = "zombie_evil"
#else
//new const szHost[] = "190.210.177.62"
new const szHost[] = "db.localhost.net.ar"
new const szUser[] = "mzamudio"
new const szPass[] = "YUFpUYQsZZeK5yaS"
new const szDB[] = "mzamudio"
#endif


/*--------------------------------------------------------------*
*-------- WEAPONS ----------------------------------------------*
*--------------------------------------------------------------*/
#define wm_mejora_cost(%1)	(((g_weapons_mejoras[id][wkey][%1] + (wkey + 4)) * 3) - 1)

#define EV_NEW_WEAPON		EV_INT_iuser3

new const weapons_numid[] = {
	-1, -1, -1, -1, -1, -1, -1, -1, 4, -1, -1, -1, -1, -1,
	3, -1, -1, -1, 1, 2, -1,-1, 5, 0, -1, -1, -1, -1, 6, -1, -1
}

new const wm_name[][] = { "Tmp 75", "AWP Sniper x7", "Umbrella MP5 Navy", "Super Galil", "AUG PRO", "M4A1 Mini" }
new const weapons_id[] = { CSW_TMP, CSW_AWP, CSW_MP5NAVY, CSW_GALIL, CSW_AUG, CSW_M4A1 }
new const wm_cost[][2] = { { 45, 1 }, { 29, 2 }, { 97, 3 }, { 60, 5 }, { 97, 7 }, { 75, 10 } }

new g_weapons_mejoras[33][6][3]
new g_weapons_puntos[33][2]
new g_wpn_mejoras_active[33]  // true only when weapon came from Modificables menu
new Float:g_recoil_mul[33]    // last computed recoil mul (1.0 = inactive)

new g_menu_mweapon[33]

// Player Models
new const model_assassin[] = "OA_Assassin"
new const model_nemesis[] = "OA-nemesis"
new const model_survivor[] = "OA_Jill"
new const model_sniper[] = "OA_Leon"
new const model_admin[] = "OA_Admin"

new model_nemesis_index, model_assassin_index

// Grenades
new const model_grenade_infect[] = "models/zombie_plague/v_grenade_infect.mdl"

new const model_v_grenade_fire[] = "oa-ze/v_granada_fuego.mdl"
new const model_p_grenade_fire[] = "oa-ze/p_granada_fuego.mdl"
new const model_w_grenade_fire[] = "oa-ze/w_granada_fuego.mdl"

new const model_v_grenade_frost[] = "oa-ze/v_granada_hielo.mdl"
new const model_p_grenade_frost[] = "oa-ze/p_granada_hielo.mdl"
new const model_w_grenade_frost[] = "oa-ze/w_granada_hielo.mdl"

new const model_v_grenade_flare[] = "oa-ze/v_granada_flare2.mdl"
new const model_p_grenade_flare[] = "oa-ze/p_granada_flare.mdl"
new const model_w_grenade_flare[] = "oa-ze/w_granada_flare.mdl"

new const model_v_grenade_field[] = "oa-ze/v_granada_campo.mdl"
new const model_forcefield[] = "models/zombie_plague/aura8.mdl"
new const model_w_grenade_field[] = "models/zombie_plague/w_aura.mdl"

new const model_v_grenade_molotov[] = "oa-ze/v_molotov.mdl"
new const model_p_grenade_molotov[] = "oa-ze/p_molotov.mdl"
new const model_w_grenade_molotov[] = "oa-ze/w_molotov.mdl"

new const model_v_grenade_anti[] = "oa-ze/v_granada_anti.mdl"
new const model_p_grenade_anti[] = "oa-ze/p_granada_anti.mdl"
new const model_w_grenade_anti[] = "oa-ze/w_granada_anti.mdl"

new const model_v_grenade_he[] = "oa-ze/v_hegrenade.mdl"
new const model_p_grenade_he[] = "oa-ze/p_hegrenade.mdl"

// Weapon Models
new const model_vknife_nemesis[] = "oa-ze/v_nemesis.mdl"
new const model_v_survivor[] = "oa-ze/v_dualmp5.mdl"
new const model_p_survivor[] = "oa-ze/p_dualmp5.mdl"

// NuclearBomb ----
new const sound_nuc_misil[] = "oa_ze/nuc_misil.wav"
new const sound_nuc_exp[] = "oa_ze/nuc_exp.wav"
new const sound_nuc_warning[] = "oa_ze/nuc_warning.wav"

// Sound menu -------
new const sound_menu[][] = { "oa_ze/menu_next.wav", "oa_ze/menu_back.wav", "oa_ze/menu_selec.wav", "oa_ze/menu_cancel.wav" }

// New sounds
new const sound_openmenu[] = "events/enemy_died.wav"
new const sound_levelup[] = "oa_ze/levelup.wav"
new const sound_leveldonw[] = "oa_ze/leveldonw.wav"
new const sound_tutor_msg[] = "oa_ze/tutor_msg.wav"

new const sound_environment_mp3[][] = { "sound/oa_ze/a/fondo1.mp3", "sound/oa_ze/a/fondo2.mp3", "sound/oa_ze/a/fondo3.mp3",
"sound/oa_ze/a/fondo4.mp3", "sound/oa_ze/a/fondo5.mp3", "sound/oa_ze/a/suspenso.mp3", "sound/oa_ze/a/suspenso2.mp3",
"sound/oa_ze/a/suspenso3.mp3", "sound/oa_ze/a/helipass.mp3", "sound/oa_ze/a/helipass2.mp3", "sound/oa_ze/a/intro1.mp3", "sound/oa_ze/a/intro2.mp3"  }

// Sound list (randomly chosen, add as many as you want)
new const sound_neme_death[] = "oa_ze/z/neme_death.wav"
new const sound_win_zombies[][] = { "oa_ze/win_zombie.wav" }
new const sound_win_humans[][] = { "oa_ze/humans_win1.wav", "oa_ze/humans_win2.wav", "oa_ze/humans_win3.wav" }
new const zombie_infect[][] = { "oa_ze/z/zombie_infec1.wav", "oa_ze/z/zombie_infect.wav", "oa_ze/z/zombie_infec2.wav", "oa_ze/z/zombie_infec3.wav", "oa_ze/z/zombie_infect2.wav", "oa_ze/z/zombie_infect3.wav" }
new const zombie_pain[][] = { "oa_ze/z/zombie_pain1.wav", "oa_ze/z/zombie_pain2.wav", "oa_ze/z/zombie_pain3.wav", "oa_ze/z/zombie_pain4.wav", "oa_ze/z/zombie_pain5.wav" }
new const nemesis_pain[][] = { "oa_ze/z/nemesis_pain1.wav", "oa_ze/z/nemesis_pain2.wav", "oa_ze/z/nemesis_pain3.wav" }
new const zombie_die[][] = { "oa_ze/z/zombie_die1.wav", "oa_ze/z/zombie_die2.wav", "oa_ze/z/zombie_die3.wav", "oa_ze/z/zombie_die4.wav", "oa_ze/z/zombie_die5.wav" }
new const zombie_fall[][] = { "oa_ze/z/zombie_fall1.wav" }
new const zombie_miss_slash[][] = { "oa_ze/z/knife_slash1.wav", "oa_ze/z/knife_slash2.wav", "oa_ze/z/knife_slash3.wav" }
new const zombie_miss_wall[][] = { "oa_ze/z/knife_wall1.wav", "oa_ze/z/knife_wall2.wav", "oa_ze/z/knife_wall3.wav" }
new const zombie_hit_normal[][] = { "weapons/knife_hit1.wav", "weapons/knife_hit2.wav", "weapons/knife_hit3.wav", "weapons/knife_hit4.wav" }
new const zombie_hit_stab[][] = { "oa_ze/z/z_attack.wav", "oa_ze/z/z_attack2.wav", "oa_ze/z/z_attack3.wav" }
new const zombie_idle[][] = { "nihilanth/nil_now_die.wav", "nihilanth/nil_slaves.wav", "nihilanth/nil_alone.wav", "oa_ze/z/zombie_brains1.wav", "oa_ze/z/zombie_brains2.wav" }
new const zombie_idle_last[][] = { "nihilanth/nil_thelast.wav" }
new const zombie_madness[][] = { "oa_ze/z/zombie_madness1.wav" }
new const sound_assassin[] =  "oa_ze/a/assround.wav"
new const sound_nemesis[][] = { "oa_ze/a/nemesis1.wav", "oa_ze/a/nemesis2.wav" }
new const sound_survivor[][] = { "oa_ze/a/survivor1.wav", "oa_ze/a/survivor2.wav" }
new const sound_swarm[][] = { "ambience/the_horror2.wav" }
new const sound_multi[][] = { "ambience/the_horror2.wav" }
new const sound_plague[][] = { "oa_ze/a/nemesis1.wav", "oa_ze/a/survivor1.wav" }
new const sound_umbrella[] = "oa_ze/a/umbrella.wav"
new const grenade_infect[][] = { "oa_ze/grenade_infect.wav" }
new const grenade_infect_player[][] = { "scientist/scream20.wav", "scientist/scream22.wav", "scientist/scream05.wav" }
new const grenade_fire[][] = { "oa_ze/grenade_explode.wav" }
new const grenade_fire_player[][] = { "oa_ze/z/zombie_burn3.wav","oa_ze/z/zombie_burn4.wav","oa_ze/z/zombie_burn5.wav","oa_ze/z/zombie_burn6.wav","oa_ze/z/zombie_burn7.wav" }
new const grenade_frost[][] = { "oa_ze/frostnova.wav" }
new const grenade_frost_player[][] = { "oa_ze/impalehit.wav" }
new const grenade_frost_break[][] = { "oa_ze/impalelaunch1.wav" }
new const sound_flare[] = "oa_ze/flare_on.wav"
new const sound_antidote[] = "items/smallmedkit1.wav"
new const sound_thunder[][] = { "oa_ze/a/thunder1.wav", "oa_ze/a/thunder2.wav" }
new const sound_pickup[] = "oa_ze/gunpickup.wav"
new const sound_transformation[] = "oa_ze/z/pre_infect.wav"
new const sound_nvgon[] = "oa_ze/z/nvgon.wav"
new const sound_nvgoff[] = "oa_ze/z/nvgoff.wav"
new const sound_he_exp[] = "oa_ze/exp/explode1.wav"
new const sound_molotov_exp[] = "oa_ze/exp/molotov_exp.wav"
new const sound_armorhit[] = "player/bhit_helmet-1.wav"
new const sound_mission_complete[] = "oa_ze/mision_completada.wav"

// Laser Trip Mine
new const mine_model[]       = "models/w_tripmine.mdl"
new const classname_mine[]   = "ze_mine"
new const mine_snd_place[]   = "weapons/mine_activate.wav"
new const mine_snd_explode[] = "weapons/mine_detonate.wav"
const Float:MINE_EXPLODE_RADIUS = 200.0
const Float:MINE_DAMAGE         = 700.0
const Float:MINE_HP             = 200.0
const MINE_MAX_DIST             = 80    // max removal distance = same as placement
const MINE_PLACE_DIST           = 80    // max placement traceline distance
new const MINE_LIMITS[]  = { 2, 2, 2, 2, 2, 2, 2 }  // mines per player (future: by class level)
new g_laserMineSpr
new g_mine_count[33]  // mines placed per player this round

// PowerBox
new const model_powerbox[] = "models/w_battery.mdl"
new const model_powerboxt[] = "models/w_batteryt.mdl"
new const sound_powerbox[] = "oa_ze/item_extrahp.wav"
new const classname_powerbox[] = "powerbox"

// Illidan Boss Round
new const ILLIDAN_MAP[] = "zl_boss_illidan_alpha"
#define ILLIDAN_BOSS_Z 42.0
#define TASK_ILLIDAN_TIMER    77777
#define TASK_OWNER_GIFT_MENU   5000  // player-select delay: 5000 + player_id
const ILLIDAN_BASE_HP = 8000
const ILLIDAN_SPEED_P1 = 250
const ILLIDAN_SPEED_P3 = 320
const ILLIDAN_DAMAGE_MELEE = 50
const ILLIDAN_DAMAGE_ROLL = 30
const Float:ILLIDAN_BLITZ_INTERVAL = 20.0
const ILLIDAN_ELEM_HP_DIV = 20
const ILLIDAN_ELEM_SPEED = 265
const ILLIDAN_ELEM_SPAWN_DMG = 10
const ILLIDAN_ELEM_SPLASH_DMG = 2
const ILLIDAN_AP_PER_100_DMG = 1
const ILLIDAN_AP_KILL_ALL = 10
const ILLIDAN_AP_KILL_TOP = 50

new const g_illidanModels[][] = {
	"models/zl/npc/illidan/zl_illidan_alpha3.mdl",
	"models/zl/npc/illidan/zl_blade.mdl",
	"sprites/zl/npc/illidan/zl_hpbar.spr",
	"models/zl/npc/illidan/zl_attack.mdl",
	"sprites/zl/npc/illidan/zl_focus_start.spr",
	"sprites/zl/npc/illidan/zl_focus_end.spr",
	"models/zl/npc/illidan/zl_attack2.mdl",
	"models/zl/npc/illidan/zl_elem.mdl",
	"sprites/laserbeam.spr",
	"sprites/shockwave.spr",
	"models/zl/npc/illidan/zl_ball_alpha.mdl",
	"models/zl/npc/illidan/zl_splash.mdl",
	"sprites/zl/npc/illidan/zl_elem_hpbar_alpha.spr",
	"sprites/zl/npc/illidan/zl_zoom_alpha.spr"
}

new const g_illidanSounds[][] = {
	"zl/npc/illidan/Illidan_attack.wav",
	"zl/npc/illidan/Illidan_attack_blitz.wav",
	"zl/npc/illidan/Illidan_attack_roar.wav",
	"zl/npc/illidan/attack_killed.wav",
	"zl/npc/illidan/event_sp_prepare.wav",
	"zl/npc/illidan/event_start.wav",
	"zl/npc/illidan/elem_fly_start.wav",
	"zl/npc/illidan/event_demon.wav",
	"zl/npc/illidan/sp_scroll.wav",
	"zl/npc/illidan/event_phase2.wav",
	"zl/npc/illidan/event_phase_magma.wav",
	"zl/npc/illidan/event_ghost.wav"
}

new g_trailSpr, g_exploSpr, g_flameSpr, g_smokeSpr, g_glassSpr, g_exploSpr2, g_smokeSpr2, g_glowSpr,
g_exploSpr3, g_particleSpr, g_bubblesSpr, g_exploSpr4, g_molotovFireStr[2]

// Lightning Lights Cycle
new const lights_thunder1[][] = { "i" ,"j", "k", "l", "m", "n", "o", "n", "m", "l", "k", "j", "i", "h", "g", "f", "e", "d", "c", "b", "a"}
new const lights_thunder2[][] = { "k", "l", "m", "l", "k", "j", "i", "h", "g", "f", "e", "d", "c", "b", "a", "a", "b", "c", "d", "e", "d", "c", "b", "a"}
new const lights_thunder3[][] = { "b", "c", "d", "e", "f", "e", "d", "c", "i" ,"j", "k", "l", "m", "l", "k", "j", "i", "h", "g", "f", "e", "d", "c", "b", "a"}

// Decal List for Zombie Bloodstains/Footsteps
new const zombie_decals[] = { 99, 107, 108, 184, 185, 186, 187, 188, 189 }

// Others string const
new const g_objective_ents[][] = { "func_bomb_target", "info_bomb_target", "info_vip_start", "func_vip_safetyzone", "func_escapezone", "hostage_entity",
"monster_scientist", "func_hostage_rescue", "info_hostage_rescue", "env_fog", "env_rain", "env_snow", "item_longjump", "func_vehicle", "armoury_entity", "info_map_parameters" }

new const FOG_DENSITY[] = "0.0009"
new const FOG_COLOR[] = "128 128 128"

new const classname_forcefield[] = "forcefield"
new const skynames[] = "space"
new const setinfo_md5key[] = "ze_md5"
new const EMAIL_DOMAINS[][] = { "@gmail.com", "@live.com", "@hotmail.com", "@yahoo.com", "@arnet.com.ar",  "@hotmail.es" }
new const BAD_WORDS[][] = { "puta", "puto", "conch", "chupa","tarad", "ierda", "pija", "pene", "verga", "trolo", "pito", "cs.", "maricon", "boliviano", "peruano", "hdp", "lctm", "deform", "cancer" }

new const error_log[] = "zevil_error.log"

// Task offsets
enum (+= 100)
{
	TASK_MODEL = 2000,
	TASK_TEAM,
	TASK_SPAWN,
	TASK_BLOOD,
	TASK_NADES,
	TASK_MAKEZOMBIE,
	TASK_WELCOMEMSG,
	TASK_THUNDER_PRE,
	TASK_THUNDER,
	TASK_AMBIENCESOUNDS,
	TASK_AMBIENCESOUNDSSTOP,
	TASK_INFO_COMBO,
	TASK_FINISH_COMBO,
	TASK_RESET_COMBO,
	TASK_BURN,
	TASK_MSG_T,
	TASK_NUKBOMB,
	TASK_ICON,
	TASK_SAVE,
	TASK_LOAD,
	TASK_INFECTION
}

// IDs inside tasks
#define ID_SPAWN (taskid - TASK_SPAWN)


// For weapon buy menu handlers
#define WPN_AUTO_ON g_menu_data[id][0]
#define WPN_AUTO_PRI g_menu_data[id][1]
#define WPN_AUTO_SEC g_menu_data[id][2]
#define PARTY_INV_ACCION g_menu_data[id][3]

// Others
#define NIVELES(%1) (((%1 * (%1 * 2)) * 2) - %1)

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord, %1)

#define is_user_valid_connected(%1) (1 <= %1 <= g_maxplayers && g_is_connected[%1])
#define is_user_valid_alive(%1) (1 <= %1 <= g_maxplayers && g_is_alive[%1])

#define set_aura(%1) g_user_aura |= (1<<(%1&31))
#define del_aura(%1) g_user_aura &= ~(1 <<(%1&31))
#define get_aura(%1) g_user_aura & (1<<(%1&31))

#define set_nvg(%1) g_user_nvg |= (1<<(%1&31))
#define del_nvg(%1) g_user_nvg &= ~(1 <<(%1&31))
#define get_nvg(%1) g_user_nvg & (1<<(%1&31))

#define is_any_zombie(%1) 	(g_zombie[%1])
#define is_zombie(%1) 		(g_zombie[%1] == CLASS_ZOMBIE)
#define is_nemesis(%1) 		(g_zombie[%1] == CLASS_NEMESIS)
#define is_assassin(%1) 	(g_zombie[%1] == CLASS_ASSASSIN)
#define is_human(%1) 		(g_human[%1] == CLASS_HUMAN)
#define is_survivor(%1) 	(g_human[%1] == CLASS_SURVIVOR)
#define is_sniper(%1) 		(g_human[%1] == CLASS_SNIPER)
#define is_civil(%1) 		(g_human[%1] == CLASS_CIVIL)
#define is_umbrella(%1) 	(g_human[%1] == CLASS_UMBRELLA)

#define mejoras_cost(%1,%2)	((g_mejoras[id][%2][%1] + 1) * 3 - 2)
#define mejoras_p(%1,%2,%3)	porcentaje(g_mejoras[id][%2][%1], %2, %3)

// Game modes
enum
{
	MODE_NONE = 0,
	MODE_INFECTION,
	MODE_NEMESIS,
	MODE_SNIPER,
	MODE_SYNAPSIS,
	MODE_ASSASSIN,
	MODE_SURVIVOR,
	MODE_SWARM,
	MODE_MULTI,
	MODE_UMBRELLA,
	MODE_PLAGUE
}

// ZP Teams
enum {
	ZP_TEAM_ANY = 0,
	ZP_TEAM_ZOMBIE,
	ZP_TEAM_HUMAN
}

enum {
	TEAM_HUMAN=0,
	TEAM_ZOMBIE
}

// MenuSound
enum {
	SOUNDMENU_NEXT = 0,
	SOUNDMENU_BACK,
	SOUNDMENU_SELECT,
	SOUNDMENU_CANCEL
}

// Happy Hour
enum {
	HFS_END = 0,
	HFS_IS,
	HFS_START,
	HFS_PRE_START,
	HFS_PRE_END,
	HF_IS,
	HF_START,
	HF_PRE_START
}

// Default exta items
enum {
	EXTRA_NVISION = 0,
	EXTRA_ANTIDOTE,
	EXTRA_MADNESS,
	EXTRA_INFBOMB,
	EXTRA_ANTIDOTE_BOMB,
	EXTRA_FORCEFIELD,
	EXTRA_UNLIMITED_CLIP
}

// Kills
enum {
	KILL_ZOMBIE=0,
	KILL_NEMESIS,
	KILL_ASSASSIN,
	KILL_INFECT,
	KILL_HUMAN,
	KILL_SURVIVOR,
	KILL_SNIPER,
	KILL_CIVIL,
	KILL_UMBRELLA,
	MAX_KILLS
}

// Colors
new const COLOR_NAME[][] = {
	"Blanco", 
	"Rojo", 
	"Azul", 
	"Verde", 
	"Celeste", 
	"Amarillo", 
	"Morado",
	"Rosa",
	"Naranja",
	"Verde Limon"
}

new const COLOR_VALUES[][3] = {
	{ 255, 255, 255 }, 
	{ 255, 0, 0 }, 
	{ 0, 0, 255 }, 
	{ 0, 255, 0 }, 
	{ 0, 255, 255 }, 
	{ 255, 255, 0 }, 
	{ 128, 0, 255 },
	{ 255, 0, 255 },
	{ 255, 171, 0 },
	{ 171, 255, 0 }
}

// Party
enum _:party {
	PARTY_ID = 0,
	PARTY_MIEMBROS,
	PARTY_APS,
	PARTY_COMBO
}
const KEYSMENU_PARTY = (1<<0)|(1<<1)|(1<<2)|(1<<9)

// Mejoras
enum {
	Z_IMPROV_DAMAGE=0,
	Z_IMPROV_HEALTH,
	Z_IMPROV_VELOCITY,
	Z_IMPROV_GRAVITY,
	MAX_IMPROV_ZOMBIE
}

enum {
	H_IMPROV_DAMAGE=0,
	H_IMPROV_HEALTH,
	H_IMPROV_ARMOR,
	H_IMPROV_VELOCITY,
	H_IMPROV_GRAVITY,
	MAX_IMPROV_HUMAN
}

new const H_IMPROV_NAMES[MAX_IMPROV_HUMAN][] = { "Da\xF1o", "Vida", "Armadura", "Velocidad", "Gravedad" }
new const Z_IMPROV_NAMES[MAX_IMPROV_ZOMBIE][] = { "Da\xF1o", "Vida", "Velocidad", "Gravedad" }

// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.17
const Float:HUD_INFECT_X = 0.05
const Float:HUD_INFECT_Y = 0.45

// CS Offsets
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41

const PDATA_SAFE = 2
const OFFSET_PAINSHOCK = 108
const OFFSET_CSMENUCODE = 205
const OFFSET_CSTEAMS = 114
const OFFSET_CSMONEY = 115
const OFFSET_CSDEATHS = 444
const OFFSET_MODELINDEX = 491
const m_flNextPrimaryAttack = 46
const m_flTimeWeaponIdle = 48
const m_szAnimExtention = 492

const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

new const TEAMNAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

enum {
	ZP_TEAM_UNASSIGNED = 0,
	ZP_TEAM_T = 1,
	ZP_TEAM_CT = 2,
	ZP_TEAM_SPECTATOR = 3
}

// Some constants
const HIDE_HUD = (1<<5)|(1<<3)
const UNIT_SECOND = (1<<12)
const DMG_HEGRENADE = (1<<24)
const IMPULSE_FLASHLIGHT = 100
const USE_USING = 2
const USE_STOPPED = 0
const STEPTIME_SILENT = 999
const BREAK_GLASS = 0x01
const FFADE_IN = 0x0000
const SPEC_TARGET = 4

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }

// Ammo IDs for weapons
new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Weapon IDs for ammo types
new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }

// Primary and Secondary Weapon Names
new const WEAPONNAMES[][] = { "", "P228 Compact", "", "Schmidt Scout", "", "XM1014 M4", "", "Ingram MAC-10", "Steyr AUG A1",
	"", "Dual Elite Berettas", "FiveseveN", "UMP 45", "SG-550 Auto-Sniper", "IMI Galil", "Famas",
	"USP .45 ACP Tactical", "Glock 18C", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun",
	"M3 Super 90", "M4A1 Carbine", "Schmidt TMP", "G3SG1 Auto-Sniper", "", "Desert Eagle .50 AE",
"SG-552 Commando", "AK-47 Kalashnikov", "", "ES P90" }

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
			
new const WEAPONSLOT[][2] = { {0,0}, {1,3}, {0,0}, {0,9}, {3,1}, {0,12}, {4,3},
	{0,13}, {0,14}, {3,9}, {1,5}, {1,6}, {0,15}, {0,16}, {0,17},{0,18},
	{ 1,4}, {1,2},{ 0,2}, {0,7},{0,4}, {0,5}, {0,6}, {0,11}, {0,3},
	{3,2}, {1,1}, {0,10}, {0,1}, {2,1}, {0,8} }
	
new const WEAPON_ICONS[][] = {
	"", "d_p228", "", "d_scout", "dmg_heat", "d_xm1014", "d_c4", "d_mac10",
	"d_aug", "dmg_shock", "d_elite", "d_fiveseven", "d_ump45", "d_sg550",
	"d_galil", "d_famas", "d_usp", "d_glock18", "d_awp", "d_mp5navy", "d_m249",
	"d_m3", "d_m4a1", "d_tmp", "d_g3sg1", "dmg_cold", "d_deagle", "d_sg552",
	"d_ak47", "", "d_p90"
}
	
enum _:WEAPONLIST_DATA
{
	WL_NAME[25]=0,
	WL_AID,
	WL_MAX,
	WL_AID2,
	WL_MAX2,
	WL_SLOTID,
	WL_SLOT,
	WL_FLAGS
}

new send_wlist[33][CSW_P90+1][WEAPONLIST_DATA]
new sends_wid[33]


/*=========GRENADES====================================================================
=====================================================================================*/
#define set_nadetype(%1,%2) entity_set_int(%1, NADE_TYPE, %2+NADE_TYPE_BASE)
#define get_nadetype(%1) (entity_get_int(%1, NADE_TYPE)-NADE_TYPE_BASE)

const Float:NADE_EXPLOSION_RADIUS = 210.0
const FLARE_COLOR = EV_INT_flSwimTime
const FLARE_DURATION = EV_INT_flDuckTime

const NADE_MODE = EV_INT_iuser1
const NADE_ORG_TYPE = EV_INT_iuser2
const NADE_BLAST_TIME = EV_FL_fuser2
const NADE_TYPE = EV_INT_flTimeStepSound
const NADE_TYPE_BASE = 1111

enum _:_GRENADES
{
	NADE_TYPE_INFECTION=1,
	NADE_TYPE_NAPALM,
	NADE_TYPE_FROST,
	NADE_TYPE_FLARE,
	NADE_TYPE_FORCEFIELD,
	NADE_TYPE_ANTIDOTEBOMB,
	NADE_TYPE_HE,
	NADE_TYPE_MOLOTOV
}

enum {
	MODE_NORMAL = 0,
	MODE_PROXIMITY,
	MODE_IMPACT,
	MODE_MOTION
}

new g_grenade_mode[33][_GRENADES]
new const modes_name[][] = { "-=[Normal]=-", "-=[Proximity]=-", "-=[Impact]=-", "-=[Motion Sensor]=-" }
new const rig_rgb[_GRENADES][3] = { {0,...}, { 255, 15, 15 }, { 15, 15, 255}, {0,...},
{0,...}, { 42, 170, 255 }, {0,...}, {0,...}, {0,...}}

const ALLOWED_GRENADE_MODE = (1<<NADE_TYPE_NAPALM)|(1<<NADE_TYPE_FROST)|(1<<NADE_TYPE_ANTIDOTEBOMB)

new const new_grenades[][WEAPONLIST_DATA] = {
	{ "oa/grenade1", 16, 3, -1, 0, 3, 4, 0 },
	{ "oa/grenade2", 17, 3, -1, 0, 3, 5, 0 },
	{ "oa/grenade3", 18, 3, -1, 0, 3, 6, 0 },
	{ "oa/grenade4", 19, 3, -1, 0, 3, 7, 0 },
	{ "oa/grenade5", 20, 3, -1, 0, 3, 8, 0 },
	{ "oa/grenade6", 21, 3, -1, 0, 3, 9, 0 },
	{ "oa/grenade7", 22, 3, -1, 0, 3, 10, 0 },
	{ "oa/grenade8", 23, 3, -1, 0, 3, 11, 0 }
}

new g_has_grenades[33][_GRENADES+1]
new g_grenades_basew[33][_GRENADES]
new g_current_grenade[33]

/*=========Human/Zombie Class==========================================================
=====================================================================================*/
#define MAX_ZCLASS  9
enum _:_ZCLASS
{
	ZCLASS_NAME[32],
	ZCLASS_INFO[32],
	ZCLASS_MODEL[32],
	ZCLASS_CLAWMODEL[64],
	ZCLASS_MODELID,
	ZCLASS_HEALTH,
	Float:ZCLASS_VELOCITY,
	Float:ZCLASS_GRAVITY,
	ZCLASS_LEVEL,
	ZCLASS_RESET
}

new const g_zclass[MAX_ZCLASS][_ZCLASS]
new g_zclass_count
// ability
new z_regenerating[33]
new z_warlock[33]

#define MAX_HCLASS  15
enum _:_HCLASS
{
	HCLASS_NAME[32],
	HCLASS_MODEL[32],
	HCLASS_HEALTH,
	HCLASS_ARMOR,
	Float:HCLASS_VELOCITY,
	Float:HCLASS_GRAVITY,
	HCLASS_LEVEL,
	HCLASS_RESET
}

new const g_hclass[MAX_HCLASS][_HCLASS]
new g_hclass_count
new default_model_index

/*=========WEAPONS====================================================================
=====================================================================================*/
#define MAX_PRIMARY_WEAPONS 20
#define MAX_SECONDARY_WEAPONS 8

enum
{
	WPN_TYPE_PRIMARY = 0,
	WPN_TYPE_SECONDARY,
	WPN_TYPE_IMPROVED
}

enum _:WEAPON_DATA
{
	WPN_NAME[32],
	WPN_BASE,
	WPN_MAX_CLIP,
	Float:WPN_SPEED,
	Float:WPN_DAMAGE,
	WPN_V_MODEL[32],
	WPN_P_MODEL[32],
	WPN_W_MODEL[32],
	WPN_LEVEL,
	WPN_RESET
}

new g_primary_weapons[MAX_PRIMARY_WEAPONS][WEAPON_DATA]
new g_secondary_weapons[MAX_SECONDARY_WEAPONS][WEAPON_DATA]
new g_weapons_count[2]

const ENTVAR_WEAPON_ID = EV_INT_flSwimTime

stock zp_get_weaponid(ent, &type)
{
	static wpnid
	wpnid = entity_get_int(ent, ENTVAR_WEAPON_ID)
	
	if(wpnid >= 3000)
	{
		type = WPN_TYPE_IMPROVED
		return wpnid-3000
	}

	if(wpnid >= 2000)
	{
		type = WPN_TYPE_SECONDARY
		return wpnid-2000
	}
	
	if(wpnid >= 1000)
	{
		type = WPN_TYPE_PRIMARY
		return wpnid-1000
	}
	
	return -1
}

stock zp_set_weaponid(ent, wpnid, type)
{
	if(type == WPN_TYPE_PRIMARY)
		entity_set_int(ent, ENTVAR_WEAPON_ID, wpnid+1000)
	else if(type == WPN_TYPE_SECONDARY)
		entity_set_int(ent, ENTVAR_WEAPON_ID, wpnid+2000)
	else if(type == WPN_TYPE_IMPROVED)
		entity_set_int(ent, ENTVAR_WEAPON_ID, wpnid+3000)
}

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// Allowed weapons for zombies (added grenades/bomb for sub-plugin support, since they shouldn't be getting them aynway)
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)

// Menu keys
const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

const ZP_PLUGIN_HANDLED = 97

/*================================================================================
[Global Vars]
=================================================================================*/

// Player vars ===============================================================
new g_is_alive[33]
new g_is_connected[33]
new g_level[33]
new g_reset_level[33]
new g_mission[33][2]
new g_mission_progress[33][MAX_KILLS]
new g_kills[33][MAX_KILLS]
new g_improv_human[33][MAX_IMPROV_HUMAN]
new g_improv_zombie[33][MAX_IMPROV_ZOMBIE]
new g_mejoras[33][2][5]
new g_points[33][2]
new g_points_spent[33][2]
new g_zombie[33]
new g_human[33]
new g_firstzombie[33]
new g_lastzombie[33]
new g_lasthuman[33]
new g_infection_level[33]
new g_infected[33]
new g_frozen[33]
new g_nodamage[33]
new g_respawn_as_zombie[33]
new g_special_respawn[33]
new g_nvision[33]
new g_nvisionenabled[33]
new g_zombieclass[33]
new g_humanclass[33]
new g_zombieclassnext[33]
new Float:g_hclass_nav_time[33]  // anti double-dispatch for hclass navigation
new g_currentweapon[33]
new g_canbuy[33]
new g_ammopacks[33]
new g_damagedealt[33]
new g_zombie_dmg[33]
new g_playermodel[33][32]
new g_menu_data[33][4]
new g_admin_action[33]      // accion pendiente en menu player-select: 1=nemesis 3=assassin 8=zombie 9=human
new g_owner_gift_type[33]   // 3=AP 4=PtsZombie 5=PtsHumano 6=PtsArma
new g_owner_gift_target[33] // target elegido en player-select de regalo
new g_burning_duration[33]
new g_has_unlimited_clip[33]
new g_rank_post[33]
new g_timelast[33]
new g_timeonline[33]
new g_weapon_icon[33][16]
new g_weapon_droped[33]
new g_pickup_time_msg[33]
new g_zombie_roundpoint[33]
new g_afk[33][3]
new g_parachute_entity[33]
new g_security_resets[33][3]
new g_user_aura
new g_user_nvg
new Float:g_velocity[33][3]
new Float:g_lastleaptime[33]
new Float:g_pickup_time[33]
// Account
new g_name[33][32]
new g_ip[33][24]
new g_login[33]
new g_registered[33]
new g_loading[33]
new g_login_error[33]
new g_new_password_status[33]
new g_login_attempts[33]
new g_temp_password[33][MAX_PASSWORD_LEN]
new g_password[33][MAX_PASSWORD_LEN]
new g_is_banned[33]
new g_ban_expire[33]
new g_hid[33][4][20]
new g_user_id[33]
new g_valid_email[33]
new g_send_email[33]
new g_email[33][40]
// Donate
new g_donate_amount[33]
new g_donate_limit[33][3]
// Say
new g_insult[33]
new g_old_msg[33][32]
new g_old_msg_time[33]
// Custom
new g_menu_colors[33]
new g_flare_color[33], g_nvg_color[33], g_autonvg[33], hud_color[33][2], Float:hud_posicion[33][2][2],
hud_menu[33], g_hud_unidadnum[33], Float:g_hud_unidad[33]
//Combo AmmoPack
new g_damagecombo[33]
new g_damagehits[33]
new g_combo[33]
new g_combo_ammopacks[33]
new g_info_combo[33][64]
new g_combo_ap_check[33]
// party
new g_party[33][party]
new g_pedidos[33][33]
// =======================================================================================


// Game vars
new g_nemround
new g_sniperround
new g_assaround
new g_synapsisround
new g_survround
new g_swarmround
new g_plagueround
new g_umbrellaround
new g_zombie_previousround[3]
new g_is_hf
new g_minplayers
new g_zombies
new g_humans
new g_newround
new g_endround
new g_lastmode
new g_scorezombies, g_scorehumans
new g_switchingteam
new g_countdown
new g_rank_total
new g_spawnCount
new Float:g_spawns[MAX_CSDM_SPAWNS][3]
new g_lights_i
new g_MsgSync, g_MsgSync2, g_MsgSync3, g_MsgSync4, g_MsgSync5
new g_freezetime, g_time, g_roundtime, g_dia
new g_players[32]
new g_maxplayers

// SVC Bad
new g_fix_delaymodel
const Float:g_modelchange_delay = 0.2
new Float:g_models_targettime
new Float:g_teams_targettime

// DualMP5
new g_attack[33]
new g_mp5[33]
new OrpheuFunction:Func_SetAnimation

// Util
new util_password[MAX_PASSWORD_LEN]
new g_item[1280], g_menu_slot[6], g_menu_null[2]
new g_admbantime[33]

// MySQL
new Handle:g_hTuple
new g_sql_stop

// Some forward handlers
new g_fwRoundStart, g_fwRoundEnd, g_fwUserInfected_pre, g_fwUserInfected_post,
g_fwUserHumanized_pre, g_fwUserHumanized_post, g_fwExtraItemSelected, g_fwDummyResult,
g_fwSpawn, g_fwPrecacheSound

// Temporary Database vars (used to restore players stats in case they get disconnected)
new db_name[MAX_STATS_SAVED][32]
new db_extraitems[MAX_STATS_SAVED][MAX_EXTRA_ITEMS]
new db_slot_i

// Extra Items
new g_extraitem_name[MAX_EXTRA_ITEMS][32]
new g_extraitem_cost[MAX_EXTRA_ITEMS]
new g_extraitem_team[MAX_EXTRA_ITEMS]
new g_extraitem_level[MAX_EXTRA_ITEMS][2]
new g_extraitem_limit[MAX_EXTRA_ITEMS]
new g_extraitem_count[3]

new g_extra_limit[33][MAX_EXTRA_ITEMS]

// Message IDs vars
new g_msgScoreInfo, g_msgScoreAttrib,  g_msgAmmoPickup, g_msgFlashlight,
g_msgScreenFade, g_msgDeathMsg, g_msgSetFOV, g_msgScreenShake,
g_msgTeamInfo, g_msgHideWeapon, g_msgCrosshair, g_IconStatus,
g_StatusText, g_StatusValue, g_msgWeaponList, g_msgRoundTime, g_msgVGUIMenu, g_msgShowMenu,
g_msgSayText, g_msgTutorText, g_msgTutorClose

// CVAR pointers
new cvar_lighting, cvar_plaguechance, cvar_zombiefirsthp, cvar_thunder, cvar_nemchance,
cvar_nemgravity,cvar_nemspd, cvar_survchance, cvar_survspd,
cvar_swarmchance, cvar_synapsischance, cvar_synapsis,
cvar_synapsisratio, cvar_multichance, cvar_sniperchance, cvar_freezeduration,
cvar_flareduration, cvar_humanlasthp,
cvar_countdown, cvar_assaspd, cvar_assassinchance, cvar_assassin, cvar_fireduration,
cvar_firedamage, cvar_multiratio, cvar_flaresize, cvar_flaresize2,
cvar_spawndelay, cvar_fireslowdown, cvar_plagueratio,
cvar_nemminplayers, cvar_survminplayers, cvar_swarmminplayers, cvar_multiminplayers,
cvar_plagueminplayers, pcvar_roundtime

// Infinite Rounds
new fix_roundend
new team_win
new g_gamingcommencement = true

new g_pGameRules
new bool:g_bLinux
new OrpheuHook:g_oMapConditions

// === Illidan Boss Round State ===
new g_illidanround
new bool:g_illidan_spawned
new g_illidan_boss
new g_illidan_hpbar
new g_illidan_phase
new g_illidan_ability
new g_illidan_blade[2]
new g_illidan_elem[2]
new g_illidan_elem_hp[2]
new g_illidan_elem_victim[2]
new Float:g_illidan_origin[3]
new Float:g_illidan_damage[33]
new Float:g_illidan_ability_time
new g_illidan_ires[14]
new OrpheuHook:g_oWinConditions
new OrpheuHook:g_oRoundTimeExpired
new MEMORY_ROUNDTIME[] = "roundTimeCheck"

/*================================================================================
[Main Forwards]
=================================================================================*/
public client_PreThink(id)
{
	if(!g_is_alive[id]) return
	
	if(is_zombie(id) || is_assassin(id))
		entity_set_int(id, EV_INT_flTimeStepSound, STEPTIME_SILENT)
	
	if(g_frozen[id])
		entity_set_vector(id, EV_VEC_velocity, Float:{0.0,0.0,0.0})

	static button, flags, oldbutton[33]
	button = get_user_button(id)
	flags = get_entity_flags(id)

	#if !defined USANDO_EN_LAN
	if(button && oldbutton[id] != button)
	{
		g_afk[id][0] = g_time
		g_afk[id][2] = 0
	}
	else if((g_time - g_afk[id][0]) > 25)
	{
		g_afk[id][2] = 1
		if((g_time - g_afk[id][0]) > 120)
		{
			g_afk[id][0] = g_time
			server_cmd("kick #%d ^"Kickeado por permaneser AFK por mas de 2 minutos.^"", get_user_userid(id))
			return
		}
		
		if(g_afk[id][1] < g_time)
		{
			zp_center_print(id, "Muevete o seras kickeado")
			client_print(id, print_console, "Muevete o seras kickeado")
			g_afk[id][1] = g_time + 1
		}
	}
	#endif

	if(g_freezetime) return

	if(allowed_leap(id, button, flags))
	{
		static force, Float:height, Float:velocity[3]

		if(is_nemesis(id)) {
			force = 555;height = 360.0
		}
		else if(is_survivor(id)) {
			force = 400;height = 235.0
		}
		else if(is_assassin(id)) {
			force = 450;height = 310.0
		}
		else if(g_zombieclass[id] == 7) {
			force = 465;height = 260.0
			if(g_nodamage[id]){force += 100;height += 80.0;}
		}
		else {
			force = 435;height = 217.0
			if(g_nodamage[id]){force += 100;height += 80.0;}
		}
		
		velocity_by_aim(id, force, velocity)
		velocity[2] = height
		entity_set_vector(id, EV_VEC_velocity, velocity)
		
		g_lastleaptime[id] = get_gametime()
	}
	
	entity_get_vector(id, EV_VEC_velocity, g_velocity[id])

	if(is_any_zombie(id)) return

	static Float:frame

	if(g_parachute_entity[id] > 0 && (flags & FL_ONGROUND)) {
		remove_entity(g_parachute_entity[id])
		player_gravity(id)
		g_parachute_entity[id] = 0
		return
	}

	if (button & IN_USE) {
		static Float:velocity[3]
		velocity[0] = g_velocity[id][0]
		velocity[1] = g_velocity[id][1]
		velocity[2] = g_velocity[id][2]

		if (velocity[2] < 0.0) {

			if(g_parachute_entity[id] <= 0) {
				g_parachute_entity[id] = create_entity("info_target")
				if(g_parachute_entity[id] > 0) {
					entity_set_string(g_parachute_entity[id], EV_SZ_classname,"parachute")
					entity_set_edict(g_parachute_entity[id], EV_ENT_aiment, id)
					entity_set_edict(g_parachute_entity[id], EV_ENT_owner, id)
					entity_set_int(g_parachute_entity[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_model(g_parachute_entity[id], "models/parachute.mdl")
					entity_set_int(g_parachute_entity[id], EV_INT_sequence, 0)
					entity_set_int(g_parachute_entity[id], EV_INT_gaitsequence, 1)
					entity_set_float(g_parachute_entity[id], EV_FL_frame, 0.0)
					entity_set_float(g_parachute_entity[id], EV_FL_fuser1, 0.0)
				}
			}

			if (g_parachute_entity[id] > 0) {

				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)

				velocity[2] = (velocity[2] + 40.0 < -90.0) ? velocity[2] + 40.0 : -90.0
				entity_set_vector(id, EV_VEC_velocity, velocity)

				if (entity_get_int(g_parachute_entity[id],EV_INT_sequence) == 0) {

					frame = entity_get_float(g_parachute_entity[id],EV_FL_fuser1) + 1.0
					entity_set_float(g_parachute_entity[id],EV_FL_fuser1,frame)
					entity_set_float(g_parachute_entity[id],EV_FL_frame,frame)

					if (frame > 100.0) {
						entity_set_float(g_parachute_entity[id], EV_FL_animtime, 0.0)
						entity_set_float(g_parachute_entity[id], EV_FL_framerate, 0.4)
						entity_set_int(g_parachute_entity[id], EV_INT_sequence, 1)
						entity_set_int(g_parachute_entity[id], EV_INT_gaitsequence, 1)
						entity_set_float(g_parachute_entity[id], EV_FL_frame, 0.0)
						entity_set_float(g_parachute_entity[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if (g_parachute_entity[id] > 0) {
			remove_entity(g_parachute_entity[id])
			player_gravity(id)
			g_parachute_entity[id] = 0
		}
	}
	else if ((oldbutton[id] & IN_USE) && g_parachute_entity[id] > 0 ) {
		remove_entity(g_parachute_entity[id])
		player_gravity(id)
		g_parachute_entity[id] = 0
	}
	
	oldbutton[id] = button
}

// Forward CmdStart
public fw_CmdStart(id, handle)
{
	if(!g_is_alive[id])
		return FMRES_IGNORED

	static buttons, key[33]
	
	buttons = get_uc(handle, UC_Buttons)
	
	if(is_any_zombie(id))
	{
		if(buttons & IN_RELOAD)
		{
			if(!key[id])
			{
				curar_team(id)
			}
			key[id] = true
		}
		else key[id] = false
	}
		
	if(!is_any_zombie(id) && g_currentweapon[id] == CSW_HEGRENADE && ((1<<g_current_grenade[id])&ALLOWED_GRENADE_MODE))
	{
		static grenade
		grenade = g_current_grenade[id]-1
	
		if(buttons & IN_ATTACK2)
		{
			if(!key[id])
			{
				if(g_grenade_mode[id][grenade] == MODE_MOTION)
					g_grenade_mode[id][grenade] = 0
				else
					g_grenade_mode[id][grenade]++
				zp_center_print(id, modes_name[g_grenade_mode[id][grenade]])
			}
			key[id] = true
		}
		else key[id] = false
	}

	if(get_uc(handle, UC_Impulse) != IMPULSE_FLASHLIGHT)
		return FMRES_IGNORED
	
	if(is_any_zombie(id) || is_survivor(id) || is_sniper(id))
	{
		set_uc(handle, UC_Impulse, 0)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

//------------------------------------------------------------
public fw_primary_attack_post(ent)
{
	if(pev_valid(ent) != PDATA_SAFE)
		return HAM_IGNORED

	new id = entity_get_edict(ent, EV_ENT_owner)
	if(!is_user_valid_alive(id) || !is_human(id))
		return HAM_IGNORED

	new w = cs_get_weapon_id(ent)
	new wkey = weapons_numid[w]

	if(wkey == -1)
		return HAM_IGNORED
		
	if(g_wpn_mejoras_active[id] && g_weapons_mejoras[id][wkey][1])
	{
		static Float:punchangle[3], Float:mul
		mul = (1.0 - (float(g_weapons_mejoras[id][wkey][1]) / 11.0))
		if(mul < 0.0) mul = 0.0

		g_recoil_mul[id] = mul

		entity_get_vector(id, EV_VEC_punchangle, punchangle)

		punchangle[0] *= mul
		punchangle[1] *= mul
		punchangle[2] *= mul

		entity_set_vector(id, EV_VEC_punchangle, punchangle)
	}

	if(g_wpn_mejoras_active[id] && g_weapons_mejoras[id][wkey][2])
	{
		static Float:mul, Float:next_attack
		mul = (1.0 - (float(g_weapons_mejoras[id][wkey][2]) / 11.0))
		if(mul < 0.0) mul = 0.0

		next_attack = get_pdata_float(ent, m_flNextPrimaryAttack, 4)
		if(next_attack > 0.0)
		{
			next_attack *= mul
			if(next_attack < 0.06) next_attack = 0.06
			set_pdata_float(ent, m_flNextPrimaryAttack, next_attack, 4)
		}
	}

	return HAM_IGNORED
}  

public fw_update_client_data(id, sendweapons, cd)
{
	if(id < 1 || id > g_maxplayers || !g_wpn_mejoras_active[id] || g_recoil_mul[id] >= 1.0)
		return FMRES_IGNORED

	static Float:punch[3]
	get_cd(cd, CD_PunchAngle, punch)
	punch[0] *= g_recoil_mul[id]
	punch[1] *= g_recoil_mul[id]
	punch[2] *= g_recoil_mul[id]
	set_cd(cd, CD_PunchAngle, punch)

	return FMRES_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {

	if(victim == attacker || !is_user_valid_connected(attacker) || g_minplayers)
		return HAM_IGNORED

	if(g_newround || g_endround)
		return HAM_SUPERCEDE
	
	if(g_nodamage[victim] || g_frozen[victim] || !g_is_alive[victim])
		return HAM_SUPERCEDE
	
	if((is_any_zombie(attacker) && is_any_zombie(victim)) || (!is_any_zombie(attacker) && !is_any_zombie(victim)))
		return HAM_SUPERCEDE

	if(g_infected[victim])
		return HAM_SUPERCEDE

	if(!is_any_zombie(attacker))
	{
		if(is_any_zombie(victim)) damage *= 0.75

		if(is_sniper(attacker))
		{
			if(g_currentweapon[attacker] == CSW_AWP)
			{
				damage *= 6.8
				SetHamParamFloat(4, damage)
				set_hudmessage(0, 255, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
				ShowSyncHudMsg(attacker, g_MsgSync3, "%d^n", floatround(damage))
			}
		}
		else if(is_survivor(attacker))
		{
			if(g_synapsisround)
				SetHamParamFloat(4, (damage *= 1.25))
			else if(g_plagueround)
				SetHamParamFloat(4, (damage *= 2.45))
			else
				SetHamParamFloat(4, (damage *= 3.35))

			set_hudmessage(0, 255, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
			ShowSyncHudMsg(attacker, g_MsgSync3, "%d^n", floatround(damage))
		}
		else
		{
			if(g_currentweapon[attacker] == CSW_SG550) damage *= 0.64
			
			static max_mejoras
			max_mejoras = 8+g_reset_level[attacker]
			if(max_mejoras > 15) max_mejoras = 15
			if(g_improv_human[attacker][H_IMPROV_DAMAGE] < max_mejoras)
				max_mejoras = g_improv_human[attacker][H_IMPROV_DAMAGE] 
		
			damage *= (1 + (max_mejoras * 0.2))
			SetHamParamFloat(4, damage)
				
			if(!g_afk[victim][2])
			{
			
			g_damagedealt[attacker] += floatround(damage)
			
			static g_ammodamage
			if(g_is_hf)
			{
				if(g_level[attacker] <= 40)
				{
					if(g_is_hf==1)
						g_ammodamage = AMMODAMAGE-200
					else
						g_ammodamage = AMMODAMAGE-300
				}
				else
				{
					if(g_is_hf==1)
						g_ammodamage = AMMODAMAGE-150
					else
						g_ammodamage = AMMODAMAGE-200
				}
			}
			else
			{
				if(g_level[attacker] <= 40)
					if(g_level[attacker] <= 20)
						g_ammodamage = AMMODAMAGE-350
					else g_ammodamage = AMMODAMAGE-250
				else
					g_ammodamage = AMMODAMAGE
			}

			new bool:up
			
			if(g_party[attacker][PARTY_ID] && g_has_unlimited_clip[attacker] <= g_time)
			{
			if(g_party[attacker][PARTY_ID] != g_party[victim][PARTY_ID])
			{
			static id;id=g_party[attacker][PARTY_ID]
				
			remove_task(id+TASK_RESET_COMBO)
			g_damagecombo[id] += floatround(damage)
			g_damagehits[id]++
			
			if(g_damagehits[id] > 10) {
				while(g_damagecombo[id] >= (85 * (g_combo[id] + 1)) + (g_combo[id] * 45)){
					g_combo[id]++
					up = true
				}
				if(up) {
					formatex(g_info_combo[id], 63, "Combo %d completado!", g_combo[id])
					
					remove_task(id+TASK_INFO_COMBO)
					set_task(3.0, "info_combo", id+TASK_INFO_COMBO)
				}
				
				remove_task(id+TASK_FINISH_COMBO)
				set_task(3.0, "finish_combo", id+TASK_FINISH_COMBO)
			}
			else {
				set_task(0.9, "reset_combo", id+TASK_RESET_COMBO)
			}
			}
			}
			else if(g_has_unlimited_clip[attacker] <= g_time)
			{
			remove_task(attacker+TASK_RESET_COMBO)
			g_damagecombo[attacker] += floatround(damage)
			g_damagehits[attacker]++
			
			if (g_damagehits[attacker] > 5) {
				while(g_damagecombo[attacker] >= (80 * (g_combo[attacker] + 1)) + (g_combo[attacker] * 40)){
					g_combo[attacker]++
					if(g_combo[attacker] >= 30) {
						up = false
						finish_combo(attacker+TASK_FINISH_COMBO)
					}
					else
						up = true
				}
				if (up){
					formatex(g_info_combo[attacker], 63, "Combo %d completado!", g_combo[attacker])
					
					remove_task(attacker+TASK_INFO_COMBO)
					set_task(3.0, "info_combo", attacker+TASK_INFO_COMBO)
				}
				if(!g_combo_ap_check[attacker]) {
					g_combo_ammopacks[attacker] = g_ammopacks[attacker]
					g_combo_ap_check[attacker] = true
				}
				
				remove_task(attacker+TASK_FINISH_COMBO)
				set_task(3.0, "finish_combo", attacker+TASK_FINISH_COMBO)
			}
			else {
				set_task(1.1, "reset_combo", attacker+TASK_RESET_COMBO)
			}
			}

			show_current_combo(attacker, floatround(damage))

			while(g_damagedealt[attacker] >= g_ammodamage) {
				g_ammopacks[attacker]++
				g_damagedealt[attacker] -= g_ammodamage
				check_player_level(attacker)
			}
			}
		}
		
		return HAM_IGNORED
	}
	
	if(damage_type & DMG_HEGRENADE)
		return HAM_SUPERCEDE
	
	if(is_nemesis(attacker) || is_assassin(attacker) || (is_any_zombie(attacker) && (g_swarmround || g_plagueround || g_humans == 1)))
	{
		if(is_nemesis(attacker) || is_assassin(attacker))
		{
			damage = 275.0
			SetHamParamFloat(4, damage)
		}
		else {
			damage *= (1 + (g_improv_zombie[attacker][Z_IMPROV_DAMAGE] * 0.2))
			SetHamParamFloat(4, damage)
		}
		set_hudmessage(0, 255, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(attacker, g_MsgSync3, "%d^n", floatround(damage))
		return HAM_IGNORED
	}
	
	if(g_swarmround || g_plagueround || g_humans == 1)
		return HAM_IGNORED

	static armor
	armor = get_user_armor(victim)

	if(armor > 0)
	{
		emit_sound(victim, CHAN_BODY, sound_armorhit, 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_user_armor(victim, max(0, armor - floatround(damage)))
		if(is_zombie(attacker))
		{
			g_zombie_dmg[attacker] += floatround(damage)
			while(g_zombie_dmg[attacker] >= ZOMBIE_DMG_PER_AP)
			{
				g_ammopacks[attacker]++
				g_zombie_dmg[attacker] -= ZOMBIE_DMG_PER_AP
			}
		}
		return HAM_SUPERCEDE
	}
	
	z_warlock[attacker]++
		
		
	SendDeathMsg(attacker, victim)
	FixDeadAttrib(victim)
	UpdateFrags(attacker, victim, 1, 1, 1)
	
	zombieme(victim, CLASS_ZOMBIE, attacker)

	add_kill(attacker, KILL_INFECT)
	g_ammopacks[attacker] += 15
	check_player_level(attacker)

	set_user_health(attacker, (get_user_health(attacker)+230))
	
	return HAM_SUPERCEDE
}

public fw_TakeDamage_Post(victim)
{
	if(!is_user_valid_alive(victim) || pev_valid(victim) != PDATA_SAFE)
		return

	if(is_human(victim) || is_survivor(victim) || is_sniper(victim) || is_assassin(victim) || g_firstzombie[victim])
		set_pdata_float(victim, OFFSET_PAINSHOCK, 1.0, OFFSET_LINUX)
	else if(is_any_zombie(victim))
		set_pdata_float(victim, OFFSET_PAINSHOCK, 0.5, OFFSET_LINUX)
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_valid_connected(attacker))
		return HAM_IGNORED
	
	if(g_survround && is_survivor(attacker) && g_currentweapon[attacker] != CSW_KNIFE)
	{
		static iOrigin[3], Float:flEnd[3]

		get_user_origin(attacker, iOrigin, 1)
		get_tr2(tracehandle, TR_vecEndPos, flEnd)

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_TRACER)
		write_coord(iOrigin[0])
		write_coord(iOrigin[1])
		write_coord(iOrigin[2])
		write_coord_f(flEnd[0]) 
		write_coord_f(flEnd[1]) 
		write_coord_f(flEnd[2]) 
		message_end()
	}

	if(g_newround || g_endround)
		return HAM_SUPERCEDE
	
	if(g_nodamage[victim] || g_frozen[victim])
		return HAM_SUPERCEDE
	
	if((is_any_zombie(attacker) && is_any_zombie(victim)) || (!is_any_zombie(attacker) && !is_any_zombie(victim)))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public Ham_BloodColor_Pre(id)
{
	if(is_zombie(id))
	{
		if(g_zombieclass[id] == 1 || g_zombieclass[id] == 3)
			SetHamReturnInteger(56)
		else
			SetHamReturnInteger(67)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}  

public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id) || !fm_get_user_team(id)) return
	
	if(!g_login[id])
	{
		if(is_user_bot(id))
			g_login[id] = true
		else
		{
			server_cmd("kick #%d ^"No estas logeado^"", get_user_userid(id))
			return
		}
	}
	
	remove_task(id+TASK_SPAWN)
	remove_task(id+TASK_TEAM)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_BURN)

	del_aura(id)

	g_afk[id][0] = time()
	g_is_alive[id] = true
	
	do_random_spawn(id)

	remove_grenades(id)
	reset_hud(id)
	
	if(g_special_respawn[id])
	{
		reset_vars(id, 0)
		
		if(g_special_respawn[id] > 20)
			humanme(id, g_special_respawn[id]-20)
		else zombieme(id, g_special_respawn[id])
		
		g_special_respawn[id] = 0
		return
	}
			
	if(g_respawn_as_zombie[id] && !g_newround)
	{
		reset_vars(id, 0)
		zombieme(id, CLASS_ZOMBIE)
		return
	}

	reset_vars(id, 0)
	check_class_fixbug(id)
	g_human[id] = CLASS_HUMAN
	set_pev(id, pev_viewmodel2, "")   // clear zombie claw/knife override
	set_pev(id, pev_weaponmodel2, "")

	strip_user_weapons(id)
	give_item(id, "weapon_knife")

	set_user_health(id, (g_hclass[g_humanclass[id]][HCLASS_HEALTH] + (g_improv_human[id][H_IMPROV_HEALTH] * 25)))
	set_user_armor(id, (g_hclass[g_humanclass[id]][HCLASS_ARMOR] + (g_improv_human[id][H_IMPROV_ARMOR] * 15)))
	parachute_reset(id)

	if(!g_newround && fm_get_user_team(id) != ZP_TEAM_CT)
	{
		remove_task(id+TASK_TEAM)
		fm_set_user_team(id, ZP_TEAM_CT)
		fm_user_team_update(id)
	}


	static already_has_model
	already_has_model = false
	
	if(get_user_flags(id) & ACCESS_FLAG)
	{
		if(equal(model_admin, g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), model_admin)
	}
	else {
		if(equal(g_hclass[g_humanclass[id]][HCLASS_MODEL], g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), g_hclass[g_humanclass[id]][HCLASS_MODEL])
	}
	
	if(!already_has_model)
	{
		if(g_newround || g_fix_delaymodel)
		{
			set_task(0.2, "fm_user_model_update", id+TASK_MODEL)
		}
		else
		{
			fm_user_model_update(id+TASK_MODEL)
		}
	}
	fm_cs_set_user_model_index(id, default_model_index)

	set_user_rendering(id)

	set_task(0.4, "show_menu_prebuy", id+TASK_SPAWN)

	set_task(5.0, "respawn_player", id+TASK_SPAWN)
	
	
	if(!g_newround) set_protection(id, SPAWNPROTECTION)

	fmCheckHZ()
	fnCheckLastZombie()
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(!is_user_valid_connected(victim))
		return

	g_is_alive[victim] = false

	if(is_user_valid_connected(attacker) && attacker != victim && !g_minplayers && !g_afk[victim][2])
	{
		if(is_human(attacker))
		{
			if(is_nemesis(victim))
			{
				add_kill(attacker, KILL_NEMESIS)
				if(g_currentweapon[attacker] == CSW_KNIFE)
				{
					zp_colored_print(attacker, "^4[Z-Evil]^3 Mataste al Nemesis con cuchi,Ganaste puntos y ammopacks extras.")
					g_points[attacker][TEAM_HUMAN] += 9
					g_weapons_puntos[attacker][TEAM_HUMAN] += 8
					g_ammopacks[attacker] += 150
				}
				else {
					g_points[attacker][TEAM_HUMAN] += 4
					g_weapons_puntos[attacker][TEAM_HUMAN] += 3
					g_ammopacks[attacker] += 55
					zp_colored_print(attacker, "^4[Z-Evil]^3 Mataste al Nemesis,Ganaste puntos y ammopacks extras.")
				}
			}
			else if(is_assassin(victim))
			{
				add_kill(attacker, KILL_ASSASSIN)
				g_ammopacks[attacker] += 45
				g_points[attacker][TEAM_HUMAN] += 3
				g_weapons_puntos[attacker][TEAM_HUMAN] += 2
				zp_colored_print(attacker, "^4[Z-Evil]^3 Mataste al Assassin,Ganaste puntos y ammopacks extras.")
			}
			else {
				add_kill(attacker, KILL_ZOMBIE)
				g_ammopacks[attacker] += 6
			}
		}
		else if(is_zombie(attacker))
		{
			if(is_survivor(victim))
			{
				add_kill(attacker, KILL_SURVIVOR)
				g_ammopacks[attacker] += 70
				g_points[attacker][TEAM_ZOMBIE] += 6
			}
			else if(is_sniper(victim))
			{
				add_kill(attacker, KILL_SNIPER)
				g_ammopacks[attacker] += 75
				g_points[attacker][TEAM_ZOMBIE] += 7
			}
			else if(is_civil(victim))
			{
				add_kill(attacker, KILL_CIVIL)
				g_ammopacks[attacker] += 55
				g_points[attacker][TEAM_ZOMBIE] += 4
			}
			else if(is_umbrella(victim))
			{
				add_kill(attacker, KILL_UMBRELLA)
				g_ammopacks[attacker] += 30
			}
			else {
				add_kill(attacker, KILL_HUMAN)
				g_ammopacks[attacker] += 15

			}
		}
		else if(is_survivor(attacker))
		{
			if(is_nemesis(victim))
				g_ammopacks[attacker] += 30
			else
				g_ammopacks[attacker] += 7
		}
		else if(is_sniper(attacker))
		{
			g_ammopacks[attacker] += 8
			static origin[3]
			get_user_origin(victim, origin)
			message_begin(MSG_PVS, SVC_TEMPENTITY, origin, 0)
			write_byte(TE_SPRITETRAIL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_short(g_glowSpr)
			write_byte(115)
			write_byte(1)
			write_byte(2)
			write_byte(60)
			write_byte(60) 
			message_end()
		}
		else if(is_nemesis(attacker) || is_assassin(attacker))
		{
			if(is_survivor(victim))
				g_ammopacks[attacker] += 12
			else
				g_ammopacks[attacker] += 4

		}
		if(is_zombie(victim) && !is_nemesis(victim) && !is_assassin(victim))
			g_ammopacks[victim] += 5
		check_player_level(attacker)
	}

	if(is_zombie(victim))
	{
		remove_task(victim+TASK_BLOOD)
		remove_task(victim+TASK_BURN)
		if(random_num(1, 15) == 3)
			create_recompensa(victim)
	}
	
	remove_weapon_icon(victim)
	parachute_reset(victim)

	set_task(0.4, "spec_nvision", victim)
	
	fmCheckHZ()
	fnCheckLastZombie()
	
	if(is_civil(victim))
		set_round_end(1)
	else {
		if((is_any_zombie(victim) && !g_zombies)) // Human Win
		{
			if(g_umbrellaround)
				set_round_end(2)
			else set_round_end(0)
		}
		else if((!is_any_zombie(victim) && !g_humans)) // Zombie Win
		{
			if(!g_illidanround)
				set_round_end(0)
		}
	}

	del_aura(victim)

	// Illidan round: respawn dead humans after short delay
	if(g_illidanround && !g_endround && !g_is_alive[victim])
	{
		set_task(5.0, "illidan_respawn_human", victim + TASK_SPAWN)
		return
	}

	if(is_nemesis(victim))
		SetHamParamInteger(3, 2)

	static selfkill
	selfkill = (victim == attacker || !is_user_valid_connected(attacker)) ? true : false

	if(!is_any_zombie(victim) && g_humans <= 1)
		return

	g_respawn_as_zombie[victim] = true
	set_task(get_pcvar_float(cvar_spawndelay), "respawn_player", victim+TASK_SPAWN)
	
	if(selfkill) return
	
	UpdateFrags(attacker, victim, 0, 0, 0)
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weaponent, id)
{
	if(!is_user_valid_connected(id))
		return HAM_IGNORED
	
	if(is_any_zombie(id))
		return HAM_SUPERCEDE
	
	if(!(get_user_button(id) & IN_DUCK))
		return HAM_SUPERCEDE
		
	static wpn, type
	wpn = zp_get_weaponid(weaponent, type)
	
	if(wpn == -1) return HAM_SUPERCEDE

	if(type == WPN_TYPE_PRIMARY)
	{
		if(g_level[id] < g_primary_weapons[wpn][WPN_LEVEL] || g_reset_level[id] < g_primary_weapons[wpn][WPN_RESET])
		{
			if(g_time > g_pickup_time_msg[id])
			{
				zp_colored_print(id, "!g- !t%s !y| !tLevel: !y%d | !tReset: !y%d", g_primary_weapons[wpn][WPN_NAME],
				g_primary_weapons[wpn][WPN_LEVEL], g_primary_weapons[wpn][WPN_RESET])
				g_pickup_time_msg[id] = g_time + 3
			}
			return HAM_SUPERCEDE
		}
	}
	else if(type == WPN_TYPE_SECONDARY)
	{
		if(g_level[id] < g_secondary_weapons[wpn][WPN_LEVEL] || g_reset_level[id] < g_secondary_weapons[wpn][WPN_RESET])
		{
			if(g_time > g_pickup_time_msg[id])
			{
				zp_colored_print(id, "!g- !t%s !y| !tLevel: !y%d | !tReset: !y%d", g_secondary_weapons[wpn][WPN_NAME],
				g_secondary_weapons[wpn][WPN_LEVEL], g_secondary_weapons[wpn][WPN_RESET])
				g_pickup_time_msg[id] = g_time + 3
			}
			return HAM_SUPERCEDE
		}
	}
	/*else if(type == WPN_TYPE_IMPROVED)
	{
	
	}*/

	g_pickup_time[id] = get_gametime()+0.1

	return HAM_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE

	if(!is_user_valid_connected(id))
		return FMRES_IGNORED

	if((sample[6] == 'g' && sample[7] == 'u' && sample[10] == 'i' && sample[15] == '2') && g_pickup_time[id] >= get_gametime()) {
		emit_sound(id, channel, sound_pickup, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE
	}

	if(!is_any_zombie(id))
		return FMRES_IGNORED
	
	// Zombie being hit
	if(sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		if(is_nemesis(id))
			emit_sound(id, channel, nemesis_pain[random_num(0, charsmax(nemesis_pain))], volume, attn, flags, pitch)
		else
			emit_sound(id, channel, zombie_pain[random_num(0, charsmax(zombie_pain))], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE
	}
	
	// Zombie attacks with knife
	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
		{
			emit_sound(id, channel, zombie_miss_slash[random_num(0, charsmax(zombie_miss_slash))], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w') // wall
			{
				emit_sound(id, channel, zombie_miss_wall[random_num(0, charsmax(zombie_miss_wall))], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE
			}
			else // hit
			{
				emit_sound(id, channel, zombie_hit_normal[random_num(0, charsmax(zombie_hit_normal))], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')  // stab
		{
			emit_sound(id, channel, zombie_hit_stab[random_num(0, charsmax(zombie_hit_stab))], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		if(is_nemesis(id) || is_assassin(id))
			emit_sound(id, channel, sound_neme_death, volume, attn, flags, pitch)
		else
			emit_sound(id, channel, zombie_die[random_num(0, charsmax(zombie_die))], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE
	}
	
	// Zombie falls off
	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		emit_sound(id, channel, zombie_fall[random_num(0, charsmax(zombie_fall))], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{
	if(key[0] == 'm' && key[3] == 'e' && key[4] == 'l')
		return FMRES_SUPERCEDE
	
	return FMRES_IGNORED
}

public fw_ClientUserInfoChanged(id, buffer)
{
	static currentmodel[32]
	get_user_info(id, "model", currentmodel, charsmax(currentmodel))
	
	if(!equal(currentmodel, g_playermodel[id]) && !task_exists(id+TASK_MODEL))
		fm_set_user_model(id+TASK_MODEL)

	if(!g_is_connected[id]) return FMRES_IGNORED

	static new_name[32]

	engfunc(EngFunc_InfoKeyValue, buffer, "name", new_name, charsmax(new_name))

	if(equal(new_name, g_name[id])) return FMRES_IGNORED

	engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", g_name[id])

	client_cmd(id, "name ^"%s^";setinfo name ^"%s^"", g_name[id], g_name[id])

	client_print(id, print_console, "[Z-Evil] No esta permitido cambiarse el nick")
	zp_colored_print(id, "!g[Z-Evil] !tNo esta permitido cambiarse el nick")

	return FMRES_SUPERCEDE
}

public fw_ThinkGrenade(entity)
{
	if(!is_valid_ent(entity))
		return HAM_IGNORED

	static Float:dmgtime, Float:current_time
	dmgtime = entity_get_float(entity, EV_FL_dmgtime)
	current_time = get_gametime()

	if(dmgtime > current_time) {
		think_grenade_mode(entity, current_time)
		return HAM_IGNORED
	}
	
	switch(get_nadetype(entity))
	{
		case NADE_TYPE_INFECTION:
			infection_explode(entity)
		case NADE_TYPE_NAPALM:
			fire_explode(entity)
		case NADE_TYPE_FROST:
			frost_explode(entity)
		case NADE_TYPE_FORCEFIELD:
		{
			new field_entity = entity_get_int(entity, EV_INT_iuser4)
			if(field_entity)
			{
				if(is_valid_ent(field_entity)) remove_entity(field_entity)
				remove_entity(entity)
			}
			else {
				if((get_entity_flags(entity) & FL_ONGROUND) && get_speed(entity) < 10)
					bubble_explode(entity)
				else {
					entity_set_float(entity, EV_FL_dmgtime, (current_time + 0.5))
					return HAM_IGNORED
				}
			}
		}
		case NADE_TYPE_ANTIDOTEBOMB:
			antidote_explode(entity)
		case NADE_TYPE_HE:
			he_explode(entity)
		case NADE_TYPE_MOLOTOV:
			molotov_explode(entity)
		case NADE_TYPE_FLARE:
		{			
			static duration
			duration = entity_get_int(entity, FLARE_DURATION)
			
			if(duration > 0)
			{
				if(duration <= 1)
				{
					remove_entity(entity)
					return HAM_SUPERCEDE
				}
				
				flare_lighting(entity, duration)

				entity_set_int(entity, FLARE_DURATION, --duration)
				entity_set_float(entity, EV_FL_dmgtime, (current_time + 5.0))
			}
			else if((get_entity_flags(entity) & FL_ONGROUND) && get_speed(entity) < 10) {
				emit_sound(entity, CHAN_WEAPON, sound_flare, 1.0, ATTN_NORM, 0, PITCH_NORM)				
				
				entity_set_int(entity, FLARE_DURATION, (1 + get_pcvar_num(cvar_flareduration)/5))
				entity_set_float(entity, EV_FL_dmgtime, (current_time + 1.0))
			}
			else {
				entity_set_float(entity, EV_FL_dmgtime, (current_time + 0.5))
			}
			return HAM_IGNORED
		}
		default: return HAM_IGNORED
	}
	
	return HAM_SUPERCEDE
}

think_grenade_mode(ent, Float:gametime)
{
	if(get_nadetype(ent) >= NADE_TYPE_HE)
		return

	static i, Float:origin[3], Float:porigin[3], trace = 0, Float:fraction

	switch(entity_get_int(ent, NADE_MODE))
	{
		case MODE_PROXIMITY:
		{
			if(!(entity_get_int(ent, EV_INT_flags) & FL_ONGROUND))
				return
				
			entity_get_vector(ent, EV_VEC_origin, origin)
			
			if(entity_get_float(ent, NADE_BLAST_TIME) <= gametime)
			{
				entity_set_float(ent, NADE_BLAST_TIME, gametime+2.0)
				show_ring(ent, origin)
			}
			
			i = -1
			while(0 < (i = find_ent_in_sphere(i, origin, 95.0)) <= 32)
			{
				if(g_is_alive[i] && is_any_zombie(i))
				{
					entity_set_float(ent, EV_FL_dmgtime, 0.0)
					return
				}
			}
				
			entity_set_float(ent, EV_FL_nextthink, gametime+0.9)
		}
		case MODE_MOTION:
		{
			if(!(entity_get_int(ent, EV_INT_flags) & FL_ONGROUND))
				return

			entity_get_vector(ent, EV_VEC_origin, origin)
			
			if(entity_get_float(ent, NADE_BLAST_TIME) <= gametime)
			{
				entity_set_float(ent, NADE_BLAST_TIME, gametime+2.0)
				show_ring(ent, origin)
			}
			
			i = -1
			static Float:v[3], Float:velocity
			
			while(0 < (i = find_ent_in_sphere(i, origin, 95.0)) <= 32)
			{
				if(g_is_alive[i] && is_any_zombie(i))
				{
					entity_get_vector(ent, EV_VEC_origin, porigin)
					engfunc(EngFunc_TraceLine, origin, porigin, IGNORE_MONSTERS, 0, trace)
					get_tr2(trace, TR_flFraction, fraction)
					if(fraction < 1.0) continue
					
					entity_get_vector(i, EV_VEC_velocity, v)
					velocity = xs_vec_len(v)
					
					if(velocity > 190.0)
					{
						entity_set_float(ent, EV_FL_dmgtime, 0.0)
						return
					}
				}
			}
			entity_set_float(ent, EV_FL_nextthink, gametime+0.9)
		}
	}
}

public fw_touchGrenade(nade, entity)
{
	if(!is_solid(entity))
		return HAM_IGNORED

	if(entity_get_int(nade, NADE_MODE) == MODE_IMPACT)
	{
		entity_set_float(nade, EV_FL_nextthink, get_gametime()+0.05)
		entity_set_float(nade, EV_FL_dmgtime, 0.0)
	}

	return HAM_IGNORED
}

public fw_SetModel(entity, const model[])
{
	static id
	id = entity_get_edict(entity, EV_ENT_owner)
	if(0 > id > 32)
		return FMRES_IGNORED

	static Float:dmgtime
	dmgtime = entity_get_float(entity, EV_FL_dmgtime)

	if(dmgtime == 0.0) 
	{
		if(g_weapon_droped[id])
		{
			entity_set_int(entity, ENTVAR_WEAPON_ID, g_weapon_droped[id])
			entity_set_float(entity, EV_FL_nextthink, get_gametime()+REMOVEDDROPPED_TIME)
			g_weapon_droped[id] = 0
		}	
		return FMRES_IGNORED
	}

	if(!g_is_connected[id])	return FMRES_IGNORED

	if(model[9] != 'h' || model[10] != 'e')
		return FMRES_IGNORED
		
	dmgtime = get_gametime()

	static grenade;grenade = g_current_grenade[id]-1 // -1 fix
	
	if(0 >= (--g_has_grenades[id][grenade]))
	{
		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<g_grenades_basew[id][grenade]))
		check_hasgrenade(id)
	}

	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id)
	write_byte(new_grenades[grenade][WL_AID])
	write_byte(g_has_grenades[id][grenade])
	message_end()
		
	if(_:--g_has_grenades[id][_GRENADES] > 0)
	{		
		new ent = find_ent_by_owner(FM_NULLENT, WEAPONENTNAMES[CSW_HEGRENADE], id)
		if(ent) ExecuteHamB(Ham_Item_Deploy, ent)
	}

	if(!is_any_zombie(id))
	{
		entity_set_int(entity, NADE_MODE, g_grenade_mode[id][grenade])

		if(g_grenade_mode[id][grenade] == MODE_NORMAL) { }
		else if(g_grenade_mode[id][grenade] == MODE_PROXIMITY || g_grenade_mode[id][grenade] == MODE_MOTION)
		{
			entity_set_float(entity, NADE_BLAST_TIME, dmgtime+1.5)
			entity_set_float(entity, EV_FL_dmgtime, dmgtime+200.0)
		}
		else {
			entity_set_float(entity, EV_FL_nextthink, dmgtime+10.0)
		}
	}
	grenade++ // +1 fix
	
	set_nadetype(entity, grenade)
	switch(grenade)
	{
		case NADE_TYPE_INFECTION:
		{
			create_trail(entity, 0, 200, 0)
			return FMRES_IGNORED
		}
		case NADE_TYPE_NAPALM:
		{
			create_trail(entity, 200, 0, 0)
			entity_set_model(entity, model_w_grenade_fire)
			return FMRES_SUPERCEDE
		}
		case NADE_TYPE_FROST:
		{
			create_trail(entity, 20, 60, 255)			
			entity_set_model(entity, model_w_grenade_frost)
			return FMRES_SUPERCEDE
		}
		case NADE_TYPE_FLARE:
		{
			set_rendering(entity, kRenderFxGlowShell, COLOR_VALUES[g_flare_color[id]][0], COLOR_VALUES[g_flare_color[id]][1], COLOR_VALUES[g_flare_color[id]][2], kRenderNormal, 16);
			create_trail(entity, COLOR_VALUES[g_flare_color[id]][0], COLOR_VALUES[g_flare_color[id]][1], COLOR_VALUES[g_flare_color[id]][2])

			entity_set_int(entity, FLARE_COLOR, g_flare_color[id])
			entity_set_model(entity, model_w_grenade_flare)
			return FMRES_SUPERCEDE
		}
		case NADE_TYPE_FORCEFIELD:
		{
			create_trail(entity, 85, 170, 255)
			entity_set_model(entity, model_w_grenade_field)
			return FMRES_SUPERCEDE
		}
		case NADE_TYPE_ANTIDOTEBOMB:
		{
			create_trail(entity, 0, 200, 0)
		}
		case NADE_TYPE_HE:
		{
			create_trail(entity, 255, 200, 0)
		}
		case NADE_TYPE_MOLOTOV:
		{
			entity_set_int(entity, NADE_MODE, MODE_IMPACT)
			entity_set_int(entity, EV_INT_sequence, 2)
			entity_set_float(entity, EV_FL_nextthink, dmgtime+10.0)
			entity_set_float(entity, EV_FL_framerate, 2.0)
			entity_set_model(entity, model_w_grenade_molotov)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_UseStationary(entity, caller, activator, use_type)
{
	if(use_type == USE_USING && is_user_valid_connected(caller) && is_any_zombie(caller))
		return HAM_SUPERCEDE
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == USE_STOPPED && is_user_valid_connected(caller))
		replace_models(caller)
}

public fw_UsePushable() return HAM_SUPERCEDE

public fw_HamRemovePlayerItem(id, weaponent)
{
	if(!is_user_valid_connected(id) || !is_valid_ent(weaponent))
		return HAM_IGNORED
	
	g_weapon_droped[id] = entity_get_int(weaponent, ENTVAR_WEAPON_ID)
	
	return HAM_IGNORED
}

public fw_ThinkWeaponbox(ent)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED

	static Float:amount
	amount = entity_get_float(ent, EV_FL_renderamt)

	if(amount == 0.0)
	{
		entity_set_int(ent, EV_INT_rendermode, kRenderTransAlpha)

		entity_set_float(ent, EV_FL_renderamt, 255.0)
		entity_set_vector(ent, EV_VEC_rendercolor, Float:{255.0, 255.0, 0.0})
		
		entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.1)
		
		return HAM_SUPERCEDE
	}
	
	if(amount < 0) return HAM_IGNORED

	
	entity_set_float(ent, EV_FL_renderamt, amount-25.0)
	entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.1)
	return HAM_SUPERCEDE
}

public fw_he_primary_attack(ent)
{
	if(pev_valid(ent) != 2)
		return HAM_IGNORED
		
	static id
	id = get_pdata_cbase(ent, 41, 4)

	if(g_current_grenade[id] != NADE_TYPE_MOLOTOV || entity_get_int(id, EV_INT_waterlevel) != 3)
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}

public fw_mp5_primary_attack(ent)
{
	if(pev_valid(ent) != 2)
		return HAM_IGNORED
		
	static id
	id = get_pdata_cbase(ent, 41, 4)

	if(!is_survivor(id)) return HAM_IGNORED
	
	g_mp5[id] = true
	
	return HAM_IGNORED
}

public OrpheuHookReturn:OP_SetAnimation(const id,const animation)
{
	if(!g_mp5[id] || animation != 5) return OrpheuIgnored
	
	g_attack[id] = !(g_attack[id])
	g_mp5[id] = false
	
	OrpheuSetParam( 2, 5+g_attack[id]);
	return OrpheuOverride;
}

public client_kill(id) return PLUGIN_HANDLED


public fw_Spawn(entity)
{
	if (!is_valid_ent(entity)) return FMRES_IGNORED
	
	new classname[32]
	entity_get_string(entity, EV_SZ_classname, classname, charsmax(classname))
	
	for(new i = 0; i < sizeof g_objective_ents; i++)
	{
		if(equal(classname, g_objective_ents[i]))
		{
			remove_entity(entity)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fw_PrecacheSound(const sound[])
{
	if(equal(sound, "hostage", 7)) return FMRES_SUPERCEDE
	
	return FMRES_IGNORED
}

public fw_touch_forcefield(ent, id)
{
	if(is_zombie(id))
	{
		static Float:pos_ptr[3], Float:pos_ptd[3]

		entity_get_vector(ent, EV_VEC_origin, pos_ptr)
		entity_get_vector(id, EV_VEC_origin, pos_ptd)

		for(new i = 0; i < 3; i++)
		{
			pos_ptd[i] -= pos_ptr[i]
			pos_ptd[i] *= 1.8
		}
		entity_set_vector(id, EV_VEC_velocity, pos_ptd)
		entity_set_vector(id, EV_INT_impulse, pos_ptd)
	}
}

public fw_AddPlayerItem(id, weapon_ent)
{
	if(!g_is_alive[id]) return

	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)

	if(MAXBPAMMO[weaponid] > 2)
		cs_set_user_bpammo(id, weaponid, MAXBPAMMO[weaponid])

	for(new i; i < _GRENADES; i++)
	{
		if(!g_has_grenades[id][i] || g_grenades_basew[id][i] != weaponid)
			continue

		new neww = get_freeweapon(entity_get_int(id, EV_INT_weapons))

		send_defaultweaponlist(id, weaponid)
		send_saveweaponlist(id, weaponid, neww)
		g_grenades_basew[id][i] = neww
		set_pev(id, pev_weapons, pev(id,pev_weapons) | (1<<neww))
		return
	}
	
	if(sends_wid[id] & (1<<weaponid))
	{
		send_defaultweaponlist(id, weaponid)
	}
}

public fw_Item_Deploy_Post(weapon_ent)
{
	if(pev_valid(weapon_ent) != 2) return

	static id, weapon
	id = fm_cs_get_weapon_ent_owner(weapon_ent)
	weapon = cs_get_weapon_id(weapon_ent)

	g_currentweapon[id] = weapon


	remove_weapon_icon(id)
	draw_weapon_icon(id)

	static hide[33]

	if(is_any_zombie(id) && weapon == CSW_KNIFE)
	{
		message_begin(MSG_ONE,  g_msgHideWeapon, _, id)
		write_byte((HIDE_HUD|(1<<6)))
		message_end()
		hide[id] = true
	}
	else if(hide[id])
	{
		message_begin(MSG_ONE,  g_msgHideWeapon, _, id)
		write_byte(HIDE_HUD)
		message_end()
		hide[id] = false
	}
	
	if(weapon == CSW_HEGRENADE)
	{
		grenade_deploy(id)

		if(!is_any_zombie(id))
		{
			if(((1<<g_current_grenade[id])&ALLOWED_GRENADE_MODE))
				zp_center_print(id, modes_name[g_grenade_mode[id][g_current_grenade[id]-1]])
		}
	}

	if(is_any_zombie(id) && !((1<<g_currentweapon[id]) & ZOMBIE_ALLOWED_WEAPONS_BITSUM))
	{
		g_currentweapon[id] = CSW_KNIFE
		engclient_cmd(id, "weapon_knife")
	}
	replace_models(id)
}

public fw_Item_PreFrame(id)
{
	player_maxspeed(id)
}

public client_connect(id)
{
	static name[32]
	get_user_name(id, name, 31)

	if(is_user_hltv(id))
	{
		server_cmd("kick #%d ^"No hay soporte para hltv^"", get_user_userid(id))
		return
	}

	new rsound = random_num(-1, 1)
	if(rsound == -1) rsound = random_num(10, 11)
	
	mp3_sound_play(id, rsound)
}

public client_putinserver(id)
{
	g_is_connected[id] = true

	get_user_name(id, g_name[id], 31)
	get_user_ip(id, g_ip[id], 23)
	get_user_info(id, "*HID", g_hid[id][0], 19)

	mp3_sound_stop(id)

	reset_vars(id, 1)

	g_loading[id] = true
	load_cuenta_task(id)

	load_stats(id)
	
	set_task(5.0, "disable_minmodels", id)
}

public disable_minmodels(id)
{
	if(!g_is_connected[id]) return
	
	client_cmd(id, "cl_minmodels 0")
	client_cmd(id, "BiNd ^"b^" ^"buy; buyze^"")
	client_cmd(id, "bind v +setlaser")
	client_cmd(id, "bind c +dellaser")
}

// Client disconnect
public client_disconnect(id)
{
	g_timeonline[id] += get_user_time(id, 1)
	
	if(get_timeleft() > 1)
		SaveCuenta(id, 0)

	destroyall_party(id)
	salir_party(id, 0)

	g_is_connected[id] = false
	check_round(id)
	g_is_alive[id] = false

	min_players()

	save_stats(id)
	
	// Remove previous tasks
	remove_task(id+TASK_TEAM)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_SPAWN)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_INFO_COMBO)
	remove_task(id+TASK_FINISH_COMBO)
	remove_task(id+TASK_RESET_COMBO)
	remove_task(id+TASK_SAVE)
	remove_task(id+TASK_LOAD)

	parachute_reset(id)

	fmCheckHZ()
	fnCheckLastZombie()
}

/*================================================================================
[Rounds End/Start]
=================================================================================*/
public event_round_start()
{
	is_hf()
	lighting_effects()

	remove_task(TASK_NADES)
	remove_task(TASK_NUKBOMB)

	remove_entity_name(classname_powerbox)
	remove_entity_name(classname_forcefield)
	// Remove all mines and reset counts
	mine_cleanup_all()
	arrayset(g_mine_count, 0, 33)
	
	set_task(0.2, "remove_stuff")
		
	g_newround = true
	g_fix_delaymodel = true
	
	g_time = time()  // sync before calculating roundtime
	g_roundtime = g_time + floatround(get_pcvar_float(pcvar_roundtime) * 60.0) - 1
	remove_task(445751)
	set_task((get_pcvar_float(pcvar_roundtime)*60.0)-1.0, "task_round_end", 445751)

	g_endround = false
	g_survround = false
	g_nemround = false
	g_swarmround = false
	g_plagueround = false
	g_synapsisround = false
	g_sniperround = false
	g_assaround = false
	g_umbrellaround = false
	g_freezetime = true

	// Reset Illidan boss round state
	g_illidanround = false
	g_illidan_spawned = false
	g_illidan_phase = 0
	g_illidan_ability = 0
	g_illidan_boss = 0
	g_illidan_hpbar = 0
	g_illidan_blade[0] = 0; g_illidan_blade[1] = 0
	g_illidan_elem[0] = 0; g_illidan_elem[1] = 0
	g_illidan_elem_victim[0] = 0; g_illidan_elem_victim[1] = 0
	arrayset(g_illidan_damage, 0.0, 33)
	remove_task(TASK_ILLIDAN_TIMER)
	
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_limitteams", 0)

	// Keep at least 1 player on T team so CS doesn't immediately end the round
	// (Orpheu CheckWinConditions hook unavailable on this build)
	{
		static first_t_set
		first_t_set = 0
		for(new _id = 1; _id <= g_maxplayers && !first_t_set; _id++)
		{
			if(!g_is_connected[_id] || !g_login[_id]) continue
			if(fm_get_user_team(_id) == ZP_TEAM_CT)
			{
				fm_set_user_team(_id, ZP_TEAM_T)
				fm_user_team_update(_id)
				first_t_set = 1
			}
		}
	}

	static i, b
	b = 0
	for(i = 0; i <= g_maxplayers; i++)
	{
		g_has_unlimited_clip[i] = 0
		if(g_is_connected[i] && g_login[i])
			b++
	}

	if(b < MIN_PLAYERS)
		g_minplayers = true
	else
		g_minplayers = false

	#if defined USANDO_EN_LAN
	g_minplayers = false
	#endif

	remove_task(TASK_WELCOMEMSG)
	set_task(2.0, "welcome_msg", TASK_WELCOMEMSG)
	
	remove_task(TASK_MAKEZOMBIE)
	g_countdown = get_pcvar_num(cvar_countdown)+2
	set_task(1.0, "show_delay_time", TASK_MAKEZOMBIE, _, _, "b")
}

public show_delay_time(task)
{
	g_countdown--
	if(g_countdown < 1)
	{
		remove_task(task)
		set_task(1.0, "make_zombie_task", TASK_MAKEZOMBIE)
		client_cmd(0, "spk ^"fvox/alert^"")
	}
	else {
		static wtime[32]

		set_dhudmessage(255, 170, 0, -1.0, 0.3, 1, 1.0, 1.1, 0.1, 0.2)
		show_dhudmessage(0, ".::::::::::::::::::::::::.^n^n.::::::::::::::::::::::::.")

		set_dhudmessage(255, 127, 42, -1.0, 0.34, 1, 1.0, 1.1, 0.1, 0.2)
		show_dhudmessage(0, " Nuevo Modo en: %d ", g_countdown)
		
		
		if(g_countdown <= 5)
		{
			num_to_word(g_countdown, wtime, 31)
			client_cmd(0, "spk ^"fvox/%s^"", wtime)
		}
	}
}

public logevent_round_start()
{
	g_freezetime = false
	
	mp3_sound_play(0, random_num(8, 9))
}

public logevent_round_end(specialend)
{
	if(fix_roundend) return

	static Float:lastendtime
	if(get_gametime() - lastendtime < 0.5) return
	lastendtime = get_gametime()
	
	static id, team
	for (id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id]) continue
			
		mp3_sound_stop(id)
		g_special_respawn[id] = 0
		
		team = fm_get_user_team(id)
			
		if(team == ZP_TEAM_SPECTATOR || team == ZP_TEAM_UNASSIGNED) continue
			
		save_stats(id)
	}
	
	g_endround = true
	
	remove_task(TASK_WELCOMEMSG)
	remove_task(TASK_MAKEZOMBIE)
	
	set_task(0.1, "alltt_to_ct")
	
	if(specialend)
	{
		if(specialend==1)
		{
			for(new id = 1; id <= g_maxplayers; id++)
			{
				if(g_is_alive[id] && is_umbrella(id))
				{
					set_hudmessage(0, 255, 0, -1.0, 0.07, 2, 0.1, 4.0, 0.1, 0.1, -1)
					ShowSyncHudMsg(id, g_MsgSync3, "Mision fracasada...")
				}
			}

			set_hudmessage(200, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_MsgSync, "Los Zombies han matado al civil!")
			
			PlaySound(sound_win_zombies[random_num(0, charsmax(sound_win_zombies))])
			g_scorezombies++
			team_win=1
			
			ExecuteForward(g_fwRoundEnd, g_fwDummyResult, 1)
		}
		else if(specialend==2)
		{
			for(new id = 1; id <= g_maxplayers; id++)
			{
				if(g_is_alive[id] && is_umbrella(id))
				{
					set_hudmessage(0, 255, 0, -1.0, 0.07, 2, 0.1, 4.0, 0.1, 0.1, -1)
					ShowSyncHudMsg(id, g_MsgSync3, "Mision Completada!")
					strip_user_weapons(id)
					give_item(id, "weapon_knife")
				}
			}
			set_hudmessage(200, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_MsgSync, "Los Humanos protegieron al civil!")
			
			PlaySound(sound_win_humans[random_num(0, charsmax(sound_win_humans))])
			g_scorehumans++
			team_win=2
			
			ExecuteForward(g_fwRoundEnd, g_fwDummyResult, 2)
		}
		else if(specialend==3)
		{
			zp_center_print(0, "Comienza el juego!!!")
			team_win=3
			ExecuteForward(g_fwRoundEnd, g_fwDummyResult, 0);
		}
		return
		
	}
	
	if(!g_zombies)
	{
		team_win=2

		set_hudmessage(0, 0, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Los Humanos han vencido la plaga!")
		
		PlaySound(sound_win_humans[random_num(0, charsmax(sound_win_humans))])
		g_scorehumans++
		
		ExecuteForward(g_fwRoundEnd, g_fwDummyResult, 2);
	}
	else if(!g_humans)
	{
		team_win=1

		set_hudmessage(200, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Los Zombies han tomado el mundo!")
		
		PlaySound(sound_win_zombies[random_num(0, charsmax(sound_win_zombies))])
		g_scorezombies++
		
		ExecuteForward(g_fwRoundEnd, g_fwDummyResult, 1);
	}
	else
	{
		team_win=3

		set_hudmessage(0, 200, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Ultima opcion... BOMBA NUCLEAR")

		remove_task(TASK_NUKBOMB)
		client_cmd(0, "spk %s", sound_nuc_warning)
		set_task(0.4, "task_launch", TASK_NUKBOMB)
		set_task(2.2, "task_blast", TASK_NUKBOMB)

		ExecuteForward(g_fwRoundEnd, g_fwDummyResult, 0);
	}
}

public task_round_end()
{
	if(g_illidanround) return  // boss round has its own ending
	if(g_umbrellaround)
		set_round_end(2)
	else
		set_round_end(0)
}

set_round_end(specialend)
{
	if(g_endround) return
	
	logevent_round_end(specialend)
	
	fix_roundend=1
	
	// All Orpheu calls are inside the g_pGameRules guard to prevent crashes
	if(g_pGameRules)
	{
		static OrpheuFunction:ofEndRoundMsg
		static OrpheuFunction:ofUpdateTeamScores
		static OrpheuFunction:ofCheckWinConditions

		if(!ofEndRoundMsg)
			ofEndRoundMsg = OrpheuGetFunction("EndRoundMessage")
		if(!ofUpdateTeamScores)
			ofUpdateTeamScores = OrpheuGetFunction("UpdateTeamScores", "CHalfLifeMultiplay")
		if(!ofCheckWinConditions)
			ofCheckWinConditions = OrpheuGetFunction("CheckWinConditions", "CHalfLifeMultiplay")

		new iEvent, iWinStatus
		new szWinOffset[20], szWinMessage[16]
		new win = team_win, score
		switch(win)
		{
			case 1:
			{
				iEvent = 9; iWinStatus = 2
				copy(szWinOffset, charsmax(szWinOffset), "m_iNumTerroristWins")
				copy(szWinMessage, charsmax(szWinMessage), "#Terrorists_Win")
				score = g_scorezombies
			}
			default:
			{
				iEvent = 8; iWinStatus = 1
				copy(szWinOffset, charsmax(szWinOffset), "m_iNumCTWins")
				copy(szWinMessage, charsmax(szWinMessage), "#CTs_Win")
				score = g_scorehumans
			}
		}

		OrpheuCallSuper(ofUpdateTeamScores, g_pGameRules)
		OrpheuCallSuper(ofEndRoundMsg, szWinMessage, iEvent)
		OrpheuMemorySetAtAddress(g_pGameRules, "m_iRoundWinStatus", 1, iWinStatus)
		OrpheuMemorySetAtAddress(g_pGameRules, "m_fTeamCount", 1, get_gametime() + 8.0)
		OrpheuMemorySetAtAddress(g_pGameRules, "m_bRoundTerminating", 1, true)
		OrpheuMemorySetAtAddress(g_pGameRules, szWinOffset, 1, score)
		OrpheuCallSuper(ofCheckWinConditions, g_pGameRules)
	}
	else
	{
		// Orpheu unavailable � trigger restart via killing all players
		set_task(4.0, "ze_orpheu_restart_round")
	}

	fix_roundend=0
}

public ze_orpheu_restart_round()
{
    if(g_newround) return  // round already restarted naturally, don't kill anyone
    force_end_round(1)
}

/*================================================================================
[Message Hooks]
=================================================================================*/
public message_cur_weapon(msg_id, msg_dest, id)
{
	if(!g_is_alive[id] || get_msg_arg_int(1) != 1)
		return 0

	static weapon, clip

	weapon = get_msg_arg_int(2)
	if(!weapon) return 0
	
	clip = get_msg_arg_int(3)

	static weapon_ent
	weapon_ent = get_current_weapon_ent(id)
		
	if(((g_has_unlimited_clip[id] > g_time && weapon != CSW_SG550 && weapon != CSW_G3SG1) || is_survivor(id)) && MAXBPAMMO[weapon] > 2)
	{
		if(clip < 3) cs_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])

		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])
	}

	if(g_currentweapon[id] != weapon)
	{
		g_currentweapon[id] = weapon
		replace_models(id)
	}
	return 0
}

public message_ammo_x(msg_id, msg_dest, id)
{
	if(!g_is_alive[id])
		return PLUGIN_CONTINUE

	static type
	type = get_msg_arg_int(1)
	
	if(type == 12)
		return PLUGIN_HANDLED

	if(is_any_zombie(id))
		return PLUGIN_CONTINUE

	if(type >= sizeof AMMOWEAPON)
		return PLUGIN_CONTINUE
	
	static weapon
	weapon = AMMOWEAPON[type]
	
	if(MAXBPAMMO[weapon] <= 2)
		return PLUGIN_CONTINUE
	
	static amount
	amount = get_msg_arg_int(2)
	
	if(amount != MAXBPAMMO[weapon])
	{
		if(amount < MAXBPAMMO[weapon])
			cs_set_user_bpammo(id, weapon, MAXBPAMMO[weapon])

		set_msg_arg_int(2, get_msg_argtype(2), MAXBPAMMO[weapon])

		static w_ent 
		w_ent = get_current_weapon_ent(id)
			
		if(!is_valid_ent(w_ent))
			return PLUGIN_CONTINUE

		weapon = cs_get_weapon_id(w_ent)
		static wkey
		wkey = weapons_numid[weapon]
		if(wkey != -1 && g_wpn_mejoras_active[id] && g_weapons_mejoras[id][wkey][0] > 0)
			cs_set_weapon_ammo(w_ent, (MAXCLIP[weapon]+5)+floatround((g_weapons_mejoras[id][wkey][0]*3.4)))
	}

	return PLUGIN_CONTINUE
}

public message_money(msg_id, msg_dest, id)
{
	if(pev_valid(id) != PDATA_SAFE)
		return PLUGIN_HANDLED

	set_pdata_int(id, OFFSET_CSMONEY, 0, OFFSET_LINUX)
	return PLUGIN_HANDLED
}

public message_status_icon(msg_id, msg_dest, id)
{
	if(!get_msg_arg_int(1)) return PLUGIN_CONTINUE
	
	static msg[4]
	get_msg_arg_string(2, msg, 3)
    
	if(msg[0] == 'b' && msg[1] == 'u' && msg[2] == 'y') 
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1 << 0))
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public message_health(msg, dest, id)
{
	if(!g_is_alive[id]) return

	static health
	health = get_msg_arg_int(1)
	
	if(health < 256) return
	
	if(health % 256 == 0)
		set_user_health(id, (get_user_health(id)+1))

	set_msg_arg_int(1, get_msg_argtype(1), 255)
}

public message_flashbat(msg_id, msg_dest, id)
{
	if(is_any_zombie(id) || is_survivor(id) || is_sniper(id))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public message_weappickup(msg_id, msg_dest, id)
{
	if(is_any_zombie(id))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public message_ammopickup(msg_id, msg_dest, id)
{
	if(is_any_zombie(id))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public message_scenario()
{
	if(get_msg_args() > 1)
	{
		static sprite[8]
		get_msg_arg_string(2, sprite, charsmax(sprite))
		
		if(equal(sprite, "hostage"))
			return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public message_textmsg()
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))

	if(equal(textmsg, "#Game_will_restart_in"))
	{
		g_scorehumans = 0
		g_scorezombies = 0
		logevent_round_end(0)
		return PLUGIN_CONTINUE
	}
	
	if(equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") ||
	equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win") || equal(textmsg, "#Alias_Not_Avail"))
		return PLUGIN_HANDLED

	static args
	args = get_msg_args()
	
	if(args == 5 && get_msg_argtype(5) == ARG_STRING)
	{
		get_msg_arg_string(5, textmsg, charsmax(textmsg))
		if(equal(textmsg, "#Fire_in_the_hole"))
			return PLUGIN_HANDLED
	}
	else if(args == 6 && get_msg_argtype(6) == ARG_STRING)
	{
		get_msg_arg_string(6, textmsg, charsmax(textmsg))
		if(equal(textmsg ,"#Fire_in_the_hole"))
			return PLUGIN_HANDLED

	}
	
	return PLUGIN_CONTINUE
}

public message_sendaudio()
{
	static audio[22]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[1], "!MRAD_FIREINHOLE") || equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public message_teaminfo(msg_id, msg_dest)
{
	if(msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST) return

	static id
	id = get_msg_arg_int(1)
	
	if(!(1 <= id <= g_maxplayers)) return

	if(g_switchingteam) return
	
	set_task(0.3, "spec_nvision", id)
	
	static team[2]
	get_msg_arg_string(2, team, charsmax(team))
	switch(team[0])
	{
		case 'T':
		{
			remove_task(id+TASK_TEAM)
			fm_set_user_team(id, ZP_TEAM_CT)
			set_msg_arg_string(2, "CT")
		}
		case 'S','U': return
	}

	if(g_gamingcommencement && fnGetPlaying() >= 2)
	{
		g_gamingcommencement = false
		set_task(0.5, "task_gamingcommencement")
		return
	}
	
	if(g_newround) return
	
	if(!allowed_respawn(id)) return

	g_respawn_as_zombie[id] = true

	remove_task(id+TASK_SPAWN)
	set_task(3.0, "respawn_player", id+TASK_SPAWN)
}

public message_show_menu(msgid, dest, id)
{
	static menu_text_code[25]
	get_msg_arg_string(4, menu_text_code, charsmax(menu_text_code))

	if(equal(menu_text_code, "#Team_Select") || equal(menu_text_code, "#Team_Select_Spect")
	|| equal(menu_text_code, "#IG_Team_Select") || equal(menu_text_code, "#IG_Team_Select_Spect")
	|| equal(menu_text_code, "#CT_Select") || equal(menu_text_code, "#Terrorist_Select"))
	{
		if(clcmd_changeteam(id))
			return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public message_vgui_menu(msgid, dest, id)
{
	new vgui = get_msg_arg_int(1)
	if(vgui != 2 && vgui != 3 && vgui != 26 && vgui != 27)
		return PLUGIN_CONTINUE
	
	if(vgui == 2) clcmd_changeteam(id)
	
	return PLUGIN_HANDLED
}

/*================================================================================
[Custom Messages]
=================================================================================*/
// Custom Night Vision
effec_nvg(id)
{
	if(!g_nvision[id] || !g_nvisionenabled[id])
	{
		del_nvg(id)
		return
	}

	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(67) // radius
	if(is_nemesis(id) || is_assassin(id) || (is_zombie(id) && g_nodamage[id]))
	{
		write_byte(255) // r
		write_byte(0) // g
		write_byte(0) // b
	}
	else
	{
		write_byte(COLOR_VALUES[g_nvg_color[id]][0]) // r
		write_byte(COLOR_VALUES[g_nvg_color[id]][1]) // g
		write_byte(COLOR_VALUES[g_nvg_color[id]][2]) // b
	}  	
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

effec_aura(id)
{
	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	if(is_any_zombie(id))
	{
		if(is_assassin(id))
			write_byte(7) // radius
		else
			write_byte(16) // radius
		write_byte(250)
		write_byte(10)
		write_byte(10)
	}
	else {
		write_byte(18) // radius
		write_byte(200) // r
		write_byte(200) // g
		write_byte(200) // b
	}
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}


infectionFX(id)
{
	// Screen fade
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND*1) // duration
	write_short(UNIT_SECOND*0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte((is_nemesis(id)) ? 255 : COLOR_VALUES[g_nvg_color[id]][0]) // r
	write_byte((is_nemesis(id)) ? 0 : COLOR_VALUES[g_nvg_color[id]][1]) // g
	write_byte((is_nemesis(id)) ? 0 : COLOR_VALUES[g_nvg_color[id]][2]) // b
	write_byte (255) // alpha
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short(UNIT_SECOND*75) // amplitude
	write_short(UNIT_SECOND*5) // duration
	write_short(UNIT_SECOND*75) // frequency
	message_end()

	// Get player origin
	static origin[3]
	get_user_origin(id, origin)
		
	// Tracers
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_IMPLOSION) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(128) // radius
	write_byte(25) // count
	write_byte(3) // duration
	message_end()
	
	// Particle Burst
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_PARTICLEBURST) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_short(55) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()
}

public make_blood(id)
{
	id -= TASK_BLOOD

	if(!(get_entity_flags(id) & FL_ONGROUND) || get_speed(id) < 110)
		return
	
	static Float:originF[3]
	entity_get_vector(id, EV_VEC_origin, originF)
	
	if(entity_get_int(id, EV_INT_bInDuck))
		originF[2] -= 18.0
	else
		originF[2] -= 36.0
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_WORLDDECAL) // TE id
	write_coord_f(originF[0]) // x
	write_coord_f(originF[1]) // y
	write_coord_f(originF[2]) // z
	write_byte(zombie_decals[random_num(0, sizeof zombie_decals - 1)]) // random decal number (offsets +12 for CZ)
	message_end()
}

flare_lighting(entity, duration)
{
	static Float:originF[3], color
	entity_get_vector(entity, EV_VEC_origin, originF)

	color = entity_get_int(entity, FLARE_COLOR)

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT)
	write_coord_f(originF[0])
	write_coord_f(originF[1])
	write_coord_f(originF[2])
	if(g_assaround)
		write_byte(get_pcvar_num(cvar_flaresize2))
	else 
		write_byte(get_pcvar_num(cvar_flaresize))
	write_byte(COLOR_VALUES[color][0]) // r
	write_byte(COLOR_VALUES[color][1]) // g
	write_byte(COLOR_VALUES[color][2]) // b
	write_byte(51) //life
	write_byte((duration < 2) ? 3 : 0) //decay rate
	message_end()	

	// Sparks
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPARKS) // TE id
	write_coord_f(originF[0]) // x
	write_coord_f(originF[1]) // y
	write_coord_f(originF[2]) // z
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPARKS) // TE id
	write_coord_f(originF[0]) // x
	write_coord_f(originF[1]) // y
	write_coord_f(originF[2]+1.0) // z
	message_end()
}

public burning_flame(id)
{
	id -= TASK_BURN

	if(!g_is_alive[id])
	{
		remove_status_icon("dmg_heat", id)
		remove_task(id+TASK_BURN)
		return
	}
	
	static origin[3], flags
	get_user_origin(id, origin)
	flags = get_entity_flags(id)
	
	// Madness mode - in water - burning stopped
	if(g_nodamage[id] || (flags & FL_INWATER) || g_burning_duration[id] < 1)
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-50) 
		write_short(g_smokeSpr)
		write_byte(random_num(15, 20))
		write_byte(random_num(10, 20))
		message_end()
		
		remove_status_icon("dmg_heat", id)
		remove_task(id+TASK_BURN)
		player_maxspeed(id)
		return
	}

	
	// Randomly play burning zombie scream sounds (not for nemesis)
	if(is_zombie(id) && !random_num(0, 20))
		emit_sound(id, CHAN_VOICE, grenade_fire_player[random_num(0, sizeof grenade_fire_player - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get fire slow down setting
	static Float:slowdown
	slowdown = get_pcvar_float(cvar_fireslowdown)
	
	// Fire slow down, unless nemesis
	if(slowdown > 0.0 && is_zombie(id) && (flags & FL_ONGROUND))
	{
		static Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		xs_vec_mul_scalar(velocity, slowdown, velocity)
		entity_set_vector(id, EV_VEC_velocity, velocity)
	}
	
	// Get health and fire damage setting
	static health, firedamage
	health = get_user_health(id)
	firedamage = get_pcvar_num(cvar_firedamage)

	if(health > firedamage)
		set_user_health(id, (health - firedamage))

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	
	// Decrease burning duration counter
	g_burning_duration[id]--
}

show_ring(ent, Float:origin[3])
{
	static grenade
	grenade = get_nadetype(ent)-1
	origin[2] += 10.0
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER)
	write_coord_f(origin[0])
	write_coord_f(origin[1])
	write_coord_f(origin[2]+10.0)
	write_coord_f(origin[0])
	write_coord_f(origin[1])
	write_coord_f(origin[2]+90.0)
	write_short(g_exploSpr)
	write_byte(0)
	write_byte(0)
	write_byte(7)
	write_byte(40)
	write_byte(0)
	write_byte(rig_rgb[grenade][0])
	write_byte(rig_rgb[grenade][1])
	write_byte(rig_rgb[grenade][2])
	write_byte(120)
	write_byte(0)
	message_end()
}

create_blast(const Float:originF[3], tipo)
{
	static r, g, b, r2, g2, b2, r3, g3, b3
	switch(tipo){
		case 0: {
			r = 0; g = 200; b = 0
			r2 = 0; g2 = 200; b2 = 0
			r3 = 0; g3 = 200; b3 = 0
		}
		case 1: {
			r = 200; g = 100; b = 0
			r2 = 200; g2 = 50; b2 = 0
			r3 = 200; g3 = 0; b3 = 0
		}
		case 2: {
			r = 0; g = 0; b = 200
			r2 = 0; g2 = 0; b2 = 200
			r3 = 0;	g3 = 0; b3 = 200
		}
		case 3: {
			r = 85; g = 170; b = 255
			r2 = 85; g2 = 170; b2 = 255
			r3 = 85; g3 = 170; b3 = 255
		}
		case 4: {
			r = 42; g = 170; b = 255
			r2 = 42; g2 = 170; b2 = 255
			r3 = 42; g3 = 170; b3 = 255
		}
	}
	
	if(tipo == 2)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SPRITETRAIL)
		write_coord_f(originF[0])
		write_coord_f(originF[1])
		write_coord_f(originF[2])
		write_coord_f(originF[0])
		write_coord_f(originF[1])
		write_coord_f(originF[2])
		write_short(g_glowSpr)
		write_byte(85)
		write_byte(1)
		write_byte(2)
		write_byte(50)
		write_byte(55) 
		message_end()
	}

	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	write_coord_f(originF[0]) // x
	write_coord_f(originF[1]) // y
	write_coord_f(originF[2]) // z
	write_coord_f(originF[0]) // x axis
	write_coord_f(originF[1]) // y axis
	write_coord_f(originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(r) // red
	write_byte(g) // green
	write_byte(b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	write_coord_f(originF[0]) // x
	write_coord_f(originF[1]) // y
	write_coord_f(originF[2]) // z
	write_coord_f(originF[0]) // x axis
	write_coord_f(originF[1]) // y axis
	write_coord_f(originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(r2) // red
	write_byte(g2) // green
	write_byte(b2) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	write_coord_f(originF[0]) // x
	write_coord_f(originF[1]) // y
	write_coord_f(originF[2]) // z
	write_coord_f(originF[0]) // x axis
	write_coord_f(originF[1]) // y axis
	write_coord_f(originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(r3) // red
	write_byte(g3) // green
	write_byte(b3) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

create_trail(ent, r, g, b)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(ent) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(r) // r
	write_byte(g) // g
	write_byte(b) // b
	write_byte(200) // brightness
	message_end()
}

FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}

SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("infection") // killer's weapon
	message_end()
}

UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	frags = (get_user_frags(attacker) + frags)

	set_user_frags(attacker, frags)
	if(!is_user_valid_alive(victim) || pev_valid(victim) != PDATA_SAFE) return
		
	fm_set_user_deaths(victim, cs_get_user_deaths(victim) + deaths)

	if(scoreboard)
	{
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(attacker) // id
		write_short(frags) // frags
		write_short(cs_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(fm_get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(victim) // id
		write_short(get_user_frags(victim)) // frags
		write_short(cs_get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(fm_get_user_team(victim)) // team
		message_end()
	}
}

update_status(id)
{
	if(!g_is_alive[id])
	{
		send_msg_status(id, "", 1)
		return
	}

	static target, ent, body, text[64]
	text[0] = '^0';target = 1;
	get_user_aiming(id, ent, body)

	if(!is_valid_ent(ent))
	{
		send_msg_status(id, "", 1)
		return
	}

	static health;health = floatround(entity_get_float(ent, EV_FL_health))
	if(is_user_valid_alive(ent))
	{
		if((is_any_zombie(id) && !is_any_zombie(ent)) || (!is_any_zombie(id) && is_any_zombie(ent)))
			formatex(text, 63, "%s - level[%d]", "%p1", g_level[ent])
		else
			formatex(text, 63, "%s - vida[%d] - level[%d]", "%p1", health, g_level[ent])

		send_msg_status(id, text, ent)
		return
	}
	
	if(is_any_zombie(id))
	{
		send_msg_status(id, "", 1)
		return
	}
	
	if(entity_get_int(ent, EV_INT_iuser2) == 123)
	{
		target = entity_get_int(ent, EV_INT_iuser3)
		if(target == id)
			formatex(text, 63, "%s,es tu lasermine - vida[%d]", "%p1", health)
		else
			formatex(text, 63, "lasermine de %s - vida[%d]", "%p1", health)
	}
	else if(entity_get_int(ent, EV_ENT_euser4) == 1111)
	{
		target = entity_get_edict(ent, EV_ENT_euser2)
		if(target == id)
			formatex(text, 63, "%s,es tu sentry - vida[%d]", "%p1", health)
		else
			formatex(text, 63, "sentry gun de %s - vida[%d]", "%p1", health)
	}

	send_msg_status(id, text, target)
}

send_msg_status(id, text[], target)
{
	message_begin(MSG_ONE_UNRELIABLE, g_StatusText, _, id)
	write_byte(0)
	write_string(text)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_StatusValue, _, id)
	write_byte(1)
	write_short(target)
	message_end()
}

stock zp_colored_print(const id, const input[], any:...)
{
	new count = 1, players[32], i
	static msg[191]

	if(numargs() == 2)
		copy(msg, 190, input)
	else
		vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!t", "^3") // Team Color
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for(i = 0; i < count; i++)
		{
			if (g_is_connected[players[i]])
			{
				message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end();
			}
		}
	}
}

stock zp_center_print(const id, const input[], any:...)
{
	static msg[191]
	new direc, i

	if(numargs() == 2)
		direc = 1
	else
		vformat(msg, 190, input, 3)

	if(g_is_connected[id])
	{
		engfunc(EngFunc_ClientPrintf, id, 1, direc?input:msg)
		return
	}
	for(i=1; i <= g_maxplayers; i++)
		if(g_is_connected[i])
			engfunc(EngFunc_ClientPrintf, i, 1, direc?input:msg)
}

send_status_icon(id, Float:removetime, icon[], r=200, g=200, b=200, flash=0)
{
	message_begin(MSG_ONE_UNRELIABLE, g_IconStatus, _, id)
	write_byte(1+flash)
	write_string(icon)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	message_end()
	
	if(removetime > 0.1) set_task(removetime, "remove_status_icon", id+TASK_ICON, icon, strlen(icon))
}

public remove_status_icon(icon[], id)
{
	if(id > TASK_ICON) id-=TASK_ICON

	if(!g_is_connected[id]) return
	
	message_begin(MSG_ONE_UNRELIABLE, g_IconStatus, _, id)
	write_byte(0)
	write_string(icon)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	message_end()
}

draw_weapon_icon(id)
{
	if(g_currentweapon[id] == CSW_HEGRENADE || !WEAPON_ICONS[g_currentweapon[id]][0])
		return

	copy(g_weapon_icon[id], charsmax(g_weapon_icon), WEAPON_ICONS[g_currentweapon[id]])

	message_begin(MSG_ONE_UNRELIABLE, g_IconStatus, _, id)
	write_byte(1)
	write_string(g_weapon_icon[id])
	write_byte(0)
	write_byte(213)
	write_byte(255)
	message_end()
}

remove_weapon_icon(id) 
{
	if(!g_weapon_icon[id][0] || !g_is_connected[id])
		return

	message_begin(MSG_ONE_UNRELIABLE, g_IconStatus, _, id)
	write_byte(0)
	write_string(g_weapon_icon[id])
	message_end()
	
	g_weapon_icon[id][0] = '^0'
}

/*================================================================================
[Other Functions and Tasks]
=================================================================================*/
public task_onesecon()
{
	if(g_sql_stop) return

	static secons
	if(secons++ >= 5)
	{
		lighting_effects()
		secons = 0
	}

	other_tasks()
	
	static id
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id]) continue
		
		update_status(id)
		
		if(g_login[id] && g_valid_email[id])
			ze_showhud(id)

		// Show mine HP when crosshair is on a mine
		if(g_is_alive[id])
		{
			static aim_ent, aim_body
			get_user_aiming(id, aim_ent, aim_body)
			if(aim_ent > 0 && pev_valid(aim_ent))
			{
				static szAimClass[32]
				pev(aim_ent, pev_classname, szAimClass, charsmax(szAimClass))
				if(equal(szAimClass, classname_mine))
				{
					static Float:aim_hp
					pev(aim_ent, pev_fuser1, aim_hp)
					set_hudmessage(0, 230, 0, -1.0, 0.12, 0, 0.0, 1.2, 0.0, 0.0, -1)
					ShowSyncHudMsg(id, g_MsgSync4, "Mina HP: %.0f/%.0f", aim_hp, MINE_HP)
				}
			}
		}

	}
	
	set_dhudmessage(10, 10, 255, 0.2, 0.0, 0, 6.0, 0.8, 0.1, 0.8)
	show_dhudmessage(0, "Humanos vivos:%d", g_humans)
	
	set_dhudmessage(255, 10, 10, 0.43, 0.0, 0, 6.0, 0.8, 0.1, 0.8)
	show_dhudmessage(0, "Zombies vivos:%d", g_zombies)
	
	g_time = time()
}

public task_aura(ent)
{
	if(g_user_nvg || g_user_aura)
	{
		static id
		for(id = 1; id <= 32; id++)
		{
			if(!g_is_connected[id])
				continue
				
			if(get_aura(id))
				effec_aura(id)
			if(get_nvg(id))
				effec_nvg(id)
		}
	}
}

other_tasks()
{
	if(g_minplayers)
		zp_center_print(0, "Hay menos de %d players ^n ganancia de ap y puntos deshabilitada", MIN_PLAYERS)

	static autosave_time
	if((autosave_time++ >= 300))
	{
		autosave_time = 0
		static i
		for(i = 0; i <= g_maxplayers; i++)
			if(g_is_connected[i] && g_login[i])
				SaveCuenta(i, 0)
	}

	static sound_time
	if(sound_time++ > 60 && g_humans < 5 && g_zombies < 15 && !g_newround && !g_endround)
	{
		mp3_sound_play(0, random_num(0, 7))
		sound_time = 0
	}
}

ze_showhud(id)
{
	static id_org
	id_org = id

	if(!g_is_alive[id])
	{
		id = entity_get_int(id, SPEC_TARGET)
		
		if(!g_is_alive[id]) return
	}
	
	static class[32]
	
	if(is_any_zombie(id))
	{
		if(is_nemesis(id))
			formatex(class, 31, "Nemesis")
		else if(is_assassin(id))
			formatex(class, 31, "Assassin")
		else
			copy(class, 31, g_zclass[g_zombieclass[id]][ZCLASS_NAME])
		
	}
	else {
		if(is_survivor(id))
			formatex(class, 31, "Survivor")
		else if(is_sniper(id))
			formatex(class, 31, "Sniper")
		else if(is_civil(id))
			formatex(class, 31, "UmbrellaMod:Civil")
		else if(is_umbrella(id))
			formatex(class, 31, "UmbrellaMod:Soldado")
		else
			copy(class, 31, g_hclass[g_humanclass[id]][HCLASS_NAME])
	}
	
	static len, info[512]
	
	len = formatex(info, charsmax(info), "[PJ: %s]^n^n" , g_name[id_org])
	
	if(id != id_org) len += formatex(info[len], charsmax(info), "[Specteando a: %s]^n" , g_name[id])

	len += formatex(info[len], charsmax(info) - len, "[Vida: %d]^n" , get_user_health(id))
	len += formatex(info[len], charsmax(info) - len, "[Chaleco: %d]^n" , get_user_armor(id))
	len += formatex(info[len], charsmax(info) - len, "[AP: %d]^n" , g_ammopacks[id])
	len += formatex(info[len], charsmax(info) - len, "[Level: %d]^n" , g_level[id])
	len += formatex(info[len], charsmax(info) - len, "[Reset: %d]^n" , g_reset_level[id])
	len += formatex(info[len], charsmax(info) - len, "[Clase: %s]^n" , class)
	
	set_hudmessage(COLOR_VALUES[hud_color[id_org][0]][0] , COLOR_VALUES[hud_color[id_org][0]][1], COLOR_VALUES[hud_color[id_org][0]][2], hud_posicion[id_org][0][0], hud_posicion[id_org][0][1], 0, 6.0, 1.2, 0.0, 0.0, -1)
	ShowSyncHudMsg(id_org, g_MsgSync2, "%s", info)

	if(id != id_org) return

	//if(g_show_info_mision[id]){
	set_hudmessage(COLOR_VALUES[hud_color[id][1]][0], COLOR_VALUES[hud_color[id][1]][1], COLOR_VALUES[hud_color[id][1]][2], hud_posicion[id][1][0], hud_posicion[id][1][1], 0, 6.0, 1.2)
	if(is_any_zombie(id))
	{
		ShowSyncHudMsg(id, g_MsgSync5, "Mision:^nH-Inf: %d/%d ^nH-Kill: %d/%d ^nSurv-Kill: %d/%d ^nSnip-Kill: %d/%d", g_mission_progress[id][KILL_INFECT], mission_kills(id, KILL_INFECT), g_mission_progress[id][KILL_HUMAN],
		mission_kills(id, KILL_HUMAN), g_mission_progress[id][KILL_SURVIVOR], mission_kills(id, KILL_SURVIVOR), g_mission_progress[id][KILL_SNIPER], mission_kills(id, KILL_SNIPER))
	}
	else
		ShowSyncHudMsg(id, g_MsgSync5, "Mision:^nZ-Kill: %d/%d ^nNeme-Kill: %d/%d ^nAssa-Kill: %d/%d", g_mission_progress[id][KILL_ZOMBIE], mission_kills(id, KILL_ZOMBIE), g_mission_progress[id][KILL_NEMESIS], mission_kills(id, KILL_NEMESIS),
		g_mission_progress[id][KILL_ASSASSIN], mission_kills(id, KILL_ASSASSIN))
	//}
}

public alltt_to_ct()
{
	new team
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(!is_user_valid_connected(id))
			continue
		
		team = fm_get_user_team(id)
		
		if(team == ZP_TEAM_SPECTATOR || team == ZP_TEAM_UNASSIGNED)
			continue
		
		remove_task(id+TASK_TEAM)
		fm_set_user_team(id, ZP_TEAM_CT)
	}
}

public welcome_msg()
{
	show_msgtutor(0, 3.5, 8, "[Z-Evil]Bienvenidos a Only-Arg^n Disfruta de nuestro Zombie-Evil %s.", PLUGIN_VERSION)
	zp_colored_print(0, "^4[Z-Evil]^3 Bienvenidos a^4 Only-Arg,^3 disfruta de nuestro^3 Zombie-Evil %s.", PLUGIN_VERSION)
	
	set_hudmessage(0, 125, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "El Virus T-VERONICA se ha liberado...")
}

public task_gamingcommencement()
{
	set_round_end(3)
}

public respawn_player(id)
{
	id -= TASK_SPAWN 
	static team
	team = fm_get_user_team(id)
	
	if(!g_endround && !g_survround && !g_swarmround && !g_nemround && !g_plagueround && team != ZP_TEAM_SPECTATOR && team != ZP_TEAM_UNASSIGNED && !g_is_alive[id])
	{
		if(g_respawn_as_zombie[id])
			fm_set_user_team(id, ZP_TEAM_T)
		else
			fm_set_user_team(id, ZP_TEAM_CT)
		
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}

check_round(leaving_player)
{
	static iPlayersnum
	iPlayersnum = fnGetPlaying()
	
	if(iPlayersnum < 2)
	{
		g_gamingcommencement = true
		return
	}
	
	if(g_endround || task_exists(TASK_MAKEZOMBIE)) return

	if(!g_is_alive[leaving_player]) return

	static id
	while((id = g_players[random_num(0, iPlayersnum-1)]) == leaving_player ) {}
	
	if((is_zombie(leaving_player) || g_infected[leaving_player]) && g_zombies == 1)
	{
		zp_colored_print(0, "^4[Z-Evil]^1 El ultimo Zombie se ha ido, %s es el nuevo Zombie.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = CLASS_ZOMBIE
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			zombieme(id, CLASS_ZOMBIE)
	}
	else if(is_assassin(leaving_player))
	{
		zp_colored_print(0, "^4[Z-Evil]^1 Se ha ido un Assassin, %s es el nuevo Assassin.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = CLASS_ASSASSIN
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			zombieme(id, CLASS_ASSASSIN)
	}
	else if(is_nemesis(leaving_player))
	{
		zp_colored_print(0, "^4[Z-Evil]^1 Se ha ido un Nemesis, %s es el nuevo Nemesis.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = CLASS_NEMESIS
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			zombieme(id, CLASS_NEMESIS)
	}
	else if(is_human(leaving_player) && g_humans == 1)
	{
		zp_colored_print(0, "^4[Z-Evil]^1 El ultimo Humano se ha ido, %s es el nuevo Humano.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = 20+CLASS_HUMAN
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			humanme(id, CLASS_HUMAN)
	}
	else if(is_sniper(leaving_player))
	{
		zp_colored_print(0, "^4[Z-Evil]^1 Se ha ido un Sniper, %s es el nuevo Sniper.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = 20+CLASS_SNIPER
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			humanme(id, CLASS_SNIPER)
	}
	else if(is_survivor(leaving_player))
	{
		zp_colored_print(0, "^4[Z-Evil]^1 Se ha ido un Survivor, %s es el nuevo Survivor.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = 20+CLASS_SURVIVOR
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			humanme(id, CLASS_SURVIVOR)
	}
	else if(is_civil(leaving_player))
	{
		zp_colored_print(0, "^4[Z-Evil]^1 El Civil se ha ido, %s es el nuevo Civil.", g_name[id])
		
		if(!g_is_alive[id])
		{
			g_special_respawn[id] = 20+CLASS_CIVIL
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		else
			humanme(id, CLASS_CIVIL)
	}
}

public lighting_effects()
{
	static lights[2]
	get_pcvar_string(cvar_lighting, lights, charsmax(lights))
	strtolower(lights)
	
	if(lights[0] == '0') return

	if(lights[0] >= 'a' && lights[0] <= 'd' || g_assaround)
	{
		static Float:thunderclap
		thunderclap = get_pcvar_float(cvar_thunder)
		
		if (thunderclap > 0.0 && !task_exists(TASK_THUNDER_PRE) && !task_exists(TASK_THUNDER))
		{
			g_lights_i = 0
			switch (random_num(0, 2))
			{
				case 0: set_task(thunderclap, "thunderclap1", TASK_THUNDER_PRE)
				case 1: set_task(thunderclap, "thunderclap2", TASK_THUNDER_PRE)
				case 2: set_task(thunderclap, "thunderclap3", TASK_THUNDER_PRE)
			}
		}
		
		if(!task_exists(TASK_THUNDER)) set_lights(g_assaround ? "a" : lights)
	}
	else
	{
		remove_task(TASK_THUNDER_PRE)
		remove_task(TASK_THUNDER)
		
		set_lights(lights)
	}
}

public thunderclap1()
{
	if(!g_lights_i) PlaySound(sound_thunder[random_num(0, charsmax(sound_thunder))])
	
	set_lights(lights_thunder1[g_lights_i])
	g_lights_i++
	
	if(g_lights_i >= sizeof lights_thunder1)
	{
		remove_task(TASK_THUNDER)
		lighting_effects()
	}
	else if (!task_exists(TASK_THUNDER))
		set_task(0.1, "thunderclap1", TASK_THUNDER, _, _, "b")
}

public thunderclap2()
{
	if (!g_lights_i) PlaySound(sound_thunder[random_num(0, charsmax(sound_thunder))])
	
	set_lights(lights_thunder2[g_lights_i])
	g_lights_i++
	
	if(g_lights_i >= sizeof lights_thunder2)
	{
		remove_task(TASK_THUNDER)
		lighting_effects()
	}
	else if(!task_exists(TASK_THUNDER))
		set_task(0.1, "thunderclap2", TASK_THUNDER, _, _, "b")
}

public thunderclap3()
{
	if(!g_lights_i) PlaySound(sound_thunder[random_num(0, charsmax(sound_thunder))])
	
	set_lights(lights_thunder3[g_lights_i])
	g_lights_i++
	
	if(g_lights_i >= sizeof lights_thunder3)
	{
		remove_task(TASK_THUNDER)
		lighting_effects()
	}
	else if (!task_exists(TASK_THUNDER))
		set_task(0.1, "thunderclap3", TASK_THUNDER, _, _, "b")
}

set_protection(id, Float:_time)
{
	if(!g_is_alive[id]) return

	set_user_rendering(id, kRenderFxGlowShell, 20, 20, 255, kRenderNormal, 20)
	g_nodamage[id] = true
	set_task(_time, "remove_protection", id+TASK_SPAWN)
}

public remove_protection(id)
{
	id -= TASK_SPAWN
	if(!g_is_alive[id]) return
	
	g_nodamage[id] = false
	set_user_rendering(id)
}

reset_hud(id)
{
	remove_task(id+4512)
	set_task(0.1, "task_reset_hud", id+4512)
}

public task_reset_hud(id)
{
	id -= 4512
	if(!g_is_connected[id]) return
	
	remove_task(id+TASK_ICON)
	
	message_begin(MSG_ONE, get_user_msgid("ResetHUD"), _, id)  
	message_end()
	
	message_begin(MSG_ONE,  g_msgHideWeapon, _, id)
	write_byte((is_any_zombie(id) && g_currentweapon[id] == CSW_KNIFE)?HIDE_HUD|(1<<6):HIDE_HUD)
	message_end()
	
	message_begin(MSG_ONE, g_msgCrosshair, _, id)
	write_byte(0)
	message_end()
	
	message_begin(MSG_ONE, g_msgRoundTime, _, id)
	write_short(max(g_roundtime-g_time,0))
	message_end()
}

turn_off_flashlight(id)
{
	if(pev(id, pev_effects) & EF_DIMLIGHT)
	{
		set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_DIMLIGHT)

		message_begin(MSG_ONE, g_msgFlashlight, _, id)
		write_byte(0)
		write_byte(100)
		message_end()
	}

	entity_set_int(id, EV_INT_impulse, 0)
}

infection_explode(ent)
{
	if(g_endround) return
	
	new attacker = entity_get_edict(ent, EV_ENT_owner)

	if(!is_user_valid_connected(attacker))
	{
		remove_entity(ent)
		return
	}

	static Float:originF[3]
	entity_get_vector(ent, EV_VEC_origin, originF)

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord_f(originF[0]); // origin x
	write_coord_f(originF[1]); // origin y
	write_coord_f(originF[2]); // origin z
	write_short(g_exploSpr2); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(18); // framerate
	write_byte(14); // flags 
	message_end(); // message end

	emit_sound(ent, CHAN_WEAPON, grenade_infect[random_num(0, charsmax(grenade_infect))], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static victim
	victim = -1
	
	while(0 < (victim = find_ent_in_sphere(victim, originF, 180.0)) <= g_maxplayers)
	{
		if(!is_user_valid_alive(victim) || is_any_zombie(victim) || g_infected[victim] || g_nodamage[victim])
			continue;
		
		emit_sound(victim, CHAN_VOICE, grenade_infect_player[random_num(0, charsmax(grenade_infect_player))], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		SendDeathMsg(attacker, victim)
		FixDeadAttrib(victim)
		UpdateFrags(attacker, victim, 1, 1, 1)		
		
		zombieme(victim, CLASS_ZOMBIE, attacker, 1)
		g_ammopacks[attacker] += 2
		check_player_level(attacker)
		set_user_health(attacker, (get_user_health(attacker)+250))
	}

	remove_entity(ent)
}

fire_explode(ent)
{
	static Float:originF[3]
	entity_get_vector(ent, EV_VEC_origin, originF)
	
	create_blast(originF, 1)
	
	emit_sound(ent, CHAN_WEAPON, grenade_fire[random_num(0, charsmax(grenade_fire))], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static victim
	victim = -1
	
	while(0 < (victim = find_ent_in_sphere(victim, originF, NADE_EXPLOSION_RADIUS)) <= g_maxplayers)
	{
		if(!is_user_valid_alive(victim) || !is_any_zombie(victim) || g_nodamage[victim]) continue
		
		send_status_icon(victim, 0.0, "dmg_heat", 250, 200, 0, 1)

		if(is_zombie(victim))
			g_burning_duration[victim] += get_pcvar_num(cvar_fireduration)*5
		else
			g_burning_duration[victim] += get_pcvar_num(cvar_fireduration)
		
		if(!task_exists(victim+TASK_BURN))
			set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")
	}
	remove_entity(ent)
}

bubble_explode(bomb)
{
	static Float:originF[3]
	entity_get_vector(bomb, EV_VEC_origin, originF)

	create_blast(originF, 3)

	new ent = create_entity("info_target")

	if(!is_valid_ent(ent))
	{
		remove_entity(bomb)
		return
	}

	entity_set_string(ent, EV_SZ_classname, classname_forcefield)

	entity_set_vector(ent, EV_VEC_origin, originF)
	entity_set_model(ent, model_forcefield)
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
	entity_set_size(ent, Float: {-110.0, -110.0, -110.0}, Float: {110.0, 110.0, 110.0})

	set_rendering(ent, kRenderFxGlowShell, 85, 170, 255, kRenderTransAlpha, 55)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT)
	write_coord_f(originF[0])
	write_coord_f(originF[1])
	write_coord_f(originF[2])
	write_byte(25)
	write_byte(127)
	write_byte(255)
	write_byte(85)
	write_byte(6)
	write_byte(0)
	message_end()

	entity_set_float(bomb, EV_FL_nextthink, get_gametime()+60.0)
	entity_set_int(bomb, EV_INT_iuser4, ent)
}

antidote_explode(ent)
{
	new attacker = entity_get_edict(ent, EV_ENT_owner)
	
	if(!is_user_valid_connected(attacker))
	{
		remove_entity(ent)
		return
	}

	static Float:originF[3]
	entity_get_vector(ent, EV_VEC_origin, originF)
	
	create_blast(originF, 0)

	static victim
	victim = -1
	while(0 < (victim = find_ent_in_sphere(victim, originF, NADE_EXPLOSION_RADIUS)) <= g_maxplayers)
	{
		if(!is_user_valid_alive(victim) || !is_zombie(victim) || g_firstzombie[victim]) continue
		
		SendDeathMsg(attacker, victim)
		FixDeadAttrib(victim)
		UpdateFrags(attacker, victim, 1, 1, 1)
		humanme(victim, CLASS_HUMAN)
		g_ammopacks[attacker] += 2
		set_user_health(attacker, (get_user_health(attacker)+50))
	}
	remove_entity(ent)
}

he_explode(ent)
{
	new attacker = entity_get_edict(ent, EV_ENT_owner)

	if(!is_user_valid_connected(attacker))
	{
		remove_entity(ent)
		return
	}

	static Float:originF[3]
	entity_get_vector(ent, EV_VEC_origin, originF)
	
	new victim = -1
	
	new Float:dist, Float:damage_max, Float:damaget, hp
	while(0 < (victim = find_ent_in_sphere(victim, originF, 255.0)) <= g_maxplayers)
	{
		if(!is_user_valid_alive(victim) || !is_zombie(victim) || g_nodamage[victim]) continue
		
		dist = entity_range(ent, victim)

		if(dist > 255.0) continue

		if(is_assassin(victim)) damage_max = 200.0
		else damage_max = 800.0

		damaget = -(((damage_max * dist) / 255.0) - damage_max)
		hp = get_user_health(victim)

		if(hp > damaget)
			ExecuteHamB(Ham_TakeDamage, victim, ent, ent, damaget, DMG_BLAST)
		else
			log_kill(attacker, victim)
	}

	new inwater = point_contents(originF) == CONTENTS_WATER
	
	emit_sound(ent, CHAN_VOICE, sound_he_exp, VOL_NORM, 0.3, 0, inwater?150:PITCH_NORM)
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION)
	write_coord_f(originF[0])
	write_coord_f(originF[1])
	write_coord_f(originF[2])
	write_short(g_exploSpr3)
	write_byte(inwater?30:40) // escale
	write_byte(10) // flame rate
	if(inwater) write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	else write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	if(!inwater)
	{
		new Float:end_post[3];end_post = originF;end_post[2] += -32.0
		trace_line(ent, originF, end_post, end_post)

		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, end_post, 0)
		write_byte(TE_WORLDDECAL) // TE id
		write_coord_f(end_post[0])
		write_coord_f(end_post[1])
		write_coord_f(end_post[2])
		write_byte(random_num(46, 48)) // texture index of precached decal texture name
		message_end() 
	
		new iOrigin[3]
		FVecIVec(originF, iOrigin)
		set_task(0.7, "humo", 1611, iOrigin, 3)
		//set_task(1.1, "particulas", 1612, iOrigin, 3)
	
		new r=random_num(0,3)
		if(r) {
			new Float:plane[3]
			traceresult(TR_PlaneNormal, plane)
			for(new i; i<=r; i++)
				create_spark(originF, plane)
		}
		remove_entity(ent)
	}
	else {
		entity_set_model(ent, "")
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE)
		entity_set_vector(ent, EV_VEC_velocity, Float:{0.0,0.0,0.0})
		entity_set_float(ent, EV_FL_nextthink, get_gametime()+9.0)
		set_task(0.7, "bubbles", ent)
	}
}

public molotov_explode(ent)
{
	static Float:origin[3], Float:originF[3],  Float:originF2[3]
	new Float:dif, inf_loop
	
	entity_get_vector(ent, EV_VEC_origin, origin)
	
	originF = origin
	
	static util_ent
	if(!util_ent) util_ent = create_entity("info_target")
	
	ground_z(originF, util_ent, 0)
	
	if((origin[2] - originF[2]) < 65) origin = originF

	if(point_contents(origin) == CONTENTS_WATER)
	{
		remove_entity(ent)
		return
	}

	originF[2] = origin[2]+150
	trace_line(ent, origin, originF, originF)
	
	new scale
	dif = originF[2] - origin[2]
	if(dif > 85) {
		scale = 15
		if(dif >= 150) {
			new iorigen[3];FVecIVec(origin, iorigen)
			set_task(0.3, "smoke", ent, iorigen, 3)
		}
	}
	else scale = floatround(dif/5.7)

	flame_fire(origin, scale, 1)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_WORLDDECAL)
	write_coord_f(origin[0])
	write_coord_f(origin[1])
	write_coord_f(origin[2])
	write_byte(random_num(46, 48))
	message_end() 
	
	new total_loop
	
	for(new i; i < 8; i++)
	{
		inf_loop=0;dif=200.0
		while(dif > 100.0 && inf_loop++ < 25) {
			total_loop++
			originF[0] = origin[0] + random_num(-95, 95)
			originF[1] = origin[1] + random_num(-95, 95)
			originF[2] = origin[2]

			trace_line(ent, origin, originF, originF)

			if(get_distance_f(origin, originF) < 10)
				continue
		
			ground_z(originF, util_ent, random_num(5, 30))
	
			if(point_contents(originF) == CONTENTS_WATER)
				continue

			dif =  origin[2] - originF[2]
		} 
		if(inf_loop >= 25) break

		originF2 = originF;originF2[2] += 55
		trace_line(ent, originF, originF2, originF2)
		scale = floatround((originF2[2] - originF[2])/5.3)
		if(scale < 5) scale = 3
		else scale = random_num(5, scale)

		flame_fire(originF, scale, 0)
	}
	
	emit_sound(ent, CHAN_VOICE, sound_molotov_exp, 1.0, ATTN_NORM, 0, PITCH_NORM)

	static victim
	victim = -1
	
	while(0 < (victim = find_ent_in_sphere(victim, origin, 110.0)) <= g_maxplayers)
	{
		if(!is_user_valid_alive(victim) || !is_any_zombie(victim) || g_nodamage[victim]) continue

		send_status_icon(victim, 0.0, "dmg_heat", 250, 200, 0, 1)

		if(is_zombie(victim))
			g_burning_duration[victim] += get_pcvar_num(cvar_fireduration)*7
		else
			g_burning_duration[victim] += get_pcvar_num(cvar_fireduration)*2

		if(!task_exists(victim+TASK_BURN))
			set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")
	}
	remove_entity(ent)
}

flame_fire(Float:origen[3], rand, spr_num)
{
	static Float:mult[] = { 5.0, 5.2 }

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origen, 0)
	write_byte(TE_SPRITE)
	write_coord_f(origen[0])
	write_coord_f(origen[1])
	write_coord_f(origen[2]+rand*mult[spr_num])
	write_short(g_molotovFireStr[spr_num])
	write_byte(rand)
	write_byte(190)
	message_end()
}

public smoke(origen[3])
{
	origen[2] += 100
	message_begin(MSG_PVS, SVC_TEMPENTITY, origen)
	write_byte(TE_SMOKE)
	write_coord(origen[0])
	write_coord(origen[1])
	write_coord(origen[2])
	write_short(g_smokeSpr)
	write_byte(random_num(20, 30))
	write_byte(12)
	message_end()
}

stock ground_z(Float:origen[3], ent, up)
{
	origen[2] += up
	
	entity_set_vector(ent, EV_VEC_origin, origen)
	drop_to_floor(ent)
	entity_get_vector(ent, EV_VEC_origin, origen)
}

// Frost Grenade Explosion
frost_explode(ent)
{
	static Float:originF[3]
	entity_get_vector(ent, EV_VEC_origin, originF)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITETRAIL)
	write_coord_f(originF[0])
	write_coord_f(originF[1])
	write_coord_f(originF[2])
	write_coord_f(originF[0])
	write_coord_f(originF[1])
	write_coord_f(originF[2])
	write_short(g_glowSpr)
	write_byte(65)
	write_byte(1)
	write_byte(2)
	write_byte(40)
	write_byte(55) 
	message_end()
		
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord_f(originF[0]); // origin x
	write_coord_f(originF[1]); // origin y
	write_coord_f(originF[2]); // origin z
	write_short(g_exploSpr4); // sprites
	write_byte(35); // scale in 0.1's
	write_byte(18); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	emit_sound(ent, CHAN_WEAPON, grenade_frost[random_num(0, charsmax(grenade_frost))], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static victim;victim = -1
	
	while(0 < (victim = find_ent_in_sphere(victim, originF, NADE_EXPLOSION_RADIUS)) <= 32)
	{
		if(!is_user_valid_alive(victim) || !is_any_zombie(victim) || g_frozen[victim] || g_nodamage[victim])
			continue
		
		if(!is_zombie(victim))
		{
			static origin2[3]
			get_user_origin(victim, origin2)
			
			emit_sound(victim, CHAN_BODY, grenade_frost_break[random_num(0, charsmax(grenade_frost_break))], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Glass shatter
			message_begin(MSG_PVS, SVC_TEMPENTITY, origin2)
			write_byte(TE_BREAKMODEL) // TE id
			write_coord(origin2[0]) // x
			write_coord(origin2[1]) // y
			write_coord(origin2[2]+24) // z
			write_coord(16) // size x
			write_coord(16) // size y
			write_coord(16) // size z
			write_coord(random_num(-50, 50)) // velocity x
			write_coord(random_num(-50, 50)) // velocity y
			write_coord(25) // velocity z
			write_byte(10) // random velocity
			write_short(g_glassSpr) // model
			write_byte(10) // count
			write_byte(25) // life
			write_byte(BREAK_GLASS) // flags
			message_end()
			continue
		}

		send_status_icon(victim, 3.0, "dmg_cold", 0, 200, 255) 
		
		set_user_rendering(victim, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)
		
		emit_sound(victim, CHAN_BODY, grenade_frost_player[random_num(0, charsmax(grenade_frost_player))], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		static Float:freezeduration
		freezeduration = get_pcvar_float(cvar_freezeduration)
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, victim)
		write_short(UNIT_SECOND*1) // duration
		write_short(floatround(UNIT_SECOND*freezeduration)) // hold time
		write_short(FFADE_IN) // fade type
		write_byte(0) // red
		write_byte(50) // green
		write_byte(210) // blue
		write_byte(110) // alpha
		message_end()
		
		g_frozen[victim] = true

		player_maxspeed(victim)
		player_gravity(victim)
		
		set_task(freezeduration, "remove_freeze", victim)
	}
	remove_entity(ent)
}

public remove_freeze(id)
{
	if(!g_frozen[id] || !g_is_alive[id])
		return
	
	g_frozen[id] = false
	
	player_gravity(id)
	player_maxspeed(id)

	emit_sound(id, CHAN_BODY, grenade_frost_break[random_num(0, charsmax(grenade_frost_break))], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_user_rendering(id)
	set_zgohst(id)
	
	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BREAKMODEL) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]+24) // z
	write_coord(16) // size x
	write_coord(16) // size y
	write_coord(16) // size z
	write_coord(random_num(-50, 50)) // velocity x
	write_coord(random_num(-50, 50)) // velocity y
	write_coord(25) // velocity z
	write_byte(10) // random velocity
	write_short(g_glassSpr) // model
	write_byte(10) // count
	write_byte(25) // life
	write_byte(BREAK_GLASS) // flags
	message_end()
}

public remove_stuff()
{
	static ent;ent = -1
	while((ent = find_ent_by_class(ent, "light")) > 0)
	{
		dllfunc(DLLFunc_Use, ent, 0)
		entity_set_string(ent, EV_SZ_targetname, "")
	}
}

reset_vars(id, resetall)
{
	g_zombie[id] = CLASS_NONE
	g_human[id] = CLASS_NONE
	g_infected[id] = false
	g_firstzombie[id] = false
	g_lastzombie[id] = false
	g_lasthuman[id] = false
	g_frozen[id] = false
	g_nodamage[id] = false
	g_respawn_as_zombie[id] = false
	g_nvision[id] = false
	g_nvisionenabled[id] = false
	g_canbuy[id] = true
	g_zombie_dmg[id] = 0

	if(!resetall) return

	g_ammopacks[id] = NIVELES(1)+2
	g_zombieclass[id] = 0
	g_zombieclassnext[id] = 0
	g_damagedealt[id] = 0
	WPN_AUTO_ON = 0
	WPN_AUTO_PRI = 0
	WPN_AUTO_SEC = 0
	
	g_login[id] = false
	g_is_banned[id] = 0
	g_ban_expire[id] = 0
	g_valid_email[id] = false
	g_registered[id] = false
	g_login_error[id] = 0
	g_reset_level[id] = 0
	g_level[id] = 1
	g_nvg_color[id] = 0
	g_flare_color[id] = 0
	g_autonvg[id] = 1
	hud_color[id][0] = 2
	hud_color[id][1] = 4
	hud_posicion[id][0] = Float:{ 0.88, 0.62 }
	hud_posicion[id][1] = Float:{ 0.20, 0.03 }
	g_hud_unidad[id] = 0.01
	g_hud_unidadnum[id] = 1
	g_login_attempts[id] = 4
	g_new_password_status[id] = 0
	g_humanclass[id] = 0
	g_timeonline[id] = 0
	g_insult[id] = 0
	
	g_hid[id][1] = "-^0"
	g_hid[id][2] = "-^0"
	g_hid[id][3] = "-^0"
	
	g_playermodel[id][0] = '^0'
	
	static i
	for(i = 0; i < MAX_EXTRA_ITEMS; i++) g_extra_limit[id][i] = 0
	for(i = 0; i < MAX_KILLS; i++) g_kills[id][i] = 0
	
	for(i = 0; i < 6; i++)
	{
		g_weapons_mejoras[id][i][0] = 0
		g_weapons_mejoras[id][i][1] = 0
		g_weapons_mejoras[id][i][2] = 0
	}
	g_weapons_puntos[id][0] = g_weapons_puntos[id][1] = 0
	g_security_resets[id][0] = g_security_resets[id][1] = g_security_resets[id][2] = 0
	
	reset_points(id)
}

reset_points(id)
{
	static i
	for(i = 0; i < MAX_KILLS; i++) g_mission_progress[id][i] = 0
	for(i = 0; i < MAX_IMPROV_HUMAN; i++) g_improv_human[id][i] = 0
	for(i = 0; i < MAX_IMPROV_ZOMBIE; i++) g_improv_zombie[id][i] = 0
	
	for(i = 0; i < 2; i++)
	{
		g_points[id][i] = 0
		g_points_spent[id][i] = 0
		g_mission[id][i] = 0
	}
}

set_user_nvg(id)
{
	if(!g_is_connected[id])
		return

	g_nvisionenabled[id] = g_autonvg[id]
	g_nvision[id] = true

	set_nvg(id)
}

public spec_nvision(id)
{
	if(!g_is_connected[id] || g_is_alive[id])
		return

	set_user_nvg(id)
}

public zombie_play_idle(id)
{
	id -= TASK_BLOOD

	if(g_endround || g_newround)
		return
	
	if(g_lastzombie[id])
		emit_sound(id, CHAN_VOICE, zombie_idle_last[random_num(0, charsmax(zombie_idle_last))], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		emit_sound(id, CHAN_VOICE, zombie_idle[random_num(0, charsmax(zombie_idle))], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public madness_over(id)
{
	id -= TASK_BLOOD
	g_nodamage[id] = false
	del_aura(id)
}

do_random_spawn(id)
{
	if(!g_spawnCount)
		return
	
	static hull
	hull = (get_entity_flags(id) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	static sp_index, i
	sp_index = random_num(0, g_spawnCount - 1)
	
	for(i = sp_index + 1; i != 999; i++)
	{
		if(i >= g_spawnCount) i = 0
		
		if(is_hull_vacant(g_spawns[i], hull))
		{
			entity_set_origin(id, g_spawns[i])
			break
		}
		
		if(i == sp_index) break
	}
}

fmCheckHZ()
{
	static id, h, z
	h = 0; z = 0
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_alive[id])
			continue

		if(!is_any_zombie(id) && !g_infected[id])
			h++
		else
			z++
	}
	g_humans = h
	g_zombies = z
}

fnGetAlive()
{
	static count, id
	count = 0

	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_alive[id]) continue
		
		g_players[count++] = id
	}

	return count
}

fnGetPlaying()
{
	static count, id, team
	count = 0
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id] || !g_login[id]) continue
		
		team = fm_get_user_team(id)	
		if(team == ZP_TEAM_SPECTATOR || team == ZP_TEAM_UNASSIGNED) continue
		
		g_players[count++] = id
	}
	return count
}

fnCheckLastZombie()
{
	static id, z[2], h[2]
	z[0] = 0;h[0] = 0;z[1] = 0;h[1] = 0;

	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_alive[id])
			continue

		if(is_zombie(id))
		{
			z[0]++
			z[1] = id
		}
		else if(is_human(id))
		{
			h[0]++
			h[1] = id
		}
	}

	if(z[0] == 1)
		g_lastzombie[z[1]] = true

	if(h[0] == 1)
	{
		if(!g_lasthuman[h[1]])
			set_user_health(h[1], (get_user_health(h[1])+get_pcvar_num(cvar_humanlasthp)))
		g_lasthuman[h[1]] = true
	}

	for(id = 1; id <= g_maxplayers; id++)
	{
		if(h[1] != id)
			g_lasthuman[id] = false
		if(z[1] != id)
			g_lastzombie[id] = false
	}
}

save_stats(id)
{	
	if (db_name[id][0] && !equal(g_name[id], db_name[id]))
	{
		if (db_slot_i >= sizeof db_name)
			db_slot_i = g_maxplayers+1
		
		copy(db_name[db_slot_i], charsmax(db_name[]), db_name[id])
		db_extraitems[db_slot_i] = db_extraitems[id]
		db_slot_i++
	}

	copy(db_name[id], charsmax(db_name[]), g_name[id])
	db_extraitems[id] = g_extra_limit[id]
}
load_stats(id)
{		
	for(new i = 0; i < sizeof db_name; i++)
	{
		if(equal(g_name[id], db_name[i]))
		{
			g_extra_limit[id] = db_extraitems[i]
			return
		}
	}
}

allowed_leap(id, buttons, flags)
{
	if((!is_any_zombie(id) && !is_sniper(id)) || g_frozen[id])
		return false

	if((!(buttons & IN_JUMP) || !(buttons & IN_DUCK)))
		return false
	
	static Float:cooldown
	cooldown = is_sniper(id) ? 3.0 : is_nemesis(id) ? 0.1 : is_assassin(id) ? 2.5 : 4.0
	
	if(get_gametime() - g_lastleaptime[id] < cooldown)
		return false
	
	if(!(flags & FL_ONGROUND) || get_speed(id) < 80)
		return false
	
	return true
}

allowed_zombie(id)
{
	if(is_any_zombie(id) || g_swarmround || g_nemround || g_survround || g_plagueround || g_endround || !g_is_alive[id] || task_exists(TASK_WELCOMEMSG) || g_humans == 1)
		return false
	
	return true
}

allowed_human(id)
{
	if(!is_any_zombie(id) || g_swarmround || g_nemround || g_survround || g_plagueround || g_endround || !g_is_alive[id] || task_exists(TASK_WELCOMEMSG) || g_zombies == 1)
		return false
	
	return true
}

player_maxspeed(id)
{
	if(!g_is_alive[id])
		return

	if(g_frozen[id])
		set_user_maxspeed(id, 1.0)
	else {
		if(is_any_zombie(id))
		{
			if(is_assassin(id))
				set_user_maxspeed(id, get_pcvar_float(cvar_assaspd))
			else if(is_nemesis(id))
				set_user_maxspeed(id, get_pcvar_float(cvar_nemspd))
			else
				set_user_maxspeed(id, (g_zclass[g_zombieclass[id]][ZCLASS_VELOCITY] + (g_improv_zombie[id][Z_IMPROV_VELOCITY] * 5.3)))
		}
		else {
			if(is_survivor(id))
				set_user_maxspeed(id, get_pcvar_float(cvar_survspd))
			else if(is_sniper(id))
				set_user_maxspeed(id, get_pcvar_float(cvar_survspd))
			else
				set_user_maxspeed(id, (g_hclass[g_humanclass[id]][HCLASS_VELOCITY] + ((g_improv_human[id][H_IMPROV_VELOCITY] + 1) * 5)))
		}
	}
}

player_gravity(id)
{
	if(!g_is_alive[id])
		return

	if(g_frozen[id])
	{
		if(get_entity_flags(id) & FL_ONGROUND)
			set_user_gravity(id, 999999.9)
		else
			set_user_gravity(id, 0.000001)
	}
	else {
		if(is_any_zombie(id))
		{
			if(is_assassin(id))
				set_user_gravity(id, get_pcvar_float(cvar_nemgravity))
			else if(is_nemesis(id))
				set_user_gravity(id, get_pcvar_float(cvar_nemgravity))
			else {
				static Float:g;g = (g_zclass[g_zombieclass[id]][ZCLASS_GRAVITY] - (0.044 * (g_improv_zombie[id][Z_IMPROV_GRAVITY] + 1)))
				if(g < 0.40) g = 0.40
				set_user_gravity(id, g)
			}
		}
		else {
			if(is_survivor(id))
				set_user_gravity(id, 0.58)
			else if(is_sniper(id))
				set_user_gravity(id, 0.58)
			else {
				static Float:g;g = (g_hclass[g_humanclass[id]][HCLASS_GRAVITY] - (0.040 * (g_improv_human[id][H_IMPROV_GRAVITY] + 1)))
				if(g < 0.42) g = 0.42
				set_user_gravity(id, g)
			}
		}
	}
}

replace_models(id)
{
	if(!g_is_alive[id])
		return
	
	_debug(0, "1replace_models(%d)", id)
	
	switch(g_currentweapon[id])
	{
		case CSW_KNIFE:
		{
			if(is_any_zombie(id) && !g_newround && !g_endround)
			{
				if(is_nemesis(id))
				{
					set_pev(id, pev_viewmodel2, model_vknife_nemesis)
					set_pev(id, pev_weaponmodel2, "")
				}
				else if(is_assassin(id))
				{
					entity_set_string(id, EV_SZ_viewmodel, "models/v_knife.mdl")
					entity_set_string(id, EV_SZ_weaponmodel, "models/p_knife.mdl")
				}
				else
				{
					set_pev(id, pev_viewmodel2, g_zclass[g_zombieclass[id]][ZCLASS_CLAWMODEL])
					set_pev(id, pev_weaponmodel2, "")
				}
			}
			else
			{
				/*if(g_w_models[CSW_KNIFE][0][0])
					entity_set_string(id, EV_SZ_viewmodel, g_w_models[CSW_KNIFE][0][0])
				if(g_w_models[CSW_KNIFE][1][0])
					entity_set_string(id, EV_SZ_weaponmodel, g_w_models[CSW_KNIFE][1][0])*/
				entity_set_string(id, EV_SZ_weaponmodel, "models/p_knife.mdl")
			}
		}
		case CSW_MP5NAVY:
		{
			if(is_survivor(id))
			{
				entity_set_string(id, EV_SZ_viewmodel, model_v_survivor)
				entity_set_string(id, EV_SZ_weaponmodel, model_p_survivor)

				if(pev_valid(id) == PDATA_SAFE)
					set_pdata_string(id, m_szAnimExtention * 4, "dualpistols", -1, OFFSET_LINUX * 4)
			}
			/*else {
				if(g_w_models[CSW_MP5NAVY][0][0])
					entity_set_string(id, EV_SZ_viewmodel, g_w_models[CSW_MP5NAVY][0])
				if(g_w_models[CSW_MP5NAVY][1][0])
					entity_set_string(id, EV_SZ_weaponmodel, g_w_models[CSW_MP5NAVY][1])
			}*/
		}/*
		default:
		{
			if(g_w_models[g_currentweapon[id]][0][0])
				entity_set_string(id, EV_SZ_viewmodel, g_w_models[g_currentweapon[id]][0])
			if(g_w_models[g_currentweapon[id]][1][0])
				entity_set_string(id, EV_SZ_weaponmodel, g_w_models[g_currentweapon[id]][1])
		}*/
	}
}

grenade_deploy(id)
{
	if(!g_current_grenade[id])
	{
		if(!check_hasgrenade(id))
		{
			engclient_cmd(id, "weapon_knife")
			return
		}
	}
	if(g_has_grenades[id][g_current_grenade[id]-1] <= 0)
	{
		if(!check_hasgrenade(id))
		{
			engclient_cmd(id, "weapon_knife")
			return
		}
	}

	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id)
	write_byte(12)
	write_byte(g_has_grenades[id][g_current_grenade[id]-1])
	message_end()
	
	switch(g_current_grenade[id])
	{
		case NADE_TYPE_MOLOTOV: {
			entity_set_string(id, EV_SZ_viewmodel, model_v_grenade_molotov)
			entity_set_string(id, EV_SZ_weaponmodel, model_p_grenade_molotov)
		}
		case NADE_TYPE_HE: {
			entity_set_string(id, EV_SZ_viewmodel, model_v_grenade_he)
			entity_set_string(id, EV_SZ_weaponmodel, model_p_grenade_he)
		}
		case NADE_TYPE_NAPALM: {
			entity_set_string(id, EV_SZ_viewmodel,  model_v_grenade_fire)
			entity_set_string(id, EV_SZ_weaponmodel, model_p_grenade_fire)
		
		}case NADE_TYPE_ANTIDOTEBOMB: {
			entity_set_string(id, EV_SZ_viewmodel, model_v_grenade_anti)
			entity_set_string(id, EV_SZ_weaponmodel, model_p_grenade_anti)
		}
		
		case NADE_TYPE_FORCEFIELD: {
			entity_set_string(id, EV_SZ_viewmodel, model_v_grenade_field)
			entity_set_string(id, EV_SZ_weaponmodel, "models/p_hegrenade.mdl")
		}
		case NADE_TYPE_FLARE: {
			entity_set_string(id, EV_SZ_viewmodel, model_v_grenade_flare)
			entity_set_string(id, EV_SZ_weaponmodel, model_p_grenade_flare)
		}
		case NADE_TYPE_INFECTION: {
			entity_set_string(id, EV_SZ_viewmodel, model_grenade_infect)
		}
		case NADE_TYPE_FROST: {
			entity_set_string(id, EV_SZ_viewmodel, model_v_grenade_frost)
			entity_set_string(id, EV_SZ_weaponmodel, model_p_grenade_frost)
		}
	}
}

min_players()
{
	static i, b
	b = 0;
	for(i = 0; i <= g_maxplayers; i++){
		if(g_is_connected[i] && g_login[i])
			b++
	}
	if(b < MIN_PLAYERS)
		g_minplayers = true
	else
		g_minplayers = false

	#if defined USANDO_EN_LAN
	g_minplayers = false
	#endif
}

player_buy_weapon(id, selection, type)
{
	if(!is_human(id) || !g_is_alive[id])
		return
	
	static weaponid, weaponent
	
	drop_weapons(id, 2)
	
	if(type == WPN_TYPE_PRIMARY)
	{
		g_wpn_mejoras_active[id] = false
		g_recoil_mul[id] = 1.0
	}

	if(type == WPN_TYPE_SECONDARY)
	{
		weaponid = g_secondary_weapons[selection][WPN_BASE]
		weaponent = give_item(id, WEAPONENTNAMES[weaponid])
		zp_set_weaponid(weaponent, selection, WPN_TYPE_SECONDARY)
		cs_set_user_bpammo(id, weaponid, MAXBPAMMO[weaponid])
	}
	else
	{
		drop_weapons(id, 1)
		strip_user_weapons(id)
		give_item(id, "weapon_knife")

		weaponid = g_primary_weapons[selection][WPN_BASE]
		weaponent = give_item(id, WEAPONENTNAMES[weaponid])
		zp_set_weaponid(weaponent, selection, WPN_TYPE_PRIMARY)
		cs_set_user_bpammo(id, weaponid, MAXBPAMMO[weaponid])
	}

	g_canbuy[id] = false
}


buy_extra_item(id, itemid)
{
	if(!g_is_alive[id] || (!is_human(id) && !is_zombie(id)))
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Comando no disponible.")
		return
	}

	if(is_zombie(id) && g_extraitem_team[itemid] == ZP_TEAM_HUMAN)
	{
		zp_colored_print(id, "^4[Z-Evil]^1 Esto solo esta disponible para humanos.")
		return
	}
	
	if(!is_zombie(id) && g_extraitem_team[itemid] == ZP_TEAM_ZOMBIE)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Esto solo esta disponible para zombies.")
		return
	}
	
	if((itemid == EXTRA_ANTIDOTE && (g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || g_zombies <= 1 || g_humans == 1))
	|| (itemid == EXTRA_MADNESS && g_nodamage[id]) || (itemid == EXTRA_INFBOMB && (g_endround || g_swarmround || g_nemround || g_survround || g_plagueround)))
	{
		zp_colored_print(id, "^4[Z-Evil]^3 No puedes usar esto ahora.")
		return
	}
	
	if(g_ammopacks[id] < extra_item_cost(id, itemid))
	{
		zp_colored_print(id, "^4[Z-Evil]^1 No tienes suficientes ammo packs.")
		return
	}
	
	if(g_extraitem_limit[itemid] > 0 && g_extra_limit[id][itemid] >= g_extraitem_limit[itemid])
	{
		zp_colored_print(id, "^4[Z-Evil]^1 No puedes volver a usar esto hasta el proximo map.")
		return
	}
	
	// Level checks removed � items gated only by AP cost
	if(g_ammopacks[id] < extra_item_cost(id, itemid))
	{
		zp_colored_print(id, "^4[Z-Evil]^1 No tienes suficientes AP. Necesitas: ^3%d ^1AP", extra_item_cost(id, itemid))
		return
	}

	g_ammopacks[id] -= extra_item_cost(id, itemid)
	g_extra_limit[id][itemid]++

	play_soundmenu(id, SOUNDMENU_SELECT)

	switch(itemid)
	{
		case EXTRA_NVISION: set_user_nvg(id)
		case EXTRA_ANTIDOTE: humanme(id, CLASS_HUMAN)
		case EXTRA_MADNESS:
		{
			g_nodamage[id] = true
			set_aura(id)
			emit_sound(id, CHAN_VOICE, zombie_madness[random_num(0, charsmax(zombie_madness))], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_task(6.0, "madness_over", id+TASK_BLOOD)
		}
		case EXTRA_INFBOMB: give_grenade(id, NADE_TYPE_INFECTION)
		case EXTRA_ANTIDOTE_BOMB: give_grenade(id, NADE_TYPE_ANTIDOTEBOMB)
		case EXTRA_FORCEFIELD: give_grenade(id, NADE_TYPE_FORCEFIELD)
		case EXTRA_UNLIMITED_CLIP: g_has_unlimited_clip[id] = g_time+100
		default:
		{
			ExecuteForward(g_fwExtraItemSelected, g_fwDummyResult, id, itemid)
			if(g_fwDummyResult >= ZP_PLUGIN_HANDLED)
					g_ammopacks[id] += extra_item_cost(id, itemid)
		}
	}
	check_player_level(id)
}

PlaySound(const sound[]) client_cmd(0, "spk ^"%s^"", sound)

play_soundmenu(id, soundid) client_cmd(id, "spk ^"%s^"", sound_menu[soundid])

mp3_sound_stop(id) client_cmd(id, "mp3 stop; stopsound")

mp3_sound_play(id, sound) client_cmd(id, "mp3 ^"play^" ^"%s^"", sound_environment_mp3[sound])

/*================================================================================
[Make Zombie/Human]
=================================================================================*/
public make_zombie_task(task)
	make_a_zombie(MODE_NONE, 0)

make_a_zombie(mode, id)
{
	// Illidan Boss Map check � runs before player count gate
	{
		static mapname[32]
		get_mapname(mapname, charsmax(mapname))
		if(equal(mapname, ILLIDAN_MAP))
		{
			remove_task(TASK_MAKEZOMBIE)
			g_newround = false
			g_survround = false
			g_nemround = false
			g_swarmround = false
			g_plagueround = false
			server_print("[IllidanBoss] illidan_round_start called on map: %s", mapname)
			illidan_round_start()
			return
		}
	}

	static iPlayersnum
	iPlayersnum = fnGetAlive()

	remove_task(TASK_MAKEZOMBIE)
	if(iPlayersnum < 1)
	{
		set_task(10.0, "make_zombie_task", TASK_MAKEZOMBIE)
		return
	}

	// Round starting
	g_newround = false
	g_survround = false
	g_nemround = false
	g_swarmround = false
	g_plagueround = false
	
	// Set up some common vars
	static forward_id, iZombies, iMaxZombies
	
	if ((mode == MODE_NONE && (g_lastmode != MODE_SURVIVOR) && random_num(1, get_pcvar_num(cvar_survchance)) == 1 && iPlayersnum >= 5)|| mode == MODE_SURVIVOR)
	{
		// Survivor Mode
		g_survround = true
		g_lastmode = MODE_SURVIVOR
		
		if(mode == MODE_NONE)
			id = g_players[random_num(0, iPlayersnum-1)]
	
		forward_id = id
		
		humanme(id, CLASS_SURVIVOR)
		set_protection(id, 8.0)
		
		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_survivor(id) || is_zombie(id)) continue
			
			zombieme(id, CLASS_ZOMBIE, 0, 1)
		}
		
		PlaySound(sound_survivor[random_num(0, charsmax(sound_survivor))])
		
		set_hudmessage(20, 20, 255, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%s es un Survivor !!!", g_name[forward_id])
		show_msgtutor(0, 3.5, 2, "%s Es un Survivor!!!", g_name[forward_id])
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_SURVIVOR, forward_id)
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_ASSASSIN) && random_num(1, get_pcvar_num(cvar_assassinchance)) == get_pcvar_num(cvar_assassin) && iPlayersnum >= 10) || mode == MODE_ASSASSIN)
	{
		// Assassin Mode
		g_nemround = true
		g_assaround = true
		g_lastmode = MODE_ASSASSIN
		
		id = g_players[random_num(0, iPlayersnum-1)]
		
		forward_id = id
		
		zombieme(id, CLASS_ASSASSIN)

		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_assassin(id) || fm_get_user_team(id) == ZP_TEAM_CT) continue
				
			remove_task(id+TASK_TEAM)			
			fm_set_user_team(id, ZP_TEAM_CT)
			fm_user_team_update(id)
		}
		
		PlaySound(sound_assassin)
		
		set_hudmessage(20, 20, 255, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%s es un Assassin !!!", g_name[forward_id])
		show_msgtutor(0, 3.5, 1, "%s Es un Assassin!!!", g_name[forward_id])
		
		lighting_effects()

		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_ASSASSIN, forward_id)	
	}	
	else if ((mode == MODE_NONE && (g_lastmode != MODE_SNIPER) && random_num(1, get_pcvar_num(cvar_sniperchance)) == 1 && iPlayersnum >= 8) || mode == MODE_SNIPER)
	{
		// Sniper Mode
		g_survround = true
		g_sniperround = true
		g_lastmode = MODE_SNIPER
		
		id = g_players[random_num(0, iPlayersnum-1)]
		
		forward_id = id
		
		humanme(id, CLASS_SNIPER)
		set_protection(id, 9.0)

		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_sniper(id) || is_zombie(id))
				continue

			zombieme(id, CLASS_ZOMBIE, 0, 1)
		}

		PlaySound(sound_survivor[random_num(0, charsmax(sound_survivor))]);
		
		set_hudmessage(20, 20, 255, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%s es un Sniper !!!", g_name[forward_id])
		show_msgtutor(0, 3.5, 2, "%s Es un Sniper!!!", g_name[forward_id])
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_SNIPER, forward_id)	
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_SWARM) && random_num(1, get_pcvar_num(cvar_swarmchance)) == 1 && iPlayersnum >= 8) || mode == MODE_SWARM)
	{		
		// Swarm Mode
		g_swarmround = true
		g_lastmode = MODE_SWARM
		
		iMaxZombies = floatround(iPlayersnum/2.0)
		iZombies = 0
		new fix_swarm = 0
		while(iZombies < iMaxZombies && fix_swarm < g_maxplayers * 3)
		{
			fix_swarm++
			if(id++ > g_maxplayers) id = 1

			if(!is_user_valid_alive(id) || is_zombie(id)) continue

			if(random_num(0, 1))
			{
				zombieme(id, CLASS_ZOMBIE, 0, 1)
				iZombies++
			}
		}
		
		for(id = 1; id<=g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_zombie(id)) continue
			

			if(fm_get_user_team(id) != ZP_TEAM_CT)
			{
				remove_task(id+TASK_TEAM)
				fm_set_user_team(id, ZP_TEAM_CT)
				fm_user_team_update(id)
			}
		}
		
		PlaySound(sound_swarm[random_num(0, charsmax(sound_swarm))]);
		
		set_hudmessage(20, 255, 20, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Modo Swarm!!!")
		show_msgtutor(0, 3.5, 0, "Modo Swarm!!!")
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_SWARM, 0)
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_MULTI) && random_num(1, get_pcvar_num(cvar_multichance)) == 1 && floatround(iPlayersnum*get_pcvar_float(cvar_multiratio), floatround_ceil) >= 2 && iPlayersnum >= get_pcvar_num(cvar_multiminplayers)) || mode == MODE_MULTI)
	{
		// Multi Infection Mode
		g_lastmode = MODE_MULTI
		
		iMaxZombies = floatround(iPlayersnum*get_pcvar_float(cvar_multiratio), floatround_ceil)
		iZombies = 0
		new fix_multi = 0
		while(iZombies < iMaxZombies && fix_multi < g_maxplayers * 3)
		{
			fix_multi++
			if(id++ > g_maxplayers) id = 1

			if(!is_user_valid_alive(id) || is_zombie(id)) continue

			if(random_num(0, 1))
			{
				zombieme(id, CLASS_ZOMBIE, 0, 1)
				iZombies++
			}
		}
		
		for(id = 1; id<=g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_zombie(id)) continue
			
			if(fm_get_user_team(id) != ZP_TEAM_CT)
			{
				remove_task(id+TASK_TEAM)
				fm_set_user_team(id, ZP_TEAM_CT)
				fm_user_team_update(id)
			}
		}
		
		PlaySound(sound_multi[random_num(0, charsmax(sound_multi))])
		
		set_hudmessage(200, 50, 0, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Multiples Infecciones!!!")
		show_msgtutor(0, 3.5, 5, "Multiples Infecciones!!!")
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_MULTI, 0)
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_SYNAPSIS) && random_num(1, get_pcvar_num(cvar_synapsischance)) == get_pcvar_num(cvar_synapsis) && floatround((iPlayersnum-2)*get_pcvar_float(cvar_synapsisratio),
	floatround_ceil) >= 1 && iPlayersnum >= 10) || mode == MODE_SYNAPSIS)
	{
		g_plagueround = true
		g_synapsisround = true
		
		new i, fix
		while(i < 3 && fix < 50)
		{
			fix++
			id = g_players[random_num(0, iPlayersnum-1)]
			if(is_any_zombie(id)) continue
			zombieme(id, CLASS_NEMESIS)
			i++
		}
		i=0;fix=0
		while(i < 3 && fix < 50)
		{
			fix++
			id = g_players[random_num(0, iPlayersnum-1)]
			if(is_any_zombie(id) || is_survivor(id)) continue
			humanme(id, CLASS_SURVIVOR)
			i++
		}

		
		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || !is_human(id)) continue
			
			if(fm_get_user_team(id) != ZP_TEAM_CT)
			{
				remove_task(id+TASK_TEAM)
				fm_set_user_team(id, ZP_TEAM_CT)
				fm_user_team_update(id)
			}
		}

		PlaySound(sound_plague[random_num(0, charsmax(sound_plague))])
		
		set_hudmessage(0, 50, 200, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Modo Synapsis!!!")
		show_msgtutor(0, 3.5, 1, "Modo Synapsis!!!")
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_SYNAPSIS, 0)
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_UMBRELLA) && (random_num(1, 10) == 4) && iPlayersnum >= 17) || mode == MODE_UMBRELLA)
	{
		// Umbrella Mode
		g_swarmround = true
		g_umbrellaround = true
		g_lastmode = MODE_UMBRELLA
		
		id = g_players[random_num(0, iPlayersnum-1)]
		humanme(id, CLASS_CIVIL)
		set_protection(id, 12.0)

		set_hudmessage(0, 255, 0, -1.0, 0.07, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, g_MsgSync3, "Eres un civil.Huye de los zombies.")

		new soldados, fix
		while(soldados < 5 && fix < 200)
		{
			id = g_players[random_num(0, iPlayersnum-1)]
			if(!is_umbrella(id) && !is_civil(id))
			{
				g_human[id] = CLASS_UMBRELLA
				set_user_health(id, 2000)

				strip_user_weapons(id)
				give_item(id, "weapon_knife")
				give_item(id, "weapon_deagle")

				if(random_num(0, 1))
					give_item(id, "weapon_m4a1")
				else
					give_item(id, "weapon_galil")

				
				if(fm_get_user_team(id) != ZP_TEAM_CT)
				{
					remove_task(id+TASK_TEAM)
					fm_set_user_team(id, ZP_TEAM_CT)
					fm_user_team_update(id)
				}

				set_protection(id, 8.0)

				switch(soldados)
				{
					case 0..1: copy(g_playermodel[id], charsmax(g_playermodel[]), "OA_SoldadoU")
					case 2: copy(g_playermodel[id], charsmax(g_playermodel[]), "OA_SoldadoU")
					case 3: copy(g_playermodel[id], charsmax(g_playermodel[]), "OA_SoldadoU")
					case 4: copy(g_playermodel[id], charsmax(g_playermodel[]), "OA_SoldadoU")
				}

				fm_user_model_update(id+TASK_MODEL)

				set_hudmessage(0, 255, 0, -1.0, 0.07, 2, 0.1, 4.0, 0.1, 0.1, -1)
				ShowSyncHudMsg(id, g_MsgSync3, "Eres un soldado umbrella.^nProtege al civil")

				soldados++
			}
			fix++
		}
		
		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_umbrella(id) || is_civil(id))
				continue
			
			set_hudmessage(0, 255, 0, -1.0, 0.07, 2, 0.1, 4.0, 0.1, 0.1, -1)
			ShowSyncHudMsg(id, g_MsgSync3, "Maten al civil!!!")
			zombieme(id, CLASS_ZOMBIE, 0, 1)
		}
		
		PlaySound(sound_umbrella)
		
		set_hudmessage(0, 50, 200, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Modo Umbrella!!!")
		show_msgtutor(0, 3.5, 6, "Modo Umbrella!!!")
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_PLAGUE, 0)
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_PLAGUE) && random_num(1, get_pcvar_num(cvar_plaguechance)) == 1 && floatround((iPlayersnum-2)*get_pcvar_float(cvar_plagueratio), floatround_ceil) >= 1 && iPlayersnum >= get_pcvar_num(cvar_plagueminplayers)) || mode == MODE_PLAGUE)
	{
		// Plague Mode
		g_plagueround = true
		g_lastmode = MODE_PLAGUE
		
		id = g_players[random_num(0, iPlayersnum-1)]
		humanme(id, CLASS_SURVIVOR)

		// Find a different player for nemesis (safety counter prevents infinite loop solo)
		new fix_nem = 0
		while(is_survivor(id) && fix_nem < 50)
		{
			fix_nem++
			id = g_players[random_num(0, iPlayersnum-1)]
		}
		if(!is_survivor(id)) zombieme(id, CLASS_NEMESIS)
		
		iMaxZombies = floatround((iPlayersnum-2)*get_pcvar_float(cvar_plagueratio), floatround_ceil)
		if(iMaxZombies < 1) iMaxZombies = 1
		iZombies = 0
		new fix_plague = 0
		while(iZombies < iMaxZombies && fix_plague < g_maxplayers * 3)
		{
			fix_plague++
			if(id++ > g_maxplayers) id = 1

			if(!is_user_valid_alive(id) || is_any_zombie(id) || is_survivor(id)) continue

			if(random_num(0, 1))
			{
				zombieme(id, CLASS_ZOMBIE, 0, 1)
				iZombies++
			}
		}

		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_any_zombie(id) || is_survivor(id)) continue
			
			
			if (fm_get_user_team(id) != ZP_TEAM_CT)
			{
				remove_task(id+TASK_TEAM)
				fm_set_user_team(id, ZP_TEAM_CT)
				fm_user_team_update(id)
			}
		}
		
		PlaySound(sound_plague[random_num(0, charsmax(sound_plague))])
		
		set_hudmessage(0, 50, 200, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "Modo Plague!!!")
		show_msgtutor(0, 3.5, 6, "Modo Plague!!!")
		
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_PLAGUE, 0);
	}
	else if ((mode == MODE_NONE && (g_lastmode != MODE_NEMESIS) && random_num(1, get_pcvar_num(cvar_nemchance)) == 1 && iPlayersnum >= get_pcvar_num(cvar_nemminplayers)) || mode == MODE_NEMESIS)
	{
		if(mode == MODE_NONE)
			id = g_players[random_num(0, iPlayersnum-1)]

		forward_id = id

		// Nemesis Mode
		g_nemround = true
		g_lastmode = MODE_NEMESIS
			
		// Turn player into nemesis
		zombieme(id, CLASS_NEMESIS)

		for (id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_any_zombie(id)) continue
			
			if(fm_get_user_team(id) != ZP_TEAM_CT)
			{
				remove_task(id+TASK_TEAM)
				fm_set_user_team(id, ZP_TEAM_CT)
				fm_user_team_update(id)
			}
		}

		PlaySound(sound_nemesis[random_num(0, charsmax(sound_nemesis))])
			
		set_hudmessage(255, 20, 20, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%s Es un Nemesis!!!", g_name[forward_id])
		show_msgtutor(0, 3.5, 1, "%s Es un Nemesis!!!", g_name[forward_id])
			
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_NEMESIS, forward_id)
	}
	else {
		// Infection Mode
		g_lastmode = MODE_INFECTION

		new zombie, zombie2, zombie3
		if(mode == MODE_NONE)
		{
			zombie = g_players[random_num(0, iPlayersnum-1)]
			for(new o; o <= 7; o++)
			{
				if(zombie == g_zombie_previousround[0] || zombie == g_zombie_previousround[1] || zombie == g_zombie_previousround[2])
					zombie = g_players[random_num(0, iPlayersnum-1)]
			}
			zombieme(zombie, CLASS_ZOMBIE, 0, 0)

			if(iPlayersnum > 15)
			{
				zombie2 = g_players[random_num(0, iPlayersnum-1)]
				while(is_zombie(zombie2) || zombie2 == g_zombie_previousround[0] || zombie2 == g_zombie_previousround[1] || zombie2 == g_zombie_previousround[2])
					zombie2 = g_players[random_num(0, iPlayersnum-1)]

				zombieme(zombie2, CLASS_ZOMBIE, 0, 0)
				set_user_health(zombie2, (floatround((g_zclass[g_zombieclass[zombie2]][ZCLASS_HEALTH] + (g_improv_zombie[zombie2][Z_IMPROV_HEALTH] * 225))*get_pcvar_float(cvar_zombiefirsthp))))

				zombie3 = g_players[random_num(0, iPlayersnum-1)]
				while(is_zombie(zombie3) || zombie3 == g_zombie_previousround[0] || zombie3 == g_zombie_previousround[1] || zombie3 == g_zombie_previousround[2])
					zombie3 = g_players[random_num(0, iPlayersnum-1)]

				zombieme(zombie3, CLASS_ZOMBIE, 0, 0)
				set_user_health(zombie3, (floatround((g_zclass[g_zombieclass[zombie3]][ZCLASS_HEALTH] + (g_improv_zombie[zombie3][Z_IMPROV_HEALTH] * 225))*get_pcvar_float(cvar_zombiefirsthp))))
			}
		}
		else
			zombieme(id, CLASS_ZOMBIE, 0, 0)

		g_zombie_previousround[0] = zombie
		g_zombie_previousround[1] = zombie2
		g_zombie_previousround[2] = zombie3

		for(id = 1; id <= g_maxplayers; id++)
		{
			if(!g_is_alive[id] || is_zombie(id)) continue
			
			if(fm_get_user_team(id) != ZP_TEAM_CT)
			{
				remove_task(id+TASK_TEAM)
				fm_set_user_team(id, ZP_TEAM_CT)
				fm_user_team_update(id)
			}
		}
		
		set_hudmessage(255, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		
		if(!zombie2)
		{
			ShowSyncHudMsg(0, g_MsgSync, "%s Es el primer zombie!", g_name[zombie])
			show_msgtutor(0, 3.5, 1, "%s Es el primer zombie!", g_name[zombie])
		}
		else {
			ShowSyncHudMsg(0, g_MsgSync, "%s, %s y %s Son los primeros zombies!", g_name[zombie], g_name[zombie2], g_name[zombie3])
			show_msgtutor(0, 3.5, 1, "%s, %s y %s Son los primeros zombies!", g_name[zombie], g_name[zombie2], g_name[zombie3])
		}

		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_INFECTION, 0)
	}

	g_fix_delaymodel = false
	fmCheckHZ()
	fnCheckLastZombie()
}

zombieme(id, class, infector=0, silent=0)
{
	if(!g_is_alive[id]) 
	{
		log_to_file("fix2.log", "name:[%s] - zombie:[%d] - zombies:[%d]- humanos:[%d]- vivo2:[%d] - conectado:[%d]",
		g_name[id], g_zombie[id], g_zombies, g_humans, is_user_alive(id), is_user_connected(id))
		return
	}
	
	if(is_user_valid_connected(infector) && g_zombies >= 3)
	{
		g_infection_level[id] = 0 
		g_infected[id] = true

		remove_task(id+TASK_TEAM)

		if(fm_get_user_team(id) != ZP_TEAM_T)
		{
			fm_set_user_team(id, ZP_TEAM_T)
			fm_user_team_update(id)
		}
		set_task(2.0, "infeccion_efec", id+TASK_INFECTION, _, _, "b")
		infeccion_efec(id+TASK_INFECTION)
		set_user_nvg(id)
		
		set_user_rendering(id, kRenderFxGlowShell, 50, 255, 50, kRenderNormal, 70)

		if(!silent)
		{
			set_hudmessage(255, 0, 0, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
			ShowSyncHudMsg(0, g_MsgSync, "%s ha sido infectado por %s...", g_name[id], g_name[infector])
		}

		send_status_icon(id, 5.0, "dmg_poison", 0, 200, 0, 1) 
		
		fmCheckHZ()
		fnCheckLastZombie()
		return
	}

	ExecuteForward(g_fwUserInfected_pre, g_fwDummyResult, id, infector)
	
	g_infected[id] = false
	g_zombie[id] = class
	g_human[id] = CLASS_NONE
	g_firstzombie[id] = false
	g_burning_duration[id] = 0
	
	check_class_fixbug(id)
	g_zombieclass[id] = g_zombieclassnext[id]
	
	
	if(is_zombie(id))
	{
		if(!g_zombies && !silent)
		{
			g_firstzombie[id] = true
			set_user_health(id, (floatround((g_zclass[g_zombieclass[id]][ZCLASS_HEALTH] + (g_improv_zombie[id][Z_IMPROV_HEALTH] * 225))*get_pcvar_float(cvar_zombiefirsthp))))
		}
		else
			set_user_health(id, (g_zclass[g_zombieclass[id]][ZCLASS_HEALTH] + (g_improv_zombie[id][Z_IMPROV_HEALTH] * 225)))
			
		if(!silent)
		{
			set_hudmessage(255, 0, 0, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
			ShowSyncHudMsg(0, g_MsgSync, "%s se ha combertido en zombie", g_name[id])
			emit_sound(id, CHAN_VOICE, zombie_infect[random_num(0, charsmax(zombie_infect))], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	else if(is_assassin(id))
	{
		set_user_health(id, (490*(g_humans+1)))
	}
	else if(is_nemesis(id))
	{
		if(g_synapsisround)
			set_user_health(id, (1200*(g_humans+1)))
		else if(g_plagueround)
			set_user_health(id, (750*(g_humans+1)))
		else
			set_user_health(id, (1250*(g_humans+1)))
	}
	
	remove_task(id+TASK_TEAM)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_BURN)
	
	del_aura(id)
	
	if(fm_get_user_team(id) != ZP_TEAM_T)
	{
		fm_set_user_team(id, ZP_TEAM_T)
		fm_user_team_update(id)
	}

	static already_has_model
	already_has_model = false

	if(is_nemesis(id))
	{
		if(equal(model_nemesis, g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), model_nemesis)

		fm_cs_set_user_model_index(id, model_nemesis_index)
	}
	else if(is_assassin(id))
	{
		if(equal(model_assassin, g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), model_assassin)
			
		fm_cs_set_user_model_index(id, model_assassin_index)
	}
	else
	{
		if(equal(g_zclass[g_zombieclass[id]][ZCLASS_MODEL], g_playermodel[id]))
			already_has_model = true	
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), g_zclass[g_zombieclass[id]][ZCLASS_MODEL])
			
		fm_cs_set_user_model_index(id, g_zclass[g_zombieclass[id]][ZCLASS_MODELID])
	}
	
	if(!already_has_model)
	{
		if(g_newround || g_fix_delaymodel)
			set_task(0.2, "fm_user_model_update", id+TASK_MODEL)
		else
			fm_user_model_update(id+TASK_MODEL)
	}
	
	if(!is_zombie(id))
	{
		set_user_rendering(id, kRenderFxGlowShell, 250, 10, 10, kRenderNormal, 22)
		set_aura(id)
	}
	else
	{
		set_user_rendering(id)
		set_task(0.8, "make_blood", id+TASK_BLOOD, _, _, "b")
	
		set_task(random_float(50.0, 75.0), "zombie_play_idle", id+TASK_BLOOD, _, _, "b")

		set_zgohst(id)
	}

	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	
	set_user_armor(id, 0)
	
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	
	strip_user_weapons(id)
	give_item(id, "weapon_knife")

	infectionFX(id)
	
	set_user_nvg(id)
	
	message_begin(MSG_ONE, g_msgSetFOV, _, id)
	write_byte(110)
	message_end()

	parachute_reset(id)
	remove_grenades(id)
	reset_hud(id)
	turn_off_flashlight(id)
	
	ExecuteForward(g_fwUserInfected_post, g_fwDummyResult, id, infector)
	
	fmCheckHZ()
	fnCheckLastZombie()
}

humanme(id, class)
{
	ExecuteForward(g_fwUserHumanized_pre, g_fwDummyResult, id)

	remove_task(id+TASK_TEAM)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_BURN)
	
	del_aura(id)
	
	g_zombie[id] = CLASS_NONE
	g_human[id] = class
	g_infected[id] = false
	g_firstzombie[id] = false
	g_nodamage[id] = false
	g_canbuy[id] = true
	g_nvision[id] = false
	g_nvisionenabled[id] = false
	g_burning_duration[id] = 0
	
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	
	if(is_survivor(id))
	{
		if(g_survround)
			set_user_health(id, (fnGetAlive()*190))
		else
			set_user_health(id, (fnGetAlive()*140))
		
		give_item(id, "weapon_usp")
		give_item(id, "weapon_mp5navy")
		
		turn_off_flashlight(id)
		set_aura(id)
	}
	else if(is_sniper(id))
	{
		set_user_health(id, (fnGetAlive()*275))

		give_item(id, "weapon_deagle")
		give_item(id, "weapon_awp")

		turn_off_flashlight(id)
		set_aura(id)
	}
	else if(is_civil(id))
	{
		set_user_health(id, 3500)

		give_item(id, "weapon_glock18")
		give_item(id, "weapon_tmp")
	}
	else
	{
		check_class_fixbug(id)

		set_user_health(id, (g_hclass[g_humanclass[id]][HCLASS_HEALTH] + (g_improv_human[id][H_IMPROV_HEALTH] * 25)))
		set_user_armor(id, (g_hclass[g_humanclass[id]][HCLASS_ARMOR] + (g_improv_human[id][H_IMPROV_ARMOR] * 15)))
		
		set_task(0.4, "show_menu_prebuy", id+TASK_SPAWN)
		
		emit_sound(id, CHAN_ITEM, sound_antidote, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		set_hudmessage(0, 0, 255, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%s ha usado un antidoto...", g_name[id])
	}	
	
	if(fm_get_user_team(id) != ZP_TEAM_CT)
	{
		fm_set_user_team(id, ZP_TEAM_CT)
		fm_user_team_update(id)
	}
		
	static already_has_model
	already_has_model = false
	
	if(is_survivor(id))
	{
		if(equal(model_survivor, g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), model_survivor)
	}
	else if(is_sniper(id))
	{
		if(equal(model_sniper, g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), model_sniper)
	}
	else if(is_civil(id))
	{
		if(equal("OA_Alice_Murray", g_playermodel[id]))
			already_has_model = true
		else
			copy(g_playermodel[id], charsmax(g_playermodel[]), "OA_Alice_Murray")
	}
	else {
		if(get_user_flags(id) & ACCESS_FLAG)
		{
			if(equal(model_admin, g_playermodel[id]))
				already_has_model = true
			else
				copy(g_playermodel[id], charsmax(g_playermodel[]), model_admin)
		}
		else {
			if(equal(g_hclass[g_humanclass[id]][HCLASS_MODEL], g_playermodel[id]))
				already_has_model = true
			else
				copy(g_playermodel[id], charsmax(g_playermodel[]), g_hclass[g_humanclass[id]][HCLASS_MODEL])
		}
	}
	
	if(!already_has_model)
	{
		if(g_newround || g_fix_delaymodel)
			set_task(0.5, "fm_user_model_update", id+TASK_MODEL)
		else
			fm_user_model_update(id+TASK_MODEL)
	}

	fm_cs_set_user_model_index(id, default_model_index)

	if(is_survivor(id) || is_sniper(id))
	{
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 25)
		set_user_nvg(id)
	}
	else if(!g_frozen[id])
		set_user_rendering(id)
	
	parachute_reset(id)
	remove_grenades(id)
	reset_hud(id)

	message_begin(MSG_ONE, g_msgSetFOV, _, id)
	write_byte(90)
	message_end()

	ExecuteForward(g_fwUserHumanized_post, g_fwDummyResult, id)
	
	fmCheckHZ()
	fnCheckLastZombie()
}

/*================================================================================
[Client Commands]
=================================================================================*/
public newmenu_back(id)
{
	if(!g_is_connected[id]) return
	
	static util[3]
	player_menu_info(id, util[0], util[1], util[2])
	if(!util[0] || util[1] < 0) return
		
	play_soundmenu(id, SOUNDMENU_BACK)
}

public newmenu_next(id)
{
	if(!g_is_connected[id]) return
	
	static util[3]
	player_menu_info(id, util[0], util[1], util[2])
	if(!util[0] || util[1] < 0) return
		
	play_soundmenu(id, SOUNDMENU_NEXT)
}

public clcmd_buy(id)
	menu_game(id, 1, 0, 0)
	
public clcmd_buyequip(id)
	menu_game(id, 2, 0, 0)

public clcmd_saymenu(id)
{
	show_menu_game(id)
}

public clcmd_nvgtoggle(id)
{
	if (g_nvision[id])
	{
		g_nvisionenabled[id] = !(g_nvisionenabled[id])
		set_nvg(id)

		if(!is_any_zombie(id)) return PLUGIN_HANDLED

		if(g_nvisionenabled[id]) client_cmd(id, "spk %s", sound_nvgon)
		else client_cmd(id, "spk %s", sound_nvgoff)

		message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
		write_short(UNIT_SECOND*4) // duration
		write_short(UNIT_SECOND*1) // hold time
		write_short(FFADE_IN) // fade type
		write_byte(5) // r
		write_byte(5) // g
		write_byte(5) // b
		write_byte(245) // alpha
		message_end()
	}
	return PLUGIN_HANDLED
}

public clcmd_drop(id)
{
	if(!is_human(id))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public clcmd_buyammo(id)
	return PLUGIN_HANDLED

public clcmd_changeteam(id)
{
	if(g_loading[id])
	{
		zp_center_print(id, "Cargando...")
		return PLUGIN_HANDLED
	}
	if(g_login_error[id])
	{
		zp_center_print(id, "Error al cargar los datos.")
		return PLUGIN_HANDLED
	}

	static Team; Team = fm_get_user_team(id)
	if((Team == 0 || Team == 3) && g_login[id] && g_valid_email[id])
		return PLUGIN_CONTINUE
	else if(!g_login[id])
		show_menu_login(id)
	else if(!g_valid_email[id])
		client_cmd(id, "messagemode E-MAIL")
	else {
		show_menu_game(id)
		client_cmd(id, "spk %s", sound_openmenu)
	}

	return PLUGIN_HANDLED
}

/*================================================================================
[Login/Create Account  -- Load/Save MySQL]
=================================================================================*/
public show_menu_login(id)
{ 
	new tiempo = time()
	if(!g_login[id] && !g_is_banned[id])
	{
		if(g_registered[id])
		{
			static str_time[16], str_time2[10]
			format_time(str_time, 15, "%d/%m/%Y", g_timelast[id])
			format_time(str_time2, 9, "%H:%M", g_timelast[id])
			formatex(g_item, charsmax(g_item), "\rOnly-Arg: Zombie-Evil ^n\yBienvenido \d%s\y.^nTu ultima visita fue: ^nEl dia \d%s \ya las \d%s",
			g_name[id], str_time, str_time2)
		}
		else
			formatex(g_item, charsmax(g_item), "\yMenu de Login/Registro")

		new Menu = menu_create(g_item, "menu_login")

		formatex(g_item, charsmax(g_item), "%sEntrar", g_registered[id]?"\w":"\d")
		menu_additem(Menu, g_item, "1", 0)
		formatex(g_item, charsmax(g_item), "%sCrear Cuenta", g_registered[id]?"\d":"\w")
		menu_additem(Menu, g_item, "2", 0)

		menu_setprop(Menu,MPROP_EXITNAME,"Salir")
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)

		menu_display(id, Menu, 0)
		g_login[id] = false
	}
	else if(g_is_banned[id])
	{
		new horas, minutos, segundos
		segundos = (g_ban_expire[id] - tiempo)

		while(segundos >= 3600) {
			horas++
			segundos -= 3600
		}
		while(segundos >= 60) {
			minutos++
			segundos -= 60
		}
		zp_colored_print(id, "!g[Z-Evil]!tEsta cuenta se desbaneara en !y%d !tHoras !y%d !tMinutos!y %d !tsegundos.", horas, minutos, segundos)
		zp_colored_print(id, "!g[Z-Evil]!tTipea !y/razon !tpara ver la razon del ban.")
	}
}

/*=================================================================================*/
public menu_login(id, menu, item)
{ 
	if(item == MENU_EXIT || g_is_banned[id] || g_login[id])
	{ 
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED 
	} 

	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0]) 

	switch(str_to_num(g_menu_slot))
	{
		case 1: {
			if(g_registered[id]) {
				client_cmd(id, "messagemode ingresar_password")
				play_soundmenu(id, SOUNDMENU_SELECT)
			}
			else
				show_menu_login(id)
		}
		case 2: {
			if(!g_registered[id]) {
				client_cmd(id, "messagemode _password")
				play_soundmenu(id, SOUNDMENU_SELECT)
			}
			else
				show_menu_login(id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED 
} 

public crear_cuenta(id)
{
	if(g_loading[id] || g_login[id] || g_is_banned[id])
		return PLUGIN_HANDLED
		
	if(g_registered[id])
	{
		zp_colored_print(id, "!g [Z-Evil]!tLa cuenta Ya Existe... Por Favor Inserte el password de su cuenta")
		show_msgtutor(id, 3.5, 3, "La cuenta Ya Existe...^nPor Favor Inserte el password ^nde su cuenta")
		client_cmd(id, "messagemode ingresar_password");
		return PLUGIN_HANDLED
	}
	
	static insert[33]
	
	read_args(util_password, charsmax(util_password))
	remove_quotes(util_password)
	trim(util_password)

	if(!util_password[0])
	{
		show_menu_login(id)
		insert[id] = false
		return PLUGIN_HANDLED
	}
	
	if(containi(util_password, "^"") != -1)
	{
		show_msgtutor(id, 3.5, 3, "La password no puede contener ^".")
		zp_colored_print(id, "!g [Z-Evil]!t La password no puede contener!y ^" !t.")
		client_cmd(id, "messagemode _password")
		insert[id] = false
		return PLUGIN_HANDLED
	}
	
	if(contain(util_password, " ") != -1)
	{
		show_msgtutor(id, 3.5, 3, "La password debe ser 1 (una) palabra")
		zp_colored_print(id, "!g [Z-Evil]!t La password debe ser 1 (una) palabra")
		client_cmd(id, "messagemode _password")
		insert[id] = false
		return PLUGIN_HANDLED
	}

	if(insert[id])
	{
		if(equali(util_password, g_temp_password[id]))
		{
			copy(g_password[id], charsmax(g_password[]), util_password)
			g_registered[id] = true
			g_login[id] = true
			SaveCuenta(id, 1)
			min_players()
			clcmd_changeteam(id)
			show_msgtutor(id, 3.5, 3, "Has sido registrado!.")
			zp_colored_print(id, "!g [Z-Evil]!t Has sido registrado!.!g Nick:!y %s!t - !gPassword:!y %s", g_name[id], g_password[id])
			client_cmd(id, "spk buttons/button3.wav")
		}
		else
		{
			show_msgtutor(id, 3.5, 3, "Las passwords no coinciden")
			zp_colored_print(id, "!g [Z-Evil]!t Las passwords no coinciden")
			client_cmd(id, "messagemode _password")
			client_cmd(id, "spk buttons/button2.wav")
			insert[id] = false
		}
	}
	else
	{
		copy(g_temp_password[id], charsmax(g_temp_password[]), util_password)
		insert[id] = true
		client_cmd(id, "messagemode confirmar_password")
	}
	
	return PLUGIN_CONTINUE
}
/*=================================================================================*/
public login(id)
{
	if(g_loading[id] || g_login[id] || !g_registered[id] || g_is_banned[id])
		return PLUGIN_HANDLED

	read_args(util_password, charsmax(util_password))
	remove_quotes(util_password)
	trim(util_password)

	if(!util_password[0])
	{
		show_menu_login(id)
		return PLUGIN_HANDLED
	}

	if(equali(g_password[id], util_password))
	{ 
		show_msgtutor(id, 3.5, 3, "Password aceptada.^nBienvenido %s", g_name[id])
		zp_colored_print(id, "!g [Z-Evil]!t Password Aceptada")
		zp_center_print(id, "Login Exitoso!")
		
		g_login[id] = true
		min_players()
		
		if(g_valid_email[id])
		{
			force_jointeam(id)
			if(g_send_email[id] != 7)
				send_email(id, 7, "Bienvenido a Only-Arg Zombie-Evil.^nNo olvides pasar por el foro.^n^nhttp://www.onlyarg.com/foro")
		}
		else {
			client_cmd(id, "messagemode E-MAIL")
			show_msgtutor(id, 3.5, 3, "Ingrese su E-MAIL. ^n^nEs muy inportante para participar en ^npromociones y recuperar la cuenta en caso de robo.")
			zp_colored_print(id, "!g [Z-Evil]!t Ingrese su E-MAIL.Es muy inportante para participar en promociones y recuperar la cuenta en caso de robo.")
		}
		client_cmd(id, "spk buttons/button3.wav")
	} 
	else {
		if(!g_login_attempts[id])
		{
			server_cmd("kick #%d ^"Las password ingresadas no son correctas.^nSi olvidaste tu password comunicate en el FORO(onlyarg.com).^"", get_user_userid(id))
			return PLUGIN_HANDLED
		}
		
		client_cmd(id, "messagemode ingresar_password")
		
		show_msgtutor(id, 3.5, 3, "Password incorrecta,te quedan %d intentos.", g_login_attempts[id])
		zp_colored_print(id, "!g [Z-Evil]!t Password incorrecta,te quedan !y%d !tintentos.", g_login_attempts[id])
		
		g_login_attempts[id]--
		g_login[id] = false
		
		client_cmd(id, "spk buttons/button2.wav")
	}
	return PLUGIN_HANDLED
}

public change_pw(id)
{
	if(!g_login[id])
		return PLUGIN_HANDLED
		
	read_args(util_password, charsmax(util_password))
	remove_quotes(util_password)
	trim(util_password)

	if(!util_password[0])
	{
		g_new_password_status[id] = 0
		return PLUGIN_HANDLED
	}

	if(containi(util_password, "^"") != -1)
	{
		show_msgtutor(id, 3.5, 3, "La password no puede contener ^".")
		zp_colored_print(id, "!g [Z-Evil]!t La password no puede contener!y ^" !t.")
		client_cmd(id, "messagemode vieja_password")
		g_new_password_status[id] = 0
		return PLUGIN_HANDLED
	}
	if(contain(util_password, " ") != -1)
	{
		zp_colored_print(id, "!g [Z-Evil]!y La password debe ser 1 (una) palabra")
		g_new_password_status[id] = 0
		client_cmd(id, "messagemode vieja_password")
		return PLUGIN_HANDLED
	}

	if(!g_new_password_status[id] && equali(g_password[id], util_password))
	{
		g_new_password_status[id] = 1
		client_cmd(id, "messagemode nueva_password")
	}
	else if(!g_new_password_status[id])
	{
		client_cmd(id, "messagemode vieja_password")
		zp_colored_print(id, "!g [Z-Evil]!t Password incorrecta") 
		client_cmd(id, "spk buttons/button2.wav")
	}
	else if(g_new_password_status[id] == 1)
	{
		copy(g_temp_password[id], charsmax(g_temp_password[]), util_password)
		g_new_password_status[id] = 2
		client_cmd(id, "messagemode confirmar_nueva_password")
	}
	else if(g_new_password_status[id] == 2 && equali(g_temp_password[id], util_password))
	{
		g_new_password_status[id] = 0
		copy(g_password[id], charsmax(g_password[]), util_password)
		SaveCuenta(id, 0)
		zp_colored_print(id, "!g [Z-Evil]!t Password cambiada con exito!!!.") 
	}
	else if(g_new_password_status[id] == 2)
	{
		zp_colored_print(id, "!g [Z-Evil]!t Las Passwords no coinciden")
		g_new_password_status[id] = 0
		client_cmd(id, "messagemode vieja_password")
		client_cmd(id, "spk buttons/button2.wav")
	}
	return PLUGIN_HANDLED
}

public set_email(id)
{
	if(!g_login[id] || g_valid_email[id]) return PLUGIN_HANDLED
	
	new say[40]

	read_args(say, charsmax(say))
	remove_quotes(say)
	trim(say)

	if(!say[0])
		return PLUGIN_HANDLED

	new email[39]
	copy(email, charsmax(email), say)
	remove_quotes(email)

	if(containi(email, "^"") != -1)
	{
		zp_colored_print(id, "!g [Z-Evil]!t El E-Mail no puede contener!y ^" !t.")
		client_cmd(id, "messagemode E-MAIL")
		client_cmd(id, "spk buttons/button2.wav")
	}
	else if(!valid_email(email))
	{
		zp_colored_print(id, "!g [Z-Evil]!t El E-Mail no es valido.")
		client_cmd(id, "messagemode E-MAIL")
		client_cmd(id, "spk buttons/button2.wav")
	}
	else {
		client_cmd(id, "spk buttons/button3.wav")
		zp_colored_print(id, "!g [Z-Evil]!t E-Mail registrado,para cambiar de E-Mail comuniquese con el aministrador.")
		g_valid_email[id] = true
		Save_small(id, "email=^"%s^"", email)
		force_jointeam(id)
	}
	return PLUGIN_HANDLED
}

LoadCuenta(id)
{
	if(!g_is_connected[id] || sql_stop2())
		return
	static szQuery[128], iData[1]

	formatex(szQuery, charsmax(szQuery), 
	"SELECT * FROM `cuentas_30` WHERE ( `nick` LIKE ^"%s^" );",
	g_name[id])
	iData[0] = id
	SQL_ThreadQuery(g_hTuple, "QuerySelectData", szQuery, iData, 1)
}
/*=================================================================================*/

public QuerySelectData(iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iDataSize, Float:fQueueTime )
{
	if(sql_stop2())
		return PLUGIN_CONTINUE 

	static id;id = iData[0]
	if(iFailState == TQUERY_CONNECT_FAILED || iFailState == TQUERY_QUERY_FAILED || iFailState != TQUERY_SUCCESS)
	{
		static error[256]
		formatex(error, 255, "load: %s", szError)
		log_to_file("mysql.log", error)
		if(g_login_error[id] < 5)
		{
			zp_center_print(id, "Error al cargar los datos,Reintentando")
			g_loading[id] = true
			load_cuenta_task(id)
			g_login_error[id]++
		}
		return PLUGIN_CONTINUE 
	}

	static ColPass, Col_ap, Col_level, Col_reset, Col_pun_mej_h, Col_pun_mej_z, Col_class, Col_mision, Col_wm,
	Col_hud, Col_colores, Col_timelast, Col_kills, Col_ban, Col_email, Col_send_email, Col_user_id,
	Col_timeonline, Col_hid
	static str_pun_mej_h[31], str_pun_mej_z[31], str_mision[31], str_hud[31], str_colores[7],
	str_class[7], i, str_wm[75], str_hid[90], str_kills[31]

	ColPass = SQL_FieldNameToNum(hQuery, "password")
	Col_user_id = SQL_FieldNameToNum(hQuery, "user_id")
	Col_ap = SQL_FieldNameToNum(hQuery, "ap")
	Col_level = SQL_FieldNameToNum(hQuery, "level")
	Col_reset = SQL_FieldNameToNum(hQuery, "reset")
	Col_class = SQL_FieldNameToNum(hQuery, "class")
	Col_pun_mej_h = SQL_FieldNameToNum(hQuery, "pun_mej_h")
	Col_pun_mej_z = SQL_FieldNameToNum(hQuery, "pun_mej_z")
	Col_mision = SQL_FieldNameToNum(hQuery, "mision")
	Col_wm = SQL_FieldNameToNum(hQuery, "w_mejoras")
	Col_hud = SQL_FieldNameToNum(hQuery, "hud")
	Col_colores = SQL_FieldNameToNum(hQuery, "colores")

	Col_timelast = SQL_FieldNameToNum(hQuery, "timelast")
	Col_kills = SQL_FieldNameToNum(hQuery, "kills")
	Col_ban = SQL_FieldNameToNum(hQuery, "ban")
	Col_timeonline = SQL_FieldNameToNum(hQuery, "timeonline")

	static Col_regalar_ap, str_regalar_ap[13]
	Col_regalar_ap = SQL_FieldNameToNum(hQuery, "regalar_ap")

	Col_email = SQL_FieldNameToNum(hQuery, "email")
	Col_send_email = SQL_FieldNameToNum(hQuery, "send_email")
	
	Col_hid = SQL_FieldNameToNum(hQuery, "lasts_hid")

	if(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery, ColPass, g_password[id], charsmax(g_password[]))

		g_user_id[id] = SQL_ReadResult(hQuery, Col_user_id)
		g_ammopacks[id] = SQL_ReadResult(hQuery, Col_ap)
		g_level[id] = SQL_ReadResult(hQuery, Col_level)
		g_reset_level[id] = SQL_ReadResult(hQuery, Col_reset)

		SQL_ReadResult(hQuery, Col_class, str_class, 6)
		SQL_ReadResult(hQuery, Col_pun_mej_h, str_pun_mej_h, 30)
		SQL_ReadResult(hQuery, Col_pun_mej_z, str_pun_mej_z, 30)
		SQL_ReadResult(hQuery, Col_mision, str_mision, 30)
		SQL_ReadResult(hQuery, Col_wm, str_wm, 74)
		SQL_ReadResult(hQuery, Col_hud, str_hud, 30)
		SQL_ReadResult(hQuery, Col_colores, str_colores, 6)
		SQL_ReadResult(hQuery, Col_hid, str_hid, 89)
		SQL_ReadResult(hQuery, Col_kills, str_kills, 30)

		g_timelast[id] = SQL_ReadResult(hQuery, Col_timelast)

		g_ban_expire[id] = SQL_ReadResult(hQuery, Col_ban)
		g_timeonline[id] = SQL_ReadResult(hQuery, Col_timeonline)
		SQL_ReadResult(hQuery, Col_regalar_ap, str_regalar_ap, 12)

		SQL_ReadResult(hQuery, Col_email, g_email[id], 39)
		g_send_email[id] = SQL_ReadResult(hQuery, Col_send_email)

		g_registered[id] = true
		SQL_NextRow(hQuery)
	}
	g_loading[id] = false
	g_login_error[id] = 0

	g_is_banned[id] = (g_ban_expire[id] > time())
	set_task(0.2, "clcmd_changeteam", id)
	
	if(!g_registered[id])
		return PLUGIN_CONTINUE

	if(valid_email(g_email[id]))
		g_valid_email[id] = true
		
	if(!g_is_banned[id])
	{
		static pw_md5[2][34]
		get_user_info(id, setinfo_md5key, pw_md5[0], charsmax(pw_md5[]))
	
		md5(g_password[id], pw_md5[1])
		pw_md5[0][8]='^0';pw_md5[1][8]='^0'
	
		if(equal(pw_md5[0], pw_md5[1]))
		{
			zp_center_print(id, "Auto Login Exitoso!")
			g_login[id] = true
			min_players()
			if(g_valid_email[id])
			{
				force_jointeam(id)
				if(g_send_email[id] != 7) {
					send_email(id, 7, "Bienvenido a Only-Arg zombie-evil.^nNo olvides pasar por el foro.^n^nhttp://www.onlyarg.com/foro")
				}
			}
			else {
				client_cmd(id, "messagemode E-MAIL")
				show_msgtutor(id, 3.5, 3, "Ingrese su E-Mail. ^n^nEs necesario para partisipar en ^npromosiones y recuperar cuenta robada.")
			}
		}
	}

	parse(str_hid, g_hid[id][0], 19, g_hid[id][1], 19, g_hid[id][2], 19, g_hid[id][3], 19)
	insert_lasthid(id)
	
	new pts_mejoras[2][7], mision[2+MAX_KILLS], w_mejoras[20], class[2], colores[3], hud[6], regalar_ap[3]
	
	str_to_arraynum(str_pun_mej_h, pts_mejoras[0], 6)
	str_to_arraynum(str_pun_mej_z, pts_mejoras[1], 5)
	str_to_arraynum(str_mision, mision, 1+MAX_KILLS)
	str_to_arraynum(str_wm, w_mejoras, 19)
	str_to_arraynum(str_class, class, 1)
	str_to_arraynum(str_colores, colores, 2)
	str_to_arraynum(str_hud, hud, 5)
	str_to_arraynum(str_regalar_ap, regalar_ap, 2)
	str_to_arraynum(str_kills, g_kills[id], MAX_KILLS-1)

	g_points[id][TEAM_HUMAN] = pts_mejoras[TEAM_HUMAN][0]
	g_points[id][TEAM_ZOMBIE] = pts_mejoras[TEAM_ZOMBIE][0]
	g_points_spent[id][TEAM_HUMAN] = pts_mejoras[TEAM_HUMAN][1]
	g_points_spent[id][TEAM_ZOMBIE] = pts_mejoras[TEAM_ZOMBIE][1]

	g_mission[id][0] = mision[0]
	g_mission[id][1] = mision[1]

	g_humanclass[id] = class[0]
	g_zombieclassnext[id] = class[1]

	g_nvg_color[id] = colores[0]
	g_flare_color[id] = colores[1]
	g_autonvg[id] = colores[2]

	g_donate_limit[id][2] = regalar_ap[0]
	g_donate_limit[id][0] = regalar_ap[1]
	g_donate_limit[id][1] = regalar_ap[2]

	for(i = 0; i < MAX_IMPROV_HUMAN; i++)
	{
		g_improv_human[id][i] = pts_mejoras[0][i+2]
		g_mejoras[id][0][i] = g_improv_human[id][i]
	}
	for(i = 0; i < MAX_IMPROV_ZOMBIE; i++)
	{
		g_improv_zombie[id][i] = pts_mejoras[1][i+2]
		g_mejoras[id][1][i] = g_improv_zombie[id][i]
	}
	for(i = 0; i < MAX_KILLS; i++)
		g_mission_progress[id][i] = mision[i+2]

	for(i = 0; i < 2; i++) {
		hud_color[id][i] = hud[i]
		hud_posicion[id][0][i] = hud[i+2]/100.0
		if(hud_posicion[id][0][i] > 0.95)
			hud_posicion[id][0][i] = 0.95

		if(hud_posicion[id][0][i] < 0.0)
			hud_posicion[id][0][i] = 0.0

		hud_posicion[id][1][i] = hud[i+4]/100.0

		if(hud_posicion[id][1][i] > 0.95)
			hud_posicion[id][1][i] = 0.95

		if(hud_posicion[id][1][i] < 0.0)
			hud_posicion[id][1][i] = 0.0
	}

	new j, k
	for(i = 0; i < 20; i++) {
		if(i < 2)
			g_weapons_puntos[id][i] = w_mejoras[i]
		else {
			g_weapons_mejoras[id][k][j++] = w_mejoras[i]
			if(j > 2) {
				j = 0;k++
			}
		}	
	}

	new f
	while(g_ammopacks[id] >= NIVELES((f+1)))
		f++
	g_level[id] = f

	if(g_donate_limit[id][2] != g_dia)
	{
		g_donate_limit[id][0] = 0
		g_donate_limit[id][1] = 0
		g_donate_limit[id][2] = g_dia
	}

	if(g_ammopacks[id] < 0 || g_level[id] < 0) {
		log_to_file("malditos2.log", "name:[%s], aps:[%d], level:[%d]", g_name[id], g_ammopacks[id], g_level[id])
		g_ammopacks[id] = 0
		g_level[id] = 0
	}

	return PLUGIN_CONTINUE 
}
/*=================================================================================*/
SaveCuenta(id, primera)
{
	if(!g_login[id] || sql_stop())
		return
	
	if(g_ammopacks[id] < 0 || g_level[id] < 0)
	{
		log_to_file("malditos.log", "name:[%s], aps:[%d], level:[%d]", g_name[id], g_ammopacks[id], g_level[id])
		return
	}

	static szQuery[650]
	new str_pun_mej_h[31], str_pun_mej_z[31], str_mision[31], str_hud[31], str_colores[6], str_class[6], str_wm[75], str_regalar_ap[13], str_kills[31]
	static int_time, len;len = 0;
	int_time = time()

	formatex(str_pun_mej_h, 30, "%d %d %d %d %d %d %d", g_points[id][TEAM_HUMAN], g_points_spent[id][TEAM_HUMAN], g_improv_human[id][H_IMPROV_DAMAGE], g_improv_human[id][H_IMPROV_HEALTH], g_improv_human[id][H_IMPROV_ARMOR],
	g_improv_human[id][H_IMPROV_VELOCITY], g_improv_human[id][H_IMPROV_GRAVITY])
	
	formatex(str_pun_mej_z, 30, "%d %d %d %d %d %d", g_points[id][TEAM_ZOMBIE], g_points_spent[id][TEAM_ZOMBIE], g_improv_zombie[id][Z_IMPROV_DAMAGE], g_improv_zombie[id][Z_IMPROV_HEALTH], g_improv_zombie[id][Z_IMPROV_VELOCITY],
	g_improv_zombie[id][Z_IMPROV_GRAVITY])

	formatex(str_hud, 30, "%d %d %d %d %d %d", hud_color[id][0], hud_color[id][1],
	floatround(hud_posicion[id][0][0]*100), floatround(hud_posicion[id][0][1]*100), floatround(hud_posicion[id][1][0]*100), floatround(hud_posicion[id][1][1]*100))
	formatex(str_colores, 5, "%d %d %d", g_nvg_color[id], g_flare_color[id], g_autonvg[id])
	formatex(str_class, 5, "%d %d", g_humanclass[id], g_zombieclassnext[id])
	formatex(str_regalar_ap, 12, "%d %d %d", g_donate_limit[id][2], g_donate_limit[id][0], g_donate_limit[id][1])
	
	len = formatex(str_mision, 30, "%d %d", g_mission[id][0], g_mission[id][1])
	new len2
	for(new k; k < MAX_KILLS; k++)
	{
		len += formatex(str_mision[len], 30-len, " %d", g_mission_progress[id][k])
		len2 += formatex(str_kills[len2], 30-len2, "%d ", g_kills[id][k])
	}
	
	len = formatex(str_wm, 74, "%d %d", g_weapons_puntos[id][0], g_weapons_puntos[id][1])
	for(new k; k < 6; k++)
		len += formatex(str_wm[len], 74-len, " %d %d %d", g_weapons_mejoras[id][k][0], g_weapons_mejoras[id][k][1], g_weapons_mejoras[id][k][2])

	if(primera)
	{
		format(szQuery, charsmax(szQuery), "REPLACE INTO `cuentas_30` (`nick`, `password`, `ap`, `level`, `class`, `pun_mej_h`, `pun_mej_z`, `mision`, `w_mejoras`, `hud`, `colores`, `time_create`, `firstpw`, `firsthid`, `timelast`) \
		VALUES (^"%s^", ^"%s^", '%d', '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%d', ^"%s^", ^"%s^", '%d');",
		g_name[id], g_password[id] , g_ammopacks[id], g_level[id], str_class, str_pun_mej_h, str_pun_mej_z, str_mision, str_wm, str_hud, str_colores, int_time, g_password[id], g_hid[id][0], int_time)
	}
	else {
		static str_hid[90]
		formatex(str_hid, 89, "%s %s %s %s", g_hid[id][0], g_hid[id][1], g_hid[id][2], g_hid[id][3])

		format(szQuery, charsmax(szQuery), "UPDATE `cuentas_30` SET password=^"%s^", ap='%d', level='%d', reset='%d', class='%s', pun_mej_h='%s', pun_mej_z='%s', mision='%s', w_mejoras='%s', hud='%s', colores='%s', \
		timelast='%d', timeonline='%d', last_ip='%s', lasts_hid=^"%s^", kills='%s', regalar_ap='%s' WHERE( `nick` LIKE ^"%s^" );",
		g_password[id], g_ammopacks[id], g_level[id], g_reset_level[id], str_class, str_pun_mej_h, str_pun_mej_z, str_mision, str_wm, str_hud, str_colores, int_time, g_timeonline[id], g_ip[id], str_hid, str_kills, str_regalar_ap, g_name[id])
	}
	new iData[1]
	iData[0] = id

	SQL_ThreadQuery(g_hTuple, "QueryHandle", szQuery, iData, 1)
}

insert_lasthid(id)
{
	new hid[20]
	get_user_info(id, "*HID", hid, 19)

	if(equal(g_hid[id][0], hid))
		return
		
	copy(g_hid[id][3], 19, g_hid[id][2])
	copy(g_hid[id][2], 19, g_hid[id][1])
	copy(g_hid[id][1], 19, g_hid[id][0])
	copy(g_hid[id][0], 19, hid)
}

/*=================================================================================*/
public QueryHandle(iFailState, Handle:hQuery, szError[], iErrnum, iData[], iSize, Float:fQueueTime)
{
	if(iFailState == TQUERY_CONNECT_FAILED || iFailState == TQUERY_QUERY_FAILED || iFailState != TQUERY_SUCCESS)
	{
		static error[256]
		formatex(error, 255, "set data: %s ^n", szError)
		log_to_file("mysql.log", error)
		if(containi(szError, "Too many") != -1)
		{
			new id = iData[0]
			SaveCuenta(id, 0)
		}
	}

	return PLUGIN_CONTINUE
}

/*=================================================================================*/
Save_small(id, datos[], any:...)
{
	if(g_login[id] && !sql_stop())
	{
		new szQuery[150], iData[1], data[96]
		vformat(data, 95, datos, 3)
		format(szQuery, 149, "UPDATE `cuentas_30` SET %s WHERE( nick LIKE ^"%s^" );", data, g_name[id])
		iData[0] = id
		SQL_ThreadQuery(g_hTuple, "QueryHandle", szQuery, iData, 1)
	}
}

/*=================================================================================*/
public load_cuenta_task(id)
{
	if(sql_stop2())
		return
		
	load_cuenta_task2(id+TASK_LOAD)
}

public load_cuenta_task2(id)
{
	id -= TASK_LOAD
	LoadCuenta(id)
}

public plugin_end()
{
	if(!g_sql_stop)
	{
		g_sql_stop = true
		SQL_FreeHandle(g_hTuple)
	}
	
	game_disableForwards()
}

sql_stop()
{
	if(g_sql_stop) return 1
	
	return 0
}

sql_stop2() {
	if(g_sql_stop)
		return 1

	if(get_timeleft() < 15)
		return 1

	return 0
}

public event_intermission()
{
	for(new i = 0; i <= g_maxplayers; i++)
	{
		if(g_is_connected[i] && g_login[i])
		{
			g_timeonline[i] += get_user_time(i, 1)
			SaveCuenta(i, 0)
		}
	}

	if(!g_sql_stop) {
		g_sql_stop = true
		SQL_FreeHandle(g_hTuple)
	}
}

/*================================================================================
[Custom Natives]
=================================================================================*/

public native_get_user_zombie(id)
	return is_any_zombie(id)

public native_get_user_nemesis(id)
	return is_nemesis(id)

public native_get_user_assassin(id)
	return is_assassin(id)

public native_get_user_sniper(id)
	return is_sniper(id)

public native_get_user_survivor(id)
	return is_survivor(id)

public native_get_user_first_zombie(id)
	return g_firstzombie[id]

public native_get_user_last_zombie(id)
	return g_lastzombie[id]

public native_get_user_last_human(id)
	return g_lasthuman[id]

public native_get_user_ammo_packs(id)
	return g_ammopacks[id]
	
public native_get_user_level(id)
	return g_level[id]

public native_set_user_ammo_packs(id, amount)
{
	g_ammopacks[id] = amount
	check_player_level(id)
}

public native_add_user_points(id, team, amount)
{
	if(team == TEAM_HUMAN || team == TEAM_ZOMBIE)
		g_points[id][team] += amount
}

public native_set_user_level(id, amount)
	g_level[id] = amount

public native_respawn_user(id, team)
{
	if (!allowed_respawn(id))
		return 0
	
	g_respawn_as_zombie[id] = (team == ZP_TEAM_ZOMBIE) ? true : false
	
	respawn_player(id+TASK_SPAWN)
	return 1
}

public native_has_round_started()
	return !g_newround

public native_is_nemesis_round()
	return g_nemround

public native_is_assassin_round()
	return g_assaround

public native_is_sniper_round()
	return g_sniperround

public native_is_survivor_round()
	return g_survround

public native_is_swarm_round()
	return g_swarmround

public native_is_plague_round()
	return g_plagueround


public native_register_extra_item(const name[], cost, team, level_min, level_max, limit)
{
	if(g_extraitem_count[ZP_TEAM_ANY] >= sizeof g_extraitem_name) return -1
	
	param_convert(1)
	
	copy(g_extraitem_name[g_extraitem_count[ZP_TEAM_ANY]], charsmax(g_extraitem_name[]), name)
	g_extraitem_cost[g_extraitem_count[ZP_TEAM_ANY]] = cost
	g_extraitem_team[g_extraitem_count[ZP_TEAM_ANY]] = team
	g_extraitem_level[g_extraitem_count[ZP_TEAM_ANY]][0] = level_min
	g_extraitem_level[g_extraitem_count[ZP_TEAM_ANY]][1] = level_max
	g_extraitem_limit[g_extraitem_count[ZP_TEAM_ANY]] = limit
	
	g_extraitem_count[ZP_TEAM_ANY]++
	
	if(team == ZP_TEAM_HUMAN) g_extraitem_count[ZP_TEAM_HUMAN]++
	else if(team == ZP_TEAM_ZOMBIE) g_extraitem_count[ZP_TEAM_ZOMBIE]++
	
	return g_extraitem_count[ZP_TEAM_ANY]-1
}

native_register_extra_item2(const name[], cost, team, level_min, level_max, limit)
{
	if(g_extraitem_count[ZP_TEAM_ANY] >= sizeof g_extraitem_name) return
	
	copy(g_extraitem_name[g_extraitem_count[ZP_TEAM_ANY]], charsmax(g_extraitem_name[]), name)
	g_extraitem_cost[g_extraitem_count[ZP_TEAM_ANY]] = cost
	g_extraitem_team[g_extraitem_count[ZP_TEAM_ANY]] = team
	g_extraitem_level[g_extraitem_count[ZP_TEAM_ANY]][0] = level_min
	g_extraitem_level[g_extraitem_count[ZP_TEAM_ANY]][1] = level_max
	g_extraitem_limit[g_extraitem_count[ZP_TEAM_ANY]] = limit
	
	g_extraitem_count[ZP_TEAM_ANY]++
	
	if(team == ZP_TEAM_HUMAN) g_extraitem_count[ZP_TEAM_HUMAN]++
	else if(team == ZP_TEAM_ZOMBIE) g_extraitem_count[ZP_TEAM_ZOMBIE]++
}

/*================================================================================
[Stocks]
=================================================================================*/
stock is_solid(ent)
	return ( ent ? ( (entity_get_int(ent, EV_INT_solid) > SOLID_TRIGGER) ? true : false ) : true )

stock make_explode(ent)
	entity_set_float(ent, EV_FL_dmgtime, 0.0)

stock get_current_weapon_ent(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return -1;

	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	//if (pev_valid(ent) != PDATA_SAFE) return -1;

	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock show_msgtutor(const id, Float:time_tutor, color, text[], any:...)
{
	static msg[200]
	vformat(msg, 199, text, 5)
	
	if(id) {
		if(!is_user_valid_connected(id)) return;
		message_begin(MSG_ONE_UNRELIABLE, g_msgTutorText, _, id)
	}
	else message_begin(MSG_BROADCAST, g_msgTutorText)
	write_string(msg)
	write_byte(0)
	write_short(0)
	write_short(0)
	write_short(1<<color)
	message_end()

	client_cmd(id, "spk ^"%s^"", sound_tutor_msg)

	if(time_tutor < 1) time_tutor = 1.0
	
	if(task_exists(id+TASK_MSG_T))
		change_task(id+TASK_MSG_T, time_tutor)
	else
		set_task(time_tutor, "RemoverTutor", id+TASK_MSG_T)
}

public RemoverTutor(id)
{
	id -= TASK_MSG_T
	if(id)
	{
		if(!is_user_valid_connected(id)) return;
		message_begin(MSG_ONE, g_msgTutorClose, _, id)
	}
	else message_begin(MSG_ALL, g_msgTutorClose)
	message_end()
}

stock ammo_level(id, arg)
	return (NIVELES((g_level[id] + arg)))

stock extra_item_cost(id, item)
{
	static div, Float:mult

	if(g_level[id] <= 10)
		return max(1, floatround(g_extraitem_cost[item] * 0.4))
	if(g_level[id] <= 25)
		return max(1, floatround(g_extraitem_cost[item] * 0.6))
	if(g_level[id] <= 50)
		return max(1, floatround(g_extraitem_cost[item] * 0.8))
	if(g_level[id] <= 100)
		return g_extraitem_cost[item]

	switch(g_level[id]) {
		case 101..120: div = 10
		case 121..135: div = 12
		case 136..140: div = 14
		default: div = 14
	}
	mult = float(g_level[id]) / float(div)
	return floatround(g_extraitem_cost[item] * mult + (g_level[id]/8))
}

stock load_spawns()
{
	collect_spawns_ent("info_player_start")
	collect_spawns_ent("info_player_deathmatch")
}

stock collect_spawns_ent(const classname[])
{
	new ent = -1
	while((ent = find_ent_by_class(ent, classname)) > 0) 
	{
		new Float:originF[3]
		entity_get_vector(ent, EV_VEC_origin, originF)
		g_spawns[g_spawnCount][0] = originF[0]
		g_spawns[g_spawnCount][1] = originF[1]
		g_spawns[g_spawnCount][2] = originF[2]
		
		g_spawnCount++
		if(g_spawnCount >= sizeof g_spawns) break;
	}
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0 
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{		
			engclient_cmd(id, "drop", WEAPONENTNAMES[weaponid])
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock is_player_stuck(id)
{
	static Float:originF[3]
	entity_get_vector(id, EV_VEC_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (get_entity_flags(id) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock fm_set_user_deaths(id, value)
{
	set_pdata_int(id, OFFSET_CSDEATHS, value, OFFSET_LINUX)
}

stock fm_get_user_team(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return ZP_TEAM_UNASSIGNED

	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

stock fm_set_user_team(id, team)
{
	if (pev_valid(id) != PDATA_SAFE)
		return

	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX)
}

public fm_set_user_team_msg(id)
{
	id -= TASK_TEAM
	g_switchingteam = true
	
	emessage_begin(MSG_ALL, g_msgTeamInfo)
	ewrite_byte(id)
	ewrite_string(TEAMNAMES[fm_get_user_team(id)])
	emessage_end()
	
	g_switchingteam = false
}

stock fm_user_team_update(id)
{
	static Float:current_time
	current_time = get_gametime()
	
	if(current_time - g_teams_targettime >= 0.1)
	{
		set_task(0.1, "fm_set_user_team_msg", id+TASK_TEAM)
		g_teams_targettime = current_time + 0.1
	}
	else
	{
		set_task((g_teams_targettime + 0.1) - current_time, "fm_set_user_team_msg", id+TASK_TEAM)
		g_teams_targettime = g_teams_targettime + 0.1
	}
}

public fm_set_user_model(id)
{
	id -= TASK_MODEL
	set_user_info(id, "model", g_playermodel[id])
}

public fm_user_model_update(taskid)
{
	static Float:current_time
	current_time = get_gametime()
	
	if(current_time - g_models_targettime >= g_modelchange_delay)
	{
		fm_set_user_model(taskid)
		g_models_targettime = current_time
	}
	else
	{
		if(g_is_alive[(taskid-TASK_MODEL)])
			fm_cs_set_fast_model((taskid-TASK_MODEL))

		set_task((g_models_targettime + g_modelchange_delay) - current_time, "fm_set_user_model", taskid)
		g_models_targettime = g_models_targettime + g_modelchange_delay
	}
}

stock fm_cs_set_fast_model(id)
{
	static info[64]
	format(info, 63, "\name\%s\model\%s\", g_name[id], g_playermodel[id])
		
	static origin[3]
	get_user_origin(id, origin)
			
	message_begin(MSG_PVS, SVC_UPDATEUSERINFO, origin, 0)
	write_byte(id-1) 
	write_long(get_user_userid(id))
	write_string(info)
	write_long(0)
	write_long(0)
	write_long(0)
	write_long(0)
	message_end()
}

stock fm_cs_set_user_model_index(id, modelindex)
{
	if (pev_valid(id) != PDATA_SAFE)
		return
	
	set_pdata_int(id, OFFSET_MODELINDEX, modelindex)
}

stock log_kill(killer, victim)
{
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, killer, 2)
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
	
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(killer)
	write_byte(victim)
	write_byte(0)
	write_string("grenade")
	message_end()
}

stock force_jointeam(id)
{
	set_msg_block(g_msgVGUIMenu, BLOCK_SET)
	set_msg_block(g_msgShowMenu, BLOCK_SET)
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "5")
	set_msg_block(g_msgVGUIMenu, BLOCK_NOT)
	set_msg_block(g_msgShowMenu, BLOCK_NOT)
}

stock str_to_arraynum(sznum[], output[], len)
{
	new i, j, k, c, temp[6], end = strlen(sznum)
	
	for(i = 0; i <= end; i++)
	{
		if(sznum[i] == ' ' || i == end)
		{
			output[j++] = str_to_num(temp)
			for(c = 0; c < k; c++) temp[c] = 0;
			k = 0
		}
		if(j > len) return j

		temp[k++] = sznum[i]
	}
	return j;
}

stock valid_email(email[]) 
{
	if(strlen(email) < 6 || str_character_count(email, '@') != 1 || contain(email, ".") == -1)
		return 0
	
	if(contain(email, "'") != -1)
		return 0

	for(new i; i < sizeof EMAIL_DOMAINS; i++)
		if(contain(email, EMAIL_DOMAINS[i]) != -1)
			return 1
	return 0
}

stock str_character_count(str[], character)
{
	new c
	for(new i; str[i]; i++)
		if(str[i] == character)
			c++
	return c
}

stock urlencode(const sString[], out[], len)
{
	static const sHexTable[] = "0123456789abcdef"
	
	new from, c
	new to

	new sResult[301]
	
	while(from < len){
		c = sString[from++]
		if(c == 0) {
			sResult[to++] = c
			break
		}
		else if(c == ' '){
			sResult[to++] = '+'
		}
		else if((c < '0' && c != '-' && c != '.') ||
		(c < 'A' && c > '9') ||
		(c > 'Z' && c < 'a' && c != '_') ||
		(c > 'z')) {
			if((to + 4) > len) {
				sResult[to] = 0
				break
			}
			sResult[to++] = '%'
			sResult[to++] = sHexTable[c >> 4]
			sResult[to++] = sHexTable[c & 15]
		}
		else {
			sResult[to++] = c
		}
	}
	copy(out, len, sResult)
}

/*================================================================================
[Check allowed,command]
=================================================================================*/
allowed_survivor(id)
{
	if(g_endround || !g_newround || !g_is_alive[id] || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_survminplayers))
		return false
	
	return true
}

allowed_nemesis(id)
{
	if (g_endround || !g_newround || !g_is_alive[id] || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_nemminplayers))
		return false
	
	return true
}

allowed_respawn(id)
{
	static team
	team = fm_get_user_team(id)
	
	if(g_endround || g_survround || g_swarmround || g_nemround || g_plagueround || team == ZP_TEAM_SPECTATOR || team == ZP_TEAM_UNASSIGNED || g_is_alive[id])
		return false
	
	return true
}

allowed_swarm()
{
	if(g_endround || !g_newround || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_swarmminplayers))
		return false
	
	return true
}

allowed_multi()
{
	if (g_endround || !g_newround || task_exists(TASK_WELCOMEMSG) || floatround(fnGetAlive()*get_pcvar_float(cvar_multiratio), floatround_ceil) < 2 || fnGetAlive() < get_pcvar_num(cvar_multiminplayers))
		return false
	
	return true
}

allowed_plague()
{
	if(g_endround || !g_newround || task_exists(TASK_WELCOMEMSG) || floatround((fnGetAlive()-2)*get_pcvar_float(cvar_plagueratio), floatround_ceil) < 1 || fnGetAlive() < get_pcvar_num(cvar_plagueminplayers))
		return false
	
	return true
}

/*================================================================================
[Menus]
=================================================================================*/
show_menu_game(id)
{		
	if(!g_login[id])
		return

	oldmenu_create("menu_game", "\r\rZombie-Evil %s", PLUGIN_VERSION)
	
	oldmenu_additem(1, 0, "\r1.\y Armas")
	
	if(g_is_alive[id] && (is_human(id) || is_zombie(id)))
		oldmenu_additem(2, 0, "\r2.\y Extra Items")
	else oldmenu_additem(-1, 0, "\d2. Extra Items")
	
	
	oldmenu_additem(3, 0, "\r3. \yAdministrar PJ^n")
	oldmenu_additem(4, 0, "\r4. \yParty^n")
	oldmenu_additem(5, 0, "\r5.\y Estadisticas\d/\yReglas\d/\yAyuda")
	oldmenu_additem(6, 0, "\r6.\y Utilidades\d/\yConfiguracion^n")
	
	if(g_is_alive[id])
		oldmenu_additem(7, 0, "\r7.\y Destrabar \r(unstuck)^n")
	else oldmenu_additem(-1, 0, "\d7. Destrabar (unstuck)^n")
	
	if(get_user_flags(id) & OWNER_FLAG)
		oldmenu_additem(8, 0, "\r8.\y Owner Menu")

	if(get_user_flags(id) & ACCESS_FLAG)
		oldmenu_additem(9, 0, "\r9.\y AdminMenu")

	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	
	oldmenu_display(id)
}

public menu_game(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1:
		{
			if(WPN_AUTO_ON)
			{
				WPN_AUTO_ON = 0
				zp_colored_print(id, "^4[Z-Evil]^3 El menu de compra ha sido re-activado.")
			}
			// Allow re-buying during countdown even after already buying once
			if(g_newround && is_human(id) && g_is_alive[id]) g_canbuy[id] = true
			if(g_canbuy[id]) show_menu_prebuy(id)
		}
		case 2:
		{
			if(g_is_alive[id] && (is_human(id) || is_zombie(id)))
				show_menu_extras(id, 1)
			else
				zp_colored_print(id, "^4[Z-Evil]^3 Comando no disponible.")
		}
		case 3: show_menu_managepj(id)
		case 4: show_menu_party(id)
		case 5: show_menu_statistics(id)
		case 6: show_menu_personal(id)
		case 7:
		{
			if(g_is_alive[id] && is_player_stuck(id))
				do_random_spawn(id)
			else
				zp_colored_print(id, "^4[Z-Evil]^3 No estas trabado.")
		}
		case 8:
		{
			if(get_user_flags(id) & OWNER_FLAG)
				show_menu_owner(id)
		}
		case 9:
		{
			if(get_user_flags(id) & ACCESS_FLAG)
				show_menu_admin(id)
		}
	}

	play_soundmenu(id, SOUNDMENU_SELECT)
}

public show_menu_prebuy(taskid)
{
	static id
	(taskid>g_maxplayers)?(id=ID_SPAWN):(id=taskid)
	
	if(!is_human(id) || !g_is_alive[id])
		return
		
	if(WPN_AUTO_ON && taskid > g_maxplayers)
	{
		player_buy_weapon(id, WPN_AUTO_PRI, WPN_TYPE_PRIMARY)
		player_buy_weapon(id, WPN_AUTO_SEC, WPN_TYPE_SECONDARY)
		show_menu_granades(id)
		return
	}
	
	oldmenu_create("menu_prebuy", "\rArmas:")
	
	oldmenu_additem(1, 0, "\r1. \yNormales")
	oldmenu_additem(2, 0, "\r2. \yModificables")
	oldmenu_additem(3, 0, "^n\r3. \yRecordar\r[%s]", (WPN_AUTO_ON) ? "SI" : "NO")
	
	
	oldmenu_display(id)
}

public menu_prebuy(id, itemnum, value, page)
{
	if(!is_human(id) || !g_is_alive[id])
		return PLUGIN_HANDLED

	switch(itemnum)
	{
		case 1: show_menu_primarybuy(id, 1)
		case 2: show_menu_buy3(id)
		case 3: {
			WPN_AUTO_ON = 1 - WPN_AUTO_ON
			show_menu_prebuy(id)
		}
	}

	play_soundmenu(id, SOUNDMENU_SELECT)
	return PLUGIN_HANDLED
}

public show_menu_primarybuy(id, page)
{
	if(!is_human(id) || !g_is_alive[id])
		return

	new maxpages, start, end, count
	oldmenu_calculate_pages(maxpages, start, end, page, g_weapons_count[0])

	oldmenu_create("menu_primarybuy", "\rArma Primaria: %d/%d", page, maxpages)
	
	for(new weap = start; weap < end; weap++)
	{
		count++
		if(g_level[id] < g_primary_weapons[weap][WPN_LEVEL] || g_reset_level[id] < g_primary_weapons[weap][WPN_RESET])
			oldmenu_additem(-1, 0, "\d%d. %s \r[Nivel:%d - Reset:%d]", count, g_primary_weapons[weap][WPN_NAME], g_primary_weapons[weap][WPN_LEVEL], g_primary_weapons[weap][WPN_RESET])
		else
			oldmenu_additem(count, weap, "\r%d. \y%s", count, g_primary_weapons[weap][WPN_NAME])
	}
	
	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")
	
	oldmenu_display(id, page)
}

public menu_primarybuy(id, itemnum, value, page)
{
	if(!is_human(id) || !g_is_alive[id])
		return

	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	if(itemnum == 8)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_primarybuy(id, page-1)
		return
	}
	
	if(itemnum == 9)
	{
		play_soundmenu(id, SOUNDMENU_NEXT)
		show_menu_primarybuy(id, page+1)
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
	
	WPN_AUTO_PRI = value
	player_buy_weapon(id, WPN_AUTO_PRI, WPN_TYPE_PRIMARY)
	
	show_menu_secondarybuy(id, 1)
}

public show_menu_secondarybuy(id, page)
{
	if(!is_human(id) || !g_is_alive[id])
		return

	new maxpages, start, end, count
	oldmenu_calculate_pages(maxpages, start, end, page, g_weapons_count[1])

	oldmenu_create("menu_secondarybuy", "\rArma Secundaria: %d/%d", page, maxpages)
	
	for(new weap = start; weap < end; weap++)
	{
		count++
		
		if(g_level[id] < g_secondary_weapons[weap][WPN_LEVEL] || g_reset_level[id] < g_secondary_weapons[weap][WPN_RESET])
			oldmenu_additem(-1, 0, "\d%d. %s \r[Nivel:%d - Reset:%d]", count, g_secondary_weapons[weap][WPN_NAME], g_secondary_weapons[weap][WPN_LEVEL], g_secondary_weapons[weap][WPN_RESET])
		else
			oldmenu_additem(count, weap, "\r%d. \y%s", count, g_secondary_weapons[weap][WPN_NAME])
	}
	
	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")
	
	oldmenu_display(id, page)
}

public menu_secondarybuy(id, itemnum, value, page)
{
	if(!is_human(id) || !g_is_alive[id])
		return

	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	if(itemnum == 8)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_secondarybuy(id, page-1)
		return
	}
	
	if(itemnum == 9)
	{
		play_soundmenu(id, SOUNDMENU_NEXT)
		show_menu_secondarybuy(id, page+1)
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
	
	WPN_AUTO_SEC = value
	player_buy_weapon(id, WPN_AUTO_SEC, WPN_TYPE_SECONDARY)

	show_menu_granades(id)
}

public show_menu_buy3(id)
{
	if(!is_human(id) || !g_is_alive[id])
		return

	new num[3], menu
	menu = menu_create("\yArmas Mejoradas", "menu_buy3")

	for(new i = 0; i < sizeof weapons_id; i++)
	{
		num_to_str(i, num, 2)
		
		if(g_reset_level[id] < wm_cost[i][1] || g_level[id] < wm_cost[i][0])
			formatex(g_item, charsmax(g_item), "\d%s \r[Nivel:%d - Reset:%d]", wm_name[i], wm_cost[i][0], wm_cost[i][1])
		else
			formatex(g_item, charsmax(g_item), "%s", wm_name[i])
			
		menu_additem(menu, g_item, num)
	}

	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)
}

public menu_buy3(id, menu, item)
{
	if(!is_human(id) || !g_is_alive[id])
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}

	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])
	
	new key = str_to_num(g_menu_slot)

	if(g_reset_level[id] < wm_cost[key][1] || g_level[id] < wm_cost[key][0])
	{
		menu_display(id, menu, 0)
		return PLUGIN_HANDLED
	}

	play_soundmenu(id, SOUNDMENU_SELECT)

	// Give the custom weapon directly from weapons_id[]
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	new wid = weapons_id[key]
	new went = give_item(id, WEAPONENTNAMES[wid])
	if(went > 0)
	{
		cs_set_user_bpammo(id, wid, MAXBPAMMO[wid])
		g_wpn_mejoras_active[id] = true
		g_recoil_mul[id] = 1.0
		new wk2 = weapons_numid[wid]
		if(wk2 != -1 && g_weapons_mejoras[id][wk2][0] > 0)
			cs_set_weapon_ammo(went, (MAXCLIP[wid]+5)+floatround(g_weapons_mejoras[id][wk2][0]*3.4))
	}
	g_canbuy[id] = false
	show_menu_secondarybuy(id, 1)

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

show_menu_extras(id, page)
{
	// Collect visible items for this player's team
	static visible_items[MAX_EXTRA_ITEMS], visible_count
	visible_count = 0
	for(new _i = 0; _i < g_extraitem_count[ZP_TEAM_ANY]; _i++)
	{
		if(is_any_zombie(id) && g_extraitem_team[_i] == ZP_TEAM_HUMAN) continue
		if(!is_zombie(id) && g_extraitem_team[_i] == ZP_TEAM_ZOMBIE) continue
		visible_items[visible_count++] = _i
	}

	new maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page, visible_count)

	oldmenu_create("menu_extras", "\rExtra Items \y%s: %d/%d", is_any_zombie(id)?"Zombie":"Humano", page, maxpages)

	new count = 1
	for(new vi = start; vi < end; vi++)
	{
		new item = visible_items[vi]
		new cost = extra_item_cost(id, item)
		if(g_ammopacks[id] >= cost)
			oldmenu_additem(count, item, "\r%d. \y%s \r(%d AP)", count, g_extraitem_name[item], cost)
		else
			oldmenu_additem(-1, item, "\d%d. %s (%d AP) [Sin AP]", count, g_extraitem_name[item], cost)
		count++
	}

	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")
	
	oldmenu_display(id, page)
}

public menu_extras(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	if(itemnum == 8)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_extras(id, page-1)
		return
	}
	
	if(itemnum == 9)
	{
		play_soundmenu(id, SOUNDMENU_NEXT)
		show_menu_extras(id, page+1)
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
	
	buy_extra_item(id, value)
}

public show_menu_zclass(id, page)
{
	if(!g_is_connected[id])
		return
		
	static maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page, g_zclass_count)
	if(page < 1) page = 1
	if(page > maxpages) page = maxpages

	oldmenu_create("menu_zclass", "\rClases de Zombies: %d/%d", page, maxpages)
	
	for(new class=start, count=1; class < end; class++, count++)
	{
		if(g_level[id] >= g_zclass[class][ZCLASS_LEVEL] && g_reset_level[id] >= g_zclass[class][ZCLASS_RESET])
		{
			if(class == g_zombieclassnext[id])
				oldmenu_additem(-1, 0, "\d%d. %s", count, g_zclass[class][ZCLASS_NAME])
			else 
				oldmenu_additem(count, class, "\r%d. \y%s", count, g_zclass[class][ZCLASS_NAME])
		}
		else
			oldmenu_additem(-1, 0, "\d%d. %s \r(Level: %d - Reset: %d)", count, g_zclass[class][ZCLASS_NAME], g_zclass[class][ZCLASS_LEVEL], g_zclass[class][ZCLASS_RESET])
	}

	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")
	
	oldmenu_display(id, page)
}

public menu_zclass(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	if(itemnum == 8)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_zclass(id, (page > 1) ? page-1 : 1)
		return
	}

	if(itemnum == 9)
	{
		play_soundmenu(id, SOUNDMENU_NEXT)
		new maxp = (g_zclass_count + 6) / 7
		show_menu_zclass(id, (page < maxp) ? page+1 : maxp)
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)

	show_menu_zclass_info(id, value, page)
}

public show_menu_zclass_info(id, class, backmenu_page)
{
	oldmenu_create("menu_zclass_info", "\y%s ^n^n\rVida:\d %d ^n\rVelocidad:\d %.2f ^n\rGravedad:\d %d ^n^n",
	g_zclass[class][ZCLASS_NAME], g_zclass[class][ZCLASS_HEALTH], g_zclass[class][ZCLASS_VELOCITY],
	floatround(g_zclass[class][ZCLASS_GRAVITY]*800))
	
	if(g_level[id] >= g_zclass[class][ZCLASS_LEVEL] && g_reset_level[id] >= g_zclass[class][ZCLASS_RESET])
		oldmenu_additem(1, class, "\r1. \yCambiar a esta clase")
	else oldmenu_additem(-1, 0, "\d1. Cambiar a esta clase")
	
	oldmenu_additem(2, class, "\r2. \yVer Model")

	oldmenu_additem(0, 0, "^n\r0. \yAtras")
	
	oldmenu_display(id, backmenu_page)
}

public menu_zclass_info(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_zclass(id, page)
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
	
	if(itemnum == 2)
	{
		// Model viewer � show class stats (original URL was dead)
		new buff[512]
		new Float:vel, Float:grav
		vel = g_zclass[value][ZCLASS_VELOCITY]
		grav = g_zclass[value][ZCLASS_GRAVITY]
		formatex(buff, charsmax(buff), "<html><body bgcolor=#000><font color=#0F0><b>%s</b><br>Vida: %d | Velocidad: %.1f | Gravedad: %.2f<br>Modelo: %s</font></body></html>", g_zclass[value][ZCLASS_NAME], g_zclass[value][ZCLASS_HEALTH], vel, grav, g_zclass[value][ZCLASS_MODEL])
		show_motd(id, buff, "Info de Clase Zombie")
		show_menu_zclass_info(id, value, page)
		return
	}

	g_zombieclassnext[id] = value

	zp_colored_print(id, "!g[Z-Evil]!t Clase seleccionada: %s", g_zclass[value][ZCLASS_NAME])
	zp_colored_print(id, "!g[Z-Evil]!tAtributos Base:")
	zp_colored_print(id, "!g[Z-Evil]!tVida:!y%d !g| !tVelocidad:!y%.1f !g| !tGravedad:!y%d",
	g_zclass[value][ZCLASS_HEALTH], g_zclass[value][ZCLASS_VELOCITY], floatround(g_zclass[value][ZCLASS_GRAVITY]*800))
}

public show_menu_hclass(id, page)
{
	if(!g_is_connected[id])
		return
		
	new maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page, g_hclass_count)
	if(page < 1) page = 1
	if(page > maxpages) page = maxpages

	oldmenu_create("menu_hclass", "\rClases de Humanos: %d/%d", page, maxpages)
	
	for(new class=start, count=1; class < end; class++, count++)
	{
		if(g_level[id] >= g_hclass[class][HCLASS_LEVEL] && g_reset_level[id] >= g_hclass[class][HCLASS_RESET])
		{
			if(class == g_humanclass[id])
				oldmenu_additem(-1, 0, "\d%d. %s", count, g_hclass[class][HCLASS_NAME])
			else 
				oldmenu_additem(count, class, "\r%d. \y%s", count, g_hclass[class][HCLASS_NAME])
		}
		else
			oldmenu_additem(-1, 0, "\d%d. %s \r(Level: %d - Reset: %d)", count, g_hclass[class][HCLASS_NAME], g_hclass[class][HCLASS_LEVEL], g_hclass[class][HCLASS_RESET])
	}

	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")
	
	oldmenu_display(id, page)
}

public menu_hclass(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	if(itemnum == 8 || itemnum == 9)
	{
		new Float:now = get_gametime()
		if(now - g_hclass_nav_time[id] < 0.15) return
		g_hclass_nav_time[id] = now

		if(itemnum == 8)
		{
			play_soundmenu(id, SOUNDMENU_BACK)
			show_menu_hclass(id, (page > 1) ? page-1 : 1)
		}
		else
		{
			play_soundmenu(id, SOUNDMENU_NEXT)
			new maxp = (g_hclass_count + 6) / 7
			show_menu_hclass(id, (page < maxp) ? page+1 : maxp)
		}
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)

	show_menu_hclass_info(id, value, page)
}

public show_menu_hclass_info(id, class, backmenu_page)
{
	oldmenu_create("menu_hclass_info", "\y%s ^n^n\rVida:\d %d ^n\rChaleco:\d %d ^n\rVelocidad:\d %.2f ^n\rGravedad:\d %d ^n^n",
	g_hclass[class][HCLASS_NAME], g_hclass[class][HCLASS_HEALTH], g_hclass[class][HCLASS_ARMOR],
	g_hclass[class][HCLASS_VELOCITY], floatround(g_hclass[class][HCLASS_GRAVITY]*800))
	
	if(g_level[id] >= g_hclass[class][HCLASS_LEVEL] && g_reset_level[id] >= g_hclass[class][HCLASS_RESET])
		oldmenu_additem(1, class, "\r1. \yCambiar a esta clase")
	else oldmenu_additem(-1, 0, "\d1. Cambiar a esta clase")
	
	oldmenu_additem(2, class, "\r2. \yVer Model")

	oldmenu_additem(0, 0, "^n\r0. \yAtras")
	
	oldmenu_display(id, backmenu_page)
}

public menu_hclass_info(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_hclass(id, page)
		return
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
	
	if(itemnum == 2)
	{
		new buff[512]
		new Float:hvel, Float:hgrav
		hvel = g_hclass[value][HCLASS_VELOCITY]
		hgrav = g_hclass[value][HCLASS_GRAVITY]
		formatex(buff, charsmax(buff), "<html><body bgcolor=#000><font color=#0AF><b>%s</b><br>Vida: %d | Chaleco: %d<br>Velocidad: %.1f | Gravedad: %.2f<br>Modelo: %s | Nivel: %d</font></body></html>", g_hclass[value][HCLASS_NAME], g_hclass[value][HCLASS_HEALTH], g_hclass[value][HCLASS_ARMOR], hvel, hgrav, g_hclass[value][HCLASS_MODEL], g_hclass[value][HCLASS_LEVEL])
		show_motd(id, buff, "Info de Clase Humana")
		show_menu_hclass_info(id, value, page)
		return
	}

	g_humanclass[id] = value
	
	zp_colored_print(id, "!g[Z-Evil]!t Clase seleccionada: %s", g_hclass[value][HCLASS_NAME])
	zp_colored_print(id, "!g[Z-Evil]!tAtributos Base:")
	zp_colored_print(id, "!g[Z-Evil]!tVida:!y%d !g| !tChaleco:!y%d !g| !tVelocidad:!y%.1f !g| !tGravedad:!y%d",
	g_hclass[value][HCLASS_HEALTH], g_hclass[value][HCLASS_ARMOR], g_hclass[value][HCLASS_VELOCITY], floatround(g_hclass[value][HCLASS_GRAVITY]*800))
}

public show_menu_managepj(id)
{  
	oldmenu_create("menu_managepj", "\rAdministrar PJ:")
	
	oldmenu_additem(1, 0, "\r1. \yClase Humana")
	oldmenu_additem(2, 0, "\r2. \yClase Zombie^n")
	oldmenu_additem(3, 0, "\r3. \yMejoras Humana\d/\yZombie^n")
	oldmenu_additem(4, 0, "\r4. \yMejoras de armas^n")
	
	if(g_level[id] >= ((MAX_LEVEL-1)+(3*g_reset_level[id])))
		oldmenu_additem(5, 0, "\r5. \yResetear")
	else oldmenu_additem(-1, 0, "\d5. Resetear \r(Level %d)", (MAX_LEVEL-1)+(3*g_reset_level[id]))
	
	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	oldmenu_display(id)
}

public menu_managepj(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1: show_menu_hclass(id, 1)
		case 2: show_menu_zclass(id, 1)
		case 3: show_menu_puntos(id)
		case 4: show_menu_wmejoras(id)
		case 5: {
			if(g_level[id] >= ((MAX_LEVEL-1)+(3*g_reset_level[id]))) {
				g_reset_level[id]++
				g_ammopacks[id] = NIVELES(1)
				g_level[id] = 1
				g_humanclass[id] = 0
				g_zombieclass[id] = 0
				g_zombieclassnext[id] = 0
				reset_points(id)
				g_points[id][TEAM_HUMAN] = (65 + (g_reset_level[id] * 15))
				g_points[id][TEAM_ZOMBIE] = (70 + (g_reset_level[id] * 15))

				SaveCuenta(id, 0)

				show_msgtutor(0, 3.5, 0, "%s ha reseteado!!!.^nFelicidades.", g_name[id])
			}
		}
	} 
	play_soundmenu(id, SOUNDMENU_SELECT)
}

public show_menu_personal(id)
{
	oldmenu_create("menu_personal", "\rUtilidades/Configuracion:")
	
	oldmenu_additem(1, 0, "\r1. \yMute")
	oldmenu_additem(2, 0, "\r2. \yRates")
	oldmenu_additem(3, 0, "\r3. \yConfigurar Interfaz")
	oldmenu_additem(4, 0, "\r4. \yPonerse de espectador")
	oldmenu_additem(5, 0, "\r5. \yRegalar AmmoPack^n")
	oldmenu_additem(6, 0, "\r6. \yOpciones de login")
	
	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	oldmenu_display(id)
}

public menu_personal(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1: client_cmd(id, "say /mute")
		case 2: client_cmd(id, "say /rates")
		case 3: show_menu_interface(id)
		case 4:
		{
			if(g_is_alive[id])
			{
				check_round(id)
				dllfunc(DLLFunc_ClientKill, id)
			}
			save_stats(id)
			
			remove_task(id+TASK_TEAM)
			remove_task(id+TASK_MODEL)
			remove_task(id+TASK_SPAWN)
			remove_task(id+TASK_BLOOD)
			remove_task(id+TASK_BURN)

			fm_set_user_team(id, ZP_TEAM_SPECTATOR)
			fm_user_team_update(id)
		}
		case 5: donate_ammopacks(id)
		case 6: show_menu_account(id)
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
}

public show_menu_account(id)
{
	new pw_md5[2][34]
	get_user_info(id, setinfo_md5key, pw_md5[0], charsmax(pw_md5[]))
	
	md5(g_password[id], pw_md5[1])
	pw_md5[0][8]='^0';pw_md5[1][8]='^0'

	oldmenu_create("menu_account", "\rOpciones de login:")
	
	oldmenu_additem(1, 0, "\r1. \yCambiar password")
	
	if(equal(pw_md5[0], pw_md5[1]))
		oldmenu_additem(2, 0, "\yRecordar\r[SI]")
	else oldmenu_additem(2, 1, "\yRecordar\r[NO]")

	oldmenu_additem(0, 0, "^n\r0. \ySalir")

	oldmenu_display(id)
}

public menu_account(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1: client_cmd(id, "messagemode vieja_password")
		case 2: {
			if(!value)
			{
				client_cmd(id, "setinfo %s null", setinfo_md5key)
			}
			else {
				new pw_md5[34]
				md5(g_password[id], pw_md5)
				pw_md5[8] = '^0'
				client_cmd(id, "setinfo %s %s", setinfo_md5key, pw_md5)
			}
			show_menu_account(id)
		}
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
}

public show_menu_interface(id)
{
	oldmenu_create("menu_interface", "\rConfigurar Interfaz:")
	
	oldmenu_additem(1, 0, "\r1. \rColor:\yNightVision")
	oldmenu_additem(2, 0, "\r2. \rColor:\yBengala")
	oldmenu_additem(3, 0, "\r3. \rColor:\yHud primario")
	oldmenu_additem(4, 0, "\r4. \rColor:\yHud secundario")
	oldmenu_additem(5, 0, "\r5. \rPosicion:\yHud primario")
	oldmenu_additem(6, 0, "\r6. \rPosicion:\yHud secundario")
	oldmenu_additem(7, 0, "\r7. \yAuto NightVision \r[%s]", (g_autonvg[id]) ? "SI" : "NO")
	
	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	oldmenu_display(id)
}

public menu_interface(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1: show_menu_colors(id, 1)
		case 2: show_menu_colors(id, 2)
		case 3: show_menu_colors(id, 3)
		case 4: show_menu_colors(id, 4)
		case 5: show_menu_hudposition(id, 0)
		case 6: show_menu_hudposition(id, 1)
		case 7: {
			g_autonvg[id] = !(g_autonvg[id])
			show_menu_interface(id)
		}
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
}

public show_menu_colors(id, type)
{
	g_menu_colors[id] = type
	
	static menu
	if(!menu)
	{
		menu = menu_create("\rColores:", "menu_colors")
		new colornum[3]
		for(new i = 0; i <= charsmax(COLOR_NAME); i++)
		{
			num_to_str(i, colornum, 2)
			menu_additem(menu, COLOR_NAME[i], colornum)
		}

		menu_setprop(menu, MPROP_EXITNAME, "Salir")
	}

	menu_display(id, menu, 0)
}

public menu_colors(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}
	
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])

	if(g_menu_colors[id] == 1)
		g_nvg_color[id] = str_to_num(g_menu_slot)
	else if(g_menu_colors[id] == 2)
		g_flare_color[id] = str_to_num(g_menu_slot)
	else if(g_menu_colors[id] == 3)
		hud_color[id][0] = str_to_num(g_menu_slot)
	else if(g_menu_colors[id] == 4)
		hud_color[id][1] = str_to_num(g_menu_slot)
		
	play_soundmenu(id, SOUNDMENU_SELECT)
	menu_display(id, menu)
	return PLUGIN_HANDLED
}

public show_menu_hudposition(id, type)
{
	hud_menu[id] = type

	oldmenu_create("menu_hudposition", "\rPosicion del HUD:")
	
	if(hud_posicion[id][hud_menu[id]][0] < 0.95)
		oldmenu_additem(1, 0, "\r1. \yDerecha")
	else oldmenu_additem(-1, 0, "\d1. Derecha")
		
	if(hud_posicion[id][hud_menu[id]][0] > 0.0)
		oldmenu_additem(2, 0, "\r2. \yIzquierda")
	else oldmenu_additem(-1, 0, "\d2. Izquierda")
		
	if(hud_posicion[id][hud_menu[id]][1] > 0.0)
		oldmenu_additem(3, 0, "\r3. \yArriba")
	else oldmenu_additem(-1, 0, "\d3. Arriba")
		
	if(hud_posicion[id][hud_menu[id]][1] < 0.95)
		oldmenu_additem(4, 0, "\r4. \yAbajo")
	else oldmenu_additem(-1, 0, "\d4. Abajo")
	
	oldmenu_additem(5, 0, "^n\r5. \yUnidad\r(%.2f)", g_hud_unidad[id])
		
	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	oldmenu_display(id)
}

public menu_hudposition(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1: {
			if((hud_posicion[id][hud_menu[id]][0]+g_hud_unidad[id]) < 0.95)
				hud_posicion[id][hud_menu[id]][0] += g_hud_unidad[id]
			else
				hud_posicion[id][hud_menu[id]][0] = 0.95
		}
		case 2: {
			if((hud_posicion[id][hud_menu[id]][0]-g_hud_unidad[id]) > 0.0)
				hud_posicion[id][hud_menu[id]][0] -= g_hud_unidad[id]
			else
				hud_posicion[id][hud_menu[id]][0] = 0.0
		}
		case 3: {
			if((hud_posicion[id][hud_menu[id]][1]-g_hud_unidad[id]) > 0.0)
				hud_posicion[id][hud_menu[id]][1] -= g_hud_unidad[id]
			else
				hud_posicion[id][hud_menu[id]][1] = 0.0
		}
		case 4: {
			if((hud_posicion[id][hud_menu[id]][1]+g_hud_unidad[id]) < 0.95)
				hud_posicion[id][hud_menu[id]][1] += g_hud_unidad[id]
			else
				hud_posicion[id][hud_menu[id]][1] = 0.95
		}
		case 5: {

			g_hud_unidadnum[id]++
			switch(g_hud_unidadnum[id])
			{
				case 1: g_hud_unidad[id] = 0.01
				case 2: g_hud_unidad[id] = 0.05
				case 3: g_hud_unidad[id] = 0.1
				case 4: g_hud_unidad[id] = 0.3
				case 5: 
				{
					g_hud_unidad[id] = 0.01
					g_hud_unidadnum[id] = 1
				}
			}
		}
	}
	
	play_soundmenu(id, SOUNDMENU_SELECT)
	show_menu_hudposition(id, hud_menu[id])
	ze_showhud(id)
}

public show_menu_statistics(id)
{
	oldmenu_create("menu_statistics", "\rEstadisticas/Reglas/Ayuda:")
	
	oldmenu_additem(1, 0, "\r1. \yPlayers Online")
	oldmenu_additem(2, 0, "\r2. \yMiniStats")
	oldmenu_additem(3, 0, "\r3. \yReglas")
	oldmenu_additem(4, 0, "\r4. \yTop20")
	oldmenu_additem(5, 0, "\r5. \yRank")

	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	oldmenu_display(id)
}

public menu_statistics(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	switch(itemnum)
	{
		case 1: // Players Online � build locally
		{
			static info[1024], len
			len = 0
			len += formatex(info[len], charsmax(info)-len, "<html><body bgcolor=#000000><font color=#00FF00>")
			len += formatex(info[len], charsmax(info)-len, "<b>Players Online</b><br>")
			for(new i = 1; i <= g_maxplayers; i++)
			{
				if(!g_is_connected[i]) continue
				len += formatex(info[len], charsmax(info)-len, "%s | Level %d | AP %d<br>", g_name[i], g_level[i], g_ammopacks[i])
			}
			len += formatex(info[len], charsmax(info)-len, "</font></body></html>")
			show_motd(id, info, "Players Online")
		}
		case 2: show_msgtutor(id, 7.0, 6, "Tu level es: %d^nAmmo pack level %d: %d^nAmmo pack faltantes: %d^nAmmo pack: %d", g_level[id], (g_level[id] + 1), ammo_level(id, 1), ammo_level(id, 1) - g_ammopacks[id], g_ammopacks[id])
		case 3: // Reglas � show local rules
		{
			show_motd(id, "<html><body bgcolor=#000000><font color=#00FF00><b>Reglas Zombie-Evil</b><br><br>1. No teamkill<br>2. No spam<br>3. Respeta a los jugadores<br>4. No exploits ni hacks<br>5. Divertite!</font></body></html>", "Reglas")
		}
		case 4: clcmd_top20(id)
		case 5: clcmd_rank(id)
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
}

//--------------------------------------------------
// Munu de Granadas-------------------------------------------------------------------
public show_menu_granades(id)
{ 
	new menu = menu_create("\rMenu de Bomba:", "menu_granadas") 
	
	if(g_level[id] < 2) menu_additem(menu, "\d 1 Fuego | 1 Hielo | 1 Bengala \r[Bloqueado]", "1", 0)
	else menu_additem(menu, "\w 1 Fuego | 1 Hielo | 1 Bengala", "1", 0)

	if(g_level[id] < 5) menu_additem(menu, "\d 1 Fuego | 2 Hielo | 1 Bengala \r[Bloqueado]", "2", 0)
	else menu_additem(menu, "\w 1 Fuego | 2 Hielo | 1 Bengala", "2", 0) 

	if(g_level[id] < 9) menu_additem(menu, "\d 2 Fuego | 2 Hielo | 2 Bengala \r[Bloqueado]", "3", 0)
	else menu_additem(menu, "\w 2 Fuego | 2 Hielo | 2 Bengala", "3", 0) 

	if(g_level[id] < 14) menu_additem(menu, "\d 2 Fuego | 3 Hielo | 3 Bengala \r[Bloqueado]", "4", 0)
	else menu_additem(menu, "\w 2 Fuego | 3 Hielo | 3 Bengala", "4", 0) 

	if(g_level[id] < 50) menu_additem(menu, "\d 1 New HE | 1 Hielo | 1 Bengala \r[Bloqueado]", "4", 0)
	else menu_additem(menu, "\w 1 New HE | 1 Hielo | 1 Bengala", "5", 0)

	if(g_level[id] < 70) menu_additem(menu, "\d 2 New HE | 3 Hielo | 1 Bengala \r[Bloqueado]", "4", 0)
	else menu_additem(menu, "\w 2 New HE | 3 Hielo | 1 Bengala", "6", 0)
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir") 
	menu_display(id, menu, 0) 
}

public  menu_granadas(id, menu, item)
{ 
	if(item == MENU_EXIT )
	{ 
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED 
	}

	if(!is_human(id) || !g_is_alive[id])
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0]) 
	
	new key = str_to_num(g_menu_slot)

	if (g_level[id] >= 2 && key < 5)
	{ 
		give_grenade(id, NADE_TYPE_NAPALM)
		give_grenade(id, NADE_TYPE_FROST)
		give_grenade(id, NADE_TYPE_FLARE)
	}
	
	switch(key){ 
		case 2: { 
			if (g_level[id] >= 5){ 
				give_grenade(id, NADE_TYPE_FROST)
			} 
		} 
		case 3: { 
			if (g_level[id] >= 9){ 
				give_grenade(id, NADE_TYPE_NAPALM)
				give_grenade(id, NADE_TYPE_FROST)
				give_grenade(id, NADE_TYPE_FLARE)
			}
		}
		case 4: { 
			if (g_level[id] >= 14){  
				give_grenade(id, NADE_TYPE_NAPALM)
				give_grenade(id, NADE_TYPE_FROST)
				give_grenade(id, NADE_TYPE_FROST)
				give_grenade(id, NADE_TYPE_FLARE)
				give_grenade(id, NADE_TYPE_FLARE)
			}
		} 
		case 5: { 
			if(g_level[id] >= 50) {
				give_grenade(id, NADE_TYPE_HE)
				give_grenade(id, NADE_TYPE_FROST)
				give_grenade(id, NADE_TYPE_FLARE)
			}
		}
		case 6: { 
			if(g_level[id] >= 70) {
				give_grenade(id, NADE_TYPE_HE)
				give_grenade(id, NADE_TYPE_HE)
				give_grenade(id, NADE_TYPE_FROST)
				give_grenade(id, NADE_TYPE_FROST)
				give_grenade(id, NADE_TYPE_FLARE)
			}
		} 
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

 //--check Level--------------------------------------------------------//
//---------------------------------------------------------------------//
check_player_level(id)
{
	if(g_ammopacks[id] < 0 || g_level[id] < 0)
	{
		g_ammopacks[id] = 0
		g_level[id] = 0
		log_to_file("malditos3.log", "name:[%s], aps:[%d], level:[%d]", g_name[id], g_ammopacks[id], g_level[id])
		return
	}

	if(g_ammopacks[id] >= NIVELES((MAX_LEVEL+(3*g_reset_level[id]))))
	{
		new temp_lvl = (MAX_LEVEL-1)+(3*g_reset_level[id])
		zp_center_print(id, "Volviste al nivel %d por llegar al limite,Resetea!!!.", temp_lvl)
		g_ammopacks[id] = NIVELES(temp_lvl)
	}
	else if(g_ammopacks[id] < ammo_level(id, 0))
	{
		while(g_ammopacks[id] < ammo_level(id, 0))
			g_level[id]--
		zp_center_print(id, "Bajaste de nivel")
		emit_sound(id, CHAN_VOICE, sound_leveldonw, 1.0, ATTN_NORM, 0, PITCH_NORM)
		SaveCuenta(id, 0)
	}
	else if(g_ammopacks[id] >= ammo_level(id, 1))
	{
		while(g_ammopacks[id] >= ammo_level(id, 1))
			g_level[id]++
		zp_center_print(id, "Subiste de nivel")
		emit_sound(id, CHAN_VOICE, sound_levelup, 1.0, ATTN_NORM, 0, PITCH_NORM)
		SaveCuenta(id, 0)
	}
}

 //--Estadisticas y otros----------------------------------------------------//
//--------------------------------------------------------------------------//

public clcmd_rank(id)
{
	static next_query[33] 
	if(next_query[id] < get_systime())
	{
		new szQuery[256], iData[1]
		formatex(szQuery, 255, "SELECT (SELECT (COUNT(*) + 1) FROM `cuentas_30` WHERE(`reset` > '%d' OR ( `reset` = '%d' AND `ap` > '%d' ))),(SELECT (COUNT(*) + 1) FROM `cuentas_30`)FROM `cuentas_30`",
		g_reset_level[id], g_reset_level[id], g_ammopacks[id])

		iData[0] = id
		SQL_ThreadQuery(g_hTuple, "show_rank", szQuery, iData, 1)
		
		next_query[id] = get_systime()+50
	}
	else
		zp_colored_print(id, "^4[Z-Evil]^3 Tu rank es !y%d !tde !y%d.", g_rank_post[id], g_rank_total, g_level[id])
}

public clcmd_top20(id)
{
	// Query DB for top players ranked by reset DESC, level DESC
	new szQuery[256]
	formatex(szQuery, charsmax(szQuery),
		"SELECT nick, level, reset, ap FROM `cuentas_30` ORDER BY reset DESC, level DESC, ap DESC LIMIT 20")
	new data[2]; data[0] = id
	SQL_ThreadQuery(g_hTuple, "top20_query_result", szQuery, data, 1)
}

public top20_query_result(iFailState, Handle:hQuery, szError[], iError, iData[], iDataSize, Float:fQueueTime)
{
	new id = iData[0]
	if(!is_user_connected(id)) return
	if(iFailState != TQUERY_SUCCESS || !SQL_NumResults(hQuery))
	{
		client_print(id, print_chat, "[Top20] Error al consultar la base de datos.")
		return
	}

	new html[2048], len, rank = 0
	len += formatex(html[len], charsmax(html)-len, "<html><body bgcolor=#000><font color=#FF0 size=4><b>TOP 20</b></font><br><font color=#AAA size=2><table><tr><td><b>#</b></td><td><b>Nick</b></td><td><b>Reset</b></td><td><b>Nivel</b></td><td><b>AP</b></td></tr>")

	while(SQL_MoreResults(hQuery) && rank < 20)
	{
		rank++
		new nick[33], rlevel, rreset, rap
		SQL_ReadResult(hQuery, 0, nick, charsmax(nick))
		rlevel = SQL_ReadResult(hQuery, 1)
		rreset = SQL_ReadResult(hQuery, 2)
		rap    = SQL_ReadResult(hQuery, 3)

		new color[] = "#FFFFFF"
		if(rank == 1) copy(color, charsmax(color), "#FFD700")
		else if(rank == 2) copy(color, charsmax(color), "#C0C0C0")
		else if(rank == 3) copy(color, charsmax(color), "#CD7F32")

		len += formatex(html[len], charsmax(html)-len, "<tr><td><font color=%s>%d</font></td><td><font color=%s>%s</font></td><td><font color=#0F0>%d</font></td><td><font color=#0AF>%d</font></td><td><font color=#F80>%d</font></td></tr>", color, rank, color, nick, rreset, rlevel, rap)

		SQL_NextRow(hQuery)
	}

	len += formatex(html[len], charsmax(html)-len, "</table></font></body></html>")
	show_motd(id, html, "Top 20 � Ranking")
}

public show_rank(iFailState, Handle:hQuery, szError[], iError, iData[], iDataSize, Float:fQueueTime) 
{ 
	if(iFailState == TQUERY_CONNECT_FAILED || iFailState == TQUERY_QUERY_FAILED) 
	{ 
		log_to_file("mysql.log", "show rank error:[%s]", szError)
		return
	} 

	new id = iData[0]

	if(!SQL_MoreResults(hQuery) || !is_user_connected(id)) return
	

	g_rank_post[id] = SQL_ReadResult(hQuery, 0)
	g_rank_total = SQL_ReadResult(hQuery, 1)

	zp_colored_print(id, "^4[Z-Evil]^3 Tu rank es !y%d !tde !y%d,!tlevel !y%d", g_rank_post[id], g_rank_total, g_level[id])
}

donate_ammopacks(id)
{
	if(g_donate_limit[id][0] > 2000)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Solo puedes dar 2000 ammopacks por dia.") 
		return
	}

	if(g_ammopacks[id] < 2000)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Tienes que tener mas de 2000 ammopacks para usar esto.") 
		return
	}

	client_cmd(id, "messagemode monto")
}

public clcmd_donate_amount(id)
{
	if(!g_login[id]) return PLUGIN_HANDLED

	if(g_donate_limit[id][0] > 2000)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Solo puedes regalar 2000 ammopacks por dia.") 
		return PLUGIN_HANDLED 
	}
	if(g_ammopacks[id] < 2000)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Tienes que tener mas de 2000 ammopacks para usar esto.") 
		return PLUGIN_HANDLED 
	} 

	new amount[6]
	read_args(amount, 5)
	remove_quotes(amount)
	trim(amount)
	
	if(!amount[0]) return PLUGIN_HANDLED

	for(new j; amount[j]; j++)
	{
		if(!isdigit(amount[j]))
		{
			zp_colored_print(id, "^4[Z-Evil]^3Solo se permiten Numeros")
			client_cmd(id, "messagemode monto")
			return PLUGIN_HANDLED
		}
	}
	
	new ammopacks = str_to_num(amount)
	
	if(ammopacks  > 500)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 No puedes regalar mas de 500 ammopacks.") 
		client_cmd(id, "messagemode monto") 
		return PLUGIN_HANDLED 
	}
	if(ammopacks  < 5)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 No puedes regalar menos de 5 ammopacks.") 
		client_cmd(id, "messagemode monto") 
		return PLUGIN_HANDLED 
	}

	
	g_donate_amount[id] = ammopacks 

	show_menu_donate(id, 1)
	return PLUGIN_HANDLED
}

public show_menu_confirm(id, player)
{
	new endamount = (g_donate_amount[id] - floatround(((g_donate_amount[id]*17.0)/100)))
	
	oldmenu_create("menu_confirm", "\yMonto:\d %d ap ^n\yIva: \d 17 %% ^n^n\wRegalar \d %d \w ammo pack^n A\d %s \w?", g_donate_amount[id], endamount, g_name[player])
	
	oldmenu_additem(1, player, "\r1. \ySi")
	oldmenu_additem(2, 0, "\r2. \yNo")
	
	oldmenu_display(id, _, 5)
	
	g_donate_amount[id] = endamount
}

public menu_confirm(id, itemnum, value, page)
{
	if(itemnum == 2)
	{
		zp_colored_print(id, "^4[Z-Evil]^3 Operacion cancelada")
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	

	if(is_user_valid_connected(value) && g_login[value])
	{
		g_ammopacks[value] += g_donate_amount[id]
		g_ammopacks[value] -= g_donate_amount[id]
			
		if(g_donate_amount[id] > 100)
			log_to_file("regalar_ap.log", "%s regalo: %d aps a: %s", g_name[id], g_donate_amount[id], g_name[value])

		zp_colored_print(id, "^4[Z-Evil]^3 Le regalaste^1 %d^3 ammopacks a^1 %s", g_donate_amount[id], g_name[value])
		zp_colored_print(value, "^4[Z-Evil]^1 %s^3 te ha regalado^1 %d^3 ammopacks", g_name[id], g_donate_amount[id])
		check_player_level(id)
		check_player_level(value)

		g_donate_limit[id][0] += g_donate_amount[id]
		g_donate_limit[value][1] += g_donate_amount[id]

		play_soundmenu(id, SOUNDMENU_SELECT)
		return
	}
	
	zp_colored_print(id, "^4[Z-Evil]^3 Player invalido,Operacion cancelada")
	play_soundmenu(id, SOUNDMENU_CANCEL)
}

public show_menu_donate(id, page)
{
	new maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page,  fnGetPlaying())
	oldmenu_create("menu_donate", "\rPlayers: %d/%d", page, maxpages)

	for(new i=start, count=1; i < end; i++, count++)
	{
		oldmenu_additem(count, g_players[i], "\r%d. \y%s", count, g_name[g_players[i]])
	}

	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")

	oldmenu_display(id, page)
}

public menu_donate(id, itemnum, value, page)
{
	if(itemnum == 0)
	{
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return
	}
	
	if(itemnum == 8)
	{
		play_soundmenu(id, SOUNDMENU_BACK)
		show_menu_donate(id, page-1)
		return
	}
	
	if(itemnum == 9)
	{
		play_soundmenu(id, SOUNDMENU_NEXT)
		show_menu_donate(id, page+1)
		return
	}
	
	if(g_donate_limit[value][1] > 1000)
	{
		zp_colored_print(id, "!g[Z-Evil]!y%s !tno puede recibir mas de 1000 ammopacks por dia.", g_name[value])
		show_menu_donate(id, page)
		return
	}

	play_soundmenu(id, SOUNDMENU_SELECT)
	
	show_menu_confirm(id, value)
}

 //----Combo--------------------------------------------------------
//------------------------------------------------------------------
public show_current_combo(id, idamage)
{
	set_hudmessage(0, 255, 0, -1.0, 0.6, 1, 3.0, 3.0, 0.01, 0.01)
	
	static partyid
	if(g_party[id][PARTY_ID])
	{
		partyid = g_party[id][PARTY_ID]
		if(g_combo[partyid])
		{
			static lasthit[33][2]
			lasthit[id][0] = idamage
			lasthit[id][1] = g_time+3

			for(new i; i <= g_maxplayers; i++)
			{
				if(!g_is_alive[i] || g_party[i][PARTY_ID] != partyid) continue
			
				if(lasthit[i][1]-g_time <= 0)
					ShowSyncHudMsg(i, g_MsgSync3, "===Party===^n%s^n^nCombo %d^n%d | %d", g_info_combo[partyid], g_combo[partyid]+1, g_damagecombo[partyid], (80 * (g_combo[partyid] + 1)) + (g_combo[partyid] * 40))
				else
					ShowSyncHudMsg(i, g_MsgSync3, "===Party===^n%s^n^nLast Hit: %d^nCombo %d^n%d | %d", g_info_combo[partyid], lasthit[id][0], g_combo[partyid]+1, g_damagecombo[partyid], (80 * (g_combo[partyid] + 1)) + (g_combo[partyid] * 40))
			}
		}
		else
			ShowSyncHudMsg(id, g_MsgSync3, "Hit de: %d", idamage)
	}
	else {
		if(!g_combo[id])
			ShowSyncHudMsg(id, g_MsgSync3, "Hit de: %d", idamage)
		else
			ShowSyncHudMsg(id, g_MsgSync3, "Hit de: %d^n%s^n^nCombo %d^n%d | %d", idamage, g_info_combo[id], g_combo[id]+1, g_damagecombo[id], (80 * (g_combo[id] + 1)) + (g_combo[id] * 40))
	}
}

public finish_combo(id)
{
	static ap, Eap, info[32], Float:valor
	valor = 3.2
	Eap = 0

	id -= TASK_FINISH_COMBO
	new Float:fix
	while(valor < g_combo[id])
	{
		fix = (3.6-(Eap*0.1))
		if(fix<1.5) fix=1.5
		valor += fix
		Eap++
	}
	
	set_hudmessage(255, 255, 0, -1.0, 0.6, 0, 3.0, 3.0, 0.01, 0.01)
	
	if(g_party[id][PARTY_ID]==id)
	{
		if(g_party[id][PARTY_MIEMBROS] >= 3)
			Eap /= (g_party[id][PARTY_MIEMBROS]-1)
		else
			Eap /= g_party[id][PARTY_MIEMBROS]
			
		g_party[id][PARTY_APS] += Eap
		g_party[id][PARTY_COMBO] += g_combo[id]
		
		for(new i; i <= g_maxplayers; i++)
		{
			if(!g_is_alive[i] || g_party[i][PARTY_ID] != id) continue
			
			ShowSyncHudMsg(i, g_MsgSync3, "Combo finalizado!^nTotal: %d, danio: %d, hits: %d^n^nExtra AP: %d", g_combo[id], g_damagecombo[id], g_damagehits[id], Eap)
				
			g_ammopacks[i] += Eap
			check_player_level(i)
		}
	}
	else {
		g_ammopacks[id] += Eap
		check_player_level(id)
		
		ap = (g_ammopacks[id] - g_combo_ammopacks[id])
		if(ap)
			formatex(info, charsmax(info), "AP ganados: %d + %d Extra AP", ap, Eap)
		else
			info[0] = '^0'
			
		if(g_combo[id] >= 30)
			ShowSyncHudMsg(id, g_MsgSync3, "Ultimo combo finalizado!^nTotal: %d, danio: %d, hits: %d^n^n%s", g_combo[id], g_damagecombo[id], g_damagehits[id], info)
		else
			ShowSyncHudMsg(id, g_MsgSync3, "Combo finalizado!^nTotal: %d, danio: %d, hits: %d^n^n%s", g_combo[id], g_damagecombo[id], g_damagehits[id], info)
	
	}
	
	g_combo[id] = 0
	g_damagecombo[id] = 0
	g_damagehits[id] = 0
	g_combo_ap_check[id] = false
}

public info_combo(id)
{
	id -= TASK_INFO_COMBO
	g_info_combo[id][0] = '^0'
}

public reset_combo(id)
{
	id -= TASK_RESET_COMBO
	
	g_combo[id] = 0
	g_damagecombo[id] = 0
	g_damagehits[id] = 0
	g_combo_ap_check[id] = false
}

public on_damage(id)
{
	static damage
	damage = read_data(2)
	set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(id, g_MsgSync4, "%i^n", damage)
}

/*================================================================================
[Hora Feliz]
=================================================================================*/
public clcmd_hf(id)
{
	new h, m, s
	time(h, m, s)
	
	new h_check
	
	new a
	
	if(h >= HOURS_HF[0] && h < HOURS_HF[1] || (HOURS_HF[0] > HOURS_HF[1]))
		a = 1
	else if(h >= HOURS_HF[1] && h < HOURS_HF[2] || (HOURS_HF[1] > HOURS_HF[2]))
		a = 2
			
	if(a)
	{
		if(g_is_hf == 1 && a == 2) {
			send_msg_hf(id, HFS_PRE_START)
			return
		}
		else if(!g_is_hf) {
			send_msg_hf(id, HF_PRE_START)
			return
		}
	}
	else if(g_is_hf) {
		send_msg_hf(id, HFS_PRE_END)
		return
	}
	
	h_check = HOURS_HF[g_is_hf]
	
	h = h - h_check
	h = 23 - h
	if(h >= 24)
		h -= 24
	m = 59 - m
	s = 60 - s
	
	switch(g_is_hf) {
		case 0: zp_colored_print(id, "!g[Z-Evil]!t Faltan!y %dH/%dm/%ds!t para que!y empieze!t la!y HORA FELIZ", h, m, s)
		case 1: zp_colored_print(id, "!g[Z-Evil]!t Faltan!y %dH/%dm/%ds!t para que!y empieze!t la!y SUPER HORA FELIZ", h, m, s)
		case 2: zp_colored_print(id, "!g[Z-Evil]!t Faltan!y %dH/%dm/%ds!t para que!y termine!t la!y SUPER HORA FELIZ", h, m, s)
	}
}

public is_hf()
{
	new h
	time(h, _, _)

	new a
	
	if(h >= HOURS_HF[0] && h < HOURS_HF[1] || (HOURS_HF[0] > HOURS_HF[1]))
		a = 1
	else if(h >= HOURS_HF[1] && h < HOURS_HF[2] || (HOURS_HF[1] > HOURS_HF[2]))
		a = 2
		
	if(a) {
		if(g_is_hf) {
			if(g_is_hf == 2)
				send_msg_hf(0, HFS_IS)
			else if(a == 2) {
				g_is_hf = 2
				send_msg_hf(0, HFS_START)
			}
			else
				send_msg_hf(0, HF_IS)
		}
		else {
			g_is_hf = 1
			send_msg_hf(0, HF_START)
		}
	}
	else if(g_is_hf) {
		send_msg_hf(0, HFS_END)
		g_is_hf = 0
	}
}

public send_msg_hf(id, msg)
{
	switch(msg) {
		case HFS_END:
			zp_colored_print(id, "!g[Z-Evil]!t La super hora feliz ha terminado")
		case HFS_IS:
			zp_colored_print(id, "!g[Z-Evil]!t Ya es la super hora feliz disfruta mientras ganas el triple de ammopacks")
		case HFS_START:
			zp_colored_print(id, "!g[Z-Evil]!t La super hora feliz ha empezado, ganas el triple de ammopacks")
		case HFS_PRE_START:
			zp_colored_print(id, "!g[Z-Evil]!t En la siguiente ronda!g EMPEZARA!y la!g SUPER HORA FELIZ")
		case HFS_PRE_END:
			zp_colored_print(id, "!g[Z-Evil]!t En la siguiente ronda!g TEMINARA!y la!g SUPER HORA FELIZ")
		case HF_IS:
			zp_colored_print(id, "!g[Z-Evil]!t Ya es la hora feliz disfruta mientras ganas el doble de ammopacks")
		case HF_START:
			zp_colored_print(id, "!g[Z-Evil]!t La hora feliz ha empezado, ganas el doble de ammopacks")
		case HF_PRE_START:
			zp_colored_print(id, "!g[Z-Evil]!t En la siguiente ronda!g EMPEZARA!y la!g HORA FELIZ")
	}
}

 //----PUNTOS Y MEJORAS---------------------------------------------------//
//-----------------------------------------------------------------------//
public show_menu_puntos(id)
{
	new menu = menu_create("\rMejoras", "menu_puntos")
	
	menu_additem(menu, "\yMejoras Humana", "1", 0)
	menu_additem(menu, "\yMejoras Zombie", "2", 0)
	
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir")
	menu_display(id, menu, 0) 
}

public menu_puntos(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])
	
	switch(str_to_num(g_menu_slot))
	{
		case 1: show_menu_mejoras_h(id)
		case 2: show_menu_mejoras_z(id)
	} 
	play_soundmenu(id, SOUNDMENU_SELECT)
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public show_menu_mejoras_h(id)
{
	new str_num[2], porc, cost
	
	new max_mejoras = 8+g_reset_level[id]
	if(max_mejoras > 15) max_mejoras = 15
	
	formatex(g_item, charsmax(g_item),
	"\yMenu de mejoras Humana^n^nTienes \r%d\y puntos para gastar^nTienes \r%d\y puntos gastados^nGanaras puntos al \r Completar la Mision^n\yMax: \r%d/15",
	g_points[id][TEAM_HUMAN], g_points_spent[id][TEAM_HUMAN], max_mejoras)
	
	new menu = menu_create(g_item, "menu_mejoras_h")
	
	for(new i; i < MAX_IMPROV_HUMAN; i++)
	{
		porc = mejoras_p(i, 0, id);cost = mejoras_cost(i, 0)
		if(porc < 100 && cost <= g_points[id][TEAM_HUMAN])
			formatex(g_item, charsmax(g_item), "\w%s\y %%(%d) | \rAumentar (%d puntos)", H_IMPROV_NAMES[i], porc, cost)
		else
			formatex(g_item, charsmax(g_item), "\d%s %%(%d) | Aumentar (%d puntos)", H_IMPROV_NAMES[i], porc, cost)
			
		num_to_str(i , str_num, 1)
		menu_additem(menu, g_item, str_num, 0)
	}
	
	if(g_points[id][TEAM_HUMAN] >= 4 && g_points_spent[id][TEAM_HUMAN])
		formatex(g_item, charsmax(g_item), "\yResetear Mejoras Humanas \r(4 puntos)")
	else
		formatex(g_item, charsmax(g_item), "\dResetear Mejoras Humanas (4 puntos)")
	menu_additem(menu, g_item, "6", 0)
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)
}

public menu_mejoras_h(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])
	
	new key = str_to_num(g_menu_slot)

	if(key == 6 && g_points[id][TEAM_HUMAN] >= 4  && g_points_spent[id][TEAM_HUMAN])
	{
		if(++g_security_resets[id][0] > 3)
		{
			new ip[25], hid[20]
			get_user_ip(id, ip, 24, 0)
			get_user_info(id, "*HID", hid, 19)
			log_to_file("robo_reset.log", "1 cuenta:[%s] - ip:[%s] - hid:[%s]", g_name[id], ip, hid)
			
			g_points[id][TEAM_HUMAN] += 4*(g_security_resets[id][0]-1)
			
			server_cmd("kick #%d ^"Que haces ? o.O.^"", get_user_userid(id))
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}
		g_points[id][TEAM_HUMAN] += (g_points_spent[id][TEAM_HUMAN] - 4)
		g_points_spent[id][TEAM_HUMAN] = 0
		for(new i; i < MAX_IMPROV_HUMAN; i++)
			g_improv_human[id][i] = 0
	} 
	else if(key != 6 && mejoras_p(key, 0, id) < 100 && mejoras_cost(key,0) <= g_points[id][TEAM_HUMAN])
	{
		g_points[id][TEAM_HUMAN] -= mejoras_cost(key, 0)
		g_points_spent[id][TEAM_HUMAN] += mejoras_cost(key, 0)
		g_improv_human[id][key]++
		g_mejoras[id][0][key]++
		play_soundmenu(id, SOUNDMENU_SELECT)
	}
		
	menu_destroy(menu)
	show_menu_mejoras_h(id)
	return PLUGIN_HANDLED
}

public show_menu_mejoras_z(id)
{
	new max_mejoras = 11+g_reset_level[id]
	if(max_mejoras > 18) max_mejoras = 18
		
	formatex(g_item, charsmax(g_item),
	"\yMenu de mejoras Zombie^n^nTienes \r%d\y puntos para gastar^nTienes \r%d\y puntos gastados^nGanaras puntos al \r Completar la Mision^n\yMax: \r%d/18",
	g_points[id][TEAM_ZOMBIE], g_points_spent[id][TEAM_ZOMBIE], max_mejoras)
	
	new menu = menu_create(g_item, "menu_mejoras_z")
	
	new str_num[2], porc, cost
	
	for(new i; i < MAX_IMPROV_ZOMBIE; i++)
	{
		porc = mejoras_p(i, 1, id);cost = mejoras_cost(i, 1)
		if(porc < 100 && cost <= g_points[id][TEAM_ZOMBIE])
			formatex(g_item, charsmax(g_item), "\w%s\y %%(%d) | \rAumentar (%d puntos)", Z_IMPROV_NAMES[i], porc, cost)
		else
			formatex(g_item, charsmax(g_item), "\d%s %%(%d) | Aumentar (%d puntos)", Z_IMPROV_NAMES[i], porc, cost)
			
		num_to_str(i , str_num, 1)
		menu_additem(menu, g_item, str_num, 0)
	}
	
	if(g_points[id][TEAM_ZOMBIE] >= 4 && g_points_spent[id][TEAM_ZOMBIE])
		formatex(g_item, charsmax(g_item), "\yResetear Mejoras Zombies \r(4 puntos)")
	else
		formatex(g_item, charsmax(g_item), "\dResetear Mejoras Zombies (4 puntos)")
	menu_additem(menu, g_item, "5", 0)
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)
}

public menu_mejoras_z(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])
	
	new key = str_to_num(g_menu_slot)

	if(key == 5 && g_points[id][TEAM_ZOMBIE] >= 4 && g_points_spent[id][TEAM_ZOMBIE])
	{
		if(++g_security_resets[id][1] > 3)
		{
			new ip[25], hid[20]
			get_user_ip(id, ip, 24, 0)
			get_user_info(id, "*HID", hid, 19)
			log_to_file("robo_reset.log", "2 cuenta:[%s] - ip:[%s] - hid:[%s]", g_name[id], ip, hid)
			
			g_points[id][TEAM_ZOMBIE] += 4*(g_security_resets[id][1]-1)
			
			server_cmd("kick #%d ^"Que haces ? o.O.^"", get_user_userid(id))
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}
		
		g_points[id][1] += (g_points_spent[id][1] - 4)
		g_points_spent[id][1] = 0
		for(new i; i < MAX_IMPROV_ZOMBIE; i++)
			g_improv_zombie[id][i] = 0
	} 
	else if(key != 5  && mejoras_p(key, 1, id) < 100 && mejoras_cost(key,1) <= g_points[id][1])
	{
		g_points[id][1] -= mejoras_cost(key, 1)
		g_points_spent[id][1] += mejoras_cost(key, 1)
		g_improv_zombie[id][key]++
		g_mejoras[id][1][key]++
		play_soundmenu(id, SOUNDMENU_SELECT)
	}

	menu_destroy(menu)
	show_menu_mejoras_z(id)
	return PLUGIN_HANDLED
}

porcentaje(monto_ac, z, id)
{
	new max_mejoras
	if(z) 
	{
		max_mejoras = 11+g_reset_level[id]
		if(max_mejoras > 18) max_mejoras = 18
	}
	else {
		max_mejoras = 8+g_reset_level[id]
		if(max_mejoras > 15) max_mejoras = 15
	}

	new p = ((monto_ac * 100) / max_mejoras)
	if(p < 0) return 0;if(p > 100) return 100;
	return  p
}

//-Clases Humanas-----------------------------------------------------------
//----------------------------------------------------------------------------

public check_class_fixbug(id)
{
	while(g_hclass[g_humanclass[id]][HCLASS_LEVEL] > g_level[id]) {
		g_humanclass[id]--
	}
	while(g_zclass[g_zombieclass[id]][ZCLASS_LEVEL] > g_level[id]) {
		g_zombieclass[id]--
		g_zombieclassnext[id] = g_zombieclass[id]
	}
}

//-----Misiones--------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------

stock add_kill(id, classkill)
{
	if(g_mission_progress[id][classkill] < mission_kills(id, classkill))
		g_mission_progress[id][classkill]++

	g_kills[id][classkill]++
	
	check_mission(id)
}

stock mission_kills(id, classkill)
{
	static Float:fl_value
	
	switch(classkill)
	{
		case KILL_ZOMBIE: {
			fl_value = (g_mission[id][TEAM_HUMAN] * 4 + 4 + 0.3)
		}
		case KILL_NEMESIS: {
			if(g_mission[id][TEAM_HUMAN] < 5) return 0
			
			fl_value = ((g_mission[id][TEAM_HUMAN]-5) + 0.1 / 1.95)
		}
		case KILL_ASSASSIN: {
			if(g_mission[id][TEAM_HUMAN] < 7) return 0
			
			fl_value = ((g_mission[id][TEAM_HUMAN]-7) + 0.1 / 1.95)
		}
		case KILL_INFECT: {
			fl_value = (g_mission[id][TEAM_ZOMBIE] * 4 + 4 + 0.3)
		}
		case KILL_HUMAN: {
			fl_value = (g_mission[id][TEAM_ZOMBIE] * 3 + 2 + 0.3)
		}
		case KILL_SURVIVOR: {
			if(g_mission[id][TEAM_ZOMBIE] < 6) return 0
			
			fl_value = (((g_mission[id][TEAM_ZOMBIE] - 6) + 0.1) / 2.4)
		}
		case KILL_SNIPER: {
			if(g_mission[id][TEAM_ZOMBIE] < 8) return 0
			
			fl_value = (((g_mission[id][TEAM_ZOMBIE] - 8) + 0.1) / 2.6)
		}
		case KILL_CIVIL: {
			return 0
		}
		case KILL_UMBRELLA: {
			return 0
		}
		default: return 0
	}

	return floatround(fl_value)
}

check_mission(id)
{
	#define complete_kills(%1) (g_mission_progress[id][%1] >= mission_kills(id, %1))
	
	if(complete_kills(KILL_HUMAN) && complete_kills(KILL_INFECT) && complete_kills(KILL_SURVIVOR) && complete_kills(KILL_SNIPER))
	{
		new points = mission_reward(g_mission[id][TEAM_ZOMBIE])
		
		g_points[id][TEAM_ZOMBIE] += points
		g_mission[id][TEAM_ZOMBIE]++

		g_mission_progress[id][KILL_HUMAN] = 0
		g_mission_progress[id][KILL_INFECT] = 0
		g_mission_progress[id][KILL_SURVIVOR] = 0
		g_mission_progress[id][KILL_SNIPER] = 0
		
		SaveCuenta(id, 0)

		show_msgtutor(id, 3.5, 4, "Mision completada!")
		zp_colored_print(id, "!g[Z-Evil] !t Mision !y#%d !tcompletada!,ganaste !y%d !tpuntos Zombies", g_mission[id][TEAM_ZOMBIE], points)
		emit_sound(id, CHAN_VOICE, sound_mission_complete, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	if(complete_kills(KILL_ZOMBIE) && complete_kills(KILL_NEMESIS) && complete_kills(KILL_ASSASSIN))
	{
		new points = mission_reward(g_mission[id][TEAM_HUMAN])

		g_points[id][TEAM_HUMAN] += points
		g_weapons_puntos[id][0] += points
		g_mission[id][TEAM_HUMAN]++

		g_mission_progress[id][KILL_ZOMBIE] = 0
		g_mission_progress[id][KILL_NEMESIS] = 0
		g_mission_progress[id][KILL_ASSASSIN] = 0
		
		SaveCuenta(id, 0)

		show_msgtutor(id, 3.5, 4, "Mision completada!")
		zp_colored_print(id, "!g[Z-Evil] !t Mision !y#%d !tcompletada!,ganaste !y%d !tpuntos Humanos y de Armas", g_mission[id][TEAM_HUMAN], points)
		emit_sound(id, CHAN_VOICE, sound_mission_complete, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

stock mission_reward(mission)
{
	if(mission <= 2) return 2

	new Float:points = (mission*0.7)
	
	if(points >= 30.0) return 30

	return floatround(points)
}

//--------------------------------------------------------
public infeccion_efec(task)
{
	static id;id = task-TASK_INFECTION
	if(!g_infected[id] || !g_is_alive[id])
	{
		remove_task(task)
		return
	}
	
	switch(g_infection_level[id])
	{
		case 0: {
			message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
			write_short(UNIT_SECOND*7) // duration
			write_short(UNIT_SECOND*1) // hold time
			write_short(0x0001) // fade type
			write_byte(215) // r
			write_byte(20) // g
			write_byte(20) // b
			write_byte(215) // alpha
			message_end()
		}
		case 1: {
			emit_sound(id, CHAN_VOICE, sound_transformation, 0.5, ATTN_NORM, 0, PITCH_NORM)
			screenshake(id)
		}
		case 2: drop_weapons(id, 1)
		case 3: drop_weapons(id, 2)
		case 4: {
			zombieme(id, CLASS_ZOMBIE, 0, 1)
			remove_task(task)
			emit_sound(id, CHAN_VOICE, zombie_infect[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	g_infection_level[id]++
}

screenshake(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*60)
	write_short((1<<12)*60)
	write_short((1<<12)*60)
	message_end() 
}

// Parachute-----------------------------
parachute_reset(id)
{
	if(g_parachute_entity[id] > 0)
		if(is_valid_ent(g_parachute_entity[id]))
			remove_entity(g_parachute_entity[id])

	if(g_is_alive[id]) player_gravity(id)
	
	g_parachute_entity[id] = 0
}

// Spinel y ExtraArmor ------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------

public fw_touch_powerbox(ent, id)
{
	if(!is_user_valid_alive(id) || is_any_zombie(id)) return

	set_user_armor(id, (get_user_armor(id)+random_num(30, 100)))
	set_user_health(id, (get_user_health(id)+random_num(50, 200)))
	emit_sound(id, CHAN_VOICE, sound_powerbox, 1.0, ATTN_NORM, 0, PITCH_NORM)

	remove_entity(ent)
}

// Crear ent------------------------------------------
create_recompensa(id)
{
	if(g_endround) return

	new Float:origin[3], Float:velocity[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	entity_get_vector(id, EV_VEC_velocity, velocity)
	
	origin[0] += random_float(-7.0, 7.0)
	origin[1] += random_float(-7.0, 7.0)
	origin[2] += 3.5

	new ent = create_entity("info_target")
	entity_set_string(ent, EV_SZ_classname, classname_powerbox) 
	entity_set_model(ent, model_powerbox)
	set_rendering(ent, kRenderFxGlowShell, 20, 255, 20, kRenderNormal, 10);

	entity_set_vector(ent, EV_VEC_mins, Float:{ -1.5, -1.5, -0.0 })
	entity_set_vector(ent, EV_VEC_maxs, Float:{ 1.5, 1.5, 4.5 })
	entity_set_size(ent, Float:{ -1.5, -1.5, -0.0 }, Float:{ 1.5, 1.5, 4.5 })

	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
	
	entity_set_float(ent, EV_FL_gravity, 0.77)
	entity_set_vector(ent, EV_VEC_velocity, velocity)

	entity_set_edict(ent, EV_ENT_owner, id)
	entity_set_origin(ent, origin)
}

// Bomba nuclear--------------------------------------------------------
//----------------------------------------------------------------------
public task_launch()
{
	// Launch sound
	client_cmd(0, "spk %s", sound_nuc_misil)
	
	// Screen fade effect
	message_begin(MSG_BROADCAST, g_msgScreenFade)
	write_short((1<<12)*4)	// Duration
	write_short((1<<12)*1)	// Hold time
	write_short(0x0001)	// Fade type
	write_byte (110)	// Red
	write_byte (255)	// Green
	write_byte (110)	// Blue
	write_byte (255)	// Alpha
	message_end()
}

public task_blast()
{
	client_cmd(0, "spk %s", sound_nuc_exp)

	message_begin(MSG_BROADCAST, g_msgScreenShake)
	write_short((1<<12)*100)
	write_short((1<<12)*5)
	write_short((1<<12)*60)
	message_end() 

	new id, deathmsg_block

	deathmsg_block = get_msg_block(g_msgDeathMsg)
	
	set_msg_block(g_msgDeathMsg, BLOCK_SET)

	for(id = 1; id <= 32; id++)
		if (g_is_alive[id])
			user_kill(id, 1)

	set_msg_block(g_msgDeathMsg, deathmsg_block)
}

// Avilidades Zombies-----------------------------------------------------------
set_zgohst(id)
{
	if(is_zombie(id) && g_zombieclass[id] == 5)
	{
		set_user_rendering(id, kRenderFxGlowShell, 100, 10, 10, kRenderTransAlpha, 5)
	}
}

public set_regenerate(id)
{
	if(!g_is_alive[id] || !is_zombie(id))
		return

	if(!z_regenerating[id] && g_zombieclass[id] == 6)
	{
		if(get_user_health(id) < g_zclass[6][ZCLASS_HEALTH])
		{
			z_regenerating[id] = true
			set_task(2.0, "regenerate", id+7556, _, _, "b")
		}
	}
}

public regenerate(id)
{
	id -=  7556
	if(!g_is_alive[id] || !is_zombie(id))
	{
		remove_task(id+7556)
		z_regenerating[id] = false
		return
	}
	static health
	health = get_user_health(id)

	if(health < g_zclass[6][ZCLASS_HEALTH])
		set_user_health(id, health + 95)
	if(health >= g_zclass[6][ZCLASS_HEALTH])
	{
		remove_task(id+7556)
		z_regenerating[id] = false
	}
}

public curar_team(id)
{
	if(!g_is_alive[id] || (g_zombieclass[id] != 8) || !is_zombie(id))
		return

	if(z_warlock[id] >= 2)
	{
		static distance, i
		for(i = 1; i <= g_maxplayers; i++)
		{
			if(i != id && g_is_alive[i] && is_zombie(i))
			{
				distance = get_entity_distance(i, id)
				if (distance <= 250)
				{
					if(get_user_health(i) < g_zclass[g_zombieclass[i]][ZCLASS_HEALTH])
						set_user_health(i, g_zclass[g_zombieclass[i]][ZCLASS_HEALTH])
				}
			}
		}
		static origin[3]
		get_user_origin(id, origin)

		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_DLIGHT)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_byte(200) // radius
		write_byte(100) // r
		write_byte(100) // g
		write_byte(255) // b	
		write_byte(6)
		write_byte(30)
		message_end()
		z_warlock[id] = 0
	}
	else if(z_warlock[id] < 2)
		zp_colored_print(id, "!g[Z-Evil]!t Necesitas %d infecciones para usar esta habilidad.", (2 - z_warlock[id]))
}

// Send E-Mail-----------------------------------------------------------------------
//---------------------------------------------------------------------------------
stock send_email(id, email_id, msg[])
{
	static send_msg[512]

	urlencode(msg, send_msg, 511)

	format(send_msg, 511, "http://www.onlyarg.com/server/ze30/mail.php?user=%d&msg=%s", g_user_id[id], send_msg)
	show_motd(id, send_msg, "send E-Mail")
	Save_small(id, "send_email='%d'", email_id)
}

//-ZP Ban--------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------

public cmd_ban(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[15], horas, time_ban
	read_argv(1, arg, 14)
	horas = str_to_num(arg)
	time_ban = (time() + (3600 * horas))

	g_admbantime[id] = time_ban
	show_player_menu(id)

	return PLUGIN_CONTINUE
}

public show_player_menu(id) 
{
	new str_num[3]
	new menu = menu_create("Players:", "player_menu")  

	for (new i = 1; i <= g_maxplayers; i++)
	{
		if(!is_user_connected(i))
			continue
		num_to_str(i,str_num, 2)
		menu_additem(menu, g_name[i], str_num)
	}
	menu_display(id, menu, 0)
}

public player_menu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])

	new targe = str_to_num(g_menu_slot)

	Save_small(targe, "ban='%d'", g_admbantime[id])

	server_cmd("kick #%d ^"Tu cuenta fue baneada.^"", get_user_userid(targe))

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public show_ban_razon(id)
{
	if(!g_is_banned[id]) return PLUGIN_HANDLED
	
	new link[64]
	formatex(link, 63, "http://onlyarg.com/server/ze30/ban_razon.php?user=%d", g_user_id[id])
	show_motd(id, link, "Razon del ban")

	return PLUGIN_HANDLED
}

//--------------------------------------------------------------------------------------------
//----Menu Mejoras de arma-------------------------------------------------------------------
//--------------------------------------------------------------------------------------------

public show_menu_wmejoras(id)
{
	new item[91], num[3], menu

	menu = menu_create("\rElija un arma", "menu_wmejoras")

	for(new i = 0; i < sizeof weapons_id; i++) {
		num_to_str(i, num, 2)
		
		if(g_reset_level[id] < wm_cost[i][1] || g_level[id] < wm_cost[i][0])
			formatex(item, 90, "\d%s \r[%d lvl,%d reset]", wm_name[i], wm_cost[i][0], wm_cost[i][1])
		else
			formatex(item, 90, "%s", wm_name[i])
			
		menu_additem(menu, item, num)
	}

	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)
}

public menu_wmejoras(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])

	play_soundmenu(id, SOUNDMENU_SELECT)
	new key = str_to_num(g_menu_slot)

	if(g_reset_level[id] < wm_cost[key][1] || g_level[id] < wm_cost[key][0])
	{
		menu_display(id, menu, 0)
		return PLUGIN_HANDLED
	}
	show_menu_wmejoras2(id, key)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}


public show_menu_wmejoras2(id, wkey)
{
	static item[128], p, cost, pts
	
	g_menu_mweapon[id] = wkey
	pts = g_weapons_puntos[id][0]
	
	formatex(item, charsmax(item), "\yMenu de mejoras:Arma: %s^n^nTienes \r%d\y puntos para gastar^nTienes \r%d\y puntos gastados", WEAPONNAMES[weapons_id[wkey]], pts, g_weapons_puntos[id][1])
	new menu = menu_create(item, "menu_wmejoras2")
	
	
	cost = wm_mejora_cost(0)
	p = porcentaje_wm(id, wkey, 0)
	if(p < 99 && cost <= pts)
		formatex(item, charsmax(item), "\wClip\y %%(%d) | \rMejorar (%d puntos)", p, cost)
	else
		formatex(item, charsmax(item), "\dClip %%(%d) | Mejorar (%d puntos)", p, cost)
	menu_additem(menu, item, "1", 0)
	
	
	cost = wm_mejora_cost(1)
	p = porcentaje_wm(id, wkey, 1)
	if(p < 99 && cost <= pts)
		formatex(item, charsmax(item), "\wRecoil\y %%(%d) | \rMejorar (%d puntos)", p, cost)
	else
		formatex(item, charsmax(item), "\dRecoil %%(%d) | Mejorar (%d puntos)", p, cost)
	menu_additem(menu, item, "2", 0)
	
	
	cost = wm_mejora_cost(2)
	p = porcentaje_wm(id, wkey, 2)
	if(p < 99 && cost <= pts)
		formatex(item, charsmax(item), "\wSpeed\y %%(%d) | \rMejorar (%d puntos)", p, cost)
	else
		formatex(item, charsmax(item), "\dSpeed %%(%d) | Mejorar (%d puntos)", p, cost)
	menu_additem(menu, item, "3", 0)
	

	if(pts >= 4 && (g_weapons_mejoras[id][wkey][0] || g_weapons_mejoras[id][wkey][1] || g_weapons_mejoras[id][wkey][2]))
		formatex(item, charsmax(item), "\yResetear mejoras de esta Arma\r(4 puntos)")
	else
		formatex(item, charsmax(item), "\dResetear mejoras de esta Arma(4 puntos)")
	menu_additem(menu, item, "4", 0)
	
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)
}

public menu_wmejoras2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		play_soundmenu(id, SOUNDMENU_CANCEL)
		return PLUGIN_HANDLED
	}
	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])
	
	new wkey = g_menu_mweapon[id]
	
	switch(str_to_num(g_menu_slot))
	{
		case 1: {
			if(porcentaje_wm(id, wkey, 0) < 99 && wm_mejora_cost(0) <= g_weapons_puntos[id][0]){
				g_weapons_puntos[id][0] -= wm_mejora_cost(0)
				g_weapons_puntos[id][1] += wm_mejora_cost(0)
				g_weapons_mejoras[id][wkey][0]++
				play_soundmenu(id, SOUNDMENU_SELECT)
			}
		}
		case 2: {
			if(porcentaje_wm(id, wkey, 1) < 99 && wm_mejora_cost(1) <= g_weapons_puntos[id][0]){
				g_weapons_puntos[id][0] -= wm_mejora_cost(1)
				g_weapons_puntos[id][1] += wm_mejora_cost(1)
				g_weapons_mejoras[id][wkey][1]++
				play_soundmenu(id, SOUNDMENU_SELECT)
			}
		}
		case 3: {
			if(porcentaje_wm(id, wkey, 2) < 99 && wm_mejora_cost(2) <= g_weapons_puntos[id][0]){
				g_weapons_puntos[id][0] -= wm_mejora_cost(2)
				g_weapons_puntos[id][1] += wm_mejora_cost(2)
				g_weapons_mejoras[id][wkey][2]++
				play_soundmenu(id, SOUNDMENU_SELECT)
			}
		}
		case 4: {
			if(g_weapons_puntos[id][0] >= 4 && (g_weapons_mejoras[id][wkey][0] || g_weapons_mejoras[id][wkey][1] || g_weapons_mejoras[id][wkey][2]))
			{
				if(++g_security_resets[id][2] > 3)
				{
					new ip[25], hid[20]
					get_user_ip(id, ip, 24, 0)
					get_user_info(id, "*HID", hid, 19)
					log_to_file("robo_reset.log", "3 cuenta:[%s] - ip:[%s] - hid:[%s]", g_name[id], ip, hid)
			
					g_weapons_puntos[id][0] += 4*3
			
					server_cmd("kick #%d ^"Que haces ? o.O.^"", get_user_userid(id))
					menu_destroy(menu)
					return PLUGIN_HANDLED
				}
				new cost
				play_soundmenu(id, SOUNDMENU_SELECT)
				for(new i; i < 3; i++)
				{
					while(g_weapons_mejoras[id][wkey][i])
					{
						cost += ((((g_weapons_mejoras[id][wkey][i] - 1) + (wkey + 4)) * 3) - 1)
						g_weapons_mejoras[id][wkey][i]--
					}
				}
				g_weapons_puntos[id][0] += (cost - 4)
				g_weapons_puntos[id][1] -= cost
			}
		}
	} 
	
	menu_destroy(menu)
	show_menu_wmejoras2(id, wkey)
	return PLUGIN_HANDLED
}

stock porcentaje_wm(id, wkey, tip)
{
	static valor
	valor = ((g_weapons_mejoras[id][wkey][tip] * 100) / 11)
	return valor
}

//------------------------------------------------------------------
// PARTY------------------------------------------------------------
public show_menu_party(id)
{
	new len
	len = formatex(g_item, charsmax(g_item), "\yParty Zombie-Evil 3.0.0Beta:^n^n")
	
	if(g_party[id][PARTY_ID])
	{
		len += formatex(g_item[len], charsmax(g_item)-len, "\rMiembros %d/%d:^n", g_party[g_party[id][PARTY_ID]][PARTY_MIEMBROS], MAX_PARTY_MEMBER)
		len += formatex(g_item[len], charsmax(g_item)-len, "\r-\y%s \r[lvl:%d] (Lider)^n\w", g_name[g_party[id][PARTY_ID]], g_level[g_party[id][PARTY_ID]])
		for(new i=1; i <= g_maxplayers; i++) {
			if(i == g_party[id][PARTY_ID] || !g_is_connected[i] || i == g_party[id][PARTY_ID] || g_party[id][PARTY_ID] != g_party[i][PARTY_ID]) continue;
			
			len += formatex(g_item[len], charsmax(g_item)-len, "\r-\d%s \r[lvl:%d]^n", g_name[i], g_level[i])
		}

		len += formatex(g_item[len], charsmax(g_item)-len, "^n\yAmmopack Ganados: \d%d^n\yTotal de Combos: \d%d^n", g_party[g_party[id][PARTY_ID]][PARTY_APS], g_party[g_party[id][PARTY_ID]][PARTY_COMBO])
	}
	else	len += formatex(g_item[len], charsmax(g_item)-len, "\r <No estas en party>^n")
	
	if(!g_party[id][PARTY_ID] || g_party[id][PARTY_ID] == id)
		len += formatex(g_item[len], charsmax(g_item)-len, "^n\r1.\wInvitar^n")
	else
		len += formatex(g_item[len], charsmax(g_item)-len, "^n\d1.Invitar^n")
	
	if(!g_party[id][PARTY_ID])
	{
		len += formatex(g_item[len], charsmax(g_item)-len, "\r2.\wInvitaciones recibidas \y(%d)^n^n", g_pedidos[id][0])
		
	}
	else if(g_party[id][PARTY_ID] == id) {
		len += formatex(g_item[len], charsmax(g_item)-len, "\r2.\wRomper party^n")
		if(g_party[g_party[id][PARTY_ID]][PARTY_MIEMBROS])
			len += formatex(g_item[len], charsmax(g_item)-len, "\r3.\wEchar^n^n")
		else
			len += formatex(g_item[len], charsmax(g_item)-len, "\d3.Echar^n^n")
	}
	else 
		len += formatex(g_item[len], charsmax(g_item)-len, "\r2.\wSalir del party^n^n")
		
	len += formatex(g_item[len], charsmax(g_item)-len, "\r0.\wSalir")

	show_menu(id, KEYSMENU_PARTY, g_item, -1, "party_menu_principal")
}

public menu_party(id, key)
{
	switch(key)
	{
		case 0: {
			if(!g_party[id][PARTY_ID] || g_party[id][PARTY_ID] == id) {
				if(g_party[id][PARTY_MIEMBROS] >= MAX_PARTY_MEMBER) {
					zp_colored_print(id, "!g[Z-Evil] !tNo se puede invitar mas miebros al party.")
					return PLUGIN_HANDLED
				}
				show_menu_invitar(id)
			}
			else
				show_menu_party(id)
		}
		case 1: {
			if(!g_party[id][PARTY_ID])
				show_menu_pedidos(id)
			else if(g_party[id][PARTY_ID] == id)
				destroyall_party(id)
			else 
				salir_party(id, 0)
		}
		case 2: {
			if(g_party[id][PARTY_ID] == id && g_party[g_party[id][PARTY_ID]][PARTY_MIEMBROS])
				show_menu_echar(id)
			else show_menu_party(id)
		}
	}
	return PLUGIN_HANDLED
}

public show_menu_invitar(id)
{
	new str_num[3]
	new menu = menu_create("Party: invitar", "menu_invitar")  

	for (new i = 1; i <= g_maxplayers; i++)
	{
		if(i == id || !g_is_connected[i]) continue

		num_to_str(i, str_num, 2)

		if(g_party[i][PARTY_ID] == id)
			formatex(g_item, charsmax(g_item), "\d%s\y(lvl:%d)\r[Mienbro]", g_name[i], g_level[i])
		else if(g_party[i][PARTY_ID])
			formatex(g_item, charsmax(g_item), "\d%s\y(lvl:%d)\r[En Party]", g_name[i], g_level[i])
		else if(g_pedidos[i][id])
			formatex(g_item, charsmax(g_item), "%s\y(lvl:%d)\r[Invitado]", g_name[i], g_level[i])
		else
			formatex(g_item, charsmax(g_item), "%s\y(lvl:%d)", g_name[i], g_level[i])

		menu_additem(menu, g_item, str_num)
	}
	menu_display(id, menu, 0)
}

public menu_invitar(id, menu, item)
{
	if(item == MENU_EXIT || (g_party[id][PARTY_ID] && g_party[id][PARTY_ID] != id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])

	new player = str_to_num(g_menu_slot)

	if(g_party[player][PARTY_ID])
	{
		menu_display(id, menu, 0)
		return PLUGIN_HANDLED
	}
	
	if(g_pedidos[player][id])
	{
		show_menu_inv_accion(id, player)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	g_pedidos[player][id] = 1
	g_pedidos[player][0]++
	zp_colored_print(id, "!g[Z-Evil] !tInvitacion enviada.")
	zp_colored_print(player, "!g[Z-Evil] !y%s !tte invito a un party.", g_name[id])
		
	show_menu_invitar(id)
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public show_menu_inv_accion(id, player)
{
	PARTY_INV_ACCION = player
	formatex(g_item, charsmax(g_item), "\rParty:^n\y?Que quieres hacer con la invitacion a \d %s \y?", g_name[player])
	
	new menu = menu_create(g_item, "menu_inv_accion")  

	menu_additem(menu, "Re-Enviar invitacion", "1")
	menu_additem(menu, "Cancelar invitacion", "2")

	menu_display(id, menu, 0)
}

public menu_inv_accion(id, menu, item)
{
	new player = PARTY_INV_ACCION
	
	if(item == MENU_EXIT || (g_party[id][PARTY_ID] && g_party[id][PARTY_ID] != id) || !g_is_connected[player] || !g_pedidos[player][id] || g_party[player][PARTY_ID])
	{
		show_menu_invitar(id)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])
	
	if(str_to_num(g_menu_slot) == 1)
	{
		zp_colored_print(id, "!g[Z-Evil] !tInvitacion Re-Enviada.")
		zp_colored_print(player, "!g[Z-Evil] !y%s !tte recuerda que te invito a un party.", g_name[id])	
	}
	else {
		g_pedidos[player][id] = 0
		g_pedidos[player][0]--
		zp_colored_print(id, "!g[Z-Evil] !tInvitacion cancelada.")
		zp_colored_print(player, "!g[Z-Evil] !y%s !tcancelo la invitacion a un party.", g_name[id])
	}
	
	show_menu_invitar(id)
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public show_menu_echar(id)
{
	new str_num[3]
	new menu = menu_create("Party: echar", "menu_echar")

	for (new i = 1; i <= g_maxplayers; i++)
	{
		if(i == id || !g_is_connected[i]) continue
			
		if(g_party[i][PARTY_ID] != id) continue

		num_to_str(i, str_num, 2)
		menu_additem(menu, g_name[i], str_num)
	}
	menu_display(id, menu, 0)
}

public menu_echar(id, menu, item)
{
	if(item == MENU_EXIT || (g_party[id][PARTY_ID] && g_party[id][PARTY_ID] != id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])

	new player = str_to_num(g_menu_slot)

	if(g_party[player][PARTY_ID] != id)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	salir_party(player, 1)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public show_menu_pedidos(id)
{
	new str_num[3]
	new menu = menu_create("Party: pedidos", "menu_pedidos")  

	for (new i = 1; i <= g_maxplayers; i++)
	{
		if(i == id || !g_is_connected[i]) continue
			
		if(!g_pedidos[id][i]) continue

		if(!g_party[i][PARTY_ID])
			formatex(g_item, charsmax(g_item), "%s\y(lvl:%d)", g_name[i], g_level[i])
		else if(g_party[i][PARTY_MIEMBROS] < MAX_PARTY_MEMBER)
			formatex(g_item, charsmax(g_item), "%s\y(lvl:%d)\r[%d/%d]", g_name[i], g_level[i], g_party[i][PARTY_MIEMBROS], MAX_PARTY_MEMBER)
		else
			formatex(g_item, charsmax(g_item), "\d%s\y(lvl:%d)\r[FULL]", g_name[i], g_level[i])
		
		num_to_str(i, str_num, 2)
		menu_additem(menu, g_name[i], str_num)
	}
	menu_display(id, menu, 0)
}

public menu_pedidos(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	menu_item_getinfo(menu, item, g_menu_null[0], g_menu_slot, 2, g_menu_null, 1, g_menu_null[0])

	new lider = str_to_num(g_menu_slot)

	if(!g_pedidos[id][lider] || (g_party[lider][PARTY_ID] && g_party[lider][PARTY_ID] != lider))
	{
		zp_colored_print(id, "!g[Z-Evil] !tError al aceptar el party.")
		show_menu_pedidos(id)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(!g_party[lider][PARTY_ID])
	{
		g_party[lider][PARTY_ID] = lider
		g_party[lider][PARTY_MIEMBROS]++
	}
	else {
		if(g_party[lider][PARTY_MIEMBROS] >= MAX_PARTY_MEMBER)
		{
			zp_colored_print(id, "!g[Z-Evil] !tParty lleno.No te puedes unirte.")
			show_menu_pedidos(id)
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}
		
		for(new i = 1; i <= g_maxplayers; i++) {
			if(i == lider) continue;

			if(g_party[i][PARTY_ID] == lider)
				zp_colored_print(i, "!g[Z-Evil] !y%s !tse unio al party.", g_name[id])
		}
	}

	g_party[id][PARTY_ID] = lider
	g_party[lider][PARTY_MIEMBROS]++

	clear_pedidos(id)

	zp_colored_print(lider, "!g[Z-Evil] !y%s !tacepto el party.", g_name[id])
	zp_colored_print(id, "!g[Z-Evil] !tTe uniste al party.")

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public clear_pedidos(id)
{
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(g_pedidos[i][id]) g_pedidos[i][0]--
		g_pedidos[i][id] = 0
	}
}

public destroyall_party(id)
{
	if(g_party[id][PARTY_ID] != id)
		return
	
	g_party[id][PARTY_MIEMBROS] = 0
	g_party[id][PARTY_APS] = 0
	g_party[id][PARTY_COMBO] = 0

	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(g_pedidos[i][id]) g_pedidos[i][0]--
		g_pedidos[i][id] = 0
		if(g_party[i][PARTY_ID] == id)
		{
			g_party[i][PARTY_ID] = 0
			zp_colored_print(i, "!g[Z-Evil] !tParty destruido.")
		}
	}
	g_party[id][PARTY_ID] = 0
}

public salir_party(id, tipe)
{
	if(!g_party[id][PARTY_ID])
		return

	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(i == id)
			continue

		if(g_party[i][PARTY_ID] == g_party[id][PARTY_ID]) {
			if(tipe)
				zp_colored_print(i, "!g[Z-Evil] !y%s !tfue echado del party.", g_name[id])
			else
				zp_colored_print(i, "!g[Z-Evil] !y%s !tabandono el party.", g_name[id])
		}
	}
	
	if(g_pedidos[id][g_party[id][PARTY_ID]]) g_pedidos[id][0]--
	g_pedidos[id][g_party[id][PARTY_ID]] = 0

	if(--g_party[g_party[id][PARTY_ID]][PARTY_MIEMBROS]<=0)
		destroyall_party(g_party[id][PARTY_ID])
		
	g_party[id][PARTY_ID] = 0
}

// dhud stocks removed: set_dhudmessage and show_dhudmessage are natives in AMXMODX 1.9.0

/*================================================================================
[Natives, Precache and Init]
=================================================================================*/

public plugin_natives()
{
	// Player specific natives
	register_native("zp_get_user_zombie", "native_get_user_zombie", 1)
	register_native("zp_get_user_nemesis", "native_get_user_nemesis", 1)
	register_native("zp_get_user_assassin", "native_get_user_assassin", 1)
	register_native("zp_get_user_sniper", "native_get_user_sniper", 1)
	register_native("zp_get_user_survivor", "native_get_user_survivor", 1)
	register_native("zp_get_user_first_zombie", "native_get_user_first_zombie", 1)
	register_native("zp_get_user_last_zombie", "native_get_user_last_zombie", 1)
	register_native("zp_get_user_last_human", "native_get_user_last_human", 1)
	register_native("zp_get_user_ammo_packs", "native_get_user_ammo_packs", 1)
	register_native("zp_set_user_ammo_packs", "native_set_user_ammo_packs", 1)
	register_native("zp_add_user_points", "native_add_user_points", 1)
	register_native("zp_respawn_user", "native_respawn_user", 1)
	
	// Round natives
	register_native("zp_has_round_started", "native_has_round_started", 1)
	register_native("zp_is_nemesis_round", "native_is_nemesis_round", 1)
	register_native("zp_is_assassin_round", "native_is_assassin_round", 1)
	register_native("zp_is_sniper_round", "native_is_sniper_round", 1)
	register_native("zp_is_survivor_round", "native_is_survivor_round", 1)
	register_native("zp_is_swarm_round", "native_is_swarm_round", 1)
	register_native("zp_is_plague_round", "native_is_plague_round", 1)
	
	// External additions natives
	register_native("zp_register_extra_item", "native_register_extra_item", 1)
	register_native("zp_get_user_level", "native_get_user_level", 1)
	register_native("zp_set_user_level", "native_set_user_level", 1)
	
	// Load up the hard coded extra items
	native_register_extra_item2("NightVision (una ronda)", 4, ZP_TEAM_HUMAN, 0, 0, 0)
	native_register_extra_item2("Antidoto Virus-T", 13, ZP_TEAM_ZOMBIE, 0, 0, 3)
	native_register_extra_item2("Furia Zombie", 11, ZP_TEAM_ZOMBIE, 10, 0, 3)
	native_register_extra_item2("Bomba de Infeccion", 20, ZP_TEAM_ZOMBIE, 15, 0, 1)
	native_register_extra_item2("Bomba Antidoto", 21, ZP_TEAM_HUMAN, 0, 0, 0)
	native_register_extra_item2("Campo de fuerza (60 seg)", 23, ZP_TEAM_HUMAN, 0, 0, 4)
	native_register_extra_item2("Unlimited Clip (120 seg)", 24, ZP_TEAM_HUMAN, 0, 125, 10)
}

public plugin_precache()
{
	register_forward(FM_Sys_Error, "fw_Sys_Error")

	precache_model("sprites/Granadas_spr.spr")
	precache_model("sprites/Granadas_spr2.spr")
	
	precache_model("models/player/OA-Zraptor/OA-ZraptorT.mdl")
	
	new precache[32]
	
	for(new i; i < sizeof new_grenades; i++)
	{
		formatex(precache, 31, "sprites/%s.txt", new_grenades[i][WL_NAME])
		precache_generic(precache)
	}

	precache_model("models/parachute.mdl")

	new i, playermodel[100]

	for(i = 0; i < sizeof sound_menu; i++)
		precache_sound(sound_menu[i])

	// Precache player models-----------------------------------------
	format(playermodel, charsmax(playermodel), "models/player/%s/%s.mdl", model_nemesis, model_nemesis)
	model_nemesis_index = precache_model(playermodel)

	format(playermodel, charsmax(playermodel), "models/player/%s/%s.mdl", model_survivor, model_survivor)
	precache_model(playermodel)

	format(playermodel, charsmax(playermodel), "models/player/%s/%s.mdl", model_assassin, model_assassin)
	model_assassin_index = precache_model(playermodel)

	format(playermodel, charsmax(playermodel), "models/player/%s/%s.mdl", model_admin, model_admin)
	precache_model(playermodel)
	
	format(playermodel, charsmax(playermodel), "models/player/%s/%s.mdl", model_sniper, model_sniper)
	precache_model(playermodel)
	
	precache_model(model_powerbox)
	precache_model(model_powerboxt)

	precache_model(model_vknife_nemesis)
	precache_model(model_v_survivor)
	precache_model(model_p_survivor)
	precache_model(model_grenade_infect)

	precache_model(model_v_grenade_fire)
	precache_model(model_p_grenade_fire)
	precache_model(model_w_grenade_fire)

	precache_model(model_v_grenade_frost)
	precache_model(model_p_grenade_frost)
	precache_model(model_w_grenade_frost)

	precache_model(model_v_grenade_flare)
	precache_model(model_p_grenade_flare)
	precache_model(model_w_grenade_flare)

	precache_model(model_v_grenade_field)
	precache_model(model_forcefield)
	precache_model(model_w_grenade_field)

	precache_model(model_v_grenade_molotov)
	precache_model(model_p_grenade_molotov)
	precache_model(model_w_grenade_molotov)
	
	precache_model(model_v_grenade_anti)
	precache_model(model_p_grenade_anti)
	precache_model(model_w_grenade_anti)
	
	precache_model(model_v_grenade_he)
	precache_model(model_p_grenade_he)


	g_molotovFireStr[0] = precache_model("oa-ze/spr/fire2.spr")
	g_molotovFireStr[1] = precache_model("oa-ze/spr/fire.spr")
	g_glowSpr = precache_model("oa-ze/spr/frost_gib.spr")
	g_trailSpr = precache_model("sprites/lgtning.spr")
	g_exploSpr = precache_model("sprites/shockwave.spr")
	g_exploSpr2 = precache_model("oa-ze/spr/inf.spr")
	g_flameSpr = precache_model("sprites/flame.spr")
	g_smokeSpr = precache_model("sprites/black_smoke3.spr")
	g_glassSpr = precache_model("models/glassgibs.mdl")
	g_smokeSpr2 = precache_model("sprites/steam1.spr")
	g_particleSpr = precache_model("oa-ze/spr/particula.spr")
	g_bubblesSpr = precache_model("sprites/bubble.spr")
	g_exploSpr3 = precache_model("sprites/underxplo.spr")
	g_exploSpr4 = precache_model("oa-ze/spr/frost_explode.spr")

	// Custom sounds------------------------------------------------
	precache_sound(sound_he_exp)
	precache_sound(sound_nuc_exp)
	precache_sound(sound_nuc_misil)
	precache_sound(sound_nuc_warning)
	precache_sound(sound_assassin)
	precache_sound(sound_neme_death)
	precache_sound(sound_levelup)
	precache_sound(sound_leveldonw)
	precache_sound(sound_mission_complete)
	precache_sound(sound_transformation)
	precache_sound(sound_nvgon)
	precache_sound(sound_nvgoff)
	precache_sound(sound_powerbox)
	precache_sound(sound_tutor_msg)
	precache_sound(sound_pickup)
	precache_sound(sound_antidote)
	precache_sound(sound_flare)
	precache_sound(sound_armorhit)
	precache_sound(sound_molotov_exp)
	precache_sound(sound_umbrella)
	
	for (i = 0; i < sizeof sound_win_zombies; i++)
		precache_sound(sound_win_zombies[i])
	for (i = 0; i < sizeof sound_win_humans; i++)
		precache_sound(sound_win_humans[i])
	for (i = 0; i < sizeof zombie_infect; i++)
		precache_sound(zombie_infect[i])
	for (i = 0; i < sizeof zombie_pain; i++)
		precache_sound(zombie_pain[i])
	for (i = 0; i < sizeof nemesis_pain; i++)
		precache_sound(nemesis_pain[i])
	for (i = 0; i < sizeof zombie_die; i++)
		precache_sound(zombie_die[i])
	for (i = 0; i < sizeof zombie_fall; i++)
		precache_sound(zombie_fall[i])
	for (i = 0; i < sizeof zombie_miss_slash; i++)
		precache_sound(zombie_miss_slash[i])
	for (i = 0; i < sizeof zombie_miss_wall; i++)
		precache_sound(zombie_miss_wall[i])
	for (i = 0; i < sizeof zombie_hit_normal; i++)
		precache_sound(zombie_hit_normal[i])
	for (i = 0; i < sizeof zombie_hit_stab; i++)
		precache_sound(zombie_hit_stab[i])
	for (i = 0; i < sizeof zombie_idle; i++)
		precache_sound(zombie_idle[i])
	for (i = 0; i < sizeof zombie_idle_last; i++)
		precache_sound(zombie_idle_last[i])	
	for (i = 0; i < sizeof zombie_madness; i++)
		precache_sound(zombie_madness[i])
	for (i = 0; i < sizeof sound_nemesis; i++)
		precache_sound(sound_nemesis[i])
	for (i = 0; i < sizeof sound_survivor; i++)
		precache_sound(sound_survivor[i])
	for (i = 0; i < sizeof sound_swarm; i++)
		precache_sound(sound_swarm[i])
	for (i = 0; i < sizeof sound_multi; i++)
		precache_sound(sound_multi[i])
	for (i = 0; i < sizeof sound_plague; i++)
		precache_sound(sound_plague[i])
	for (i = 0; i < sizeof grenade_infect; i++)
		precache_sound(grenade_infect[i])
	for (i = 0; i < sizeof grenade_infect_player; i++)
		precache_sound(grenade_infect_player[i])
	for (i = 0; i < sizeof grenade_fire; i++)
		precache_sound(grenade_fire[i])
	for (i = 0; i < sizeof grenade_fire_player; i++)
		precache_sound(grenade_fire_player[i])
	for (i = 0; i < sizeof grenade_frost; i++)
		precache_sound(grenade_frost[i])
	for (i = 0; i < sizeof grenade_frost_player; i++)
		precache_sound(grenade_frost_player[i])
	for (i = 0; i < sizeof grenade_frost_break; i++)
		precache_sound(grenade_frost_break[i])
	for (i = 0; i < sizeof sound_thunder; i++)
		precache_sound(sound_thunder[i])
	for (i = 0; i < sizeof sound_environment_mp3; i++)
		precache_generic(sound_environment_mp3[i])
		
	add_weapon(true, 1, 0, "Schmidt TMP", CSW_TMP, _, _, _, "v_tmp", "p_tmp")
	add_weapon(true, 4, 0, "Ingram MAC-10", CSW_MAC10, _, _, _, "v_mac10", "p_mac10")
	add_weapon(true, 11, 0, "UMP 45", CSW_UMP45, _, _, _, "v_ump45", "p_ump45")
	add_weapon(true, 16, 0, "ES P90", CSW_P90, _, _, _, "v_p90", "p_p90")
	add_weapon(true, 18, 0, "Schmidt Scout", CSW_SCOUT, 15, 0.7, 1.1, "v_scout", "p_scout")
	add_weapon(true, 23, 0, "M3 Super 90", CSW_M3, _, _, _, "v_m3", "p_m3")
	add_weapon(true, 32, 0, "XM1014 M4", CSW_XM1014, _, _, _, "v_xm1014", "p_xm1014")
	add_weapon(true, 39, 0, "MP5 Navy", CSW_MP5NAVY, _, _, _, "v_mp5", "p_mp5")
	add_weapon(true, 46, 0, "IMI Galil", CSW_GALIL, _, _, _, "v_galil", "p_galil")
	add_weapon(true, 47, 0, "Famas", CSW_FAMAS, _, _, _, "v_famas", "p_famas")
	add_weapon(true, 50, 0, "AWP Magnum Sniper", CSW_AWP, 15, 0.8, 1.3, "")
	add_weapon(true, 54, 0, "Steyr AUG A1", CSW_AUG, _, _, _, "v_aug", "p_aug")
	add_weapon(true, 60, 0, "SG-552 Commando", CSW_SG552, _, _, _, "v_sg552", "p_sg552")
	add_weapon(true, 65, 0, "M4A1 Carbine", CSW_M4A1, _, _, _, "v_m4a1", "p_m4a1")
	add_weapon(true, 72, 0, "AK-47 Kalashnikov", CSW_AK47, _, _, _, "")
	add_weapon(true, 85, 0, "M249 Machinegun", CSW_M249, _, _, _, "")
	add_weapon(true, 99, 0, "SG-550 Auto-Sniper", CSW_SG550, _, _, _, "")
	
	add_weapon(false, 1, 0, "Glock 18C", CSW_GLOCK18, _, _, _, "")
	add_weapon(false, 6, 0, "USP .45 ACP Tactical", CSW_USP, _, _, _, "")
	add_weapon(false, 13, 0, "P228 Compact", CSW_P228, _, _, _, "")
	add_weapon(false, 30, 0, "Desert Eagle .50 AE", CSW_DEAGLE, _, _, _, "")
	add_weapon(false, 35, 0, "FiveseveN", CSW_FIVESEVEN, _, _, _, "")
	add_weapon(false, 40, 0, "Dual Elite Berettas", CSW_ELITE, _, _, _, "")
	
	add_zclass("Clasico", "=Balanceado=", "zombie_source", "v_knife_zombie", 1850, 227.0, 1.0, 0, 0)
	add_zclass("Raptor", "HP+ Speed++", "OA-Zraptor", "v_knife_zombie", 2000, 264.0, 0.9, 6, 0)
	add_zclass("Poison", "HP+ Jump+", "OA-Zpoison", "v_smoker", 2300, 237.0, 0.74, 12, 0)
	add_zclass("Gordo", "=HP+++ Speed- Jump--", "OA-Zgordo", "v_gordo", 4350, 217.0, 1.0, 20, 0)
	add_zclass("Leech", "HP+  HPxInf+++ Jump+", "OA-Zoa", "v_smoker", 2900, 237.0, 0.85, 28, 0)
	add_zclass("Ghost", "Semi invisible", "zombie_source", "v_knife_zombie", 2300, 246.0, 0.9, 35, 0)
	add_zclass("Regenerativo", "Regenera su vida", "OA-Zreg", "v_drowned", 3300, 238.0, 0.85, 44, 0)
	add_zclass("Longjump", "Salto largo", "OA-Zlong_jump", "v_smoker", 2400, 245.0, 0.65, 53, 0)
	add_zclass("Warlock", "Curar Zombies (Letra R)", "OA-Zfaller", "v_drowned", 1850, 227.0, 1.0, 0, 0)
	
	add_hclass("Zoey", "OA_Zoey", 105, 0, 210.0, 0.9, 0, 0)
	add_hclass("Louis", "OA_Lois", 109, 8, 205.0, 1.0, 4, 0) 
	add_hclass("Francis", "OA_Francis", 113, 13, 210.0, 0.9, 9, 0)
	add_hclass("Ellis", "OA_Ellis", 119, 18, 230.0, 0.82, 14, 0) 
	add_hclass("Alice Murray", "OA_Alice_Murray", 125, 25, 225.0, 0.84, 20, 0)
	add_hclass("Sam Fisher", "OA_Sam_Fisher", 130, 30, 220.0, 0.9, 28, 0) 
	add_hclass("Soldado Umbrella", "OA_SoldadoU", 142, 42, 235.0, 0.84, 36, 0)
	add_hclass("Rebecca Chambers", "OA_Rebecca", 156, 56, 230.0, 0.82, 44, 0) 
	add_hclass("Carlos Oliveira", "OA_Carlos", 190, 90, 240.0, 0.83, 51, 0)
	add_hclass("Claire Redfield", "OA_Claire", 154, 55, 235.0, 0.8, 62, 0) 
	add_hclass("Sheva Alomar", "OA_Sheva", 160, 62, 235.0, 0.79, 75, 0)
	add_hclass("Chris Redfield", "OA_Chris", 200, 120, 245.0, 0.76, 88, 0) 
	add_hclass("Jill Valentine", "OA_Jill2", 240, 145, 250.0, 0.81, 97, 0)
	add_hclass("Leon", "OA_Leon", 265, 160, 245.0, 0.84, 109, 0) 
	add_hclass("Ada Wong", "OA_Ada", 235, 140, 265.0, 0.74, 120, 0)
	
	new ent
	ent = create_entity("env_fog")
	if(is_valid_ent(ent))
	{
		DispatchKeyValue(ent, "density", FOG_DENSITY)
		DispatchKeyValue(ent, "rendercolor", FOG_COLOR)
		DispatchSpawn(ent)
	}

	ent = create_entity("info_map_parameters")
	if(is_valid_ent(ent))
	{
		DispatchKeyValue(ent, "buying", "3")
		DispatchSpawn(ent)
	}

	// Laser Mine
	precache_model(mine_model)
	precache_sound(mine_snd_place)
	precache_sound(mine_snd_explode)
	g_laserMineSpr = precache_model("sprites/laserbeam.spr")

	// Illidan Boss resources (always precache for map zl_boss_illidan_alpha)
	for(new illi = 0; illi < sizeof g_illidanModels; illi++)
		g_illidan_ires[illi] = precache_model(g_illidanModels[illi])
	for(new illi = 0; illi < sizeof g_illidanSounds; illi++)
		precache_sound(g_illidanSounds[illi])
	precache_sound("de_losttemple/lt_tunnel.wav")

	// Prevent some entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	g_fwPrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound")
	
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "game_onInstallGameRules", OrpheuHookPost)
	Func_SetAnimation = OrpheuGetFunction("SetAnimation", "CBasePlayer")
	OrpheuRegisterHook(Func_SetAnimation, "OP_SetAnimation")
}

public plugin_init()
{
	// Register plugin call
	register_plugin("Zombie-Evil", PLUGIN_VERSION, "Destro")
	server_print("*** [ZE] Plugin loaded - BUILD APR27 ILLIDAN OK ***")

	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")
	register_event("Damage", "set_regenerate", "be", "2>0")
	register_event("30", "event_intermission", "a")
	
	// Forwards
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_BloodColor, "player", "Ham_BloodColor_Pre", 0)

	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)

	RegisterHam(Ham_Use, "func_pushable", "fw_UsePushable")

	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Think, "weaponbox", "fw_ThinkWeaponbox")

	RegisterHam(Ham_RemovePlayerItem , "player", "fw_HamRemovePlayerItem")
	RegisterHam(Ham_Item_PreFrame, "player", "fw_Item_PreFrame", 1)
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem")
	
	for(new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if(WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)

	new weapon_name[20]
	for (new i = 0; i < sizeof weapons_id; i++)
	{
		if(get_weaponname(weapons_id[i], weapon_name, charsmax(weapon_name))) 
		{
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_primary_attack_post", 1)
		}
	}
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hegrenade", "fw_he_primary_attack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_mp5_primary_attack")

	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Touch, "grenade", "fw_touchGrenade")

	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_update_client_data", 1)
	//register_forward(FM_AddToFullPack, "fw_addtofullpack", 1)

	unregister_forward(FM_Spawn, g_fwSpawn)
	unregister_forward(FM_PrecacheSound, g_fwPrecacheSound)
	
	register_touch(classname_forcefield, "player", "fw_touch_forcefield")
	register_touch(classname_powerbox ,"player", "fw_touch_powerbox")

	// Illidan Boss
	RegisterHam(Ham_TakeDamage, "info_target", "fw_illidan_take_damage")
	RegisterHam(Ham_TraceAttack, "info_target", "fw_illidan_trace_attack")
	RegisterHam(Ham_Killed, "info_target", "fw_illidan_entity_killed")
	register_think("boss_illidan", "think_illidan_boss")
	register_think("boss_illidan_hpbar", "think_illidan_hpbar")
	register_think("boss_illidan_attack", "think_illidan_attack_visual")
	register_think("boss_illidan_elem", "think_illidan_elem")
	register_think("boss_illidan_splash", "think_illidan_splash")
	register_think("boss_blade_hpbar", "think_illidan_blade_hpbar")
	register_touch("boss_illidan", "player", "touch_illidan_boss")
	register_touch("boss_illidan_ball", "*", "touch_illidan_ball")
	

	// Client commands
	register_clcmd("say zpmenu", "clcmd_saymenu")
	register_clcmd("say /zpmenu", "clcmd_saymenu")
	register_clcmd("nightvision", "clcmd_nvgtoggle")
	register_clcmd("drop", "clcmd_drop")
	register_clcmd("buyammo1", "clcmd_buyammo")
	register_clcmd("buyammo2", "clcmd_buyammo")
	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")
	register_clcmd("ingresar_password", "login")
	register_clcmd("_password", "crear_cuenta")
	register_clcmd("confirmar_password", "crear_cuenta")
	register_clcmd("vieja_password", "change_pw")
	register_clcmd("nueva_password", "change_pw")
	register_clcmd("confirmar_nueva_password", "change_pw")
	register_clcmd("E-MAIL", "set_email")
	register_clcmd("say /rank", "clcmd_rank")
	register_clcmd("say /top15", "clcmd_top20")
	register_clcmd("say /top20", "clcmd_top20")
	register_clcmd("say /hf", "clcmd_hf")
	register_clcmd("say /razon", "show_ban_razon")
	register_clcmd("say /party", "show_menu_party")
	register_clcmd("monto", "clcmd_donate_amount")
	register_clcmd("menuselect 8", "newmenu_back")
	register_clcmd("menuselect 9", "newmenu_next")
	register_clcmd("buyze", "clcmd_buy")
	register_clcmd("buyequip", "clcmd_buyequip")
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_say_team")
	
	register_clcmd("weapon_hegrenade", "cmd_grenade")
	for(new i; i < sizeof new_grenades; i++)
		register_clcmd(new_grenades[i][WL_NAME], "cmd_grenade")
	
	// Menus
	// All oldmenu-based menus route through ze_oldmenu_dispatch
	// which converts raw key index ? itemnum/value and calls the right handler
	register_menu("menu_game",          KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_prebuy",        KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_primarybuy",    KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_secondarybuy",  KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_extras",        KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_zclass",        KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_zclass_info",   KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_hclass",        KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_hclass_info",   KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_managepj",      KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_personal",      KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_account",       KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_interface",     KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_hudposition",   KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_statistics",    KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_confirm",       KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("menu_donate",        KEYSMENU,       "ze_oldmenu_dispatch")
	register_menu("Admin Menu ZE",            KEYSMENU, "ze_oldmenu_dispatch")
	register_menu("menu_owner",                KEYSMENU, "ze_oldmenu_dispatch")
	register_menu("menu_owner_playerselect",   KEYSMENU, "ze_oldmenu_dispatch")
	register_menu("menu_owner_amount",         KEYSMENU, "ze_oldmenu_dispatch")
	register_menu("menu_admin_playerselect",   KEYSMENU, "ze_oldmenu_dispatch")
	register_menu("party_menu_principal", KEYSMENU_PARTY, "menu_party")
	// oldmenuhandler catch-all (fallback for any unregistered menu key press)
	register_menucmd(register_menuid("oldmenuhandler", 0), 1023, "ze_oldmenu_dispatch")

	register_concmd("ze_ban",        "cmd_ban",        ADMIN_IMMUNITY, "<horas>")
	register_concmd("ze_zombie",     "cmd_ze_zombie",  OWNER_FLAG, "<player>")
	register_concmd("ze_human",      "cmd_ze_human",   OWNER_FLAG, "<player>")
	register_concmd("ze_setlevel",   "cmd_ze_setlevel",OWNER_FLAG, "<player> <level>")
	register_concmd("ze_givelevel",  "cmd_ze_givelevel",OWNER_FLAG,"<player> <amount>")
	register_concmd("ze_takelevel",  "cmd_ze_takelevel",OWNER_FLAG,"<player> <amount>")
	register_concmd("ze_setap",      "cmd_ze_setap",   OWNER_FLAG, "<player> <amount>")
	register_concmd("ze_giveap",     "cmd_ze_giveap",  OWNER_FLAG, "<player> <amount>")
	register_concmd("ze_takeap",     "cmd_ze_takeap",  OWNER_FLAG, "<player> <amount>")
	register_concmd("ze_ap",         "cmd_ze_ap",      OWNER_FLAG, "<amount>")
	register_concmd("ze_hpoints",    "cmd_ze_hpoints", OWNER_FLAG, "<player> <amount>")
	register_concmd("ze_zpoints",    "cmd_ze_zpoints", OWNER_FLAG, "<player> <amount>")
	register_concmd("ze_wpoints",    "cmd_ze_wpoints", OWNER_FLAG, "<player> <amount>")
	register_concmd("ze_resetstats", "cmd_ze_resetstats",OWNER_FLAG,"<player>")
	register_concmd("ze_setreset",   "cmd_ze_setreset",OWNER_FLAG, "<player> <count>")
	register_clcmd("ze_flashlight", "cmd_flashlight")
	// Mine system � +setlaser to place, +dellaser to remove
	register_clcmd("+setlaser",         "cmd_mine_place")
	register_clcmd("-setlaser",         "cmd_mine_place_end")
	register_clcmd("+dellaser",         "cmd_mine_remove")
	register_clcmd("-dellaser",         "cmd_mine_remove_end")
	// Legacy buyze binds kept for compatibility
	register_clcmd("buyze_mine_place",  "cmd_mine_place")
	register_clcmd("buyze_mine_remove", "cmd_mine_remove")
	// Mine system
	RegisterHam(Ham_TakeDamage, "func_breakable", "fw_mine_takedamage")
	RegisterHam(Ham_Player_PreThink, "player", "fw_mine_player_prethink")
	register_think(classname_mine, "fw_mine_think_reg")
	register_touch(classname_mine, "player", "fw_mine_touch_reg")

	// Message IDs
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgTeamInfo = get_user_msgid("TeamInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msgSetFOV = get_user_msgid("SetFOV")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgFlashlight = get_user_msgid("Flashlight")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	g_msgHideWeapon = get_user_msgid("HideWeapon")
	g_msgCrosshair = get_user_msgid("Crosshair")
	g_msgTutorText = get_user_msgid("TutorText")
	g_msgTutorClose = get_user_msgid("TutorClose")
	g_IconStatus = get_user_msgid("StatusIcon")
	g_StatusText = get_user_msgid("StatusText")
	g_StatusValue = get_user_msgid("StatusValue")
	g_msgWeaponList = get_user_msgid("WeaponList")
	g_msgRoundTime = get_user_msgid("RoundTime")
	g_msgVGUIMenu =  get_user_msgid("VGUIMenu")
	g_msgShowMenu =  get_user_msgid("ShowMenu")
	g_msgSayText = get_user_msgid("SayText")
	
	// Message hooks
	register_message(get_user_msgid("AmmoX"), "message_ammo_x")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	register_message(get_user_msgid("Money"), "message_money")
	register_message(get_user_msgid("Health"), "message_health")
	register_message(get_user_msgid("FlashBat"), "message_flashbat")
	register_message(get_user_msgid("WeapPickup"), "message_weappickup")
	register_message(g_msgAmmoPickup, "message_ammopickup")
	register_message(get_user_msgid("Scenario"), "message_scenario")
	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	register_message(g_msgTeamInfo, "message_teaminfo")
	register_message(g_msgVGUIMenu, "message_vgui_menu")
	register_message(g_msgShowMenu, "message_show_menu")
	register_message(g_IconStatus, "message_status_icon")
	
	set_msg_block(g_StatusText, BLOCK_SET)
	set_msg_block(g_StatusValue, BLOCK_SET)
	set_msg_block(get_user_msgid("HostagePos"), BLOCK_SET)
	set_msg_block(get_user_msgid("Radar"), BLOCK_SET)
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	set_msg_block(get_user_msgid("HudTextArgs"), BLOCK_SET)

	cvar_countdown = register_cvar("zp_delay", "15")
	cvar_lighting = register_cvar("zp_lighting", "b")
	cvar_thunder = register_cvar("zp_thunderclap", "90")
	cvar_spawndelay = register_cvar("zp_spawn_delay", "5")
	
	cvar_humanlasthp = register_cvar("zp_human_last_extrahp", "200")
	
	cvar_fireduration = register_cvar("zp_fire_duration", "10")
	cvar_firedamage = register_cvar("zp_fire_damage", "5")
	cvar_fireslowdown = register_cvar("zp_fire_slowdown", "0.5")
	cvar_freezeduration = register_cvar("zp_frost_duration", "3")
	cvar_flareduration = register_cvar("zp_flare_duration", "60")
	cvar_flaresize = register_cvar("zp_flare_size", "25")
	
	cvar_zombiefirsthp = register_cvar("zp_zombie_first_hp", "2.0")
	
	cvar_nemchance = register_cvar("zp_nem_chance", "20")
	cvar_nemminplayers = register_cvar("zp_nem_min_players", "10")
	cvar_nemspd = register_cvar("zp_nem_speed", "250")
	cvar_nemgravity = register_cvar("zp_nem_gravity", "0.5")

	
	cvar_survchance = register_cvar("zp_surv_chance", "20")
	cvar_survminplayers = register_cvar("zp_surv_min_players", "0")
	cvar_survspd = register_cvar("zp_surv_speed", "230")
	
	cvar_swarmchance = register_cvar("zp_swarm_chance", "20")
	cvar_swarmminplayers = register_cvar("zp_swarm_min_players", "0")
	
	cvar_multichance = register_cvar("zp_multi_chance", "20")
	cvar_multiminplayers = register_cvar("zp_multi_min_players", "10")
	cvar_multiratio = register_cvar("zp_multi_ratio", "0.3")
	
	cvar_plaguechance = register_cvar("zp_plague_chance", "30")
	cvar_plagueminplayers = register_cvar("zp_plague_min_players", "6")
	cvar_plagueratio = register_cvar("zp_plague_ratio", "0.5")

	cvar_sniperchance = register_cvar("zp_sniper_chance", "20")
	
	cvar_synapsis = register_cvar("zp_synapsis_enabled", "1")
	cvar_synapsischance = register_cvar("zp_synapsis_chance", "20")
	cvar_synapsisratio = register_cvar("zp_synapsis_ratio", "0.5")
	
	cvar_assassin = register_cvar("zp_assassin_enabled", "1")
	cvar_assassinchance = register_cvar("zp_assassin_chance", "20")
	cvar_assaspd = register_cvar("zp_assassin_speed", "600")
	cvar_flaresize2 = register_cvar ("zp_assassin_flare_size", "10")
	
	register_cvar("zp_version", "4.01-Beta", FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_version", "4.01-Beta")
	register_cvar("ze_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("ze_version", PLUGIN_VERSION)

	pcvar_roundtime = get_cvar_pointer("mp_roundtime")

	g_hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB)
	
	g_fwRoundStart = CreateMultiForward("zp_round_started", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwRoundEnd = CreateMultiForward("zp_round_ended", ET_IGNORE, FP_CELL)
	g_fwUserInfected_pre = CreateMultiForward("zp_user_infected_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwUserInfected_post = CreateMultiForward("zp_user_infected_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwUserHumanized_pre = CreateMultiForward("zp_user_humanized_pre", ET_IGNORE, FP_CELL)
	g_fwUserHumanized_post = CreateMultiForward("zp_user_humanized_post", ET_IGNORE, FP_CELL)
	g_fwExtraItemSelected = CreateMultiForward("zp_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)
	
	load_spawns()
	
	set_cvar_string("sv_skyname", skynames)
	
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
	
	g_MsgSync = CreateHudSyncObj()
	g_MsgSync2 = CreateHudSyncObj()
	g_MsgSync3 = CreateHudSyncObj()
	g_MsgSync4 = CreateHudSyncObj()
	g_MsgSync5 = CreateHudSyncObj()

	g_maxplayers = get_maxplayers()

	default_model_index = engfunc(EngFunc_ModelIndex, "models/player/urban/urban.mdl")

	db_slot_i = g_maxplayers+1

	date(_, _, g_dia)

	set_task(1.0, "event_round_start")
	set_task(1.0, "task_onesecon", .flags="b")
	set_task(0.1, "task_aura", .flags="b")

	g_bLinux = bool:is_linux_server()

	game_enableForwards()
}

public plugin_cfg()
{
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	server_cmd("exec %s/zombieplague.cfg", cfgdir)
}

public fw_Sys_Error(const error[])
{
	_debug_draw()
	log_to_file("hlds_error.log", "error:[%s]", error)
}


// ----------------------------------------------------------
// Efecto de explocion --------------------------------------
// ----------------------------------------------------------
public create_spark(Float:origen[3], Float:dir[3])
{
	new ent = create_entity("spark_shower")
	if(!is_valid_ent(ent)) return
	
	entity_set_origin(ent, origen)
	entity_set_vector(ent, EV_VEC_angles, dir)
	
	DispatchSpawn(ent)	
}

public humo(origen[3])
{
	origen[2] += 60
	message_begin(MSG_PVS, SVC_TEMPENTITY, origen, 0)
	write_byte(TE_SMOKE)
	write_coord(origen[0])
	write_coord(origen[1])
	write_coord(origen[2]) 
	write_short(g_smokeSpr2)
	write_byte(35) // escala
	write_byte(12) // flame rate
	message_end()
}

public bubbles(ent)
{
	if(!is_valid_ent(ent))
		return
		
	new Float:origenF[3]
	entity_get_vector(ent, EV_VEC_origin, origenF)

	new Float:altura = UTIL_WaterLevel(origenF, origenF[2], origenF[2]+512)
	altura = altura - (origenF[2] - 40)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origenF, 0)
	write_byte(TE_BUBBLES)
	write_coord_f(origenF[0]-40)
	write_coord_f(origenF[1]-40)
	write_coord_f(origenF[2]-40)
	write_coord_f(origenF[0]+40)
	write_coord_f(origenF[1]+40)
	write_coord_f(origenF[2]+40)
	write_coord_f(altura) // altura (?
	write_short(g_bubblesSpr) // model index
	write_byte(40) // cound
	write_coord(8) // speed
	message_end()

	remove_entity(ent)
}

public particulas(origen[3])
{
	origen[2] += 130
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origen, 0)
	write_byte(TE_BLOODSPRITE)
	write_coord(origen[0]-30)
	write_coord(origen[1]-30)
	write_coord(origen[2]) 
	write_short(g_particleSpr)
	write_short(g_particleSpr)
	write_byte(70) // color
	write_byte(3) // escale
	message_end()
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origen, 0)
	write_byte(TE_BLOODSPRITE)
	write_coord(origen[0]+30)
	write_coord(origen[1]+30)
	write_coord(origen[2]) 
	write_short(g_particleSpr)
	write_short(g_particleSpr)
	write_byte(70) // color
	write_byte(3) // escale
	message_end()
}

Float:UTIL_WaterLevel(const Float:position[3], Float:minz, Float:maxz)
{
	new Float:midUp[3]
	midUp = position
	midUp[2] = minz

	if(point_contents(midUp) != CONTENTS_WATER)
		return minz

	midUp[2] = maxz
	if(point_contents(midUp) == CONTENTS_WATER)
		return maxz

	new loop
	new Float:diff = maxz - minz
	while(diff > 1.0)
	{
		midUp[2] = minz + diff/2.0
		if(point_contents(midUp) == CONTENTS_WATER)
			minz = midUp[2]
		else
			maxz = midUp[2]
		diff = maxz - minz
		loop++
	}

	return midUp[2]
}

// -------------WEANPON LIST--------------------------------------------------------------
//----------------------------------------------------------------------------------------
public cmd_grenade(id)
{
	new arg[25]
	read_argv(0, arg, 24)
	
	new grenade = str_to_num(arg[10])
	
	if(!grenade || !g_has_grenades[id][grenade-1]) return PLUGIN_HANDLED
	
	new oldgrenade = g_current_grenade[id]
	g_current_grenade[id] = grenade
	
	if(g_currentweapon[id] != CSW_HEGRENADE)
		engclient_cmd(id, WEAPONENTNAMES[CSW_HEGRENADE])
	else if(oldgrenade != grenade) {
		new ent = get_current_weapon_ent(id)
		if(ent>0) ExecuteHamB(Ham_Item_Deploy, ent)
	}
	return PLUGIN_HANDLED
}

stock give_grenade(id, grenade)
{
	grenade -= 1
	g_has_grenades[id][_GRENADES]++
	g_has_grenades[id][grenade]++
	
	if(!find_ent_by_owner(FM_NULLENT, WEAPONENTNAMES[CSW_HEGRENADE], id))
	{
		set_msg_block(get_user_msgid("WeapPickup"), BLOCK_SET)
		set_msg_block(get_user_msgid("AmmoPickup"), BLOCK_SET)
		give_item(id, WEAPONENTNAMES[CSW_HEGRENADE])
		set_msg_block(get_user_msgid("WeapPickup"), BLOCK_NOT)
		set_msg_block(get_user_msgid("AmmoPickup"), BLOCK_NOT)
		
		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<CSW_HEGRENADE))
	}
	
	cs_set_user_bpammo(id, CSW_HEGRENADE, g_has_grenades[id][_GRENADES])

	if((g_has_grenades[id][grenade]-1))
	{
		message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id)
		write_byte(new_grenades[grenade][WL_AID])
		write_byte(g_has_grenades[id][grenade])
		message_end()
		return
	}
	new weaponbits = entity_get_int(id, EV_INT_weapons)
	new w = get_freeweapon(weaponbits)

	g_grenades_basew[id][grenade] = w
	
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id)
	write_byte(new_grenades[grenade][WL_AID])
	write_byte(g_has_grenades[id][grenade])
	message_end()

	new data[2]
	data[0] = id
	data[1] = w
	set_task(0.15, "task_weap_pickup", _, data, 2)
	
	send_weaponlist(id, new_grenades[grenade][WL_NAME], new_grenades[grenade][WL_AID], new_grenades[grenade][WL_MAX],
	-1, 0, new_grenades[grenade][WL_SLOTID], new_grenades[grenade][WL_SLOT], w, 0, 1)
	
	set_pev(id, pev_weapons, pev(id,pev_weapons) | (1<<w))
}

public task_weap_pickup(data[2])
{
	if(!g_is_connected[data[0]]) return
	
	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), _, data[0])
	write_byte(data[1])
	message_end()
}

stock send_weaponlist(id, name[], aid, amax, aid2, amax2, position, slot, weapon, flags, save)
{
	message_begin(MSG_ONE, g_msgWeaponList, _, id)  
	write_string(name)
	write_byte(aid) // Ammo Type
	write_byte(amax) // Max Ammo 1
	write_byte(aid2) // Ammo2 Type (-1)
	write_byte(amax2) // Max Ammo 2 (0)
	write_byte(position) // posicion (0/4)
	write_byte(slot) // slot (1/30)
	write_byte(weapon) // id (bit index into pev->weapons)
	write_byte(flags) // Flags
	message_end()
	
	sends_wid[id] |= (1<<weapon)
	
	reset_hud(id)

	if(!save) return
	
	copy(send_wlist[id][weapon][WL_NAME], 24, name)
	send_wlist[id][weapon][WL_AID] = aid
	send_wlist[id][weapon][WL_MAX] = amax
	send_wlist[id][weapon][WL_AID2] = aid2
	send_wlist[id][weapon][WL_MAX2] = amax2
	send_wlist[id][weapon][WL_SLOTID] = position
	send_wlist[id][weapon][WL_SLOT] = slot
	send_wlist[id][weapon][WL_FLAGS] = flags
}

stock send_saveweaponlist(id, oldw, neww)
{
	copy(send_wlist[id][neww][WL_NAME], 24, send_wlist[id][oldw][WL_NAME])
	send_wlist[id][neww][WL_AID] = send_wlist[id][oldw][WL_AID]
	send_wlist[id][neww][WL_MAX] = send_wlist[id][oldw][WL_MAX]
	send_wlist[id][neww][WL_AID2] = send_wlist[id][oldw][WL_AID2]
	send_wlist[id][neww][WL_MAX2] = send_wlist[id][oldw][WL_MAX2]
	send_wlist[id][neww][WL_SLOTID] = send_wlist[id][oldw][WL_SLOTID]
	send_wlist[id][neww][WL_SLOT] = send_wlist[id][oldw][WL_SLOT]
	send_wlist[id][neww][WL_FLAGS] = send_wlist[id][oldw][WL_FLAGS]
	
	send_weaponlist(id, send_wlist[id][neww][WL_NAME], send_wlist[id][neww][WL_AID],
	send_wlist[id][neww][WL_MAX], send_wlist[id][neww][WL_AID2], send_wlist[id][neww][WL_MAX2],
	send_wlist[id][neww][WL_SLOTID], send_wlist[id][neww][WL_SLOT],
	neww, send_wlist[id][neww][WL_FLAGS], 1)
}

stock send_defaultweaponlist(id, w)
{
	send_weaponlist(id, WEAPONENTNAMES[w], AMMOID[w],
	MAXBPAMMO[w], -1, 0, WEAPONSLOT[w][0], WEAPONSLOT[w][1], w, 0, 0)
	
	sends_wid[id] &= ~(1<<w)
}

stock get_freeweapon(curweapons)
{
	for(new w=CSW_P228; w <= CSW_P90; w++) {
		if(w == CSW_HEGRENADE) continue
		if(!(curweapons & (1<<w)))
			return w
	}
	return 0
}

stock check_hasgrenade(id)
{
	for(new i; i < _GRENADES; i++)
	{
		if(!g_has_grenades[id][i]) continue
		
		g_current_grenade[id] = i+1
		return 1
	}
	return 0
}

stock remove_grenades(id)
{
	static g
	for(g=0; g < _GRENADES; g++) {
		g_has_grenades[id][g] = 0
		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<g_grenades_basew[id][g]))
		g_grenades_basew[id][g] = 0
	}
	g_has_grenades[id][_GRENADES] = 0
	g_current_grenade[id] = 0
}


// Orpheu


public game_onInstallGameRules()
	g_pGameRules = OrpheuGetReturn();

game_enableForwards()
{
	g_oMapConditions = OrpheuRegisterHook(OrpheuGetFunction("CheckMapConditions", "CHalfLifeMultiplay"), "game_blockConditions")
	g_oWinConditions = OrpheuRegisterHook(OrpheuGetFunction("CheckWinConditions", "CHalfLifeMultiplay"), "game_blockConditions")

	if(g_bLinux)
		g_oRoundTimeExpired = OrpheuRegisterHook(OrpheuGetFunction("HasRoundTimeExpired", "CHalfLifeMultiplay"), "game_blockConditions")
	else
		game_memoryReplace(MEMORY_ROUNDTIME, {0x90, 0x90, 0x90})
}

game_disableForwards()
{
	OrpheuUnregisterHook(g_oMapConditions)
	OrpheuUnregisterHook(g_oWinConditions)

	if(g_bLinux)
		OrpheuUnregisterHook(g_oRoundTimeExpired)
	else
		game_memoryReplace(MEMORY_ROUNDTIME, {0xF6, 0xC4, 0x41})
}
public OrpheuHookReturn:game_blockConditions()
{
	OrpheuSetReturn(false)

	return OrpheuSupercede
}

game_memoryReplace(szID[], const iBytes[], const iLen = sizeof iBytes)
{
	new iAddress

	OrpheuMemoryGet(szID, iAddress)

	for(new i; i < iLen; i++)
	{
		OrpheuMemorySetAtAddress(iAddress, "roundTimeCheck|dummy", 1, iBytes[i], iAddress)

		iAddress++
	}

	server_cmd("sv_restart 1")
}

public hook_say(id)
{
	if(!g_is_connected[id])
		return PLUGIN_HANDLED

	static say[128]
	read_args(say, 127)
	remove_quotes(say)
	
	if(!say[0])
		return PLUGIN_HANDLED
	
	static tiempo, str_len
	tiempo = time();str_len = strlen(say)

	if(str_len > 4 && (tiempo - g_old_msg_time[id]) < 4 && equal(say, g_old_msg[id], 30))
	{
		zp_colored_print(id, "!g[Only-Arg] !tMensaje bloqueado.Deja de floodear con el mismo mensaje.")
		return PLUGIN_HANDLED
	}
	if(contain_insulto(say))
	{
		if(g_insult[id]++ >= 3)
		{
			server_cmd("kick #%d ^"Kickeado por insultar^"", get_user_userid(id))
			zp_colored_print(0, "!g[Only-Arg] !y%s !tfue kickeado por insultar.", g_name[id])
		}
		zp_colored_print(id, "!g[Only-Arg] !tMensaje bloqueado.El mensaje contiene insultos.")
		return PLUGIN_HANDLED
	}
	if(replace_spam(say, str_len) == 2)
	{
		zp_colored_print(id, "!g[Only-Arg] !tMensaje bloqueado.El mensaje contiene muchos numeros")
		return PLUGIN_HANDLED
	}
	
	g_old_msg_time[id] = tiempo
	copy(g_old_msg[id], 31, say)
	replace_all(say, 127, "%", " ")
	replace(say, 127, "^3", " ")
	replace(say, 127, "^4", " ")
	
	static const prefix[][] = { "Zm", "Ne", "As", "Hu", "Su", "Sn", "Ci", "Um", "MUERTO", "SPECTADOR", "SIN-TEAM" }
	static team, prefixid, new_say[192]
	team = fm_get_user_team(id)

	if(team == 3) prefixid = 9
	else if(team == 0) prefixid = 10
	else if(g_is_alive[id])
	{
		if(g_zombie[id]) prefixid = g_zombie[id]-1
		else prefixid = g_human[id]+2
	
	}
	else prefixid = 8
	
	format(new_say, 191, "^4[%s]^3%s ^4  Level[%d] ^1: %s", prefix[prefixid], g_name[id], g_level[id], say)
	
	if(strlen(new_say) > 96)
	{
		static new_say_fix[97]
		copy(new_say_fix, 96, new_say)
		send_msg(id, new_say_fix)
		send_msg(id, new_say[96])
	}
	else send_msg(id, new_say)
	
	log_to_file("say.log", "%s",  new_say)
	
	return PLUGIN_HANDLED
}

public hook_say_team(id)
{
	static say[128]
	read_args(say, 127)

	if(!say[0])
		return PLUGIN_HANDLED

	if(contain_insulto(say) || replace_spam(say, strlen(say)))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

contain_insulto(say[])
{
	for(new i=0; i <= charsmax(BAD_WORDS); i++)
		if(containi(say, BAD_WORDS[i]) != -1)
			return 1
	return 0
}

replace_spam(say[], str_len)
{
	static j, c
	c = 0

	static guion[11]

	for(j = 0; j < str_len; j++)
	{
		if(isdigit(say[j]))
		{
			if(c >= 10) return 2
			guion[c] = j
			c++
		}
	}
	
	if(c >= 6) {
		for(j = 0; j < c; j++) say[guion[j]] = '#'
		return 1
	}
	return 0
}

send_msg(id, message[])
{
	message_begin(MSG_BROADCAST, g_msgSayText)
	write_byte(id)
	write_string(message)
	message_end()
}

// ==========================================================================================================
stock add_weapon(primary, level, reset, weapon_name[], weapon_base, max_clip=0, Float:speed=1.0, Float:damage=1.0, v_model[]="", p_model[]="", w_model[]="")
{
	new model[32]

	if(primary)
	{
		if(g_hclass_count >= MAX_PRIMARY_WEAPONS)
		{
			log_to_file(error_log, "add_weapon(primary): array limit %d", MAX_PRIMARY_WEAPONS)
			return
		}
	
		copy(g_primary_weapons[g_weapons_count[0]][WPN_NAME], 31, weapon_name)
		
		g_primary_weapons[g_weapons_count[0]][WPN_BASE] = weapon_base
		g_primary_weapons[g_weapons_count[0]][WPN_MAX_CLIP] = max_clip
		g_primary_weapons[g_weapons_count[0]][WPN_SPEED] = _:speed
		g_primary_weapons[g_weapons_count[0]][WPN_DAMAGE] = _:damage
		g_primary_weapons[g_weapons_count[0]][WPN_LEVEL] = level
		g_primary_weapons[g_weapons_count[0]][WPN_RESET] = reset
		
		if(v_model[0])
		{
			formatex(model, charsmax(model), "oa-ze/%s.mdl", v_model)
			if(file_exists(model))
			{
				copy(g_primary_weapons[g_weapons_count[0]][WPN_V_MODEL], 31, model)
				precache_model(model)
			}
			else log_to_file(error_log, "add_weapon: model v_ no exists: [%s]", model)
		}
		
		if(p_model[0])
		{
			formatex(model, charsmax(model), "oa-ze/%s.mdl", p_model)
			if(file_exists(model))
			{
				copy(g_primary_weapons[g_weapons_count[0]][WPN_P_MODEL], 31, model)
				precache_model(model)
			}
			else log_to_file(error_log, "add_weapon: model p_ no exists: [%s]", model)
		}
		
		if(w_model[0])
		{
			formatex(model, charsmax(model), "oa-ze/%s.mdl", w_model)
			if(file_exists(model))
			{
				copy(g_primary_weapons[g_weapons_count[0]][WPN_W_MODEL], 31, model)
				precache_model(model)
			}
			else log_to_file(error_log, "add_weapon: model w_ no exists: [%s]", model)
		}
		g_weapons_count[0]++
	}
	else {
		if(g_hclass_count >= MAX_SECONDARY_WEAPONS)
		{
			log_to_file(error_log, "add_weapon(secondary): array limit %d", MAX_SECONDARY_WEAPONS)
			return
		}
		
		copy(g_secondary_weapons[g_weapons_count[1]][WPN_NAME], 31, weapon_name)
		
		g_secondary_weapons[g_weapons_count[1]][WPN_BASE] = weapon_base
		g_secondary_weapons[g_weapons_count[1]][WPN_MAX_CLIP] = max_clip
		g_secondary_weapons[g_weapons_count[1]][WPN_SPEED] = _:speed
		g_secondary_weapons[g_weapons_count[1]][WPN_DAMAGE] = _:damage
		g_secondary_weapons[g_weapons_count[1]][WPN_LEVEL] = level
		g_secondary_weapons[g_weapons_count[1]][WPN_RESET] = reset
		
		if(v_model[0])
		{
			formatex(model, charsmax(model), "oa-ze/%s.mdl", v_model)
			if(file_exists(model))
			{
				copy(g_secondary_weapons[g_weapons_count[1]][WPN_V_MODEL], 31, model)
				precache_model(model)
			}
			else log_to_file(error_log, "add_weapon: model v_ no exists: [%s]", model)
		}
		
		if(p_model[0])
		{
			formatex(model, charsmax(model), "oa-ze/%s.mdl", p_model)
			if(file_exists(model))
			{
				copy(g_secondary_weapons[g_weapons_count[1]][WPN_P_MODEL], 31, model)
				precache_model(model)
			}
			else log_to_file(error_log, "add_weapon: model p_ no exists: [%s]", model)
		}
		
		if(w_model[0])
		{
			formatex(model, charsmax(model), "oa-ze/%s.mdl", w_model)
			if(file_exists(model))
			{
				copy(g_secondary_weapons[g_weapons_count[1]][WPN_W_MODEL], 31, model)
				precache_model(model)
			}
			else log_to_file(error_log, "add_weapon: model w_ no exists: [%s]", model)
		}
		g_weapons_count[1]++
	}
}

stock add_zclass(name[], info[], model[], clawmodel[], health, Float:velocity, Float:gravity, level, reset)
{
	if(g_hclass_count >= MAX_ZCLASS)
	{
		log_to_file(error_log, "add_zclass: array limit %d", MAX_HCLASS)
		return
	}
	
	new util_model[64]

	copy(g_zclass[g_zclass_count][ZCLASS_NAME], 31, name)
	copy(g_zclass[g_zclass_count][ZCLASS_INFO], 31, info)
	copy(g_zclass[g_zclass_count][ZCLASS_MODEL], 31, model)

	g_zclass[g_zclass_count][ZCLASS_HEALTH] = health
	g_zclass[g_zclass_count][ZCLASS_VELOCITY] = _:velocity
	g_zclass[g_zclass_count][ZCLASS_GRAVITY] = _:gravity
	g_zclass[g_zclass_count][ZCLASS_LEVEL] = level
	g_zclass[g_zclass_count][ZCLASS_RESET] = reset

	formatex(util_model, charsmax(util_model), "models/player/%s/%s.mdl", model, model)
	if(file_exists(util_model))
	{
		g_zclass[g_zclass_count][ZCLASS_MODELID] = precache_model(util_model)
	}
	else log_to_file(error_log, "add_zclass: model player no exists: [%s]", util_model)
	
	
	formatex(util_model, charsmax(util_model), "models/zombie_plague/%s.mdl", clawmodel)
	if(file_exists(util_model))
	{
		copy(g_zclass[g_zclass_count][ZCLASS_CLAWMODEL], 63, util_model)
		precache_model(util_model)
	}
	else log_to_file(error_log, "add_zclass: model claw no exists: [%s]", util_model)

	g_zclass_count++
}

stock add_hclass(name[], model[], health, armor, Float:velocity, Float:gravity, level, reset)
{
	if(g_hclass_count >= MAX_HCLASS)
	{
		log_to_file(error_log, "add_hclass: array limit %d", MAX_HCLASS)
		return
	}

	new util_model[64]

	copy(g_hclass[g_hclass_count][HCLASS_NAME], 31, name)
	copy(g_hclass[g_hclass_count][HCLASS_MODEL], 31, model)

	g_hclass[g_hclass_count][HCLASS_HEALTH] = health
	g_hclass[g_hclass_count][HCLASS_ARMOR] = armor
	g_hclass[g_hclass_count][HCLASS_VELOCITY] = _:velocity
	g_hclass[g_hclass_count][HCLASS_GRAVITY] = _:gravity
	g_hclass[g_hclass_count][HCLASS_LEVEL] = level
	g_hclass[g_hclass_count][HCLASS_RESET] = reset

	formatex(util_model, charsmax(util_model), "models/player/%s/%s.mdl", model, model)
	if(file_exists(util_model))
		precache_model(util_model)
	else log_to_file(error_log, "add_hclass: model player no exists: [%s]", util_model)
	
	g_hclass_count++
}

/*================================================================================
 [ADMIN COMMANDS � OWNER FLAG]
=================================================================================*/

// Helper: find player by partial name
stock ze_find_player(const arg[])
{
	new id = str_to_num(arg)
	if(id > 0 && id <= 32 && g_is_connected[id]) return id
	for(id = 1; id <= g_maxplayers; id++)
		if(g_is_connected[id] && containi(g_name[id], arg) != -1) return id
	return 0
}

public cmd_ze_zombie(id, level, cid)
{
	new arg[32]; read_argv(1, arg, charsmax(arg))
	new target = ze_find_player(arg)
	if(!target) { console_print(id, "[ZE] Player not found: %s", arg); return PLUGIN_HANDLED; }
	if(!g_is_alive[target]) ExecuteHamB(Ham_CS_RoundRespawn, target)
	zombieme(target, CLASS_ZOMBIE)
	console_print(id, "[ZE] %s ? Zombie", g_name[target])
	return PLUGIN_HANDLED
}

public cmd_ze_human(id, level, cid)
{
	new arg[32]; read_argv(1, arg, charsmax(arg))
	new target = ze_find_player(arg)
	if(!target) { console_print(id, "[ZE] Player not found: %s", arg); return PLUGIN_HANDLED; }
	humanme(target, CLASS_HUMAN)
	console_print(id, "[ZE] %s ? Human", g_name[target])
	return PLUGIN_HANDLED
}

public cmd_ze_setlevel(id, level, cid)
{
	new arg1[32], arg2[10]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_ammopacks[target] = str_to_num(arg2) == 0 ? 0 : NIVELES(str_to_num(arg2)) + 2
	g_level[target] = str_to_num(arg2)
	check_player_level(target)
	console_print(id, "[ZE] %s level ? %d", g_name[target], g_level[target])
	return PLUGIN_HANDLED
}

public cmd_ze_givelevel(id, level, cid)
{
	new arg1[32], arg2[10]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_ammopacks[target] += NIVELES(g_level[target] + str_to_num(arg2)) - NIVELES(g_level[target])
	check_player_level(target)
	console_print(id, "[ZE] %s +%s levels ? %d", g_name[target], arg2, g_level[target])
	return PLUGIN_HANDLED
}

public cmd_ze_takelevel(id, level, cid)
{
	new arg1[32], arg2[10]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	new newlvl = max(0, g_level[target] - str_to_num(arg2))
	g_ammopacks[target] = NIVELES(newlvl) + 2
	check_player_level(target)
	console_print(id, "[ZE] %s -%s levels ? %d", g_name[target], arg2, g_level[target])
	return PLUGIN_HANDLED
}

public cmd_ze_setap(id, level, cid)
{
	new arg1[32], arg2[16]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_ammopacks[target] = str_to_num(arg2)
	check_player_level(target)
	console_print(id, "[ZE] %s AP ? %d", g_name[target], g_ammopacks[target])
	return PLUGIN_HANDLED
}

public cmd_ze_giveap(id, level, cid)
{
	new arg1[32], arg2[16]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_ammopacks[target] += str_to_num(arg2)
	check_player_level(target)
	console_print(id, "[ZE] %s +%s AP ? %d", g_name[target], arg2, g_ammopacks[target])
	return PLUGIN_HANDLED
}

public cmd_ze_takeap(id, level, cid)
{
	new arg1[32], arg2[16]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_ammopacks[target] = max(0, g_ammopacks[target] - str_to_num(arg2))
	check_player_level(target)
	console_print(id, "[ZE] %s -%s AP ? %d", g_name[target], arg2, g_ammopacks[target])
	return PLUGIN_HANDLED
}

public cmd_ze_ap(id, level, cid)
{
	new arg[16]; read_argv(1, arg, charsmax(arg))
	g_ammopacks[id] += str_to_num(arg)
	check_player_level(id)
	console_print(id, "[ZE] You now have %d AP", g_ammopacks[id])
	return PLUGIN_HANDLED
}

public cmd_ze_hpoints(id, level, cid)
{
	new arg1[32], arg2[16]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_points[target][TEAM_HUMAN] = max(0, g_points[target][TEAM_HUMAN] + str_to_num(arg2))
	console_print(id, "[ZE] %s human points ? %d", g_name[target], g_points[target][TEAM_HUMAN])
	return PLUGIN_HANDLED
}

public cmd_ze_zpoints(id, level, cid)
{
	new arg1[32], arg2[16]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_points[target][TEAM_ZOMBIE] = max(0, g_points[target][TEAM_ZOMBIE] + str_to_num(arg2))
	console_print(id, "[ZE] %s zombie points ? %d", g_name[target], g_points[target][TEAM_ZOMBIE])
	return PLUGIN_HANDLED
}

public cmd_ze_wpoints(id, level, cid)
{
	new arg1[32], arg2[16]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	new amount = str_to_num(arg2)
	g_weapons_puntos[target][TEAM_HUMAN] = max(0, g_weapons_puntos[target][TEAM_HUMAN] + amount)
	console_print(id, "[ZE] %s weapon points ? %d", g_name[target], g_weapons_puntos[target][TEAM_HUMAN])
	return PLUGIN_HANDLED
}

public cmd_ze_resetstats(id, level, cid)
{
	new arg[32]; read_argv(1, arg, charsmax(arg))
	new target = ze_find_player(arg); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_ammopacks[target] = NIVELES(1) + 2
	g_level[target] = 1
	g_humanclass[target] = 0; g_zombieclass[target] = 0
	reset_points(target)
	g_points[target][TEAM_HUMAN] = 65; g_points[target][TEAM_ZOMBIE] = 70
	check_player_level(target)
	console_print(id, "[ZE] %s stats reset", g_name[target])
	return PLUGIN_HANDLED
}

public cmd_ze_setreset(id, level, cid)
{
	new arg1[32], arg2[10]; read_argv(1, arg1, charsmax(arg1)); read_argv(2, arg2, charsmax(arg2))
	new target = ze_find_player(arg1); if(!target) { console_print(id, "[ZE] Player not found"); return PLUGIN_HANDLED; }
	g_reset_level[target] = str_to_num(arg2)
	console_print(id, "[ZE] %s reset count ? %d", g_name[target], g_reset_level[target])
	return PLUGIN_HANDLED
}

/*================================================================================
 [LASER TRIP MINE]
=================================================================================*/

// Activate mine solid after short delay (reference approach)
public mine_activate_solid(ent)
{
	if(!pev_valid(ent)) return
	static szClass[32]; pev(ent, pev_classname, szClass, charsmax(szClass))
	if(!equal(szClass, classname_mine)) return
	// SOLID_SLIDEBOX = player-type collision that blocks movement (confirmed by reference plugin)
	set_pev(ent, pev_solid, SOLID_SLIDEBOX)
	engfunc(EngFunc_SetSize, ent, Float:{-10.0,-10.0,-2.0}, Float:{10.0,10.0,72.0})
	static Float:o[3]; pev(ent, pev_origin, o)
	engfunc(EngFunc_SetOrigin, ent, o)
	set_rendering(ent, kRenderFxGlowShell, 0, 230, 0, kRenderNormal, 30)
	emit_sound(ent, CHAN_WEAPON, mine_snd_place, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

mine_cleanup_all()
{
	static ent
	ent = -1
	while((ent = find_ent_by_class(ent, classname_mine)) > 0)
	{
		new beam = pev(ent, pev_iuser1)
		if(beam > 0 && pev_valid(beam)) remove_entity(beam)
		remove_entity(ent)
	}
}

// Per-frame mine blocking: runs every player frame before physics (prevents pushing through)
public fw_mine_player_prethink(id)
{
	if(!g_is_alive[id] || !is_any_zombie(id)) return HAM_IGNORED

	static Float:pl_pos[3], Float:mine_pos[3], Float:diff[3]
	pev(id, pev_origin, pl_pos)

	new mine = -1
	while((mine = find_ent_by_class(mine, classname_mine)) > 0)
	{
		if(pev(mine, pev_solid) == SOLID_NOT) continue  // not yet activated

		entity_get_vector(mine, EV_VEC_origin, mine_pos)
		diff[0] = pl_pos[0]-mine_pos[0]
		diff[1] = pl_pos[1]-mine_pos[1]
		diff[2] = pl_pos[2]-mine_pos[2]
		new Float:dist_xy = floatsqroot(diff[0]*diff[0]+diff[1]*diff[1])

		if(dist_xy < 40.0 && diff[2] >= -40.0 && diff[2] <= 90.0)
		{
			if(dist_xy < 0.5) dist_xy = 0.5
			static Float:vel[3], Float:dot
			pev(id, pev_velocity, vel)
			dot = -(vel[0]*diff[0]+vel[1]*diff[1]) / dist_xy
			if(dot > 0.0)
			{
				vel[0] += dot*diff[0]/dist_xy
				vel[1] += dot*diff[1]/dist_xy
				// Active pushback when very close
				if(dist_xy < 28.0)
				{
					vel[0] += diff[0]/dist_xy*150.0
					vel[1] += diff[1]/dist_xy*150.0
				}
				set_pev(id, pev_velocity, vel)
			}
		}
	}
	return HAM_IGNORED
}

// Mine think � handles attack detection (blocking now in PreThink)
public fw_mine_think_reg(ent)
{
	if(!pev_valid(ent)) return

	static Float:mine_pos[3], Float:pl_pos[3], Float:diff[3]
	entity_get_vector(ent, EV_VEC_origin, mine_pos)
	static Float:last_dmg[33]

	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_alive[id] || !is_any_zombie(id)) continue
		pev(id, pev_origin, pl_pos)
		diff[0] = pl_pos[0]-mine_pos[0]; diff[1] = pl_pos[1]-mine_pos[1]; diff[2] = pl_pos[2]-mine_pos[2]
		new Float:dist_xy = floatsqroot(diff[0]*diff[0]+diff[1]*diff[1])

			// Laser beam detection: if zombie is crossing the beam, explode
		// Beam goes from mine origin upward to ceiling (stored in beam entity)
		new beam_ent = pev(ent, pev_iuser1)
		if(pev_valid(beam_ent) && dist_xy < 12.0 && diff[2] > 0.0 && diff[2] < 200.0)
		{
			// Zombie is inside the laser beam column � explode!
			mine_explode(ent)
			return
		}

		// Button damage (melee)
		if(dist_xy < 50.0 && diff[2] >= -40.0 && diff[2] <= 90.0)
		{
			new btn = pev(id, pev_button)
			if((btn & IN_ATTACK) || (btn & IN_ATTACK2))
			{
				new Float:now = get_gametime()
				if(now - last_dmg[id] >= 0.5)
				{
					last_dmg[id] = now
					static Float:hp; pev(ent, pev_fuser1, hp)
					hp -= 50.0; set_pev(ent, pev_fuser1, hp)
					new owner = entity_get_edict(ent, EV_ENT_owner)
					if(is_user_valid_connected(owner))
						zp_colored_print(owner, "^4[Mine] ^1Mina atacada! HP: ^3%.0f/%.0f", hp, MINE_HP)
					if(hp <= MINE_HP * 0.4) set_rendering(ent, kRenderFxGlowShell, 230, 0, 0, kRenderNormal, 30)
					if(hp <= 0.0) { mine_explode(ent); return; }
				}
			}
		}
	}
	set_pev(ent, pev_nextthink, get_gametime() + 0.05)
}

// Touch: stop zombie velocity moving into mine
public fw_mine_touch_reg(mine, player)
{
	if(!pev_valid(mine) || !is_user_valid_alive(player) || !is_any_zombie(player)) return
	static Float:vel[3], Float:mp[3], Float:pp[3], Float:diff[3], Float:dist
	entity_get_vector(mine, EV_VEC_origin, mp); pev(player, pev_origin, pp)
	diff[0]=pp[0]-mp[0]; diff[1]=pp[1]-mp[1]
	dist = floatsqroot(diff[0]*diff[0]+diff[1]*diff[1])
	if(dist < 0.1) return
	pev(player, pev_velocity, vel)
	new Float:dot = -(vel[0]*diff[0]+vel[1]*diff[1])/dist
	if(dot > 0.0) { vel[0]+=dot*diff[0]/dist; vel[1]+=dot*diff[1]/dist; set_pev(player,pev_velocity,vel); }
}


public cmd_mine_place_end(id)
{
	return PLUGIN_HANDLED
}
public cmd_mine_remove_end(id)
{
	return PLUGIN_HANDLED
}

public cmd_mine_place(id)
{
	if(!g_is_alive[id] || !is_human(id))
		return PLUGIN_HANDLED

	new limit = MINE_LIMITS[0]  // default limit 2
	if(g_mine_count[id] >= limit)
	{
		zp_colored_print(id, "^4[Mine] ^1Limite de minas alcanzado (%d). Presiona H para retirar una.", limit)
		return PLUGIN_HANDLED
	}

	// Traceline from player eyes along aim direction
	static Float:eye_pos[3], Float:aim_vec[3], Float:end_pos[3]
	static Float:origin[3], Float:normal[3], Float:ent_angles[3]
	pev(id, pev_origin, eye_pos)
	eye_pos[2] += 15.0
	velocity_by_aim(id, MINE_PLACE_DIST, aim_vec)
	xs_vec_add(aim_vec, eye_pos, end_pos)

	static Float:fraction
	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, eye_pos, end_pos, DONT_IGNORE_MONSTERS, id, tr)
	get_tr2(tr, TR_flFraction, fraction)
	get_tr2(tr, TR_vecEndPos, origin)
	get_tr2(tr, TR_vecPlaneNormal, normal)
	free_tr2(tr)

	if(fraction >= 1.0)
	{
		zp_colored_print(id, "^4[Mine] ^1Apunta a una superficie para colocar la mina.")
		return PLUGIN_HANDLED
	}

	// Mine orientation from surface normal (correct for floor, wall, any surface)
	vector_to_angle(normal, ent_angles)

	// Offset from surface
	xs_vec_mul_scalar(normal, 8.0, normal)
	xs_vec_add(origin, normal, origin)

	// Create mine as func_breakable (required for SOLID_SLIDEBOX blocking + HAM damage)
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_breakable"))
	if(!ent) return PLUGIN_HANDLED
	set_pev(ent, pev_classname, classname_mine)
	entity_set_edict(ent, EV_ENT_owner, id)
	engfunc(EngFunc_SetModel, ent, mine_model)
	set_pev(ent, pev_angles, ent_angles)
	engfunc(EngFunc_SetSize, ent, Float:{-4.0,-4.0,-4.0}, Float:{4.0,4.0,4.0})
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	entity_set_int(ent, EV_INT_rendermode, kRenderNormal)
	entity_set_float(ent, EV_FL_renderamt, 255.0)
	entity_set_int(ent, EV_INT_effects, 0)
	engfunc(EngFunc_SetOrigin, ent, origin)
	// pev_health for entity (NOT set_user_health which is players only)
	set_pev(ent, pev_health, MINE_HP)
	set_pev(ent, pev_max_health, MINE_HP)
	set_pev(ent, pev_fuser1, MINE_HP)
	set_rendering(ent, kRenderFxGlowShell, 0, 230, 0, kRenderNormal, 30)

	set_task(0.5, "mine_activate_solid", ent)
	set_pev(ent, pev_nextthink, get_gametime() + 0.6)  // start think after activation
	create_mine_beam(ent)

	g_mine_count[id]++
	zp_colored_print(id, "^4[Mine] ^3Mina colocada! HP: ^1%.0f ^3| Presiona C para retirar.", MINE_HP)
	return PLUGIN_HANDLED
}

public cmd_mine_remove(id)
{
	if(!g_is_alive[id] || !is_human(id))
		return PLUGIN_HANDLED

	// Aim-based removal: hard limit = MINE_PLACE_DIST from player eye (same as placement),
	// among mines in range pick the one closest to the crosshair aim endpoint
	static Float:eye_pos[3], Float:aim_vec[3], Float:aim_end[3], Float:ent_pos[3]
	pev(id, pev_origin, eye_pos)
	eye_pos[2] += 15.0
	velocity_by_aim(id, MINE_PLACE_DIST, aim_vec)
	xs_vec_add(aim_vec, eye_pos, aim_end)

	new best_ent = -1
	new Float:best_dist = 99999.0
	new ent = -1
	while((ent = find_ent_by_class(ent, classname_mine)) > 0)
	{
		if(entity_get_edict(ent, EV_ENT_owner) != id) continue
		entity_get_vector(ent, EV_VEC_origin, ent_pos)
		if(vector_distance(eye_pos, ent_pos) > float(MINE_PLACE_DIST)) continue
		new Float:d = vector_distance(aim_end, ent_pos)
		if(d < best_dist) { best_dist = d; best_ent = ent; }
	}
	if(best_ent == -1)
	{
		zp_colored_print(id, "^4[Mine] ^1No hay minas tuyas cerca (max %d unidades).", MINE_PLACE_DIST)
		return PLUGIN_HANDLED
	}
	new beam = pev(best_ent, pev_iuser1)
	if(beam > 0 && pev_valid(beam)) remove_entity(beam)
	remove_entity(best_ent)
	if(g_mine_count[id] > 0) g_mine_count[id]--
	zp_colored_print(id, "^4[Mine] ^3Mina retirada.")
	return PLUGIN_HANDLED
}

// HAM hook: zombie melee (DMG_SLASH) damages only the CLOSEST mine to attacker
public fw_mine_takedamage(ent, inflictor, attacker, Float:damage, damagetype)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	static szClass[32]
	pev(ent, pev_classname, szClass, charsmax(szClass))
	if(!equal(szClass, classname_mine)) return HAM_IGNORED
	if(!is_user_valid_connected(attacker) || !is_any_zombie(attacker)) return HAM_IGNORED
	if(!(damagetype & DMG_SLASH)) return HAM_IGNORED

	// Find the single closest mine to attacker � only THAT mine takes damage
	static Float:atk_pos[3], Float:ent_pos[3]
	pev(attacker, pev_origin, atk_pos)

	new Float:best_dist = 9999.0
	new best_mine = -1
	new check = -1
	while((check = find_ent_by_class(check, classname_mine)) > 0)
	{
		entity_get_vector(check, EV_VEC_origin, ent_pos)
		new Float:d = vector_distance(atk_pos, ent_pos)
		if(d < best_dist) { best_dist = d; best_mine = check; }
	}

	// Only the closest mine takes damage
	if(best_mine != ent) return HAM_SUPERCEDE

	static Float:hp
	pev(ent, pev_fuser1, hp)
	hp -= damage
	set_pev(ent, pev_fuser1, hp)

	// Notify mine owner
	new owner = entity_get_edict(ent, EV_ENT_owner)
	if(is_user_valid_connected(owner))
		zp_colored_print(owner, "^4[Mine] ^3Tu mina fue golpeada! HP: ^1%.0f/%.0f", hp, MINE_HP)

	// Glow red below 40% HP
	if(hp <= MINE_HP * 0.4)
		set_rendering(ent, kRenderFxGlowShell, 230, 0, 0, kRenderNormal, 30)

	if(hp <= 0.0)
		mine_explode(ent)

	return HAM_SUPERCEDE
}

mine_explode(ent)
{
	static Float:origin[3]
	entity_get_vector(ent, EV_VEC_origin, origin)

	// Screen shake for everyone nearby
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(g_exploSpr)
	write_byte(20)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()

	message_begin(MSG_BROADCAST, g_msgScreenShake)
	write_short((1<<12) * 12)
	write_short((1<<12) * 2)
	write_short((1<<12) * 8)
	message_end()

	// Radius damage + knockback to zombies
	static victim; victim = -1
	while(0 < (victim = find_ent_in_sphere(victim, origin, MINE_EXPLODE_RADIUS)) <= g_maxplayers)
	{
		if(!is_user_valid_alive(victim) || !is_any_zombie(victim)) continue
		ExecuteHamB(Ham_TakeDamage, victim, ent, ent, MINE_DAMAGE, DMG_BLAST)
		// Knockback away from mine
		static Float:vpos[3], Float:kdir[3]
		pev(victim, pev_origin, vpos)
		xs_vec_sub(vpos, origin, kdir)
		kdir[2] += 50.0
		xs_vec_normalize(kdir, kdir)
		xs_vec_mul_scalar(kdir, 600.0, kdir)
		set_pev(victim, pev_velocity, kdir)
	}

	// Remove beam then mine
	new beam = pev(ent, pev_iuser1)
	if(beam > 0 && pev_valid(beam)) remove_entity(beam)

	new owner = entity_get_edict(ent, EV_ENT_owner)
	if(is_user_valid_connected(owner) && g_mine_count[owner] > 0)
		g_mine_count[owner]--

	emit_sound(0, CHAN_AUTO, mine_snd_explode, 1.0, ATTN_NORM, 0, PITCH_NORM)
	remove_entity(ent)
}

create_mine_beam(mine_ent)
{
	static Float:start[3], Float:end_up[3], Float:endp[3]
	entity_get_vector(mine_ent, EV_VEC_origin, start)
	start[2] += 4.0
	end_up[0] = start[0]; end_up[1] = start[1]; end_up[2] = start[2] + 2048.0

	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, start, end_up, IGNORE_MONSTERS, mine_ent, tr)
	get_tr2(tr, TR_vecEndPos, endp)
	free_tr2(tr)

	// Create a persistent info_target beam entity
	new beam = create_entity("info_target")
	if(!pev_valid(beam)) return

	entity_set_string(beam, EV_SZ_classname, "ze_mine_beam")
	entity_set_int(beam, EV_INT_movetype, MOVETYPE_NONE)
	entity_set_int(beam, EV_INT_solid, SOLID_NOT)

	// Draw beam every second via a think that re-emits TE_BEAMPOINTS
	set_pev(beam, pev_nextthink, get_gametime() + 0.5)
	// Store mine ref in beam
	entity_set_edict(beam, EV_ENT_owner, mine_ent)
	// Store start/end in pev fields
	set_pev(beam, pev_origin, start)
	set_pev(beam, pev_angles, endp)

	register_think("ze_mine_beam", "think_mine_beam")

	// Link beam to mine
	set_pev(mine_ent, pev_iuser1, beam)

	// Emit initial beam
	mine_beam_draw(start, endp)
}

public think_mine_beam(beam)
{
	if(!pev_valid(beam)) return
	new mine_ent = entity_get_edict(beam, EV_ENT_owner)
	if(!pev_valid(mine_ent))
	{
		remove_entity(beam)
		return
	}
	static Float:start[3], Float:endp[3]
	pev(beam, pev_origin, start)
	pev(beam, pev_angles, endp)
	mine_beam_draw(start, endp)
	set_pev(beam, pev_nextthink, get_gametime() + 0.8)
}

mine_beam_draw(Float:start[3], Float:endp[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	engfunc(EngFunc_WriteCoord, endp[0])
	engfunc(EngFunc_WriteCoord, endp[1])
	engfunc(EngFunc_WriteCoord, endp[2])
	write_short(g_laserMineSpr)
	write_byte(1)   // startframe
	write_byte(5)   // framerate
	write_byte(9)   // life (tenths)
	write_byte(8)   // width
	write_byte(0)   // noise
	write_byte(0); write_byte(230); write_byte(0)  // RGB green
	write_byte(200) // brightness
	write_byte(0)   // speed
	message_end()
}

/*================================================================================
 [FLASHLIGHT]
=================================================================================*/
public cmd_flashlight(id)
{
	if(!g_is_alive[id] || is_any_zombie(id))
		return PLUGIN_HANDLED

	// Toggle flashlight via impulse 100
	client_cmd(id, "impulse 100")
	return PLUGIN_HANDLED
}

/*================================================================================
 [ADMIN MENU]
=================================================================================*/

show_menu_admin(id)
{
	if(!(get_user_flags(id) & ACCESS_FLAG)) return

	oldmenu_create("Admin Menu ZE", "\r\rMENU ADMIN^n")

	// 1-7: game modes � always available from admin menu (handler sets g_newround=true)
	// Modos 1-7
	oldmenu_additem(1, 0, "\r1.\y Modo Nemesis \d(elige jugador)")
	oldmenu_additem(2, 0, "\r2.\y Modo Survivor")
	oldmenu_additem(3, 0, "\r3.\y Modo Assassin \d(elige jugador)")
	oldmenu_additem(4, 0, "\r4.\y Modo Swarm")
	oldmenu_additem(5, 0, "\r5.\y Modo Multi Infeccion")
	oldmenu_additem(6, 0, "\r6.\y Modo Plague")
	oldmenu_additem(7, 0, "\r7.\y Modo Normal^n")

	// 8-9: conversiones directas
	oldmenu_additem(8, 0, "\r8.\y Convertir a Zombie")
	oldmenu_additem(9, 0, "\r9.\y Convertir a Humano")

	oldmenu_additem(0, 0, "^n\r0.\y Salir")
	oldmenu_display(id)
}

public menu_admin_ze(id, itemnum, value, page)
{
	if(!(get_user_flags(id) & ACCESS_FLAG)) return
	if(itemnum == 0) { play_soundmenu(id, SOUNDMENU_CANCEL); return; }

	switch(itemnum)
	{
		// Admin menu bypasses allowed_* checks � forces mode directly
		case 1:
		{
			// Nemesis: elegir jugador
			g_admin_action[id] = 1
			show_menu_admin_playerselect(id, 1)
			return
		}
		case 2:
		{
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Survivor.", name)
			g_newround = true
			make_a_zombie(MODE_SURVIVOR, id)
		}
		case 3:
		{
			// Assassin: elegir jugador
			g_admin_action[id] = 3
			show_menu_admin_playerselect(id, 1)
			return
		}
		case 4:
		{
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Swarm.", name)
			g_newround = true
			make_a_zombie(MODE_SWARM, 0)
		}
		case 5:
		{
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Multi Infeccion.", name)
			g_newround = true
			make_a_zombie(MODE_MULTI, 0)
		}
		case 6:
		{
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Plague.", name)
			g_newround = true
			make_a_zombie(MODE_PLAGUE, 0)
		}
		case 7:
		{
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Normal.", name)
			g_newround = true
			make_a_zombie(MODE_INFECTION, 0)
		}
		case 8:
		{
			// Convertir a zombie: elegir jugador
			g_admin_action[id] = 8
			show_menu_admin_playerselect(id, 1)
			return
		}
		case 9:
		{
			// Convertir a humano: elegir jugador
			g_admin_action[id] = 9
			show_menu_admin_playerselect(id, 1)
			return
		}
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
}

/*================================================================================
 [OWNER MENU]
=================================================================================*/

show_menu_owner(id)
{
	if(!(get_user_flags(id) & OWNER_FLAG)) return

	new mapname[32]
	get_mapname(mapname, charsmax(mapname))

	oldmenu_create("menu_owner", "\r\rOWNER MENU^n")

	if(equal(mapname, ILLIDAN_MAP) && !g_illidanround)
		oldmenu_additem(1, 0, "\r1.\y Boss Illidan")
	else if(g_illidanround)
		oldmenu_additem(-1, 0, "\d1. Boss Illidan \r(activo)")
	else
		oldmenu_additem(-1, 0, "\d1. Boss Illidan \r(mapa incorrecto)")

	oldmenu_additem(2, 0, "\r2.\y Gifts Event^n")

	oldmenu_additem(3, 0, "\r3.\y Regalar Ammo Packs")
	oldmenu_additem(4, 0, "\r4.\y Regalar Puntos Zombie")
	oldmenu_additem(5, 0, "\r5.\y Regalar Puntos Humano")
	oldmenu_additem(6, 0, "\r6.\y Regalar Puntos de Arma")

	oldmenu_additem(0, 0, "^n\r0.\y Salir")
	oldmenu_display(id)
}

public menu_owner(id, itemnum, value, page)
{
	if(!(get_user_flags(id) & OWNER_FLAG)) return
	if(itemnum == 0) { play_soundmenu(id, SOUNDMENU_CANCEL); return; }

	switch(itemnum)
	{
		case 1: // Boss Illidan
		{
			new mapname[32]; get_mapname(mapname, charsmax(mapname))
			if(!equal(mapname, ILLIDAN_MAP))
			{
				zp_colored_print(id, "^4[Owner]^3 Solo disponible en ^4zl_boss_illidan_alpha^3.")
				show_menu_owner(id); return
			}
			if(g_illidanround)
			{
				zp_colored_print(id, "^4[Owner]^3 Boss ya activo.")
				show_menu_owner(id); return
			}
			remove_task(TASK_MAKEZOMBIE)
			g_newround = false; g_survround = false
			g_nemround = false; g_swarmround = false; g_plagueround = false
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Owner]^3 %s^1 inicio el Boss Illidan!", name)
			server_print("[IllidanBoss] Boss manually started by %s", name)
			illidan_round_start()
		}
		case 2: // Gifts Event
		{
			client_cmd(id, "ze_gift_event 10")
			new name[32]; get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "^4[Owner]^3 %s^1 lanzo un evento de regalos!", name)
		}
		case 3: // Regalar AP
		{
			g_owner_gift_type[id] = 3
			set_task(0.1, "task_owner_gift_menu", id + TASK_OWNER_GIFT_MENU)
			return
		}
		case 4: // Regalar Pts Zombie
		{
			g_owner_gift_type[id] = 4
			set_task(0.1, "task_owner_gift_menu", id + TASK_OWNER_GIFT_MENU)
			return
		}
		case 5: // Regalar Pts Humano
		{
			g_owner_gift_type[id] = 5
			set_task(0.1, "task_owner_gift_menu", id + TASK_OWNER_GIFT_MENU)
			return
		}
		case 6: // Regalar Pts Arma
		{
			g_owner_gift_type[id] = 6
			set_task(0.1, "task_owner_gift_menu", id + TASK_OWNER_GIFT_MENU)
			return
		}
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
}

public task_owner_gift_menu(taskid)
{
	new id = taskid - TASK_OWNER_GIFT_MENU
	if(is_user_connected(id))
		show_menu_owner_playerselect(id, 1)
}

/*================================================================================
 [OWNER GIFT — PLAYER SELECT + AMOUNT]
=================================================================================*/

show_menu_owner_playerselect(id, page)
{
	if(!(get_user_flags(id) & OWNER_FLAG)) return

	new label[32]
	switch(g_owner_gift_type[id])
	{
		case 3: copy(label, 31, "Ammo Packs")
		case 4: copy(label, 31, "Pts Zombie")
		case 5: copy(label, 31, "Pts Humano")
		case 6: copy(label, 31, "Pts Arma")
		default: copy(label, 31, "?")
	}

	new maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page, fnGetPlaying())

	oldmenu_create("menu_owner_playerselect", "\rRegalar %s^n\rJugador: %d/%d", label, page, maxpages)

	for(new i = start, count = 1; i < end; i++, count++)
	{
		new pid = g_players[i]
		oldmenu_additem(count, pid, "\r%d. \y%s", count, g_name[pid])
	}

	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else         oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else                oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")

	oldmenu_display(id, page)
}

public menu_owner_playerselect(id, itemnum, value, page)
{
	if(!(get_user_flags(id) & OWNER_FLAG)) return
	if(itemnum == 0) { play_soundmenu(id, SOUNDMENU_CANCEL); return; }
	if(itemnum == 8) { play_soundmenu(id, SOUNDMENU_BACK); show_menu_owner_playerselect(id, page-1); return; }
	if(itemnum == 9) { play_soundmenu(id, SOUNDMENU_NEXT); show_menu_owner_playerselect(id, page+1); return; }

	new target = value
	if(!target || !is_user_connected(target)) { show_menu_owner_playerselect(id, page); return; }

	g_owner_gift_target[id] = target
	play_soundmenu(id, SOUNDMENU_SELECT)
	show_menu_owner_amount(id)
}

show_menu_owner_amount(id)
{
	if(!(get_user_flags(id) & OWNER_FLAG)) return

	new target = g_owner_gift_target[id]
	new tname[32]
	get_user_name(target, tname, charsmax(tname))

	switch(g_owner_gift_type[id])
	{
		case 3: // Ammo Packs
		{
			oldmenu_create("menu_owner_amount", "\rRegalar Ammo Packs^n\rA: \y%s", tname)
			oldmenu_additem(1,   50, "\r1. \y50 AP")
			oldmenu_additem(2,  100, "\r2. \y100 AP")
			oldmenu_additem(3,  250, "\r3. \y250 AP")
			oldmenu_additem(4,  500, "\r4. \y500 AP")
			oldmenu_additem(5, 1000, "\r5. \y1000 AP")
		}
		case 4: // Pts Zombie
		{
			oldmenu_create("menu_owner_amount", "\rRegalar Pts Zombie^n\rA: \y%s", tname)
			oldmenu_additem(1,  10, "\r1. \y10 pts")
			oldmenu_additem(2,  25, "\r2. \y25 pts")
			oldmenu_additem(3,  50, "\r3. \y50 pts")
			oldmenu_additem(4, 100, "\r4. \y100 pts")
			oldmenu_additem(5, 250, "\r5. \y250 pts")
		}
		case 5: // Pts Humano
		{
			oldmenu_create("menu_owner_amount", "\rRegalar Pts Humano^n\rA: \y%s", tname)
			oldmenu_additem(1,  10, "\r1. \y10 pts")
			oldmenu_additem(2,  25, "\r2. \y25 pts")
			oldmenu_additem(3,  50, "\r3. \y50 pts")
			oldmenu_additem(4, 100, "\r4. \y100 pts")
			oldmenu_additem(5, 250, "\r5. \y250 pts")
		}
		case 6: // Pts Arma
		{
			oldmenu_create("menu_owner_amount", "\rRegalar Pts Arma^n\rA: \y%s", tname)
			oldmenu_additem(1,  25, "\r1. \y25 pts")
			oldmenu_additem(2,  50, "\r2. \y50 pts")
			oldmenu_additem(3, 100, "\r3. \y100 pts")
			oldmenu_additem(4, 250, "\r4. \y250 pts")
			oldmenu_additem(5, 500, "\r5. \y500 pts")
		}
	}
	oldmenu_additem(0, 0, "^n\r0. \ySalir")
	oldmenu_display(id)
}

public menu_owner_amount(id, itemnum, value, page)
{
	if(!(get_user_flags(id) & OWNER_FLAG)) return
	if(itemnum == 0) { play_soundmenu(id, SOUNDMENU_CANCEL); return; }

	new target = g_owner_gift_target[id]
	if(!target || !is_user_connected(target))
	{
		zp_colored_print(id, "^4[Owner]^3 El jugador ya no esta conectado.")
		show_menu_owner(id)
		return
	}

	new amount = value
	new aname[32]; get_user_name(id, aname, charsmax(aname))
	new tname[32]; get_user_name(target, tname, charsmax(tname))

	switch(g_owner_gift_type[id])
	{
		case 3:
		{
			g_ammopacks[target] += amount
			zp_colored_print(target, "^4[Owner] ^3%s^1 te regalo ^4%d Ammo Packs^1!", aname, amount)
			zp_colored_print(id, "^4[Owner]^1 Regalaste ^4%d AP^1 a ^3%s^1.", amount, tname)
		}
		case 4:
		{
			g_points[target][TEAM_ZOMBIE] += amount
			zp_colored_print(target, "^4[Owner] ^3%s^1 te regalo ^4%d Puntos Zombie^1!", aname, amount)
			zp_colored_print(id, "^4[Owner]^1 Regalaste ^4%d Pts Zombie^1 a ^3%s^1.", amount, tname)
		}
		case 5:
		{
			g_points[target][TEAM_HUMAN] += amount
			zp_colored_print(target, "^4[Owner] ^3%s^1 te regalo ^4%d Puntos Humano^1!", aname, amount)
			zp_colored_print(id, "^4[Owner]^1 Regalaste ^4%d Pts Humano^1 a ^3%s^1.", amount, tname)
		}
		case 6:
		{
			g_weapons_puntos[target][0] += amount
			zp_colored_print(target, "^4[Owner] ^3%s^1 te regalo ^4%d Puntos de Arma^1!", aname, amount)
			zp_colored_print(id, "^4[Owner]^1 Regalaste ^4%d Pts Arma^1 a ^3%s^1.", amount, tname)
		}
	}

	emit_sound(target, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	play_soundmenu(id, SOUNDMENU_SELECT)
}

/*================================================================================
 [ADMIN PLAYER SELECT SUBMENU]
 Usado para Nemesis, Assassin, Convertir a Zombie/Humano
=================================================================================*/

show_menu_admin_playerselect(id, page)
{
	if(!(get_user_flags(id) & ACCESS_FLAG)) return

	new action = g_admin_action[id]
	new label[32]
	if(action == 1)      copy(label, 31, "Modo Nemesis")
	else if(action == 3) copy(label, 31, "Modo Assassin")
	else if(action == 8) copy(label, 31, "-> Zombie")
	else if(action == 9) copy(label, 31, "-> Humano")
	else                 copy(label, 31, "Accion")

	new maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page, fnGetPlaying())

	oldmenu_create("menu_admin_playerselect", "\rElegir jugador (%s): %d/%d", label, page, maxpages)

	for(new i = start, count = 1; i < end; i++, count++)
	{
		new pid = g_players[i]
		if(action == 8)
			oldmenu_additem(count, pid, "\r%d. \y%s \d%s", count, g_name[pid], is_any_zombie(pid) ? "[zombie]" : "")
		else if(action == 9)
			oldmenu_additem(count, pid, "\r%d. \y%s \d%s", count, g_name[pid], is_any_zombie(pid) ? "" : "[humano]")
		else
			oldmenu_additem(count, pid, "\r%d. \y%s", count, g_name[pid])
	}

	if(page > 1) oldmenu_additem(8, 0, "^n\r8. \yAtras")
	else oldmenu_additem(-1, 0, "^n\d8. Atras")
	if(page < maxpages) oldmenu_additem(9, 0, "\r9. \ySiguiente")
	else oldmenu_additem(-1, 0, "\d9. Siguiente")
	oldmenu_additem(0, 0, "\r0. \ySalir")

	oldmenu_display(id, page)
}

public menu_admin_playerselect(id, itemnum, value, page)
{
	if(!(get_user_flags(id) & ACCESS_FLAG)) return

	if(itemnum == 0) { play_soundmenu(id, SOUNDMENU_CANCEL); return; }

	if(itemnum == 8) { play_soundmenu(id, SOUNDMENU_BACK); show_menu_admin_playerselect(id, page-1); return; }
	if(itemnum == 9) { play_soundmenu(id, SOUNDMENU_NEXT); show_menu_admin_playerselect(id, page+1); return; }

	new target = value
	if(!target || !is_user_connected(target)) { show_menu_admin_playerselect(id, page); return; }

	new aname[32]; get_user_name(id, aname, charsmax(aname))
	new tname[32]; get_user_name(target, tname, charsmax(tname))

	switch(g_admin_action[id])
	{
		case 1: // Modo Nemesis sobre ese jugador
		{
			if(!g_is_alive[target]) ExecuteHamB(Ham_CS_RoundRespawn, target)
			g_newround = true
			make_a_zombie(MODE_NEMESIS, target)
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Nemesis sobre ^3%s^1.", aname, tname)
		}
		case 3: // Modo Assassin sobre ese jugador
		{
			if(!g_is_alive[target]) ExecuteHamB(Ham_CS_RoundRespawn, target)
			g_newround = true
			make_a_zombie(MODE_ASSASSIN, target)
			zp_colored_print(0, "^4[Admin]^3 %s^1 inicio Modo Assassin sobre ^3%s^1.", aname, tname)
		}
		case 8: // Convertir a zombie
		{
			if(!g_is_alive[target]) ExecuteHamB(Ham_CS_RoundRespawn, target)
			zombieme(target, CLASS_ZOMBIE)
			zp_colored_print(0, "^4[Admin]^3 %s^1 convirtio a ^3%s^1 en zombie.", aname, tname)
		}
		case 9: // Convertir a humano
		{
			humanme(target, CLASS_HUMAN)
			zp_colored_print(0, "^4[Admin]^3 %s^1 convirtio a ^3%s^1 en humano.", aname, tname)
		}
	}
	play_soundmenu(id, SOUNDMENU_SELECT)
}

// Stubs for menus registered but not yet implemented
public menu_class_h_info(id, itemnum, value, page)
{
	play_soundmenu(id, SOUNDMENU_CANCEL)
}
public menu_class_z_info(id, itemnum, value, page)
{
	play_soundmenu(id, SOUNDMENU_CANCEL)
}
// Central dispatcher for all oldmenu-based menus
// register_menu passes raw bit-index key (0=key1, 1=key2, ..., 9=key0)
// Converts to itemnum (1-9, 0) and value, then calls the right handler
public ze_oldmenu_dispatch(id, key)
{
	// Convert bit-index to actual key number
	new itemnum = (key == 9) ? 0 : (key + 1)

	// Find value stored for this key
	new value = 0
	for(new i = 0; i < g_oldmenu_itemcount; i++)
	{
		if(g_oldmenu_items[i][0] == itemnum)
		{
			value = g_oldmenu_items[i][1]
			break
		}
	}

	new page = g_oldmenu_page[id]

	// Dispatch based on which menu this player is currently in
	static menu[64]
	copy(menu, charsmax(menu), g_current_menu[id])

	if     (equal(menu, "menu_game"))          menu_game(id, itemnum, value, page)
	else if(equal(menu, "menu_prebuy"))        menu_prebuy(id, itemnum, value, page)
	else if(equal(menu, "menu_primarybuy"))    menu_primarybuy(id, itemnum, value, page)
	else if(equal(menu, "menu_secondarybuy"))  menu_secondarybuy(id, itemnum, value, page)
	else if(equal(menu, "menu_extras"))        menu_extras(id, itemnum, value, page)
	else if(equal(menu, "menu_zclass"))        menu_zclass(id, itemnum, value, page)
	else if(equal(menu, "menu_zclass_info"))   menu_zclass_info(id, itemnum, value, page)
	else if(equal(menu, "menu_hclass"))        menu_hclass(id, itemnum, value, page)
	else if(equal(menu, "menu_hclass_info"))   menu_hclass_info(id, itemnum, value, page)
	else if(equal(menu, "menu_managepj"))      menu_managepj(id, itemnum, value, page)
	else if(equal(menu, "menu_personal"))      menu_personal(id, itemnum, value, page)
	else if(equal(menu, "menu_account"))       menu_account(id, itemnum, value, page)
	else if(equal(menu, "menu_interface"))     menu_interface(id, itemnum, value, page)
	else if(equal(menu, "menu_hudposition"))   menu_hudposition(id, itemnum, value, page)
	else if(equal(menu, "menu_statistics"))    menu_statistics(id, itemnum, value, page)
	else if(equal(menu, "menu_confirm"))       menu_confirm(id, itemnum, value, page)
	else if(equal(menu, "menu_donate"))        menu_donate(id, itemnum, value, page)
	else if(equal(menu, "Admin Menu ZE"))           menu_admin_ze(id, itemnum, value, page)
	else if(equal(menu, "menu_owner"))               menu_owner(id, itemnum, value, page)
	else if(equal(menu, "menu_owner_playerselect"))  menu_owner_playerselect(id, itemnum, value, page)
	else if(equal(menu, "menu_owner_amount"))        menu_owner_amount(id, itemnum, value, page)
	else if(equal(menu, "menu_admin_playerselect"))  menu_admin_playerselect(id, itemnum, value, page)
}

/*================================================================================
 [ILLIDAN BOSS ROUND]
=================================================================================*/

// ---- Stock helpers defined first so they are visible to all callers below ----

stock illidan_alive_count()
{
	new c = 0
	for(new i = 1; i <= g_maxplayers; i++)
		if(g_is_alive[i]) c++
	return c
}

stock illidan_choose_player(ent, mode)
{
	if(mode == 2) // closest
	{
		new closest = 0
		new Float:min_d = 9999999.0
		for(new i = 1; i <= g_maxplayers; i++)
		{
			if(!g_is_alive[i]) continue
			new Float:d = entity_range(ent, i)
			if(d < min_d) { min_d = d; closest = i; }
		}
		return closest
	}
	new pool[32], cnt = 0
	for(new i = 1; i <= g_maxplayers; i++)
		if(g_is_alive[i]) pool[cnt++] = i
	if(!cnt) return 0
	return pool[random_num(0, cnt - 1)]
}

stock Float:illidan_move(ent, target, Float:speed, Float:vel[3], Float:ang[3])
{
	static Float:o1[3], Float:o2[3], Float:v[3]
	pev(ent, pev_origin, o1)
	pev(target, pev_origin, o2)
	xs_vec_sub(o2, o1, v)
	new Float:len = xs_vec_len(v)
	vector_to_angle(v, ang)
	ang[0] = 0.0; ang[2] = 0.0
	xs_vec_normalize(v, v)
	xs_vec_mul_scalar(v, speed, v)
	vel[0] = v[0]; vel[1] = v[1]; vel[2] = 0.0
	return len
}

stock illidan_anim(ent, seq, Float:rate)
{
	set_pev(ent, pev_sequence, seq)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, rate)
	set_pev(ent, pev_animtime, get_gametime())
}

stock illidan_damage_player(id, damage)
{
	if(!is_user_alive(id)) return
	ExecuteHamB(Ham_TakeDamage, id, g_illidan_boss, g_illidan_boss, float(damage), DMG_CLUB)
}

stock illidan_screenfade(id, duration, holdtime, color[3], alpha)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short((1<<12) * duration)
	write_short((1<<12) * holdtime)
	write_short(FFADE_IN)
	write_byte(color[0]); write_byte(color[1]); write_byte(color[2])
	write_byte(alpha)
	message_end()
}

stock illidan_screenshake(id, amplitude, duration)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12) * amplitude)
	write_short((1<<12) * duration)
	write_short((1<<12) * 4)
	message_end()
}

stock illidan_spawn_attack_visual(model_idx)
{
	static Float:o[3], Float:a[3]
	pev(g_illidan_boss, pev_origin, o)
	pev(g_illidan_boss, pev_angles, a)
	new ent = create_entity("info_target")
	set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	engfunc(EngFunc_SetModel, ent, g_illidanModels[model_idx])
	engfunc(EngFunc_SetOrigin, ent, o)
	set_pev(ent, pev_angles, a)
	set_pev(ent, pev_classname, "boss_illidan_attack")
	set_pev(ent, pev_button, 255)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	if(model_idx == 6) illidan_anim(ent, 1, 1.0)
}

stock illidan_blitz_trace_kill(Float:s[3], Float:e[3])
{
	static trace_h, Float:endpos[3], victim
	engfunc(EngFunc_TraceLine, s, e, DONT_IGNORE_MONSTERS, -1, trace_h)
	get_tr2(trace_h, TR_vecEndPos, endpos)
	victim = 0
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, endpos, 30.0)) != 0)
	{
		if(is_user_alive(victim))
			ExecuteHamB(Ham_Killed, victim, victim, 2)
	}
}

stock illidan_get_forward_pos(ent, Float:fwd_dist, Float:up_dist, Float:result[3])
{
	static Float:o[3], Float:a[3], Float:f[3]
	pev(ent, pev_origin, o)
	pev(ent, pev_angles, a)
	angle_vector(a, ANGLEVECTOR_FORWARD, f)
	result[0] = o[0] + f[0] * fwd_dist
	result[1] = o[1] + f[1] * fwd_dist
	result[2] = o[2] + f[2] * fwd_dist + up_dist
}

stock illidan_laser(a, b, color[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMENTS)
	write_short(a); write_short(b)
	write_short(g_illidan_ires[8])
	write_byte(1); write_byte(1)
	write_byte(1000)
	write_byte(8); write_byte(5)
	write_byte(color[0]); write_byte(color[1]); write_byte(color[2])
	write_byte(200); write_byte(0)
	message_end()
}

stock illidan_shockwave(Float:orig[3], life, width, Float:radius, color[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, orig, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, orig[0])
	engfunc(EngFunc_WriteCoord, orig[1])
	engfunc(EngFunc_WriteCoord, orig[2] - 40.0)
	engfunc(EngFunc_WriteCoord, orig[0])
	engfunc(EngFunc_WriteCoord, orig[1])
	engfunc(EngFunc_WriteCoord, orig[2] + radius)
	write_short(g_illidan_ires[9])
	write_byte(0); write_byte(0)
	write_byte(life); write_byte(width); write_byte(0)
	write_byte(color[0]); write_byte(color[1]); write_byte(color[2])
	write_byte(255); write_byte(0)
	message_end()
}

// ---- End of stock helpers ----

illidan_round_start()
{
	g_illidanround = true
	g_survround = true  // blocks zombie infection
	arrayset(g_illidan_damage, 0.0, 33)
	g_illidan_ability_time = 0.0
	g_illidan_spawned = false
	g_illidan_phase = 1
	g_illidan_ability = 0

	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!g_is_alive[i]) continue
		if(is_any_zombie(i)) humanme(i, CLASS_HUMAN)
		if(fm_get_user_team(i) != ZP_TEAM_CT)
		{
			remove_task(i + TASK_TEAM)
			fm_set_user_team(i, ZP_TEAM_CT)
			fm_user_team_update(i)
		}
	}

	PlaySound(g_illidanSounds[5])

	// Illidan map: max brightness + persistent NVG
	set_lights("z")
	set_task(2.0, "illidan_refresh_lights", TASK_ILLIDAN_TIMER + 1, _, _, "b")

	set_hudmessage(128, 0, 255, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "--- ILLIDAN STORMRAGE ---")
	zp_colored_print(0, "^4[BOSS]^3 Illidan Stormrage^1 ha llegado. Todos contra el boss!")

	// Create boss entity now; activate after 7s intro delay
	new boss = engfunc(EngFunc_FindEntityByString, 0, "targetname", "boss")
	server_print("[IllidanBoss] boss entity found: %d", boss)
	if(boss <= 0)
		boss = create_entity("info_target")

	g_illidan_boss = boss
	pev(boss, pev_origin, g_illidan_origin)

	engfunc(EngFunc_SetModel, boss, g_illidanModels[0])
	engfunc(EngFunc_SetSize, boss, Float:{-42.0, -42.0, -32.0}, Float:{ILLIDAN_BOSS_Z, 42.0, 72.0})
	set_pev(boss, pev_classname, "boss_illidan")
	set_pev(boss, pev_deadflag, DEAD_RESPAWNABLE)
	set_pev(boss, pev_takedamage, DAMAGE_NO)
	set_pev(boss, pev_solid, SOLID_SLIDEBOX)
	set_pev(boss, pev_movetype, MOVETYPE_TOSS)
	set_pev(boss, pev_body, 8)
	illidan_anim(boss, 1, 1.0)

	new hpbar = create_entity("info_target")
	g_illidan_hpbar = hpbar
	engfunc(EngFunc_SetModel, hpbar, g_illidanModels[2])
	set_pev(hpbar, pev_aiment, boss)
	set_pev(hpbar, pev_body, 1)
	set_pev(hpbar, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(hpbar, pev_classname, "boss_illidan_hpbar")
	set_pev(hpbar, pev_effects, EF_NODRAW)
	set_pev(hpbar, pev_scale, 0.3)

	set_task(7.0, "illidan_spawn_boss")
	set_task(0.5, "illidan_timer_think", TASK_ILLIDAN_TIMER, _, _, "b")
}

public illidan_spawn_boss()
{
	server_print("[IllidanBoss] illidan_spawn_boss called � illidanround:%d boss_ent:%d valid:%d", g_illidanround, g_illidan_boss, pev_valid(g_illidan_boss))
	if(!g_illidanround || !pev_valid(g_illidan_boss)) return

	new alive = illidan_alive_count()
	if(alive < 1) alive = 1
	new Float:hp = float(ILLIDAN_BASE_HP * alive)

	set_pev(g_illidan_boss, pev_health, hp)
	set_pev(g_illidan_boss, pev_max_health, hp)
	set_pev(g_illidan_boss, pev_deadflag, DEAD_NO)
	set_pev(g_illidan_boss, pev_takedamage, DAMAGE_YES)
	set_pev(g_illidan_boss, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(g_illidan_boss, pev_nextthink, get_gametime() + 0.5)

	set_pev(g_illidan_hpbar, pev_effects, pev(g_illidan_hpbar, pev_effects) & ~EF_NODRAW)
	set_pev(g_illidan_hpbar, pev_nextthink, get_gametime() + 0.2)

	g_illidan_ability_time = get_gametime() + ILLIDAN_BLITZ_INTERVAL
	g_illidan_spawned = true

	set_hudmessage(255, 80, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 4.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "BOSS HP: %d | Fase 1 - Detenlo!", floatround(hp))
	// No extra sound here - "You are not prepared!" already played at round start
}

// Keep lights bright + NVG for all players during Illidan round
public illidan_refresh_lights()
{
	if(!g_illidanround) return
	set_lights("z")
	for(new _i = 1; _i <= g_maxplayers; _i++)
	{
		if(!g_is_connected[_i] || !g_is_alive[_i]) continue
		message_begin(MSG_ONE, g_msgFlashlight, _, _i)
		write_byte(1)
		write_byte(100)
		message_end()
	}
}

// Called every 0.5s: periodic blitz trigger
public illidan_timer_think()
{
	if(!g_illidanround || !g_illidan_spawned) return
	if(!pev_valid(g_illidan_boss)) return
	if(pev(g_illidan_boss, pev_deadflag) != DEAD_NO) return

	if(g_illidan_phase == 1 && g_illidan_ability == 0)
	{
		if(g_illidan_ability_time != 0.0 && g_illidan_ability_time <= get_gametime())
		{
			g_illidan_ability = 2
			g_illidan_ability_time = get_gametime() + ILLIDAN_BLITZ_INTERVAL
		}
	}
}

// Respawn dead players as humans during boss round
public illidan_respawn_human(taskid)
{
	new id = taskid - TASK_SPAWN
	if(!g_illidanround || !g_is_connected[id] || g_is_alive[id] || g_endround) return

	g_respawn_as_zombie[id] = false
	fm_set_user_team(id, ZP_TEAM_CT)
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

/*-------------------------------------------------------
  Boss Main AI Think
-------------------------------------------------------*/
public think_illidan_boss(boss)
{
	if(!pev_valid(boss) || !g_illidanround) return
	if(pev(boss, pev_deadflag) != DEAD_NO) return

	switch(g_illidan_ability)
	{
		case 0: // RUN toward nearest player
		{
			// Ensure correct movetype for walking (may have been TOSS after elemental descent)
			if(pev(boss, pev_movetype) != MOVETYPE_PUSHSTEP)
			{
				set_pev(boss, pev_movetype, MOVETYPE_PUSHSTEP)
				set_pev(boss, pev_solid, SOLID_BBOX)
			}

			static victim
			victim = pev(boss, pev_euser2)

			if(!is_user_alive(victim))
			{
				victim = illidan_choose_player(boss, 0)
				set_pev(boss, pev_euser2, victim)
				set_pev(boss, pev_nextthink, get_gametime() + 0.1)
				return
			}

			if(pev(boss, pev_sequence) != 2) illidan_anim(boss, 2, 1.0)

			static Float:vel[3], Float:ang[3]
			illidan_move(boss, victim, float((g_illidan_phase == 3) ? ILLIDAN_SPEED_P3 : ILLIDAN_SPEED_P1), vel, ang)

			set_pev(boss, pev_velocity, vel)
			set_pev(boss, pev_angles, ang)
			set_pev(boss, pev_nextthink, get_gametime() + 0.1)
		}
		case 1: // MELEE ATTACK
		{
			static num_melee
			switch(num_melee)
			{
				case 0:
				{
					illidan_anim(boss, 8, 1.0)
					PlaySound(g_illidanSounds[0])
					set_pev(boss, pev_nextthink, get_gametime() + 0.5)
					num_melee++
				}
				case 1:
				{
					static victim; victim = pev(boss, pev_euser2)
					set_pev(boss, pev_euser2, 0)
					num_melee = 0

					if(!is_user_alive(victim))
					{
						set_pev(boss, pev_nextthink, get_gametime() + 0.1)
						g_illidan_ability = 0
						return
					}

					if(entity_range(victim, boss) < 180)
					{
						if(g_illidan_phase < 3)
						{
							illidan_damage_player(victim, ILLIDAN_DAMAGE_MELEE)
							illidan_screenfade(victim, 1, 1, {0, 50, 0}, 50)
							illidan_screenshake(victim, 15, 3)
						}
						else
						{
							if(is_user_alive(victim))
								ExecuteHamB(Ham_Killed, victim, victim, 2)
						}
					}

					illidan_spawn_attack_visual(3)
					set_pev(boss, pev_nextthink, get_gametime() + 1.6)
					g_illidan_ability = 0
				}
			}
		}
		case 2: // BLITZ ATTACK (arrow dash)
		{
			static num_blitz
			static Float:bs[3], Float:be[3]
			static ent_marker

			switch(num_blitz)
			{
				case 0:
				{
					new id = illidan_choose_player(boss, 2)
					if(!is_user_alive(id))
					{
						g_illidan_ability = 0
						set_pev(boss, pev_nextthink, get_gametime() + 0.1)
						return
					}

					static Float:orig[3], Float:end[3]
					pev(id, pev_origin, orig)

					ent_marker = create_entity("info_target")
					engfunc(EngFunc_SetModel, ent_marker, g_illidanModels[4])

					orig[2] += 300.0
					end[0] = orig[0]; end[1] = orig[1]; end[2] = orig[2] - 600.0
					new tr
					engfunc(EngFunc_TraceLine, orig, end, IGNORE_MONSTERS, ent_marker, tr)
					get_tr2(tr, TR_vecEndPos, end)
					end[2] += 1.0
					engfunc(EngFunc_SetOrigin, ent_marker, end)

					static Float:yaw
					yaw = random_float(-180.0, 180.0)
					static Float:a[3]
					a[0] = 0.0; a[1] = yaw; a[2] = 0.0
					set_pev(boss, pev_angles, a)
					a[0] = 90.0; a[1] += 90.0
					set_pev(ent_marker, pev_angles, a)

					static Float:fwd[3]
					pev(boss, pev_angles, a)
					angle_vector(a, ANGLEVECTOR_FORWARD, fwd)
					bs[0] = end[0] - fwd[0] * 285.0
					bs[1] = end[1] - fwd[1] * 285.0
					bs[2] = end[2] + ILLIDAN_BOSS_Z - 1.0
					be[0] = end[0] + fwd[0] * 285.0
					be[1] = end[1] + fwd[1] * 285.0
					be[2] = end[2] + ILLIDAN_BOSS_Z - 1.0

					set_pev(boss, pev_effects, EF_NODRAW)
					set_pev(g_illidan_hpbar, pev_effects, EF_NODRAW)
					set_pev(boss, pev_movetype, MOVETYPE_NOCLIP)
					set_pev(boss, pev_solid, SOLID_NOT)
					PlaySound(g_illidanSounds[4])

					for(new i = 1; i <= g_maxplayers; i++)
					{
						if(!is_user_alive(i)) continue
						static Float:op[3], Float:v[3]
						pev(i, pev_origin, op)
						xs_vec_sub(bs, op, v)
						xs_vec_normalize(v, v)
						xs_vec_mul_scalar(v, 1000.0, v)
						v[2] = 250.0
						set_pev(i, pev_velocity, v)
						illidan_screenfade(i, 2, 1, {0, 0, 0}, 255)
					}

					set_pev(boss, pev_nextthink, get_gametime() + 3.0)
					num_blitz++
				}
				case 1:
				{
					engfunc(EngFunc_SetOrigin, boss, bs)
					set_pev(g_illidan_hpbar, pev_effects, pev(g_illidan_hpbar, pev_effects) & ~EF_NODRAW)
					set_pev(boss, pev_effects, pev(boss, pev_effects) & ~EF_NODRAW)
					engfunc(EngFunc_SetModel, ent_marker, g_illidanModels[5])
					illidan_anim(boss, 10, 1.2)
					set_pev(boss, pev_nextthink, get_gametime() + 0.5)
					num_blitz++
				}
				case 2:
				{
					static Float:va[3]
					xs_vec_sub(be, bs, va)
					xs_vec_normalize(va, va)
					xs_vec_mul_scalar(va, 1000.0, va)
					set_pev(boss, pev_velocity, va)
					set_pev(boss, pev_nextthink, get_gametime() + 0.3)
					PlaySound(g_illidanSounds[1])
					num_blitz++
				}
				case 3:
				{
					illidan_blitz_trace_kill(bs, be)
					set_pev(boss, pev_nextthink, get_gametime() + 0.2)
					num_blitz++
				}
				case 4:
				{
					set_pev(boss, pev_velocity, {0.0, 0.0, 0.0})
					set_pev(boss, pev_nextthink, get_gametime() + 1.0)
					num_blitz++
				}
				case 5:
				{
					if(pev_valid(ent_marker))
						set_pev(ent_marker, pev_flags, pev(ent_marker, pev_flags) | FL_KILLME)
					set_pev(boss, pev_solid, SOLID_BBOX)
					bs[0]=0.0;bs[1]=0.0;bs[2]=0.0
					be[0]=0.0;be[1]=0.0;be[2]=0.0
					num_blitz = 0
					g_illidan_ability = 3  // chain into roll
					set_pev(boss, pev_nextthink, get_gametime() + 1.0)
				}
			}
		}
		case 3: // ROLL/SCROLL DASH
		{
			static num_roll
			switch(num_roll)
			{
				case 0:
				{
					set_pev(boss, pev_movetype, MOVETYPE_FLY)
					set_pev(boss, pev_solid, SOLID_NOT)

					new victim = illidan_choose_player(boss, 2)
					if(!is_user_alive(victim))
					{
						set_pev(boss, pev_nextthink, get_gametime() + 0.1)
						return
					}

					static Float:ov[3], Float:ev[3]
					pev(victim, pev_origin, ov)
					ov[2] += 300.0
					ev[0]=ov[0];ev[1]=ov[1];ev[2]=ov[2]-600.0
					new tr
					engfunc(EngFunc_TraceLine, ov, ev, IGNORE_MONSTERS, -1, tr)
					get_tr2(tr, TR_vecEndPos, ev)
					ev[2] += ILLIDAN_BOSS_Z + 1.0
					engfunc(EngFunc_SetOrigin, boss, ev)

					illidan_anim(boss, 11, 1.0)
					PlaySound(g_illidanSounds[8])
					set_pev(boss, pev_nextthink, get_gametime() + 0.8)
					num_roll++
				}
				case 1:
				{
					for(new i = 1; i <= g_maxplayers; i++)
					{
						if(!is_user_alive(i)) continue
						if(entity_range(i, boss) < 180)
						{
							if(g_illidan_phase < 3)
							{
								illidan_damage_player(i, ILLIDAN_DAMAGE_ROLL)
								illidan_screenfade(i, 1, 1, {0, 50, 0}, 50)
								illidan_screenshake(i, 15, 3)
							}
							else
							{
								ExecuteHamB(Ham_Killed, i, i, 2)
							}
						}
					}
					illidan_spawn_attack_visual(6)
					set_pev(boss, pev_nextthink, get_gametime() + 1.0)
					num_roll++
				}
				case 2:
				{
					set_pev(boss, pev_solid, SOLID_BBOX)
					set_pev(boss, pev_nextthink, get_gametime() + 1.0)
					num_roll = 0
					g_illidan_ability = 0
				}
			}
		}
		case 4: // ELEMENTAL PHASE (Phase 2 transition)
		{
			static num_elem
			switch(num_elem)
			{
				case 0:
				{
					set_pev(boss, pev_movetype, MOVETYPE_PUSHSTEP)
					set_pev(boss, pev_solid, SOLID_BBOX)
					illidan_anim(boss, 1, 1.0)
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
					num_elem++
				}
				case 1: // walk back to origin
				{
					static Float:o_boss[3], Float:v[3], Float:ang[3], Float:len
					pev(boss, pev_origin, o_boss)
					xs_vec_sub(g_illidan_origin, o_boss, v)
					vector_to_angle(v, ang)
					len = xs_vec_len(v)
					xs_vec_normalize(v, v)
					xs_vec_mul_scalar(v, float(ILLIDAN_SPEED_P1), v)
					set_pev(boss, pev_velocity, v)
					ang[0] = 0.0; ang[2] = 0.0
					set_pev(boss, pev_angles, ang)
					if(pev(boss, pev_sequence) != 2) illidan_anim(boss, 2, 1.0)
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
					if(len < 100)
					{
						set_pev(boss, pev_velocity, {0.0, 0.0, 0.0})
						set_pev(boss, pev_movetype, MOVETYPE_FLY)
						illidan_anim(boss, 1, 1.0)
						num_elem++
					}
				}
				case 2:
				{
					illidan_anim(boss, 4, 1.0)
					set_pev(boss, pev_nextthink, get_gametime() + 0.3)
					num_elem++
				}
				case 3:
				{
					PlaySound(g_illidanSounds[6])
					set_pev(boss, pev_takedamage, DAMAGE_NO)
					set_pev(boss, pev_velocity, {0.0, 0.0, 850.0})
					set_pev(boss, pev_nextthink, get_gametime() + 0.4)
					num_elem++
				}
				case 4:
				{
					illidan_anim(boss, 5, 1.0)
					set_pev(boss, pev_body, 0)
					set_pev(boss, pev_velocity, {0.0, 0.0, 0.0})
					set_pev(boss, pev_nextthink, get_gametime() + 1.0)
					num_elem++
				}
				case 5: // spawn blades + elementals (boss pauses here until blades die)
				{
					new alive = illidan_alive_count()
					if(alive < 1) alive = 1
					new hp_blade = (ILLIDAN_BASE_HP * alive) / ILLIDAN_ELEM_HP_DIV
					if(hp_blade < 100) hp_blade = 100

					g_illidan_elem_victim[0] = 0
					g_illidan_elem_victim[1] = 0

					for(new i = 0; i < 2; i++)
					{
						new blade = create_entity("info_target")
						g_illidan_blade[i] = blade
						engfunc(EngFunc_SetModel, blade, g_illidanModels[1])
						engfunc(EngFunc_SetSize, blade, {-32.0,-5.0,-42.0}, {5.0,5.0,42.0})
						set_pev(blade, pev_classname, "illidan_blade")
						set_pev(blade, pev_health, float(hp_blade))
						set_pev(blade, pev_max_health, float(hp_blade))
						set_pev(blade, pev_takedamage, DAMAGE_YES)
						set_pev(blade, pev_movetype, MOVETYPE_FLY)
						set_pev(blade, pev_solid, SOLID_BBOX)
						set_pev(blade, pev_angles, {90.0, 0.0, 0.0})

						new ent_elem = create_entity("info_target")
						g_illidan_elem[i] = ent_elem
						engfunc(EngFunc_SetSize, ent_elem, {-32.0,-32.0,-42.0}, {32.0,32.0,62.0})
						set_pev(ent_elem, pev_movetype, MOVETYPE_PUSHSTEP)
						set_pev(ent_elem, pev_solid, SOLID_NOT)
						set_pev(ent_elem, pev_takedamage, DAMAGE_NO)
						set_pev(ent_elem, pev_classname, "boss_illidan_elem")
						set_pev(ent_elem, pev_nextthink, get_gametime() + 1.0)

						new hp_bar = create_entity("info_target")
						g_illidan_elem_hp[i] = hp_bar
						engfunc(EngFunc_SetModel, hp_bar, g_illidanModels[12])
						set_pev(hp_bar, pev_movetype, MOVETYPE_FOLLOW)
						set_pev(hp_bar, pev_aiment, blade)
						set_pev(hp_bar, pev_classname, "boss_blade_hpbar")
						set_pev(hp_bar, pev_scale, 0.5)
						set_pev(hp_bar, pev_nextthink, get_gametime() + 0.2)

						new fix_lp = 0
						while(g_illidan_elem_victim[i] == 0 && fix_lp < 20)
						{
							fix_lp++
							new v = illidan_choose_player(ent_elem, 2)
							if(v != 0 && (i == 0 || v != g_illidan_elem_victim[0] || fix_lp >= 10))
								g_illidan_elem_victim[i] = v
						}
						if(g_illidan_elem_victim[i] == 0 && g_illidan_elem_victim[0] != 0)
							g_illidan_elem_victim[i] = g_illidan_elem_victim[0]
					}

					engfunc(EngFunc_SetOrigin, g_illidan_elem_hp[0], {-204.755142, 284.222656, 126.031250})
					engfunc(EngFunc_SetOrigin, g_illidan_elem_hp[1], {172.372299, 268.844909, 126.031250})
					engfunc(EngFunc_SetOrigin, g_illidan_blade[0], {-204.755142, 284.222656, 36.031250})
					engfunc(EngFunc_SetOrigin, g_illidan_blade[1], {172.372299, 268.844909, 36.031250})

					num_elem++
					// NO pev_nextthink set � boss pauses until both blades are killed
				}
				case 6: // blades killed, boss descends into Phase 3
				{
					set_pev(boss, pev_solid, SOLID_BBOX)
					set_pev(boss, pev_movetype, MOVETYPE_TOSS)
					illidan_anim(boss, 6, 0.8)
					set_pev(boss, pev_nextthink, get_gametime() + 2.0)
					num_elem++
				}
				case 7: // demon form
				{
					set_pev(boss, pev_takedamage, DAMAGE_YES)
					set_pev(boss, pev_body, 7)
					static Float:max_hp
					pev(boss, pev_max_health, max_hp)
					set_pev(boss, pev_health, max_hp * 0.5)
					g_illidan_phase = 3
					g_illidan_ability = 0
					num_elem = 0
					PlaySound(g_illidanSounds[7])
					set_hudmessage(255, 0, 80, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 4.0, 1.0, 1.0, -1)
					ShowSyncHudMsg(0, g_MsgSync, ">>> FORMA DEMONIO <<<")
					zp_colored_print(0, "^4[BOSS] ^3Illidan ^1ha tomado su forma demoniaca! Velocidad y da�o aumentados!")
					set_pev(boss, pev_nextthink, get_gametime() + 0.5)
				}
			}
		}
	}
}

/*-------------------------------------------------------
  Boss HP Bar Think � monitors HP, triggers phase change
-------------------------------------------------------*/
public think_illidan_hpbar(e)
{
	if(!pev_valid(e)) return

	if(!pev_valid(g_illidan_boss) || pev(g_illidan_boss, pev_deadflag) == DEAD_DYING)
	{
		set_pev(e, pev_flags, pev(e, pev_flags) | FL_KILLME)
		return
	}

	static Float:hp_c, Float:hp_m, Float:pct
	pev(g_illidan_boss, pev_max_health, hp_m)
	pev(g_illidan_boss, pev_health, hp_c)
	if(hp_m <= 0.0) { set_pev(e, pev_nextthink, get_gametime() + 0.1); return; }
	pct = hp_c * 100.0 / hp_m

	set_pev(e, pev_frame, 100.0 - pct)

	// Phase 1 ? Phase 2 at 50% HP
	if(g_illidan_phase == 1 && pct <= 50.0 && g_illidan_ability == 0)
	{
		g_illidan_phase = 2
		g_illidan_ability = 4
		// Sound plays when boss actually flies up (elem_fly_start in ability 4 case 3)
		set_hudmessage(255, 128, 0, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 4.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, ">>> FASE 2: ELEMENTALES <<<")
		zp_colored_print(0, "^4[BOSS] ^3Illidan ^1invoca sus elementales! Destruid las espadas!")
	}

	set_pev(e, pev_nextthink, get_gametime() + 0.1)
}

/*-------------------------------------------------------
  Attack visual (fading model)
-------------------------------------------------------*/
public think_illidan_attack_visual(ent)
{
	if(!pev_valid(ent)) return
	static a
	a = pev(ent, pev_button)
	if(a > 15)
	{
		static Float:b; b = 240.0 / 30.0
		a = a - floatround(b)
		set_pev(ent, pev_button, a)
		set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, a)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	}
	else
	{
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
	}
}

/*-------------------------------------------------------
  Boss Touch � triggers melee when physically colliding
-------------------------------------------------------*/
public touch_illidan_boss(boss, entity)
{
	if(pev(boss, pev_deadflag) != DEAD_NO) return
	if(pev(boss, pev_sequence) != 2) return  // only while running

	if(g_illidan_ability == 4 && is_user_alive(entity))
	{
		ExecuteHamB(Ham_Killed, entity, entity, 2)
		return
	}

	if((g_illidan_ability == 0) && is_user_alive(entity))
	{
		g_illidan_ability = 1
		set_pev(boss, pev_euser2, entity)
	}
}

/*-------------------------------------------------------
  Elemental Think
-------------------------------------------------------*/
public think_illidan_elem(elem)
{
	if(!pev_valid(elem) || !g_illidanround) return
	if(pev(elem, pev_flags) & FL_KILLME) return  // already dying

	new idx = (elem == g_illidan_elem[0]) ? 0 : (elem == g_illidan_elem[1]) ? 1 : -1
	if(idx == -1) return  // orphaned entity

	static Float:time_laser_update[2]
	static num0, num1  // sub-state per elem index

	new num
	if(idx == 0) num = num0
	else num = num1

	switch(num)
	{
		case 0:
		{
			static Float:os[3]
			pev(g_illidan_elem_victim[idx], pev_origin, os)
			illidan_shockwave(os, 10, 200, 200.0, {0, 255, 0})
			engfunc(EngFunc_SetOrigin, elem, os)
			engfunc(EngFunc_SetModel, elem, g_illidanModels[7])
			illidan_anim(elem, 1, 1.0)

			for(new i = 1; i <= g_maxplayers; i++)
			{
				if(!is_user_alive(i)) continue
				if(entity_range(i, elem) < 200)
				{
					illidan_damage_player(i, ILLIDAN_ELEM_SPAWN_DMG)
					illidan_screenfade(i, 1, 1, {0, 50, 0}, 50)
					illidan_screenshake(i, 15, 3)
				}
			}

			set_pev(elem, pev_nextthink, get_gametime() + 0.1)
			num++
		}
		case 1:
		{
			set_pev(elem, pev_movetype, MOVETYPE_PUSHSTEP)
			set_pev(elem, pev_solid, SOLID_BBOX)
			illidan_laser(elem, g_illidan_blade[idx], {0, 255, 0})
			set_pev(elem, pev_nextthink, get_gametime() + 4.3)
			num++
		}
		case 2: // chase / shoot behavior
		{
			if(pev(elem, pev_deadflag) == DEAD_DYING)
			{
				illidan_anim(elem, 13, 1.0)
				set_pev(elem, pev_nextthink, get_gametime() + 3.0)
				num = 4
			}
			else if(idx == 0) // melee elem: chase and kill
			{
				static victim1
				victim1 = illidan_choose_player(elem, 0)
				if(!is_user_alive(victim1)) { set_pev(elem, pev_nextthink, get_gametime() + 0.1); }
				else
				{
					static Float:vel2[3], Float:ang2[3], Float:len2
					len2 = illidan_move(elem, victim1, float(ILLIDAN_ELEM_SPEED), vel2, ang2)
					set_pev(elem, pev_velocity, vel2)
					set_pev(elem, pev_angles, ang2)
					set_pev(elem, pev_nextthink, get_gametime() + 0.1)
					if(len2 < 50)
					{
						illidan_anim(elem, 10, 1.0)
						set_pev(elem, pev_velocity, {0.0, 0.0, 0.0})
						set_pev(elem, pev_nextthink, get_gametime() + 1.5)
						num++
					}
				}
			}
			else // ranged elem: shoot balls
			{
				illidan_anim(elem, 9, 0.4)
				new victim2 = illidan_choose_player(elem, 2)
				if(!is_user_alive(victim2)) { set_pev(elem, pev_nextthink, get_gametime() + 0.1); }
				else
				{
					static Float:ball_from[3], Float:ball_to[3], Float:ball_ang[3], Float:ball_v[3]
					illidan_get_forward_pos(elem, 100.0, 80.0, ball_from)
					pev(victim2, pev_origin, ball_to)
					ball_to[2] -= 30.0
					xs_vec_sub(ball_to, ball_from, ball_v)
					vector_to_angle(ball_v, ball_ang)
					ball_ang[0] = 0.0; ball_ang[2] = 0.0
					set_pev(elem, pev_angles, ball_ang)
					xs_vec_normalize(ball_v, ball_v)
					xs_vec_mul_scalar(ball_v, 800.0, ball_v)

					new ball = create_entity("info_target")
					engfunc(EngFunc_SetModel, ball, g_illidanModels[10])
					set_pev(ball, pev_solid, SOLID_TRIGGER)
					set_pev(ball, pev_movetype, MOVETYPE_FLY)
					illidan_anim(ball, 1, 0.5)
					engfunc(EngFunc_SetOrigin, ball, ball_from)
					set_pev(ball, pev_velocity, ball_v)
					set_pev(ball, pev_classname, "boss_illidan_ball")

					set_pev(elem, pev_nextthink, get_gametime() + 0.8)
				}
			}
		}
		case 3: // melee elem kill strike
		{
			static victim_saved
			victim_saved = illidan_choose_player(elem, 0)
			if(entity_range(elem, victim_saved) < 180 && is_user_alive(victim_saved))
				ExecuteHamB(Ham_Killed, victim_saved, victim_saved, 2)
			set_pev(elem, pev_nextthink, get_gametime() + 1.0)
			num--
		}
		case 4: // death animation done � remove
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_KILLBEAM)
			write_short(elem)
			message_end()
			set_pev(elem, pev_flags, pev(elem, pev_flags) | FL_KILLME)
			g_illidan_elem[idx] = -1  // mark dead immediately

			if(pev_valid(g_illidan_blade[idx]))
				set_pev(g_illidan_blade[idx], pev_flags, pev(g_illidan_blade[idx], pev_flags) | FL_KILLME)
			g_illidan_blade[idx] = -1

			new other = idx ^ 1
			// Both elems dead ? resume boss to Phase 3
			if(g_illidan_elem[other] <= 0 && g_illidan_elem[idx] <= 0)
				set_pev(g_illidan_boss, pev_nextthink, get_gametime() + 1.5)

			num = 0
		}
	}

	// Update laser periodically
	if(pev_valid(elem))
	{
		if(time_laser_update[idx] < get_gametime())
		{
			if(pev_valid(g_illidan_blade[idx]))
				illidan_laser(elem, g_illidan_blade[idx], {0, 255, 0})
			time_laser_update[idx] = get_gametime() + 13.0
		}
	}

	if(idx == 0) num0 = num
	else num1 = num
}

/*-------------------------------------------------------
  Ball Touch
-------------------------------------------------------*/
public touch_illidan_ball(ball, ent)
{
	if(is_user_alive(ent))
	{
		ExecuteHamB(Ham_Killed, ent, ent, 2)
	}
	else
	{
		static Float:origin[3]
		pev(ball, pev_origin, origin)
		illidan_shockwave(origin, 10, 200, 150.0, {0, 255, 0})
		for(new i = 1; i <= g_maxplayers; i++)
		{
			if(!is_user_alive(i)) continue
			if(entity_range(ball, i) < 180)
			{
				illidan_damage_player(i, ILLIDAN_ELEM_SPLASH_DMG)
				illidan_screenfade(i, 1, 1, {0, 50, 0}, 50)
				illidan_screenshake(i, 15, 3)
			}
		}

		static Float:end[3]
		origin[2] += 300.0
		end[0]=origin[0]; end[1]=origin[1]; end[2]=origin[2]-600.0
		new tr
		engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, -1, tr)
		get_tr2(tr, TR_vecEndPos, end)
		end[2] += 1.0

		new splash = create_entity("info_target")
		engfunc(EngFunc_SetModel, splash, g_illidanModels[11])
		engfunc(EngFunc_SetOrigin, splash, end)
		set_pev(splash, pev_classname, "boss_illidan_splash")
		set_pev(splash, pev_nextthink, get_gametime() + 0.2)
	}
	set_pev(ball, pev_flags, pev(ball, pev_flags) | FL_KILLME)
}

public think_illidan_splash(splash)
{
	if(!pev_valid(splash)) return
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!is_user_alive(i)) continue
		if(entity_range(splash, i) < 250)
		{
			illidan_damage_player(i, ILLIDAN_ELEM_SPLASH_DMG)
			illidan_screenfade(i, 1, 1, {0, 50, 0}, 50)
		}
	}
	set_pev(splash, pev_nextthink, get_gametime() + 0.2)
}

/*-------------------------------------------------------
  Blade HP Bar Think
-------------------------------------------------------*/
public think_illidan_blade_hpbar(e)
{
	static Float:hp_c, Float:hp_m, Float:pct
	new idx = (e == g_illidan_elem_hp[0]) ? 0 : 1
	if(!pev_valid(g_illidan_blade[idx]))
	{
		set_pev(e, pev_flags, pev(e, pev_flags) | FL_KILLME)
		return
	}
	pev(g_illidan_blade[idx], pev_max_health, hp_m)
	pev(g_illidan_blade[idx], pev_health, hp_c)
	if(hp_m <= 0.0) { set_pev(e, pev_flags, pev(e, pev_flags) | FL_KILLME); return; }
	pct = 100.0 - hp_c * 100.0 / hp_m
	if(pct > 100.0) { set_pev(e, pev_flags, pev(e, pev_flags) | FL_KILLME); return; }
	set_pev(e, pev_frame, pct)
	set_pev(e, pev_nextthink, get_gametime() + 0.1)
}

/*-------------------------------------------------------
  HAM hooks � damage tracking, blade/boss death
-------------------------------------------------------*/
public fw_illidan_take_damage(ent, inflictor, attacker, Float:damage, damagetype)
{
	if(!g_illidanround) return HAM_IGNORED
	static szClass[32]
	pev(ent, pev_classname, szClass, charsmax(szClass))
	if(!equal(szClass, "boss_illidan")) return HAM_IGNORED
	if(!is_user_valid_connected(attacker)) return HAM_IGNORED

	new Float:prev = g_illidan_damage[attacker]
	g_illidan_damage[attacker] += damage

	// Blood + spark effect at hit location
	static Float:boss_pos[3]
	pev(ent, pev_origin, boss_pos)
	boss_pos[2] += 40.0
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, boss_pos[0])
	engfunc(EngFunc_WriteCoord, boss_pos[1])
	engfunc(EngFunc_WriteCoord, boss_pos[2])
	message_end()

	// Show HP to attacker via HUD
	static Float:hp_c, Float:hp_m
	pev(ent, pev_health, hp_c)
	pev(ent, pev_max_health, hp_m)
	if(hp_m > 0.0)
	{
		new pct = floatround(hp_c * 100.0 / hp_m)
		set_hudmessage(255, 80, 0, -1.0, 0.07, 0, 0.0, 1.5, 0.0, 0.0, -1)
		ShowSyncHudMsg(attacker, g_MsgSync4, "BOSS HP: %d%% | %.0f/%.0f", pct, hp_c, hp_m)
	}

	// Give 1 AP per 100 damage milestone
	new ap_prev = floatround(prev / 100.0, floatround_floor)
	new ap_now  = floatround(g_illidan_damage[attacker] / 100.0, floatround_floor)
	if(ap_now > ap_prev)
	{
		new gained = (ap_now - ap_prev) * ILLIDAN_AP_PER_100_DMG
		g_ammopacks[attacker] += gained
		check_player_level(attacker)
		zp_colored_print(attacker, "^4[BOSS] ^3+%d AP ^1por %d de da�o al boss!", gained, floatround(g_illidan_damage[attacker]))
	}

	return HAM_IGNORED
}

public fw_illidan_trace_attack(v, attacker, Float:dmg, Float:dir[3], tr, dt)
{
	if(!g_illidanround) return HAM_IGNORED
	static szClass[32]
	pev(v, pev_classname, szClass, charsmax(szClass))
	if(!equal(szClass, "illidan_blade")) return HAM_IGNORED
	// Show sparks on blade hit
	static Float:tr_end[3]
	get_tr2(tr, TR_vecEndPos, tr_end)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, tr_end[0])
	engfunc(EngFunc_WriteCoord, tr_end[1])
	engfunc(EngFunc_WriteCoord, tr_end[2])
	message_end()
	return HAM_IGNORED
}

public fw_illidan_entity_killed(v, a, c)
{
	if(!g_illidanround) return HAM_IGNORED
	static szClass[32]
	pev(v, pev_classname, szClass, charsmax(szClass))

	if(equal(szClass, "boss_illidan"))
	{
		illidan_boss_killed()
		return HAM_SUPERCEDE
	}
	if(equal(szClass, "illidan_blade"))
	{
		set_pev(v, pev_solid, SOLID_NOT)
		if(v == g_illidan_blade[0] && pev_valid(g_illidan_elem[0]))
			set_pev(g_illidan_elem[0], pev_deadflag, DEAD_DYING)
		if(v == g_illidan_blade[1] && pev_valid(g_illidan_elem[1]))
			set_pev(g_illidan_elem[1], pev_deadflag, DEAD_DYING)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

/*-------------------------------------------------------
  Boss Death � rewards and round end
-------------------------------------------------------*/
illidan_boss_killed()
{
	if(!g_illidanround) return
	g_illidanround = false   // guard against double-call immediately

	PlaySound(g_illidanSounds[3])
	set_hudmessage(0, 255, 100, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 6.0, 2.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "ILLIDAN HA CAIDO!")
	zp_colored_print(0, "^4[BOSS] ^3Illidan^1 ha sido derrotado! Los humanos ganan!")

	// Find top damager
	new top_id = 0
	new Float:top_dmg = 0.0
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!g_is_connected[i]) continue
		if(g_illidan_damage[i] > top_dmg) { top_dmg = g_illidan_damage[i]; top_id = i; }
	}

	// AP rewards for all contributors
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!g_is_connected[i]) continue
		new ap_dmg = floatround(g_illidan_damage[i] / 100.0, floatround_floor)
		if(ap_dmg < 0) ap_dmg = 0
		new total = ap_dmg + ILLIDAN_AP_KILL_ALL
		g_ammopacks[i] += total
		check_player_level(i)
		if(total > 0)
			zp_colored_print(i, "^4[BOSS] ^3+%d AP^1 (da�o) ^3+%d AP^1 (bonus boss muerto)", ap_dmg, ILLIDAN_AP_KILL_ALL)
	}

	// Top damager bonus
	if(top_id > 0 && g_is_connected[top_id])
	{
		g_ammopacks[top_id] += ILLIDAN_AP_KILL_TOP
		check_player_level(top_id)
		zp_colored_print(top_id, "^4[BOSS] ^3+%d AP^1 bonus por mayor da�o! (%.0f dmg)", ILLIDAN_AP_KILL_TOP, top_dmg)
	}

	// Drop 5 reward boxes at boss location
	if(pev_valid(g_illidan_boss))
	{
		static Float:bo[3]
		pev(g_illidan_boss, pev_origin, bo)
		for(new i = 0; i < 5; i++)
		{
			new box = create_entity("info_target")
			entity_set_string(box, EV_SZ_classname, classname_powerbox)
			entity_set_model(box, model_powerbox)
			set_rendering(box, kRenderFxGlowShell, 255, 215, 0, kRenderNormal, 20)
			entity_set_vector(box, EV_VEC_mins, Float:{-1.5,-1.5,0.0})
			entity_set_vector(box, EV_VEC_maxs, Float:{1.5,1.5,4.5})
			entity_set_size(box, Float:{-1.5,-1.5,0.0}, Float:{1.5,1.5,4.5})
			entity_set_int(box, EV_INT_movetype, MOVETYPE_TOSS)
			entity_set_int(box, EV_INT_solid, SOLID_TRIGGER)
			entity_set_float(box, EV_FL_gravity, 0.77)
			static Float:scatter[3]
			scatter[0] = bo[0] + random_float(-60.0, 60.0)
			scatter[1] = bo[1] + random_float(-60.0, 60.0)
			scatter[2] = bo[2] + 40.0
			entity_set_origin(box, scatter)
		}
	}

	// Visually kill the boss entity
	if(pev_valid(g_illidan_boss))
	{
		set_pev(g_illidan_boss, pev_deadflag, DEAD_DYING)
		set_pev(g_illidan_boss, pev_effects, EF_NODRAW)
		set_pev(g_illidan_boss, pev_takedamage, DAMAGE_NO)
	}

	remove_task(TASK_ILLIDAN_TIMER)
	remove_task(TASK_ILLIDAN_TIMER + 1)  // lights refresh task
	set_lights("a")  // restore normal lighting

	g_scorehumans++
	team_win = 2
	set_task(4.0, "illidan_end_round")
}

public illidan_end_round()
{
	if(g_endround) return  // round already ended
	static mapname[32]
	get_mapname(mapname, charsmax(mapname))
	if(!equal(mapname, ILLIDAN_MAP)) return  // map already changed
	set_round_end(0)
}

public force_end_round(humans_win)
{
    new players[32], num
    get_players(players, num, "a")

    for (new i = 0; i < num; i++)
    {
        new id = players[i]

        if (!is_user_alive(id))
            continue

        if (humans_win)
        {
            if (cs_get_user_team(id) == CS_TEAM_T)
                user_kill(id, 1)
        }
        else
        {
            if (cs_get_user_team(id) == CS_TEAM_CT)
                user_kill(id, 1)
        }
    }

    // Forzar restart del engine (clave)
    set_task(0.5, "force_engine_restart")
}

public force_engine_restart()
{
	// Reduce restart delay to 1s so new round starts quickly
	server_cmd("mp_roundrestartdelay 1")
	// Kill ALL alive players so CS fires Round_End and starts new round
	new deathmsg = get_msg_block(g_msgDeathMsg)
	set_msg_block(g_msgDeathMsg, BLOCK_SET)
	for(new _id = 1; _id <= g_maxplayers; _id++)
		if(g_is_alive[_id]) user_kill(_id, 1)
	set_msg_block(g_msgDeathMsg, deathmsg)
	// Restore normal delay after new round starts
	set_task(3.0, "ze_restore_restart_delay")
}

public ze_restore_restart_delay()
{
	server_cmd("mp_roundrestartdelay 5")
}

/*-------------------------------------------------------
  Helper stocks
-------------------------------------------------------*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
