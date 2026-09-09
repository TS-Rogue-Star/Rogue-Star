/////////////////////////////////////////////////////////////////////////
//Created by Lira for Rogue Star May 2026 for persistent memory system //
/////////////////////////////////////////////////////////////////////////

#define CHARACTER_MEMORY_VERSION 1
#define CHARACTER_MEMORY_NOTE_LIMIT 4000
#define CHARACTER_MEMORY_EVENT_DETAIL_LIMIT 80
#define CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR "||"
#define CHARACTER_MEMORY_PAIR_FIRST 1
#define CHARACTER_MEMORY_PAIR_SECOND 2

GLOBAL_DATUM_INIT(tgui_character_memory_state, /datum/tgui_state/character_memory_state, new)

/datum/tgui_state/character_memory_state/can_use_topic(src_object, mob/user)
	var/datum/character_memory/memory = src_object
	if(!istype(memory) || memory.ourmob != user)
		return STATUS_CLOSE
	return user.shared_tgui_interaction(user)

/datum/character_memory
	var/mob/living/ourmob
	var/save_path
	var/database/memory_db
	var/savable = FALSE
	var/needs_saving = FALSE
	var/shutting_down = FALSE
	var/save_cooldown = 0
	var/list/contacts = list()
	var/selected_contact
	var/list/ui_contact_tokens = list()
	var/status_message
	var/error_message

/datum/character_memory/New(var/mob/living/L)
	if(!isliving(L))
		qdel(src)
		return
	ourmob = L
	save_cooldown = rand(5, 10)
	return ..()

/datum/character_memory/Destroy()
	ourmob = null
	memory_db = null
	contacts = null
	ui_contact_tokens = null
	return ..()

/datum/character_memory/proc/process_memory()
	if(!savable)
		return
	if(save_cooldown <= 0)
		save()
		save_cooldown = rand(5, 10)
	else
		save_cooldown--

/datum/character_memory/proc/get_save_path(var/datum/preferences/P)
	if(!ourmob)
		return
	var/owner_ckey = get_tracking_ckey(ourmob)
	if(!owner_ckey)
		savable = FALSE
		return
	var/character_name = ourmob.real_name
	if(!character_name && P)
		character_name = P.real_name
	if(!character_name || !has_non_generic_real_name(ourmob))
		savable = FALSE
		return
	var/event_suffix = ourmob.etching?.event_character ? "-EVENT" : ""
	save_path = "data/player_saves/[copytext(owner_ckey, 1, 2)]/[owner_ckey]/magic/[character_name][event_suffix]-memory.db"
	savable = TRUE

/datum/character_memory/proc/load(var/datum/preferences/P)
	error_message = null
	status_message = null
	if(!ourmob)
		return
	if(save_path)
		return
	if(!get_tracking_ckey(ourmob))
		log_debug("<span class = 'danger'>Character memory load failed: Aborting memory load for [ourmob.real_name], no ckey</span>")
		savable = FALSE
		return
	get_save_path(P)
	if(!save_path)
		log_debug("<span class = 'danger'>Character memory load failed: No save_path</span>")
		savable = FALSE
		return
	contacts = list()
	if(!ensure_database() || !load_database_contacts())
		log_debug("<span class = 'danger'>Character memory database failed to load! File path: '[save_path]'. Aborting and clearing save_path.</span>")
		save_path = null
		memory_db = null
		savable = FALSE
		return
	normalize_contacts()
	if(needs_saving)
		save(force = TRUE)

/datum/character_memory/proc/save(delet = FALSE, force = FALSE)
	if(!ourmob || !get_tracking_ckey(ourmob))
		return
	if(!savable || (!needs_saving && !force))
		return
	if(shutting_down)
		return
	if(delet)
		shutting_down = TRUE
	if(!save_path)
		if(shutting_down)
			ourmob = null
			qdel(src)
		return

	if(!sync_database_from_memory())
		log_debug("Character memory saving: [save_path] failed database sync.")
		return

	needs_saving = FALSE
	if(shutting_down)
		ourmob = null
		qdel(src)

/datum/character_memory/proc/enable_event_character()
	if(needs_saving)
		save(force = TRUE)
	save_path = null
	memory_db = null
	get_save_path()
	needs_saving = TRUE

/datum/character_memory/proc/build_database_query(var/query_data)
	var/database/query/query
	if(islist(query_data))
		query = new(arglist(query_data))
	else
		query = new(query_data)
	if(!istype(query))
		return null
	return query

/datum/character_memory/proc/database_query_failed(var/database/query/query, var/context)
	if(!query)
		log_debug("Character memory database query failed to build: [context] ([save_path])")
		return TRUE
	if(query.Error())
		log_debug("Character memory database error: [context] ([save_path]): [query.ErrorMsg()]")
		return TRUE
	return FALSE

/datum/character_memory/proc/execute_database_update(var/query_data, var/context)
	if(!memory_db)
		return FALSE
	var/database/query/query = build_database_query(query_data)
	if(!query)
		database_query_failed(query, context)
		return FALSE
	try
		query.Execute(memory_db)
	catch(var/exception/E)
		error("Character memory database update exception - [context] - Path: [save_path]: [E]")
		return FALSE
	if(database_query_failed(query, context))
		return FALSE
	return TRUE

/datum/character_memory/proc/execute_database_query(var/query_data, var/context)
	if(!memory_db)
		return null
	var/database/query/query = build_database_query(query_data)
	if(!query)
		database_query_failed(query, context)
		return null
	try
		query.Execute(memory_db)
	catch(var/exception/E)
		error("Character memory database query exception - [context] - Path: [save_path]: [E]")
		return null
	if(database_query_failed(query, context))
		return null
	var/list/results = list()
	while(query.NextRow())
		results[++results.len] = query.GetRowData()
	return results

/datum/character_memory/proc/ensure_database()
	if(memory_db)
		return TRUE
	if(!save_path)
		return FALSE
	memory_db = new(save_path)
	if(!memory_db)
		log_debug("Character memory failed to open database: [save_path]")
		return FALSE
	if(!init_database_schema())
		memory_db = null
		return FALSE
	return TRUE

/datum/character_memory/proc/init_database_schema()
	if(!execute_database_update("CREATE TABLE IF NOT EXISTS meta (name TEXT NOT NULL PRIMARY KEY, value TEXT)", "create character memory meta table"))
		return FALSE
	if(!execute_database_update("CREATE TABLE IF NOT EXISTS contacts (contact_id TEXT NOT NULL PRIMARY KEY, display_name TEXT, last_seen TEXT, notes TEXT NOT NULL DEFAULT '')", "create character memory contacts table"))
		return FALSE
	if(!execute_database_update("CREATE TABLE IF NOT EXISTS daily_counts (contact_id TEXT NOT NULL, date_key TEXT NOT NULL, event_key TEXT NOT NULL, role_key TEXT NOT NULL, amount INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(contact_id, date_key, event_key, role_key))", "create character memory daily counts table"))
		return FALSE
	if(!execute_database_update("CREATE TABLE IF NOT EXISTS total_counts (contact_id TEXT NOT NULL, event_key TEXT NOT NULL, role_key TEXT NOT NULL, amount INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(contact_id, event_key, role_key))", "create character memory total counts table"))
		return FALSE
	if(!execute_database_update("CREATE INDEX IF NOT EXISTS character_memory_daily_contact_idx ON daily_counts (contact_id, date_key)", "create character memory daily contact index"))
		return FALSE
	return execute_database_update(list("INSERT OR REPLACE INTO meta (name, value) VALUES (?, ?)", "version", "[CHARACTER_MEMORY_VERSION]"), "save character memory schema version")

/datum/character_memory/proc/save_database_metadata()
	if(!execute_database_update(list("INSERT OR REPLACE INTO meta (name, value) VALUES (?, ?)", "version", "[CHARACTER_MEMORY_VERSION]"), "save character memory schema version"))
		return FALSE
	return execute_database_update(list("INSERT OR REPLACE INTO meta (name, value) VALUES (?, ?)", "owner", ourmob?.real_name || ""), "save character memory owner")

/datum/character_memory/proc/normalize_loaded_contact_id(var/contact_id)
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

/datum/character_memory/proc/merge_loaded_contact_notes(var/current_notes, var/incoming_notes, var/source_contact_id)
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
	needs_saving = TRUE
	return copytext(merged_notes, 1, CHARACTER_MEMORY_NOTE_LIMIT + 1)

/datum/character_memory/proc/ensure_loaded_contact(var/contact_id, var/display_name, var/last_seen, var/notes)
	if(!contact_id)
		return null
	var/raw_contact_id = "[contact_id]"
	contact_id = normalize_loaded_contact_id(raw_contact_id)
	if(contact_id != raw_contact_id)
		needs_saving = TRUE
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
		contact = list(
			"display_name" = display_name || contact_id,
			"last_seen" = null,
			"notes" = "",
			"days" = list(),
			"totals" = list()
		)
		contacts[contact_id] = contact
	if(display_name)
		if(contact_id == raw_contact_id || !contact["display_name"] || contact["display_name"] == contact_id)
			contact["display_name"] = "[display_name]"
	else if(isnull(contact["display_name"]))
		contact["display_name"] = contact_id
	if(!isnull(last_seen))
		var/incoming_last_seen = "[last_seen]"
		var/current_last_seen = contact["last_seen"]
		if(!current_last_seen || sorttext("[current_last_seen]", incoming_last_seen) > 0)
			contact["last_seen"] = incoming_last_seen
	if(!isnull(notes))
		contact["notes"] = merge_loaded_contact_notes(contact["notes"], notes, raw_contact_id)
	if(!islist(contact["days"]))
		contact["days"] = list()
	if(!islist(contact["totals"]))
		contact["totals"] = list()
	if(isnull(contact["notes"]))
		contact["notes"] = ""
	return contact

/datum/character_memory/proc/load_database_contacts()
	var/list/contact_rows = execute_database_query("SELECT contact_id, display_name, last_seen, notes FROM contacts", "load character memory contacts")
	if(!islist(contact_rows))
		return FALSE
	for(var/list/contact_row as anything in contact_rows)
		ensure_loaded_contact(contact_row["contact_id"], contact_row["display_name"], contact_row["last_seen"], contact_row["notes"])

	var/list/daily_rows = execute_database_query("SELECT contact_id, date_key, event_key, role_key, amount FROM daily_counts", "load character memory daily counts")
	if(!islist(daily_rows))
		return FALSE
	for(var/list/daily_row as anything in daily_rows)
		var/list/contact = ensure_loaded_contact(daily_row["contact_id"], null, null, null)
		var/date_value = daily_row["date_key"]
		var/event_value = daily_row["event_key"]
		var/role_value = daily_row["role_key"]
		if(!islist(contact) || !date_value || !event_value || !role_value)
			continue
		var/date_key = "[date_value]"
		var/event_key = "[event_value]"
		var/role_key = "[role_value]"
		var/list/days = contact["days"]
		var/list/day = days[date_key]
		if(!islist(day))
			day = list("events" = list())
			days[date_key] = day
		var/list/day_events = day["events"]
		if(!islist(day_events))
			day_events = list()
			day["events"] = day_events
		increment_role_count(day_events, event_key, role_key, daily_row["amount"])

	var/list/total_rows = execute_database_query("SELECT contact_id, event_key, role_key, amount FROM total_counts", "load character memory total counts")
	if(!islist(total_rows))
		return FALSE
	for(var/list/total_row as anything in total_rows)
		var/list/total_contact = ensure_loaded_contact(total_row["contact_id"], null, null, null)
		var/total_event_value = total_row["event_key"]
		var/total_role_value = total_row["role_key"]
		if(!islist(total_contact) || !total_event_value || !total_role_value)
			continue
		increment_role_count(total_contact["totals"], "[total_event_value]", "[total_role_value]", total_row["amount"])
	return TRUE

/datum/character_memory/proc/save_database_contact(var/contact_id)
	if(!contact_id)
		return FALSE
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
		return FALSE
	var/display_name = contact["display_name"] || contact_id
	var/notes = contact["notes"]
	if(isnull(notes))
		notes = ""
	return execute_database_update(list("INSERT OR REPLACE INTO contacts (contact_id, display_name, last_seen, notes) VALUES (?, ?, ?, ?)", contact_id, display_name, contact["last_seen"], notes), "save character memory contact")

/datum/character_memory/proc/normalize_database_amount(var/amount)
	var/add_count = amount
	if(!isnum(add_count))
		add_count = text2num("[add_count]")
	if(!isnum(add_count) || add_count <= 0)
		add_count = 1
	return add_count

/datum/character_memory/proc/increment_database_daily_count(var/contact_id, var/date_key, var/event_key, var/role_key, var/amount = 1)
	var/add_count = normalize_database_amount(amount)
	if(!execute_database_update(list("INSERT OR IGNORE INTO daily_counts (contact_id, date_key, event_key, role_key, amount) VALUES (?, ?, ?, ?, 0)", contact_id, date_key, event_key, role_key), "ensure character memory daily count"))
		return FALSE
	return execute_database_update(list("UPDATE daily_counts SET amount = amount + ? WHERE contact_id = ? AND date_key = ? AND event_key = ? AND role_key = ?", add_count, contact_id, date_key, event_key, role_key), "update character memory daily count")

/datum/character_memory/proc/increment_database_total_count(var/contact_id, var/event_key, var/role_key, var/amount = 1)
	var/add_count = normalize_database_amount(amount)
	if(!execute_database_update(list("INSERT OR IGNORE INTO total_counts (contact_id, event_key, role_key, amount) VALUES (?, ?, ?, 0)", contact_id, event_key, role_key), "ensure character memory total count"))
		return FALSE
	return execute_database_update(list("UPDATE total_counts SET amount = amount + ? WHERE contact_id = ? AND event_key = ? AND role_key = ?", add_count, contact_id, event_key, role_key), "update character memory total count")

/datum/character_memory/proc/persist_interaction(var/contact_id, var/date_key, var/event_key, var/role_key)
	if(!ensure_database())
		return FALSE
	if(!execute_database_update("BEGIN TRANSACTION", "begin character memory interaction transaction"))
		return FALSE
	if(!save_database_contact(contact_id) || !increment_database_daily_count(contact_id, date_key, event_key, role_key) || !increment_database_total_count(contact_id, event_key, role_key))
		execute_database_update("ROLLBACK", "rollback character memory interaction transaction")
		return FALSE
	if(!execute_database_update("COMMIT", "commit character memory interaction transaction"))
		execute_database_update("ROLLBACK", "rollback character memory interaction transaction")
		return FALSE
	return TRUE

/datum/character_memory/proc/save_database_contact_counts(var/contact_id)
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
		return FALSE
	if(!save_database_contact(contact_id))
		return FALSE
	var/list/days = contact["days"]
	if(islist(days))
		for(var/daily_date_key in days)
			var/list/day = days[daily_date_key]
			if(!islist(day))
				continue
			var/list/day_events = day["events"]
			if(!islist(day_events))
				continue
			for(var/daily_event_key in day_events)
				var/list/daily_roles = day_events[daily_event_key]
				if(!islist(daily_roles))
					continue
				for(var/daily_role_key in daily_roles)
					if(!increment_database_daily_count(contact_id, daily_date_key, daily_event_key, daily_role_key, daily_roles[daily_role_key]))
						return FALSE
	var/list/totals = contact["totals"]
	if(islist(totals))
		for(var/total_event_key in totals)
			var/list/total_roles = totals[total_event_key]
			if(!islist(total_roles))
				continue
			for(var/total_role_key in total_roles)
				if(!increment_database_total_count(contact_id, total_event_key, total_role_key, total_roles[total_role_key]))
					return FALSE
	return TRUE

/datum/character_memory/proc/sync_database_from_memory()
	normalize_contacts()
	if(!ensure_database())
		return FALSE
	if(!execute_database_update("BEGIN TRANSACTION", "begin character memory full sync transaction"))
		return FALSE
	var/success = TRUE
	if(success && !save_database_metadata())
		success = FALSE
	if(success && !execute_database_update("DELETE FROM daily_counts", "clear character memory daily counts"))
		success = FALSE
	if(success && !execute_database_update("DELETE FROM total_counts", "clear character memory total counts"))
		success = FALSE
	if(success && !execute_database_update("DELETE FROM contacts", "clear character memory contacts"))
		success = FALSE
	if(success)
		for(var/contact_id in contacts)
			if(!save_database_contact_counts(contact_id))
				success = FALSE
				break
	if(!success)
		execute_database_update("ROLLBACK", "rollback character memory full sync transaction")
		return FALSE
	if(!execute_database_update("COMMIT", "commit character memory full sync transaction"))
		execute_database_update("ROLLBACK", "rollback character memory full sync transaction")
		return FALSE
	return TRUE

/datum/character_memory/proc/normalize_contacts()
	if(!islist(contacts))
		contacts = list()
	for(var/contact_id in contacts)
		var/list/contact = contacts[contact_id]
		if(!islist(contact))
			contacts -= contact_id
			needs_saving = TRUE
			continue
		if(!islist(contact["days"]))
			contact["days"] = list()
			needs_saving = TRUE
		if(!islist(contact["totals"]))
			contact["totals"] = list()
			needs_saving = TRUE
		if(isnull(contact["notes"]))
			contact["notes"] = ""
		if(isnull(contact["display_name"]))
			contact["display_name"] = contact_id
	if(selected_contact && !(selected_contact in contacts))
		selected_contact = null

/datum/character_memory/proc/get_valid_tracking_ckey(var/candidate_ckey, var/candidate_key)
	if(!candidate_ckey)
		return null
	if(candidate_key && IsGuestKey(candidate_key))
		return null
	if(candidate_key && copytext("[candidate_key]", 1, 2) == "@")
		return null
	var/normalized_ckey = ckey(candidate_ckey)
	if(!normalized_ckey || copytext(normalized_ckey, 1, 2) == "@" || findtext(normalized_ckey, "guest") == 1)
		return null
	return normalized_ckey

/datum/character_memory/proc/get_tracking_ckey(var/mob/living/L)
	if(!isliving(L))
		return null
	var/tracking_ckey = get_valid_tracking_ckey(L.ckey, L.key)
	if(tracking_ckey)
		return tracking_ckey
	tracking_ckey = get_valid_tracking_ckey(L.client?.ckey, L.client?.key)
	if(tracking_ckey)
		return tracking_ckey
	if(ismob(L.teleop))
		var/mob/linked_mob = L.teleop
		tracking_ckey = get_valid_tracking_ckey(linked_mob.ckey, linked_mob.key)
		if(tracking_ckey)
			return tracking_ckey
		tracking_ckey = get_valid_tracking_ckey(linked_mob.client?.ckey, linked_mob.client?.key)
		if(tracking_ckey)
			return tracking_ckey
	return null

/datum/character_memory/proc/has_non_generic_real_name(var/mob/living/L)
	if(!isliving(L) || !L.real_name)
		return FALSE
	var/character_name = trim("[L.real_name]")
	if(!character_name)
		return FALSE
	var/lower_name = lowertext(character_name)
	if(lower_name in list("unknown", "test dummy", "dummy"))
		return FALSE
	var/initial_real_name = initial(L.real_name)
	if(initial_real_name)
		var/lower_initial_real_name = lowertext("[initial_real_name]")
		if(lower_name == lower_initial_real_name || findtext(lower_name, "[lower_initial_real_name] (") == 1)
			return FALSE
	var/initial_name = initial(L.name)
	if(initial_name)
		var/lower_initial_name = lowertext("[initial_name]")
		if(lower_name == lower_initial_name || findtext(lower_name, "[lower_initial_name] (") == 1)
			return FALSE
	return TRUE

/datum/character_memory/proc/can_track(var/mob/living/L)
	if(!isliving(L))
		return FALSE
	if(!get_tracking_ckey(L))
		return FALSE
	if(!has_non_generic_real_name(L))
		return FALSE
	if(!L.etching)
		return FALSE
	if(!L.character_memory)
		return FALSE
	return TRUE

/datum/character_memory/proc/get_contact_id(var/mob/living/L)
	if(!can_track(L))
		return null
	return "[get_tracking_ckey(L)]|[L.real_name]"

/datum/character_memory/proc/contact_identity_hidden(var/mob/living/L, var/event_key)
	if(!isliving(L) || !L.real_name)
		return TRUE
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if((event_key == "say" || event_key == "whisper") && H.GetVoice() != H.real_name)
			return TRUE
		if(event_key == "say" || event_key == "whisper")
			return FALSE
		if(H.get_visible_name() != H.real_name)
			return TRUE
		return FALSE
	return L.name != L.real_name

/datum/character_memory/proc/ensure_contact(var/mob/living/L, var/mark_dirty = TRUE)
	var/contact_id = get_contact_id(L)
	if(!contact_id)
		return null
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
		contact = list(
			"display_name" = L.real_name,
			"last_seen" = null,
			"notes" = "",
			"days" = list(),
			"totals" = list()
		)
		contacts[contact_id] = contact
		if(mark_dirty)
			needs_saving = TRUE
	contact["display_name"] = L.real_name
	contact["last_seen"] = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")
	if(!islist(contact["days"]))
		contact["days"] = list()
	if(!islist(contact["totals"]))
		contact["totals"] = list()
	if(isnull(contact["notes"]))
		contact["notes"] = ""
	return contact_id

/datum/character_memory/proc/get_date_key()
	return time2text(world.realtime, "YYYY-MM-DD")

/datum/character_memory/proc/increment_role_count(var/list/event_bucket, var/event_key, var/role_key, var/amount = 1)
	if(!islist(event_bucket) || !event_key || !role_key)
		return
	var/add_count = amount
	if(!isnum(add_count))
		add_count = text2num("[add_count]")
	if(!isnum(add_count) || add_count <= 0)
		add_count = 1
	var/list/roles = event_bucket[event_key]
	if(!islist(roles))
		roles = list()
		event_bucket[event_key] = roles
	var/current_count = roles[role_key]
	if(!isnum(current_count))
		current_count = text2num("[current_count]")
	if(!isnum(current_count))
		current_count = 0
	roles[role_key] = current_count + add_count

/datum/character_memory/proc/sanitize_event_detail(var/event_detail)
	if(isnull(event_detail))
		return null
	event_detail = sanitize("[event_detail]", CHARACTER_MEMORY_EVENT_DETAIL_LIMIT + 1, FALSE, TRUE, TRUE)
	if(!event_detail)
		return null
	event_detail = replacetext(event_detail, CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR, "/")
	return copytext(event_detail, 1, CHARACTER_MEMORY_EVENT_DETAIL_LIMIT + 1)

/datum/character_memory/proc/build_event_key(var/event_key, var/event_detail)
	if(!event_key)
		return null
	var/clean_detail = sanitize_event_detail(event_detail)
	if(!clean_detail)
		return event_key
	return "[event_key][CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR][clean_detail]"

/datum/character_memory/proc/split_event_key(var/event_key)
	var/list/event_data = list(
		"event" = event_key,
		"detail" = null
	)
	var/separator_position = findtext(event_key, CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR)
	if(separator_position)
		event_data["event"] = copytext(event_key, 1, separator_position)
		event_data["detail"] = copytext(event_key, separator_position + length(CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR))
	return event_data

/datum/character_memory/proc/get_event_category(var/event_key)
	var/list/event_data = split_event_key(event_key)
	var/base_event = event_data["event"]
	if(!base_event)
		return "other"
	switch(base_event)
		if("say", "whisper", "absorbed_say", "psay", "me", "absorbed_me", "pme", "subtle", "music")
			return "social"
		if("attack", "picked_up")
			return "physical"
	if(findtext(base_event, "vore_") == 1)
		return "vore"
	return "other"

/datum/character_memory/proc/record_interaction(var/mob/living/other, var/event_key, var/role_key, var/event_detail)
	if(!event_key || !role_key || !can_track(ourmob) || !can_track(other) || other == ourmob)
		return FALSE
	if(contact_identity_hidden(other, event_key))
		return FALSE
	if(!save_path)
		load()
	if(!save_path || !savable)
		return FALSE
	var/stored_event_key = build_event_key(event_key, event_detail)
	if(!stored_event_key)
		return FALSE

	var/contact_id = ensure_contact(other, FALSE)
	if(!contact_id)
		return FALSE

	var/list/contact = contacts[contact_id]
	var/list/days = contact["days"]
	var/date_key = get_date_key()
	var/list/day = days[date_key]
	if(!islist(day))
		day = list("events" = list())
		days[date_key] = day
	var/list/day_events = day["events"]
	if(!islist(day_events))
		day_events = list()
		day["events"] = day_events

	var/list/totals = contact["totals"]
	if(!islist(totals))
		totals = list()
		contact["totals"] = totals

	increment_role_count(day_events, stored_event_key, role_key)
	increment_role_count(totals, stored_event_key, role_key)
	if(!persist_interaction(contact_id, date_key, stored_event_key, role_key))
		needs_saving = TRUE
	return TRUE

/datum/character_memory/proc/sanitize_note(var/note)
	if(isnull(note))
		note = ""
	note = sanitize("[note]", CHARACTER_MEMORY_NOTE_LIMIT + 1, FALSE, TRUE, TRUE)
	if(!note)
		return ""
	return copytext(note, 1, CHARACTER_MEMORY_NOTE_LIMIT + 1)

/datum/character_memory/proc/resolve_ui_contact_id(var/token)
	if(!token)
		return null
	var/contact_id = ui_contact_tokens[token]
	if(contact_id && (contact_id in contacts))
		return contact_id
	return null

/datum/character_memory/proc/get_ui_contact_token(var/contact_id)
	if(!contact_id)
		return null
	var/contact_key = "[contact_id]"
	return "contact-[md5(contact_key)]"

/datum/character_memory/proc/build_event_rows(var/list/event_bucket)
	var/list/rows = list()
	if(!islist(event_bucket))
		return rows
	var/list/event_keys = list()
	for(var/event_key in event_bucket)
		event_keys += event_key
	event_keys = sortList(event_keys)
	for(var/event_key in event_keys)
		var/list/roles = event_bucket[event_key]
		if(!islist(roles))
			continue
		var/list/event_data = split_event_key(event_key)
		var/list/role_rows = list()
		var/list/role_keys = list()
		for(var/role_key in roles)
			role_keys += role_key
		role_keys = sortList(role_keys)
		for(var/role_key in role_keys)
			role_rows += list(list(
				"role" = role_key,
				"count" = roles[role_key]
			))
		rows += list(list(
			"event" = event_data["event"],
			"detail" = event_data["detail"],
			"roles" = role_rows
		))
	return rows

/datum/character_memory/proc/build_event_categories(var/list/event_bucket)
	var/list/categories = list()
	if(!islist(event_bucket))
		return categories
	var/list/category_lookup = list()
	for(var/event_key in event_bucket)
		var/list/roles = event_bucket[event_key]
		if(!islist(roles))
			continue
		var/category = get_event_category(event_key)
		if(category)
			category_lookup[category] = TRUE
	var/list/category_keys = list()
	for(var/category in category_lookup)
		category_keys += category
	category_keys = sortList(category_keys)
	for(var/category in category_keys)
		categories += category
	return categories

/datum/character_memory/proc/build_day_rows(var/list/contact)
	var/list/rows = list()
	var/list/days = contact["days"]
	if(!islist(days))
		return rows
	var/list/day_keys = list()
	for(var/date_key in days)
		day_keys += date_key
	day_keys = sortList(day_keys)
	for(var/i = day_keys.len, i >= 1, i--)
		var/date_key = day_keys[i]
		var/list/day = days[date_key]
		if(!islist(day))
			continue
		rows += list(list(
			"date" = date_key,
			"events" = build_event_rows(day["events"])
		))
	return rows

/datum/character_memory/proc/get_first_met_date(var/list/contact)
	var/list/days = contact["days"]
	if(!islist(days) || !days.len)
		return null
	var/list/day_keys = list()
	for(var/date_key in days)
		day_keys += date_key
	day_keys = sortList(day_keys)
	return day_keys[1]

/datum/character_memory/proc/build_contact_data(var/contact_id, var/token)
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
		return null
	return list(
		"id" = token,
		"name" = contact["display_name"],
		"first_met" = get_first_met_date(contact),
		"last_seen" = contact["last_seen"],
		"notes" = contact["notes"],
		"categories" = build_event_categories(contact["totals"]),
		"totals" = build_event_rows(contact["totals"]),
		"days" = build_day_rows(contact)
	)

/proc/cmp_character_memory_contact_row_name(var/list/A, var/list/B)
	if(!islist(A) || !islist(B))
		return 0
	var/a_display_name = A["name"] || ""
	var/b_display_name = B["name"] || ""
	var/a_name = lowertext("[a_display_name]")
	var/b_name = lowertext("[b_display_name]")
	. = sorttext(b_name, a_name)
	if(!.)
		. = sorttext("[b_display_name]", "[a_display_name]")
	if(!.)
		var/a_contact_id = A["contact_id"] || ""
		var/b_contact_id = B["contact_id"] || ""
		. = sorttext("[b_contact_id]", "[a_contact_id]")

/datum/character_memory/tgui_state(mob/user)
	return GLOB.tgui_character_memory_state

/datum/character_memory/tgui_interact(mob/user, datum/tgui/ui = null)
	if(user != ourmob)
		return
	error_message = null
	if(!save_path && user.client)
		load(user.client.prefs)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterMemory", "Memory")
		ui.open()
	ui.set_autoupdate(FALSE)

/datum/character_memory/tgui_data(mob/user)
	var/list/data = list()
	if(user != ourmob)
		return data
	data["status"] = status_message
	data["error"] = error_message
	data["note_limit"] = CHARACTER_MEMORY_NOTE_LIMIT
	data["savable"] = savable

	normalize_contacts()
	var/list/contact_sort_rows = list()
	for(var/contact_id in contacts)
		var/list/contact = contacts[contact_id]
		if(!islist(contact))
			continue
		contact_sort_rows += list(list(
			"contact_id" = contact_id,
			"name" = contact["display_name"] || contact_id
		))
	contact_sort_rows = sortTim(contact_sort_rows, GLOBAL_PROC_REF(cmp_character_memory_contact_row_name), FALSE)
	var/list/contact_keys = list()
	for(var/list/contact_sort_row as anything in contact_sort_rows)
		contact_keys += contact_sort_row["contact_id"]

	if(!selected_contact && contact_keys.len)
		selected_contact = contact_keys[1]

	ui_contact_tokens = list()
	var/list/contact_rows = list()
	var/selected_token = null
	for(var/contact_id in contact_keys)
		var/list/contact = contacts[contact_id]
		if(!islist(contact))
			continue
		var/token = get_ui_contact_token(contact_id)
		if(!token)
			continue
		ui_contact_tokens[token] = contact_id
		if(contact_id == selected_contact)
			selected_token = token
		var/list/days = contact["days"]
		var/day_count = islist(days) ? days.len : 0
		contact_rows += list(list(
			"id" = token,
			"name" = contact["display_name"],
			"last_seen" = contact["last_seen"],
			"day_count" = day_count,
			"categories" = build_event_categories(contact["totals"])
		))

	data["contacts"] = contact_rows
	data["selected_contact"] = selected_token
	if(selected_contact && selected_token)
		data["detail"] = build_contact_data(selected_contact, selected_token)
	return data

/datum/character_memory/tgui_act(action, params)
	. = ..()
	if(.)
		return
	if(usr != ourmob)
		return TRUE
	status_message = null
	error_message = null
	switch(action)
		if("select_contact")
			var/contact_id = resolve_ui_contact_id(params["id"])
			if(!contact_id)
				error_message = "That memory entry is no longer available."
				return TRUE
			selected_contact = contact_id
			return TRUE
		if("save_note")
			var/contact_id = resolve_ui_contact_id(params["id"])
			if(!contact_id)
				error_message = "That memory entry is no longer available."
				return TRUE
			var/list/contact = contacts[contact_id]
			if(!islist(contact))
				error_message = "That memory entry is no longer available."
				return TRUE
			contact["notes"] = sanitize_note(params["note"])
			needs_saving = TRUE
			save(force = TRUE)
			status_message = "Memory note saved."
			return TRUE
		if("refresh")
			return TRUE
	return FALSE

/mob/living/verb/character_memory()
	set name = "Memory"
	set category = "IC"
	set desc = "Review your character's memories."

	if(!character_memory)
		to_chat(src, "<span class='warning'>You have no character memory for this body.</span>")
		return
	character_memory.tgui_interact(src)

/proc/record_character_memory_pair(var/mob/living/first, var/mob/living/second, var/event_key, var/first_role = "by_you", var/second_role = "by_them", var/event_detail)
	. = 0
	if(!isliving(first) || !isliving(second) || first == second)
		return
	if(first.character_memory)
		if(first.character_memory.record_interaction(second, event_key, first_role, event_detail))
			. |= CHARACTER_MEMORY_PAIR_FIRST
	if(second.character_memory)
		if(second.character_memory.record_interaction(first, event_key, second_role, event_detail))
			. |= CHARACTER_MEMORY_PAIR_SECOND

/proc/character_memory_belly_transfer_detail(var/obj/belly/source, var/obj/belly/target)
	var/source_name = source?.name
	var/target_name = target?.name
	if(source_name && target_name)
		return "[source_name] - [target_name]"
	if(source_name)
		return source_name
	return target_name

/proc/character_memory_adjacent_visible_delivery(var/mob/living/source, var/mob/living/recipient)
	if(!isliving(source) || !isliving(recipient))
		return FALSE
	if(source.Adjacent(recipient))
		return TRUE
	if(istype(source.loc, /obj/item/weapon/holder) && source.loc.loc == recipient)
		return TRUE
	return FALSE

/proc/character_memory_message_would_display(var/mob/living/source, var/mob/living/recipient, var/message_type, var/allow_adjacent_visible = FALSE)
	if(!message_type)
		return TRUE
	if(allow_adjacent_visible && message_type != AUDIBLE_MESSAGE && character_memory_adjacent_visible_delivery(source, recipient))
		return TRUE
	if((message_type & VISIBLE_MESSAGE) && (recipient.is_blind() || recipient.paralysis))
		return FALSE
	if((message_type & AUDIBLE_MESSAGE) && recipient.is_deaf())
		return FALSE
	return TRUE

/proc/character_memory_source_can_identify_recipient(var/mob/living/source, var/mob/living/recipient, var/event_key)
	if(!isliving(source) || !isliving(recipient) || source == recipient)
		return FALSE
	if(!source.character_memory)
		return FALSE
	if(source.stat != CONSCIOUS || source.sleeping > 0 || source.is_blind() || source.paralysis)
		return FALSE
	if(!(recipient in view(world.view, source)))
		return FALSE
	if(source.character_memory.contact_identity_hidden(recipient, event_key))
		return FALSE
	return TRUE

/proc/character_memory_source_known_contained_recipients(var/mob/living/source)
	. = list()
	if(!isliving(source))
		return
	var/obj/belly/source_belly = get_belly(source)
	if(istype(source_belly) && isliving(source_belly.owner) && source_belly.owner != source)
		. |= source_belly.owner
	for(var/mob/living/contained_mob in source.contents)
		if(contained_mob != source)
			. |= contained_mob
	if(!LAZYLEN(source.vore_organs))
		return
	for(var/obj/belly/B as anything in source.vore_organs)
		if(!istype(B))
			continue
		for(var/mob/living/contained_mob in B)
			if(contained_mob != source)
				. |= contained_mob

/proc/character_memory_can_hear_speech(var/mob/living/source, var/mob/living/recipient)
	if(!isliving(source) || !isliving(recipient))
		return FALSE
	if(recipient.is_deaf())
		return FALSE
	var/turf/recipient_turf = get_turf(recipient)
	if(!recipient_turf)
		return FALSE
	var/datum/gas_mixture/environment = recipient_turf.return_air()
	var/pressure = environment ? environment.return_pressure() : 0
	if(pressure < SOUND_MINIMUM_PRESSURE && get_dist(source, recipient) > 1)
		return FALSE
	return TRUE

/proc/record_character_memory_recipients(var/mob/living/source, var/list/recipients, var/event_key, var/range_limit = world.view, var/require_recipient_memory = FALSE, var/message_type = 0, var/allow_adjacent_visible = FALSE, var/check_speech_hearing = FALSE, var/list/source_known_recipients = null)
	. = list()
	if(!isliving(source) || !islist(recipients))
		return
	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return
	for(var/mob/living/recipient as anything in recipients)
		if(!isliving(recipient) || recipient == source || isobserver(recipient) || isnewplayer(recipient))
			continue
		if(!recipient.client && !recipient.teleop)
			continue
		if(recipient.stat != CONSCIOUS || recipient.sleeping > 0)
			continue
		var/turf/recipient_turf = get_turf(recipient)
		if(!recipient_turf)
			continue
		if(range_limit >= 0 && get_dist(source_turf, recipient_turf) > range_limit)
			continue
		if(!character_memory_message_would_display(source, recipient, message_type, allow_adjacent_visible))
			continue
		if(check_speech_hearing && !character_memory_can_hear_speech(source, recipient))
			continue
		var/recorded = 0
		var/source_can_identify_recipient = character_memory_source_can_identify_recipient(source, recipient, event_key)
		if(!source_can_identify_recipient && islist(source_known_recipients) && (recipient in source_known_recipients))
			if(source.character_memory && !source.character_memory.contact_identity_hidden(recipient, event_key))
				source_can_identify_recipient = TRUE
		if(require_recipient_memory)
			if(!recipient.character_memory || !recipient.character_memory.record_interaction(source, event_key, "by_them"))
				continue
			recorded |= CHARACTER_MEMORY_PAIR_SECOND
			if(source_can_identify_recipient && source.character_memory.record_interaction(recipient, event_key, "by_you"))
				recorded |= CHARACTER_MEMORY_PAIR_FIRST
		else
			if(source_can_identify_recipient && source.character_memory.record_interaction(recipient, event_key, "by_you"))
				recorded |= CHARACTER_MEMORY_PAIR_FIRST
			if(recipient.character_memory && recipient.character_memory.record_interaction(source, event_key, "by_them"))
				recorded |= CHARACTER_MEMORY_PAIR_SECOND
		if(recorded)
			. += recipient

/proc/character_memory_can_identify_attack_participant(var/mob/living/observer, var/mob/living/observed)
	if(!isliving(observer) || !isliving(observed))
		return FALSE
	if(!observer.client && !observer.teleop)
		return FALSE
	if(observer.stat != CONSCIOUS || observer.sleeping > 0 || observer.is_blind())
		return FALSE
	if(!(observed in view(world.view, observer)))
		return FALSE
	return TRUE

/proc/record_character_memory_attack_log(var/mob/attacker, var/mob/victim, var/what_done)
	. = 0
	if(!isliving(attacker) || !isliving(victim) || attacker == victim)
		return
	if(character_memory_should_ignore_attack_log(what_done))
		return
	var/mob/living/living_attacker = attacker
	var/mob/living/living_victim = victim
	if(character_memory_can_identify_attack_participant(living_attacker, living_victim) && living_attacker.character_memory)
		if(living_attacker.character_memory.record_interaction(living_victim, "attack", "as_attacker"))
			. |= CHARACTER_MEMORY_PAIR_FIRST
	if(character_memory_can_identify_attack_participant(living_victim, living_attacker) && living_victim.character_memory)
		if(living_victim.character_memory.record_interaction(living_attacker, "attack", "as_target"))
			. |= CHARACTER_MEMORY_PAIR_SECOND

/proc/character_memory_should_ignore_attack_log(var/what_done)
	if(!what_done)
		return FALSE
	var/log_text = lowertext("[what_done]")
	if(log_text == "scooped up")
		return TRUE
	if(findtext(log_text, "eaten via"))
		return TRUE
	if(findtext(log_text, "forced to eat"))
		return TRUE
	if(findtext(log_text, "devoured"))
		return TRUE
	if(findtext(log_text, "digested in"))
		return TRUE
	return FALSE

/proc/record_character_memory_round_end_inside()
	for(var/mob/living/prey in mob_list)
		if(!isliving(prey) || isobserver(prey))
			continue
		var/obj/belly/B = get_belly(prey)
		if(!istype(B) || !isliving(B.owner))
			continue
		var/mob/living/pred = B.owner
		if(pred == prey)
			continue
		record_character_memory_pair(pred, prey, "vore_round_end_inside", "as_pred", "as_prey", B.name)
		pred.character_memory?.save(force = TRUE)
		prey.character_memory?.save(force = TRUE)

#undef CHARACTER_MEMORY_VERSION
#undef CHARACTER_MEMORY_NOTE_LIMIT
#undef CHARACTER_MEMORY_EVENT_DETAIL_LIMIT
#undef CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR
#undef CHARACTER_MEMORY_PAIR_FIRST
#undef CHARACTER_MEMORY_PAIR_SECOND
