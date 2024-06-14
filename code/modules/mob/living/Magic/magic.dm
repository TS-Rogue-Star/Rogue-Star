/mob/living
	var/datum/etching/etching

/mob/living/Initialize()
	. = ..()
	init_magic()

/mob/living/Login()
	. = ..()
	if(etching)
		etching.load()

/mob/living/Destroy()
	if(etching)
		var/datum/etching/E = etching
		E.save(TRUE)
	..()

/mob/living/Life()
	. = ..()
	process_magic()

/mob/living/proc/init_magic()
	if(ishuman(src) || isanimal(src))
		etching = new /datum/etching(src)

/mob/living/proc/process_magic()
	if(!etching)
		return
	var/datum/etching/E = etching
	if(E.mana < E.max_mana)
		E.mana += E.mana_regen
	if(E.mana_cooldown)
		E.mana_cooldown --

/datum/etching
	var/mob/living/ourmob			//Reference to the mob we are working with
	var/true_name					//Magic bs
	var/mana = 0					//How much you have
	var/max_mana = 0				//How much you could have
	var/mana_regen = 0				//How fast it comes back
	var/mana_cooldown = 0			//How soon you can do it again
	var/core						//Head/body
	var/l_arm
	var/r_arm
	var/l_leg
	var/r_leg
	var/shutting_down = FALSE		//If true it won't try to save again
	var/save_path					//The file path for the save/load function
	var/list/xp = list()			//A list of different experience values

/datum/etching/New(var/L)
	log_debug("<span class = 'danger'>ETCHING STARTED</span>")
	if(!L)
		log_debug("<span class = 'danger'>Etching: No target, delete self</span>")
		qdel(src)
		return
	ourmob = L
	log_debug("<span class = 'danger'>Etching: Registered to [ourmob]</span>")
	return ..()

/datum/etching/Destroy()
	. = ..()
	ourmob = null

/datum/etching/proc/get_save_path()
	return "data/player_saves/[copytext(ourmob.ckey, 1, 2)]/[ourmob.ckey]/magic/[ourmob.real_name]-etching.json"

/datum/etching/proc/load()
	if(IsGuestKey(ourmob.key))
		return
	if(!ourmob.ckey)
		log_debug("<span class = 'danger'>Aborting etching load for [ourmob.real_name], no ckey</span>")
		return

	save_path = get_save_path()

	if(!save_path)
		log_debug("<span class = 'danger'>Etching load failed: No save_path</span>")
		return
	if(!fexists(save_path))
		log_debug("Etching load failed: No file '[save_path]' exists. Beginning setup.")
		setup()
		return

	var/content
	try
		content = file2text(save_path)
	catch(var/exception/E_content)
		error("Exception when loading etching content - [save_path] - [content]: [E_content]")

	if(!content)
		error("Etching failed to load for [ourmob.real_name], aborting.")
		return

	var/list/load

	try
		load = json_decode(file2text(save_path))
	catch(var/exception/E_json_decode)
		error("Exception decoding etching content - [save_path] - [load]: [E_json_decode]")

	if(!load)
		log_debug("<span class = 'danger'>Etching json_decode failed! File path: '[save_path]'. Load contents: [] </span>")
		return

	true_name = load["true_name"]
	core = load["core"]
	l_arm = load["l_arm"]
	r_arm = load["r_arm"]
	l_leg = load["l_leg"]
	r_leg = load["r_leg"]
	xp = load["xp"]

	log_debug("<span class = 'rose'>Etching load complete for [ourmob.real_name].</span>")

/datum/etching/proc/save(delet = FALSE)
	if(IsGuestKey(ourmob.key))
		return
	if(!ourmob.ckey)
		return

	if(shutting_down)	//Don't try to save more than once if we're already saving and shutting down.
		return
	if(delet)	//Our mob got deleted, so we're saving and quitting.
		shutting_down = TRUE

	if(!save_path)
		return

	var/list/to_save = list(
		"true_name" = true_name,
		"core" = core,
		"l_arm" = l_arm,
		"r_arm" = r_arm,
		"l_leg" = l_leg,
		"r_leg" = r_leg,
		"xp" = xp
		)

	var/json_to_file = json_encode(to_save)
	if(!json_to_file)
		log_debug("Saving: [save_path] failed jsonencode")
		return

	//Write it out
	rustg_file_write(json_to_file, save_path)

	if(!fexists(save_path))
		log_debug("Saving: [save_path] failed file write")

	if(shutting_down)
		ourmob = null
		qdel(src)

/datum/etching/proc/setup()

	log_debug("<span class = 'danger'>setup</span>")

	return

/mob/proc/magic_rename(var/old_name,var/new_name)
	var/old_path = "data/player_saves/[copytext(ckey, 1, 2)]/[ckey]/magic/[old_name]-etching.json"
	if(!fexists(old_path))
		return
	var/list/load = json_decode(file2text(old_path))

	var/new_path = "data/player_saves/[copytext(ckey, 1, 2)]/[ckey]/magic/[new_name]-etching.json"

	if(isliving(src))	//We might be playing as the mob we want to rename
		var/mob/living/L = src
		if(L.real_name == old_name)	//We are
			var/datum/etching/E = L.etching
			E.save_path = new_path	//Update the save path, in case we need to save again later to the mob's new name

	var/json_to_file = json_encode(load)
	if(!json_to_file)
		log_debug("Saving: [new_path] failed jsonencode on rename function")
		return

	//Write it out
	rustg_file_write(json_to_file, new_path)

	if(!fexists(new_path))
		log_debug("Saving: [new_path] failed file write on rename function")
		return
	fdel(old_path)
	if(fexists(old_path))
		log_debug("Saving: [old_path] failed to delete on rename function")
		return
