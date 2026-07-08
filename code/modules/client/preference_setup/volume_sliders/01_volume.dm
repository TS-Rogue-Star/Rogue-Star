/datum/category_group/player_setup_category/volume_sliders
	name = "Sound"
	sort_order = 7
	category_item_type = /datum/category_item/player_setup_item/volume_sliders

/datum/category_item/player_setup_item/volume_sliders/volume
	name = "General Volume"
	sort_order = 1

/datum/category_item/player_setup_item/volume_sliders/volume/load_preferences(var/savefile/S)
	S["volume_channels"] >> pref.volume_channels

/datum/category_item/player_setup_item/volume_sliders/volume/save_preferences(var/savefile/S)
	S["volume_channels"] << pref.volume_channels

/datum/category_item/player_setup_item/volume_sliders/volume/sanitize_preferences()
	if(isnull(pref.volume_channels))
		pref.volume_channels = list()

	for(var/channel in pref.volume_channels)
		if(!(channel in GLOB.all_volume_channels))
			// Channel no longer exists, yeet
			pref.volume_channels.Remove(channel)

	for(var/channel in GLOB.all_volume_channels)
		if(!(channel in pref.volume_channels))
			pref.volume_channels["[channel]"] = 1
		else
			pref.volume_channels["[channel]"] = clamp(pref.volume_channels["[channel]"], 0, 2)

// RS Edit: Sound preferences panel (Lira, June 2026)
/datum/category_item/player_setup_item/volume_sliders/volume/content(var/mob/user)
	. += "<b>Sound Settings</b><br>"
	. += "<a href='?src=\ref[src];open_sound_settings=1'>Open Sound Settings</a><br>"
	. += "<br>"

/datum/category_item/player_setup_item/volume_sliders/volume/OnTopic(var/href, var/list/href_list, var/mob/user)
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	if(href_list["open_sound_settings"])
		if(CanUseTopic(user))
			user?.client?.open_sound_settings_panel()
		return TOPIC_NOACTION
	// RS Add End
	if(href_list["change_volume"])
		if(CanUseTopic(user))
			var/channel = href_list["change_volume"]
			if(!(channel in pref.volume_channels))
				pref.volume_channels["[channel]"] = 1
			var/value = tgui_input_number(usr, "Choose your volume for [channel] (0-200%)", "[channel] volume", (pref.volume_channels[channel] * 100), 200, 0)
			if(isnum(value))
				value = CLAMP(value, 0, 200)
				pref.volume_channels["[channel]"] = (value / 100)
				// RS Add: Browser-based instrument audio (Lira, March 2026)
				if(channel == VOLUME_CHANNEL_MASTER || channel == VOLUME_CHANNEL_INSTRUMENTS)
					user?.client?.refresh_instrument_audio()
			return TOPIC_REFRESH
	return ..()

/mob/proc/get_preference_volume_channel(volume_channel)
	if(!client)
		return 0
	return client.get_preference_volume_channel(volume_channel)

/client/proc/get_preference_volume_channel(volume_channel)
	if(!volume_channel || !prefs)
		return 1
	if(!(volume_channel in prefs.volume_channels))
		prefs.volume_channels["[volume_channel]"] = 1
	return prefs.volume_channels["[volume_channel]"]


// Neat little volume adjuster thing in case you don't wanna touch preferences by hand you lazy fuck
/datum/volume_panel
/datum/volume_panel/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/volume_panel/tgui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VolumePanel", "Sound Settings") // RS Edit: Sound preferences panel (Lira, June 2026)
		ui.open()

/datum/volume_panel/tgui_data(mob/user)
	if(!user.client || !user.client.prefs)
		return list("error" = TRUE)

	var/list/data = ..()
	// RS Edit Start: Sound preferences panel (Lira, June 2026)
	var/datum/preferences/P = user.client.prefs
	data["volume_channels"] = P.volume_channels
	data["media_volume"] = P.media_volume
	data["media_player"] = P.media_player
	data["media_players"] = list(
		list("id" = 2, "label" = "HTML5"),
		list("id" = 1, "label" = "WMP"),
		list("id" = 0, "label" = "VLC")
	)
	data["sound_preferences"] = build_sound_preferences(user)
	// RS Edit End
	return data

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/build_sound_preferences(mob/user)
	. = list()
	if(!user?.client?.prefs)
		return

	var/list/group_order = list(
		SOUND_PANEL_GROUP_MUSIC,
		SOUND_PANEL_GROUP_WORLD,
		SOUND_PANEL_GROUP_ITEMS,
		SOUND_PANEL_GROUP_CHAT,
		SOUND_PANEL_GROUP_VORE,
		SOUND_PANEL_GROUP_STAFF
	)

	for(var/group in group_order)
		var/list/group_preferences = list()
		for(var/datum/client_preference/client_pref as anything in get_client_preferences())
			if(client_pref.sound_panel_group != group)
				continue
			if(!client_pref.may_toggle(user))
				continue

			var/list/preference_entry = list(
				"key" = client_pref.key,
				"label" = client_pref.description,
				"enabled" = user.client.is_preference_enabled(client_pref.key),
				"enabled_label" = client_pref.enabled_description,
				"disabled_label" = client_pref.disabled_description,
				"sort_order" = client_pref.sound_panel_sort_order
			)
			insert_sound_preference(group_preferences, preference_entry)

		if(group == SOUND_PANEL_GROUP_WORLD)
			insert_sound_preference(group_preferences, build_ambience_chance_preference(user.client.prefs))

		if(length(group_preferences))
			. += list(list(
				"name" = group,
				"preferences" = group_preferences
			))

// RS Add: Sound preferences panel (Lira, July 2026)
/datum/volume_panel/proc/build_ambience_chance_preference(datum/preferences/P)
	var/current_chance = clamp(round(P.ambience_chance), 0, 100)
	return list(
		"key" = "AMBIENCE_CHANCE",
		"label" = "Ambience Chance",
		"type" = "input",
		"value" = current_chance,
		"tooltip" = "Input the chance you'd like to hear ambience played to you (On area change, or by random ambience). 35 means a 35% chance to play ambience. This is a range from 0-100. 0 disables ambience playing entirely. This is also affected by Ambience Frequency.",
		"sort_order" = 15
	)

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/insert_sound_preference(list/preference_list, list/preference_entry)
	var/insert_at = length(preference_list) + 1
	for(var/i = 1 to length(preference_list))
		var/list/existing_entry = preference_list[i]
		if(preference_entry["sort_order"] < existing_entry["sort_order"])
			insert_at = i
			break

	preference_list += list(preference_entry)
	for(var/i = length(preference_list), i > insert_at, i--)
		preference_list[i] = preference_list[i - 1]
	preference_list[insert_at] = preference_entry

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel
	var/client/owner
	var/next_slider_action = 0
	var/next_toggle_action = 0
	var/preferences_save_pending = FALSE
	var/preferences_save_timer

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/New(client/C)
	. = ..()
	owner = C

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/Destroy()
	flush_preferences_save()
	owner = null
	return ..()

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/can_accept_slider_action()
	if(world.time < next_slider_action)
		return FALSE

	next_slider_action = world.time + SOUND_PANEL_SLIDER_ACTION_DELAY
	return TRUE

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/can_accept_toggle_action()
	if(world.time < next_toggle_action)
		return FALSE

	next_toggle_action = world.time + SOUND_PANEL_TOGGLE_ACTION_DELAY
	return TRUE

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/param_number(value, default_value = 0)
	if(isnum(value))
		return value
	if(istext(value))
		var/parsed_value = text2num(value)
		if(isnum(parsed_value))
			return parsed_value
	return default_value

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/schedule_preferences_save()
	preferences_save_pending = TRUE
	if(preferences_save_timer)
		deltimer(preferences_save_timer)

	preferences_save_timer = addtimer(CALLBACK(src, PROC_REF(flush_preferences_save), TRUE), SOUND_PANEL_SAVE_DELAY, TIMER_STOPPABLE)

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/proc/flush_preferences_save(from_timer = FALSE)
	if(preferences_save_timer)
		if(!from_timer)
			deltimer(preferences_save_timer)
		preferences_save_timer = null

	if(!preferences_save_pending)
		return

	preferences_save_pending = FALSE
	if(owner?.prefs)
		SScharacter_setup.queue_preferences_save(owner.prefs)

// RS Add: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/tgui_close(mob/user)
	. = ..()
	flush_preferences_save()

// RS Edit: Sound preferences panel (Lira, June 2026)
/datum/volume_panel/tgui_act(action, params)
	if(..())
		return TRUE

	if(!usr?.client?.prefs)
		return FALSE

	var/datum/preferences/P = usr.client.prefs
	switch(action)
		if("adjust_volume")
			var/channel = params["channel"]
			if(channel in P.volume_channels)
				var/new_volume = clamp(param_number(params["vol"], P.volume_channels["[channel]"]), 0, 2)
				if(new_volume == P.volume_channels["[channel]"])
					return FALSE
				if(!can_accept_slider_action())
					return FALSE

				P.volume_channels["[channel]"] = new_volume
				schedule_preferences_save()
				// RS Add: Browser-based instrument audio (Lira, March 2026)
				if(channel == VOLUME_CHANNEL_MASTER || channel == VOLUME_CHANNEL_INSTRUMENTS)
					usr.client.refresh_instrument_audio()
				return TRUE
		if("set_media_volume")
			var/new_media_volume = clamp(param_number(params["volume"], P.media_volume), 0, 1)
			if(new_media_volume == P.media_volume)
				return FALSE
			if(!can_accept_slider_action())
				return FALSE

			P.media_volume = new_media_volume
			schedule_preferences_save()
			if(usr.client.media)
				usr.client.media.update_volume(P.media_volume)
			return TRUE
		if("set_media_player")
			var/new_player = sanitize_inlist(param_number(params["player"], P.media_player), list(0, 1, 2), P.media_player)
			if(new_player == P.media_player)
				return FALSE
			if(!can_accept_toggle_action())
				return FALSE

			P.media_player = new_player
			schedule_preferences_save()
			if(usr.client.media)
				usr.client.media.open()
				spawn(10)
					usr.update_music()
			return TRUE
		if("set_ambience_chance")
			var/new_ambience_chance = clamp(round(param_number(params["chance"], P.ambience_chance)), 0, 100)
			if(new_ambience_chance == P.ambience_chance)
				return FALSE
			if(!can_accept_slider_action())
				return FALSE

			P.ambience_chance = new_ambience_chance
			schedule_preferences_save()
			return TRUE
		if("set_preference")
			var/preference_key = params["key"]
			var/datum/client_preference/client_pref = get_client_preference(preference_key)
			if(!client_pref || !client_pref.sound_panel_group || !client_pref.may_toggle(usr))
				return FALSE

			var/enabled = param_number(params["enabled"], FALSE)
			if(enabled == usr.client.is_preference_enabled(client_pref.key))
				return FALSE
			if(!can_accept_toggle_action())
				return FALSE

			if(!usr.client.set_preference(client_pref.key, enabled))
				return FALSE

			schedule_preferences_save()
			return TRUE

// RS Edit: Sound preferences panel (Lira, June 2026)
/client/proc/open_sound_settings_panel()
	if(!volume_panel)
		volume_panel = new(src)

	volume_panel.tgui_interact(mob)

// RS Edit: Sound preferences panel (Lira, June 2026)
/client/verb/volume_panel()
	set name = "Sound Settings"
	set category = "Preferences"
	set desc = "Allows you to adjust sound settings on the fly."

	open_sound_settings_panel()
