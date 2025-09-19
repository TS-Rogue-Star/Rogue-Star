//The 'V' is for 'VORE' but you can pretend it's for Vue.js if you really want.

////////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star September 2025 as part of a VChat enhancement package//
////////////////////////////////////////////////////////////////////////////////////////

//These are sent to the client via browse_rsc() in advance so the HTML can access them.
GLOBAL_LIST_INIT(vchatFiles, list(
	"code/modules/vchat/css/vchat-font-embedded.css",
	"code/modules/vchat/css/semantic.min.css",
	"code/modules/vchat/css/ss13styles.css",
	"code/modules/vchat/js/polyfills.min.js",
	"code/modules/vchat/js/vue.min.js",
	"code/modules/vchat/js/vchat.min.js"
))
// RS Add: Vchat category rules (Lira, September 2025)
GLOBAL_LIST_INIT(vchat_category_rules, list(
	list(
		category = "vc_localchat",
		matchers = list(
			list(include = list("filter_say")),
			list(include = list("say")),
			list(include = list("emote")),
			list(include = list("emote_subtle"))
		)
	),
	list(
		category = "vc_radio",
		matchers = list(
			list(include = list("filter_radio")),
			list(include = list("alert")),
			list(include = list("syndradio")),
			list(include = list("centradio")),
			list(include = list("airadio")),
			list(include = list("entradio")),
			list(include = list("comradio")),
			list(include = list("secradio")),
			list(include = list("engradio")),
			list(include = list("medradio")),
			list(include = list("sciradio")),
			list(include = list("supradio")),
			list(include = list("srvradio")),
			list(include = list("expradio")),
			list(include = list("radio")),
			list(include = list("deptradio")),
			list(include = list("newscaster"))
		)
	),
	list(
		category = "vc_info",
		matchers = list(
			list(include = list("filter_notice")),
			list(include = list("notice"), exclude = list("pm")),
			list(include = list("adminnotice")),
			list(include = list("info")),
			list(include = list("sinister")),
			list(include = list("cult"))
		)
	),
	list(
		category = "vc_warnings",
		matchers = list(
			list(include = list("filter_warning")),
			list(include = list("warning"), exclude = list("pm")),
			list(include = list("critical")),
			list(include = list("userdanger")),
			list(include = list("italics"))
		)
	),
	list(
		category = "vc_deadchat",
		matchers = list(
			list(include = list("filter_deadsay")),
			list(include = list("deadsay"))
		)
	),
	list(
		category = "vc_pray",
		matchers = list(
			list(include = list("filter_pray"))
		)
	),
	list(
		category = "vc_globalooc",
		matchers = list(
			list(include = list("ooc")),
			list(include = list("filter_ooc"))
		)
	),
	list(
		category = "vc_nif",
		matchers = list(
			list(include = list("nif"))
		)
	),
	list(
		category = "vc_mentor",
		matchers = list(
			list(include = list("mentor_channel")),
			list(include = list("mentor"))
		)
	),
	list(
		category = "vc_adminpm",
		matchers = list(
			list(include = list("filter_pm")),
			list(include = list("pm"))
		)
	),
	list(
		category = "vc_adminchat",
		matchers = list(
			list(include = list("filter_asay")),
			list(include = list("admin_channel"))
		)
	),
	list(
		category = "vc_modchat",
		matchers = list(
			list(include = list("filter_msay")),
			list(include = list("mod_channel"))
		)
	),
	list(
		category = "vc_eventchat",
		matchers = list(
			list(include = list("filter_esay")),
			list(include = list("event_channel"))
		)
	),
	list(
		category = "vc_combat",
		matchers = list(
			list(include = list("filter_combat")),
			list(include = list("danger"))
		)
	),
	list(
		category = "vc_adminlogs",
		matchers = list(
			list(include = list("filter_adminlogs")),
			list(include = list("log_message"))
		)
	),
	list(
		category = "vc_attacklogs",
		matchers = list(
			list(include = list("filter_attacklogs"))
		)
	),
	list(
		category = "vc_debuglogs",
		matchers = list(
			list(include = list("filter_debuglogs"))
		)
	),
	list(
		category = "vc_looc",
		matchers = list(
			list(include = list("looc"))
		)
	),
	list(
		category = "vc_rlooc",
		matchers = list(
			list(include = list("rlooc"))
		)
	),
	list(
		category = "vc_system",
		matchers = list(
			list(include = list("boldannounce")),
			list(include = list("filter_system"))
		)
	),
	list(
		category = "vc_unsorted",
		matchers = list(
			list(include = list("unsorted"))
		)
	)
))

// The to_chat() macro calls this proc
/proc/__to_chat(var/target, var/message)
	// First do logging in database
	if(isclient(target))
		var/client/C = target
		vchat_add_message(C.ckey, message)
	else if(ismob(target))
		var/mob/M = target
		if(M.ckey)
			vchat_add_message(M.ckey, message)
	else if(target == world)
		for(var/client/C in GLOB.clients)
			if(!QDESTROYING(C)) // Might be necessary?
				vchat_add_message(C.ckey, message)

	// Now lets either queue it for sending, or send it right now
	if(Master.current_runlevel == RUNLEVEL_INIT || !SSchat?.subsystem_initialized)
		to_chat_immediate(target, world.time, message)
	else
		SSchat.queue(target, world.time, message)

//This is used to convert icons to base64 <image> strings, because byond stores icons in base64 in savefiles.
GLOBAL_DATUM_INIT(iconCache, /savefile, new("data/iconCache.sav")) //Cache of icons for the browser output

// RS Add Start: Procs to support vchat update (Lira, September 2025)

// Return TRUE when a character should be treated as whitespace while trimming strings
/proc/vchat_is_whitespace_char(var/ch)
	if(!istext(ch) || !length(ch))
		return FALSE
	var/ascii_val = text2ascii(ch)
	if(isnull(ascii_val))
		return FALSE
	return ascii_val == 32 || ascii_val == 9 || ascii_val == 10 || ascii_val == 13

// Trim leading and trailing whitespace from strings used in filenames and payloads
/proc/vchat_trim_whitespace(var/text)
	if(!istext(text))
		return ""
	var/len = length(text)
	if(!len)
		return ""
	var/start = 1
	while(start <= len && vchat_is_whitespace_char(copytext(text, start, start + 1)))
		start++
	if(start > len)
		return ""
	var/finish = len + 1
	while(finish > start && vchat_is_whitespace_char(copytext(text, finish - 1, finish)))
		finish--
	return copytext(text, start, finish)

// Extract the class list
/proc/vchat_extract_span_classes(var/message)
	if(!istext(message))
		return list()

	var/lower_message = lowertext(message)
	var/start = findtext(lower_message, "<span")
	if(!start)
		return list()
	var/end = findtext(lower_message, ">", start)
	if(!end)
		return list()
	var/segment = copytext(message, start, end)
	var/segment_lower = lowertext(segment)

	var/class_pos = findtext(segment_lower, "class")
	if(!class_pos)
		return list()

	var/pos = class_pos + 5 // move to the character after "class"
	while(pos <= length(segment) && vchat_is_whitespace_char(copytext(segment_lower, pos, pos + 1)))
		pos++

	if(pos > length(segment) || copytext(segment, pos, pos + 1) != "=")
		return list()
	pos++

	while(pos <= length(segment) && vchat_is_whitespace_char(copytext(segment_lower, pos, pos + 1)))
		pos++

	if(pos > length(segment))
		return list()
	var/delim = copytext(segment, pos, pos + 1)
	if(!(delim == "\"" || delim == "'"))
		return list()

	var/value_start = pos + 1
	var/value_end = findtext(segment, delim, value_start)
	if(!value_end)
		value_end = length(segment) + 1
	var/class_text = lowertext(copytext(segment, value_start, value_end))
	class_text = replacetext(class_text, "\t", " ")
	class_text = replacetext(class_text, "\n", " ")
	while(findtext(class_text, "  "))
		class_text = replacetext(class_text, "  ", " ")

	var/list/classes = list()
	for(var/token in splittext(class_text, " "))
		if(!length(token))
			continue
		classes += token

	return classes

// Resolve a VChat category identifier from a stored message snippet
/proc/vchat_category_from_message(var/message)
	var/list/classes = vchat_extract_span_classes(message)
	if(!LAZYLEN(classes))
		return "vc_unsorted"

	var/list/class_lookup = list()
	for(var/class_name in classes)
		class_lookup[class_name] = TRUE

	for(var/list/rule_entry as anything in GLOB.vchat_category_rules)
		var/list/matchers = rule_entry["matchers"]
		if(!islist(matchers))
			continue

		for(var/list/matcher as anything in matchers)
			var/list/includes = matcher["include"]
			var/list/excludes = matcher["exclude"]
			var/matched = TRUE

			if(islist(includes))
				for(var/inc in includes)
					if(!class_lookup[inc])
						matched = FALSE
						break

			if(!matched)
				continue

			if(islist(excludes))
				for(var/exc in excludes)
					if(class_lookup[exc])
						matched = FALSE
						break

			if(matched)
				return rule_entry["category"]

	return "vc_unsorted"

// Return TRUE when the given category should appear in the current export set
/proc/vchat_allowed_category(var/list/categories, var/category)
	if(!LAZYLEN(categories))
		return TRUE
	return (category in categories)

// Format a message plus repeat counter for fallback HTML exports
/proc/vchat_format_saved_message(var/message, var/repeats)
	var/result = message
	if(repeats > 1)
		result += "(x[repeats])"
	result += "<br>\n"
	return result


// Prune unsafe characters from user supplied filenames prior to export
/proc/vchat_sanitize_filename(var/name)
	if(!istext(name))
		return null

	var/cleaned = vchat_trim_whitespace(copytext(name, 1, 128))
	if(!length(cleaned))
		return null

	var/list/output = list()
	for(var/i = 1, i <= length(cleaned), i++)
		var/ch = copytext(cleaned, i, i + 1)
		var/ascii_val = text2ascii(ch)
		if(isnull(ascii_val))
			continue
		if((ascii_val >= 48 && ascii_val <= 57) || (ascii_val >= 65 && ascii_val <= 90) || (ascii_val >= 97 && ascii_val <= 122))
			output += ch
		else if(ch == " " || ch == "-" || ch == "_" || ch == "(" || ch == ")" || ch == ".")
			output += ch
		else
			output += "_"

	var/result = vchat_trim_whitespace(list2text(output, ""))
	if(!length(result))
		return null

	if(!findtext(result, ".html"))
		result += ".html"

	return result

// RS Add End

//The main object attached to clients, created when they connect, and has start() called on it in client/New()
/datum/chatOutput
	var/client/owner = null
	var/loaded = FALSE
	var/list/message_queue = list()
	var/broken = FALSE
	var/resources_sent = FALSE
	var/message_buffer = 200 // Number of messages being actively shown to the user, used to play back that many messages on reconnect

	var/last_topic_time = 0
	var/too_many_topics = 0
	var/topic_spam_limit = 10 //Just enough to get over the startup and such

/datum/chatOutput/New(client/C)
	. = ..()

	owner = C

/datum/chatOutput/Destroy()
	owner = null
	. = ..()

// RSEdit Start
/datum/chatOutput/proc/update_vis()
	if(!loaded && !broken)
		// Only show loading
		output_winset(html = FALSE, loading = TRUE, oldchat = FALSE)
	else if(broken)
		// Only show oldchat, as 'broken' is overloaded as an oldchat-enable toggle
		output_winset(html = FALSE, loading = FALSE, oldchat = TRUE)
	else if(loaded)
		// Only show htmloutput
		output_winset(html = TRUE, loading = FALSE, oldchat = FALSE)

// Redid all these to fix stupid client bug in ~515.1642
// Seems like the bug is that controls refuse to accept is-visible and many other settings 'sometimes'
// But seem to accept 'some' other settings like pos and size which can be used to hide them
/datum/chatOutput/proc/output_winset(html, loading, oldchat)
	if(html)
		winset(owner, "htmloutput", "is-visible=true;pos=0,0;size=0x0")
	else
		winset(owner, "htmloutput", "is-visible=false;pos=999,999;size=1x1")

	if(loading)
		winset(owner, "chatloadlabel", "is-visible=true;pos=0,0;size=0x0")
	else
		winset(owner, "chatloadlabel", "is-visible=false;pos=999,999;size=1x1")

	if(oldchat)
		winset(owner, "oldoutput", "is-visible=true;pos=0,0;size=0x0")
	else
		winset(owner, "oldoutput", "is-visible=false;pos=999,999;size=1x1")
// RSEdit End

//Shove all the assets at them
/datum/chatOutput/proc/send_resources()
	for(var/filename in GLOB.vchatFiles)
		owner << browse_rsc(file(filename))
	resources_sent = TRUE

//Called from client/New() in a spawn()
/datum/chatOutput/proc/start()
	if(!owner)
		qdel(src)
		return FALSE

	if(!winexists(owner, "htmloutput"))
		tgui_alert_async(owner, "Updated chat window does not exist. If you are using a custom skin file please allow the game to update.")
		become_broken()
		return FALSE

	if(!owner?.is_preference_enabled(/datum/client_preference/vchat_enable))
		become_broken()
		return FALSE

	//Could be loaded from a previous round, are you still there?
	if(winget(owner,"outputwindow.htmloutput","is-visible") == "true") //Winget returns strings
		send_event(event = list("evttype" = "availability"))
		sleep(3 SECONDS)

	if(!owner) // In case the client vanishes before winexists returns
		qdel(src)
		return FALSE

	if(!loaded)
		update_vis()
		if(!resources_sent)
			send_resources()
		load()

	return TRUE

//Attempts to actually load the HTML page into the client's UI
/datum/chatOutput/proc/load()
	if(!owner)
		qdel(src)
		return

	owner << browse(file2text("code/modules/vchat/html/vchat.html"), "window=htmloutput")

	//Check back later
	spawn(15 SECONDS)
		if(!src)
			return
		if(!src.loaded)
			src.become_broken()

//var/list/joins = list() //Just for testing with the below
//Called by Topic, when the JS in the HTML page finishes loading
/datum/chatOutput/proc/done_loading()
	if(loaded)
		return

	loaded = TRUE
	broken = FALSE
	owner.chatOutputLoadedAt = world.time

	update_vis() //It does it's own winsets //RS Edit: Well, sometimes it does.
	ping_cycle()
	send_playerinfo()
	load_database()

	owner.verbs += /client/proc/vchat_export_log

//Perform DB shenanigans
/datum/chatOutput/proc/load_database()
	set waitfor = FALSE
	// Only send them the number of buffered messages, instead of the ENTIRE log
	var/list/results = vchat_get_messages(owner.ckey, message_buffer, GLOB.vchat_current_round_id) //If there's bad performance on reconnects, look no further || RS Edit: Add round ID (Lira, September 2025)
	if(islist(results))
		for(var/i in results.len to 1 step -1)
			var/list/message = results[i]
			var/count = 10
			to_chat_immediate(owner, message["time"], message["message"])
			count++
			if(count >= 10)
				count = 0
				CHECK_TICK

//It din work
/datum/chatOutput/proc/become_broken()
	broken = TRUE
	loaded = FALSE

	if(!owner)
		qdel(src)
		return

	update_vis()

	spawn()
	if(owner.is_preference_enabled(/datum/client_preference/vchat_enable))
		tgui_alert_async(owner,"VChat didn't load after some time. Switching to use oldchat as a fallback. Try using 'Reload VChat' verb in OOC verbs, or reconnecting to try again.")

//Provide the JS with who we are
/datum/chatOutput/proc/send_playerinfo()
	if(!owner)
		qdel(src)
		return

	var/list/playerinfo = list("evttype" = "byond_player", "cid" = owner.computer_id, "ckey" = owner.ckey, "address" = owner.address, "admin" = owner.holder ? "true" : "false")
	send_event(playerinfo)

//Ugh byond doesn't handle UTF-8 well so we have to do this.
/proc/jsEncode(var/list/message) {
	if(!islist(message))
		CRASH("Passed a non-list to encode.")

	return url_encode(url_encode(json_encode(message)))
}

//Send a side-channel event to the chat window
/datum/chatOutput/proc/send_event(var/event, var/client/C = owner)
	C << output(jsEncode(event), "htmloutput:get_event")

//Looping sleeping proc that just pings the client and dies when we die
/datum/chatOutput/proc/ping_cycle()
	set waitfor = FALSE
	while(!QDELING(src))
		if(!owner)
			qdel(src)
			return
		send_event(event = keep_alive())
		sleep(20 SECONDS) //Make sure this makes sense with what the js client is expecting

//Just produces a message for using in keepalives from the server to the client
/datum/chatOutput/proc/keep_alive()
	return list("evttype" = "keepalive")

//A response to a latency check from the client
/datum/chatOutput/proc/latency_check()
	return list("evttype" = "pong")

//Redirected from client/Topic when the user clicks a link that pertains directly to the chat (when src == "chat")
/datum/chatOutput/Topic(var/href, var/list/href_list)
	if(usr.client != owner)
		return 1

	if(last_topic_time > (world.time - 3 SECONDS))
		too_many_topics++
		if(too_many_topics >= topic_spam_limit)
			log_and_message_admins("Kicking [key_name(owner)] - VChat Topic() spam")
			to_chat(owner,"<span class='danger'>You have been kicked due to VChat sending too many messages to the server. Try reconnecting.</span>")
			qdel(owner)
			qdel(src)
			return
	else
		too_many_topics = 0
	last_topic_time = world.time

	var/list/params = list()
	for(var/key in href_list)
		if(length(key) > 7 && findtext(key, "param"))
			var/param_name = copytext(key, 7, -1)
			var/item = href_list[key]
			params[param_name] = item

	var/data
	switch(href_list["proc"])
		if("not_ready")
			CRASH("Tried to send a message to [owner.ckey] chatOutput before it was ready!")
		if("done_loading")
			data = done_loading(arglist(params))
		if("ping")
			data = latency_check(arglist(params))
		if("ident")
			data = bancheck(arglist(params))
		if("unloading")
			loaded = FALSE
		if("debug")
			data = debugmsg(arglist(params))
		// RS Add Start: Refs for vchat update (Lira, September 2025)
		if("save_chatlog")
			save_chatlog_request(arglist(params))
		if("request_rounds")
			data = round_list_request(arglist(params))
		if("request_history")
			data = round_history_request(arglist(params))
		// RS Add End

	if(href_list["showingnum"])
		message_buffer = CLAMP(text2num(href_list["showingnum"]), 50, 2000)

	if(data)
		send_event(event = data)

//Print a message that was an error from a client
/datum/chatOutput/proc/debugmsg(var/message = "No String Provided")
	log_debug("VChat: [owner] got: [message]")

//Check relevant client info reported from JS
/datum/chatOutput/proc/bancheck(var/clientdata)
	var/list/info = json_decode(clientdata)
	var/ckey = info["ckey"]
	var/ip = info["ip"]
	var/cid = info["cid"]

	//Never connected? How sad!
	if(!cid && !ip && !ckey)
		return

	if(cid && !isnum(cid) && !(cid == ""))
		log_and_message_admins("[key_name(owner)] - bancheck with invalid cid! ([cid])")

	if(ip && !findtext(ip, new/regex(@"^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$")) && !(ip == ""))
		log_and_message_admins("[key_name(owner)] - bancheck with invalid ip! ([ip])")

	var/list/ban = world.IsBanned(key = ckey, address = ip, computer_id = cid)
	if(ban)
		log_and_message_admins("[key_name(owner)] has a cookie from a banned account! (Cookie: [ckey], [ip], [cid])")

// RS Add Start: Save and history procs (Lira, September 2025)

// Handle save chatlog
/datum/chatOutput/proc/save_chatlog_request(var/data)
	if(!owner || !data)
		return

	var/list/payload
	if(istext(data))
		payload = json_decode(data)
	else if(islist(data))
		payload = data

	if(!islist(payload))
		return

	var/list/categories = list()
	if(islist(payload["categories"]))
		for(var/category in payload["categories"])
			if(istext(category))
				categories += category

	var/filename = null
	if(istext(payload["filename"]))
		filename = vchat_sanitize_filename(payload["filename"])

	var/round_id = null
	var/use_all_rounds = FALSE
	if(istext(payload["round_id"]))
		var/tmp_round = vchat_trim_whitespace(payload["round_id"])
		if(length(tmp_round))
			if(lowertext(tmp_round) == "all")
				use_all_rounds = TRUE
			else
				round_id = tmp_round

	save_chatlog_to_disk(categories, filename, round_id, use_all_rounds)

// Compile the saved round overview sent to the client history UI
/datum/chatOutput/proc/round_list_request()
	if(!owner)
		return list("evttype" = "round_list", "rounds" = list(), "error" = "Client unavailable")

	var/list/rounds = vchat_get_round_overview(owner.ckey)
	if(!islist(rounds))
		rounds = list()

	var/total_messages = 0
	for(var/list/entry in rounds)
		if(!islist(entry))
			continue
		var/count = entry["message_count"]
		if(istext(count))
			count = text2num(count)
		if(isnum(count))
			total_messages += count

	return list(
		"evttype" = "round_list",
		"rounds" = rounds,
		"round_total" = rounds.len,
		"total_messages" = total_messages,
		"current_round_id" = GLOB.vchat_current_round_id)

// Fetch stored chat messages for a specific round or all rounds on demand
/datum/chatOutput/proc/round_history_request(var/data)
	if(!owner)
		return list("evttype" = "round_history", "round_id" = null, "messages" = list(), "error" = "Client unavailable", "current_round_id" = GLOB.vchat_current_round_id)

	var/list/payload
	if(istext(data))
		payload = json_decode(data)
	else if(islist(data))
		payload = data

	var/round_id = null
	var/use_all_rounds = FALSE
	var/source = null
	if(islist(payload))
		if(istext(payload["round_id"]))
			var/tmp_round = vchat_trim_whitespace(payload["round_id"])
			if(length(tmp_round))
				if(lowertext(tmp_round) == "all")
					use_all_rounds = TRUE
				else
					round_id = tmp_round
		if(istext(payload["source"]))
			source = payload["source"]

	if(isnull(round_id) && !use_all_rounds)
		round_id = GLOB.vchat_current_round_id

	var/list/messages = vchat_get_messages(owner.ckey, null, use_all_rounds ? null : round_id)
	if(!LAZYLEN(messages))
		return list(
			"evttype" = "round_history",
			"round_id" = round_id,
			"messages" = list(),
			"error" = "No messages found for that round.",
			"current_round_id" = GLOB.vchat_current_round_id,
			"use_all_rounds" = use_all_rounds)

	var/list/output = list()
	var/message_count = 0
	for(var/list/entry in messages)
		if(!islist(entry))
			continue
		var/msg_text = entry["message"]
		if(!istext(msg_text))
			continue
		var/logged_at = entry["logged_at"]
		if(istext(logged_at))
			logged_at = text2num(logged_at)
		if(!isnum(logged_at))
			logged_at = 0
		var/world_time = entry["worldtime"]
		if(istext(world_time))
			world_time = text2num(world_time)
		var/list/output_line = list(
			"content" = msg_text,
			"logged_at" = logged_at,
			"worldtime" = world_time)
		output += list(output_line)
		message_count++
		CHECK_TICK

	return list(
		"evttype" = "round_history",
		"round_id" = round_id,
		"messages" = output,
		"message_count" = message_count,
		"current_round_id" = GLOB.vchat_current_round_id,
		"use_all_rounds" = use_all_rounds,
		"source" = source)

// Perform the server-side chatlog export workflow and stream the file to the client
/datum/chatOutput/proc/save_chatlog_to_disk(var/list/categories, var/filename, var/round_id, var/use_all_rounds = FALSE)
	if(!owner)
		return

	if(isnull(round_id) && !use_all_rounds)
		round_id = GLOB.vchat_current_round_id

	var/list/messages = vchat_get_messages(owner.ckey, null, use_all_rounds ? null : round_id)
	if(!LAZYLEN(messages))
		to_chat(owner, "<span class='warning'>Error: No messages found! Please inform a dev if you do have messages!</span>")
		return

	var/list/allowed_categories = list()
	if(LAZYLEN(categories))
		for(var/category in categories)
			if(istext(category))
				allowed_categories += category

	var/list/output_lines = list()
	var/last_message
	var/last_category
	var/repeat_count = 0

	for(var/list/result in messages)
		var/message = result["message"]
		if(!istext(message))
			continue

		var/category = vchat_category_from_message(message)
		if(!vchat_allowed_category(allowed_categories, category))
			continue

		if(last_message && last_category == category && last_message == message)
			repeat_count++
			continue

		if(last_message)
			output_lines += vchat_format_saved_message(last_message, repeat_count)

		last_message = message
		last_category = category
		repeat_count = 1
		CHECK_TICK

	if(last_message)
		output_lines += vchat_format_saved_message(last_message, repeat_count)

	if(!output_lines.len)
		to_chat(owner, "<span class='warning'>Error: No messages matched the selected filters.</span>")
		return

	var/text_blob = "<html><head><style>"
	text_blob += file2text(file("code/modules/vchat/css/ss13styles.css"))
	text_blob += "</style></head><body>"
	text_blob += list2text(output_lines, "")
	text_blob += "</body></html>"

	var/tmp_path = "data/chatlog_tmp/[owner.ckey]_client_chat_log"
	if(fexists(tmp_path) && !fdel(tmp_path))
		to_chat(owner, "<span class='warning'>Error: Your chat log is already being prepared. Please wait until it's been downloaded before trying again.</span>")
		return

	rustg_file_write(text_blob, tmp_path)

	var/export_name = filename
	if(!istext(export_name) || !length(export_name))
		var/date_segment = time2text(world.timeofday, "YYYY_MM_DD_(hh_mm)")
		export_name = "log_[date_segment].html"

	owner << ftp(file(tmp_path), export_name)

	spawn(10 SECONDS)
		if(fexists(tmp_path) && !fdel(tmp_path))
			spawn(1 MINUTE)
				if(fexists(tmp_path) && !fdel(tmp_path))
					log_debug("Warning: [owner.ckey]'s chatlog could not be deleted one minute after file transfer was initiated. It is located at '[tmp_path]' and will need to be manually removed.")

// RS Add End

//Converts an icon to base64. Operates by putting the icon in the iconCache savefile,
// exporting it as text, and then parsing the base64 from that.
// (This relies on byond automatically storing icons in savefiles as base64)
/proc/icon2base64(var/icon/icon, var/iconKey = "misc")
	if (!isicon(icon)) return FALSE

	GLOB.iconCache[iconKey] << icon
	var/iconData = GLOB.iconCache.ExportText(iconKey)
	var/list/partial = splittext(iconData, "{")
	return replacetext(copytext(partial[2], 3, -5), "\n", "")

/proc/expire_bicon_cache(key)
	if(GLOB.bicon_cache[key])
		GLOB.bicon_cache -= key
		return TRUE
	return FALSE

GLOBAL_LIST_EMPTY(bicon_cache) // Cache of the <img> tag results, not the icons
/proc/bicon(var/obj, var/use_class = 1, var/custom_classes = "")
	var/class = use_class ? "class='icon misc [custom_classes]'" : null
	if(!obj)
		return

	// Try to avoid passing bicon an /icon directly. It is better to pass it an atom so it can cache.
	if(isicon(obj)) // Passed an icon directly, nothing to cache-key on, as icon refs get reused *often*
		return "<img [class] src='data:image/png;base64,[icon2base64(obj)]'>"

	// Either an atom or somebody fucked up and is gonna get a runtime, which I'm fine with.
	var/atom/A = obj
	var/key
	var/changes_often = ishuman(A) || isobserver(A) // If this ends up with more, move it into a proc or var on atom.

	if(changes_often)
		key = "\ref[A]"
	else
		key = "[istype(A.icon, /icon) ? "\ref[A.icon]" : A.icon]:[A.icon_state]"

	var/base64 = GLOB.bicon_cache[key]
	// Non-human atom, no cache
	if(!base64) // Doesn't exist, make it.
		base64 = icon2base64(A.examine_icon(), key)
		GLOB.bicon_cache[key] = base64
		if(changes_often)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(expire_bicon_cache), key), 50 SECONDS, TIMER_UNIQUE) //RS Edit: Global Proc so needs global ref (Lira, August 2025)

	// May add a class to the img tag created by bicon
	if(use_class)
		class = "class='icon [A.icon_state] [custom_classes]'"

	return "<IMG [class] src='data:image/png;base64,[base64]'>"

//Checks if the message content is a valid to_chat message
/proc/is_valid_tochat_message(message)
	return istext(message)

//Checks if the target of to_chat is something we can send to
/proc/is_valid_tochat_target(target)
	return !istype(target, /savefile) && (ismob(target) || islist(target) || isclient(target) || target == world)

var/to_chat_filename
var/to_chat_line
var/to_chat_src

//This proc is only really used if the SSchat subsystem is unavailable (not started yet)
/proc/to_chat_immediate(target, time, message)
	if(!is_valid_tochat_message(message) || !is_valid_tochat_target(target))
		target << message

		// Info about the "message"
		if(isnull(message))
			message = "(null)"
		else if(istype(message, /datum))
			var/datum/D = message
			message = "([D.type]): '[D]'"
		else if(!is_valid_tochat_message(message))
			message = "(bad message) : '[message]'"

		// Info about the target
		var/targetstring = "'[target]'"
		if(istype(target, /datum))
			var/datum/D = target
			targetstring += ", [D.type]"

		// The final output
		log_debug("to_chat called with invalid message/target: [to_chat_filename], [to_chat_line], [to_chat_src], Message: '[message]', Target: [targetstring]")
		return

	else if(is_valid_tochat_message(message))
		if(istext(target))
			log_debug("Somehow, to_chat got a text as a target")
			return

		var/original_message = message
		message = replacetext(message, "\n", "<br>")
		message = replacetext(message, "\improper", "")
		message = replacetext(message, "\proper", "")

		if(isnull(time))
			time = world.time

		var/client/C = CLIENT_FROM_VAR(target)
		if(!C)
			return // No client? No care.
		else if(C.chatOutput.broken)
			DIRECT_OUTPUT(C, original_message)
			return
		else if(!C.chatOutput.loaded)
			return // If not loaded yet, do nothing and history-sending on load will get it.

		var/list/tojson = list("time" = time, "message" = message);
		target << output(jsEncode(tojson), "htmloutput:putmessage")

/client/proc/vchat_export_log()
	set name = "Export chatlog"
	set category = "OOC"

	if(chatOutput.broken)
		to_chat(src, "<span class='warning'>Error: VChat isn't processing your messages!</span>")
		return

	var/list/results = vchat_get_messages(ckey, null, GLOB.vchat_current_round_id) // RS Edit: Add round ID (Lira, September 2025)
	if(!LAZYLEN(results))
		to_chat(src, "<span class='warning'>Error: No messages found! Please inform a dev if you do have messages!</span>")
		return

	var/o_file = "data/chatlog_tmp/[ckey]_chat_log"
	if(fexists(o_file) && !fdel(o_file))
		to_chat(src, "<span class='warning'>Error: Your chat log is already being prepared. Please wait until it's been downloaded before trying to export it again.</span>")
		return

	// Write the CSS file to the log
	var/text_blob = "<html><head><style>"
	text_blob += file2text(file("code/modules/vchat/css/ss13styles.css"))
	text_blob += "</style></head><body>"

	// Write the messages to the log
	for(var/list/result in results)
		text_blob += "[result["message"]]<br>"
		CHECK_TICK

	text_blob += "</body></html>"

	rustg_file_write(text_blob, o_file)

	// Send the log to the client
	src << ftp(file(o_file), "log_[time2text(world.timeofday, "YYYY_MM_DD_(hh_mm)")].html")

	// clean up the file on our end
	spawn(10 SECONDS)
		if(!fdel(o_file))
			spawn(1 MINUTE)
				if(!fdel(o_file))
					log_debug("Warning: [ckey]'s chatlog could not be deleted one minute after file transfer was initiated. It is located at 'data/chatlog_tmp/[ckey]_chat_log' and will need to be manually removed.")
