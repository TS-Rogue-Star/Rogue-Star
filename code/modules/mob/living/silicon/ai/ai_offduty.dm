/////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: New system for allowing the AI to go off duty //
/////////////////////////////////////////////////////////////////////////////////////////////////

/mob/living/silicon/pai/ai_offduty
	name = "AI"
	icon = 'icons/mob/pai_vr.dmi'
	icon_state = "pai-typezero"
	mob_size = MOB_SMALL
	anchored = FALSE
	density = FALSE
	canmove = TRUE
	holder_type = null
	var/current_emotion = 1

	var/datum/ai_laws/stored_laws = null
	var/datum/ai_icon/stored_icon = null
	var/mob/living/silicon/ai/stored_core = null
	var/stored_custom_sprite = FALSE
	var/stored_holo_color = null
	var/icon/stored_holo_icon = null
	var/list/stored_network = list()
	var/list/stored_languages = list()
	var/list/stored_radio_channels = list()
	var/stored_display_name = null
	var/stored_real_name = null
	var/stored_desc = null
	var/stored_ooc_notes = null
	var/stored_ooc_likes = null
	var/stored_ooc_dislikes = null
	var/dark_mode = FALSE


/mob/living/silicon/pai/ai_offduty/New(loc)
	if(istype(loc, /obj/item/device/paicard))
		..(loc)
	else
		..(null)
		if(loc)
			forceMove(loc)
	if(radio)
		qdel(radio)
	if(card)
		card.radio = null
	var/atom/radio_loc = card ? card : src
	radio = new /obj/item/device/radio/borg/pai(radio_loc)
	radio.subspace_transmission = TRUE
	common_radio = radio
	if(card)
		card.radio = radio
	ai_list |= src
	verbs -= /mob/living/silicon/pai/verb/save_pai_to_slot
	verbs += /mob/living/silicon/pai/ai_offduty/proc/return_to_duty
	chassis = "pai-typezero"
	update_icon()
	job = "AI (Off Duty)"

/mob/living/silicon/pai/ai_offduty/Destroy()
	if(card)
		var/obj/item/device/paicard/ai_offduty/offduty_card = card
		if(loc == offduty_card)
			var/turf/T = get_turf(offduty_card)
			if(T)
				forceMove(T)
			else
				forceMove(null)
		card = null
		var/atom/card_holder = offduty_card.loc
		if(istype(card_holder, /obj/machinery))
			var/obj/machinery/M = card_holder
			if(M.paicard == offduty_card)
				M.paicard = null
		offduty_card.removePersonality()
		QDEL_NULL(offduty_card)
	ai_list -= src
	return ..()

/mob/living/silicon/pai/ai_offduty/proc/setup_from_ai(mob/living/silicon/ai/core)
	if(!core)
		return

	stored_core = core
	stored_laws = core.laws
	laws = stored_laws

	stored_icon = core.selected_sprite
	stored_custom_sprite = core.custom_sprite
	stored_holo_color = core.holo_color
	if(core.holo_icon)
		stored_holo_icon = icon(core.holo_icon)

	stored_network = list()
	if(core.network)
		stored_network = core.network.Copy()

	stored_display_name = core.name
	stored_real_name = core.real_name
	stored_desc = core.flavor_text
	stored_ooc_notes = core.ooc_notes
	stored_ooc_likes = core.ooc_notes_likes
	stored_ooc_dislikes = core.ooc_notes_dislikes
	SetName(stored_display_name)
	pai_law0 = "None"
	master = null
	master_dna = null

	stored_radio_channels = list()
	if(core.aiRadio)
		stored_radio_channels = core.aiRadio.channels.Copy()
	if(radio && stored_radio_channels.len)
		radio.channels = stored_radio_channels.Copy()

	stored_languages = list()
	for(var/datum/language/L as anything in core.languages)
		if(L && !(L.name in stored_languages))
			stored_languages += L.name
	for(var/lang_name in stored_languages)
		add_language(lang_name, TRUE)

	if(card)
		card.setPersonality(src)
		card.setEmotion(current_emotion)

	flavor_text = stored_desc
	ooc_notes = stored_ooc_notes
	ooc_notes_likes = stored_ooc_likes
	ooc_notes_dislikes = stored_ooc_dislikes

	if(idcard)
		if(!istype(idcard.access, /list))
			idcard.access = list()
		idcard.access |= list(access_ai_upload, access_maint_tunnels)

	to_chat(src, span("notice", "You disengage from your core and operate off duty."))

/mob/living/silicon/pai/ai_offduty/close_up(silent = FALSE)
	return ..(silent)

/mob/living/silicon/pai/ai_offduty/tgui_data(mob/user)
	var/list/data = list()

	var/list/bought_software = list()
	var/list/not_bought_software = list()

	for(var/key in pai_software_by_key)
		var/datum/pai_software/S = pai_software_by_key[key]
		var/software_data[0]
		software_data["name"] = S.name
		software_data["id"] = S.id
		if(key in software)
			software_data["on"] = S.is_active(src)
			bought_software.Add(list(software_data))
		else
			software_data["ram"] = S.ram_cost
			not_bought_software.Add(list(software_data))

	data["bought"] = bought_software
	data["not_bought"] = not_bought_software
	data["available_ram"] = ram

	var/list/emotions = list()
	for(var/name in pai_emotions)
		var/list/emote = list()
		emote["name"] = name
		emote["id"] = pai_emotions[name]
		emotions.Add(list(emote))

	data["emotions"] = emotions
	data["current_emotion"] = current_emotion
	data["dark_mode"] = dark_mode

	return data

/mob/living/silicon/pai/ai_offduty/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(action == "toggle_dark_mode")
		dark_mode = !dark_mode
		set_offduty_emotion(current_emotion)
		return TRUE
	if(action == "image")
		var/img = text2num(params["image"])
		if(1 <= img && img <= pai_emotions.len)
			set_offduty_emotion(img)
		return TRUE

	return ..(action, params, ui, state)

/mob/living/silicon/pai/ai_offduty/proc/set_offduty_emotion(var/emotion)
	if(!isnum(emotion) || emotion < 1 || emotion > pai_emotions.len)
		return
	current_emotion = emotion
	if(card)
		card.setEmotion(current_emotion)

/mob/living/silicon/pai/ai_offduty/examine(mob/user)
	var/out = ..(user)
	if(islist(out) && length(out))
		out[1] = replacetext(out[1], ", personal AI", ", an off-duty AI")
	return out

/mob/living/silicon/pai/ai_offduty/savefile_save(mob/user)
	return 0

/mob/living/silicon/pai/ai_offduty/savefile_load(mob/user, var/silent = 1)
	return 0

/mob/living/silicon/pai/ai_offduty/proc/return_to_duty()
	set category = "AI Commands"
	set name = "Return to Duty"
	set desc = "Recreate your AI core and resume full functionality."

	if(!stored_laws)
		to_chat(src, span("warning", "Missing core data; unable to restore AI systems."))
		return

	var/mob/living/silicon/ai/core = stored_core
	if(core && QDELETED(core))
		core = null
	if(!core)
		to_chat(src, span("warning", "Your AI core is missing; unable to return to duty."))
		return
	if(core.stat == DEAD)
		to_chat(src, span("warning", "Your AI core is destroyed; unable to return to duty."))
		return

	var/turf/core_turf = get_turf(core)
	if(!core_turf)
		to_chat(src, span("warning", "Unable to locate your AI core."))
		return

	if(get_dist(src, core) > 1)
		to_chat(src, span("warning", "You must be adjacent to your AI core to resume duty."))
		return

	var/has_clear_space = FALSE
	for(var/direction in GLOB.alldirs)
		var/turf/candidate = get_step(loc, direction)
		if(!istype(candidate, /turf))
			continue
		if(is_blocked_turf(candidate, TRUE))
			continue
		has_clear_space = TRUE
		break

	if(!has_clear_space)
		to_chat(src, span("warning", "There's no clear space here to reinitialize your core."))
		return

	var/mob/living/silicon/ai/current_occupant = null
	for(var/mob/living/silicon/ai/occupant in core_turf)
		if(occupant == core)
			continue
		if(QDELETED(occupant))
			continue
		if(occupant.stat == DEAD)
			continue
		if(!occupant.mind)
			continue
		current_occupant = occupant
		break

	if(current_occupant)
		to_chat(src, span("warning", "[current_occupant] is already occupying your core; you remain in off-duty mode."))
		return

	stored_laws = laws
	stored_display_name = name
	stored_real_name = real_name

	stored_languages = list()
	for(var/datum/language/L as anything in languages)
		if(L && !(L.name in stored_languages))
			stored_languages += L.name

	stored_radio_channels = list()
	if(radio && radio.channels)
		stored_radio_channels = radio.channels.Copy()

	if(stored_icon)
		core.selected_sprite = stored_icon

	if(stored_laws)
		core.laws = stored_laws

	core.custom_sprite = stored_custom_sprite
	core.holo_color = stored_holo_color
	if(stored_holo_icon)
		core.holo_icon = icon(stored_holo_icon)
	else
		core.holo_icon = null

	if(stored_network && stored_network.len)
		core.network = stored_network.Copy()

	if(stored_display_name)
		core.SetName(stored_display_name)
	if(stored_real_name)
		core.real_name = stored_real_name

	if(stored_radio_channels.len && core.aiRadio)
		core.aiRadio.channels = stored_radio_channels.Copy()

	if(!core.psupply)
		core.create_powersupply()
	core.aiRestorePowerRoutine = 0
	core.stat = CONSCIOUS
	core.anchored = TRUE
	core.density = TRUE
	core.canmove = FALSE
	for(var/lang_name in stored_languages)
		core.add_language(lang_name, TRUE)

	to_chat(src, span("notice", "Reinitializing AI core."))
	visible_message(span("notice", "[src] reintegrates with their dormant AI core."), span("notice", "You reintegrate with your AI core."))

	if(mind)
		mind.transfer_to(core)

	core.update_icon()
	core.sync_unassigned_shells()
	core.announce_duty_status(TRUE)

	stored_core = core

	qdel(src)
