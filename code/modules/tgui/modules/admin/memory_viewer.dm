////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star May 2026: Admin tool for viewing character memories //
////////////////////////////////////////////////////////////////////////////////////////

#define MEMORY_VIEWER_EVENT_DETAIL_SEPARATOR "||"
#define MEMORY_VIEWER_NOTE_LIMIT 4000

/datum/tgui_module/admin/client_memory_viewer
	name = "Memory Viewer"
	tgui_id = "MemoryViewer"

	var/target_ckey = ""
	var/list/characters = list()
	var/list/character_cache = list()
	var/selected_character = null
	var/selected_contact = null
	var/status_message = null
	var/error_message = null

/datum/tgui_module/admin/client_memory_viewer/tgui_state(mob/user)
	return GLOB.tgui_admin_state

/datum/tgui_module/admin/client_memory_viewer/tgui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, tgui_id, name, parent_ui)
		ui.open()
	ui.set_autoupdate(FALSE)
	SStgui.open_uis.Remove(ui)
	return ui

/datum/tgui_module/admin/client_memory_viewer/proc/reset_characters()
	characters = list()
	character_cache = list()
	selected_character = null
	selected_contact = null

/datum/tgui_module/admin/client_memory_viewer/proc/get_save_directory(var/ckey_to_use)
	if(!ckey_to_use)
		return null
	return "data/player_saves/[copytext(ckey_to_use, 1, 2)]/[ckey_to_use]/magic/"

/datum/tgui_module/admin/client_memory_viewer/proc/is_memory_database_file(var/file_name)
	if(!file_name)
		return FALSE
	var/suffix = "-memory.db"
	var/file_length = length(file_name)
	var/suffix_length = length(suffix)
	if(file_length < suffix_length)
		return FALSE
	return copytext(file_name, file_length - suffix_length + 1, file_length + 1) == suffix

/datum/tgui_module/admin/client_memory_viewer/proc/load_ckey(var/new_ckey)
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
		error_message = "No memory files found for [new_ckey]."
		return FALSE

	for(var/file_name in file_list)
		if(!file_name)
			continue
		var/end_char = copytext(file_name, length(file_name), length(file_name) + 1)
		if(end_char == "/")
			continue
		if(!is_memory_database_file(file_name))
			continue
		var/list/entry = build_character_entry(base_dir, file_name)
		characters[file_name] = entry

	if(!characters.len)
		error_message = "No memory files found for [new_ckey]."
		return FALSE

	var/list/sorted_ids = get_sorted_character_ids()
	selected_character = sorted_ids.len ? sorted_ids[1] : null
	ensure_character_cached(selected_character, TRUE)

	status_message = "Loaded [characters.len] memory file[characters.len == 1 ? "" : "s"] for [new_ckey]."
	return TRUE

/datum/tgui_module/admin/client_memory_viewer/proc/build_character_entry(var/base_dir, var/file_name)
	var/list/entry = list()
	entry["file"] = file_name
	entry["path"] = "[base_dir][file_name]"

	var/display_name = replacetext(file_name, "-memory.db", "")
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

/datum/tgui_module/admin/client_memory_viewer/proc/get_sorted_character_ids()
	var/list/ids = list()
	for(var/id in characters)
		ids += id
	return sortList(ids)

/datum/tgui_module/admin/client_memory_viewer/proc/ensure_character_cached(var/file_id, var/force = FALSE)
	if(!file_id || !(file_id in characters))
		return null
	if(force || !(file_id in character_cache))
		read_character_entry(file_id)
	return character_cache[file_id]

/datum/tgui_module/admin/client_memory_viewer/proc/build_database_query(var/query_data)
	var/database/query/query
	if(islist(query_data))
		query = new(arglist(query_data))
	else
		query = new(query_data)
	if(!istype(query))
		return null
	return query

/datum/tgui_module/admin/client_memory_viewer/proc/database_query_failed(var/database/query/query, var/context)
	if(!query)
		error_message = "Memory viewer database query failed to build: [context]."
		return TRUE
	if(query.Error())
		error_message = "Memory viewer database error while [context]: [query.ErrorMsg()]"
		return TRUE
	return FALSE

/datum/tgui_module/admin/client_memory_viewer/proc/execute_database_query(var/database/memory_db, var/query_data, var/context)
	if(!memory_db)
		error_message = "Memory viewer database was not open while [context]."
		return null
	var/database/query/query = build_database_query(query_data)
	if(!query)
		database_query_failed(query, context)
		return null
	try
		query.Execute(memory_db)
	catch(var/exception/E)
		error_message = "Memory viewer database exception while [context]: [E]"
		return null
	if(database_query_failed(query, context))
		return null
	var/list/results = list()
	while(query.NextRow())
		results[++results.len] = query.GetRowData()
	return results

/datum/tgui_module/admin/client_memory_viewer/proc/execute_database_update(var/database/memory_db, var/query_data, var/context)
	if(!memory_db)
		error_message = "Memory viewer database was not open while [context]."
		return FALSE
	var/database/query/query = build_database_query(query_data)
	if(!query)
		database_query_failed(query, context)
		return FALSE
	try
		query.Execute(memory_db)
	catch(var/exception/E)
		error_message = "Memory viewer database exception while [context]: [E]"
		return FALSE
	if(database_query_failed(query, context))
		return FALSE
	return TRUE

/datum/tgui_module/admin/client_memory_viewer/proc/read_character_entry(var/file_id)
	var/list/entry = characters[file_id]
	if(!entry)
		return

	var/list/detail = initialize_detail(entry)
	var/error_text = null
	var/database/memory_db
	error_message = null

	if(!fexists(entry["path"]))
		error_text = "Memory file not found on disk."
	else
		try
			memory_db = new(entry["path"])
		catch(var/exception/E)
			error_text = "Unable to open memory database: [E]"

	if(!error_text && !memory_db)
		error_text = "Unable to open memory database."

	var/list/meta_rows
	var/list/contact_rows
	var/list/first_met_rows
	var/list/day_count_rows
	var/list/total_count_rows
	var/list/total_rows
	var/list/daily_rows
	if(!error_text)
		meta_rows = execute_database_query(memory_db, "SELECT name, value FROM meta ORDER BY name", "load memory metadata")
		contact_rows = execute_database_query(memory_db, "SELECT contact_id, display_name, last_seen, notes FROM contacts ORDER BY lower(display_name), lower(contact_id)", "load memory contacts")
		first_met_rows = execute_database_query(memory_db, "SELECT contact_id, MIN(date_key) AS first_met FROM daily_counts GROUP BY contact_id", "load first-met dates")
		day_count_rows = execute_database_query(memory_db, "SELECT contact_id, COUNT(DISTINCT date_key) AS day_count FROM daily_counts GROUP BY contact_id", "load contact day counts")
		total_count_rows = execute_database_query(memory_db, "SELECT contact_id, SUM(amount) AS total_count FROM total_counts GROUP BY contact_id", "load contact total counts")
		total_rows = execute_database_query(memory_db, "SELECT contact_id, event_key, role_key, amount FROM total_counts ORDER BY contact_id, event_key, role_key", "load memory totals")
		daily_rows = execute_database_query(memory_db, "SELECT contact_id, date_key, event_key, role_key, amount FROM daily_counts ORDER BY contact_id, date_key DESC, event_key, role_key", "load daily memory")
		if(error_message)
			error_text = error_message

	if(!error_text)
		if(!islist(meta_rows) || !islist(contact_rows) || !islist(first_met_rows) || !islist(day_count_rows) || !islist(total_count_rows) || !islist(total_rows) || !islist(daily_rows))
			error_text = "Memory database did not return expected tables."
		else
			detail = build_character_detail(entry, meta_rows, contact_rows, first_met_rows, day_count_rows, total_count_rows, total_rows, daily_rows)

	memory_db = null

	if(error_text)
		detail["character_error"] = error_text

	character_cache[file_id] = list("detail" = detail)

	var/list/contact_list = detail["contacts"]
	var/list/contact_details = detail["contact_details"]
	if(islist(contact_list) && contact_list.len && (!selected_contact || !islist(contact_details) || !(selected_contact in contact_details)))
		var/list/first_contact = contact_list[1]
		selected_contact = first_contact["contact_id"]

/datum/tgui_module/admin/client_memory_viewer/proc/initialize_detail(var/list/entry)
	var/list/detail = list(
		"name" = entry["display_name"],
		"file" = entry["file"],
		"path" = entry["path"],
		"event" = entry["is_event"],
		"ckey" = target_ckey,
		"owner" = null,
		"schema_version" = null,
		"metaRows" = list(),
		"contacts" = list(),
		"contact_details" = list(),
		"duplicateGroups" = list(),
		"selected_contact" = null,
		"contact_detail" = null,
		"character_error" = null
	)
	return detail

/datum/tgui_module/admin/client_memory_viewer/proc/build_contact_value_lookup(var/list/rows, var/value_key)
	var/list/lookup = list()
	for(var/list/row as anything in rows)
		var/contact_id = row["contact_id"]
		if(!contact_id)
			continue
		lookup["[contact_id]"] = row[value_key]
	return lookup

/datum/tgui_module/admin/client_memory_viewer/proc/get_contact_ckey(var/contact_id)
	if(!contact_id)
		return ""
	var/pipe_position = findtext(contact_id, "|")
	if(!pipe_position)
		return ""
	return copytext(contact_id, 1, pipe_position)

/datum/tgui_module/admin/client_memory_viewer/proc/get_contact_character_name(var/contact_id)
	if(!contact_id)
		return ""
	var/pipe_position = findtext(contact_id, "|")
	if(!pipe_position)
		return "[contact_id]"
	return copytext(contact_id, pipe_position + 1)

/datum/tgui_module/admin/client_memory_viewer/proc/normalize_memory_contact_ckey(var/contact_ckey)
	if(!contact_ckey)
		return ""
	var/raw_ckey = lowertext(trim("[contact_ckey]"))
	if(copytext(raw_ckey, 1, 2) != "@")
		return raw_ckey
	var/normalized_ckey = ckey(copytext(raw_ckey, 2))
	if(!normalized_ckey)
		return raw_ckey
	return normalized_ckey

/datum/tgui_module/admin/client_memory_viewer/proc/normalize_memory_contact_id(var/contact_id)
	if(!contact_id)
		return null
	var/raw_contact_id = "[contact_id]"
	var/pipe_position = findtext(raw_contact_id, "|")
	if(!pipe_position)
		return raw_contact_id
	var/contact_ckey = copytext(raw_contact_id, 1, pipe_position)
	if(copytext(contact_ckey, 1, 2) != "@")
		return raw_contact_id
	var/normalized_ckey = ckey(copytext(contact_ckey, 2))
	if(!normalized_ckey)
		return raw_contact_id
	return "[normalized_ckey]|[copytext(raw_contact_id, pipe_position + 1)]"

/datum/tgui_module/admin/client_memory_viewer/proc/get_duplicate_key(var/contact_ckey, var/contact_name)
	var/normalized_ckey = normalize_memory_contact_ckey(contact_ckey)
	var/normalized_name = lowertext(trim("[contact_name]"))
	if(!normalized_ckey || !normalized_name)
		return null
	return "[normalized_ckey]|[normalized_name]"

/datum/tgui_module/admin/client_memory_viewer/proc/merge_memory_notes(var/current_notes, var/incoming_notes, var/source_contact_id)
	if(isnull(current_notes))
		current_notes = ""
	if(isnull(incoming_notes))
		incoming_notes = ""
	current_notes = "[current_notes]"
	incoming_notes = "[incoming_notes]"
	if(!incoming_notes)
		return current_notes
	if(!current_notes || current_notes == incoming_notes)
		return incoming_notes
	var/merge_header = "Merged duplicate memory note from [source_contact_id]:"
	if(findtext(current_notes, merge_header) && findtext(current_notes, incoming_notes))
		return current_notes
	var/merged_notes = "[current_notes]\n\n[merge_header]\n[incoming_notes]"
	return copytext(merged_notes, 1, MEMORY_VIEWER_NOTE_LIMIT + 1)

/datum/tgui_module/admin/client_memory_viewer/proc/ensure_consolidated_contact(var/list/consolidated_contacts, var/contact_id, var/raw_contact_id, var/display_name, var/last_seen, var/notes)
	if(!contact_id || !islist(consolidated_contacts))
		return null
	if(!raw_contact_id)
		raw_contact_id = contact_id
	var/list/contact = consolidated_contacts[contact_id]
	var/new_contact = FALSE
	if(!islist(contact))
		new_contact = TRUE
		var/fallback_name = get_contact_character_name(contact_id)
		if(!fallback_name)
			fallback_name = contact_id
		contact = list(
			"contact_id" = contact_id,
			"display_name" = fallback_name,
			"last_seen" = null,
			"notes" = ""
		)
		consolidated_contacts[contact_id] = contact
	if(!isnull(display_name))
		var/display_name_text = "[display_name]"
		if(display_name_text && (new_contact || raw_contact_id == contact_id || !contact["display_name"] || contact["display_name"] == contact_id))
			contact["display_name"] = display_name_text
	if(!isnull(last_seen))
		var/incoming_last_seen = "[last_seen]"
		var/current_last_seen = contact["last_seen"]
		if(!current_last_seen || sorttext("[current_last_seen]", incoming_last_seen) > 0)
			contact["last_seen"] = incoming_last_seen
	if(!isnull(notes))
		contact["notes"] = merge_memory_notes(contact["notes"], notes, raw_contact_id)
	if(isnull(contact["notes"]))
		contact["notes"] = ""
	if(isnull(contact["display_name"]))
		contact["display_name"] = contact_id
	return contact

/datum/tgui_module/admin/client_memory_viewer/proc/insert_consolidated_daily_count(var/database/memory_db, var/list/daily_row, var/contact_id)
	if(!memory_db || !islist(daily_row) || !contact_id)
		return FALSE
	var/date_key = daily_row["date_key"]
	var/event_key = daily_row["event_key"]
	var/role_key = daily_row["role_key"]
	if(!date_key || !event_key || !role_key)
		return TRUE
	var/amount = normalize_count(daily_row["amount"])
	if(!execute_database_update(memory_db, list("INSERT OR IGNORE INTO daily_counts (contact_id, date_key, event_key, role_key, amount) VALUES (?, ?, ?, ?, 0)", contact_id, date_key, event_key, role_key), "ensure consolidated memory daily count"))
		return FALSE
	return execute_database_update(memory_db, list("UPDATE daily_counts SET amount = amount + ? WHERE contact_id = ? AND date_key = ? AND event_key = ? AND role_key = ?", amount, contact_id, date_key, event_key, role_key), "update consolidated memory daily count")

/datum/tgui_module/admin/client_memory_viewer/proc/insert_consolidated_total_count(var/database/memory_db, var/list/total_row, var/contact_id)
	if(!memory_db || !islist(total_row) || !contact_id)
		return FALSE
	var/event_key = total_row["event_key"]
	var/role_key = total_row["role_key"]
	if(!event_key || !role_key)
		return TRUE
	var/amount = normalize_count(total_row["amount"])
	if(!execute_database_update(memory_db, list("INSERT OR IGNORE INTO total_counts (contact_id, event_key, role_key, amount) VALUES (?, ?, ?, 0)", contact_id, event_key, role_key), "ensure consolidated memory total count"))
		return FALSE
	return execute_database_update(memory_db, list("UPDATE total_counts SET amount = amount + ? WHERE contact_id = ? AND event_key = ? AND role_key = ?", amount, contact_id, event_key, role_key), "update consolidated memory total count")

/datum/tgui_module/admin/client_memory_viewer/proc/consolidate_character_file(var/file_id)
	if(!file_id || !(file_id in characters))
		error_message = "Select a memory file before consolidating."
		return FALSE

	var/list/entry = characters[file_id]
	error_message = null
	status_message = null
	selected_character = file_id

	if(!fexists(entry["path"]))
		error_message = "Memory file not found on disk."
		return FALSE

	var/database/memory_db
	try
		memory_db = new(entry["path"])
	catch(var/exception/E)
		error_message = "Unable to open memory database: [E]"
		return FALSE
	if(!memory_db)
		error_message = "Unable to open memory database."
		return FALSE

	var/list/contact_rows = execute_database_query(memory_db, "SELECT contact_id, display_name, last_seen, notes FROM contacts", "load contacts for memory consolidation")
	var/list/daily_rows = execute_database_query(memory_db, "SELECT contact_id, date_key, event_key, role_key, amount FROM daily_counts", "load daily counts for memory consolidation")
	var/list/total_rows = execute_database_query(memory_db, "SELECT contact_id, event_key, role_key, amount FROM total_counts", "load total counts for memory consolidation")
	if(error_message || !islist(contact_rows) || !islist(daily_rows) || !islist(total_rows))
		if(!error_message)
			error_message = "Memory database did not return expected tables."
		memory_db = null
		return FALSE

	var/list/consolidated_contacts = list()
	var/normalized_contact_rows = 0
	var/normalized_daily_rows = 0
	var/normalized_total_rows = 0

	for(var/list/contact_row as anything in contact_rows)
		var/raw_contact_id_value = contact_row["contact_id"]
		if(!raw_contact_id_value)
			continue
		var/raw_contact_id = "[raw_contact_id_value]"
		var/contact_id = normalize_memory_contact_id(raw_contact_id)
		if(contact_id != raw_contact_id)
			normalized_contact_rows++
		ensure_consolidated_contact(consolidated_contacts, contact_id, raw_contact_id, contact_row["display_name"], contact_row["last_seen"], contact_row["notes"])

	for(var/list/daily_row as anything in daily_rows)
		var/raw_daily_contact_value = daily_row["contact_id"]
		if(!raw_daily_contact_value)
			continue
		var/raw_daily_contact_id = "[raw_daily_contact_value]"
		var/daily_contact_id = normalize_memory_contact_id(raw_daily_contact_id)
		if(daily_contact_id != raw_daily_contact_id)
			normalized_daily_rows++
		ensure_consolidated_contact(consolidated_contacts, daily_contact_id, raw_daily_contact_id, null, null, null)

	for(var/list/total_row as anything in total_rows)
		var/raw_total_contact_value = total_row["contact_id"]
		if(!raw_total_contact_value)
			continue
		var/raw_total_contact_id = "[raw_total_contact_value]"
		var/total_contact_id = normalize_memory_contact_id(raw_total_contact_id)
		if(total_contact_id != raw_total_contact_id)
			normalized_total_rows++
		ensure_consolidated_contact(consolidated_contacts, total_contact_id, raw_total_contact_id, null, null, null)

	if(!normalized_contact_rows && !normalized_daily_rows && !normalized_total_rows)
		status_message = "No @ contact IDs found to consolidate in [entry["display_name"]]."
		memory_db = null
		return TRUE

	var/success = TRUE
	if(!execute_database_update(memory_db, "BEGIN TRANSACTION", "begin memory consolidation transaction"))
		memory_db = null
		return FALSE
	if(success && !execute_database_update(memory_db, "DELETE FROM daily_counts", "clear memory daily counts for consolidation"))
		success = FALSE
	if(success && !execute_database_update(memory_db, "DELETE FROM total_counts", "clear memory total counts for consolidation"))
		success = FALSE
	if(success && !execute_database_update(memory_db, "DELETE FROM contacts", "clear memory contacts for consolidation"))
		success = FALSE

	if(success)
		var/list/contact_ids = list()
		for(var/contact_id in consolidated_contacts)
			contact_ids += contact_id
		contact_ids = sortList(contact_ids)
		for(var/contact_id in contact_ids)
			var/list/contact = consolidated_contacts[contact_id]
			if(!islist(contact))
				continue
			if(!execute_database_update(memory_db, list("INSERT OR REPLACE INTO contacts (contact_id, display_name, last_seen, notes) VALUES (?, ?, ?, ?)", contact_id, contact["display_name"], contact["last_seen"], contact["notes"]), "save consolidated memory contact"))
				success = FALSE
				break

	if(success)
		for(var/list/daily_row as anything in daily_rows)
			var/raw_daily_contact_value = daily_row["contact_id"]
			if(!raw_daily_contact_value)
				continue
			var/daily_contact_id = normalize_memory_contact_id("[raw_daily_contact_value]")
			if(!insert_consolidated_daily_count(memory_db, daily_row, daily_contact_id))
				success = FALSE
				break

	if(success)
		for(var/list/total_row as anything in total_rows)
			var/raw_total_contact_value = total_row["contact_id"]
			if(!raw_total_contact_value)
				continue
			var/total_contact_id = normalize_memory_contact_id("[raw_total_contact_value]")
			if(!insert_consolidated_total_count(memory_db, total_row, total_contact_id))
				success = FALSE
				break

	if(!success)
		execute_database_update(memory_db, "ROLLBACK", "rollback memory consolidation transaction")
		memory_db = null
		return FALSE
	if(!execute_database_update(memory_db, "COMMIT", "commit memory consolidation transaction"))
		execute_database_update(memory_db, "ROLLBACK", "rollback memory consolidation transaction")
		memory_db = null
		return FALSE

	memory_db = null
	if(selected_contact)
		selected_contact = normalize_memory_contact_id(selected_contact)
	ensure_character_cached(file_id, TRUE)
	status_message = "Consolidated [normalized_contact_rows] contact row[normalized_contact_rows == 1 ? "" : "s"], [normalized_daily_rows] daily row[normalized_daily_rows == 1 ? "" : "s"], and [normalized_total_rows] total row[normalized_total_rows == 1 ? "" : "s"] in [entry["display_name"]]."
	return TRUE

/datum/tgui_module/admin/client_memory_viewer/proc/normalize_count(var/value)
	if(isnum(value))
		return value
	var/number = text2num("[value]")
	if(isnum(number))
		return number
	return 0

/datum/tgui_module/admin/client_memory_viewer/proc/split_event_key(var/event_key)
	var/list/event_data = list(
		"event" = event_key,
		"detail" = null
	)
	var/separator_position = findtext(event_key, MEMORY_VIEWER_EVENT_DETAIL_SEPARATOR)
	if(separator_position)
		event_data["event"] = copytext(event_key, 1, separator_position)
		event_data["detail"] = copytext(event_key, separator_position + length(MEMORY_VIEWER_EVENT_DETAIL_SEPARATOR))
	return event_data

/datum/tgui_module/admin/client_memory_viewer/proc/build_count_row(var/list/source_row, var/include_date = FALSE)
	var/raw_event = source_row["event_key"]
	var/list/event_data = split_event_key(raw_event)
	var/list/row = list(
		"raw_event" = raw_event,
		"event" = event_data["event"],
		"detail" = event_data["detail"],
		"role" = source_row["role_key"],
		"count" = normalize_count(source_row["amount"])
	)
	if(include_date)
		row["date"] = source_row["date_key"]
	return row

/datum/tgui_module/admin/client_memory_viewer/proc/build_character_detail(var/list/entry, var/list/meta_rows, var/list/contact_rows, var/list/first_met_rows, var/list/day_count_rows, var/list/total_count_rows, var/list/total_rows, var/list/daily_rows)
	var/list/detail = initialize_detail(entry)
	var/list/meta_lookup = list()
	var/list/meta_entries = list()
	for(var/list/meta_row as anything in meta_rows)
		var/meta_name = meta_row["name"]
		if(!meta_name)
			continue
		meta_name = "[meta_name]"
		meta_lookup[meta_name] = meta_row["value"]
		meta_entries += list(list(
			"key" = meta_name,
			"value" = format_value(meta_row["value"])
		))
	detail["metaRows"] = meta_entries
	detail["owner"] = meta_lookup["owner"]
	detail["schema_version"] = meta_lookup["version"]

	var/list/first_met_lookup = build_contact_value_lookup(first_met_rows, "first_met")
	var/list/day_count_lookup = build_contact_value_lookup(day_count_rows, "day_count")
	var/list/total_count_lookup = build_contact_value_lookup(total_count_rows, "total_count")

	var/list/contact_entries = list()
	var/list/contact_details = list()
	var/list/contact_entries_by_id = list()
	var/list/duplicate_groups_by_key = list()

	for(var/list/contact_row as anything in contact_rows)
		var/contact_id = contact_row["contact_id"]
		if(!contact_id)
			continue
		contact_id = "[contact_id]"
		var/display_name = contact_row["display_name"] || get_contact_character_name(contact_id) || contact_id
		display_name = "[display_name]"
		var/parsed_ckey = get_contact_ckey(contact_id)
		var/parsed_name = get_contact_character_name(contact_id)
		var/notes = contact_row["notes"]
		if(isnull(notes))
			notes = ""
		notes = "[notes]"
		var/duplicate_key = get_duplicate_key(parsed_ckey, parsed_name)
		var/list/contact_entry = list(
			"contact_id" = contact_id,
			"display_name" = display_name,
			"parsed_ckey" = parsed_ckey,
			"parsed_name" = parsed_name,
			"last_seen" = contact_row["last_seen"],
			"first_met" = first_met_lookup[contact_id],
			"day_count" = normalize_count(day_count_lookup[contact_id]),
			"total_count" = normalize_count(total_count_lookup[contact_id]),
			"notes_length" = length(notes),
			"duplicate_key" = duplicate_key,
			"duplicate_count" = 1
		)
		contact_entries += list(contact_entry)
		contact_entries_by_id[contact_id] = contact_entry

		var/list/contact_detail = contact_entry.Copy()
		contact_detail["notes"] = notes
		contact_detail["totals"] = list()
		contact_detail["daily"] = list()
		contact_details[contact_id] = contact_detail

		if(duplicate_key)
			var/list/duplicate_group = duplicate_groups_by_key[duplicate_key]
			if(!islist(duplicate_group))
				duplicate_group = list(
					"key" = duplicate_key,
					"ckey" = normalize_memory_contact_ckey(parsed_ckey),
					"name" = trim(parsed_name),
					"contact_ids" = list()
				)
				duplicate_groups_by_key[duplicate_key] = duplicate_group
			var/list/group_contacts = duplicate_group["contact_ids"]
			group_contacts += contact_id

	for(var/list/total_row as anything in total_rows)
		var/contact_id = total_row["contact_id"]
		if(!contact_id)
			continue
		var/list/contact_detail = contact_details["[contact_id]"]
		if(!islist(contact_detail))
			continue
		var/list/total_list = contact_detail["totals"]
		total_list += list(build_count_row(total_row))

	for(var/list/daily_row as anything in daily_rows)
		var/contact_id = daily_row["contact_id"]
		if(!contact_id)
			continue
		var/list/contact_detail = contact_details["[contact_id]"]
		if(!islist(contact_detail))
			continue
		var/list/daily_list = contact_detail["daily"]
		daily_list += list(build_count_row(daily_row, TRUE))

	var/list/duplicate_groups = list()
	for(var/duplicate_key in duplicate_groups_by_key)
		var/list/duplicate_group = duplicate_groups_by_key[duplicate_key]
		var/list/group_contacts = duplicate_group["contact_ids"]
		if(!islist(group_contacts) || group_contacts.len < 2)
			continue
		duplicate_groups += list(list(
			"key" = duplicate_group["key"],
			"ckey" = duplicate_group["ckey"],
			"name" = duplicate_group["name"],
			"count" = group_contacts.len,
			"contact_ids" = group_contacts
		))
		for(var/contact_id in group_contacts)
			var/list/contact_entry = contact_entries_by_id[contact_id]
			if(islist(contact_entry))
				contact_entry["duplicate_count"] = group_contacts.len
			var/list/contact_detail = contact_details[contact_id]
			if(islist(contact_detail))
				contact_detail["duplicate_count"] = group_contacts.len

	detail["contacts"] = contact_entries
	detail["contact_details"] = contact_details
	detail["duplicateGroups"] = duplicate_groups

	return detail

/datum/tgui_module/admin/client_memory_viewer/proc/format_value(var/value)
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

/datum/tgui_module/admin/client_memory_viewer/proc/get_online_ckeys()
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

/datum/tgui_module/admin/client_memory_viewer/tgui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE

	switch(action)
		if("load_ckey")
			var/input_ckey = params["ckey"]
			load_ckey(input_ckey)
			return TRUE

		if("prompt_ckey")
			var/default_value = target_ckey ? target_ckey : ""
			var/input = tgui_input_text(usr, "Enter a player's ckey.", "Memory Viewer", default = default_value)
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
			selected_contact = null
			ensure_character_cached(selected_character, TRUE)
			status_message = "Selected [characters[file_id]["display_name"]]."
			return TRUE

		if("select_contact")
			var/contact_id = params["contact_id"]
			var/list/cache = ensure_character_cached(selected_character)
			var/list/detail = cache ? cache["detail"] : null
			var/list/contact_details = islist(detail) ? detail["contact_details"] : null
			if(!contact_id || !islist(contact_details) || !(contact_id in contact_details))
				return TRUE
			selected_contact = contact_id
			status_message = "Selected [contact_id]."
			return TRUE

		if("refresh_character")
			var/file_to_refresh = params["file"] || selected_character
			if(!(file_to_refresh in characters))
				return TRUE
			ensure_character_cached(file_to_refresh, TRUE)
			status_message = "Reloaded [characters[file_to_refresh]["display_name"]]."
			return TRUE

		if("consolidate_character")
			var/file_to_consolidate = params["file"] || selected_character
			if(!(file_to_consolidate in characters))
				return TRUE
			var/list/entry = characters[file_to_consolidate]
			if(tgui_alert(usr, "Consolidate @ contact entries in [entry["display_name"]]'s memory file? This rewrites only the selected memory database.", "Memory Viewer", list("Consolidate", "Cancel")) != "Consolidate")
				return TRUE
			consolidate_character_file(file_to_consolidate)
			return TRUE

	return FALSE

/datum/tgui_module/admin/client_memory_viewer/tgui_data(mob/user)
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
			var/list/detail = cache["detail"]
			var/list/contact_details = detail["contact_details"]
			var/list/contact_list = detail["contacts"]
			if(islist(contact_list) && contact_list.len && (!selected_contact || !islist(contact_details) || !(selected_contact in contact_details)))
				var/list/first_contact = contact_list[1]
				selected_contact = first_contact["contact_id"]
			var/list/ui_detail = detail.Copy()
			ui_detail["contact_details"] = null
			ui_detail["selected_contact"] = selected_contact
			if(selected_contact && islist(contact_details))
				ui_detail["contact_detail"] = contact_details[selected_contact]
			else
				ui_detail["contact_detail"] = null
			data["detail"] = ui_detail

	return data

#undef MEMORY_VIEWER_EVENT_DETAIL_SEPARATOR
#undef MEMORY_VIEWER_NOTE_LIMIT
