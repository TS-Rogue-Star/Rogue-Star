/datum/preferences
	var/preferences_enabled = null
	var/preferences_disabled = null

/datum/category_item/player_setup_item/player_global/settings
	name = "Settings"
	sort_order = 2

/datum/category_item/player_setup_item/player_global/settings/load_preferences(var/savefile/S)
	S["lastchangelog"]        >> pref.lastchangelog
	S["lastnews"]             >> pref.lastnews
	S["lastlorenews"]         >> pref.lastlorenews
	S["default_slot"]	      >> pref.default_slot
	S["preferences"]          >> pref.preferences_enabled
	S["preferences_disabled"] >> pref.preferences_disabled

/datum/category_item/player_setup_item/player_global/settings/save_preferences(var/savefile/S)
	S["lastchangelog"]        << pref.lastchangelog
	S["lastnews"]             << pref.lastnews
	S["lastlorenews"]         << pref.lastlorenews
	S["default_slot"]         << pref.default_slot
	S["preferences"]          << pref.preferences_enabled
	S["preferences_disabled"] << pref.preferences_disabled

/datum/category_item/player_setup_item/player_global/settings/sanitize_preferences()
	// Ensure our preferences are lists.
	if(!istype(pref.preferences_enabled, /list))
		pref.preferences_enabled = list()
	if(!istype(pref.preferences_disabled, /list))
		pref.preferences_disabled = list()

	// Arrange preferences that have never been enabled/disabled.
	var/list/client_preference_keys = list()
	for(var/datum/client_preference/client_pref as anything in get_client_preferences())
		client_preference_keys += client_pref.key
		if((client_pref.key in pref.preferences_enabled) || (client_pref.key in pref.preferences_disabled))
			continue

		if(client_pref.enabled_by_default)
			pref.preferences_enabled += client_pref.key
		else
			pref.preferences_disabled += client_pref.key

	// Clean out preferences that no longer exist.
	for(var/key in pref.preferences_enabled)
		if(!(key in client_preference_keys))
			pref.preferences_enabled -= key
	for(var/key in pref.preferences_disabled)
		if(!(key in client_preference_keys))
			pref.preferences_disabled -= key

	pref.lastchangelog	= sanitize_text(pref.lastchangelog, initial(pref.lastchangelog))
	pref.lastnews		= sanitize_text(pref.lastnews, initial(pref.lastnews))
	pref.default_slot	= sanitize_integer(pref.default_slot, 1, config.character_slots, initial(pref.default_slot))

// RS Edit: Preference settings panel (Lira, July 2026)
/datum/category_item/player_setup_item/player_global/settings/content(var/mob/user)
	. = list()
	. += "<b>Preferences</b><br>"
	. += "<a href='?src=\ref[src];open_preference_settings=1'>Open Preference Settings</a><br>"
	. += "<br>"
	return jointext(., "")

// RS Edit: Sound preferences panel (Lira, June 2026) || Preference settings panel (Lira, July 2026)
/datum/category_item/player_setup_item/player_global/settings/OnTopic(var/href,var/list/href_list, var/mob/user)
	var/mob/pref_mob = preference_mob()
	var/preference_key
	var/datum/client_preference/client_pref
	if(href_list["open_preference_settings"])
		if(CanUseTopic(user))
			user?.client?.open_preference_settings_panel()
		return TOPIC_NOACTION
	else if(href_list["toggle_on"])
		preference_key = href_list["toggle_on"]
		client_pref = get_client_preference(preference_key)
		if(client_pref?.sound_panel_group || client_pref?.settings_panel_group)
			return TOPIC_NOACTION
		. = pref_mob.set_preference(preference_key, TRUE)
	else if(href_list["toggle_off"])
		preference_key = href_list["toggle_off"]
		client_pref = get_client_preference(preference_key)
		if(client_pref?.sound_panel_group || client_pref?.settings_panel_group)
			return TOPIC_NOACTION
		. = pref_mob.set_preference(preference_key, FALSE)
	if(.)
		return TOPIC_REFRESH

	return ..()

/**
 * This can take either a single preference datum or a list of preferences, and will return true if *all* preferences in the arguments are enabled.
 */
/client/proc/is_preference_enabled(var/preference)
	if(!islist(preference))
		preference = list(preference)
	for(var/p in preference)
		var/datum/client_preference/cp = get_client_preference(p)
		if(!prefs || !cp || !(cp.key in prefs.preferences_enabled))
			return FALSE
	return TRUE

/client/proc/set_preference(var/preference, var/set_preference)
	var/datum/client_preference/cp = get_client_preference(preference)
	if(!cp)
		return FALSE
	preference = cp.key

	if(set_preference && !(preference in prefs.preferences_enabled))
		return toggle_preference(cp)
	else if(!set_preference && (preference in prefs.preferences_enabled))
		return toggle_preference(cp)

/client/proc/toggle_preference(var/preference, var/set_preference)
	var/datum/client_preference/cp = get_client_preference(preference)
	if(!cp)
		return FALSE
	preference = cp.key

	var/enabled
	if(preference in prefs.preferences_disabled)
		prefs.preferences_enabled  |= preference
		prefs.preferences_disabled -= preference
		enabled = TRUE
		. = TRUE
	else if(preference in prefs.preferences_enabled)
		prefs.preferences_enabled  -= preference
		prefs.preferences_disabled |= preference
		enabled = FALSE
		. = TRUE
	if(.)
		cp.toggled(mob, enabled)

/mob/proc/is_preference_enabled(var/preference)
	if(!client)
		return FALSE
	return client.is_preference_enabled(preference)

/mob/proc/set_preference(var/preference, var/set_preference)
	if(!client)
		return FALSE
	if(!client.prefs)
		log_debug("Client prefs found to be null for mob [src] and client [ckey], this should be investigated.")
		return FALSE

	return client.set_preference(preference, set_preference)

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel
	var/client/owner
	var/next_toggle_action = 0
	var/preferences_save_pending = FALSE
	var/preferences_save_timer

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/New(client/C)
	. = ..()
	owner = C

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/Destroy()
	flush_preferences_save()
	owner = null
	return ..()

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/tgui_state(mob/user)
	return GLOB.tgui_always_state

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/tgui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PreferenceSettings", "Preference Settings")
		ui.open()

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/tgui_data(mob/user)
	if(!user.client || !user.client.prefs)
		return list("error" = TRUE)

	var/list/data = ..()
	data["preference_groups"] = build_preference_groups(user)
	return data

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/proc/build_preference_groups(mob/user)
	. = list()
	if(!user?.client?.prefs)
		return

	var/list/group_order = list(
		PREFERENCE_SETTINGS_GROUP_INTERFACE,
		PREFERENCE_SETTINGS_GROUP_CHAT,
		PREFERENCE_SETTINGS_GROUP_RUNECHAT,
		PREFERENCE_SETTINGS_GROUP_GAMEPLAY,
		PREFERENCE_SETTINGS_GROUP_STAFF
	)

	for(var/group in group_order)
		var/list/group_preferences = list()
		for(var/datum/client_preference/client_pref as anything in get_client_preferences())
			if(client_pref.settings_panel_group != group)
				continue
			if(client_pref.sound_panel_group)
				continue
			if(!client_pref.may_toggle(user))
				continue

			var/enabled = user.client.is_preference_enabled(client_pref.key)
			var/list/preference_entry = list(
				"key" = client_pref.key,
				"label" = client_pref.description,
				"enabled" = enabled,
				"enabled_label" = client_pref.enabled_description,
				"disabled_label" = client_pref.disabled_description,
				"tooltip" = client_pref.settings_panel_tooltip,
				"sort_order" = client_pref.settings_panel_sort_order
			)
			insert_preference(group_preferences, preference_entry)

		if(group == PREFERENCE_SETTINGS_GROUP_CHAT)
			var/list/chat_timestamps_entry = list(
				"key" = "CHAT_TIMESTAMPS",
				"label" = "Chat Timestamps",
				"type" = "toggle",
				"enabled" = user.client.prefs.chat_timestamp ? TRUE : FALSE,
				"enabled_label" = "Enabled",
				"disabled_label" = "Disabled",
				"tooltip" = "Toggles whether or not messages in chat will display timestamps. Enabling this will not add timestamps to messages that have already been sent.",
				"sort_order" = 45
			)
			insert_preference(group_preferences, chat_timestamps_entry)

		if(group == PREFERENCE_SETTINGS_GROUP_STAFF && can_select_ooc_color(user))
			var/using_default_ooc_color = (user.client.prefs.ooccolor == initial(user.client.prefs.ooccolor))
			var/list/ooc_color_entry = list(
				"key" = "OOC_COLOR",
				"label" = "OOC Color",
				"type" = "color",
				"value" = user.client.prefs.ooccolor,
				"display_value" = using_default_ooc_color ? "Using Default" : user.client.prefs.ooccolor,
				"using_default" = using_default_ooc_color,
				"enabled" = TRUE,
				"enabled_label" = "",
				"disabled_label" = "",
				"tooltip" = "Choose a distinct color that is easy to read and does not mix with other chat and radio frequency colors.",
				"sort_order" = 80
			)
			insert_preference(group_preferences, ooc_color_entry)

		if(length(group_preferences))
			. += list(list(
				"name" = group,
				"preferences" = group_preferences
			))

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/proc/insert_preference(list/preference_list, list/preference_entry)
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

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/proc/can_accept_toggle_action()
	if(world.time < next_toggle_action)
		return FALSE

	next_toggle_action = world.time + PREFERENCE_SETTINGS_TOGGLE_ACTION_DELAY
	return TRUE

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/proc/param_number(value, default_value = 0)
	if(isnum(value))
		return value
	if(istext(value))
		var/parsed_value = text2num(value)
		if(isnum(parsed_value))
			return parsed_value
	return default_value

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/proc/schedule_preferences_save()
	preferences_save_pending = TRUE
	if(preferences_save_timer)
		deltimer(preferences_save_timer)

	preferences_save_timer = addtimer(CALLBACK(src, PROC_REF(flush_preferences_save), TRUE), PREFERENCE_SETTINGS_SAVE_DELAY, TIMER_STOPPABLE)

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/proc/flush_preferences_save(from_timer = FALSE)
	if(preferences_save_timer)
		if(!from_timer)
			deltimer(preferences_save_timer)
		preferences_save_timer = null

	if(!preferences_save_pending)
		return

	preferences_save_pending = FALSE
	if(owner?.prefs)
		SScharacter_setup.queue_preferences_save(owner.prefs)

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/tgui_close(mob/user)
	. = ..()
	flush_preferences_save()

// RS Add: Preference settings panel (Lira, July 2026)
/datum/preference_settings_panel/tgui_act(action, params)
	if(..())
		return TRUE

	if(!usr?.client?.prefs)
		return FALSE

	var/mob/preference_mob = usr

	switch(action)
		if("set_ooc_color")
			if(!can_select_ooc_color(preference_mob))
				return FALSE
			if(!can_accept_toggle_action())
				return FALSE

			var/new_ooccolor = input(preference_mob, "Choose OOC color:", "OOC Color", preference_mob.client.prefs.ooccolor) as color|null
			if(isnull(new_ooccolor) || !preference_mob?.client?.prefs || !can_select_ooc_color(preference_mob))
				return FALSE

			var/safe_ooccolor = sanitize_hexcolor(new_ooccolor, null)
			if(!safe_ooccolor || safe_ooccolor == preference_mob.client.prefs.ooccolor)
				return FALSE

			preference_mob.client.prefs.ooccolor = safe_ooccolor
			schedule_preferences_save()
			return TRUE

		if("reset_ooc_color")
			if(!can_select_ooc_color(preference_mob))
				return FALSE
			if(preference_mob.client.prefs.ooccolor == initial(preference_mob.client.prefs.ooccolor))
				return FALSE
			if(!can_accept_toggle_action())
				return FALSE

			preference_mob.client.prefs.ooccolor = initial(preference_mob.client.prefs.ooccolor)
			schedule_preferences_save()
			return TRUE

		if("set_preference")
			var/preference_key = params["key"]
			if(preference_key == "CHAT_TIMESTAMPS")
				var/enabled = param_number(params["enabled"], FALSE)
				if(enabled == (usr.client.prefs.chat_timestamp ? TRUE : FALSE))
					return FALSE
				if(!can_accept_toggle_action())
					return FALSE

				usr.client.prefs.chat_timestamp = enabled ? TRUE : FALSE
				schedule_preferences_save()
				return TRUE

			var/datum/client_preference/client_pref = get_client_preference(preference_key)
			if(!client_pref || !client_pref.settings_panel_group || client_pref.sound_panel_group || !client_pref.may_toggle(usr))
				return FALSE

			var/enabled = param_number(params["enabled"], FALSE)
			if(enabled == usr.client.is_preference_enabled(client_pref.key))
				return FALSE
			if(!can_accept_toggle_action())
				return FALSE

			if(client_pref.type == /datum/client_preference/vchat_enable && usr.client.chatOutputLoadedAt > (world.time - 5 SECONDS))
				tgui_alert_async(usr, "You can't swap chats more than once within 5 seconds.")
				return FALSE

			if(!usr.client.set_preference(client_pref.key, enabled))
				return FALSE

			schedule_preferences_save()
			if(client_pref.type == /datum/client_preference/vchat_enable)
				usr.client.reload_vchat()
			return TRUE

// RS Add: Preference settings panel (Lira, July 2026)
/client/proc/open_preference_settings_panel()
	if(!preference_settings_panel)
		preference_settings_panel = new(src)

	preference_settings_panel.tgui_interact(mob)

// RS Add: Preference settings panel (Lira, July 2026)
/client/verb/preference_settings_panel()
	set name = "Preference Settings"
	set category = "Preferences"
	set desc = "Allows you to adjust general preference toggles."

	open_preference_settings_panel()

// RS Add: Preference settings panel (Lira, July 2026)
/proc/can_select_ooc_color(var/mob/user)
	return config.allow_admin_ooccolor && check_rights(R_ADMIN|R_EVENT|R_FUN, 0, user)
