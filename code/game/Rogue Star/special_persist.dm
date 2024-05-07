//PLEASE NOTE, this system will only work correctly if the affected map lists are the same on every map load.
//If you load one map with one set of redgates, and another map with a different set, it won't matter what you saved
//you will just have told the system to load something that may or may not exist in the code at that time
//so keep the lists of anything we save here synced between all maps or it won't work right!

/datum/persistent/next_round_maps
	name = "next round maps"

/datum/persistent/next_round_maps/SetFilename()
	filename = ADMIN_CUSTOM_MAP_LOAD_PATH

/datum/persistent/next_round_maps/Shutdown()
	var/list/to_save = list()

	if(SSpersistence.redgate)
		to_save["Redgate"] = SSpersistence.redgate	//We're saving a string for the kind of thing, and a string for the specific selection as an associated list
	if(SSpersistence.gateway)						//Your map list needs to have the name you want saved as the index for the actual map names to be compatible
		to_save["Gateway"] = SSpersistence.gateway
	if(fexists(filename))	//Delete the file so we can save a new one
		log_debug("Removing previous round's custom map load data.")
		fdel(filename)
	if(!to_save.len)		//Nothing to save, let's just quit here
		log_debug("No custom map load data detected, aborting Shutdown function.")
		return

	log_debug("Saving custom map load data.")
	to_file(file(filename), json_encode(to_save))	//Save it as a json file!
	if(fexists(filename))	//Did we do it?
		log_debug("Saved custom map load data to [filename].")	//Nice
	else
		log_debug("Tried to save custom map load data to [filename], but something went wrong!")	//Don't ask me about this if it doesn't work I won't know why

/client/proc/pick_next_random_map()
	set name = "Pick Next Random Map"
	set category = "Fun"		//:)

	if(!check_rights(R_FUN)) return

	var/list/kinds = list(
		"Redgate",
		"Gateway"
		)

	var/which = tgui_input_list(usr, "Which pool will you pick from?", "Pick", kinds)

	switch(which)
		if("Redgate")
			if(SSpersistence.redgate)
				which = tgui_alert(usr, "[SSpersistence.redgate] is already selected to be loaded for next round. What would you like to do?", "Redgate", list("Select","Clear","Nothing"))
				switch(which)
					if("Nothing")
						return
					if("Clear")
						SSpersistence.redgate = null
						log_and_message_admins("has cleared next round's Redgate selection. It will now be randomly selected.")
						return
			which = tgui_input_list(usr, "Which Redgate map will you pick?", "Pick Redgate Map", using_map.lateload_redgate)
			if(!which)
				return
			SSpersistence.redgate = which
			log_and_message_admins("set next round's Redgate to [SSpersistence.redgate].")

		if("Gateway")
			if(SSpersistence.gateway)
				which = tgui_alert(usr, "[SSpersistence.gateway] is already selected to be loaded for next round. What would you like to do?", "Gateway", list("Select","Clear","Nothing"))
				switch(which)
					if("Nothing")
						return
					if("Clear")
						SSpersistence.gateway = null
						log_and_message_admins("has cleared next round's Gateway selection. It will now be randomly selected.")
						return
			which = tgui_input_list(usr, "Which Gateway map will you pick?", "Pick Gateway Map", using_map.lateload_gateway)
			if(!which)
				return
			SSpersistence.gateway = which
			log_and_message_admins("set next round's Gateway to [SSpersistence.gateway].")

	feedback_add_details("admin_verb","RS-PNRM") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
