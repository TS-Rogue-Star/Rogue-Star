/////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
/////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/custom_marking_designer
	var/loadout_save_in_progress = FALSE
	var/loadout_load_in_progress = FALSE
	var/loadout_catalog_signature
	var/list/loadout_catalog
	var/list/loadout_variant_cache = list()
	var/loadout_preview_generation = 0

/datum/tgui_module/custom_marking_designer/proc/get_loadout_recipe_signature()
	return get_equipment_catalog_signature()

/datum/tgui_module/custom_marking_designer/proc/get_loadout_variant_cache_key(datum/gear/G, variant, item_path)
	return "[get_loadout_recipe_signature()]|[G.type]|[G.slot]|[variant]|[item_path]"

/datum/tgui_module/custom_marking_designer/proc/cache_loadout_variant(key, list/recipe)
	loadout_variant_cache -= key
	loadout_variant_cache[key] = recipe
	while(loadout_variant_cache.len > 4096)
		loadout_variant_cache.Cut(1, 2)

/proc/loadout_choice_options(list/choices, indexed = FALSE)
	var/list/result = list()
	for(var/i = 1 to choices.len)
		var/choice = choices[i]
		var/label = "[choice]"
		if(indexed)
			var/obj/item/item_type = choice
			label = item_type ? initial(item_type.name) : "None"
		result += list(list("value" = indexed ? i : choice, "label" = label))
	return result

/proc/build_loadout_tweak_spec(datum/gear_tweak/tweak, mob/user)
	var/list/spec = list("id" = "[tweak]", "default" = tweak.get_default())
	if(istype(tweak, /datum/gear_tweak/path))
		var/datum/gear_tweak/path/T = tweak
		spec["kind"] = "path"
		spec["label"] = "Type"
		spec["options"] = loadout_choice_options(T.valid_paths)
	else if(istype(tweak, /datum/gear_tweak/color))
		var/datum/gear_tweak/color/T = tweak
		spec["kind"] = "color"
		spec["label"] = "Color"
		if(T.valid_colors)
			spec["options"] = loadout_choice_options(T.valid_colors)
	else if(istype(tweak, /datum/gear_tweak/matrix_recolor))
		spec["kind"] = "matrix"
		spec["label"] = "Matrix Recolor"
	else if(istype(tweak, /datum/gear_tweak/custom_name))
		var/datum/gear_tweak/custom_name/T = tweak
		spec["kind"] = T.valid_custom_names ? "choice" : "text"
		spec["label"] = "Name"
		spec["placeholder_key"] = "default_name"
		spec["max_length"] = MAX_LNAME_LEN
		spec["disabled"] = user && jobban_isbanned(user, "Custom loadout")
		if(T.valid_custom_names)
			spec["options"] = loadout_choice_options(T.valid_custom_names)
	else if(istype(tweak, /datum/gear_tweak/custom_desc))
		var/datum/gear_tweak/custom_desc/T = tweak
		spec["kind"] = T.valid_custom_desc ? "choice" : "text"
		spec["label"] = "Description"
		spec["placeholder_key"] = "default_description"
		spec["max_length"] = MAX_MESSAGE_LEN
		spec["multiline"] = TRUE
		spec["disabled"] = user && jobban_isbanned(user, "Custom loadout")
		if(T.valid_custom_desc)
			spec["options"] = loadout_choice_options(T.valid_custom_desc)
	else if(istype(tweak, /datum/gear_tweak/collar_tag))
		spec["kind"] = "text"
		spec["label"] = "Collar Tag"
		spec["max_length"] = MAX_NAME_LEN
	else if(istype(tweak, /datum/gear_tweak/contents))
		var/datum/gear_tweak/contents/T = tweak
		var/list/fields = list()
		for(var/i = 1 to T.valid_contents.len)
			fields += list(list("label" = "Contents [i]", "options" = loadout_choice_options(T.valid_contents[i] + list("Random", "None"))))
		spec["kind"] = "choices"
		spec["label"] = "Contents"
		spec["fields"] = fields
	else if(istype(tweak, /datum/gear_tweak/reagents))
		var/datum/gear_tweak/reagents/T = tweak
		spec["kind"] = "choice"
		spec["label"] = "Reagents"
		spec["options"] = loadout_choice_options(T.valid_reagents + list("Random", "Random Alcoholic", "Random Non-Alcoholic", "None"))
	else if(istype(tweak, /datum/gear_tweak/implant_location))
		spec["kind"] = "choice"
		spec["label"] = "Implant Location"
		spec["options"] = loadout_choice_options(tweak:bodypart_names_to_tokens)
	else if(istype(tweak, /datum/gear_tweak/tablet) || istype(tweak, /datum/gear_tweak/laptop))
		var/list/fields = list()
		var/list/hardware_fields = list("Processor" = "ValidProcessors", "Battery" = "ValidBatteries", "Hard Drive" = "ValidHardDrives", "Network Card" = "ValidNetworkCards", "Nanoprinter" = "ValidNanoPrinters", "Card Slot" = "ValidCardSlots", "Tesla Link" = "ValidTeslaLinks")
		for(var/label in hardware_fields)
			fields += list(list("label" = label, "options" = loadout_choice_options(tweak.vars[hardware_fields[label]], TRUE)))
		spec["kind"] = "choices"
		spec["label"] = "Computer Components"
		spec["fields"] = fields
	else
		return null
	return spec

/proc/loadout_option_valid(value, list/options)
	for(var/list/option in options)
		if(value == option["value"])
			return TRUE
	return FALSE

/proc/validate_loadout_tweak_value(datum/gear_tweak/tweak, value, mob/user, list/errors)
	var/list/spec = build_loadout_tweak_spec(tweak, user)
	if(!spec || spec["disabled"])
		errors += "This item customization is not available."
		return null
	var/kind = spec["kind"]
	if(kind == "matrix")
		if(isnull(value) || (islist(value) && !length(value)))
			return list()
		if(!islist(value) || !(length(value) in list(9, 12, 16, 20)))
			errors += "Invalid color matrix."
			return null
		for(var/component in value)
			if(!isnum(component) || !ISINRANGE(component, -10, 10))
				errors += "Invalid color matrix component."
				return null
		var/datum/ColorMate/checker = new(user)
		var/valid = checker.check_valid_color(value, user)
		qdel(checker)
		if(!valid)
			errors += "The color matrix is too dark."
			return null
		var/list/copied_value = value
		return copied_value.Copy()
	if(kind == "choices")
		var/list/fields = spec["fields"]
		if(!islist(value) || length(value) != fields.len)
			errors += "Choose every item component."
			return null
		for(var/i = 1 to fields.len)
			var/list/field = fields[i]
			if(!loadout_option_valid(value[i], field["options"]))
				errors += "Invalid item component."
				return null
		var/list/copied_value = value
		return copied_value.Copy()
	if(spec["options"])
		if(!loadout_option_valid(value, spec["options"]))
			errors += "Invalid [spec["label"]] choice."
			return null
		return value
	if(!istext(value))
		errors += "Invalid [spec["label"]] value."
		return null
	if(kind == "color")
		var/color = sanitize_hexcolor(value, null)
		if(!color || lowertext(value) != lowertext(color))
			errors += "Invalid item color."
			return null
		return color
	var/limit = spec["max_length"] || MAX_MESSAGE_LEN
	if(length(value) > limit)
		errors += "[spec["label"]] is too long."
		return null
	return sanitize(value, limit, extra = istype(tweak, /datum/gear_tweak/collar_tag) ? 1 : 0) || ""

/datum/tgui_module/custom_marking_designer/proc/get_loadout_slots()
	var/list/slots = islist(prefs.gear_list) ? prefs.gear_list.Copy() : list()
	slots["[prefs.gear_slot]"] = islist(prefs.gear) ? prefs.gear : list()
	return slots

/datum/tgui_module/custom_marking_designer/proc/get_loadout_revision()
	return md5(json_encode(list(get_loadout_slots(), prefs.gear_slot, get_loadout_context_signature())))

/datum/tgui_module/custom_marking_designer/proc/get_loadout_context_signature()
	if(!prefs)
		return null
	return md5(json_encode(list(get_equipment_context_signature(), prefs.real_name, prefs.client_ckey, config.loadout_whitelist, config.loadout_slots)))

/datum/tgui_module/custom_marking_designer/proc/build_loadout_values()
	var/list/slots = get_loadout_slots()
	var/list/result = list()
	for(var/i = 1 to config.loadout_slots)
		var/list/items = list()
		var/list/saved = slots["[i]"]
		for(var/name in saved)
			var/datum/gear/G = gear_datums[name]
			var/list/tweaks = list()
			var/list/metadata = saved[name]
			if(G)
				for(var/datum/gear_tweak/T in G.gear_tweaks)
					tweaks["[T]"] = islist(metadata) && ("[T]" in metadata) ? metadata["[T]"] : T.get_default()
			items += list(list("id" = name, "tweaks" = tweaks))
		result["[i]"] = items
	return list("revision" = get_loadout_revision(), "active" = prefs.gear_slot, "slots" = result)

/datum/tgui_module/custom_marking_designer/proc/get_loadout_valid_choices()
	for(var/datum/category_group/player_setup_category/group in prefs.player_setup.categories)
		for(var/datum/category_item/player_setup_item/loadout/item in group.items)
			if(istype(item))
				return item.valid_gear_choices()
	return list()

/proc/get_loadout_base_source(obj/item/item_type)
	var/icon_source = initial(item_type.icon)
	var/icon_state = initial(item_type.icon_state)
	if(ispath(item_type, /obj/item/weapon/reagent_containers/food/drinks/glass2))
		var/obj/item/weapon/reagent_containers/food/drinks/glass2/glass_type = item_type
		icon_state = initial(glass_type.base_icon)
	else if(ispath(item_type, /obj/item/weapon/material/ashtray))
		icon_state = "ashtray"
	if(!(icon_state in cached_icon_states(icon_source)))
		var/list/fallback_sources = list(initial(item_type.icon_override), initial(item_type.default_worn_icon))
		var/slot_flags = initial(item_type.slot_flags)
		if(slot_flags & SLOT_EARS)
			fallback_sources |= INV_EARS_DEF_ICON
		if(slot_flags & SLOT_FEET)
			fallback_sources |= INV_FEET_DEF_ICON
		for(var/fallback_source in fallback_sources)
			if(fallback_source && (icon_state in cached_icon_states(fallback_source)))
				icon_source = fallback_source
				break
	return list(icon_source, icon_state)

/datum/tgui_module/custom_marking_designer/proc/prewarm_loadout_item_sources(list/sources, list/states)
	var/list/worn_paths = list()
	for(var/name in gear_datums)
		var/datum/gear/G = gear_datums[name]
		var/list/paths = list(G.path)
		for(var/datum/gear_tweak/path/T in G.gear_tweaks)
			for(var/variant in T.valid_paths)
				paths |= T.valid_paths[variant]
		for(var/obj/item/item_type as anything in paths)
			custom_marking_yield_heartbeat(FALSE)
			var/list/source = get_loadout_base_source(item_type)
			note_static_gear_source_state(sources, states, source[1], source[2])
			if(ispath(item_type, /obj/item/coinpouch))
				note_static_gear_source_state(sources, states, source[1], "[source[2]]-accent")
			if(G.slot && G.slot != "implant")
				worn_paths[item_type] = TRUE
	var/atom/movable/template_holder = new(null)
	for(var/item_type as anything in worn_paths)
		custom_marking_yield_heartbeat(FALSE)
		var/obj/item/item_template
		try
			item_template = new item_type(template_holder)
		catch(var/exception/error)
			item_template = locate(item_type) in template_holder
			if(!item_template)
				log_debug("Loadout atlas could not inspect worn sources for [item_type]: [error.name]")
		if(item_template)
			note_static_gear_item_sources(sources, states, item_type, item_template)
		for(var/obj/item/temporary_item in template_holder)
			qdel(temporary_item)
	qdel(template_holder)

/datum/tgui_module/custom_marking_designer/proc/build_loadout_variant(datum/gear/G, variant, item_path, mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin)
	try
		return build_loadout_variant_recipe(G, variant, item_path, mannequin)
	catch(var/exception/error)
		log_debug("Loadout gallery using base preview for [G.display_name] ([item_path]): [error.name]")
		reset_mannequin_equipment(mannequin, list(6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27))
		var/obj/item/item_type = item_path
		var/list/source = get_loadout_base_source(item_type)
		return list("id" = variant || "", "name" = variant || initial(item_type.name), "default_name" = initial(item_type.name), "default_description" = initial(item_type.desc), "icon" = resolve_static_gear_appearance_asset(source[1], source[2], SOUTH), "recipes" = list(), "equippable" = FALSE, "worn" = FALSE, "color" = initial(item_type.color))

/datum/tgui_module/custom_marking_designer/proc/build_loadout_variant_metadata(datum/gear/G, variant, item_path)
	var/cache_key = get_loadout_variant_cache_key(G, variant, item_path)
	var/list/cached = loadout_variant_cache[cache_key]
	if(islist(cached))
		cache_loadout_variant(cache_key, cached)
		return cached
	var/obj/item/item_type = item_path
	var/list/source = get_loadout_base_source(item_type)
	var/icon_asset = resolve_static_gear_appearance_asset(source[1], source[2], SOUTH)
	var/list/base_overlays
	if(ispath(item_type, /obj/item/coinpouch))
		var/obj/item/coinpouch/pouch_type = item_type
		var/accent = resolve_static_gear_appearance_asset(source[1], "[source[2]]-accent", SOUTH)
		if(accent)
			base_overlays = list(list("asset" = accent, "colors" = list(initial(pouch_type.accent_color)), "loadout_tint" = FALSE))
	return list("preview_pending" = !!G.slot && G.slot != "implant", "id" = variant || "", "name" = variant || initial(item_type.name), "default_name" = initial(item_type.name), "default_description" = initial(item_type.desc), "icon" = icon_asset, "recipes" = list(), "equippable" = FALSE, "worn" = FALSE, "color" = initial(item_type.color), "base_overlays" = base_overlays)

/datum/tgui_module/custom_marking_designer/proc/build_loadout_variant_recipe(datum/gear/G, variant, item_path, mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin)
	var/list/base = build_loadout_variant_metadata(G, variant, item_path)
	if(!base["preview_pending"])
		return base
	var/icon_asset = base["icon"]
	var/static/list/layers = list(6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27)
	reset_mannequin_equipment(mannequin, layers)
	var/obj/item/I = new item_path(mannequin)
	var/base_color = I.color
	var/static/list/tint_marker = list(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.123, 0.234, 0.345)
	I.color = tint_marker
	var/list/normalized_tint_marker = I.color
	var/list/before = list()
	if(G.slot == slot_tie || G.slot == slot_wear_id)
		mannequin.equip_to_slot_or_del(new /obj/item/clothing/under(mannequin), slot_w_uniform)
		for(var/dir in direction_order)
			before["[dir]"] = build_static_gear_overlay_assets_for_layers(mannequin, dir, layers)
	var/equipped = FALSE
	if(G.slot && G.slot != "implant")
		equipped = mannequin.equip_to_slot_if_possible(I, G.slot, del_on_fail = FALSE, disable_warning = TRUE)
	var/list/recipes = list()
	var/has_worn_preview = FALSE
	for(var/dir in direction_order)
		var/list/overlays = equipped ? build_static_gear_overlay_assets_for_layers(mannequin, dir, layers) : list()
		var/list/carriers = before["[dir]"]
		if(LAZYLEN(carriers))
			var/list/filtered = list()
			for(var/list/overlay in overlays)
				var/is_carrier = FALSE
				for(var/list/carrier in carriers)
					if(overlay["asset"] == carrier["asset"] && overlay["layer"] == carrier["layer"])
						is_carrier = TRUE
						var/list/additions = overlay["overlays"]
						for(var/list/addition in additions)
							var/list/component = addition.Copy()
							component["layer"] = overlay["layer"]
							component["slot"] = "accessory"
							filtered += list(component)
				if(!is_carrier)
					filtered += list(overlay)
			overlays = filtered
		for(var/list/overlay in overlays)
			mark_loadout_tint_components(overlay, normalized_tint_marker)
		recipes["[dir]"] = overlays || list()
		if(length(overlays))
			has_worn_preview = TRUE
	var/name = variant || I.name
	var/list/result = list("id" = variant || "", "name" = name, "default_name" = I.name, "default_description" = I.desc, "icon" = icon_asset, "recipes" = recipes, "equippable" = equipped, "worn" = equipped && has_worn_preview, "color" = base_color)
	if(istype(I, /obj/item/clothing/accessory))
		var/obj/item/clothing/accessory/A = I
		result["accessory_slot"] = A.slot
	if(istype(I, /obj/item/clothing))
		var/obj/item/clothing/C = I
		result["valid_accessory_slots"] = C.valid_accessory_slots
		result["restricted_accessory_slots"] = C.restricted_accessory_slots
	if(!equipped)
		qdel(I)
	reset_mannequin_equipment(mannequin, layers)
	return result

/proc/mark_loadout_tint_components(list/component, list/marker)
	var/list/colors = component["colors"]
	var/list/retained = list()
	component["loadout_tint"] = FALSE
	for(var/color in colors)
		if(islist(color) && json_encode(color) == json_encode(marker))
			component["loadout_tint"] = TRUE
		else
			retained += list(color)
	component["colors"] = retained
	for(var/list/overlay in component["overlays"])
		mark_loadout_tint_components(overlay, marker)

/datum/tgui_module/custom_marking_designer/proc/build_loadout_catalog(mob/user)
	if(!custom_marking_gear_preview_cache_complete)
		throw EXCEPTION("Loadout preview assets are still loading.")
	var/list/valid = get_loadout_valid_choices()
	var/context_signature = get_loadout_context_signature()
	var/signature = md5("[context_signature]|[json_encode(valid)]|[jobban_isbanned(user, "Custom loadout")]")
	if(loadout_catalog_signature == signature && islist(loadout_catalog))
		return loadout_catalog
	var/list/items = list()
	var/list/names = valid.Copy()
	var/list/slots = get_loadout_slots()
	for(var/slot in slots)
		var/list/saved = slots[slot]
		for(var/name in saved)
			names |= name
	var/datum/job/preview_job = prefs.get_loadout_preview_job()
	for(var/name in names)
		CHECK_TICK
		var/datum/gear/G = gear_datums[name]
		if(!G)
			items += list(list("id" = name, "name" = name, "category" = "Unavailable", "description" = "This saved item no longer exists.", "cost" = 0, "available" = FALSE, "permitted" = FALSE, "slot" = "", "tweaks" = list(), "variants" = list(list("id" = "", "name" = name, "recipes" = list()))))
			continue
		var/list/tweaks = list()
		var/datum/gear_tweak/path/path_tweak
		for(var/datum/gear_tweak/T in G.gear_tweaks)
			var/list/spec = build_loadout_tweak_spec(T, user)
			if(spec)
				tweaks += list(spec)
			if(istype(T, /datum/gear_tweak/path))
				path_tweak = T
		var/list/variants = list()
		if(path_tweak)
			for(var/variant in path_tweak.valid_paths)
				variants += list(build_loadout_variant_metadata(G, variant, path_tweak.valid_paths[variant]))
		else
			variants += list(build_loadout_variant_metadata(G, "", G.path))
		var/permitted = (!G.allowed_roles || (preview_job && (preview_job.title in G.allowed_roles))) && (!G.whitelisted || G.whitelisted == prefs.species)
		items += list(list("id" = name, "name" = G.display_name, "category" = G.sort_category, "description" = G.description, "cost" = G.cost, "available" = (name in valid), "permitted" = permitted, "slot" = "[G.slot]", "stackable" = (G.slot == slot_tie), "requires_uniform" = (G.slot == slot_wear_id), "tweaks" = tweaks, "variant_tweak" = path_tweak ? "[path_tweak]" : null, "variants" = variants))
	if(context_signature != get_loadout_context_signature())
		throw EXCEPTION("Character settings changed while the Loadout catalog was loading.")
	loadout_catalog = list("items" = items, "slot_count" = config.loadout_slots, "max_cost" = MAX_GEAR_COST, "hide_shoes" = !!prefs.shoe_hater, "silicon_job" = preview_job && (preview_job.type == /datum/job/ai || preview_job.type == /datum/job/cyborg))
	loadout_catalog_signature = signature
	return loadout_catalog

/proc/cmp_loadout_preview_priority(list/A, list/B)
	return (A["priority"] - B["priority"]) || sorttext(B["name"], A["name"])

/datum/tgui_module/custom_marking_designer/proc/build_loadout_preview_queue(list/catalog, list/values)
	var/list/queue = list()
	var/list/saved_variants = list()
	var/list/items = catalog["items"]
	for(var/list/entry in items)
		var/list/variants = entry["variants"]
		var/list/presets = values["slots"]
		saved_variants = list()
		for(var/slot in presets)
			for(var/list/saved in presets[slot])
				if(saved["id"] == entry["id"])
					var/list/first_variant = variants[1]
					saved_variants |= saved["tweaks"]?[entry["variant_tweak"]] || first_variant["id"]
		for(var/i = 1 to variants.len)
			var/list/variant = variants[i]
			if(variant["preview_pending"])
				queue += list(list("entry" = entry, "index" = i, "name" = variant["name"], "priority" = (variant["id"] in saved_variants) ? 0 : (entry["category"] == "General" ? 1 : 2)))
	sortTim(queue, GLOBAL_PROC_REF(cmp_loadout_preview_priority))
	return queue

/datum/tgui_module/custom_marking_designer/proc/stream_loadout_previews(mob/user, request_id, generation, recipe_signature, list/queue)
	set waitfor = FALSE
	var/sequence = 0
	var/next = 1
	var/next_update = world.time
	var/list/pending_previews = list()
	while(next <= queue.len)
		sleep(world.tick_lag > 0 ? world.tick_lag : 1)
		CHECK_TICK
		if(QDELETED(src) || generation != loadout_preview_generation || recipe_signature != get_loadout_recipe_signature() || !SStgui.get_open_ui(user, src))
			return
		var/list/previews = list()
		var/exception/build_error
		acquire_preview_payload_build_lock()
		var/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin = get_static_gear_recipe_mannequin()
		try
			if(generation != loadout_preview_generation || recipe_signature != get_loadout_recipe_signature())
				release_preview_payload_build_lock()
				return
			copy_preferences_to_mannequin_without_marking(mannequin)
			while(next <= queue.len && previews.len < 20)
				var/list/task = queue[next++]
				var/list/entry = task["entry"]
				var/list/variants = entry["variants"]
				var/list/variant = variants[task["index"]]
				var/datum/gear/G = gear_datums[entry["id"]]
				var/item_path = G.path
				for(var/datum/gear_tweak/path/T in G.gear_tweaks)
					item_path = T.valid_paths[variant["id"]]
				var/cache_key = get_loadout_variant_cache_key(G, variant["id"], item_path)
				var/list/recipe = build_loadout_variant(G, variant["id"], item_path, mannequin)
				cache_loadout_variant(cache_key, recipe)
				variants[task["index"]] = recipe
				previews += list(list("gear_id" = entry["id"], "variant" = recipe))
				if(TICK_CHECK)
					break
		catch(var/exception/error)
			build_error = error
		reset_mannequin_equipment(mannequin, list(6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27))
		release_preview_payload_build_lock()
		if(QDELETED(src) || generation != loadout_preview_generation || recipe_signature != get_loadout_recipe_signature())
			return
		pending_previews += previews
		if(next <= queue.len && !build_error && world.time < next_update)
			continue
		var/list/batch = list("request_id" = request_id, "recipe_signature" = recipe_signature, "sequence" = ++sequence, "previews" = pending_previews, "complete" = next > queue.len || !!build_error)
		pending_previews = list()
		next_update = world.time + 1
		if(build_error)
			log_error("Character Designer Loadout previews failed: [build_error.name]")
			batch["error"] = "Some Loadout previews could not be loaded. Retry previews to continue."
		var/datum/tgui/ui = SStgui.get_open_ui(user, src)
		if(ui)
			ui.send_update(list("loadout_preview_batch" = batch))
		if(build_error)
			return

/datum/preferences/proc/get_loadout_preview_job()
	if(job_civilian_low & ASSISTANT)
		return job_master.GetJob(USELESS_JOB)
	if(ispAI(client?.mob))
		return null
	for(var/datum/job/job in job_master.occupations)
		var/job_flag
		switch(job.department_flag)
			if(CIVILIAN)
				job_flag = job_civilian_high
			if(MEDSCI)
				job_flag = job_medsci_high
			if(ENGSEC)
				job_flag = job_engsec_high
		if(job.flag == job_flag)
			return job
	return null

/datum/tgui_module/custom_marking_designer/proc/validate_loadout_payload(list/values, mob/user, list/errors)
	if(!islist(values) || values["revision"] != get_loadout_revision())
		errors += "This Loadout draft is out of date. Reload saved Loadout and try again."
		return null
	var/active = values["active"]
	var/list/changed = values["slots"]
	if(!isnum(active) || active != round(active) || !ISINRANGE(active, 1, config.loadout_slots) || !islist(changed) || changed.len > config.loadout_slots)
		errors += "Invalid loadout presets."
		return null
	var/list/valid = get_loadout_valid_choices()
	var/list/staged = get_loadout_slots()
	if(active != prefs.gear_slot && !("[active]" in changed))
		changed = changed.Copy()
		var/list/current_values = build_loadout_values()
		var/list/current_slots = current_values["slots"]
		changed["[active]"] = current_slots["[active]"]
	for(var/slot in changed)
		var/index = text2num(slot)
		var/list/items = changed[slot]
		if(!index || "[index]" != slot || index != round(index) || !ISINRANGE(index, 1, config.loadout_slots) || !islist(items) || items.len > gear_datums.len)
			errors += "Invalid loadout preset."
			return null
		var/list/previous = staged[slot]
		var/list/next = list()
		var/total = 0
		for(var/entry in items)
			if(!islist(entry))
				errors += "Invalid loadout item."
				return null
			var/list/item = entry
			var/name = item["id"]
			var/datum/gear/G = gear_datums[name]
			if(!G || !(name in valid) || (name in next))
				errors += "Invalid, duplicate, or unavailable loadout item: [name]."
				return null
			total += G.cost
			if(total > MAX_GEAR_COST)
				errors += "Preset [slot] exceeds the loadout point limit."
				return null
			var/list/submitted = item["tweaks"]
			if(!islist(submitted))
				errors += "Invalid item customizations."
				return null
			var/list/old_metadata = previous?[name]
			var/list/metadata = islist(old_metadata) ? old_metadata.Copy() : list()
			var/list/known = list()
			for(var/datum/gear_tweak/T in G.gear_tweaks)
				var/key = "[T]"
				known += key
				if(!(key in submitted))
					continue
				var/old_value = islist(old_metadata) && (key in old_metadata) ? old_metadata[key] : T.get_default()
				var/new_value = submitted[key]
				if(json_encode(old_value) == json_encode(new_value))
					if(!islist(old_metadata) || !(key in old_metadata))
						metadata[key] = old_value
					continue
				metadata[key] = validate_loadout_tweak_value(T, new_value, user, errors)
				if(errors.len)
					return null
			for(var/key in submitted)
				if(!(key in known))
					errors += "Unknown item customization."
					return null
			next[name] = metadata
		staged[slot] = next
	return staged

/datum/tgui_module/custom_marking_designer/proc/handle_loadout_action(action, list/params, mob/user)
	if(!(action in list("load_loadout", "save_loadout", "close_loadout")))
		return FALSE
	if(!prefs || !user)
		return TRUE
	if(action == "close_loadout")
		if(!loadout_save_in_progress)
			loadout_preview_generation++
			SStgui.close_uis(src)
		return TRUE
	var/saving = action == "save_loadout"
	var/request_id = params?["request_id"]
	var/list/response = list("request_id" = request_id)
	var/list/errors = list()
	var/accepted = FALSE
	var/generation
	var/list/preview_queue
	if(loadout_save_in_progress || loadout_load_in_progress)
		response["error"] = "A Loadout request is already in progress."
	else
		loadout_save_in_progress = saving
		loadout_load_in_progress = !saving
		if(!saving)
			generation = ++loadout_preview_generation
			try
				response["catalog"] = build_loadout_catalog(user)
				response["values"] = build_loadout_values()
				response["context_signature"] = get_loadout_context_signature()
				response["recipe_signature"] = get_loadout_recipe_signature()
				preview_queue = build_loadout_preview_queue(response["catalog"], response["values"])
			catch(var/exception/error)
				errors += "Loadout could not be loaded. Please try again."
				log_error("Character Designer Loadout catalog failed: [error.name]")
		acquire_preview_payload_build_lock()
		try
			if(saving)
				var/list/values = json_decode(params?["loadout"])
				var/list/staged = validate_loadout_payload(values, user, errors)
				if(islist(staged))
					prefs.gear_list = staged
					prefs.gear_slot = values["active"]
					prefs.gear = staged["[prefs.gear_slot]"] || list()
					accepted = TRUE
					response["values"] = build_loadout_values()
					response["gear"] = build_static_gear_preview_recipes()
			else if(!errors.len)
				var/list/catalog = response["catalog"]
				catalog["gear"] = build_static_gear_preview_recipes()
		catch(var/exception/error)
			log_error("Character Designer Loadout [action] failed: [error.name]")
			errors += "Loadout could not be processed. Please try again."
		release_preview_payload_build_lock()
		loadout_save_in_progress = FALSE
		loadout_load_in_progress = FALSE
	if(errors.len)
		response["error"] = jointext(errors, " ")
	if(saving)
		response["accepted"] = accepted
	var/datum/tgui/ui = SStgui.get_open_ui(user, src)
	if(ui)
		ui.send_update(list((saving ? "loadout_save_result" : "loadout_payload") = response, "loadout_context_signature" = get_loadout_context_signature(), "equipment_context_signature" = get_equipment_context_signature(), "loadout_recipe_signature" = get_loadout_recipe_signature()))
	if(ui && !saving && !errors.len && length(preview_queue))
		stream_loadout_previews(user, request_id, generation, response["recipe_signature"], preview_queue)
	if(accepted)
		try
			refresh_preferences_window_if_visible(TRUE)
		catch(var/exception/error)
			log_error("Loadout saved, but preferences refresh failed: [error.name]")
	return TRUE
