///////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Admin tool for viewing etching data //
///////////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/admin/client_etching_viewer
	name = "Etching Viewer"
	tgui_id = "EtchingViewer"

	var/target_ckey = ""
	var/list/characters = list()
	var/list/character_cache = list()
	var/selected_character = null
	var/status_message = null
	var/error_message = null

/datum/tgui_module/admin/client_etching_viewer/tgui_state(mob/user)
	return GLOB.tgui_admin_state

/datum/tgui_module/admin/client_etching_viewer/tgui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, tgui_id, name, parent_ui)
		ui.open()
	ui.set_autoupdate(FALSE)
	SStgui.open_uis.Remove(ui)
	return ui

/datum/tgui_module/admin/client_etching_viewer/proc/reset_characters()
	characters = list()
	character_cache = list()
	selected_character = null

/datum/tgui_module/admin/client_etching_viewer/proc/get_save_directory(var/ckey_to_use)
	if(!ckey_to_use)
		return null
	return "data/player_saves/[copytext(ckey_to_use, 1, 2)]/[ckey_to_use]/magic/"

/datum/tgui_module/admin/client_etching_viewer/proc/load_ckey(var/new_ckey)
	new_ckey = ckey(new_ckey)
	target_ckey = new_ckey ? new_ckey : ""
	status_message = null
	error_message = null
	reset_characters()

	if(!new_ckey)
		error_message = "Please provide a valid ckey."
		return FALSE

	var/base_dir = get_save_directory(new_ckey)
	var/list/file_list
	if(base_dir)
		file_list = flist(base_dir)

	if(!file_list || !file_list.len)
		error_message = "No etching files found for [new_ckey]."
		return FALSE

	for(var/file_name in file_list)
		if(!file_name)
			continue
		var/end_char = copytext(file_name, length(file_name), length(file_name) + 1)
		if(end_char == "/")
			continue
		if(!findtext(file_name, "-etching.json"))
			continue
		var/list/entry = build_character_entry(base_dir, file_name)
		characters[file_name] = entry

	if(!characters.len)
		error_message = "No etching files found for [new_ckey]."
		return FALSE

	var/list/sorted_ids = get_sorted_character_ids()
	selected_character = sorted_ids.len ? sorted_ids[1] : null
	ensure_character_cached(selected_character, TRUE)

	status_message = "Loaded [characters.len] etching file[characters.len == 1 ? "" : "s"] for [new_ckey]."
	return TRUE

/datum/tgui_module/admin/client_etching_viewer/proc/build_character_entry(var/base_dir, var/file_name)
	var/list/entry = list()
	entry["file"] = file_name
	entry["path"] = "[base_dir][file_name]"

	var/display_name = replacetext(file_name, "-etching.json", "")
	var/event_suffix = "-EVENT"
	var/name_length = length(display_name)
	var/suffix_length = length(event_suffix)
	var/is_event = FALSE
	if(name_length >= suffix_length)
		var/check = copytext(display_name, name_length - suffix_length + 1, name_length + 1)
		if(check == event_suffix)
			is_event = TRUE
			display_name = copytext(display_name, 1, name_length - suffix_length + 1)
	entry["display_name"] = trim(display_name)
	entry["is_event"] = is_event
	return entry

/datum/tgui_module/admin/client_etching_viewer/proc/get_sorted_character_ids()
	var/list/ids = list()
	for(var/id in characters)
		ids += id
	return sortList(ids)

/datum/tgui_module/admin/client_etching_viewer/proc/ensure_character_cached(var/file_id, var/force = FALSE)
	if(!file_id || !(file_id in characters))
		return null
	if(force || !(file_id in character_cache))
		read_character_entry(file_id)
	return character_cache[file_id]

/datum/tgui_module/admin/client_etching_viewer/proc/read_character_entry(var/file_id)
	var/list/entry = characters[file_id]
	if(!entry)
		return

	var/list/detail = initialize_detail(entry)
	var/error_text = null
	var/raw_text

	if(!fexists(entry["path"]))
		error_text = "Etching file not found on disk."
	else
		try
			raw_text = file2text(entry["path"])
		catch(var/exception/E)
			error_text = "Unable to read etching file: [E]"

	if(!error_text && (!raw_text || !length(raw_text)))
		error_text = "Etching file for [entry["display_name"]] was empty."

	var/list/raw_data
	if(!error_text)
		try
			raw_data = json_decode(raw_text)
		catch(var/exception/E_json)
			error_text = "Failed to decode etching JSON: [E_json]"

	if(!error_text && !islist(raw_data))
		error_text = "Decoded etching data for [entry["display_name"]] was invalid."

	if(error_text)
		detail["rawJson"] = raw_text ? raw_text : ""
		detail["character_error"] = error_text
	else
		detail = build_character_detail(entry, raw_data, raw_text)

	character_cache[file_id] = list("detail" = detail)

/datum/tgui_module/admin/client_etching_viewer/proc/initialize_detail(var/list/entry)
	var/list/detail = list(
		"name" = entry["display_name"],
		"file" = entry["file"],
		"path" = entry["path"],
		"event" = entry["is_event"],
		"ckey" = target_ckey,
		"triangles" = 0,
		"xp" = list(),
		"itemStorage" = list(),
		"unlockables" = list(),
		"petData" = list(),
		"extras" = list(),
		"nif" = list(
			"type" = null,
			"durability" = null,
			"savedata" = list(),
			"raw" = ""
		),
		"meta" = list(
			"path" = entry["path"],
			"size" = 0
		),
		"rawJson" = "",
		"character_error" = null
	)
	return detail

/datum/tgui_module/admin/client_etching_viewer/proc/build_character_detail(var/list/entry, var/list/raw_data, var/raw_text)
	var/list/detail = initialize_detail(entry)

	if(isnum(raw_data["triangles"]))
		detail["triangles"] = raw_data["triangles"]

	var/list/xp_entries = list()
	if(islist(raw_data["xp"]))
		for(var/label in raw_data["xp"])
			xp_entries += list(list(
				"label" = "[label]",
				"value" = raw_data["xp"][label]
			))
	detail["xp"] = xp_entries

	var/list/item_entries = list()
	if(islist(raw_data["item_storage"]))
		for(var/item_name in raw_data["item_storage"])
			item_entries += list(list(
				"label" = "[item_name]",
				"type" = format_value(raw_data["item_storage"][item_name])
			))
	detail["itemStorage"] = item_entries

	var/list/unlockable_entries = list()
	if(islist(raw_data["unlockables"]))
		for(var/item in raw_data["unlockables"])
			unlockable_entries += list(list(
				"label" = "[item]",
				"type" = format_value(raw_data["unlockables"][item])
			))
	detail["unlockables"] = unlockable_entries

	var/list/nif = detail["nif"]
	nif["type"] = raw_data["nif_type"]
	nif["durability"] = raw_data["nif_durability"]
	var/list/nif_savedata_entries = list()
	if(islist(raw_data["nif_savedata"]))
		for(var/key in raw_data["nif_savedata"])
			nif_savedata_entries += list(list(
				"key" = "[key]",
				"value" = format_value(raw_data["nif_savedata"][key])
			))
	else if(raw_data["nif_savedata"])
		nif_savedata_entries += list(list(
			"key" = "value",
			"value" = format_value(raw_data["nif_savedata"])
		))
	nif["savedata"] = nif_savedata_entries
	nif["raw"] = format_value(raw_data["nif_savedata"])

	var/list/known_keys = list(
		"xp" = TRUE,
		"triangles" = TRUE,
		"item_storage" = TRUE,
		"unlockables" = TRUE,
		"nif_type" = TRUE,
		"nif_durability" = TRUE,
		"nif_savedata" = TRUE
	)

	var/list/extra_entries = list()
	for(var/key in raw_data)
		if(known_keys[key])
			continue
		var/value_text = format_value(raw_data[key])
		var/list/row = list(
			"key" = "[key]",
			"value" = value_text
		)
		extra_entries += row
	detail["extras"] = extra_entries

	if(istext(raw_text))
		detail["rawJson"] = raw_text
		detail["meta"]["size"] = length(raw_text)

	return detail

/datum/tgui_module/admin/client_etching_viewer/proc/format_value(var/value)
	if(isnull(value))
		return "null"
	if(istext(value))
		return value
	if(isnum(value))
		return "[value]"
	if(ispath(value))
		return "[value]"
	if(islist(value))
		try
			return json_encode(value)
		catch
			return "[value]"
	return "[value]"

/datum/tgui_module/admin/client_etching_viewer/proc/get_online_ckeys()
	var/list/seen = list()
	for(var/client/C in GLOB.clients)
		if(!C || !C.ckey)
			continue
		var/online_ckey = ckey(C.ckey)
		if(!online_ckey)
			continue
		seen[online_ckey] = TRUE
	var/list/result = list()
	for(var/name in seen)
		result += name
	return sortList(result)

/datum/tgui_module/admin/client_etching_viewer/tgui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE

	switch(action)
		if("load_ckey")
			var/input_ckey = params["ckey"]
			load_ckey(input_ckey)
			return TRUE

		if("prompt_ckey")
			var/default_value = target_ckey ? target_ckey : ""
			var/input = tgui_input_text(usr, "Enter a player's ckey.", "Etching Viewer", default = default_value)
			if(input)
				load_ckey(input)
			return TRUE

		if("clear_ckey")
			target_ckey = ""
			reset_characters()
			status_message = null
			error_message = null
			return TRUE

		if("select_character")
			var/file_id = params["file"]
			if(!(file_id in characters))
				return TRUE
			selected_character = file_id
			ensure_character_cached(selected_character, TRUE)
			status_message = "Selected [characters[file_id]["display_name"]]."
			return TRUE

		if("refresh_character")
			var/file_to_refresh = params["file"] || selected_character
			if(!(file_to_refresh in characters))
				return TRUE
			ensure_character_cached(file_to_refresh, TRUE)
			status_message = "Reloaded [characters[file_to_refresh]["display_name"]]."
			return TRUE

	return FALSE

/datum/tgui_module/admin/client_etching_viewer/tgui_data(mob/user)
	var/list/data = list()
	data["target_ckey"] = target_ckey
	data["status"] = status_message
	data["error"] = error_message
	data["online_ckeys"] = get_online_ckeys()

	var/list/character_rows = list()
	var/list/sorted_ids = get_sorted_character_ids()
	for(var/id in sorted_ids)
		var/list/entry = characters[id]
		character_rows += list(list(
			"file" = id,
			"name" = entry["display_name"],
			"event" = entry["is_event"],
			"path" = entry["path"]
		))
	data["characters"] = character_rows
	data["selected_file"] = selected_character

	if(selected_character && (selected_character in characters))
		var/list/cache = ensure_character_cached(selected_character)
		if(cache)
			data["detail"] = cache["detail"]

	return data
