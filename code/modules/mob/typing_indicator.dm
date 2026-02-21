/proc/generate_speech_bubble(var/bubble_loc, var/speech_state, var/set_layer = FLOAT_LAYER)
	var/image/I = image('icons/mob/talk_vr.dmi', bubble_loc, speech_state, set_layer)  //VOREStation Edit - talk_vr.dmi instead of talk.dmi for right-side icons
	I.appearance_flags |= (RESET_COLOR|PIXEL_SCALE)			//VOREStation Edit
	/*			//VOREStation Removal Start
	if(istype(bubble_loc, /atom/movable))
		var/atom/movable/AM = bubble_loc
		var/x_scale = AM.get_icon_scale_x()
		if(abs(x_scale) < 2) // reset transform on bubbles, except for the Very Large
			I.pixel_z = (AM.icon_expected_height * (x_scale-1))
			I.appearance_flags |= RESET_TRANSFORM
	*/			//VOREStation Removal Start
	return I

/mob/proc/init_typing_indicator(var/set_state = "typing")
	if(typing_indicator)
		qdel(typing_indicator)
		typing_indicator = null
	typing_indicator = new
	typing_indicator.appearance = generate_speech_bubble(null, set_state)
	typing_indicator.appearance_flags |= (RESET_COLOR|PIXEL_SCALE)			//VOREStation Edit

/mob/proc/set_typing_indicator(var/state) //Leaving this here for mobs.

	// RS Add: Support for typing indicator enhancement (Lira, October 2025)
	if(!state)
		input_typing_indicator_active = FALSE

	if(!is_preference_enabled(/datum/client_preference/show_typing_indicator))
		if(typing_indicator)
			cut_overlay(typing_indicator, TRUE)
		// RS Add Start: Support for typing indicator enhancement (Lira, October 2025)
		typing = FALSE
		typing_indicator_active = null
		// RS Add End
		return

	var/cur_bubble_appearance = custom_speech_bubble
	if(!cur_bubble_appearance || cur_bubble_appearance == "default")
		cur_bubble_appearance = speech_bubble_appearance()
	if(!typing_indicator || cur_typing_indicator != cur_bubble_appearance)
		init_typing_indicator("[cur_bubble_appearance]_typing")

	if(state && !typing)
		add_overlay(typing_indicator, TRUE)
		typing = TRUE
		typing_indicator_active = typing_indicator
	else if(typing)
		cut_overlay(typing_indicator_active, TRUE)
		typing = FALSE
		if(typing_indicator_active != typing_indicator)
			qdel(typing_indicator_active)
		typing_indicator_active = null

	return state

// RS Add Start: Support for typing indicator enhancement (Lira, October 2025)

/mob/verb/typing_indicator_focus()
	set name = ".TypingIndicatorFocus"
	set hidden = 1

	if(!client)
		return

	input_typing_focus = TRUE
	start_input_typing_indicator_monitor()

/mob/verb/typing_indicator_blur()
	set name = ".TypingIndicatorBlur"
	set hidden = 1

	if(!client || !input_typing_focus)
		return

	lose_input_typing_focus()

#define TYPING_INDICATOR_POLL 10
#define TYPING_INDICATOR_INPUT_CONTROL "mainwindow.input"

/mob/proc/lose_input_typing_focus()
	if(!input_typing_focus)
		return

	input_typing_focus = FALSE
	stop_input_typing_indicator_monitor()

	if(input_typing_indicator_active)
		input_typing_indicator_active = FALSE
		set_typing_indicator(FALSE)

/mob/proc/start_input_typing_indicator_monitor()
	if(input_typing_timer_id || !client)
		return

	schedule_input_typing_indicator_check(TYPING_INDICATOR_POLL)

/mob/proc/stop_input_typing_indicator_monitor()
	if(input_typing_timer_id)
		deltimer(input_typing_timer_id)
		input_typing_timer_id = null

/mob/proc/update_input_typing_indicator()
	input_typing_timer_id = null

	if(!client)
		lose_input_typing_focus()
		return

	if(!input_typing_focus)
		return

	var/current_focus = winget(client, null, "focus")
	if(current_focus != TYPING_INDICATOR_INPUT_CONTROL)
		lose_input_typing_focus()
		return

	var/input_text = winget(client, "input", "text")
	var/should_show = should_input_trigger_typing_indicator(input_text)

	if(should_show)
		if(!input_typing_indicator_active)
			input_typing_indicator_active = TRUE
			set_typing_indicator(TRUE)
	else if(input_typing_indicator_active)
		input_typing_indicator_active = FALSE
		set_typing_indicator(FALSE)

	schedule_input_typing_indicator_check(TYPING_INDICATOR_POLL)

/mob/proc/schedule_input_typing_indicator_check(var/delay)
	if(input_typing_timer_id || !client)
		return
	input_typing_timer_id = addtimer(CALLBACK(src, PROC_REF(update_input_typing_indicator)), delay, TIMER_STOPPABLE)

/mob/proc/should_input_trigger_typing_indicator(var/input_text)
	if(!input_text)
		return FALSE

	var/trimmed = trim_left(input_text)
	if(!length(trimmed))
		return FALSE

	var/lowered = lowertext(trimmed)
	if(startswith(lowered, "say "))
		return has_say_message_after_prefix(trimmed, "say ")
	if(startswith(lowered, "me "))
		return has_non_space_after_prefix(trimmed, "me ")

	return FALSE

/mob/proc/startswith(var/text, var/prefix)
	if(length(text) < length(prefix))
		return FALSE
	return copytext(text, 1, length(prefix) + 1) == prefix

/mob/proc/has_non_space_after_prefix(var/text, var/prefix)
	if(length(text) <= length(prefix))
		return FALSE
	var/remainder = copytext(text, length(prefix) + 1)
	return length(trim_left(remainder)) > 0

/mob/proc/has_say_message_after_prefix(var/text, var/prefix)
	if(length(text) <= length(prefix))
		return FALSE
	var/remainder = trim_left(copytext(text, length(prefix) + 1))
	if(!length(remainder))
		return FALSE
	if(copytext(remainder, 1, 2) == "\"")
		var/after_quote = copytext(remainder, 2)
		return length(trim_left(after_quote)) > 0
	return TRUE

#undef TYPING_INDICATOR_POLL
#undef TYPING_INDICATOR_INPUT_CONTROL

// RS Add End

// RS Add: TGUI emote interface (Lira, February 2026)
/mob/proc/dispatch_unified_say_emote_input(var/list/input_payload)
	if(!islist(input_payload))
		return

	var/message = input_payload["message"]
	if(!message)
		return

	var/mode = lowertext("[input_payload["mode"]]")
	var/subtle_enabled = input_payload["subtle"] ? TRUE : FALSE
	var/subtle_mode = input_payload["subtle_mode"]
	var/emote_vore_mode = sanitize_unified_say_emote_vore_mode(input_payload["emote_vore_mode"], "none")
	var/default_channel = (mode == "emote") ? (subtle_enabled ? "subtle" : "emote") : (subtle_enabled ? "whisper" : "say")
	var/channel = sanitize_unified_say_emote_channel(input_payload["channel"], default_channel)

	if(channel == "ooc")
		client?.submit_ooc_message(message)
		return

	if(channel == "looc")
		client?.submit_looc_message(message)
		return

	if(channel == "psay")
		psay(message)
		return

	if(channel == "pme")
		pme(message)
		return

	if(channel == "nsay")
		nsay(message)
		return

	if(channel == "nme")
		nme(message)
		return

	if(subtle_mode == "Psay/Pme")
		if(channel == "subtle")
			pme(message)
			return
		if(channel == "custom_subtle")
			pme(message)
			return
		if(channel == "whisper")
			psay(message)
			return

	var/message_sent = FALSE
	switch(channel)
		if("emote")
			message_sent = me_verb(message) ? TRUE : FALSE
		if("subtle")
			message_sent = me_verb_subtle(message) ? TRUE : FALSE
		if("custom_subtle")
			message_sent = me_verb_subtle_with_mode(message, subtle_mode) ? TRUE : FALSE
		if("whisper")
			message_sent = whisper(message) ? TRUE : FALSE
		else
			message_sent = say_verb(message) ? TRUE : FALSE

	if(message_sent && emote_vore_mode != "none" && istype(src, /mob/living))
		if(channel == "say" || channel == "whisper" || channel == "emote" || channel == "subtle" || channel == "custom_subtle")
			var/mob/living/L = src
			L.handle_emote_vore_mode(emote_vore_mode)

/mob/verb/say_wrapper()
	set name = ".Say"
	set hidden = 1

	set_typing_indicator(TRUE)
	var/list/input_payload = tgui_input_say_emote(usr, "Say", "say", FALSE, "Type your message:") // RS Edit: TGUI emote interface (Lira, February 2026)
	set_typing_indicator(FALSE)
	dispatch_unified_say_emote_input(input_payload) // RS Edit: TGUI emote interface (Lira, February 2026)

/mob/verb/me_wrapper()
	set name = ".Me"
	set hidden = 1

	set_typing_indicator(TRUE)
	var/list/input_payload = tgui_input_say_emote(usr, "Emote", "emote", FALSE, "Type your message:") // RS Edit: TGUI emote interface (Lira, February 2026)
	set_typing_indicator(FALSE)
	dispatch_unified_say_emote_input(input_payload) // RS Add: TGUI emote interface (Lira, February 2026)

// RS Add Start: New client communication verbs that call the hotkey wrappers (Lira, October 2025, February 2026)
/client/verb/say_panel()
	set name = "Say"
	set category = "IC"

	if(!mob)
		return

	mob.say_wrapper()

/client/verb/me_panel()
	set name = "Me"
	set category = "IC"

	if(!mob)
		return

	mob.me_wrapper()

/client/verb/whisper_panel()
	set name = "Whisper"
	set category = "IC"

	if(!mob)
		return

	mob.whisper_wrapper()

/client/verb/subtle_panel()
	set name = "Subtle"
	set category = "IC"

	if(!mob)
		return

	mob.subtle_wrapper()

/client/verb/subtle_custom_panel()
	set name = "Subtle (Custom)"
	set category = "IC"

	if(!mob)
		return

	mob.subtle_custom_wrapper()

/client/verb/psay_panel()
	set name = "Psay"
	set category = "IC"

	if(!mob)
		return

	mob.psay(null)

/client/verb/pme_panel()
	set name = "Pme"
	set category = "IC"

	if(!mob)
		return

	mob.pme(null)
// RS Add End

// No typing indicators here, but this is the file where the wrappers are, so...
/mob/verb/whisper_wrapper()
	set name = ".Whisper"
	set hidden = 1

	// RS Edit Start: TGUI emote interface (Lira, February 2026)
	var/list/input_payload = tgui_input_say_emote(usr, "Whisper", "say", TRUE, "Type your message:")
	dispatch_unified_say_emote_input(input_payload)
	// RS Edit End

/mob/verb/subtle_wrapper()
	set name = ".Subtle"
	set hidden = 1

	// RS Edit Start: TGUI emote interface (Lira, February 2026)
	var/list/input_payload = tgui_input_say_emote(usr, "Subtle", "emote", TRUE, "Type your message:")
	dispatch_unified_say_emote_input(input_payload)
	// RS Edit End

// RS Add: TGUI emote interface (Lira, February 2026)
/mob/verb/subtle_custom_wrapper()
	set name = ".SubtleCustom"
	set hidden = 1

	if(client?.prefs?.tgui_input_mode)
		var/list/input_payload = tgui_input_say_emote(usr, "Subtle (Custom)", "emote", TRUE, "Type your message:", "custom_subtle")
		dispatch_unified_say_emote_input(input_payload)
		return

	var/message = input(usr, "Choose an emote to display.", "Subtle (Custom)") as message|null
	if(isnull(message))
		return
	me_verb_subtle_custom(message)
