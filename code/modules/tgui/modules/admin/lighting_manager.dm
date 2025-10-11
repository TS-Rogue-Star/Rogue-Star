//////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2025: New panel for managing lighting //
//////////////////////////////////////////////////////////////////////////////////

#define ADMIN_LIGHTING_TARGET_CEILING "ceiling"
#define ADMIN_LIGHTING_TARGET_FLOOR "floor"

/datum/tgui_module/admin_lighting
	name = "Lighting Manager"
	tgui_id = "AdminLightingManager"

	var/list/default_z_selection
	var/list/default_targets
	var/last_result = ""
	var/last_changed = 0
	var/last_considered = 0
	var/light_color_buffer = "#E0EFF0"
	var/overlay_color_buffer = "#E0EFF0"
	var/light_color_revision = 0
	var/overlay_color_revision = 0

/datum/tgui_module/admin_lighting/New()
	..()
	default_z_selection = list()
	for(var/i = 1, i <= min(world.maxz, 3), i++)
		default_z_selection += i
	default_targets = list(ADMIN_LIGHTING_TARGET_CEILING, ADMIN_LIGHTING_TARGET_FLOOR)

/datum/tgui_module/admin_lighting/tgui_state(mob/user)
	return GLOB.tgui_admin_state

/datum/tgui_module/admin_lighting/tgui_data(mob/user)
	var/list/data = list()

	var/list/z_lookup = list()
	var/list/z_entries = list()

	for(var/i = 1, i <= world.maxz, i++)
		var/list/entry = list(
			"id" = i,
			"label" = "Z [i]",
			"ceiling_count" = 0,
			"floor_count" = 0,
			"total" = 0
		)
		z_entries += list(entry)
		z_lookup["[i]"] = entry

	var/total_ceiling = 0
	var/total_floor = 0

	for(var/obj/machinery/light/L in world)
		var/z_key = "[L.z]"
		var/list/entry = z_lookup[z_key]
		if(!entry)
			continue

		entry["total"]++
		if(istype(L, /obj/machinery/light/floortube))
			entry["floor_count"]++
			total_floor++
		else
			entry["ceiling_count"]++
			total_ceiling++

	data["z_levels"] = z_entries.Copy()
	data["target_options"] = list(
		list(
			"id" = ADMIN_LIGHTING_TARGET_CEILING,
			"label" = "Ceiling Fixtures",
			"description" = "Standard wall and ceiling lights."
		),
		list(
			"id" = ADMIN_LIGHTING_TARGET_FLOOR,
			"label" = "Floor Tubes",
			"description" = "Embedded floor lighting fixtures."
		)
	)
	data["default_z"] = default_z_selection.Copy()
	data["default_targets"] = default_targets.Copy()
	data["last_result"] = last_result
	data["last_changed"] = last_changed
	data["last_considered"] = last_considered
	data["summary"] = list(
		"total_ceiling" = total_ceiling,
		"total_floor" = total_floor,
		"total" = total_ceiling + total_floor
	)
	data["light_color_pick"] = light_color_buffer
	data["overlay_color_pick"] = overlay_color_buffer
	data["light_color_revision"] = light_color_revision
	data["overlay_color_revision"] = overlay_color_revision

	return data

/datum/tgui_module/admin_lighting/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(..())
		return TRUE

	switch(action)
		if("apply")
			apply_changes(params)
			return TRUE
		if("restore_defaults")
			restore_defaults(params)
			return TRUE
		if("pick_light_color")
			return pick_color_dialog(params, TRUE)
		if("pick_overlay_color")
			return pick_color_dialog(params, FALSE)
		if("set_light_color")
			return set_color_from_client(params, TRUE)
		if("set_overlay_color")
			return set_color_from_client(params, FALSE)

	return FALSE

/datum/tgui_module/admin_lighting/proc/apply_changes(list/params)
	var/list/z_levels = params["z_levels"]
	if(!islist(z_levels) || !z_levels.len)
		last_result = "Select at least one Z-level."
		return

	var/list/targets = params["targets"]
	if(!islist(targets) || !targets.len)
		last_result = "Select at least one fixture type."
		return

	var/apply_range = lighting_panel_bool(params["apply_range"])
	var/apply_power = lighting_panel_bool(params["apply_power"])
	var/apply_light_color = lighting_panel_bool(params["apply_light_color"])
	var/apply_overlay_color = lighting_panel_bool(params["apply_overlay_color"])
	var/apply_flicker = lighting_panel_bool(params["trigger_flicker"])
	var/apply_spark = lighting_panel_bool(params["trigger_spark"])
	if(!(apply_range || apply_power || apply_light_color || apply_overlay_color || apply_flicker || apply_spark))
		last_result = "Nothing to change. Enable at least one setting."
		return

	var/range_value = null
	if(apply_range)
		range_value = lighting_panel_num(params["range"])
		if(isnull(range_value))
			range_value = 6
		else
			range_value = clamp(range_value, 0, 7)
	else
		range_value = 6

	var/power_value = null
	if(apply_power)
		power_value = lighting_panel_num(params["power"])
		if(isnull(power_value))
			power_value = 1
	else
		power_value = 1

	var/light_color = null
	if(apply_light_color)
		light_color = lighting_panel_color(params["light_color"])
		if(isnull(light_color))
			last_result = "Invalid light color."
			return
		light_color_buffer = light_color

	var/overlay_color = null
	if(apply_overlay_color)
		overlay_color = lighting_panel_color(params["overlay_color"])
		if(isnull(overlay_color))
			last_result = "Invalid overlay color."
			return
		overlay_color_buffer = overlay_color

	var/list/z_filter = list()
	var/list/z_display = list()
	for(var/entry in z_levels)
		var/z = entry
		if(istext(z))
			z = text2num(z)
		if(!isnum(z))
			continue
		z = round(z)
		z_filter["[z]"] = TRUE
		if(!(z in z_display))
			z_display += z

	if(!z_filter.len)
		last_result = "No valid Z-levels found."
		return

	var/affect_ceiling = (ADMIN_LIGHTING_TARGET_CEILING in targets)
	var/affect_floor = (ADMIN_LIGHTING_TARGET_FLOOR in targets)

	if(!(affect_ceiling || affect_floor))
		last_result = "No valid fixture types selected."
		return

	var/changed = 0
	var/considered = 0
	var/flickered = 0
	var/sparked = 0
	var/turned_on = 0

	for(var/obj/machinery/light/L in world)
		if(!(("[L.z]" in z_filter)))
			continue

		var/is_floor = istype(L, /obj/machinery/light/floortube)
		if(is_floor)
			if(!affect_floor)
				continue
		else
			if(!affect_ceiling)
				continue

		considered++
		var/did_change = FALSE

		if(apply_range && L.brightness_range != range_value)
			L.brightness_range = range_value
			did_change = TRUE

		if(apply_power && L.brightness_power != power_value)
			L.brightness_power = power_value
			did_change = TRUE

		if(apply_light_color && L.brightness_color != light_color)
			L.brightness_color = light_color
			did_change = TRUE

		if(apply_overlay_color && overlay_color && L.overlay_color != overlay_color)
			L.overlay_color = overlay_color
			did_change = TRUE

		var/needs_on = (L.status == LIGHT_OK && !L.on && (apply_range || apply_power || apply_light_color || apply_overlay_color || apply_flicker))

		if(did_change)
			if(needs_on)
				L.seton(TRUE)
			else
				L.update(FALSE)
			changed++
		else if(needs_on)
			L.seton(TRUE)
			turned_on++

		if(apply_flicker && L.status == LIGHT_OK)
			if(!L.on)
				L.seton(TRUE)
				turned_on++
			L.flicker()
			flickered++

		if(apply_spark)
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, L)
			s.start()
			sparked++

	if(!considered)
		last_result = "No fixtures matched the selection."
	else
		var/list/desc = list()
		if(apply_range)
			desc += "range = [range_value]"
		if(apply_power)
			desc += "power = [power_value]"
		if(apply_light_color)
			desc += "light color = [light_color]"
		if(apply_overlay_color && overlay_color)
			desc += "overlay color = [overlay_color]"

		var/list/result_bits = list()
		if(changed)
			result_bits += "updated [changed] fixture" + (changed != 1 ? "s" : "")
		if(flickered)
			result_bits += "triggered flicker on [flickered] fixture" + (flickered != 1 ? "s" : "")
		if(sparked)
			result_bits += "triggered sparks on [sparked] fixture" + (sparked != 1 ? "s" : "")
		if(turned_on)
			result_bits += "turned on [turned_on] fixture" + (turned_on != 1 ? "s" : "")
		if(result_bits.len)
			last_result = "[capitalize(english_list(result_bits))] across [english_list(z_display)]."
		else
			last_result = "Fixtures on [english_list(z_display)] already match the requested settings."

		var/list/log_components = list()
		if(desc && desc.len)
			log_components += "adjusted settings ([english_list(desc)])"
		if(flickered)
			log_components += "triggered flicker on [flickered] fixture" + (flickered != 1 ? "s" : "")
		if(sparked)
			log_components += "triggered sparks on [sparked] fixture" + (sparked != 1 ? "s" : "")
		if(turned_on)
			log_components += "turned on [turned_on] fixture" + (turned_on != 1 ? "s" : "")
		if(log_components.len)
			log_and_message_admins("has [english_list(log_components)] on [english_list(z_display)].")

	last_changed = changed + flickered + sparked + turned_on
	last_considered = considered

/datum/tgui_module/admin_lighting/proc/restore_defaults(list/params)
	var/list/z_levels = params["z_levels"]
	if(!islist(z_levels) || !z_levels.len)
		last_result = "Select at least one Z-level."
		return

	var/list/targets = params["targets"]
	if(!islist(targets) || !targets.len)
		last_result = "Select at least one fixture type."
		return

	var/list/z_filter = list()
	var/list/z_display = list()
	for(var/entry in z_levels)
		var/z = entry
		if(istext(z))
			z = text2num(z)
		if(!isnum(z))
			continue
		z = round(z)
		z_filter["[z]"] = TRUE
		if(!(z in z_display))
			z_display += z

	if(!z_filter.len)
		last_result = "No valid Z-levels found."
		return

	var/affect_ceiling = (ADMIN_LIGHTING_TARGET_CEILING in targets)
	var/affect_floor = (ADMIN_LIGHTING_TARGET_FLOOR in targets)

	if(!(affect_ceiling || affect_floor))
		last_result = "No valid fixture types selected."
		return

	var/changed = 0
	var/considered = 0
	var/preview_light_color = null
	var/preview_overlay_color = null
	var/turned_on = 0

	for(var/obj/machinery/light/L in world)
		if(!("[L.z]" in z_filter))
			continue

		var/is_floor = istype(L, /obj/machinery/light/floortube)
		if(is_floor)
			if(!affect_floor)
				continue
		else
			if(!affect_ceiling)
				continue

		considered++

		var/obj/item/weapon/light/bulb = L.installed_light
		var/new_range = null
		var/new_power = null
		var/new_color = null
		var/new_range_ns = null
		var/new_power_ns = null
		var/new_color_ns = null
		var/new_overlay = null

		if(istype(bulb))
			new_range = bulb.brightness_range
			new_power = bulb.brightness_power
			new_color = bulb.brightness_color
			new_range_ns = bulb.nightshift_range
			new_power_ns = bulb.nightshift_power
			new_color_ns = bulb.nightshift_color
			new_overlay = bulb.brightness_color
		else
			new_range = initial(L.brightness_range)
			new_power = initial(L.brightness_power)
			new_color = initial(L.brightness_color)
			new_range_ns = initial(L.brightness_range_ns)
			new_power_ns = initial(L.brightness_power_ns)
			new_color_ns = initial(L.brightness_color_ns)
			new_overlay = initial(L.overlay_color)

		if(isnull(preview_light_color) && !isnull(new_color))
			preview_light_color = new_color
		if(isnull(preview_overlay_color))
			if(!isnull(new_overlay))
				preview_overlay_color = new_overlay
			else if(!isnull(new_color))
				preview_overlay_color = new_color

		var/did_change = FALSE

		if(!isnull(new_range) && L.brightness_range != new_range)
			L.brightness_range = new_range
			did_change = TRUE
		if(!isnull(new_power) && L.brightness_power != new_power)
			L.brightness_power = new_power
			did_change = TRUE
		if(!isnull(new_color) && L.brightness_color != new_color)
			L.brightness_color = new_color
			did_change = TRUE
		if(!isnull(new_range_ns))
			if(L.brightness_range_ns != new_range_ns)
				L.brightness_range_ns = new_range_ns
				did_change = TRUE
		if(!isnull(new_power_ns))
			if(L.brightness_power_ns != new_power_ns)
				L.brightness_power_ns = new_power_ns
				did_change = TRUE
		if(!isnull(new_color_ns))
			if(L.brightness_color_ns != new_color_ns)
				L.brightness_color_ns = new_color_ns
				did_change = TRUE

		if(isnull(new_overlay))
			new_overlay = new_color
		if(!isnull(new_overlay) && L.overlay_color != new_overlay)
			L.overlay_color = new_overlay
			did_change = TRUE

		var/turn_on = (L.status == LIGHT_OK && !L.on)

		if(did_change)
			if(turn_on)
				L.seton(TRUE)
				turned_on++
			else
				L.update(FALSE)
			changed++
		else if(turn_on)
			L.seton(TRUE)
			turned_on++

	if(!considered)
		last_result = "No fixtures matched the selection."
	else
		if(changed)
			last_result = "Restored defaults for [changed] of [considered] fixtures on [english_list(z_display)]."
			log_and_message_admins("has restored default lighting on [english_list(z_display)].")
		else if(turned_on)
			var/msg = "Turned on [turned_on] fixture" + (turned_on != 1 ? "s" : "") + " on [english_list(z_display)]."
			last_result = msg
			log_and_message_admins("has " + lowertext(msg))
		else
			last_result = "Fixtures on [english_list(z_display)] already match their defaults."

	var/updated_buffers = FALSE
	if(!isnull(preview_light_color))
		light_color_buffer = preview_light_color
		light_color_revision++
		updated_buffers = TRUE
	if(!isnull(preview_overlay_color))
		overlay_color_buffer = preview_overlay_color
		overlay_color_revision++
		updated_buffers = TRUE
	if(updated_buffers)
		SStgui.update_uis(src)

	last_changed = changed + turned_on
	last_considered = considered

	return

/datum/tgui_module/admin_lighting/proc/pick_color_dialog(list/params, var/is_light = TRUE)
	var/current = params ? params["current"] : null
	var/default_color = lighting_panel_color(current)
	if(isnull(default_color))
		default_color = is_light ? light_color_buffer : overlay_color_buffer
	var/title = is_light ? "Light Color" : "Overlay Color"
	var/prompt = is_light ? "Select a new light color." : "Select a new overlay tint."
	var/new_color = input(usr, prompt, title, default_color) as null|color
	if(!new_color)
		return FALSE
	if(is_light)
		light_color_buffer = new_color
		light_color_revision++
	else
		overlay_color_buffer = new_color
		overlay_color_revision++
	SStgui.update_uis(src)
	return TRUE

/datum/tgui_module/admin_lighting/proc/set_color_from_client(list/params, var/is_light = TRUE)
	if(!islist(params))
		return FALSE
	var/new_color = lighting_panel_color(params["color"])
	if(isnull(new_color))
		return FALSE
	if(is_light)
		light_color_buffer = new_color
		light_color_revision++
	else
		overlay_color_buffer = new_color
		overlay_color_revision++
	SStgui.update_uis(src)
	return TRUE

/proc/lighting_panel_bool(value)
	if(isnull(value))
		return FALSE
	if(isnum(value))
		return value != 0
	if(istext(value))
		var/text_value = lowertext(value)
		if(text_value == "true" || text_value == "yes" || text_value == "1" || text_value == "on")
			return TRUE
		return FALSE
	return !!value

/proc/lighting_panel_num(value)
	if(isnull(value))
		return null
	if(isnum(value))
		return value
	if(istext(value))
		var/num_value = text2num(value)
		if(isnum(num_value))
			return num_value
	return null

/proc/lighting_panel_color(value)
	if(isnull(value) || !istext(value))
		return null
	value = trim(value)
	if(!length(value))
		return null
	return value

#undef ADMIN_LIGHTING_TARGET_CEILING
#undef ADMIN_LIGHTING_TARGET_FLOOR
