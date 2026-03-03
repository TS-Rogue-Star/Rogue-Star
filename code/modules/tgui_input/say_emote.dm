//////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star February 2026: TGUI interface for says, emotes, and related verbs //
//////////////////////////////////////////////////////////////////////////////////////////////////////

#define UNIFIED_SAY_EMOTE_MAX_LEN 8192
#define UNIFIED_SAY_EMOTE_WINDOW_TITLE "Text Input"
#define UNIFIED_SAY_EMOTE_DEFAULT_WIDTH 460
#define UNIFIED_SAY_EMOTE_DEFAULT_HEIGHT 259
#define UNIFIED_SAY_EMOTE_MIN_WIDTH 150
#define UNIFIED_SAY_EMOTE_MAX_WIDTH 20000
#define UNIFIED_SAY_EMOTE_MIN_HEIGHT 50
#define UNIFIED_SAY_EMOTE_MAX_HEIGHT 20000
#define UNIFIED_SAY_EMOTE_BUCKET_SAY_WHISPER "say_whisper"
#define UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE "emote_subtle"

/proc/sanitize_unified_say_emote_channel(choice, fallback = "say")
	var/static/list/valid_channels = list("say", "emote", "whisper", "subtle", "custom_subtle", "psay", "pme", "nsay", "nme", "ooc", "looc")
	var/channel = lowertext("[choice]")
	if(channel in valid_channels)
		return channel
	var/fallback_channel = lowertext("[fallback]")
	if(fallback_channel in valid_channels)
		return fallback_channel
	return "say"

/proc/sanitize_unified_say_emote_vore_mode(choice, fallback = "none")
	var/static/list/valid_modes = list("none", "pred", "prey")
	var/mode = lowertext("[choice]")
	if(mode in valid_modes)
		return mode
	var/fallback_mode = lowertext("[fallback]")
	if(fallback_mode in valid_modes)
		return fallback_mode
	return "none"

/proc/tgui_input_say_emote(mob/user, title = "Communication", initial_mode = "say", initial_subtle = FALSE, prompt = "Type your message:", initial_channel = null)
	if(istext(user))
		stack_trace("tgui_input_say_emote() received text for user instead of mob")
		return
	if(!user)
		user = usr
	if(!istype(user))
		if(istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			return

	var/mode = lowertext("[initial_mode]") == "emote" ? "emote" : "say"
	var/subtle_enabled = initial_subtle ? TRUE : FALSE
	var/default_channel = (mode == "emote") ? (subtle_enabled ? "subtle" : "emote") : (subtle_enabled ? "whisper" : "say")
	var/channel = sanitize_unified_say_emote_channel(initial_channel, default_channel)
	switch(channel)
		if("say")
			mode = "say"
			subtle_enabled = FALSE
		if("emote")
			mode = "emote"
			subtle_enabled = FALSE
		if("whisper")
			mode = "say"
			subtle_enabled = TRUE
		if("subtle")
			mode = "emote"
			subtle_enabled = TRUE
		if("custom_subtle")
			mode = "emote"
			subtle_enabled = TRUE
		if("psay")
			mode = "say"
			subtle_enabled = TRUE
		if("pme")
			mode = "emote"
			subtle_enabled = TRUE
		if("nsay")
			mode = "say"
			subtle_enabled = FALSE
		if("nme")
			mode = "emote"
			subtle_enabled = FALSE
		if("ooc", "looc")
			mode = "say"
			subtle_enabled = FALSE
	var/subtle_mode = sanitize_subtle_mode_choice(user.client?.tgui_input_round_subtle_mode)
	var/multiline = (mode == "emote")

	if(!user.client.prefs.tgui_input_mode)
		var/message = tgui_input_text(user, prompt, title, multiline = multiline, use_message_window_scale = multiline)
		if(!message)
			return
		return list(
			"message" = message,
			"mode" = mode,
			"subtle" = subtle_enabled,
			"subtle_mode" = subtle_mode,
			"channel" = channel,
			"emote_vore_mode" = "none"
		)

	if(length(user.tgui_open_uis))
		for(var/datum/tgui/open_ui in user.tgui_open_uis)
			if(open_ui?.interface == "UnifiedSayEmoteInput" && !open_ui.closing && open_ui.status > STATUS_CLOSE)
				return

	var/datum/tgui_input_say_emote/input = new(
		user = user,
		title = title,
		initial_mode = mode,
		initial_subtle = subtle_enabled,
		initial_subtle_mode = subtle_mode,
		prompt = prompt,
		initial_channel = channel
	)
	input.tgui_interact(user)
	input.wait()
	if(input)
		. = input.get_result()
		qdel(input)

/datum/tgui_input_say_emote
	var/mob/owner
	var/title
	var/prompt
	var/mode = "say"
	var/channel = "say"
	var/subtle_enabled = FALSE
	var/subtle_mode = "Adjacent Turfs (Default)"
	var/emote_vore_mode = "none"
	var/window_width = UNIFIED_SAY_EMOTE_DEFAULT_WIDTH
	var/window_height = UNIFIED_SAY_EMOTE_DEFAULT_HEIGHT
	var/entry
	var/submitted = FALSE
	var/closed = FALSE

/datum/tgui_input_say_emote/New(
	mob/user,
	title,
	initial_mode,
	initial_subtle,
	initial_subtle_mode,
	prompt,
	initial_channel)
	owner = user
	src.title = UNIFIED_SAY_EMOTE_WINDOW_TITLE
	src.prompt = prompt || "Type your message:"
	mode = lowertext("[initial_mode]") == "emote" ? "emote" : "say"
	subtle_enabled = initial_subtle ? TRUE : FALSE
	channel = sanitize_unified_say_emote_channel(initial_channel, (mode == "emote") ? (subtle_enabled ? "subtle" : "emote") : (subtle_enabled ? "whisper" : "say"))
	set_channel(channel)
	subtle_mode = sanitize_subtle_mode_choice(initial_subtle_mode)
	load_window_size_for_bucket(get_window_size_bucket())

/datum/tgui_input_say_emote/Destroy(force, ...)
	SStgui.close_uis(src)
	. = ..()

/datum/tgui_input_say_emote/proc/wait()
	while(!submitted && !closed && !QDELETED(src))
		stoplag(1)

/datum/tgui_input_say_emote/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "UnifiedSayEmoteInput", title)
		var/window_owner = user?.client?.ckey || "guest"
		ui.window_key = "unified-say-emote-[window_owner]"
		ui.open()

/datum/tgui_input_say_emote/tgui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/tgui_input_say_emote/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/tgui_input_say_emote/tgui_static_data(mob/user)
	var/list/data = list()
	data["large_buttons"] = user.client.prefs.tgui_large_buttons
	data["max_length"] = UNIFIED_SAY_EMOTE_MAX_LEN
	data["message"] = prompt
	data["subtle_mode_options"] = get_subtle_mode_options()
	data["swapped_buttons"] = !user.client.prefs.tgui_swapped_buttons
	data["title"] = title
	return data

/datum/tgui_input_say_emote/tgui_data(mob/user)
	var/list/data = list()
	var/autowhisper_mode_display = owner?.autowhisper_mode
	if(!autowhisper_mode_display)
		autowhisper_mode_display = "Default whisper/subtle"
	data["mode"] = mode
	data["channel"] = channel
	data["subtle_enabled"] = subtle_enabled
	data["subtle_mode"] = subtle_mode
	data["emote_vore_mode"] = emote_vore_mode
	data["autowhisper_enabled"] = owner?.autowhisper ? TRUE : FALSE
	data["autowhisper_mode"] = autowhisper_mode_display
	data["window_width"] = window_width
	data["window_height"] = window_height
	data["size_bucket"] = get_window_size_bucket()
	return data

/datum/tgui_input_say_emote/tgui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("set_channel")
			set_channel(params["channel"])
			return TRUE
		if("set_mode")
			set_mode(params["mode"])
			return TRUE
		if("toggle_subtle")
			if(channel == "ooc" || channel == "looc")
				return TRUE
			subtle_enabled = !subtle_enabled
			channel = (mode == "emote") ? (subtle_enabled ? "subtle" : "emote") : (subtle_enabled ? "whisper" : "say")
			return TRUE
		if("set_subtle_mode")
			set_subtle_mode(params["subtle_mode"])
			return TRUE
		if("set_emote_vore_mode")
			set_emote_vore_mode(params["emote_vore_mode"])
			return TRUE
		if("remember_window_size")
			remember_window_size(params["width"], params["height"])
			return TRUE
		if("save_window_pref")
			save_window_pref(params["width"], params["height"])
			return TRUE
		if("submit")
			remember_window_size(params["width"], params["height"])
			set_entry(params["entry"])
			set_emote_vore_mode(params["emote_vore_mode"])
			submitted = TRUE
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE
		if("cancel")
			remember_window_size(params["width"], params["height"])
			emote_vore_mode = "none"
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE

/datum/tgui_input_say_emote/proc/set_mode(next_mode)
	mode = (lowertext("[next_mode]") == "emote") ? "emote" : "say"
	channel = (mode == "emote") ? (subtle_enabled ? "subtle" : "emote") : (subtle_enabled ? "whisper" : "say")

/datum/tgui_input_say_emote/proc/set_channel(next_channel)
	channel = sanitize_unified_say_emote_channel(next_channel, "say")
	switch(channel)
		if("say")
			mode = "say"
			subtle_enabled = FALSE
		if("emote")
			mode = "emote"
			subtle_enabled = FALSE
		if("whisper")
			mode = "say"
			subtle_enabled = TRUE
		if("subtle")
			mode = "emote"
			subtle_enabled = TRUE
		if("custom_subtle")
			mode = "emote"
			subtle_enabled = TRUE
		if("psay")
			mode = "say"
			subtle_enabled = TRUE
		if("pme")
			mode = "emote"
			subtle_enabled = TRUE
		if("nsay")
			mode = "say"
			subtle_enabled = FALSE
		if("nme")
			mode = "emote"
			subtle_enabled = FALSE
		if("ooc", "looc")
			mode = "say"
			subtle_enabled = FALSE
		else
			mode = "say"
			subtle_enabled = FALSE

/datum/tgui_input_say_emote/proc/set_subtle_mode(next_subtle_mode)
	subtle_mode = sanitize_subtle_mode_choice(next_subtle_mode)
	if(owner?.client)
		owner.client.tgui_input_round_subtle_mode = subtle_mode

/datum/tgui_input_say_emote/proc/set_emote_vore_mode(next_mode)
	emote_vore_mode = sanitize_unified_say_emote_vore_mode(next_mode, "none")

/datum/tgui_input_say_emote/proc/get_window_size_bucket()
	return (mode == "emote") ? UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE : UNIFIED_SAY_EMOTE_BUCKET_SAY_WHISPER

/datum/tgui_input_say_emote/proc/sanitize_window_width(value, fallback = UNIFIED_SAY_EMOTE_DEFAULT_WIDTH)
	return sanitize_integer(value, UNIFIED_SAY_EMOTE_MIN_WIDTH, UNIFIED_SAY_EMOTE_MAX_WIDTH, fallback)

/datum/tgui_input_say_emote/proc/sanitize_window_height(value, fallback = UNIFIED_SAY_EMOTE_DEFAULT_HEIGHT)
	return sanitize_integer(value, UNIFIED_SAY_EMOTE_MIN_HEIGHT, UNIFIED_SAY_EMOTE_MAX_HEIGHT, fallback)

/datum/tgui_input_say_emote/proc/load_window_size_for_bucket(bucket)
	var/client/C = owner?.client
	var/width = UNIFIED_SAY_EMOTE_DEFAULT_WIDTH
	var/height = UNIFIED_SAY_EMOTE_DEFAULT_HEIGHT

	if(C?.prefs)
		if(bucket == UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE)
			width = sanitize_window_width(C.prefs.tgui_input_emote_subtle_width, width)
			height = sanitize_window_height(C.prefs.tgui_input_emote_subtle_height, height)
		else
			width = sanitize_window_width(C.prefs.tgui_input_say_whisper_width, width)
			height = sanitize_window_height(C.prefs.tgui_input_say_whisper_height, height)

	if(C)
		if(bucket == UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE)
			if(isnum(C.tgui_input_round_emote_subtle_width))
				width = sanitize_window_width(C.tgui_input_round_emote_subtle_width, width)
			if(isnum(C.tgui_input_round_emote_subtle_height))
				height = sanitize_window_height(C.tgui_input_round_emote_subtle_height, height)
		else
			if(isnum(C.tgui_input_round_say_whisper_width))
				width = sanitize_window_width(C.tgui_input_round_say_whisper_width, width)
			if(isnum(C.tgui_input_round_say_whisper_height))
				height = sanitize_window_height(C.tgui_input_round_say_whisper_height, height)

	window_width = width
	window_height = height

/datum/tgui_input_say_emote/proc/remember_window_size(next_width, next_height)
	var/client/C = owner?.client
	if(!C)
		return

	var/bucket = get_window_size_bucket()
	var/safe_width = sanitize_window_width(next_width, window_width)
	var/safe_height = sanitize_window_height(next_height, window_height)

	window_width = safe_width
	window_height = safe_height

	if(bucket == UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE)
		C.tgui_input_round_emote_subtle_width = safe_width
		C.tgui_input_round_emote_subtle_height = safe_height
	else
		C.tgui_input_round_say_whisper_width = safe_width
		C.tgui_input_round_say_whisper_height = safe_height

/datum/tgui_input_say_emote/proc/save_window_pref(next_width, next_height)
	remember_window_size(next_width, next_height)

	var/client/C = owner?.client
	if(!C?.prefs)
		return

	var/bucket = get_window_size_bucket()
	if(bucket == UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE)
		C.prefs.tgui_input_emote_subtle_width = window_width
		C.prefs.tgui_input_emote_subtle_height = window_height
	else
		C.prefs.tgui_input_say_whisper_width = window_width
		C.prefs.tgui_input_say_whisper_height = window_height

	SScharacter_setup.queue_preferences_save(C.prefs)
	if(owner)
		var/bucket_label = (bucket == UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE) ? "Emote/Subtle" : "Say/Whisper"
		to_chat(owner, "<span class='notice'>Saved [bucket_label] window size to [window_width]x[window_height].</span>")

/datum/tgui_input_say_emote/proc/set_entry(new_entry)
	if(isnull(new_entry))
		entry = null
		return
	var/text_entry = "[new_entry]"
	entry = trim(text_entry, UNIFIED_SAY_EMOTE_MAX_LEN)

/datum/tgui_input_say_emote/proc/get_result()
	if(!submitted)
		return null
	return list(
		"message" = entry,
		"mode" = mode,
		"subtle" = subtle_enabled,
		"subtle_mode" = subtle_mode,
		"channel" = channel,
		"emote_vore_mode" = emote_vore_mode
	)

#undef UNIFIED_SAY_EMOTE_MAX_LEN
#undef UNIFIED_SAY_EMOTE_WINDOW_TITLE
#undef UNIFIED_SAY_EMOTE_DEFAULT_WIDTH
#undef UNIFIED_SAY_EMOTE_DEFAULT_HEIGHT
#undef UNIFIED_SAY_EMOTE_MIN_WIDTH
#undef UNIFIED_SAY_EMOTE_MAX_WIDTH
#undef UNIFIED_SAY_EMOTE_MIN_HEIGHT
#undef UNIFIED_SAY_EMOTE_MAX_HEIGHT
#undef UNIFIED_SAY_EMOTE_BUCKET_SAY_WHISPER
#undef UNIFIED_SAY_EMOTE_BUCKET_EMOTE_SUBTLE
