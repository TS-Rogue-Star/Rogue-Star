/datum/category_item/player_setup_item/player_global/ui
	name = "UI"
	sort_order = 1

/datum/category_item/player_setup_item/player_global/ui/load_preferences(var/savefile/S)
	S["UI_style"]				>> pref.UI_style
	S["UI_style_color"]			>> pref.UI_style_color
	S["UI_style_alpha"]			>> pref.UI_style_alpha
	S["ooccolor"]				>> pref.ooccolor
	S["tooltipstyle"]			>> pref.tooltipstyle
	S["client_fps"]				>> pref.client_fps
	S["ambience_chance"] 		>> pref.ambience_chance
	S["tgui_fancy"]				>> pref.tgui_fancy
	S["tgui_lock"]				>> pref.tgui_lock
	S["tgui_input_mode"]		>> pref.tgui_input_mode
	S["tgui_input_lock"]		>> pref.tgui_input_lock
	S["tgui_large_buttons"]		>> pref.tgui_large_buttons
	S["tgui_swapped_buttons"]	>> pref.tgui_swapped_buttons
	S["tgui_input_window_scale"]	>> pref.tgui_input_window_scale // RS Add: TGUI window scaling (Lira, January 2026)
	// RS Add Start: Unified say/emote scaling (Lira, February 2026)
	S["tgui_input_say_whisper_width"]	>> pref.tgui_input_say_whisper_width
	S["tgui_input_say_whisper_height"]	>> pref.tgui_input_say_whisper_height
	S["tgui_input_emote_subtle_width"]	>> pref.tgui_input_emote_subtle_width
	S["tgui_input_emote_subtle_height"]	>> pref.tgui_input_emote_subtle_height
	// RS Add End
	S["chat_timestamp"]			>> pref.chat_timestamp

/datum/category_item/player_setup_item/player_global/ui/save_preferences(var/savefile/S)
	S["UI_style"]				<< pref.UI_style
	S["UI_style_color"]			<< pref.UI_style_color
	S["UI_style_alpha"]			<< pref.UI_style_alpha
	S["ooccolor"]				<< pref.ooccolor
	S["tooltipstyle"]			<< pref.tooltipstyle
	S["client_fps"]				<< pref.client_fps
	S["ambience_chance"] 		<< pref.ambience_chance
	S["tgui_fancy"]				<< pref.tgui_fancy
	S["tgui_lock"]				<< pref.tgui_lock
	S["tgui_input_mode"]		<< pref.tgui_input_mode
	S["tgui_input_lock"]		<< pref.tgui_input_lock
	S["tgui_large_buttons"]		<< pref.tgui_large_buttons
	S["tgui_swapped_buttons"]	<< pref.tgui_swapped_buttons
	S["tgui_input_window_scale"]	<< pref.tgui_input_window_scale // RS Add: TGUI window scaling (Lira, January 2026)
	// RS Add Start: Unified say/emote scaling (Lira, February 2026)
	S["tgui_input_say_whisper_width"]	<< pref.tgui_input_say_whisper_width
	S["tgui_input_say_whisper_height"]	<< pref.tgui_input_say_whisper_height
	S["tgui_input_emote_subtle_width"]	<< pref.tgui_input_emote_subtle_width
	S["tgui_input_emote_subtle_height"]	<< pref.tgui_input_emote_subtle_height
	// RS Add End
	S["chat_timestamp"]			<< pref.chat_timestamp

/datum/category_item/player_setup_item/player_global/ui/sanitize_preferences()
	pref.UI_style			= sanitize_inlist(pref.UI_style, all_ui_styles, initial(pref.UI_style))
	pref.UI_style_color		= sanitize_hexcolor(pref.UI_style_color, initial(pref.UI_style_color))
	pref.UI_style_alpha		= sanitize_integer(pref.UI_style_alpha, 0, 255, initial(pref.UI_style_alpha))
	pref.ooccolor			= sanitize_hexcolor(pref.ooccolor, initial(pref.ooccolor))
	pref.tooltipstyle		= sanitize_inlist(pref.tooltipstyle, all_tooltip_styles, initial(pref.tooltipstyle))
	pref.client_fps			= sanitize_integer(pref.client_fps, 0, MAX_CLIENT_FPS, initial(pref.client_fps))
	pref.ambience_chance 	= sanitize_integer(pref.ambience_chance, 0, 100, initial(pref.ambience_chance)) // 0-100 range.
	pref.tgui_fancy			= sanitize_integer(pref.tgui_fancy, 0, 1, initial(pref.tgui_fancy))
	pref.tgui_lock			= sanitize_integer(pref.tgui_lock, 0, 1, initial(pref.tgui_lock))
	pref.tgui_input_mode	= sanitize_integer(pref.tgui_input_mode, 0, 1, initial(pref.tgui_input_mode))
	pref.tgui_input_lock	= sanitize_integer(pref.tgui_input_lock, 0, 1, initial(pref.tgui_input_lock))
	pref.tgui_large_buttons	= sanitize_integer(pref.tgui_large_buttons, 0, 1, initial(pref.tgui_large_buttons))
	pref.tgui_swapped_buttons	= sanitize_integer(pref.tgui_swapped_buttons, 0, 1, initial(pref.tgui_swapped_buttons))
	pref.tgui_input_window_scale = sanitize_integer(pref.tgui_input_window_scale, 1, 3, initial(pref.tgui_input_window_scale)) // RS Add: TGUI window scaling (Lira, January 2026)
	// RS Add Start: Unified say/emote scaling (Lira, February 2026)
	pref.tgui_input_say_whisper_width = sanitize_integer(pref.tgui_input_say_whisper_width, 150, 20000, initial(pref.tgui_input_say_whisper_width))
	pref.tgui_input_say_whisper_height = sanitize_integer(pref.tgui_input_say_whisper_height, 50, 20000, initial(pref.tgui_input_say_whisper_height))
	pref.tgui_input_emote_subtle_width = sanitize_integer(pref.tgui_input_emote_subtle_width, 150, 20000, initial(pref.tgui_input_emote_subtle_width))
	pref.tgui_input_emote_subtle_height = sanitize_integer(pref.tgui_input_emote_subtle_height, 50, 20000, initial(pref.tgui_input_emote_subtle_height))
	// RS Add End
	pref.chat_timestamp		= sanitize_integer(pref.chat_timestamp, 0, 1, initial(pref.chat_timestamp))

/datum/category_item/player_setup_item/player_global/ui/content(var/mob/user)
	. = "" // RS Edit: Preference settings panel (Lira, July 2026)

/datum/category_item/player_setup_item/player_global/ui/OnTopic(var/href,var/list/href_list, var/mob/user)
	// RS Edit: Preference settings panel (Lira, July 2026)
	if(href_list["select_tooltip_style"] || href_list["select_client_fps"])
		return TOPIC_NOACTION
	/* //RS Edit. See PR #67 for reference. Commenting this out to prevent href hacks.
	else if(href_list["select_ambience_freq"])
		var/ambience_new = tgui_input_number(user, "Input how often you wish to hear ambience repeated! (1-60 MINUTES, 0 for disabled)", "Global Preference", pref.ambience_freq, 60, 0)
		if(isnull(ambience_new) || !CanUseTopic(user)) return TOPIC_NOACTION
		if(ambience_new < 0 || ambience_new > 60) return TOPIC_NOACTION
		pref.ambience_freq = ambience_new
		return TOPIC_REFRESH
	*/
	else if(href_list["select_ambience_chance"])
		return TOPIC_NOACTION // RS Edit: Sound preferences panel (Lira, July 2026)

	return ..()
