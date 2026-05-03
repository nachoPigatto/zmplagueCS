================================================
  ZOMBIE EVIL SERVER - BACKUP COMPLETO
  Fecha: 2026-05-03
================================================

REQUISITOS BASE (instalar primero):
  - HLDS (Half-Life Dedicated Server) para CS 1.6
  - AMX Mod X 1.10.0 para Windows
  - Metamod 1.21.1-am

ESTRUCTURA - copiar sobre cstrike/:
  plugins/compiled/  -> cstrike/addons/amxmodx/plugins/
  plugins/source/    -> (guardar, para recompilar si hace falta)
  configs/           -> cstrike/addons/amxmodx/configs/
  configs/orpheu/    -> cstrike/addons/amxmodx/configs/orpheu/
  models/            -> cstrike/models/
  models/player/     -> cstrike/models/player/
  sound/oa_ze/       -> cstrike/sound/oa_ze/
  sprites/oa/        -> cstrike/sprites/oa/
  modules/           -> cstrike/addons/amxmodx/modules/
  maps/              -> cstrike/maps/

PLUGINS CUSTOM:
  - zombie_evil34.amxx   (plugin principal)
  - ze_bazooka.amxx      (bazooka del Nemesis - granada)
  - ze_gifts.amxx        (evento de regalos del owner)
  - ze_testbot.amxx      (bot de pruebas)

NOTAS:
  - orpheu_amxx.dll es OBLIGATORIO (memoria dinámica para CS 1.6)
  - El archivo users.ini contiene las cuentas de admin/owner
  - Para recompilar: usar plugins/source/*.sma con el compilador de AMXX 1.10

================================================
