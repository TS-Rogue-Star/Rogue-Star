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
		return TRUE
	if(startswith(lowered, "me "))
		return TRUE

	return FALSE

/mob/proc/startswith(var/text, var/prefix)
	if(length(text) < length(prefix))
		return FALSE
	return copytext(text, 1, length(prefix) + 1) == prefix

#undef TYPING_INDICATOR_POLL
#undef TYPING_INDICATOR_INPUT_CONTROL

// RS Add End

/mob/verb/say_wrapper()
	set name = ".Say"
	set hidden = 1

	set_typing_indicator(TRUE)
	var/message = tgui_input_text(usr, "Type your message:", "Say")
	set_typing_indicator(FALSE)

	if(message)
		say_verb(message)

/mob/verb/me_wrapper()
	set name = ".Me"
	set hidden = 1

	set_typing_indicator(TRUE)
	var/message = tgui_input_text(usr, "Type your message:", "Emote", multiline = TRUE, use_message_window_scale = TRUE) // RS Edit: TGUI window scaling (Lira, January 2026)
	set_typing_indicator(FALSE)

	if(message)
		me_verb(message)

// RS Add Start: New client me and say verbs that call the hotkey wrappers (Lira, October 2025)
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
// RS Add End

// No typing indicators here, but this is the file where the wrappers are, so...
/mob/verb/whisper_wrapper()
	set name = ".Whisper"
	set hidden = 1

	var/message = tgui_input_text(usr, "Type your message:", "Whisper")

	if(message)
		whisper(message)

/mob/verb/subtle_wrapper()
	set name = ".Subtle"
	set hidden = 1

	var/message = tgui_input_text(usr, "Type your message:", "Subtle", multiline = TRUE, use_message_window_scale = TRUE) // RS Edit: TGUI window scaling (Lira, January 2026)

	if(message)
		me_verb_subtle(message)
