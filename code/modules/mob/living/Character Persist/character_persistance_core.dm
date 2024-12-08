//RS FILE

/mob/living
	var/datum/etching/etching
	var/admin_magic = FALSE

/mob/living/Initialize()
	. = ..()
	init_etching()

/mob/living/Login()
	. = ..()
	if(etching)
		log_debug("<span class = 'danger'>Etching started: Registered to [ckey]</span>")
		etching.load()

/mob/living/Destroy()
	if(etching && istype(etching, /datum/etching))
		etching.save(TRUE)
	..()

/mob/living/Life()
	. = ..()
	if(etching)
		etching.process_etching()

/mob/living/proc/init_etching()
	if((ishuman(src) && !(istype(src, /mob/living/carbon/human/dummy))) || isanimal(src))
		etching = new /datum/etching(src)

/mob/living/proc/update_etching(mode,value)
	if(etching)
		etching.update_etching(mode,value)

/mob/living/proc/grant_xp(kind,value)
	if(!etching)
		return
	if(!kind || !value)
		var/list/xp_list = list()
		xp_list += etching.xp
		xp_list += "New kind of XP"
		kind = tgui_input_list(usr, "What kind of XP would you like to add?", "Grant XP", xp_list)
		if(!kind)
			return
		if(kind == "New kind of XP")
			kind = tgui_input_text(usr, "What kind of XP would you like to add?", "Grant XP", prevent_enter = TRUE)
		value = tgui_input_number(usr, "How many [kind] should be granted?", "Grant [kind]")
		if(!value)
			return

	etching.grant_xp(kind,value)

/mob/living/memory()
	. = ..()
	if(etching)
		etching.report_status()

/mob/proc/etching_rename(var/old_name,var/new_name)
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


/datum/etching
	var/mob/living/ourmob			//Reference to the mob we are working with
	var/event_character = FALSE		//If true, saves to an alternative path and allows editing

	var/shutting_down = FALSE		//If true it won't try to save again
	var/save_path					//The file path for the save/load function
	var/list/xp = list()			//A list of different experience values

	var/savable = TRUE				//Will never save while false
	var/needs_saving = FALSE		//For if changes have occured, it will try to save if it can
	var/save_cooldown = 0

/datum/etching/New(var/L)
	if(!L)
		log_debug("<span class = 'danger'>Etching: No target, delete self</span>")
		qdel(src)
		return
	if(!isliving(L))
		log_debug("<span class = 'danger'>Etching: Target [L] is not living, delete self</span>")
		qdel(src)
		return
	ourmob = L
	save_cooldown = rand(200,350)	//Make the number be random so that there's less chance it tries to autosave everyone at the same time.
	return ..()

/datum/etching/Destroy()
	. = ..()
	ourmob = null

/datum/etching/proc/process_etching()
	if(savable)
		if(save_cooldown <= 0)
			save()
			save_cooldown = rand(200,350)	//Make the number be random so that there's less chance it tries to autosave everyone at the same time.
		else
			save_cooldown --

/datum/etching/proc/get_save_path()

	if(event_character)
		save_path = "data/player_saves/[copytext(ourmob.ckey, 1, 2)]/[ourmob.ckey]/magic/[ourmob.real_name]-EVENT-etching.json"
	else
		save_path = "data/player_saves/[copytext(ourmob.ckey, 1, 2)]/[ourmob.ckey]/magic/[ourmob.real_name]-etching.json"

/datum/etching/proc/load()
	if(IsGuestKey(ourmob.key))
		return
	if(!ourmob.ckey)
		log_debug("<span class = 'danger'>Etching load failed: Aborting etching load for [ourmob.real_name], no ckey</span>")
		savable = FALSE
		return

	get_save_path()

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

	xp = null
	xp = load["xp"]

	item_load(load)
	log_debug("<span class = 'rose'>Etching load complete for [ourmob.real_name].</span>")

/datum/etching/proc/save(delet = FALSE)
	if(IsGuestKey(ourmob.key))
		return

	if((!savable && !event_character) || !needs_saving)
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
		"xp" = xp
		)

	to_save += item_save()

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
	return

/datum/etching/proc/update_etching(mode,value)
	needs_saving = TRUE

/datum/etching/proc/grant_xp(kind,value,quiet = FALSE,source)
	xp["[kind]"] += value
	if(!quiet)
		to_chat(ourmob,"<span class = 'notice'>You earned [value] [kind]! New total: ([xp["[kind]"]])</span>")
	needs_saving = TRUE
	if(source)
		log_admin("earned [value] [kind] XP from [source]. Total: ([xp["[kind]"]])")
	else
		log_and_message_admins("granted [value] [kind] XP to [ourmob]/[ourmob.ckey]. Total: ([xp["[kind]"]])")

/datum/etching/proc/report_status()
	if(!save_path)
		return

	var/our_xp = report_xp()
	if(our_xp)
		. = our_xp

	to_chat(ourmob, .)

/datum/etching/proc/report_xp()
	for(var/thing in xp)
		. += "<span class='boldnotice'>[capitalize(thing)]</span>: [xp[thing]]\n"

/datum/etching/vv_edit_var(var_name, var_value)
	if(var_name == "event_character")
		enable_event_character()
		return
	else if(var_name == "savable")
		return FALSE
	else if(var_name == "unlockables")
		return FALSE
	if(!event_character)
		return FALSE

	else
		needs_saving = TRUE
		return ..()

/datum/etching/get_view_variables_options()
	return ..() + {"
	<option>---</option>
	<option value='?_src_=vars;[HrefToken()];event_etching=\ref[src.ourmob]'>Toggle Event Character</option>
	<option value='?_src_=vars;[HrefToken()];save_etching=\ref[src.ourmob]'>Save</option>
	<option value='?_src_=vars;[HrefToken()];load_etching=\ref[src.ourmob]'>Load</option>
	"}

/datum/etching/proc/enable_event_character()
	event_character = TRUE
	get_save_path()
	savable = FALSE

/client/view_var_Topic(href, href_list, hsrc)
	. = ..()

	if(href_list["event_etching"])
		if(!check_rights(R_FUN))	return

		var/mob/living/L = locate(href_list["event_etching"])
		if(!L.etching)
			to_chat(usr, "\The [L] has no etching.")
			return
		if(tgui_alert(usr, "Enable event mode for [L]'s etching? This will disable normal saving, but enable variable editing.","Confirm",list("Enable","Cancel")) != "Enable")
			return
		if(!L)
			to_chat(usr, "\The [L] no longer exists.")
			return
		if(!L.etching)
			to_chat(usr, "\The [L] has no etching.")
			return
		L.etching.enable_event_character()
		log_and_message_admins(" has enabled [L]'s etching event mode.")
	if(href_list["save_etching"])
		if(!check_rights(R_FUN))	return

		var/mob/living/L = locate(href_list["save_etching"])
		if(!L.etching)
			to_chat(usr, "\The [L] has no etching.")
			return
		if(!L.etching.savable && !L.etching.event_character)
			to_chat(usr, "\The [L]'s etching can not be saved in this state.")
			return
		if(L.etching.event_character)
			to_chat(usr, "Saving [L]'s event etching.")
		else
			to_chat(usr, "Saving [L]'s etching.")
		L.etching.save()
		log_and_message_admins(" saved [L]'s etching.")
	if(href_list["load_etching"])
		if(!check_rights(R_FUN))	return

		var/mob/living/L = locate(href_list["load_etching"])
		if(!L.etching)
			to_chat(usr, "\The [L] has no etching.")
			return
		if(L.etching.event_character)
			to_chat(usr, "Loading [L]'s event etching.")
		else
			to_chat(usr, "Loading [L]'s etching.")
		L.etching.load()
		log_and_message_admins(" has loaded [L]'s etching.")

/* //Just for fun. UwU
/obj/belly/proc/xp(mob/living/ourprey)
	if(!isliving(ourprey))
		return

	var/Pred = 0.01
	var/Prey = 0.01

	if(owner.ckey)
		Pred = 1
	if(ourprey.ckey)
		Prey = 1
	if(Pred == 1)
		owner.etching.grant_xp("Pred points",Prey,source = "eating [ourprey]")
	if(Prey == 1)
		ourprey.etching.grant_xp("Prey points",Pred,source = "being eaten by [owner]")
*/
