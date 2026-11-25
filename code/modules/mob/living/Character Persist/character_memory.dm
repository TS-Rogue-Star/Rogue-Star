//////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star May 2026 for persistent memory system //
//////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Drink Memories //////////
//////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Chemistry Memories //////
//////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Food Memories ///////////
//////////////////////////////////////////////////////////////////////////

#define CHARACTER_MEMORY_VERSION 4
#define CHARACTER_MEMORY_NOTE_LIMIT 4000
#define CHARACTER_MEMORY_EVENT_DETAIL_LIMIT 80
#define CHARACTER_MEMORY_EVENT_DETAIL_SEPARATOR "||"
#define CHARACTER_MEMORY_PAIR_FIRST 1
#define CHARACTER_MEMORY_PAIR_SECOND 2

GLOBAL_LIST_EMPTY(character_memories_by_path)
GLOBAL_DATUM_INIT(tgui_character_memory_state, /datum/tgui_state/character_memory_state, new)

/datum/tgui/character_memory
	var/active_tab = "characters"
	var/list/received_note_submissions

/datum/tgui_state/character_memory_state/can_use_topic(src_object, mob/user)
	var/datum/character_memory/memory = src_object
	if(!istype(memory) || memory.ourmob != user || !memory.can_access_memory())
		return STATUS_CLOSE
	return user.shared_tgui_interaction(user)

/datum/character_memory
	var/save_path
	var/tmp/save_generation = 0
	var/tmp/save_owner_ckey
	var/mob/living/ourmob
	var/tmp/contacts_need_refresh = FALSE
	var/tmp/recipes_need_refresh = FALSE
	var/tmp/saved_memory_needs_reload = FALSE
	var/tmp/recipes_saved_path
	var/tmp/list/recipe_discoveries = list()
	var/tmp/pending_recipe_path
	var/database/memory_db
	var/savable = FALSE
	var/needs_saving = FALSE
	var/shutting_down = FALSE
	var/save_cooldown = 0
	var/list/contacts = list()
	var/tmp/list/saved_contact_notes
	var/tmp/list/conflicting_contact_notes
	var/tmp/list/edited_note_revisions
	var/tmp/submitted_note_path
	var/tmp/list/pending_contact_interactions
	var/tmp/pending_interaction_path
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
	set_save_path(null)
	ourmob = null
	memory_db = null
	contacts = null
	drinks = null
	chemicals = null
	foods = null
	pending_drink_batches = null
	pending_chemical_batches = null
	pending_food_batches = null
	food_search_cache = null
	ui_contact_tokens = null
	return ..()

/proc/character_save_path_key(var/path)
	return path && world.system_type == MS_WINDOWS ? lowertext(path) : path

/proc/character_save_path_matches(var/path, var/expected)
	return path && (path == expected || character_save_path_key(path) == character_save_path_key(expected))

/proc/character_save_sibling_path(var/path, var/suffix, var/new_suffix)
	if(path && character_save_path_matches(copytext(path, -length(suffix)), suffix))
		return "[copytext(path, 1, -length(suffix))][new_suffix]"

/proc/character_event_save_path(var/normal_path, var/suffix)
	return character_save_sibling_path(normal_path, suffix, "-EVENT[suffix]")

/datum/character_memory/proc/set_save_path(var/path)
	if(save_path == path)
		return
	if(save_path)
		var/key = character_save_path_key(save_path)
		var/list/readers = GLOB.character_memories_by_path[key]
		readers -= src
		if(!length(readers))
			GLOB.character_memories_by_path -= key
	save_path = path
	if(path)
		var/key = character_save_path_key(path)
		LAZYOR(GLOB.character_memories_by_path[key], src)

/datum/character_memory/proc/process_memory()
	if(!savable)
		return
	if(save_cooldown <= 0)
		save()
		if(recipes_need_refresh && !saved_memory_needs_reload && can_access_memory() && refresh_stale_recipes())
			SStgui.update_uis(src)
		save_cooldown = rand(5, 10)
	else
		save_cooldown--

/datum/character_memory/proc/can_access_memory()
	if(!save_owner_ckey)
		return !save_path
	return save_owner_ckey == get_tracking_ckey(ourmob)

/datum/character_memory/proc/get_save_path(var/datum/preferences/P, var/event_character = ourmob?.etching?.event_character)
	if(!ourmob)
		return
	var/owner_ckey = get_tracking_ckey(ourmob)
	if(!owner_ckey)
		savable = FALSE
		return
	var/character_name = ourmob.real_name
	if(!character_name && P)
		character_name = P.real_name
	if(!character_name || !has_non_generic_real_name(ourmob) || findtext(character_name, "/") || findtext(character_name, "\\"))
		savable = FALSE
		return
	save_owner_ckey = owner_ckey
	set_save_path("data/player_saves/[copytext(owner_ckey, 1, 2)]/[owner_ckey]/magic/[character_name][event_character ? "-EVENT" : ""]-memory.db")
	savable = TRUE

/datum/character_memory/proc/load(var/datum/preferences/P)
	if(!can_access_memory())
		SStgui.close_uis(src)
		return
	error_message = null
	status_message = null
	if(!ourmob)
		return
	if(save_path)
		if(savable && !shutting_down)
			recipes_need_refresh = TRUE
			if(ensure_saved_memory_loaded() && ensure_database() && persist_recipe_changes())
				if(recipes_need_refresh)
					load_database_recipes()
				if(needs_saving)
					save()
				if(contacts_need_refresh && !needs_saving)
					refresh_database_contacts()
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
	load_saved_memory()

/datum/character_memory/vv_edit_var(var_name, var_value)
	if(var_name != "save_path")
		return ..()
	if(!isnull(var_value) && !istext(var_value))
		return FALSE
	if(character_save_path_key(save_path) != character_save_path_key(var_value) && !replace_saved_history(var_value))
		return FALSE
	datum_flags |= DF_VAR_EDITED
	return TRUE

/datum/character_memory/proc/invalidate_save_operations()
	save_generation++
	SStgui.close_uis(src)
	ui_contact_tokens.Cut()

/datum/character_memory/proc/replace_saved_history(var/path)
	if(save_path != path && (needs_saving || pending_recipe_path || length(edited_note_revisions) || length(pending_contact_interactions)) && !save())
		return FALSE
	memory_db?.Close()
	memory_db = null
	pending_recipe_path = null
	pending_food_batches.Cut()
	pending_drink_batches.Cut()
	pending_chemical_batches.Cut()
	needs_saving = FALSE
	set_save_path(path)
	load_saved_memory()
	return TRUE

/datum/character_memory/proc/load_saved_memory()
	invalidate_save_operations()
	saved_memory_needs_reload = TRUE
	contacts_need_refresh = TRUE
	recipes_saved_path = null
	status_message = null
	error_message = null
	selected_contact = null
	selected_food = null
	selected_drink = null
	selected_chemical = null
	contacts = list()
	drinks = list()
	chemicals = list()
	foods = list()
	recipe_discoveries.Cut()
	food_search_cache.Cut()
	saved_contact_notes = null
	conflicting_contact_notes = null
	edited_note_revisions = null
	submitted_note_path = null
	pending_contact_interactions = null
	pending_interaction_path = null
	if(ensure_saved_memory_loaded() && needs_saving)
		save(force = TRUE)

/datum/character_memory/proc/ensure_saved_memory_loaded(var/allow_bound_batches = FALSE)
	if(!saved_memory_needs_reload)
		return TRUE
	if(!can_access_memory() && !(allow_bound_batches && save_owner_ckey && pending_recipe_path && pending_recipe_path == save_path))
		return FALSE
	return refresh_saved_memory()

/datum/character_memory/proc/ensure_contacts_loaded()
	return islist(saved_contact_notes) || (ensure_database() && refresh_database_contacts())

/datum/character_memory/proc/refresh_saved_memory()
	if(!ensure_database() || !refresh_database_contacts() || !persist_pending_interactions() || !load_database_recipes())
		return FALSE
	if(saved_memory_needs_reload)
		saved_memory_needs_reload = FALSE
		if(pending_recipe_path == save_path)
			merge_pending_recipe_batches(foods, pending_food_batches)
			merge_pending_recipe_batches(drinks, pending_drink_batches)
			merge_pending_recipe_batches(chemicals, pending_chemical_batches)
		error_message = null
		SStgui.update_uis(src)
	return TRUE

/datum/character_memory/proc/refresh_stale_recipes()
	if(!recipes_need_refresh)
		return !pending_recipe_path || persist_recipe_changes()
	return ensure_database() && persist_recipe_changes() && load_database_recipes()

/datum/character_memory/proc/load_database_recipes()
	recipes_need_refresh = !(load_reagent_recipes("drink", drinks, "bartending") && load_reagent_recipes("chemical", chemicals, "chemistry") && load_database_foods())
	return !recipes_need_refresh

/datum/character_memory/proc/load_reagent_recipes(var/kind, var/list/entries, var/skill)
	var/id_column = "[kind]_id"
	var/list/rows = execute_database_query("SELECT [id_column], times_made, first_made, last_made FROM [kind]s", "load character memory [kind]s")
	if(!islist(rows))
		return FALSE
	entries.Cut()
	for(var/list/row as anything in rows)
		var/id = row[id_column]
		var/times_made = text2num("[row["times_made"]]")
		if(!istext(id) || !length(id) || !isnum(times_made) || times_made < 1)
			continue
		entries[id] = list("times_made" = round(times_made), "first_made" = row["first_made"], "last_made" = row["last_made"])
	food_search_cache.Cut()
	set_recipe_discoveries(skill, length(entries), reconcile_keys = TRUE)
	return TRUE

/datum/character_memory/proc/record_recipe_batches(var/id, var/list/entries, var/list/pending, var/batches = 1)
	var/today = get_date_key()
	add_recipe_batches(pending, id, batches, today, today)
	if(!saved_memory_needs_reload)
		if(!(id in entries))
			food_search_cache.Cut()
		add_recipe_batches(entries, id, batches, today, today)
	if(!persist_recipe_changes())
		SStgui.update_uis(src)
	return TRUE

/datum/character_memory/proc/add_recipe_batches(var/list/entries, var/id, var/batches, var/first_made, var/last_made)
	var/list/entry = entries[id]
	if(!entry)
		entries[id] = list("times_made" = batches, "first_made" = first_made, "last_made" = last_made)
		return
	entry["times_made"] += batches
	if(first_made && (!entry["first_made"] || sorttext(first_made, entry["first_made"]) > 0))
		entry["first_made"] = first_made
	if(last_made && (!entry["last_made"] || sorttext(entry["last_made"], last_made) > 0))
		entry["last_made"] = last_made

/datum/character_memory/proc/bind_pending_recipes()
	if(!save_path)
		load()
	if(!savable || !save_path || !can_access_memory() || (pending_recipe_path && pending_recipe_path != save_path))
		return FALSE
	pending_recipe_path = save_path
	return TRUE

/datum/character_memory/proc/get_bound_etching()
	RETURN_TYPE(/datum/etching)
	if(ourmob?.character_memory != src)
		return null
	var/datum/etching/etching = ourmob.etching
	if(!save_owner_ckey || !etching)
		return null
	if(character_save_path_matches(etching.save_path, character_save_sibling_path(save_path, "-memory.db", "-etching.json")))
		return etching

/proc/recipe_xp_skill(var/kind)
	var/skill = lowertext(trim("[kind]"))
	if(skill in list("cooking", "bartending", "chemistry"))
		return skill

/proc/set_recipe_xp_balance(var/list/balances, var/skill, var/total, var/reconcile_keys = FALSE)
	var/changed = FALSE
	if(reconcile_keys)
		for(var/kind in balances.Copy())
			if(kind != skill && recipe_xp_skill(kind) == skill)
				balances -= kind
				changed = TRUE
	if(isnull(balances[skill]) || balances[skill] != total)
		balances[skill] = total
		changed = TRUE
	return changed

/datum/character_memory/proc/set_recipe_discoveries(var/skill, var/total, var/reconcile_keys = FALSE)
	recipe_discoveries[skill] = total
	var/datum/etching/bound = get_bound_etching()
	if(!bound)
		return
	bound.xp = SANITIZE_LIST(bound.xp)
	if(set_recipe_xp_balance(bound.xp, skill, total, reconcile_keys))
		bound.needs_saving = TRUE

/datum/character_memory/proc/database_recipe_xp()
	var/list/rows = execute_database_query({"
		SELECT (SELECT COUNT(*) FROM foods) AS cooking,
			(SELECT COUNT(*) FROM drinks WHERE drink_id != '' AND CAST(times_made AS INTEGER) > 0) AS bartending,
			(SELECT COUNT(*) FROM chemicals WHERE chemical_id != '' AND CAST(times_made AS INTEGER) > 0) AS chemistry
	"}, "read committed character recipe XP")
	return rows?[1]

/datum/character_memory/proc/save(delet = FALSE, force = FALSE)
	if(!ourmob || !savable || shutting_down)
		return FALSE
	var/had_bound_work = length(pending_contact_interactions) || length(edited_note_revisions) || pending_recipe_path
	var/interactions_saved = persist_pending_interactions()
	var/notes_saved = !length(edited_note_revisions) || sync_database_from_memory(submitted_notes_only = TRUE)
	if(saved_memory_needs_reload && (!interactions_saved || length(edited_note_revisions) || !ensure_saved_memory_loaded(allow_bound_batches = TRUE)))
		return FALSE
	if(!save_owner_ckey || !can_access_memory())
		var/recipes_saved = !pending_recipe_path || (pending_recipe_path == save_path && persist_recipe_changes())
		return had_bound_work && interactions_saved && recipes_saved && notes_saved
	if(!interactions_saved || length(edited_note_revisions))
		return FALSE
	if(!needs_saving && !force && !pending_recipe_path)
		return !length(conflicting_contact_notes)
	if(delet)
		shutting_down = TRUE
	if(!save_path)
		if(shutting_down)
			ourmob = null
			qdel(src)
		return FALSE

	var/saved = (needs_saving || force) ? sync_database_from_memory() : persist_recipe_changes()
	if(!saved)
		log_debug("Character memory saving: [save_path] failed database sync.")
		return FALSE

	needs_saving = FALSE
	if(length(conflicting_contact_notes))
		return FALSE
	if(shutting_down)
		ourmob = null
		qdel(src)
	return TRUE

/datum/character_memory/proc/enable_event_character()
	if(ourmob?.etching?.event_character && character_save_path_matches(save_path, character_save_sibling_path(ourmob.etching.save_path, "-etching.json", "-memory.db")))
		return TRUE
	if(save_path || can_track(ourmob))
		if(!can_access_memory())
			return FALSE
		if(!save_path)
			get_save_path(event_character = FALSE)
			if(save_path)
				load_saved_memory()
		if(!save_path || !save() || !refresh_saved_memory())
			return FALSE
	var/datum/character_memory/snapshot = new(ourmob)
	if(save_path)
		snapshot.save_owner_ckey = save_owner_ckey
		snapshot.set_save_path(character_event_save_path(save_path, "-memory.db"))
		snapshot.savable = savable
		snapshot.contacts = contacts
		snapshot.foods = foods
		snapshot.drinks = drinks
		snapshot.chemicals = chemicals
		if(!snapshot.savable || !snapshot.publish_event_snapshot())
			qdel(snapshot)
			return FALSE

	invalidate_save_operations()
	memory_db?.Close()
	memory_db = snapshot.memory_db
	snapshot.memory_db = null
	save_owner_ckey = snapshot.save_owner_ckey
	set_save_path(snapshot.save_path)
	savable = snapshot.savable
	recipes_saved_path = save_path
	if(save_path)
		remember_contact_notes()
	conflicting_contact_notes = null
	edited_note_revisions = null
	submitted_note_path = null
	contacts_need_refresh = FALSE
	recipes_need_refresh = FALSE
	saved_memory_needs_reload = FALSE
	needs_saving = FALSE
	for(var/skill in recipe_discoveries)
		set_recipe_discoveries(skill, recipe_discoveries[skill], reconcile_keys = TRUE)
	qdel(snapshot)
	return TRUE

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
	contacts_need_refresh = TRUE
	memory_db = new(save_path)
	if(!memory_db)
		log_debug("Character memory failed to open database: [save_path]")
		return FALSE
	if(!init_database_schema())
		memory_db = null
		return FALSE
	return TRUE

/datum/character_memory/proc/init_database_schema()
	if(!init_drinks_schema() || !init_chemicals_schema() || !init_foods_schema())
		return FALSE
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
	return copytext(merged_notes, 1, CHARACTER_MEMORY_NOTE_LIMIT + 1)

/datum/character_memory/proc/ensure_loaded_contact(var/contact_id, var/display_name, var/last_seen, var/notes, var/list/legacy_ids)
	if(!contact_id)
		return null
	var/raw_contact_id = "[contact_id]"
	contact_id = normalize_loaded_contact_id(raw_contact_id)
	if(contact_id != raw_contact_id && islist(legacy_ids))
		legacy_ids[raw_contact_id] = contact_id
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

/datum/character_memory/proc/mark_peer_contacts_stale()
	var/list/peers = GLOB.character_memories_by_path[character_save_path_key(save_path)]
	for(var/datum/character_memory/peer in peers)
		if(peer != src)
			peer.contacts_need_refresh = TRUE

/datum/character_memory/proc/refresh_stale_memory()
	if(!ensure_saved_memory_loaded())
		error_message = "The latest memories could not be loaded. Refresh to try again."
		return
	refresh_stale_recipes()
	if(contacts_need_refresh && !needs_saving && (!ensure_database() || !refresh_database_contacts()))
		error_message = "The latest contacts could not be loaded. Refresh to try again."

/datum/character_memory/proc/refresh_database_contacts()
	if(length(edited_note_revisions) && !sync_database_from_memory(submitted_notes_only = TRUE))
		return FALSE
	if(!execute_database_update("BEGIN TRANSACTION", "begin character memory contact read"))
		return FALSE
	var/list/old_contacts = contacts
	var/list/legacy_ids = list()
	contacts = list()
	if(!load_database_contacts(legacy_ids) || !migrate_legacy_contacts(legacy_ids) || !execute_database_update("COMMIT", "commit character memory contact read"))
		execute_database_update("ROLLBACK", "rollback character memory contact read")
		contacts = old_contacts
		return FALSE
	if(length(legacy_ids))
		mark_peer_contacts_stale()
	contacts_need_refresh = FALSE
	for(var/contact_id in conflicting_contact_notes)
		var/list/conflict = conflicting_contact_notes[contact_id]
		conflict["saved"] = contacts[contact_id]?["notes"]
		if(!contacts[contact_id])
			contacts[contact_id] = old_contacts[contact_id]
			contacts[contact_id]["notes"] = ""
	normalize_contacts()
	remember_contact_notes()
	for(var/list/interaction as anything in pending_contact_interactions)
		apply_contact_interaction(interaction)
	return TRUE

/datum/character_memory/proc/remember_contact_notes()
	edited_note_revisions = null
	submitted_note_path = null
	saved_contact_notes = list()
	for(var/contact_id in contacts)
		saved_contact_notes[contact_id] = contacts[contact_id]["notes"]

/datum/character_memory/proc/load_database_contacts(var/list/legacy_ids)
	var/list/contact_rows = execute_database_query("SELECT contact_id, display_name, last_seen, notes FROM contacts", "load character memory contacts")
	if(!islist(contact_rows))
		return FALSE
	for(var/list/contact_row as anything in contact_rows)
		ensure_loaded_contact(contact_row["contact_id"], contact_row["display_name"], contact_row["last_seen"], contact_row["notes"], legacy_ids)

	var/list/daily_rows = execute_database_query("SELECT contact_id, date_key, event_key, role_key, amount FROM daily_counts", "load character memory daily counts")
	if(!islist(daily_rows))
		return FALSE
	for(var/list/daily_row as anything in daily_rows)
		var/list/contact = ensure_loaded_contact(daily_row["contact_id"], null, null, null, legacy_ids)
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
		var/list/total_contact = ensure_loaded_contact(total_row["contact_id"], null, null, null, legacy_ids)
		var/total_event_value = total_row["event_key"]
		var/total_role_value = total_row["role_key"]
		if(!islist(total_contact) || !total_event_value || !total_role_value)
			continue
		increment_role_count(total_contact["totals"], "[total_event_value]", "[total_role_value]", total_row["amount"])
	return TRUE

/datum/character_memory/proc/migrate_legacy_contacts(var/list/legacy_ids)
	if(!length(legacy_ids))
		return TRUE
	var/list/merged_ids = list()
	for(var/legacy_id in legacy_ids)
		var/contact_id = legacy_ids[legacy_id]
		merged_ids[contact_id] = TRUE
		for(var/table_name in list("daily_counts", "total_counts", "contacts"))
			if(!execute_database_update(list("DELETE FROM [table_name] WHERE contact_id IN (?, ?)", legacy_id, contact_id), "remove legacy character memory rows"))
				return FALSE
	for(var/contact_id in merged_ids)
		if(!save_database_contact(contact_id) || !save_database_contact_counts(contact_id))
			return FALSE
	return TRUE

/datum/character_memory/proc/save_database_contact(var/contact_id, var/preserve_note = FALSE)
	if(!contact_id)
		return FALSE
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
		return FALSE
	var/display_name = contact["display_name"] || contact_id
	var/notes = preserve_note ? null : (contact["notes"] || "")
	return execute_database_update(list({"
		INSERT OR REPLACE INTO contacts (contact_id, display_name, last_seen, notes)
		SELECT ?, ?, MAX(last_seen), COALESCE(?, MAX(notes), '') FROM (
			SELECT last_seen, notes FROM contacts WHERE contact_id = ?
			UNION ALL SELECT ?, NULL
		)
	"}, contact_id, display_name, notes, contact_id, contact["last_seen"]), "save character memory contact")

/datum/character_memory/proc/read_contact_note(var/contact_id)
	return execute_database_query(list("SELECT notes FROM contacts WHERE contact_id = ?", contact_id), "check current character memory note")

/datum/character_memory/proc/save_contact_note(var/contact_id, var/list/conflicts)
	var/note = contacts[contact_id]["notes"] || ""
	var/revision = edited_note_revisions?[contact_id] || md5(saved_contact_notes[contact_id] || "")
	var/list/rows = read_contact_note(contact_id)
	if(!islist(rows))
		return null
	if(!length(rows))
		conflicts[contact_id] = list("draft" = note, "saved" = null)
		return FALSE
	var/current_note = rows[1]["notes"] || ""
	if(md5(current_note) != revision && current_note != note)
		conflicts[contact_id] = list("draft" = note, "saved" = current_note)
		return FALSE
	if(current_note != note && !execute_database_update(list("UPDATE contacts SET notes = ? WHERE contact_id = ?", note, contact_id), "save character memory note"))
		return null
	return TRUE

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

/datum/character_memory/proc/write_contact_interaction(var/list/interaction)
	var/contact_id = interaction["contact_id"]
	var/event_key = interaction["event"]
	var/role_key = interaction["role"]
	return save_database_contact(contact_id, preserve_note = TRUE) && increment_database_daily_count(contact_id, interaction["date"], event_key, role_key) && increment_database_total_count(contact_id, event_key, role_key)

/datum/character_memory/proc/persist_interaction(var/contact_id, var/date_key, var/event_key, var/role_key, var/display_name, var/last_seen)
	if(!save_path || (pending_interaction_path && pending_interaction_path != save_path))
		return FALSE
	pending_interaction_path = save_path
	var/list/interaction = list(
		"contact_id" = contact_id,
		"date" = date_key,
		"event" = event_key,
		"role" = role_key,
		"name" = display_name || contacts[contact_id]?["display_name"],
		"last_seen" = last_seen || contacts[contact_id]?["last_seen"]
	)
	LAZYADD(pending_contact_interactions, list(interaction))
	if(islist(saved_contact_notes))
		apply_contact_interaction(interaction)
	return persist_pending_interactions()

/datum/character_memory/proc/persist_pending_interactions()
	if(!length(pending_contact_interactions))
		return TRUE
	if(pending_interaction_path != save_path || !ensure_database() || !ensure_contacts_loaded())
		return FALSE
	if(!execute_database_update("BEGIN TRANSACTION", "begin character memory interaction transaction"))
		return FALSE
	for(var/list/interaction as anything in pending_contact_interactions)
		if(!write_contact_interaction(interaction))
			execute_database_update("ROLLBACK", "rollback character memory interaction transaction")
			return FALSE
	if(!execute_database_update("COMMIT", "commit character memory interaction transaction"))
		execute_database_update("ROLLBACK", "rollback character memory interaction transaction")
		return FALSE
	if(islist(saved_contact_notes))
		for(var/list/interaction as anything in pending_contact_interactions)
			var/contact_id = interaction["contact_id"]
			if(!(contact_id in saved_contact_notes))
				saved_contact_notes[contact_id] = ""
	pending_contact_interactions = null
	pending_interaction_path = null
	mark_peer_contacts_stale()
	return TRUE

/datum/character_memory/proc/save_database_contact_counts(var/contact_id)
	var/list/contact = contacts[contact_id]
	if(!islist(contact))
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

/datum/character_memory/proc/publish_event_snapshot()
	if(!ensure_database() || !execute_database_update("BEGIN TRANSACTION", "begin event memory snapshot"))
		return FALSE
	if(!save_database_metadata() || !copy_event_contacts() || !copy_event_recipes("drink", drinks) || !copy_event_recipes("chemical", chemicals) || !copy_event_recipes("food", foods) || !execute_database_update("COMMIT", "commit event memory snapshot"))
		execute_database_update("ROLLBACK", "roll back event memory snapshot")
		return FALSE
	var/list/peers = GLOB.character_memories_by_path[character_save_path_key(save_path)]
	for(var/datum/character_memory/peer in peers?.Copy())
		if(peer != src)
			peer.replace_saved_history(save_path)
	return TRUE

/datum/character_memory/proc/copy_event_contacts()
	for(var/table_name in list("daily_counts", "total_counts", "contacts"))
		if(!execute_database_update("DELETE FROM [table_name]", "replace event memory contacts"))
			return FALSE
	for(var/contact_id in contacts)
		if(!save_database_contact(contact_id) || !save_database_contact_counts(contact_id))
			return FALSE
	return TRUE

/datum/character_memory/proc/copy_event_recipes(var/kind, var/list/entries)
	var/table_name = "[kind]s"
	var/id_column = "[kind]_id"
	if(!execute_database_update("DELETE FROM [table_name]", "clear character memory [table_name]"))
		return FALSE
	for(var/id in entries)
		var/list/entry = entries[id]
		if(!execute_database_update(list("INSERT INTO [table_name] ([id_column], times_made, first_made, last_made) VALUES (?, ?, ?, ?)", id, entry["times_made"], entry["first_made"], entry["last_made"]), "copy character memory [kind]"))
			return FALSE
	return TRUE

/datum/character_memory/proc/save_recipe_rows(var/kind, var/list/pending, var/list/saved_rows)
	var/table_name = "[kind]s"
	var/id_column = "[kind]_id"
	if(!length(pending))
		return TRUE
	var/list/updated = list()
	saved_rows[kind] = updated
	var/query = {"
		INSERT OR REPLACE INTO [table_name] ([id_column], times_made, first_made, last_made)
		SELECT ?, SUM(times_made), MIN(first_made), MAX(last_made) FROM (
			SELECT times_made, first_made, last_made FROM [table_name] WHERE [id_column] = ? AND CAST(times_made AS INTEGER) > 0
			UNION ALL SELECT ?, ?, ?
		)
	"}
	for(var/id in pending)
		var/list/batch = pending[id]
		if(!execute_database_update(list(query, id, id, batch["times_made"], batch["first_made"], batch["last_made"]), "save character memory [kind]"))
			return FALSE
		var/list/rows = execute_database_query(list("SELECT times_made, first_made, last_made FROM [table_name] WHERE [id_column] = ?", id), "read updated character memory [kind]")
		if(!length(rows))
			return FALSE
		updated[id] = rows[1]
	return TRUE

/datum/character_memory/proc/save_recipe_changes(var/list/saved_rows)
	if(recipes_saved_path != save_path || (pending_recipe_path && pending_recipe_path != save_path))
		return null
	if(!save_recipe_rows("drink", pending_drink_batches, saved_rows) || !save_recipe_rows("chemical", pending_chemical_batches, saved_rows))
		return null
	if(!save_recipe_rows("food", pending_food_batches, saved_rows))
		return null
	if(length(pending_drink_batches) || length(pending_chemical_batches))
		var/list/totals = database_recipe_xp()
		if(!islist(totals))
			return null
		saved_rows["totals"] = totals
		return totals["cooking"]
	return length(pending_food_batches) ? database_food_count() : (recipe_discoveries["cooking"] || 0)

/datum/character_memory/proc/reagent_recipe_save_committed(var/list/entries, var/list/pending, var/list/updated, var/skill, var/total, var/tab)
	if(isnull(total))
		return
	for(var/id in updated)
		entries[id] = updated[id]
	set_recipe_discoveries(skill, total)
	if(can_access_memory())
		for(var/id in pending)
			if(entries[id]["times_made"] == pending[id]["times_made"])
				var/datum/reagent/product = SSchemistry.chemical_reagents[id]
				to_chat(ourmob, SPAN_NOTICE("You learned to make [product.name]! +1 [skill] XP ([total] total). Find the recipe in Memory's [tab] tab."))
	pending.Cut()

/datum/character_memory/proc/apply_shared_recipe_rows(var/list/entries, var/list/pending, var/list/updated)
	for(var/id in updated)
		if(!(id in entries))
			food_search_cache.Cut()
		var/list/row = updated[id]
		entries[id] = row.Copy()
	merge_pending_recipe_batches(entries, pending, updated)

/datum/character_memory/proc/merge_pending_recipe_batches(var/list/entries, var/list/pending, var/list/updated)
	for(var/id in pending)
		if(isnull(updated) || (id in updated))
			var/list/batch = pending[id]
			add_recipe_batches(entries, id, batch["times_made"], batch["first_made"], batch["last_made"])

/datum/character_memory/proc/recipe_save_committed(var/list/saved_rows, var/discovery_count)
	pending_recipe_path = null
	var/list/totals = saved_rows["totals"]
	reagent_recipe_save_committed(drinks, pending_drink_batches, saved_rows["drink"], "bartending", totals?["bartending"], "Drinks")
	reagent_recipe_save_committed(chemicals, pending_chemical_batches, saved_rows["chemical"], "chemistry", totals?["chemistry"], "Chemistry")
	food_save_committed(saved_rows["food"], discovery_count)
	if(!length(saved_rows))
		return
	if(can_access_memory())
		SStgui.update_uis(src)
	var/list/peers = GLOB.character_memories_by_path[character_save_path_key(save_path)]
	for(var/datum/character_memory/peer in peers)
		if(peer == src || peer.shutting_down || peer.saved_memory_needs_reload || !character_save_path_matches(peer.save_path, save_path))
			continue
		if(!peer.can_access_memory())
			peer.recipes_need_refresh = TRUE
			continue
		if(saved_rows["drink"])
			peer.apply_shared_recipe_rows(peer.drinks, peer.pending_drink_batches, saved_rows["drink"])
			peer.recipe_discoveries["bartending"] = totals["bartending"]
		if(saved_rows["chemical"])
			peer.apply_shared_recipe_rows(peer.chemicals, peer.pending_chemical_batches, saved_rows["chemical"])
			peer.recipe_discoveries["chemistry"] = totals["chemistry"]
		if(saved_rows["food"])
			peer.apply_shared_recipe_rows(peer.foods, peer.pending_food_batches, saved_rows["food"])
			peer.recipe_discoveries["cooking"] = discovery_count
		SStgui.update_uis(peer)

/datum/character_memory/proc/persist_recipe_changes()
	if(!ensure_saved_memory_loaded())
		return FALSE
	if(recipes_saved_path == save_path && !pending_recipe_path)
		return TRUE
	if(!ensure_database() || !execute_database_update("BEGIN TRANSACTION", "begin character memory recipe transaction"))
		return FALSE
	var/list/saved_rows = list()
	var/discovery_count = save_recipe_changes(saved_rows)
	if(isnull(discovery_count) || !execute_database_update("COMMIT", "commit character memory recipe transaction"))
		execute_database_update("ROLLBACK", "rollback character memory recipe transaction")
		return FALSE
	recipe_save_committed(saved_rows, discovery_count)
	return TRUE

/datum/character_memory/proc/save_contact_changes(var/list/saved_notes, var/list/conflicts, var/submitted_notes_only)
	if(!islist(saved_contact_notes))
		return FALSE
	var/list/contact_ids = submitted_notes_only ? edited_note_revisions : contacts
	for(var/contact_id in contact_ids)
		var/list/conflict = conflicting_contact_notes?[contact_id]
		if(conflict)
			continue
		var/new_contact = !(contact_id in saved_contact_notes)
		if(new_contact && (submitted_notes_only || !save_database_contact(contact_id, preserve_note = TRUE)))
			return FALSE
		if(contacts[contact_id]["notes"] != (saved_contact_notes[contact_id] || "") || (contact_id in edited_note_revisions))
			var/saved = save_contact_note(contact_id, conflicts)
			if(isnull(saved))
				return FALSE
			if(!saved)
				continue
		else if(!new_contact)
			continue
		if(new_contact && !save_database_contact_counts(contact_id))
			return FALSE
		saved_notes[contact_id] = contacts[contact_id]["notes"]
	return TRUE

/datum/character_memory/proc/sync_database_from_memory(var/submitted_notes_only = FALSE)
	if((!submitted_notes_only && !ensure_saved_memory_loaded()) || !ensure_database())
		return FALSE
	if(length(edited_note_revisions) && !character_save_path_matches(submitted_note_path, save_path))
		return FALSE
	if(submitted_notes_only && !islist(saved_contact_notes))
		return FALSE
	if(!submitted_notes_only)
		normalize_contacts()
		if(!persist_pending_interactions())
			return FALSE
		if(pending_recipe_path && recipes_saved_path == save_path && !persist_recipe_changes())
			return FALSE
	if(!execute_database_update("BEGIN TRANSACTION", "begin character memory full sync transaction"))
		return FALSE
	var/list/saved_notes = list()
	var/list/conflicts = list()
	var/success = (submitted_notes_only || save_database_metadata()) && save_contact_changes(saved_notes, conflicts, submitted_notes_only)
	var/list/saved_rows = list()
	var/discovery_count
	if(success && !submitted_notes_only)
		discovery_count = save_recipe_changes(saved_rows)
		success = !isnull(discovery_count)
	if(!success || !execute_database_update("COMMIT", "commit character memory full sync transaction"))
		execute_database_update("ROLLBACK", "rollback character memory full sync transaction")
		return FALSE
	var/pending_notes_before = length(edited_note_revisions)
	var/contacts_changed = length(saved_notes)
	for(var/contact_id in saved_notes)
		saved_contact_notes[contact_id] = saved_notes[contact_id]
		LAZYREMOVE(edited_note_revisions, contact_id)
	for(var/contact_id in conflicts)
		var/list/conflict = conflicts[contact_id]
		LAZYSET(conflicting_contact_notes, contact_id, conflict)
		contacts[contact_id]["notes"] = conflict["saved"] || ""
		saved_contact_notes[contact_id] = contacts[contact_id]["notes"]
		LAZYREMOVE(edited_note_revisions, contact_id)
	if(!length(edited_note_revisions))
		submitted_note_path = null
	if(contacts_changed)
		mark_peer_contacts_stale()
	if(!submitted_notes_only)
		recipe_save_committed(saved_rows, discovery_count)
	if(length(conflicts) || length(edited_note_revisions) < pending_notes_before)
		SStgui.update_uis(src)
	return !submitted_notes_only || (!length(edited_note_revisions) && !length(conflicts))

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
	if(L.client)
		return get_valid_tracking_ckey(L.client.ckey, L.client.key)
	var/tracking_ckey = get_valid_tracking_ckey(L.ckey, L.key)
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
	if(!save_path || !savable || !can_access_memory())
		return FALSE
	var/stored_event_key = build_event_key(event_key, event_detail)
	var/contact_id = get_contact_id(other)
	if(!stored_event_key || !contact_id)
		return FALSE
	if(!persist_interaction(contact_id, get_date_key(), stored_event_key, role_key, other.real_name, time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")))
		needs_saving = TRUE
	return TRUE

/datum/character_memory/proc/apply_contact_interaction(var/list/interaction)
	var/list/contact = ensure_loaded_contact(interaction["contact_id"], interaction["name"], interaction["last_seen"], null)
	var/list/days = contact["days"]
	var/date_key = interaction["date"]
	var/list/day = days[date_key]
	if(!islist(day))
		day = list("events" = list())
		days[date_key] = day
	if(!islist(day["events"]))
		day["events"] = list()
	increment_role_count(day["events"], interaction["event"], interaction["role"])
	increment_role_count(contact["totals"], interaction["event"], interaction["role"])

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
	var/contact_key = "[REF(src)]|[save_generation]|[contact_id]"
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
	var/list/conflict = conflicting_contact_notes?[contact_id]
	return list(
		"id" = token,
		"name" = contact["display_name"],
		"first_met" = get_first_met_date(contact),
		"last_seen" = contact["last_seen"],
		"notes" = conflict ? conflict["draft"] : contact["notes"],
		"note_conflict" = !!conflict,
		"contact_deleted" = conflict && isnull(conflict["saved"]),
		"note_pending" = (contact_id in edited_note_revisions),
		"note_revision" = md5((conflict ? conflict["saved"] : saved_contact_notes?[contact_id]) || ""),
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
	if(user != ourmob || !can_access_memory())
		return
	if(!ui)
		error_message = null
	if(!save_path && user.client)
		load(user.client.prefs)
	else if(!ui)
		refresh_stale_memory()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui/character_memory(user, src, "CharacterMemory", "Memory")
		ui.open()
	ui.set_autoupdate(FALSE)

/datum/character_memory/tgui_data(mob/user, datum/tgui/character_memory/ui)
	var/list/data = list()
	if(user != ourmob || !can_access_memory())
		return data
	data["status"] = status_message
	data["error"] = error_message
	data["note_limit"] = CHARACTER_MEMORY_NOTE_LIMIT
	data["savable"] = savable
	data["recipes_need_refresh"] = recipes_need_refresh || saved_memory_needs_reload
	data["tab"] = ui?.active_tab || "characters"
	switch(data["tab"])
		if("food")
			add_foods_ui_data(data)
			return data
		if("drinks")
			add_drinks_ui_data(data)
			return data
		if("chemistry")
			add_chemicals_ui_data(data)
			return data

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

	data["detail"] = null
	data["contacts"] = contact_rows
	data["selected_contact"] = selected_token
	if(selected_contact && selected_token)
		var/list/detail = build_contact_data(selected_contact, selected_token)
		var/list/submission = ui?.received_note_submissions?[selected_contact]
		detail["received_submission"] = submission?["id"]
		detail["submitted_revision"] = submission?["revision"]
		data["detail"] = detail
		if(!error_message && detail["contact_deleted"])
			data["error"] = "This contact was removed from the shared memory. Copy any note text you want to keep before discarding the edit."
		else if(!error_message && (selected_contact in conflicting_contact_notes))
			data["error"] = "Another body saved the note \"[conflicting_contact_notes[selected_contact]["saved"]]\". Use the saved note or save your edit to replace it."
		else if(selected_contact in edited_note_revisions)
			data["error"] = "The note could not be saved. Your edit is still pending."
	return data

/datum/character_memory/tgui_act(action, params, datum/tgui/character_memory/ui)
	. = ..()
	if(!ourmob || usr != ourmob || ui?.user != ourmob || !can_access_memory())
		return TRUE
	var/list/submission
	if(action == "save_note" && isnum(params["submission"]))
		var/contact_id = resolve_ui_contact_id(params["id"])
		if(contact_id)
			submission = list("id" = params["submission"])
			LAZYSET(ui.received_note_submissions, contact_id, submission)
	if(. && !(ui.status == STATUS_UPDATE && (action in list("select_tab", "select_contact", "select_drink", "select_chemical", "select_food", "refresh"))))
		return TRUE
	if(action == "select_tab")
		var/tab = params["tab"]
		if(tab == ui.active_tab || !(tab in list("characters", "drinks", "food", "chemistry")))
			return FALSE
		ui.active_tab = tab
		return TRUE
	status_message = null
	error_message = null
	switch(action)
		if("select_food")
			if(params["id"] in foods)
				selected_food = params["id"]
			return TRUE
		if("select_chemical")
			if(params["id"] in chemicals)
				selected_chemical = params["id"]
			return TRUE
		if("select_drink")
			if(params["id"] in drinks)
				selected_drink = params["id"]
			return TRUE
		if("select_contact")
			var/contact_id = resolve_ui_contact_id(params["id"])
			if(!contact_id)
				error_message = "That memory entry is no longer available."
				return TRUE
			selected_contact = contact_id
			return TRUE
		if("discard_note", "discard_deleted_note")
			var/contact_id = resolve_ui_contact_id(params["id"])
			var/list/conflict = conflicting_contact_notes?[contact_id]
			if(!conflict || (action == "discard_deleted_note" && !isnull(conflict["saved"])))
				return FALSE
			var/list/rows = ensure_database() ? read_contact_note(contact_id) : null
			if(!islist(rows))
				error_message = "The saved note could not be loaded. Try discarding the edit again."
				return TRUE
			if(length(rows))
				var/saved_note = rows[1]["notes"] || ""
				contacts[contact_id]["notes"] = saved_note
				saved_contact_notes[contact_id] = saved_note
				LAZYREMOVE(conflicting_contact_notes, contact_id)
				return TRUE
			needs_saving = TRUE
			save()
			if(needs_saving)
				error_message = "The remaining contacts could not be saved. Try discarding the edit again."
				return TRUE
			LAZYREMOVE(conflicting_contact_notes, contact_id)
			contacts -= contact_id
			saved_contact_notes -= contact_id
			contacts_need_refresh = TRUE
			refresh_stale_memory()
			return TRUE
		if("save_note")
			if(!save_path || !savable || !ensure_contacts_loaded())
				error_message = "The latest contacts could not be loaded. Refresh to try again."
				return TRUE
			var/contact_id = resolve_ui_contact_id(params["id"])
			if(!contact_id)
				error_message = "That memory entry is no longer available."
				return TRUE
			var/list/contact = contacts[contact_id]
			if(!islist(contact))
				error_message = "That memory entry is no longer available."
				return TRUE
			var/revision = params["note_revision"]
			if(!istext(revision) || length(revision) != 32)
				error_message = "Refresh this memory entry before saving your note."
				return TRUE
			LAZYREMOVE(conflicting_contact_notes, contact_id)
			submitted_note_path = save_path
			LAZYSET(edited_note_revisions, contact_id, revision)
			contact["notes"] = sanitize_note(params["note"])
			if(submission)
				submission["revision"] = md5(contact["notes"])
			if(!sync_database_from_memory(submitted_notes_only = TRUE) && length(edited_note_revisions))
				needs_saving = TRUE
			if(!(contact_id in edited_note_revisions) && !(contact_id in conflicting_contact_notes))
				status_message = "Memory note saved."
			return TRUE
		if("refresh")
			refresh_stale_memory()
			return TRUE
	return FALSE

/mob/living/verb/character_memory()
	set name = "Memory"
	set category = "IC"
	set desc = "Review your character's memories."

	if(!character_memory || !character_memory.can_access_memory())
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
