////////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star September 2025 as part of a VChat enhancement package//
////////////////////////////////////////////////////////////////////////////////////////

#define VCHAT_FILENAME "data/vchat.db"
#define VCHAT_ROUND_HISTORY 10 // RS Add: Store ten rounds (Lira, September 2025)
GLOBAL_DATUM(vchatdb, /database)
GLOBAL_VAR_INIT(vchat_current_round_id, null) //RS Add: Round ID (Lira, September 2025)

//Boot up db file || RS Edit: Updated for multi-round (Lira, September 2025)
/proc/init_vchat()
	//Create a new one
	if(!check_vchat())
		GLOB.vchatdb = new(VCHAT_FILENAME)

	//Build our basic boring tables
	vchat_create_tables()
	vchat_migrate_schema()
	vchat_repair_missing_round_records()

	if(!GLOB.vchat_current_round_id)
		vchat_begin_round()

//Check to see if it's init
/proc/check_vchat()
	if(istype(GLOB.vchatdb))
		return TRUE
	else
		return FALSE

//For INSERT/CREATE/DELETE, etc that return a RowsAffected.
/proc/vchat_exec_update(var/query)
	if(!check_vchat())
		log_world("There's no vchat database open but you tried to query it with: [query]")
		return FALSE

	//Solidify our query
	var/database/query/q = vchat_build_query(query)

	//Run it
	q.Execute(GLOB.vchatdb)

	//Handle errors
	if(q.Error())
		log_world("Query \"[islist(query)?query[1]:query]\" ended in error [q.ErrorMsg()]")
		return FALSE

	return q.RowsAffected()

//For SELECT, that return results.
/proc/vchat_exec_query(var/query)
	if(!check_vchat())
		log_world("There's no vchat database open but you tried to query it!")
		return FALSE

	//Solidify our query
	var/database/query/q = vchat_build_query(query)

	//Run it
	q.Execute(GLOB.vchatdb)

	//Handle errors
	if(q.Error())
		log_world("Query \"[islist(query)?query[1]:query]\" ended in error [q.ErrorMsg()]")
		return FALSE

	//Return any results
	var/list/results = list()
	//Return results if any.
	while(q.NextRow())
		results[++results.len] = q.GetRowData()

	return results

//Create a query from string or list with params
/proc/vchat_build_query(var/query)
	var/database/query/q

	if(islist(query))
		q = new(arglist(query))
	else
		q = new(query)

	if(!istype(q))
		return

	return q

// RS Edit: Updated for multi-round (Lira, September 2025)
/proc/vchat_create_tables()
	//Messages table
	var/tabledef = "CREATE TABLE IF NOT EXISTS messages(\
			id INTEGER PRIMARY KEY AUTOINCREMENT,\
			ckey VARCHAR(50) NOT NULL,\
			worldtime INTEGER NOT NULL,\
			message TEXT NOT NULL,\
			round_id TEXT,\
			logged_at INTEGER)"
	vchat_exec_update(tabledef)

	//Index on ckey
	var/indexdef = "CREATE INDEX IF NOT EXISTS msg_ckey_idx ON messages (ckey)"
	vchat_exec_update(indexdef)

	var/round_index = "CREATE INDEX IF NOT EXISTS msg_round_ckey_idx ON messages (ckey, round_id)"
	vchat_exec_update(round_index)

	var/time_index = "CREATE INDEX IF NOT EXISTS msg_logged_at_idx ON messages (logged_at)"
	vchat_exec_update(time_index)

	var/round_table = "CREATE TABLE IF NOT EXISTS rounds(\
			id TEXT PRIMARY KEY NOT NULL,\
			start_time INTEGER NOT NULL,\
			end_time INTEGER)"
	vchat_exec_update(round_table)

	var/round_indexdef = "CREATE INDEX IF NOT EXISTS rounds_start_idx ON rounds (start_time)"
	vchat_exec_update(round_indexdef)

	var/round_end_index = "CREATE INDEX IF NOT EXISTS rounds_end_idx ON rounds (end_time)"
	vchat_exec_update(round_end_index)

// RS Add Start: New procs for multi-round db (Lira, September 2025)

// Check if a given table already contains a specific column
/proc/vchat_table_has_column(var/table_name, var/column_name)
	var/list/info = vchat_exec_query("PRAGMA table_info([table_name])")
	if(!islist(info))
		return FALSE
	for(var/list/row in info)
		if(lowertext(row["name"]) == lowertext(column_name))
			return TRUE
	return FALSE

// Bring the legacy schema up to date with round-aware columns and indexes
/proc/vchat_migrate_schema()
	if(!vchat_table_has_column("messages", "round_id"))
		vchat_exec_update("ALTER TABLE messages ADD COLUMN round_id TEXT")

	if(!vchat_table_has_column("messages", "logged_at"))
		vchat_exec_update("ALTER TABLE messages ADD COLUMN logged_at INTEGER DEFAULT 0")

	// Ensure indexes exist even on migrated tables
	vchat_exec_update("CREATE INDEX IF NOT EXISTS msg_round_ckey_idx ON messages (ckey, round_id)")
	vchat_exec_update("CREATE INDEX IF NOT EXISTS msg_logged_at_idx ON messages (logged_at)")

	// Assign any legacy rows to the current round once one exists
	if(GLOB.vchat_current_round_id)
		vchat_assign_round_to_unassigned(GLOB.vchat_current_round_id)

/proc/vchat_current_realtime()
	if(isnum(world.realtime))
		return world.realtime
	return 0

// Create a unique identifier for a new chat round using timestamp entropy
/proc/vchat_generate_round_id()
	var/timestamp = time2text(vchat_current_realtime(), "YYYYMMDD_hhmmss")
	var/random_segment = rand(1000, 9999)
	return "round_[timestamp]_[random_segment]"

// Stamp the provided round as ended so queries know it is historical
/proc/vchat_mark_round_closed(var/round_id)
	if(!round_id)
		return
	vchat_exec_update(list("UPDATE rounds SET end_time = ? WHERE id = ? AND (end_time IS NULL OR end_time = 0)", vchat_current_realtime(), round_id))

// Apply the active round ID to legacy messages that were missing metadata
/proc/vchat_assign_round_to_unassigned(var/round_id)
	if(!round_id)
		return
	vchat_exec_update(list("UPDATE messages SET round_id = ? WHERE round_id IS NULL OR round_id = ''", round_id))
	vchat_exec_update(list("UPDATE messages SET logged_at = ? WHERE (logged_at IS NULL OR logged_at = 0)", vchat_current_realtime()))

// Backfill round rows when an older/broken database has round-aware messages but no round metadata
/proc/vchat_repair_missing_round_records()
	var/list/missing_rounds = vchat_exec_query("SELECT m.round_id, MIN(NULLIF(m.logged_at, 0)) AS start_time, MAX(NULLIF(m.logged_at, 0)) AS end_time FROM messages m LEFT JOIN rounds r ON r.id = m.round_id WHERE m.round_id IS NOT NULL AND m.round_id != '' AND r.id IS NULL GROUP BY m.round_id")
	if(!islist(missing_rounds) || !missing_rounds.len)
		return

	var/repaired = 0
	for(var/list/row in missing_rounds)
		if(!islist(row))
			continue

		var/round_id = row["round_id"]
		if(!istext(round_id) || !length(round_id))
			continue

		var/start_time = row["start_time"]
		if(istext(start_time))
			start_time = text2num(start_time)
		if(!isnum(start_time) || start_time <= 0)
			start_time = 0

		var/end_time = row["end_time"]
		if(istext(end_time))
			end_time = text2num(end_time)
		if(!isnum(end_time) || end_time <= 0)
			end_time = null

		var/updated = vchat_exec_update(list("INSERT OR IGNORE INTO rounds (id, start_time, end_time) VALUES (?, ?, ?)", round_id, start_time, end_time))
		if(isnum(updated))
			repaired += updated

	if(repaired)
		log_world("VChat repaired [repaired] missing round records from saved messages.")

// Cull excess historical rounds beyond the configured retention window
/proc/vchat_cleanup_old_rounds()
	var/list/message_rounds = vchat_exec_query("SELECT round_id FROM messages WHERE round_id IS NOT NULL AND round_id != '' GROUP BY round_id ORDER BY MAX(id) DESC, round_id DESC")
	if(!islist(message_rounds))
		return

	var/list/keep_rounds = list()
	if(istext(GLOB.vchat_current_round_id) && length(GLOB.vchat_current_round_id))
		keep_rounds[GLOB.vchat_current_round_id] = TRUE

	for(var/list/entry in message_rounds)
		if(!islist(entry))
			continue
		var/round_id = entry["round_id"]
		if(!istext(round_id) || !length(round_id))
			continue
		if(keep_rounds[round_id])
			continue
		if(keep_rounds.len >= VCHAT_ROUND_HISTORY)
			break
		keep_rounds[round_id] = TRUE

	for(var/list/entry in message_rounds)
		if(!islist(entry))
			continue
		var/remove_id = entry["round_id"]
		if(!istext(remove_id) || !length(remove_id) || keep_rounds[remove_id])
			continue
		vchat_exec_update(list("DELETE FROM messages WHERE round_id = ?", remove_id))
		vchat_exec_update(list("DELETE FROM rounds WHERE id = ?", remove_id))

	var/list/round_rows = vchat_exec_query("SELECT id FROM rounds")
	if(!islist(round_rows))
		return
	for(var/list/entry in round_rows)
		if(!islist(entry))
			continue
		var/remove_id = entry["id"]
		if(!istext(remove_id) || !length(remove_id) || keep_rounds[remove_id])
			continue
		vchat_exec_update(list("DELETE FROM rounds WHERE id = ?", remove_id))

// Start a fresh chat round record and keep the global pointer up to date
/proc/vchat_begin_round()
	if(!check_vchat())
		return

	var/previous_round = GLOB.vchat_current_round_id
	if(!previous_round)
		var/list/open_round = vchat_exec_query("SELECT id FROM rounds WHERE end_time IS NULL OR end_time = 0 ORDER BY start_time DESC, id DESC LIMIT 1")
		if(islist(open_round) && open_round.len)
			var/list/entry = open_round[1]
			if(islist(entry))
				previous_round = entry["id"]

	if(previous_round)
		vchat_mark_round_closed(previous_round)

	var/new_round = vchat_generate_round_id()
	vchat_exec_update(list("INSERT INTO rounds (id, start_time) VALUES (?, ?)", new_round, vchat_current_realtime()))
	GLOB.vchat_current_round_id = new_round

	vchat_assign_round_to_unassigned(new_round)
	vchat_cleanup_old_rounds()

// RS Add End

//INSERT a new message || RS Edit: Adjusted for multi-round db (Lira, September 2025)
/proc/vchat_add_message(var/ckey, var/message)
	if(!ckey || !message)
		return

	if(!GLOB.vchat_current_round_id)
		vchat_begin_round()

	var/list/messagedef = list(
		"INSERT INTO messages (ckey,worldtime,message,round_id,logged_at) VALUES (?, ?, ?, ?, ?)",
		ckey,
		world.time,
		message,
		GLOB.vchat_current_round_id,
		vchat_current_realtime())

	return vchat_exec_update(messagedef)

//Get a player's message history.  If limit is supplied, messages will be in reverse order. || RS Edit: Adjusted for multi-round db (Lira, September 2025)
/proc/vchat_get_messages(var/ckey, var/limit, var/round_id)
	if(!ckey)
		return

	var/list/getdef
	if(limit)
		if(round_id)
			getdef = list("SELECT * FROM messages WHERE ckey = ? AND round_id = ? ORDER BY id DESC LIMIT [text2num(limit)]", ckey, round_id)
		else
			getdef = list("SELECT * FROM messages WHERE ckey = ? ORDER BY id DESC LIMIT [text2num(limit)]", ckey)
	else
		if(round_id)
			getdef = list("SELECT * FROM messages WHERE ckey = ? AND round_id = ? ORDER BY id ASC", ckey, round_id)
		else
			getdef = list("SELECT * FROM messages WHERE ckey = ? ORDER BY id ASC", ckey)

	return vchat_exec_query(getdef)

// RS Add Start: New procs for multi-round db (Lira, September 2025)

// Render a stored realtime value into a timestamp for the UI
/proc/vchat_format_round_timestamp(var/value)
	if(isnull(value))
		return null

	if(istext(value))
		value = text2num(value)

	if(!isnum(value) || value <= 0)
		return null

	return time2text(value, "YYYY-MM-DD hh:mm")

// Render timestamps embedded in generated IDs when stored realtime data is missing
/proc/vchat_format_round_id_timestamp(var/round_id)
	if(!istext(round_id) || length(round_id) < 21)
		return null
	if(copytext(round_id, 1, 7) != "round_" || copytext(round_id, 15, 16) != "_")
		return null

	var/year = copytext(round_id, 7, 11)
	var/month = copytext(round_id, 11, 13)
	var/day = copytext(round_id, 13, 15)
	var/hour = copytext(round_id, 16, 18)
	var/minute = copytext(round_id, 18, 20)
	return "[year]-[month]-[day] [hour]:[minute]"

// Return the most recent rounds
/proc/vchat_get_round_overview(var/ckey, var/limit = VCHAT_ROUND_HISTORY)
	if(!limit || !isnum(limit) || limit <= 0)
		limit = VCHAT_ROUND_HISTORY

	var/sql_limit = max(round(limit), 1)
	var/query = "SELECT m.round_id AS id, COALESCE(NULLIF(r.start_time, 0), MIN(NULLIF(m.logged_at, 0)), 0) AS start_time, r.end_time, COUNT(m.id) AS message_count, MAX(m.id) AS last_message_id FROM messages m LEFT JOIN rounds r ON r.id = m.round_id WHERE m.round_id IS NOT NULL AND m.round_id != ''"
	if(ckey)
		query += " AND m.ckey = ?"
	query += " GROUP BY m.round_id, r.start_time, r.end_time ORDER BY last_message_id DESC, m.round_id DESC LIMIT [sql_limit]"

	var/list/results
	if(ckey)
		results = vchat_exec_query(list(query, ckey))
	else
		results = vchat_exec_query(query)

	if(!islist(results))
		return list()

	var/list/output = list()
	for(var/list/row in results)
		if(!islist(row))
			continue

		var/round_id = row["id"]
		if(!istext(round_id) || !length(round_id))
			continue

		var/message_count = row["message_count"]
		if(istext(message_count))
			message_count = text2num(message_count)
		else if(!isnum(message_count))
			message_count = 0

		var/start_time = row["start_time"]
		if(istext(start_time))
			start_time = text2num(start_time)

		var/end_time = row["end_time"]
		if(istext(end_time))
			end_time = text2num(end_time)

		var/list/entry = list(
			"id" = round_id,
			"message_count" = message_count,
			"start_display" = vchat_format_round_timestamp(start_time) || vchat_format_round_id_timestamp(round_id),
			"end_display" = vchat_format_round_timestamp(end_time),
			"is_current" = (round_id == GLOB.vchat_current_round_id),
			"is_open" = (round_id == GLOB.vchat_current_round_id)
		)

		output += list(entry)

	return output

// RS Add End

#undef VCHAT_FILENAME
#undef VCHAT_ROUND_HISTORY // RS Add: undefine round history (Lira, September 2025)
