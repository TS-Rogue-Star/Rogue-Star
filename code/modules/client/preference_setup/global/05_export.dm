//////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star January 2026: Export player save data //
//////////////////////////////////////////////////////////////////////////

GLOBAL_VAR_INIT(preferences_export_round_id, 1)

/hook/roundend/proc/advance_preferences_export_round()
	GLOB.preferences_export_round_id++
	return 1

/datum/category_item/player_setup_item/player_global/save_data
	name = "Save Data"
	sort_order = 5

/datum/category_item/player_setup_item/player_global/save_data/content(var/mob/user)
	. = "<b>Save Data:</b><br>"
	. += "Exports character data for all slots: <a href='?src=\ref[src];export_prefs=1'>Export</a><br>"

/datum/category_item/player_setup_item/player_global/save_data/OnTopic(var/href, var/list/href_list, var/mob/user)
	if(href_list["export_prefs"])
		if(!CanUseTopic(user))
			return TOPIC_NOACTION
		if(!ticker || ticker.current_state == GAME_STATE_INIT)
			to_chat(user, "<span class='warning'>Save data export is unavailable during server initialization.</span>")
			return TOPIC_NOACTION
		if(IsGuestKey(user.key))
			to_chat(user, "<span class='warning'>Guests cannot export save data.</span>")
			return TOPIC_NOACTION
		if(pref.last_preferences_export_round_id == GLOB.preferences_export_round_id)
			to_chat(user, "<span class='warning'>You can only export save data once per round.</span>")
			return TOPIC_NOACTION
		if(!pref.path || !fexists(pref.path))
			to_chat(user, "<span class='warning'>No saved preferences were found to export.</span>")
			return TOPIC_NOACTION

		var/export_ckey = pref.client_ckey
		if(!export_ckey)
			export_ckey = user.ckey
		if(!export_ckey)
			export_ckey = "player"

		var/export_name = "preferences_[export_ckey].sav"
		user << ftp(file(pref.path), export_name)
		pref.last_preferences_export_round_id = GLOB.preferences_export_round_id
		log_debug("[key_name(user)] exported preferences.sav via character setup.")
		to_chat(user, "<span class='notice'>Save data export started.</span>")
		return TOPIC_NOACTION

	return ..()
