
/*
VVVVVVVV           VVVVVVVV     OOOOOOOOO     RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEE
V::::::V           V::::::V   OO:::::::::OO   R::::::::::::::::R  E::::::::::::::::::::E
V::::::V           V::::::V OO:::::::::::::OO R::::::RRRRRR:::::R E::::::::::::::::::::E
V::::::V           V::::::VO:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEEE::::E
 V:::::V           V:::::V O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
  V:::::V         V:::::V  O:::::O     O:::::O  R::::R     R:::::R  E:::::E
   V:::::V       V:::::V   O:::::O     O:::::O  R::::RRRRRR:::::R   E::::::EEEEEEEEEE
    V:::::V     V:::::V    O:::::O     O:::::O  R:::::::::::::RR    E:::::::::::::::E
     V:::::V   V:::::V     O:::::O     O:::::O  R::::RRRRRR:::::R   E:::::::::::::::E
      V:::::V V:::::V      O:::::O     O:::::O  R::::R     R:::::R  E::::::EEEEEEEEEE
       V:::::V:::::V       O:::::O     O:::::O  R::::R     R:::::R  E:::::E
        V:::::::::V        O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
         V:::::::V         O:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEE:::::E
          V:::::V           OO:::::::::::::OO R::::::R     R:::::RE::::::::::::::::::::E
           V:::V              OO:::::::::OO   R::::::R     R:::::RE::::::::::::::::::::E
            VVV                 OOOOOOOOO     RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE

-Aro <3 */

#define VORE_VERSION	3	//This is a Define so you don't have to worry about magic numbers.

//
// Overrides/additions to stock defines go here, as well as hooks. Sort them by
// the object they are overriding. So all /mob/living together, etc.
//
/datum/configuration
	var/items_survive_digestion = TRUE	//For configuring if the important_items survive digestion

//
// The datum type bolted onto normal preferences datums for storing Virgo stuff
//
var/list/preferences_datums_vr = list()
/client
	var/datum/vore_preferences/prefs_vr

/datum/vore_preferences
	//Actual preferences
	var/digestable = TRUE
	var/devourable = TRUE
	var/absorbable = TRUE
	var/feeding = TRUE
	var/can_be_drop_prey = FALSE
	var/can_be_drop_pred = FALSE
	var/allow_spontaneous_tf = FALSE
	var/digest_leave_remains = FALSE
	var/allowmobvore = TRUE
	var/permit_healbelly = TRUE

	var/resizable = TRUE
	var/show_vore_fx = TRUE
	var/step_mechanics_pref = FALSE
	var/pickup_pref = TRUE

	var/list/belly_prefs = list()
	var/vore_taste = "nothing in particular"
	var/vore_smell = "nothing in particular"

	var/nif_type = null
	var/nif_health = 0
	var/list/nif_savedata = null
	var/died_with_nif = FALSE

	//Mechanically required
	var/path_vore
	var/path_nif
	var/slot
	var/client/client
	var/client_ckey

/datum/vore_preferences/New(client/C)
	if(istype(C))
		client = C
		client_ckey = C.ckey
		preload()
		load_vore()
		load_nif()

//
//	Check if an object is capable of eating things, based on vore_organs
//
/proc/is_vore_predator(mob/living/O)
	if(istype(O,/mob/living))
		if(O.vore_organs.len > 0)
			return TRUE

	return FALSE

//
//	Belly searching for simplifying other procs
//  Mostly redundant now with belly-objects and isbelly(loc)
//
/proc/check_belly(atom/movable/A)
	return isbelly(A.loc)

/datum/vore_preferences/proc/preload()
	if(!client || !client_ckey)
		return FALSE //No client, how can we save?
	if(!client.prefs || !client.prefs.default_slot)
		return FALSE //Need to know what character to load!

	slot = client.prefs.default_slot

	load_paths(client_ckey,slot)

/datum/vore_preferences/proc/load_paths(ckey, slot, filename="character", ext="json")
	if(!ckey || !slot)
		return
	path_vore = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/vore/[filename][slot].[ext]"
	path_nif = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/vore/[filename][slot]_nif.[ext]"

//
// Save/Load Vore Preferences
//
/datum/vore_preferences/proc/load_vore()
	if(!path_vore)
		return FALSE //Path couldn't be set?
	if(!rustg_file_exists(path_vore)) //Never saved before
		save_vore() //Make the file first
		return TRUE

	var/list/json_from_file = json_decode(rustg_file_read(path_vore))
	if(!json_from_file)
		return FALSE //My concern grows

	var/version = json_from_file["version"]
	json_from_file = patch_version(json_from_file,version)

	digestable = json_from_file["digestable"]
	devourable = json_from_file["devourable"]
	resizable = json_from_file["resizable"]
	feeding = json_from_file["feeding"]
	absorbable = json_from_file["absorbable"]
	digest_leave_remains = json_from_file["digest_leave_remains"]
	allowmobvore = json_from_file["allowmobvore"]
	vore_taste = json_from_file["vore_taste"]
	vore_smell = json_from_file["vore_smell"]
	permit_healbelly = json_from_file["permit_healbelly"]
	show_vore_fx = json_from_file["show_vore_fx"]
	can_be_drop_prey = json_from_file["can_be_drop_prey"]
	can_be_drop_pred = json_from_file["can_be_drop_pred"]
	allow_spontaneous_tf = json_from_file["allow_spontaneous_tf"]
	step_mechanics_pref = json_from_file["step_mechanics_pref"]
	pickup_pref = json_from_file["pickup_pref"]
	belly_prefs = json_from_file["belly_prefs"]

	//Quick sanitize
	if(isnull(digestable))
		digestable = TRUE
	if(isnull(devourable))
		devourable = TRUE
	if(isnull(resizable))
		resizable = TRUE
	if(isnull(feeding))
		feeding = TRUE
	if(isnull(absorbable))
		absorbable = TRUE
	if(isnull(digest_leave_remains))
		digest_leave_remains = FALSE
	if(isnull(allowmobvore))
		allowmobvore = TRUE
	if(isnull(permit_healbelly))
		permit_healbelly = TRUE
	if(isnull(show_vore_fx))
		show_vore_fx = TRUE
	if(isnull(can_be_drop_prey))
		can_be_drop_prey = FALSE
	if(isnull(can_be_drop_pred))
		can_be_drop_pred = FALSE
	if(isnull(allow_spontaneous_tf))
		allow_spontaneous_tf = FALSE
	if(isnull(step_mechanics_pref))
		step_mechanics_pref = TRUE
	if(isnull(pickup_pref))
		pickup_pref = TRUE
	if(isnull(belly_prefs))
		belly_prefs = list()

	return TRUE

/datum/vore_preferences/proc/save_vore()
	if(!path_vore)
		return FALSE

	var/version = VORE_VERSION	//For "good times" use in the future
	var/list/settings_list = list(
			"version"				= version,
			"digestable"			= digestable,
			"devourable"			= devourable,
			"resizable"				= resizable,
			"absorbable"			= absorbable,
			"feeding"				= feeding,
			"digest_leave_remains"	= digest_leave_remains,
			"allowmobvore"			= allowmobvore,
			"vore_taste"			= vore_taste,
			"vore_smell"			= vore_smell,
			"permit_healbelly"		= permit_healbelly,
			"show_vore_fx"			= show_vore_fx,
			"can_be_drop_prey"		= can_be_drop_prey,
			"can_be_drop_pred"		= can_be_drop_pred,
			"allow_spontaneous_tf"	= allow_spontaneous_tf,
			"step_mechanics_pref"	= step_mechanics_pref,
			"pickup_pref"			= pickup_pref,
			"belly_prefs"			= belly_prefs,
		)

	//List to JSON
	var/json_to_file = json_encode(settings_list)
	if(!json_to_file)
		log_debug("Saving: [path_vore] failed jsonencode")
		return FALSE

	//Write it out
	rustg_file_write(json_to_file, path_vore)

	if(!rustg_file_exists(path_vore))
		log_debug("Saving: [path_vore] failed file write")
		return FALSE

	return TRUE

//
// Save/Load NIF persistence
//
/datum/vore_preferences/proc/load_nif()
	if(!path_nif)
		return FALSE //Path couldn't be set?
	if(!rustg_file_exists(path_nif)) //Never saved before
		save_nif() //Make the file first
		return TRUE

	// Legacy conversion
	var/save_now = FALSE
	if(client?.prefs.legacy_nif_type)
		save_now = TRUE
		nif_type = client.prefs.legacy_nif_type
		nif_health = client.prefs.legacy_nif_dura
		nif_savedata = client.prefs.legacy_nif_savedata
		died_with_nif = FALSE

		client.prefs.legacy_nif_type = null
		client.prefs.legacy_nif_dura = null
		client.prefs.legacy_nif_savedata = null
		client.prefs.save_character()
	// Normal loading
	else
		var/list/json_from_file = json_decode(rustg_file_read(path_nif))
		if(!json_from_file)
			return FALSE //My concern grows

		var/version = json_from_file["version"]
		json_from_file = patch_version(json_from_file,version)

		nif_type = text2path(json_from_file["nif_type"])
		nif_health = json_from_file["nif_health"]
		nif_savedata = json_from_file["nif_savedata"]
		died_with_nif = json_from_file["died_with_nif"]
	
	//Quick sanitize
	if(!isnum(nif_health))
		nif_health = 0
	if(isnull(died_with_nif))
		died_with_nif = FALSE
	if(!isnull(resizable) || ispath(nif_type))
		nif_type = null
	if(!islist(nif_savedata))
		nif_savedata = list()

	if(save_now)
		save_nif()

	return TRUE

/datum/vore_preferences/proc/save_nif()
	if(!path_nif)
		return FALSE

	var/version = VORE_VERSION	//For "good times" use in the future
	var/list/settings_list = list(
			"version"				= version,
			"nif_type"				= "[nif_type]", // type to text
			"nif_health"			= nif_health,
			"nif_savedata"			= nif_savedata.Copy(),
			"died_with_nif"			= died_with_nif
		)

	//List to JSON
	var/json_to_file = json_encode(settings_list)
	if(!json_to_file)
		log_debug("Saving: [path_nif] failed jsonencode")
		return FALSE

	//Write it out
	rustg_file_write(json_to_file, path_nif)

	if(!fexists(path_nif))
		log_debug("Saving: [path_nif] failed file write")
		return FALSE

	return TRUE

//Can do conversions here
/datum/vore_preferences/proc/patch_version(var/list/json_from_file,var/version)
	return json_from_file
