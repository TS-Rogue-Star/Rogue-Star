//RS Add Start: TGUI emote interface (Lira, February 2026)
/mob/proc/autowhisper_forced_psay_externally_controlled()
	if(istype(src, /mob/living/dominated_brain))
		return TRUE
	if(isbelly(loc) && absorbed)
		var/obj/belly/b = loc
		if(b.mode_flags & DM_FLAG_FORCEPSAY)
			return TRUE
	return FALSE

/mob/proc/update_forced_psay_from_autowhisper_mode()
	if(autowhisper_forced_psay_externally_controlled())
		return
	forced_psay = (autowhisper && autowhisper_mode == "Psay/Pme")
//RS Add End

/mob/living/verb/toggle_autowhisper()
	set name = "Autowhisper Toggle"
	set desc = "Toggle whether you will automatically whisper/subtle"
	set category = "IC"

	autowhisper = !autowhisper
	if(autowhisper_display)
		autowhisper_display.icon_state = "[autowhisper ? "autowhisper1" : "autowhisper"]"

	if(autowhisper_mode == "Psay/Pme")
		if(isbelly(loc) && absorbed)
			var/obj/belly/b = loc
			if(b.mode_flags & DM_FLAG_FORCEPSAY)
				var/mes = "but you are affected by forced psay right now, so you will automatically use psay/pme instead of any other option."
				to_chat(src, "<span class='notice'>Autowhisper has been [autowhisper ? "enabled, [mes]" : "disabled, [mes]"].</span>")
				return
		else
			update_forced_psay_from_autowhisper_mode() //RS Edit: TGUI emote interface (Lira, February 2026)
			to_chat(src, "<span class='notice'>Autowhisper has been [autowhisper ? "enabled. You will now automatically psay/pme when using say/me. As a note, this option will only work if you are in a situation where you can send psay/pme messages! Otherwise it will work as default whisper/subtle" : "disabled"].</span>")

	else
		update_forced_psay_from_autowhisper_mode() //RS Edit: TGUI emote interface (Lira, February 2026)
		to_chat(src, "<span class='notice'>Autowhisper has been [autowhisper ? "enabled. You will now automatically whisper/subtle when using say/me" : "disabled"].</span>")

/mob/living/verb/autowhisper_mode()
	set name = "Autowhisper Mode"
	set desc = "Set the mode your emotes will default to while using Autowhisper"
	set category = "IC"


	var/choice = tgui_input_list(src, "Select Custom Subtle Mode", "Custom Subtle Mode", get_subtle_mode_options(TRUE)) //RS Edit: TGUI emote interface (Lira, February 2026)
	if(!choice || choice == "Adjacent Turfs (Default)")
		autowhisper_mode = null
		update_forced_psay_from_autowhisper_mode() //RS Edit: TGUI emote interface (Lira, February 2026)
		to_chat(src, "<span class='notice'>Your subtles have returned to the default setting.</span>")
		return
	if(choice == "Psay/Pme")
		if(autowhisper)
			if(isbelly(loc) && absorbed)
				var/obj/belly/b = loc
				if(b.mode_flags & DM_FLAG_FORCEPSAY)
					to_chat(src, "<span class='warning'>You can't set that mode right now, as you appear to be absorbed in a belly using forced psay!</span>")
					return
			to_chat(src, "<span class='notice'>As a note, this option will only work if you are in a situation where you can send psay/pme messages! Otherwise it will work as default whisper/subtle.</span>")
	autowhisper_mode = choice
	update_forced_psay_from_autowhisper_mode() //RS Edit: TGUI emote interface (Lira, February 2026)
	to_chat(src, "<span class='notice'>Your subtles have been set to <b>[autowhisper_mode]</b>.</span>")
