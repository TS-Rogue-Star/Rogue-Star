//RS Add || Ports vorebelly import, from CHOMPStation PR9330, PR10512
#define IMPORT_ALL_BELLIES "Import all bellies from VRDB"
#define IMPORT_ONE_BELLY "Import one belly from VRDB"
/datum/vore_look/proc/import_belly(mob/host)
	var/panel_choice = tgui_input_list(host, "Belly Import", "Pick an option", list(IMPORT_ALL_BELLIES, IMPORT_ONE_BELLY))
	if(!panel_choice) return
	var/pickOne = FALSE
	if(panel_choice == IMPORT_ONE_BELLY)
		pickOne = TRUE
	var/input_file = input(host,"Please choose a valid VRDB file to import from.","Belly Import") as file
	var/input_data
	try
		input_data = json_decode(file2text(input_file))
	catch(var/exception/e)
		tgui_alert_async(host, "The supplied file contains errors: [e]", "Error!")
		return FALSE

	// RS Edit Start: Updated to support both local and other server vrdb file structures (Lira, November 2025)
	var/list/belly_entries = list()
	if(islist(input_data["bellies"]))
		belly_entries = input_data["bellies"]
	else if(islist(input_data))
		for(var/key in input_data)
			var/val = input_data[key]
			if(islist(val))
				if(islist(val["bellies"]))
					for(var/nested_belly in val["bellies"])
						if(islist(nested_belly))
							belly_entries += list(nested_belly)
					continue
				if(istext(val["name"]))
					belly_entries += list(val)
		if(length(belly_entries) <= 0)
			belly_entries = input_data

	if(!islist(belly_entries) || length(belly_entries) <= 0)
		tgui_alert_async(usr, "The supplied file was not a valid VRDB file.", "Error!")
		return FALSE
	input_data = belly_entries
	// RS Edit End

	var/list/valid_names = list()
	var/list/valid_lists = list()
	var/list/updated = list()

	for(var/list/raw_list in input_data)
		if(length(valid_names) >= BELLIES_MAX) break
		if(!islist(raw_list)) continue
		if(!istext(raw_list["name"])) continue
		if(length(raw_list["name"]) > BELLIES_NAME_MAX || length(raw_list["name"]) < BELLIES_NAME_MIN) continue
		if(raw_list["name"] in valid_names) continue
		for(var/obj/belly/B in host.vore_organs)
			if(lowertext(B.name) == lowertext(raw_list["name"]))
				updated += raw_list["name"]
				break
		if(!pickOne && length(host.vore_organs)+length(valid_names)-length(updated) >= BELLIES_MAX) continue
		valid_names += raw_list["name"]
		valid_lists += list(raw_list)

	if(length(valid_names) <= 0)
		tgui_alert_async(usr, "The supplied VRDB file does not contain any valid bellies.", "Error!")
		return FALSE

	if(pickOne) //Choose one vorebelly in the list
		var/picked = tgui_input_list(host, "Belly Import", "Which belly?", valid_names)
		if(!picked) return
		for(var/B in valid_lists)
			if(lowertext(picked) == lowertext(B["name"]))
				valid_names = list(picked)
				valid_lists = list(B)
				break
		if(picked in updated)
			updated = list(picked)
		else
			updated = list()

	var/list/alert_msg = list()
	if(length(valid_names)-length(updated) > 0)
		alert_msg += "add [length(valid_names)-length(updated)] new bell[length(valid_names)-length(updated) == 1 ? "y" : "ies"]"
	if(length(updated) > 0)
		alert_msg += "update [length(updated)] existing bell[length(updated) == 1 ? "y" : "ies"]. Please make sure you have saved a copy of your existing bellies"

	var/confirm = tgui_alert(host, "WARNING: This will [jointext(alert_msg," and ")]. You can revert the import by using the Reload Prefs button under Preferences as long as you don't Save Prefs. Are you sure?","Import bellies?",list("Yes","Cancel"))
	if(confirm != "Yes") return FALSE

	for(var/list/belly_data in valid_lists)
		var/obj/belly/new_belly
		for(var/obj/belly/existing_belly in host.vore_organs)
			if(lowertext(existing_belly.name) == lowertext(belly_data["name"]))
				new_belly = existing_belly
				break
		if(!new_belly && length(host.vore_organs) < BELLIES_MAX)
			new_belly = new(host)
			new_belly.name = belly_data["name"]
		if(!new_belly) continue

		// Controls
		if(istext(belly_data["mode"])) //Set the mode of the vorebelly
			var/new_mode = html_encode(belly_data["mode"])
			if(new_mode in new_belly.digest_modes)
				new_belly.digest_mode = new_mode

		if(istext(belly_data["item_mode"])) //set the item mode of the vorebelly
			var/new_item_mode = html_encode(belly_data["item_mode"])
			if(new_item_mode in new_belly.item_digest_modes)
				new_belly.item_digest_mode = new_item_mode

		if(islist(belly_data["addons"]))
			new_belly.mode_flags = 0
			//new_belly.slow_digestion = FALSE
			STOP_PROCESSING(SSbellies, new_belly)
			STOP_PROCESSING(SSobj, new_belly)
			START_PROCESSING(SSbellies, new_belly)
			for(var/addon in belly_data["addons"])
				new_belly.mode_flags += new_belly.mode_flag_list[addon]
				//switch(addon) // Intent for future update; but does not currently exist in RS
					//if("Slow Body Digestion")
						//new_belly.slow_digestion = TRUE

		// Descriptions
		if(istext(belly_data["desc"]))
			var/new_desc = html_encode(belly_data["desc"])
			if(new_desc)
				new_desc = readd_quotes(new_desc)
			if(length(new_desc) > 0 && length(new_desc) <= BELLIES_DESC_MAX)
				new_belly.desc = new_desc
			else if(length(new_desc) > 0 && length(new_desc) >= BELLIES_DESC_MAX)
				tgui_alert_async(usr, "Invalid description for the " + belly_data["name"] + " vorebelly! It is likely too long. The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(istext(belly_data["absorbed_desc"]))
			var/new_absorbed_desc = html_encode(belly_data["absorbed_desc"])
			if(new_absorbed_desc)
				new_absorbed_desc = readd_quotes(new_absorbed_desc)
			if(length(new_absorbed_desc) > 0 && length(new_absorbed_desc) <= BELLIES_DESC_MAX) //ensure belly description is within a valid length
				new_belly.absorbed_desc = new_absorbed_desc
			else if(length(new_absorbed_desc) > 0 && length(new_absorbed_desc) >= BELLIES_DESC_MAX) //if the description is too long and likely got truncated
				tgui_alert_async(usr, "Invalid absorbed description. It is likely too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(istext(belly_data["vore_verb"]))
			var/new_vore_verb = html_encode(belly_data["vore_verb"])
			if(new_vore_verb)
				new_vore_verb = readd_quotes(new_vore_verb)
			if(length(new_vore_verb) >= BELLIES_NAME_MIN && length(new_vore_verb) <= BELLIES_NAME_MAX)
				new_belly.vore_verb = new_vore_verb
			else if(length(new_vore_verb) >= BELLIES_NAME_MIN && length(new_vore_verb) >= BELLIES_NAME_MAX) //if it's too long
				tgui_alert_async(usr, "Invalid vore verb for the " + belly_data["name"] + " vorebelly! It is likely too long. The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(istext(belly_data["release_verb"]))
			var/new_release_verb = html_encode(belly_data["release_verb"])
			if(new_release_verb)
				new_release_verb = readd_quotes(new_release_verb)
			if(length(new_release_verb) >= BELLIES_NAME_MIN && length(new_release_verb) <= BELLIES_NAME_MAX)
				new_belly.release_verb = new_release_verb
			else if(length(new_release_verb) >= BELLIES_NAME_MIN && length(new_release_verb) >= BELLIES_NAME_MAX) //if it it's too long
				tgui_alert_async(usr, "Invalid release verb for the " + belly_data["name"] + " vorebelly! It is likely too long. The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["digest_messages_prey"]))
			var/new_digest_messages_prey = sanitize(jointext(belly_data["digest_messages_prey"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_digest_messages_prey)
				new_belly.set_messages(new_digest_messages_prey,"dmp")
			else if(length(new_digest_messages_prey) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid prey digest messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["digest_messages_owner"]))
			var/new_digest_messages_owner = sanitize(jointext(belly_data["digest_messages_owner"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_digest_messages_owner)
				new_belly.set_messages(new_digest_messages_owner,"dmo")
			else if(length(new_digest_messages_owner) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid pred digest messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["absorb_messages_prey"]))
			var/new_absorb_messages_prey = sanitize(jointext(belly_data["absorb_messages_prey"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_absorb_messages_prey)
				new_belly.set_messages(new_absorb_messages_prey,"amp")
			else if(length(new_absorb_messages_prey) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid prey absorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["absorb_messages_owner"]))
			var/new_absorb_messages_owner = sanitize(jointext(belly_data["absorb_messages_owner"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_absorb_messages_owner)
				new_belly.set_messages(new_absorb_messages_owner,"amo")
			else if(length(new_absorb_messages_owner) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid prey absorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["unabsorb_messages_prey"]))
			var/new_unabsorb_messages_prey = sanitize(jointext(belly_data["unabsorb_messages_prey"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_unabsorb_messages_prey)
				new_belly.set_messages(new_unabsorb_messages_prey,"uamp")
			else if(length(new_unabsorb_messages_prey) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid prey unabsorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["unabsorb_messages_owner"]))
			var/new_unabsorb_messages_owner = sanitize(jointext(belly_data["unabsorb_messages_owner"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_unabsorb_messages_owner)
				new_belly.set_messages(new_unabsorb_messages_owner,"uamo")
			else if(length(new_unabsorb_messages_owner) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid pred unabsorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["struggle_messages_outside"]))
			var/new_struggle_messages_outside = sanitize(jointext(belly_data["struggle_messages_outside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_struggle_messages_outside)
				new_belly.set_messages(new_struggle_messages_outside,"smo")
			else if(length(new_struggle_messages_outside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid outside struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["struggle_messages_inside"]))
			var/new_struggle_messages_inside = sanitize(jointext(belly_data["struggle_messages_inside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_struggle_messages_inside)
				new_belly.set_messages(new_struggle_messages_inside,"smi")
			else if(length(new_struggle_messages_inside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid inside struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["absorbed_struggle_messages_outside"]))
			var/new_absorbed_struggle_messages_outside = sanitize(jointext(belly_data["absorbed_struggle_messages_outside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_absorbed_struggle_messages_outside)
				new_belly.set_messages(new_absorbed_struggle_messages_outside,"asmo")
			else if(length(new_absorbed_struggle_messages_outside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid outside absorbed struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["absorbed_struggle_messages_inside"]))
			var/new_absorbed_struggle_messages_inside = sanitize(jointext(belly_data["absorbed_struggle_messages_inside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_absorbed_struggle_messages_inside)
				new_belly.set_messages(new_absorbed_struggle_messages_inside,"asmi")
			else if(length(new_absorbed_struggle_messages_inside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid inside absorbed struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["examine_messages"]))
			var/new_examine_messages = sanitize(jointext(belly_data["examine_messages"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_examine_messages)
				new_belly.set_messages(new_examine_messages,"em")
			else if(length(new_examine_messages) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid examine messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["examine_messages_absorbed"]))
			var/new_examine_messages_absorbed = sanitize(jointext(belly_data["examine_messages_absorbed"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_examine_messages_absorbed)
				new_belly.set_messages(new_examine_messages_absorbed,"ema")
			else if(length(new_examine_messages_absorbed) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid absorbed examine messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_digest"]))
			var/new_emotes_digest = sanitize(jointext(belly_data["emotes_digest"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_digest)
				new_belly.set_messages(new_emotes_digest,"im_digest")
			else if(length(new_emotes_digest) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid digestion messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_hold"]))
			var/new_emotes_hold = sanitize(jointext(belly_data["emotes_hold"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_hold)
				new_belly.set_messages(new_emotes_hold,"im_hold")
			else if(length(new_emotes_hold) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid holding messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_holdabsorbed"]))
			var/new_emotes_holdabsorbed = sanitize(jointext(belly_data["emotes_holdabsorbed"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_holdabsorbed)
				new_belly.set_messages(new_emotes_holdabsorbed,"im_holdabsorbed")
			else if(length(new_emotes_holdabsorbed) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid absorbed-holding messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_absorb"]))
			var/new_emotes_absorb = sanitize(jointext(belly_data["emotes_absorb"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_absorb)
				new_belly.set_messages(new_emotes_absorb,"im_absorb")
			else if(length(new_emotes_absorb) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid absorbing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_heal"]))
			var/new_emotes_heal = sanitize(jointext(belly_data["emotes_heal"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_heal)
				new_belly.set_messages(new_emotes_heal,"im_heal")
			else if(length(new_emotes_heal) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid healing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_drain"]))
			var/new_emotes_drain = sanitize(jointext(belly_data["emotes_drain"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_drain)
				new_belly.set_messages(new_emotes_drain,"im_drain")
			else if(length(new_emotes_drain) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid draining messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_steal"]))
			var/new_emotes_steal = sanitize(jointext(belly_data["emotes_steal"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_steal)
				new_belly.set_messages(new_emotes_steal,"im_steal")
			else if(length(new_emotes_steal) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid size stealing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_egg"]))
			var/new_emotes_egg = sanitize(jointext(belly_data["emotes_egg"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_egg)
				new_belly.set_messages(new_emotes_egg,"im_egg")
			else if(length(new_emotes_egg) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid egg messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_shrink"]))
			var/new_emotes_shrink = sanitize(jointext(belly_data["emotes_shrink"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_shrink)
				new_belly.set_messages(new_emotes_shrink,"im_shrink")
			else if(length(new_emotes_shrink) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid shrinking messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_grow"]))
			var/new_emotes_grow = sanitize(jointext(belly_data["emotes_grow"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_grow)
				new_belly.set_messages(new_emotes_grow,"im_grow")
			else if(length(new_emotes_grow) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid growing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		if(islist(belly_data["emotes_unabsorb"]))
			var/new_emotes_unabsorb = sanitize(jointext(belly_data["emotes_unabsorb"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
			if(new_emotes_unabsorb)
				new_belly.set_messages(new_emotes_unabsorb,"im_unabsorb")
			else if(length(new_emotes_unabsorb) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
				tgui_alert_async(usr, "Invalid unabsorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

		// Options
		if(isnum(belly_data["can_taste"]))
			var/new_can_taste = belly_data["can_taste"]
			if(new_can_taste == 0)
				new_belly.can_taste = FALSE
			if(new_can_taste == 1)
				new_belly.can_taste = TRUE

		if(isnum(belly_data["contaminates"]))
			var/new_contaminates = belly_data["contaminates"]
			if(new_contaminates == 0)
				new_belly.contaminates = FALSE
			if(new_contaminates == 1)
				new_belly.contaminates = TRUE

		if(istext(belly_data["contamination_flavor"]))
			var/new_contamination_flavor = sanitize(belly_data["contamination_flavor"],MAX_MESSAGE_LEN,0,0,0)
			if(new_contamination_flavor)
				if(new_contamination_flavor in contamination_flavors)
					new_belly.contamination_flavor = new_contamination_flavor

		if(istext(belly_data["contamination_color"]))
			var/new_contamination_color = sanitize(belly_data["contamination_color"],MAX_MESSAGE_LEN,0,0,0)
			if(new_contamination_color)
				if(new_contamination_color in contamination_colors)
					new_belly.contamination_color = new_contamination_color

		if(isnum(belly_data["nutrition_percent"]))
			var/new_nutrition_percent = belly_data["nutrition_percent"]
			new_belly.nutrition_percent = CLAMP(new_nutrition_percent,0.01,100)

		if(isnum(belly_data["bulge_size"]))
			var/new_bulge_size = belly_data["bulge_size"]
			if(new_bulge_size == 0)
				new_belly.bulge_size = 0
			else
				new_belly.bulge_size = CLAMP(new_bulge_size,0.25,2)

		if(isnum(belly_data["display_absorbed_examine"]))
			var/new_display_absorbed_examine = belly_data["display_absorbed_examine"]
			if(new_display_absorbed_examine == 0)
				new_belly.display_absorbed_examine = FALSE
			if(new_display_absorbed_examine == 1)
				new_belly.display_absorbed_examine = TRUE

		if(isnum(belly_data["save_digest_mode"]))
			var/new_save_digest_mode = belly_data["save_digest_mode"]
			if(new_save_digest_mode == 0)
				new_belly.save_digest_mode = FALSE
			if(new_save_digest_mode == 1)
				new_belly.save_digest_mode = TRUE

		if(isnum(belly_data["emote_active"]))
			var/new_emote_active = belly_data["emote_active"]
			if(new_emote_active == 0)
				new_belly.emote_active = FALSE
			if(new_emote_active == 1)
				new_belly.emote_active = TRUE

		if(isnum(belly_data["emote_time"]))
			var/new_emote_time = belly_data["emote_time"]
			new_belly.emote_time = CLAMP(new_emote_time, 60, 600)

		if(isnum(belly_data["digest_brute"]))
			var/new_digest_brute = belly_data["digest_brute"]
			new_belly.digest_brute = CLAMP(new_digest_brute, 0, 6)

		if(isnum(belly_data["digest_burn"]))
			var/new_digest_burn = belly_data["digest_burn"]
			new_belly.digest_burn = CLAMP(new_digest_burn, 0, 6)

		if(isnum(belly_data["digest_oxy"]))
			var/new_digest_oxy = belly_data["digest_oxy"]
			new_belly.digest_oxy = CLAMP(new_digest_oxy, 0, 12)

		if(isnum(belly_data["digest_tox"]))
			var/new_digest_tox = belly_data["digest_tox"]
			new_belly.digest_tox = CLAMP(new_digest_tox, 0, 6)

		if(isnum(belly_data["digest_clone"]))
			var/new_digest_clone = belly_data["digest_clone"]
			new_belly.digest_clone = CLAMP(new_digest_clone, 0, 6)

		if(isnum(belly_data["shrink_grow_size"]))
			var/new_shrink_grow_size = belly_data["shrink_grow_size"]
			new_belly.shrink_grow_size = CLAMP(new_shrink_grow_size, 0.25, 2)

		if(istext(belly_data["egg_type"]))
			var/new_egg_type = sanitize(belly_data["egg_type"],MAX_MESSAGE_LEN,0,0,0)
			if(new_egg_type)
				if(new_egg_type in global_vore_egg_types)
					new_belly.egg_type = new_egg_type

		if(istext(belly_data["selective_preference"]))
			var/new_selective_preference = belly_data["selective_preference"]
			if(new_selective_preference == "Digest")
				new_belly.selective_preference = DM_DIGEST
			if(new_selective_preference == "Absorb")
				new_belly.selective_preference = DM_ABSORB

		// Sounds
		if(isnum(belly_data["is_wet"]))
			var/new_is_wet = belly_data["is_wet"]
			if(new_is_wet == 0)
				new_belly.is_wet = FALSE
			if(new_is_wet == 1)
				new_belly.is_wet = TRUE

		if(isnum(belly_data["wet_loop"]))
			var/new_wet_loop = belly_data["wet_loop"]
			if(new_wet_loop == 0)
				new_belly.wet_loop = FALSE
			if(new_wet_loop == 1)
				new_belly.wet_loop = TRUE

		if(isnum(belly_data["fancy_vore"]))
			var/new_fancy_vore = belly_data["fancy_vore"]
			if(new_fancy_vore == 0)
				new_belly.fancy_vore = FALSE
			if(new_fancy_vore == 1)
				new_belly.fancy_vore = TRUE

		//Set vore sounds, if they exist. Otherwise set to default gulp/splatter for insert/release
		if(new_belly.fancy_vore)
			if(!(new_belly.vore_sound in fancy_vore_sounds))
				new_belly.vore_sound = "Gulp"
			if(!(new_belly.release_sound in fancy_vore_sounds))
				new_belly.release_sound = "Splatter"
		else
			if(!(new_belly.vore_sound in classic_vore_sounds))
				new_belly.vore_sound = "Gulp"
			if(!(new_belly.release_sound in classic_vore_sounds))
				new_belly.release_sound = "Splatter"

		if(istext(belly_data["vore_sound"]))
			var/new_vore_sound = sanitize(belly_data["vore_sound"],MAX_MESSAGE_LEN,0,0,0)
			if(new_vore_sound)
				if (new_belly.fancy_vore && (new_vore_sound in fancy_vore_sounds))
					new_belly.vore_sound = new_vore_sound
				if (!new_belly.fancy_vore && (new_vore_sound in classic_vore_sounds))
					new_belly.vore_sound = new_vore_sound

		if(istext(belly_data["release_sound"]))
			var/new_release_sound = sanitize(belly_data["release_sound"],MAX_MESSAGE_LEN,0,0,0)
			if(new_release_sound)
				if (new_belly.fancy_vore && (new_release_sound in fancy_release_sounds))
					new_belly.release_sound = new_release_sound
				if (!new_belly.fancy_vore && (new_release_sound in classic_release_sounds))
					new_belly.release_sound = new_release_sound

		// Visuals
		if(isnum(belly_data["affects_vore_sprites"]))
			var/new_affects_vore_sprites = belly_data["affects_vore_sprites"]
			if(new_affects_vore_sprites == 0)
				new_belly.affects_vore_sprites = FALSE
			if(new_affects_vore_sprites == 1)
				new_belly.affects_vore_sprites = TRUE

		if(isnum(belly_data["count_absorbed_prey_for_sprite"]))
			var/new_count_absorbed_prey_for_sprite = belly_data["count_absorbed_prey_for_sprite"]
			if(new_count_absorbed_prey_for_sprite == 0)
				new_belly.count_absorbed_prey_for_sprite = FALSE
			if(new_count_absorbed_prey_for_sprite == 1)
				new_belly.count_absorbed_prey_for_sprite = TRUE

		if(isnum(belly_data["absorbed_multiplier"]))
			var/new_absorbed_multiplier = belly_data["absorbed_multiplier"]
			new_belly.absorbed_multiplier = CLAMP(new_absorbed_multiplier, 0.1, 3)

		if(isnum(belly_data["count_liquid_for_sprite"]))
			var/new_count_liquid_for_sprite = belly_data["count_liquid_for_sprite"]
			if(new_count_liquid_for_sprite == 0)
				new_belly.count_liquid_for_sprite = FALSE
			if(new_count_liquid_for_sprite == 1)
				new_belly.count_liquid_for_sprite = TRUE

		if(isnum(belly_data["liquid_multiplier"]))
			var/new_liquid_multiplier = belly_data["liquid_multiplier"]
			new_belly.liquid_multiplier = CLAMP(new_liquid_multiplier, 0.1, 10)

		// RS Edit Start: Catch for multiple spellings (Lira, November 2025)
		var/new_reagent_touches = null
		if(isnum(belly_data["reagent_touches"])) //Reagent bellies || RS Add || Chomp Port
			new_reagent_touches = belly_data["reagent_touches"]
		else if(isnum(belly_data["reagent_toches"])) // Handle vrdb3 typo
			new_reagent_touches = belly_data["reagent_toches"]
		if(isnum(new_reagent_touches))
		// RS Edit End
			if(new_reagent_touches == 0)
				new_belly.reagent_touches = FALSE
			if(new_reagent_touches == 1)
				new_belly.reagent_touches = TRUE

		if(isnum(belly_data["count_items_for_sprite"]))
			var/new_count_items_for_sprite = belly_data["count_items_for_sprite"]
			if(new_count_items_for_sprite == 0)
				new_belly.count_items_for_sprite = FALSE
			if(new_count_items_for_sprite == 1)
				new_belly.count_items_for_sprite = TRUE

		if(isnum(belly_data["item_multiplier"]))
			var/new_item_multiplier = belly_data["item_multiplier"]
			new_belly.item_multiplier = CLAMP(new_item_multiplier, 0.1, 10)

		if(isnum(belly_data["health_impacts_size"]))
			var/new_health_impacts_size = belly_data["health_impacts_size"]
			if(new_health_impacts_size == 0)
				new_belly.health_impacts_size = FALSE
			if(new_health_impacts_size == 1)
				new_belly.health_impacts_size = TRUE

		if(isnum(belly_data["resist_triggers_animation"]))
			var/new_resist_triggers_animation = belly_data["resist_triggers_animation"]
			if(new_resist_triggers_animation == 0)
				new_belly.resist_triggers_animation = FALSE
			if(new_resist_triggers_animation == 1)
				new_belly.resist_triggers_animation = TRUE

		if(isnum(belly_data["size_factor_for_sprite"])) //how large the vore-sprite is
			var/new_size_factor_for_sprite = belly_data["size_factor_for_sprite"]
			new_belly.size_factor_for_sprite = CLAMP(new_size_factor_for_sprite, 0.1, 3)

		if(istext(belly_data["belly_sprite_to_affect"]))
			var/new_belly_sprite_to_affect = sanitize(belly_data["belly_sprite_to_affect"],MAX_MESSAGE_LEN,0,0,0)
			if(istype(host, /mob/living/carbon/human)) //workaround for vore belly sprites
				var/mob/living/carbon/human/hhost = host
				if(new_belly_sprite_to_affect)
					if(new_belly_sprite_to_affect in hhost.vore_icon_bellies) //determine if it is normal or taur belly
						new_belly.belly_sprite_to_affect = new_belly_sprite_to_affect

		//determine if the HUD is to be disabled for the person inside or not
		if(isnum(belly_data["disable_hud"]))
			var/new_disable_hud = belly_data["disable_hud"]
			if(new_disable_hud == 0)
				new_belly.disable_hud = FALSE
			if(new_disable_hud == 1)
				new_belly.disable_hud = TRUE

		//set the vore belly overlay
		var/possible_fullscreens = icon_states('icons/mob/screen_full_colorized_vore.dmi')
		if(!new_belly.colorization_enabled)
			possible_fullscreens = icon_states('icons/mob/screen_full_vore.dmi')
			possible_fullscreens -= "a_synth_flesh_mono"
			possible_fullscreens -= "a_synth_flesh_mono_hole"
			possible_fullscreens -= "a_anim_belly"
		if(!(new_belly.belly_fullscreen in possible_fullscreens))
			new_belly.belly_fullscreen = ""
		else
			tgui_alert_async(usr, "Invalid vorebelly overlay for the " + belly_data["name"] + " vorebelly!", "Error!") //Supply error message to the us

		// Interactions
		if(isnum(belly_data["escapable"]))
			var/new_escapable = belly_data["escapable"]
			if(new_escapable == 0)
				new_belly.escapable = FALSE
			if(new_escapable == 1)
				new_belly.escapable = TRUE

		if(isnum(belly_data["escapechance"]))
			var/new_escapechance = belly_data["escapechance"]
			new_belly.escapechance = sanitize_integer(new_escapechance, 0, 100, initial(new_belly.escapechance))

		if(isnum(belly_data["escapetime"]))
			var/new_escapetime = belly_data["escapetime"]
			new_belly.escapetime = sanitize_integer(new_escapetime*10, 10, 600, initial(new_belly.escapetime))

		if(isnum(belly_data["transferchance"]))
			var/new_transferchance = belly_data["transferchance"]
			new_belly.transferchance = sanitize_integer(new_transferchance, 0, 100, initial(new_belly.transferchance))

		if(istext(belly_data["transferlocation"]))
			var/new_transferlocation = sanitize(belly_data["transferlocation"],MAX_MESSAGE_LEN,0,0,0)
			if(new_transferlocation)
				for(var/obj/belly/existing_belly in host.vore_organs) //if the transfer location currently exists
					if(existing_belly.name == new_transferlocation)
						new_belly.transferlocation = new_transferlocation
						break
				if(new_transferlocation in valid_names)
					new_belly.transferlocation = new_transferlocation
				if(new_transferlocation == new_belly.name) //if the transfer location is to this belly
					new_belly.transferlocation = null

		if(isnum(belly_data["transferchance_secondary"]))
			var/new_transferchance_secondary = belly_data["transferchance_secondary"]
			new_belly.transferchance_secondary = sanitize_integer(new_transferchance_secondary, 0, 100, initial(new_belly.transferchance_secondary))

		if(istext(belly_data["transferlocation_secondary"]))
			var/new_transferlocation_secondary = sanitize(belly_data["transferlocation_secondary"],MAX_MESSAGE_LEN,0,0,0)
			if(new_transferlocation_secondary)
				for(var/obj/belly/existing_belly in host.vore_organs)
					if(existing_belly.name == new_transferlocation_secondary)
						new_belly.transferlocation_secondary = new_transferlocation_secondary
						break
				if(new_transferlocation_secondary in valid_names)
					new_belly.transferlocation_secondary = new_transferlocation_secondary
				if(new_transferlocation_secondary == new_belly.name)
					new_belly.transferlocation_secondary = null

		if(isnum(belly_data["absorbchance"]))
			var/new_absorbchance = belly_data["absorbchance"]
			new_belly.absorbchance = sanitize_integer(new_absorbchance, 0, 100, initial(new_belly.absorbchance))

		if(isnum(belly_data["digestchance"]))
			var/new_digestchance = belly_data["digestchance"]
			new_belly.digestchance = sanitize_integer(new_digestchance, 0, 100, initial(new_belly.digestchance))

		if(istext(belly_data["custom_reagentcolor"])) // Liquid bellies || RS Add || Chomp Port
			var/custom_reagentcolor = sanitize_hexcolor(belly_data["custom_reagentcolor"],new_belly.custom_reagentcolor)
			new_belly.custom_reagentcolor = custom_reagentcolor

		if(istext(belly_data["mush_color"]))
			var/mush_color = sanitize_hexcolor(belly_data["mush_color"],new_belly.mush_color)
			new_belly.mush_color = mush_color

		if(istext(belly_data["mush_alpha"]))
			var/new_mush_alpha = sanitize_integer(belly_data["mush_alpha"],0,255,initial(new_belly.mush_alpha))
			new_belly.mush_alpha = new_mush_alpha

		if(isnum(belly_data["max_mush"]))
			var/max_mush = belly_data["max_mush"]
			new_belly.max_mush = CLAMP(max_mush, 0, 6000)

		if(isnum(belly_data["min_mush"]))
			var/min_mush = belly_data["min_mush"]
			new_belly.min_mush = CLAMP(min_mush, 0, 100)

		if(isnum(belly_data["liquid_overlay"]))
			var/new_liquid_overlay = belly_data["liquid_overlay"]
			if(new_liquid_overlay == 0)
				new_belly.liquid_overlay = FALSE
			if(new_liquid_overlay == 1)
				new_belly.liquid_overlay = TRUE

		if(isnum(belly_data["max_liquid_level"]))
			var/max_liquid_level = belly_data["max_liquid_level"]
			new_belly.max_liquid_level = CLAMP(max_liquid_level, 0, 100)

		if(isnum(belly_data["mush_overlay"]))
			var/new_mush_overlay = belly_data["mush_overlay"]
			if(new_mush_overlay == 0)
				new_belly.mush_overlay = FALSE
			if(new_mush_overlay == 1)
				new_belly.mush_overlay = TRUE // End liquid bellies

		// After import updates
		new_belly.items_preserved.Cut()

	if(istype(host, /mob/living/carbon/human))
		var/mob/living/carbon/human/hhost = host
		hhost.update_fullness()
	host.updateVRPanel()
	unsaved_changes = TRUE

#undef IMPORT_ALL_BELLIES
#undef IMPORT_ONE_BELLY
