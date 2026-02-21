//RS FILE
/datum/preferences
	var/list/vore_whitelist = list()	//A list of people we are fine with doing the vorny
	var/vore_whitelist_preference = "Accept Both"

/datum/preferences/proc/extra_global_path()
	return "data/player_saves/[copytext(client_ckey, 1, 2)]/[client_ckey]/[client_ckey]-extra-global.json"

/datum/preferences/proc/extra_global_save()
	if(!client_ckey)	//If we don't have a key we can't make a path
		return
	var/path = extra_global_path()

	var/list/to_save = list(
		"vore_whitelist" = vore_whitelist,
		"vore_whitelist_preference" = vore_whitelist_preference
		)

	var/json_to_file
	try
		json_to_file = json_encode(to_save)		//Encode the list into json format
	catch
		error("Etching failed to encode to json for [client_ckey]")

	if(!json_to_file)
		log_debug("Saving: [path] failed json encode.")
		return

	//Write it out
	try
		rustg_file_write(json_to_file, path)
	catch
		error("Etching failed to write to file for [client_ckey]: [json_to_file] - [path]")

	if(!fexists(path))
		log_debug("Saving: [path] failed file write")

/datum/preferences/proc/extra_global_load()
	if(!client_ckey)	//If we don't have a key we can't make a path
		return
	var/path = extra_global_path()

	if(!fexists(path))
		return

	var/content
	try
		content = file2text(path)
	catch(var/exception/E_content)
		error("Exception when loading extra_global content - Path: [path] - Content: [content]: [E_content]")

	if(!content)
		log_debug("<span class = 'danger'>Extra global preferences failed to populate after loading from file.</span>")
		return

	var/list/load

	try
		load = json_decode(file2text(path))
	catch(var/exception/E_json_decode)
		error("Exception decoding extra_global content - Path: [path] - Content: [content] - Load: [load]: [E_json_decode]")

	if(!load)
		log_debug("<span class = 'danger'>Etching json_decode failed! File path: '[path]'. Load contents: '[content]'. Aborting and clearing save_path.</span>")
		return

	extra_global_apply(load)

/datum/preferences/proc/vore_whitelist_remove(var/to_remove)
	if(!to_remove)
		return
	vore_whitelist -= to_remove
	client.prefs.extra_global_save()

/datum/preferences/proc/vore_whitelist_add(var/to_add)
	if(!to_add)
		return
	vore_whitelist |= to_add
	client.prefs.extra_global_save()

////////// If you add more things you can do it here //////////
/datum/preferences/proc/extra_global_apply(var/list/load)

	if(load["vore_whitelist"])
		vore_whitelist = load["vore_whitelist"]
	if(load["vore_whitelist_preference"])
		vore_whitelist_preference = load["vore_whitelist_preference"]

///////////////////////////////////////////////////////////////
/mob/living/proc/toggle_vore_whitelist()
	set name = "Vore Trust List"
	set category = "Preferences"

	if(!ckey)
		return

	var/choice = tgui_alert(src,"Will you add or remove from the trust list?","Vore Trust List",list("Add","Remove"))

	if(choice == "Add")
		var/list/our_keys = list()
		for(var/client/C in GLOB.clients)
			if(C != src.client)
				our_keys += C.key
		if(!our_keys.len)
			to_chat(src, SPAN_WARNING("There are no keys connected that you can add."))
			return
		choice = tgui_input_list(src,"Who will you add to the trust list?","Add To trust list",our_keys)
		if(!choice)
			return
		client.prefs.vore_whitelist_add(choice)
		to_chat(src, SPAN_NOTICE("[choice] was added to the vore trust list."))

	if(choice == "Remove")
		if(!client.prefs.vore_whitelist.len)
			to_chat(src, SPAN_WARNING("Your trust list is empty."))
			return
		choice = tgui_input_list(src,"Who will you remove from the trust list?","Remove From Trust List",client.prefs.vore_whitelist)

		if(!choice)
			return

		client.prefs.vore_whitelist_remove(choice)
		to_chat(src, SPAN_NOTICE("[choice] was removed from the vore trust list."))

/mob/living/Login()
	. = ..()
	client.prefs.extra_global_load()

/mob/living/proc/check_vore_whitelist(var/mob/living/L,var/preftype,var/mode)	//Check if preftype is something we have on whitelist, and if so, if L is on our list
	if(!client)	//not going to have a whitelist, so just say yes
		return TRUE
	if(!(preftype in client.prefs_vr.vore_whitelist_toggles))	//we don't care about this pref
		return TRUE
	if(client.prefs.vore_whitelist_preference != WL_BOTH)
		if(client.prefs.vore_whitelist_preference == WL_PREY && mode != WL_PREY)
			return FALSE
		if(client.prefs.vore_whitelist_preference == WL_PRED && mode != WL_PRED)
			return FALSE
	if(L.client.key in client.prefs.vore_whitelist)
		return TRUE
	return FALSE

/proc/check_vore_whitelist_pair(var/mob/living/pred,var/mob/living/prey,var/preftype)
	if(!pred || !prey)
		return TRUE
	if(preftype == SPONT_PRED || preftype == SPONT_PREY)
		if(prey.check_vore_whitelist(pred,SPONT_PREY,WL_PREY) && pred.check_vore_whitelist(prey,SPONT_PRED,WL_PRED))
			return TRUE

	else if(prey.check_vore_whitelist(pred,preftype,WL_PREY) && pred.check_vore_whitelist(prey,preftype,WL_PRED))
		return TRUE
	return FALSE

/mob/living/proc/adjust_vore_whitelist_toggles()
	set name = "Vore Trust List Toggles"
	set category = "Preferences"

	var/list/preflist = list(
		SPONT_PREY,
		SPONT_PRED,
		DROP_VORE,
		STUMBLE_VORE,
		BUCKLE_VORE, // Seperated out from stumble vore (Lira, January 2026)
		SLIP_VORE,
		THROW_VORE,
		FOOD_VORE,
		EMOTE_VORE, // Add emote spont vore (Lira, February 2026)
		MICRO_PICKUP,
		"Whitelist Pred/Prey"
		)

	var/choice = tgui_input_list(src,"What preference will you toggle trust list mode on?","Toggle Trust List",preflist)

	if(!choice)
		return

	if(choice == "Whitelist Pred/Prey")
		choice = tgui_alert(src,"For preferences that the trust list is enabled for, setting this will allow trusted users to engage only with the selected mode, and will restrict all users from interacting with the opposite mode, if applicable. Which will you choose?","Trust List Mode",list("[WL_BOTH]","[WL_PREY]","[WL_PRED]"))

		if(!choice)
			return
		client.prefs.vore_whitelist_preference = choice
		return

	if(choice in client.prefs_vr.vore_whitelist_toggles)
		client.prefs_vr.vore_whitelist_toggles -= choice
		to_chat(src, SPAN_WARNING("[choice] trust list mode disabled."))
	else
		client.prefs_vr.vore_whitelist_toggles |= choice
		to_chat(src, SPAN_NOTICE("[choice] trust list mode enabled."))
	vorePanel.unsaved_changes = TRUE

/proc/spont_pref_check(var/mob/living/pred,var/mob/living/prey,var/preftype)
	if(!preftype)
		return FALSE

	if(preftype == MICRO_PICKUP)
		if(!pred.pickup_pref || !pred.pickup_active || !prey.pickup_pref || !prey.pickup_active)
			return FALSE
		if(pred != prey && !prey.check_vore_whitelist(pred,MICRO_PICKUP))
			return FALSE
		return TRUE

	if(preftype == RESIZING)
		if(!prey.resizable)	//Only check the prey since the pred won't be getting resized, and they might like to resize someone else
			return FALSE
		if(pred != prey && !prey.check_vore_whitelist(pred,RESIZING))
			return FALSE
		return TRUE

	if(preftype == SPONT_TF)
		if(!pred.allow_spontaneous_tf || !prey.allow_spontaneous_tf)
			return FALSE
		if(pred != prey && !prey.check_vore_whitelist(pred,SPONT_TF))
			return FALSE
		return TRUE

	if(!pred.vore_selected)
		return FALSE

	if(!prey.devourable)
		return FALSE
	if(isanimal(pred) && !prey.allowmobvore)
		return FALSE
	if(pred != prey && !pred.can_be_drop_pred || !prey.can_be_drop_prey)	//Both of these always need to be true for any of the other spont vore checks to go through
		return FALSE
	if(!pred.client || !prey.client)	//One doesn't have a client, so no chance of whitelist happening.
		return TRUE
	if(pred != prey && !check_vore_whitelist_pair(pred,prey,preftype))	//Now let's check the whitelist for the preference, finally!!!
		return FALSE

	switch(preftype)
		if(SPONT_PREY)	//Only test this on the prey
			if(prey.client)
				if(!prey.client.prefs_vr.can_be_drop_prey)
					return FALSE
		if(SPONT_PRED)	//Only test this on the pred
			if(pred.client)
				if(!pred.client.prefs_vr.can_be_drop_pred)
					return FALSE

		if(DROP_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.drop_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.drop_vore)
					return FALSE

		if(STUMBLE_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.stumble_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.stumble_vore)
					return FALSE

		// Seperate out from stumble vore (Lira, September 2026)
		if(BUCKLE_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.buckle_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.buckle_vore)
					return FALSE

		if(SLIP_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.slip_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.slip_vore)
					return FALSE

		if(THROW_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.throw_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.throw_vore)
					return FALSE

		if(FOOD_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.food_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.food_vore)
					return FALSE

		// Add emote spont vore (Lira, February 2026)
		if(EMOTE_VORE)
			if(prey.client)
				if(!prey.client.prefs_vr.emote_vore)
					return FALSE
			if(pred.client)
				if(!pred.client.prefs_vr.emote_vore)
					return FALSE

	return TRUE

///////////////////////////////////////////////////////////////////////////////////////////////

/mob/living/proc/print_vore_whitelist()
	set name = "Vore Trust List Print"
	set category = "Preferences"

	if(!ckey)
		return

	. = SPAN_WARNING("===VORE TRUST LIST BEGIN===\n")

	. += SPAN_DANGER("MODE: [client.prefs.vore_whitelist_preference]")

	. += SPAN_NOTICE("\n\nPROTECTED PREFERENCES:\n")

	for(var/thing in client.prefs_vr.vore_whitelist_toggles)
		. += "[thing]\n"

	. += SPAN_WARNING("\n======\n\n")
	. += SPAN_NOTICE("TRUSTED KEYS:\n")

	for(var/mob_key in client.prefs.vore_whitelist)
		. += "[mob_key]\n"

	to_chat(src, .)

/////////////////////////////////////////////////////////////////////////////////////////////

/mob/living/verb/vore_trustlist()
	set name = "Vore Trustlist"
	set category = "Preferences"

	if(!client)
		return

	var/dat = {"
	<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">
	<html>
		<head>
			<style>
				.content {
					padding: 5;
					width: 100%;
					background-color: #363636;
				}
				.active {
					padding: 10;
					background-color: #109c00;
					color: white;
					width: 50%;
					text-align: left;
					font-size: 12px;
				}
				.inactive {
					padding: 10;
					background-color: #130072;
					color: white;
					width: 50%;
					text-align: left;
					font-size: 12px;
				}
				.ourmode {
					padding: 30;
					background-color: #ab5500;
					color: white;
					width: 100%;
					text-align: center;
					font-size: 25px;
				}
				.table, th, td {
					border:1px solid black;
				}

				</style>
			</head>"}

	dat += {"<body><table>"}
	var/active = "<span style='font-face: fixedsys; font-size: 11px; background-color: ["#1aff00"]; color: ["#1aff00"]'>_____</span>"
	var/inactive = "<span style='font-face: fixedsys; font-size: 11px; background-color: ["#130072"]; color: ["#130072"]'>_____</span>"
	var/disabled = "<span style='font-face: fixedsys; font-size: 11px; background-color: ["#000000"]; color: ["#ffffff"]'>DISABLED</span>"

	dat += {"
	Any of the preferences set to [active] will only work with any trusted users that you have registered. These preferences DO NOT override the general vore panel settings. If you have them disabled in the vore panel, then these settings won't do anything. The mode listed below has to do with what kinds of interactions will be accepted on prefs where the trustlist is enabled.			</table>
			</body>
			</html>
			"}

	dat += {"<br>"}
	dat += {"<a href='?src=\ref[src];edit_vore_trustlist=1'>Edit Trustlist Keys</a> - <a href='?src=\ref[src];print_vore_trustlist=1'>Print Trustlist Data</a> - <a href='?src=\ref[src];toggle_vore_trustlist_mode=1'>Toggle Mode</a><br>"}
	dat += {"<br>"}
	dat += {"<div class="ourmode"><b><br>Mode: [client.prefs.vore_whitelist_preference]<br><br></b></div>"}
	if(client.prefs.vore_whitelist_preference == WL_BOTH)
		dat += {"'[WL_BOTH]' will accept both predator and prey interactions for any preference set to [active]."}
	if(client.prefs.vore_whitelist_preference == WL_PREY)
		dat += {"'[WL_PREY]' will only accept prey interactions for any preference set to [active]."}
	if(client.prefs.vore_whitelist_preference == WL_PRED)
		dat += {"'[WL_PRED]' will only accept predator interactions for any preference set to [active]."}

	dat += {"<br><br><center>"}
	var/variance
	if(!client.prefs_vr.can_be_drop_prey)
		variance = disabled
	else if(SPONT_PREY in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[SPONT_PREY]'>[variance] [SPONT_PREY]</a> - "}

	if(!client.prefs_vr.can_be_drop_pred)
		variance = disabled
	else if(SPONT_PRED in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[SPONT_PRED]'>[variance] [SPONT_PRED]</a><br>"}

	if(!client.prefs_vr.drop_vore)
		variance = disabled
	else if(DROP_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[DROP_VORE]'>[variance] [DROP_VORE]</a> - "}

	if(!client.prefs_vr.stumble_vore)
		variance = disabled
	else if(STUMBLE_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[STUMBLE_VORE]'>[variance] [STUMBLE_VORE]</a><br>"}

	// Seperate out from stumble vore (Lira, January 2026)
	if(!client.prefs_vr.buckle_vore)
		variance = disabled
	else if(BUCKLE_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[BUCKLE_VORE]'>[variance] [BUCKLE_VORE]</a><br>"}

	if(!client.prefs_vr.slip_vore)
		variance = disabled
	else if(SLIP_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[SLIP_VORE]'>[variance] [SLIP_VORE]</a> - "}

	if(!client.prefs_vr.throw_vore)
		variance = disabled
	else if(THROW_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[THROW_VORE]'>[variance] [THROW_VORE]</a><br>"}

	if(!client.prefs_vr.food_vore)
		variance = disabled
	else if(FOOD_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[FOOD_VORE]'>[variance] [FOOD_VORE]</a> - "}

	// Add emote spont vore (Lira, February 2026)
	if(!client.prefs_vr.emote_vore)
		variance = disabled
	else if(EMOTE_VORE in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[EMOTE_VORE]'>[variance] [EMOTE_VORE]</a><br>"}

	if(!(pickup_pref && pickup_active))
		variance = disabled
	else if(MICRO_PICKUP in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[MICRO_PICKUP]'>[variance] [MICRO_PICKUP]</a><br>"}

	if(!client.prefs_vr.allow_spontaneous_tf)
		variance = disabled
	else if(SPONT_TF in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[SPONT_TF]'>[variance] [SPONT_TF]</a> - "}

	if(!client.prefs_vr.resizable)
		variance = disabled
	else if(RESIZING in client.prefs_vr.vore_whitelist_toggles)
		variance = active
	else
		variance = inactive
	dat += {"<a href='?src=\ref[src];toggle_vore_trustlist=[RESIZING]'>[variance] [RESIZING]</a>"}
	dat += {"</center>"}
	var/key = "vore_trustlist[src.ckey]"	//Generate a unique key so we can make unique clones of windows, that way we can have more than one

	winclone(src, "vore_trustlist", key)		//Allows us to have more than one OOC notes panel open

	winshow(src, key, TRUE)				//Register our window
	var/datum/browser/popup = new(src, key, "Vore Trustlist", 600, 650)		//Create the window
	popup.set_content(dat)	//Populate window contents
	popup.open(FALSE) // Skip registring onclose on the browser pane
	onclose(src, key, src) // We want to register on the window itself

/mob/living/proc/toggle_vore_trustlist(var/ourpref)
	if(!ourpref) return

	if(!client)
		to_chat(usr,SPAN_DANGER("Please close and reopen this window to refresh."))
		return

	if(ourpref in client.prefs_vr.vore_whitelist_toggles)
		client.prefs_vr.vore_whitelist_toggles -= ourpref
		to_chat(src,SPAN_WARNING("Toggled [ourpref] trustlist mode: Disabled"))

	else
		client.prefs_vr.vore_whitelist_toggles |= ourpref
		to_chat(src,SPAN_NOTICE("Toggled [ourpref] trustlist mode: Enabled"))

	to_chat(src,SPAN_NOTICE("Remember to save your changes in the vore panel to have them stick!"))
	vorePanel.unsaved_changes = TRUE

// Adjusted to allow TGUI changes without opening html window (Lira, September 2025)
/mob/living/proc/toggle_vore_trustlist_mode(var/new_mode)
	if(new_mode)
		if(!(new_mode in list(WL_BOTH, WL_PREY, WL_PRED)))
			return
		client.prefs.vore_whitelist_preference = new_mode
		client.prefs.extra_global_save()
		to_chat(src, SPAN_NOTICE("Trust list mode set to [new_mode]."))
		return

	var/choice = tgui_alert(src,"For preferences that the trust list is enabled for, setting this will allow trusted users to engage only with the selected mode, and will restrict all users from interacting with the opposite mode, if applicable. Which will you choose?","Trust List Mode",list("[WL_BOTH]","[WL_PREY]","[WL_PRED]"))

	if(!choice)
		return
	client.prefs.vore_whitelist_preference = choice
	client.prefs.extra_global_save()
	vore_trustlist()
