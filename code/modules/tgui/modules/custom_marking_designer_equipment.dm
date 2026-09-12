///////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Equipment //
///////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/custom_marking_designer
	var/equipment_revision = 1
	var/equipment_save_in_progress = FALSE
	var/equipment_catalog_signature
	var/list/equipment_catalog
	var/equipment_gear_options_signature
	var/list/equipment_gear_options

/datum/tgui_module/custom_marking_designer/proc/get_equipment_color(category)
	var/list/metadata = prefs?.all_underwear_metadata?[category]
	var/color = metadata?["[gear_tweak_free_color_choice]"]
	color = sanitize_hexcolor(color, gear_tweak_free_color_choice.get_default())
	if(length(color) == 4)
		return "#[copytext(color, 2, 3)][copytext(color, 2, 3)][copytext(color, 3, 4)][copytext(color, 3, 4)][copytext(color, 4, 5)][copytext(color, 4, 5)]"
	return color

/datum/tgui_module/custom_marking_designer/proc/build_equipment_values()
	var/list/underwear = list()
	var/list/colors = list()
	for(var/datum/category_group/underwear/category in global_underwear.categories)
		underwear[category.name] = prefs.all_underwear?[category.name] || "None"
		colors[category.name] = get_equipment_color(category.name)
	return list(
		"revision" = equipment_revision,
		"underwear" = underwear,
		"colors" = colors,
		"backbag" = prefs.backbag,
		"pdachoice" = prefs.pdachoice,
		"communicator_visibility" = !!prefs.communicator_visibility,
		"shoe_hater" = !!prefs.shoe_hater
	)

/datum/tgui_module/custom_marking_designer/proc/get_equipment_catalog_signature()
	return md5(json_encode(list(prefs.species, prefs.custom_base, prefs.biological_gender, prefs.digitigrade, prefs.tail_style, get_static_limb_override_signature())))

/datum/tgui_module/custom_marking_designer/proc/get_equipment_context_signature()
	if(!prefs)
		return null
	return md5("[get_equipment_catalog_signature()]|[get_static_gear_preview_signature()]")

/datum/tgui_module/custom_marking_designer/proc/build_equipment_catalog()
	var/signature = get_equipment_catalog_signature()
	if(equipment_catalog_signature == signature && islist(equipment_catalog))
		return equipment_catalog
	var/list/catalog = list()
	var/list/bags = list()
	var/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin = get_static_gear_recipe_mannequin()
	var/static/list/gear_layers = list(6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27)
	reset_mannequin_equipment(mannequin, gear_layers)
	copy_preferences_to_mannequin_without_marking(mannequin)
	var/list/tail_override = apply_preview_tail_override(mannequin)
	try
		for(var/datum/category_group/underwear/category in global_underwear.categories)
			var/list/entries = list()
			for(var/datum/category_item/underwear/item in category.items)
				var/list/recipes = list()
				for(var/dir in direction_order)
					var/list/overlays = list()
					if(item.icon_state && (mannequin.species.appearance_flags & HAS_UNDERWEAR))
						var/asset = resolve_static_gear_appearance_asset(item.icon, item.icon_state, dir)
						if(asset)
							overlays += list(list("asset" = asset, "layer" = 6, "slot" = "underwear"))
					recipes["[dir]"] = overlays
				entries += list(list("id" = item.name, "name" = item.name, "colorable" = !!item.has_color, "recipes" = recipes))
			catalog[category.name] = entries
		for(var/index = 1 to backbaglist.len)
			reset_mannequin_equipment(mannequin, gear_layers)
			var/bag_path = prefs.get_generic_preview_backbag_path(index)
			if(ispath(bag_path, /obj/item))
				mannequin.equip_to_slot_or_del(new bag_path(mannequin), slot_back)
			var/list/recipes = list()
			for(var/dir in direction_order)
				recipes["[dir]"] = build_static_gear_overlay_assets_for_layers(mannequin, dir, list(20)) || list()
			bags += list(list("id" = "[index]", "name" = backbaglist[index], "recipes" = recipes))
	catch(var/exception/error)
		reset_mannequin_equipment(mannequin, gear_layers)
		if(tail_override)
			restore_preview_tail_override(tail_override)
		throw error
	reset_mannequin_equipment(mannequin, gear_layers)
	if(tail_override)
		restore_preview_tail_override(tail_override)
	catalog["backpack"] = bags
	var/list/pdas = list()
	for(var/index = 1 to pdachoicelist.len)
		var/asset = resolve_static_gear_appearance_asset(get_pda_choice_icon(index), "pda", SOUTH)
		pdas += list(list("id" = "[index]", "name" = pdachoicelist[index], "icon" = asset, "singlePreview" = TRUE))
	catalog["pda"] = pdas
	equipment_catalog_signature = signature
	equipment_catalog = catalog
	return catalog

/datum/tgui_module/custom_marking_designer/proc/validate_equipment_payload(list/params, list/errors)
	var/list/values
	try
		values = json_decode(params?["equipment"])
	catch
		errors += "Equipment data could not be read. Reload the tab and try again."
		return null
	if(!islist(values) || values["revision"] != equipment_revision)
		errors += "This Equipment draft is out of date. Reload it and try again."
		return null
	var/list/underwear = values["underwear"]
	var/list/colors = values["colors"]
	if(!islist(underwear) || !islist(colors) || underwear.len != global_underwear.categories.len || colors.len != global_underwear.categories.len)
		errors += "Equipment must include every underwear category."
		return null
	for(var/datum/category_group/underwear/category in global_underwear.categories)
		var/name = underwear[category.name]
		var/color = colors[category.name]
		if(!istext(name) || !category.items_by_name[name])
			errors += "Choose a valid [category.display_name]."
			return null
		if(!istext(color) || length(color) != 7 || lowertext(color) != sanitize_hexcolor(color, null))
			errors += "Choose a valid color for [category.display_name]."
			return null
		colors[category.name] = sanitize_hexcolor(color, null)
	for(var/field in list("backbag", "pdachoice"))
		var/value = values[field]
		var/maximum = field == "backbag" ? backbaglist.len : pdachoicelist.len
		if(!isnum(value) || value != round(value) || value < 1 || value > maximum)
			errors += "Choose a valid [field == "backbag" ? "backpack" : "PDA"] style."
			return null
	for(var/field in list("communicator_visibility", "shoe_hater"))
		if(!(field in values) || !isnum(values[field]) || !(values[field] in list(TRUE, FALSE)))
			errors += "Equipment visibility and shoe settings must be Yes or No."
			return null
	return values

/datum/tgui_module/custom_marking_designer/proc/apply_equipment_values(list/values)
	var/list/underwear = islist(prefs.all_underwear) ? prefs.all_underwear.Copy() : list()
	var/list/metadata = islist(prefs.all_underwear_metadata) ? prefs.all_underwear_metadata.Copy() : list()
	var/list/selections = values["underwear"]
	var/list/colors = values["colors"]
	for(var/datum/category_group/underwear/category in global_underwear.categories)
		var/color_changed = lowertext(colors[category.name]) != lowertext(get_equipment_color(category.name))
		if(selections[category.name] != (underwear[category.name] || "None") || (color_changed && !(category.name in underwear)))
			underwear[category.name] = selections[category.name]
		if(color_changed)
			var/list/old_metadata = metadata[category.name]
			var/list/new_metadata = islist(old_metadata) ? old_metadata.Copy() : list()
			new_metadata["[gear_tweak_free_color_choice]"] = colors[category.name]
			metadata[category.name] = new_metadata
	prefs.all_underwear = underwear
	prefs.all_underwear_metadata = metadata
	prefs.backbag = values["backbag"]
	prefs.pdachoice = values["pdachoice"]
	prefs.communicator_visibility = values["communicator_visibility"]
	prefs.shoe_hater = values["shoe_hater"]

/datum/tgui_module/custom_marking_designer/proc/build_equipment_gear_options()
	if(!prefs || !custom_marking_gear_preview_cache_complete)
		return null
	var/signature = get_static_gear_preview_signature()
	if(equipment_gear_options_signature == signature && islist(equipment_gear_options))
		return equipment_gear_options
	var/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin = get_static_gear_recipe_mannequin()
	var/static/list/gear_layers = list(6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27)
	var/original_shoes = prefs.shoe_hater
	var/list/tail_override
	var/list/options = list()
	var/exception/build_error
	try
		reset_mannequin_equipment(mannequin, gear_layers)
		copy_preferences_to_mannequin_without_marking(mannequin)
		tail_override = apply_preview_tail_override(mannequin)
		prefs.shoe_hater = FALSE
		for(var/mode in list(EQUIP_PREVIEW_JOB, EQUIP_PREVIEW_LOADOUT))
			var/is_job = mode == EQUIP_PREVIEW_JOB
			var/choice_count = is_job ? backbaglist.len : pdachoicelist.len
			var/list/choices = list()
			for(var/index = 1 to choice_count)
				reset_mannequin_equipment(mannequin, gear_layers)
				mannequin.backbag = is_job ? index : prefs.backbag
				mannequin.pdachoice = is_job ? prefs.pdachoice : index
				prefs.equip_prepared_preview_mob(mannequin, mode)
				var/list/directions = list()
				for(var/dir in direction_order)
					directions["[dir]"] = build_static_gear_overlay_assets_for_layers(mannequin, dir, gear_layers) || list()
				choices["[index]"] = directions
			options[is_job ? "job_by_backbag" : "loadout_by_pda"] = choices
	catch(var/exception/error)
		build_error = error
	prefs.shoe_hater = original_shoes
	reset_mannequin_equipment(mannequin, gear_layers)
	mannequin.backbag = prefs.backbag
	mannequin.pdachoice = prefs.pdachoice
	if(tail_override)
		restore_preview_tail_override(tail_override)
	if(build_error)
		throw build_error
	equipment_gear_options_signature = signature
	equipment_gear_options = options
	return options

/datum/tgui_module/custom_marking_designer/proc/send_equipment_update(mob/user, list/update)
	var/datum/tgui/ui = SStgui.get_open_ui(user, src)
	if(ui)
		update["equipment_context_signature"] = get_equipment_context_signature()
		update["loadout_context_signature"] = get_loadout_context_signature()
		ui.send_update(update)

/datum/tgui_module/custom_marking_designer/proc/handle_equipment_action(action, list/params, mob/user)
	if(!(action in list("load_equipment", "save_equipment", "close_equipment")))
		return FALSE
	if(action == "close_equipment")
		if(!equipment_save_in_progress)
			SStgui.close_uis(src)
		return TRUE
	if(!prefs || !user)
		return TRUE
	if(action == "load_equipment")
		// Separate Equipment preloading from the essential Designer previews by one server tick.
		sleep(world.tick_lag > 0 ? world.tick_lag : 1)
		if(QDELETED(src) || !prefs || !user || !SStgui.get_open_ui(user, src))
			return TRUE
	var/request_id = params?["request_id"]
	var/list/update = list()
	var/list/errors = list()
	var/saving = action == "save_equipment"
	var/accepted = FALSE
	var/list/saved_values
	var/list/saved_gear
	if(saving && equipment_save_in_progress)
		send_equipment_update(user, list("equipment_save_result" = list("request_id" = request_id, "accepted" = FALSE, "error" = "An Equipment save is already in progress.")))
		return TRUE
	if(saving)
		equipment_save_in_progress = TRUE
	acquire_preview_payload_build_lock()
	try
		if(action == "load_equipment")
			var/list/payload = list(
				"request_id" = request_id,
				"values" = build_equipment_values(),
				"catalog_signature" = get_equipment_catalog_signature(),
				"gear_options" = build_equipment_gear_options()
			)
			if(params?["known_catalog"] != payload["catalog_signature"])
				payload["catalog"] = build_equipment_catalog()
			update["equipment_payload"] = payload
		else
			var/list/values = validate_equipment_payload(params, errors)
			if(islist(values))
				apply_equipment_values(values)
				equipment_revision++
				saved_values = build_equipment_values()
				accepted = TRUE
				saved_gear = build_equipment_gear_options()
	catch(var/exception/error)
		log_error("Character Designer Equipment [action] failed: [error.name]")
		errors += "Equipment could not be processed. Please try again."
	release_preview_payload_build_lock()
	if(saving)
		equipment_save_in_progress = FALSE
		var/list/save_result = list("request_id" = request_id, "accepted" = accepted, "revision" = equipment_revision)
		if(accepted)
			save_result["values"] = saved_values
			save_result["gear_options"] = saved_gear
		else
			save_result["error"] = errors.len ? jointext(errors, " ") : "Equipment could not be saved."
		update["equipment_revision"] = equipment_revision
		update["equipment_save_result"] = save_result
	else if(errors.len)
		update["equipment_payload"] = list("request_id" = request_id, "error" = jointext(errors, " "))
	send_equipment_update(user, update)
	if(saving && accepted)
		try
			refresh_preferences_window_if_visible(TRUE)
		catch(var/exception/refresh_error)
			log_error("Character Designer Equipment saved, but preferences refresh failed: [refresh_error.name]")
	return TRUE
