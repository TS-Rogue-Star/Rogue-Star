///////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Pet Register Interface //
///////////////////////////////////////////////////////////////////////////

/datum/pet_register_session
	var/datum/weakref/etching_ref
	var/datum/weakref/candidate
	var/candidate_token = 0
	var/candidate_portrait
	var/list/legacy
	var/legacy_slot_mismatch = FALSE
	var/legacy_load_failed = FALSE
	var/message
	var/message_error = FALSE
	var/result_id = 0
	var/saved_name

/datum/pet_register_session/Destroy()
	etching_ref = null
	candidate = null
	legacy = null
	return ..()

/obj/machinery/mob_bank
	var/pet_opening_sound = "sound/rogue-star/pet_bank.mp3"
	var/list/pet_sessions = list()
	var/static/list/pet_operations = list()
	var/operation_key
	var/operation_text
	var/operation_started = 0

/obj/machinery/mob_bank/Destroy()
	end_pet_operation()
	SStgui.close_uis(src)
	for(var/session_key in pet_sessions)
		qdel(pet_sessions[session_key])
	pet_sessions = null
	return ..()

/obj/machinery/mob_bank/proc/can_use_pet_register(mob/living/user, announce = FALSE)
	if(!ishuman(user) || !user.client || !user.ckey || IsGuestKey(user.key) || !user.etching || !Adjacent(user) || user.incapacitated())
		return FALSE
	if(inoperable() || panel_open)
		if(announce)
			to_chat(user, SPAN_WARNING("\The [src] seems to be nonfunctional..."))
		return FALSE
	return TRUE

/obj/machinery/mob_bank/tgui_state(mob/user)
	return GLOB.tgui_physical_state

/obj/machinery/mob_bank/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!can_use_pet_register(user))
		return
	get_pet_session(user)
	if(!ui)
		ui = new(user, src, "PetRegister", "PET System")
		ui.open()
		if(ui.window)
			user.playsound_local(get_turf(src), pet_opening_sound, 50, FALSE)

/obj/machinery/mob_bank/tgui_close(mob/user)
	var/session_key = REF(user)
	var/datum/pet_register_session/session = pet_sessions[session_key]
	pet_sessions.Remove(session_key)
	qdel(session)
	return ..()

/obj/machinery/mob_bank/proc/get_pet_session(mob/living/user)
	var/session_key = REF(user)
	var/datum/pet_register_session/session = pet_sessions[session_key]
	if(session && session.etching_ref?.resolve() != user.etching)
		qdel(session)
		session = null
	if(!session)
		session = new
		session.etching_ref = WEAKREF(user.etching)
		session.legacy = read_legacy_pet(user, session)
		pet_sessions[session_key] = session
	return session

/obj/machinery/mob_bank/proc/pet_result(datum/pet_register_session/session, message, failed = FALSE, saved_name)
	if(!QDELETED(session))
		session.message = message
		session.message_error = failed
		session.result_id++
		session.saved_name = saved_name
	if(!QDELETED(src))
		if(failed)
			visible_message(SPAN_WARNING("\The [src] boops sadly..."), runemessage = "boop...")
		SStgui.update_uis(src)

/obj/machinery/mob_bank/proc/pet_candidate_valid(mob/living/user, mob/living/simple_mob/M)
	if(!istype(M) || QDELETED(M) || !Adjacent(M) || !user.Adjacent(M) || !isturf(M.loc))
		return FALSE
	return M.save_conditions(user)

/obj/machinery/mob_bank/proc/is_registered_pet(mob/living/user, mob/living/simple_mob/M)
	if(!M || M.load_owner != user.ckey)
		return FALSE
	var/list/record = LAZYACCESS(user.etching.pet_data, M.registered_pet_name)
	return islist(record) && record["type"] == "[M.registered_pet_type ? M.registered_pet_type : M.type]"

/obj/machinery/mob_bank/proc/offer_pet_candidate(mob/living/user, mob/living/simple_mob/M)
	if(!can_use_pet_register(user, TRUE))
		return
	var/datum/pet_register_session/session = get_pet_session(user)
	if(operation_key || pet_operation_active(user.ckey))
		pet_result(session, "Please wait for the current scan to finish.", TRUE)
	else if(!pet_candidate_valid(user, M))
		pet_result(session, "This creature cannot be registered or stored. Check that it is nearby, eligible, and belongs to you.", TRUE)
	else
		session.candidate = WEAKREF(M)
		session.candidate_token++
		session.candidate_portrait = icon2base64(getFlatIcon(M, SOUTH, no_anim = TRUE))
		session.message = null
	tgui_interact(user)

/obj/machinery/mob_bank/proc/pet_operation_active(account_key)
	var/datum/weakref/active = pet_operations[account_key]
	if(active?.resolve())
		return TRUE
	pet_operations.Remove(account_key)
	return FALSE

/obj/machinery/mob_bank/proc/begin_pet_operation(mob/living/user, label)
	if(operation_key || pet_operation_active(user.ckey))
		return FALSE
	operation_key = user.ckey
	pet_operations[operation_key] = WEAKREF(src)
	operation_text = label
	operation_started = world.time
	begin_use(10)
	SStgui.update_uis(src)
	return TRUE

/obj/machinery/mob_bank/proc/end_pet_operation()
	if(operation_key)
		var/datum/weakref/active = pet_operations[operation_key]
		if(active == weak_reference)
			pet_operations.Remove(operation_key)
	operation_key = null
	operation_text = null
	operation_started = 0
	stop_use()

/obj/machinery/mob_bank/proc/pet_entry(pet_name, list/record, active = FALSE, legacy = FALSE)
	var/pet_type = islist(record) ? pet_register_type(record["type"]) : null
	return list(
		"id" = legacy ? "legacy" : "saved:[pet_name]",
		"name" = pet_name,
		"species" = pet_type ? initial(pet_type:name) : "Unknown creature",
		"portrait" = pet_type ? pet_register_portrait(record) : null,
		"note" = islist(record) && istext(record["note"]) ? record["note"] : "",
		"active" = active,
		"legacy" = legacy,
		"valid" = !!pet_type
	)

/obj/machinery/mob_bank/tgui_data(mob/user)
	var/list/data = list()
	if(!ishuman(user) || !user.etching)
		return data
	var/datum/etching/E = user.etching
	var/datum/pet_register_session/session = get_pet_session(user)
	var/list/entries = list()
	if(islist(E.pet_data))
		for(var/pet_name in sortList(E.pet_data))
			entries += list(pet_entry(pet_name, E.pet_data[pet_name], pet_name == E.loaded_pet))
	if(session.legacy)
		entries += list(pet_entry(session.legacy["name"], session.legacy, FALSE, TRUE))
	data["pets"] = entries
	data["legacySlotMismatch"] = session.legacy_slot_mismatch
	data["legacyLoadFailed"] = session.legacy_load_failed
	data["characterName"] = user.real_name
	data["revision"] = E.pet_revision
	data["slots"] = max(1, E.pet_slots)
	data["maxSlots"] = 10
	data["usedSlots"] = LAZYLEN(E.pet_data)
	data["triangles"] = E.triangles
	data["slotCost"] = max(1, E.pet_slots) * 5
	data["nameLimit"] = PET_NAME_MAX
	data["noteLimit"] = 500
	data["retrievalBlocked"] = E.loaded_pet || (user.ckey in mob_takers)
	data["registrationUsed"] = (user.ckey in mob_savers)
	data["sessionOnly"] = E.event_character
	data["busy"] = !!operation_key || pet_operation_active(user.ckey)
	data["operation"] = operation_text
	data["progress"] = operation_key ? clamp((world.time - operation_started) / (10 SECONDS), 0, 1) : 0
	data["message"] = session.message
	data["messageError"] = session.message_error
	data["resultId"] = session.result_id
	data["savedName"] = session.saved_name
	data["candidate"] = null
	var/mob/living/simple_mob/M = session.candidate?.resolve()
	if(M && Adjacent(M) && user.Adjacent(M))
		data["candidate"] = list(
			"token" = session.candidate_token,
			"name" = M.name,
			"species" = initial(M.name),
			"portrait" = session.candidate_portrait,
			"registered" = is_registered_pet(user, M),
			"stationAllowed" = !M.load_owner
		)
	else
		session.candidate = null
	return data

/obj/machinery/mob_bank/tgui_act(action, list/params, datum/tgui/ui)
	if(..())
		if(ui?.user)
			pet_result(pet_sessions[REF(ui.user)], "You can no longer interact with the PET System. Move closer and try again.", TRUE)
		return TRUE
	var/mob/living/user = ui.user
	if(!can_use_pet_register(user))
		pet_result(pet_sessions[REF(user)], "Stand beside a working PET System with its maintenance panel closed.", TRUE)
		return TRUE
	var/datum/pet_register_session/session = get_pet_session(user)
	var/datum/etching/E = user.etching
	if(action == "cancel_candidate")
		session.candidate = null
		session.candidate_token++
		return TRUE
	if(operation_key || pet_operation_active(user.ckey))
		pet_result(session, "Another pet operation is in progress. Please wait.", TRUE)
		return TRUE
	if(params["revision"] != E.pet_revision)
		pet_result(session, "Your pet records changed. Review the current details and try again.", TRUE)
		return TRUE
	switch(action)
		if("save_details")
			var/new_name = pet_register_clean_name(params["newName"])
			var/new_note = params["note"]
			if(!istext(new_note) || length(new_note) > 500 || !new_name)
				pet_result(session, "Please enter a name of 1 to 25 characters and a note of at most 500 characters.", TRUE)
				return TRUE
			new_note = length(new_note) ? sanitize(new_note, 0, encode = FALSE, trim = FALSE) : ""
			if(!E.manage_pets(params["name"], new_name, new_note, params["revision"]))
				pet_result(session, "The details could not be saved. Names must be unique and the pet must be in storage.", TRUE)
			else
				pet_result(session, "Pet details saved.", FALSE, new_name)
		if("purchase_slot")
			if(!params["confirm"] || !E.purchase_pet_slot(params["cost"]))
				pet_result(session, "Storage could not be expanded. Check your balance, the current price, and the slot limit.", TRUE)
			else
				visible_message(SPAN_NOTICE("\The [src] pings happily!"), runemessage = "Ping!")
				pet_result(session, "Your pet storage has been expanded.")
		if("retrieve", "retrieve_legacy", "register", "store")
			if(!params["confirm"])
				return TRUE
			var/label = (action == "retrieve" || action == "retrieve_legacy") ? "Retrieving your pet" : (action == "store" ? "Returning your pet to storage" : "Scanning your pet")
			if(begin_pet_operation(user, label))
				run_pet_operation(user, session, action, params.Copy())
	return TRUE

/obj/machinery/mob_bank/proc/run_pet_operation(mob/living/user, datum/pet_register_session/session, action, list/params)
	set waitfor = FALSE
	var/success = FALSE
	var/mob/living/simple_mob/scanned_pet
	var/failure = "The scan was interrupted. Stay beside the machine and keep your pet nearby."
	try
		var/valid_operation = pet_operation_valid(user, session, action, params)
		if(valid_operation && action == "register")
			scanned_pet = session.candidate?.resolve()
			visible_message(SPAN_NOTICE("\The [src] scans \the [scanned_pet] thoroughly..."), runemessage = "wrrr...")
		if(valid_operation && do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) && pet_operation_valid(user, session, action, params))
			failure = "The operation could not be completed. Your existing pet records have been kept."
			switch(action)
				if("retrieve")
					success = !!persist_mob_load(user, params["name"])
				if("retrieve_legacy")
					var/list/record = read_legacy_pet(user, session)
					var/pet_name = record["name"]
					var/list/next_data = islist(user.etching.pet_data) ? user.etching.pet_data.Copy() : list()
					if(params["replacement"])
						next_data.Remove(params["replacement"])
					next_data[pet_name] = record.Copy()
					if(user.etching.pet_commit(next_data, max(1, user.etching.pet_slots), user.etching.triangles))
						if(!user.etching.event_character)
							fdel(persist_mob_savefile_path(user))
						session.legacy = null
						success = !!persist_mob_load(user, pet_name)
				if("register", "store")
					var/mob/living/simple_mob/M = session.candidate?.resolve()
					success = persist_mob_save(user, M, pet_register_clean_name(params["name"]), action == "store" ? "store" : params["destination"], params["replacement"])
					if(success)
						session.candidate = null
						session.candidate_token++
	catch(var/exception/error)
		success = FALSE
		log_runtime(error, src, "PET operation failed: [action]")
		failure = "The PET System could not finish this operation. Please try again."
	if(!QDELETED(src))
		end_pet_operation()
		if(success)
			if(action == "register")
				visible_message(SPAN_NOTICE("\The [src] pings happily as it finishes scanning \the [scanned_pet]!"), runemessage = "Ping!")
			else
				visible_message(SPAN_NOTICE("\The [src] pings happily!"), runemessage = "Ping!")
		pet_result(session, success ? "All done. Your pet's record is up to date." : failure, !success)

/obj/machinery/mob_bank/proc/pet_operation_valid(mob/living/user, datum/pet_register_session/session, action, list/params)
	if(QDELETED(src) || QDELETED(user) || QDELETED(session) || pet_sessions[REF(user)] != session || !can_use_pet_register(user))
		return FALSE
	var/datum/etching/E = user.etching
	if(session.etching_ref?.resolve() != E || params["revision"] != E.pet_revision)
		return FALSE
	if(action == "retrieve" || action == "retrieve_legacy")
		if(E.loaded_pet || (user.ckey in mob_takers))
			return FALSE
		if(action == "retrieve_legacy")
			var/list/record = read_legacy_pet(user, session)
			return islist(record) && islist(session.legacy) && json_encode(record) == json_encode(session.legacy) && E.pet_replacement_valid(record["name"], params["replacement"])
		if(!istext(params["name"]))
			return FALSE
		var/list/record = LAZYACCESS(E.pet_data, params["name"])
		return islist(record) && !!pet_register_type(record["type"])
	var/mob/living/simple_mob/M = session.candidate?.resolve()
	if(params["token"] != session.candidate_token || !pet_candidate_valid(user, M))
		return FALSE
	if(action == "store")
		return is_registered_pet(user, M)
	if(action != "register" || (user.ckey in mob_savers) || !pet_register_clean_name(params["name"]))
		return FALSE
	if(params["destination"] == "station")
		return !M.load_owner
	return params["destination"] == "personal" && !(user.ckey in mob_takers) && !E.loaded_pet && E.pet_replacement_valid(pet_register_clean_name(params["name"]), params["replacement"])

/proc/pet_register_name_valid(value)
	return istext(value) && length(trim(value)) > 0 && length(value) <= PET_NAME_MAX

/proc/pet_register_clean_name(value)
	if(!pet_register_name_valid(value))
		return null
	return trim(replacetext(sanitize(value, 0, encode = FALSE), "\n", " "))

/proc/pet_register_type(value)
	if(istext(value))
		value = text2path(value)
	return ispath(value, /mob/living/simple_mob) ? value : null
