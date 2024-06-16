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
	if(etching)
		etching.process_etching()

/mob/living/proc/init_magic()
	if((ishuman(src) && !(istype(src, /mob/living/carbon/human/dummy))) || isanimal(src))
		etching = new /datum/etching(src)

/mob/living/proc/update_etching(mode,value)
	if(etching)
		etching.update_etching(mode,value)

/mob/living/proc/grant_xp(kind,value)
	if(etching)
		etching.grant_xp(kind,value)

/mob/living/memory()
	. = ..()
	if(etching)
		etching.report_status()

/datum/etching
	var/mob/living/ourmob			//Reference to the mob we are working with
	var/event_character = FALSE		//If true, saves to an alternative path and allows editing
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

	var/triangles = 0				//Triangle money

	var/savable = TRUE				//Will never save while false
	var/needs_saving = FALSE		//For if changes have occured, it will try to save if it can
	var/save_cooldown = 0

/datum/etching/New(var/L)
	log_debug("<span class = 'danger'>ETCHING STARTED</span>")
	if(!L)
		log_debug("<span class = 'danger'>Etching: No target, delete self</span>")
		qdel(src)
		return
	ourmob = L
	log_debug("<span class = 'danger'>Etching: Registered to [ourmob]</span>")
	save_cooldown = rand(200,350)	//Make the number be random so that there's less chance it tries to autosave everyone at the same time.
	return ..()

/datum/etching/Destroy()
	. = ..()
	ourmob = null

/datum/etching/proc/process_etching()
	if(mana < max_mana)
		mana += mana_regen
	if(mana_cooldown)
		mana_cooldown --

	if(savable)
		if(save_cooldown <= 0)
			save()
			save_cooldown = rand(200,350)	//Make the number be random so that there's less chance it tries to autosave everyone at the same time.
		else
			save_cooldown --

/datum/etching/proc/get_save_path()

	if(event_character)
		return "data/player_saves/[copytext(ourmob.ckey, 1, 2)]/[ourmob.ckey]/magic/[ourmob.real_name]-EVENT-etching.json"
	else
		return "data/player_saves/[copytext(ourmob.ckey, 1, 2)]/[ourmob.ckey]/magic/[ourmob.real_name]-etching.json"

/datum/etching/proc/load()
	if(IsGuestKey(ourmob.key))
		return
	if(!ourmob.ckey)
		log_debug("<span class = 'danger'>Aborting etching load for [ourmob.real_name], no ckey</span>")
		savable = FALSE
		return

	save_path = get_save_path()

	if(!save_path)
		log_debug("<span class = 'danger'>Etching load failed: No save_path</span>")
		savable = FALSE
		return
	if(!fexists(save_path))
		log_debug("Etching load failed: No file '[save_path]' exists. Beginning setup.")
		setup()
		return

	var/content
	try
		content = file2text(save_path)
	catch(var/exception/E_content)
		error("Exception when loading etching content - Path: [save_path] - Content: [content]: [E_content]")

	if(!content)
		log_debug("<span class = 'danger'>Etching failed to load for [ourmob.real_name], aborting and clearing save_path.</span>")
		save_path = null
		savable = FALSE
		return

	var/list/load

	try
		load = json_decode(file2text(save_path))
	catch(var/exception/E_json_decode)
		error("Exception decoding etching content - Path: [save_path] - Content: [content] - Load: [load]: [E_json_decode]")

	if(!load)
		log_debug("<span class = 'danger'>Etching json_decode failed! File path: '[save_path]'. Load contents: '[content]'. Aborting and clearing save_path.</span>")
		save_path = null
		savable = FALSE
		return

	true_name = load["true_name"]
	core = load["core"]
	l_arm = load["l_arm"]
	r_arm = load["r_arm"]
	l_leg = load["l_leg"]
	r_leg = load["r_leg"]
	xp = load["xp"]
	triangles = load["triangles"]

	log_debug("<span class = 'rose'>Etching load complete for [ourmob.real_name].</span>")

/datum/etching/proc/save(delet = FALSE)
	if(!savable || !needs_saving)
		return
	if(IsGuestKey(ourmob.key))
		return

	if(shutting_down)	//Don't try to save more than once if we're already saving and shutting down.
		return
	if(delet)	//Our mob got deleted, so we're saving and quitting.
		shutting_down = TRUE

	if(!save_path || !ishuman(ourmob) || istype(ourmob, /mob/living/carbon/human/dummy))
		if(shutting_down)
			ourmob = null
			qdel(src)
		return

	var/list/to_save = list(
		"true_name" = true_name,
		"core" = core,
		"l_arm" = l_arm,
		"r_arm" = r_arm,
		"l_leg" = l_leg,
		"r_leg" = r_leg,
		"xp" = xp,
		"triangles" = triangles
		)

	var/json_to_file
	try
		json_to_file = json_encode(to_save)
	catch
		error("Etching failed to encode to json for [ourmob.real_name]")

	if(!json_to_file)
		log_debug("Saving: [save_path] failed json encode.")
		return

	//Write it out
	try
		rustg_file_write(json_to_file, save_path)
	catch
		error("Etching failed to write to file for [ourmob.real_name]: [json_to_file] - [save_path]")

	if(!fexists(save_path))
		log_debug("Saving: [save_path] failed file write")

	needs_saving = FALSE

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

/datum/etching/proc/update_etching(mode,value)
	switch(mode)
		if("triangles")
			triangles += value

	needs_saving = TRUE

/datum/etching/proc/grant_xp(kind,value)
	xp["[kind]"] += value
	needs_saving = TRUE

/datum/etching/proc/report_status()
	if(!save_path)
		return
	. = "<span class='boldnotice'>◬</span>: [triangles]\n\n"

	var/extra = FALSE
	if(core)
		. += "<span class='boldnotice'>Core</span>: [core]\n"
		extra = TRUE
	if(l_arm)
		. += "[l_arm]\n"
		extra = TRUE
	if(r_arm)
		. += "[r_arm]\n"
		extra = TRUE
	if(l_arm)
		. += "[l_leg]\n"
		extra = TRUE
	if(r_leg)
		. += "[r_leg]\n"
		extra = TRUE

	if(extra)
		. += "\n"

	for(var/thing in xp)
		. += "<span class='boldnotice'>[thing]</span>: [xp[thing]]\n"

	to_chat(ourmob, .)

/datum/etching/vv_edit_var(var_name, var_value)
	return FALSE
