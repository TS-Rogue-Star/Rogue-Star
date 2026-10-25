///////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Character Designer - JSON Export //
///////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/custom_marking_designer
	var/character_export_in_progress = FALSE

/datum/tgui_module/custom_marking_designer/proc/build_character_export_traits()
	var/list/selected = list()
	var/list/preferences = list()
	for(var/category in list("positive", "neutral", "negative"))
		var/list/traits = resolve_selected_traits(category)
		for(var/trait in traits)
			selected += "[trait]"
			preferences["[trait]"] = traits[trait] || list()
	var/list/custom_keys = list()
	for(var/key in prefs.language_custom_keys)
		custom_keys[prefs.language_custom_keys[key]] = key
	return list(
		"selected_traits" = selected,
		"trait_preferences" = preferences,
		"languages" = list(
			"alternate_languages" = prefs.alternate_languages,
			"preferred_language" = prefs.preferred_language,
			"custom_keys" = custom_keys,
			"language_prefixes" = prefs.language_prefixes
		)
	)

/datum/tgui_module/custom_marking_designer/proc/build_character_export_marking()
	if(!mark)
		return null
	var/list/frames = list()
	for(var/key in mark.frames)
		var/datum/custom_marking_frame/frame = mark.frames[key]
		if(istype(frame))
			frames[key] = frame.get_composite()
	return list(
		"id" = mark.id,
		"name" = mark.name,
		"body_parts" = mark.body_parts,
		"width" = get_canvas_width(),
		"height" = get_canvas_height(),
		"part_replacements" = mark.get_part_replacement_payload(),
		"part_render_priority" = mark.get_part_render_priority_payload(),
		"part_canvas_size" = mark.get_part_canvas_size_payload(),
		"frames" = frames
	)

/datum/tgui_module/custom_marking_designer/proc/build_character_export_payload(mob/user)
	var/list/appearance = build_species_save_basic_appearance_payload()
	appearance -= "definition_data"
	var/list/identity = build_identity_payload(user)
	identity -= list("location_options", "citizenship_catalog_options", "faction_catalog_options", "religion_catalog_options")
	if(!appearance["prosthetic_context"])
		appearance["prosthetic_context"] = build_basic_prosthetic_context()
	return list(
		"slot" = prefs.default_slot,
		"species" = list(
			"species" = prefs.species,
			"icon_base" = prefs.custom_base,
			"custom_species" = identity_text_for_payload(prefs.custom_species)
		),
		"identity" = identity,
		"appearance" = appearance,
		"body_markings" = build_species_save_body_marking_state(),
		"traits" = build_character_export_traits(),
		"equipment" = build_equipment_values(),
		"loadout" = build_loadout_values(),
		"occupation" = build_occupation_values(),
		"custom_markings" = build_character_export_marking()
	)

/datum/tgui_module/custom_marking_designer/proc/send_character_export(mob/user, request_id)
	if(!prefs || !user?.client || user.client.prefs != prefs || !istext(request_id) || length(request_id) > 128)
		return FALSE
	var/datum/tgui/ui = SStgui.get_open_ui(user, src)
	if(!ui)
		return FALSE
	var/list/result = list("request_id" = request_id, "state_token" = state_session_token)
	if(character_export_in_progress || save_in_progress || identity_save_in_progress || equipment_save_in_progress || loadout_save_in_progress || occupation_save_in_progress)
		result["error"] = "Please wait for the current request to finish, then export again."
	else
		character_export_in_progress = TRUE
		acquire_preview_payload_build_lock()
		try
			result["baseline"] = build_character_export_payload(user)
		catch(var/exception/error)
			result["error"] = "The character could not be exported. Please try again."
			log_error("Character Designer JSON export failed: [error.name]")
		release_preview_payload_build_lock()
		character_export_in_progress = FALSE
	ui.send_update(list("character_export_result" = result))
	return TRUE
