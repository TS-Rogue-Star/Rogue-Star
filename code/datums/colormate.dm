//RS Add || Port Virgo PR 15836

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star September 2025 with a new mode for use in the character creator loadout//
//////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/ColorMate
	var/name = "colouring"
	var/atom/movable/inserted
	var/activecolor = "#FFFFFF"
	var/list/color_matrix_last
	var/active_mode = COLORMATE_HSV

	var/build_hue = 0
	var/build_sat = 1
	var/build_val = 1

	/// Minimum lightness for normal mode
	var/minimum_normal_lightness = 50
	/// Minimum lightness for matrix mode, tested using 4 test colors of full red, green, blue, white.
	var/minimum_matrix_lightness = 75
	/// Minimum matrix tests that must pass for something to be considered a valid color (see above)
	var/minimum_matrix_tests = 2
	/// Temporary messages
	var/temp

	// Picker-mode support (for loadout UI, etc.) (Lira, September 2025)
	var/picker_mode = FALSE           // When TRUE, acts as a value picker, not a painter
	var/picker_button = null         // 1 = Ok (paint/confirm), 2 = Erase (clear), 3 = Cancel/Close
	var/list/picker_result_matrix    // Resulting matrix when confirming in picker mode
	var/picker_force_mode = 0        // Non-zero to force a specific mode (e.g., COLORMATE_MATRIX)

/datum/ColorMate/New(mob/user)
	color_matrix_last = list(
		1, 0, 0,
		0, 1, 0,
		0, 0, 1,
		0, 0, 0,
	)
	if(istype(user))
		inserted = user
	. = ..()

/datum/ColorMate/Destroy()
	inserted = null
	. = ..()

/datum/ColorMate/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ColorMate", src.name)
		ui.set_autoupdate(FALSE) //This might be a bit intensive, better to not update it every few ticks
		ui.open()

/datum/ColorMate/tgui_state(mob/user)
	// In picker mode, allow opening even outside a living/conscious context (Lira, September 2025)
	if(picker_mode)
		return GLOB.tgui_always_state
	return GLOB.tgui_conscious_state

// If user closes the window while in picker mode without making a selection, treat as Cancel (Lira, September 2025)
/datum/ColorMate/tgui_close(mob/user)
	. = ..()
	if(picker_mode && !picker_button)
		picker_button = 3

/datum/ColorMate/tgui_data()
	. = list()
	.["activemode"] = active_mode
	.["matrixcolors"] = list(
		"rr" = color_matrix_last[1],
		"rg" = color_matrix_last[2],
		"rb" = color_matrix_last[3],
		"gr" = color_matrix_last[4],
		"gg" = color_matrix_last[5],
		"gb" = color_matrix_last[6],
		"br" = color_matrix_last[7],
		"bg" = color_matrix_last[8],
		"bb" = color_matrix_last[9],
		"cr" = color_matrix_last[10],
		"cg" = color_matrix_last[11],
		"cb" = color_matrix_last[12],
	)
	.["buildhue"] = build_hue
	.["buildsat"] = build_sat
	.["buildval"] = build_val
	if(temp)
		.["temp"] = temp
	if(inserted)
		.["item"] = list()
		.["item"]["name"] = inserted.name
		.["item"]["sprite"] = icon2base64(get_flat_icon(inserted,dir=SOUTH,no_anim=TRUE))
		.["item"]["preview"] = icon2base64(build_preview())
	else
		.["item"] = null

/datum/ColorMate/tgui_act(action, params)
	. = ..()
	if(.)
		return
	if(inserted)
		switch(action)
			if("switch_modes")
				// In picker mode with a forced mode, ignore attempts to switch (Lira, September 2025)
				if(picker_mode && picker_force_mode)
					active_mode = picker_force_mode
					return TRUE
				active_mode = text2num(params["mode"])
				return TRUE
			if("choose_color")
				var/chosen_color = input(inserted, "Choose a color: ", "ColorMate colour picking", activecolor) as color|null
				if(chosen_color)
					activecolor = chosen_color
				return TRUE
			if("paint")
				// In picker mode, confirm and return a matrix result without painting (Lira, September 2025)
				if(picker_mode)
					var/list/cm
					switch(active_mode)
						if(COLORMATE_MATRIX)
							cm = rgb_construct_color_matrix(
								text2num(color_matrix_last[1]),
								text2num(color_matrix_last[2]),
								text2num(color_matrix_last[3]),
								text2num(color_matrix_last[4]),
								text2num(color_matrix_last[5]),
								text2num(color_matrix_last[6]),
								text2num(color_matrix_last[7]),
								text2num(color_matrix_last[8]),
								text2num(color_matrix_last[9]),
								text2num(color_matrix_last[10]),
								text2num(color_matrix_last[11]),
								text2num(color_matrix_last[12]),
							)
						if(COLORMATE_HSV)
							cm = color_matrix_hsv(build_hue, build_sat, build_val)
					// Only accept valid matrices in picker mode
					if(!cm || !islist(cm) || !check_valid_color(cm, inserted))
						temp = "Invalid color."
						return TRUE
					picker_result_matrix = cm
					picker_button = 1
					SStgui.close_uis(src)
					qdel(src)
					return TRUE
				// Normal mode: actually paint
				do_paint(inserted)
				temp = "Painted Successfully!"
				if(istype(inserted, /mob/living/simple_mob))
					var/mob/living/simple_mob/M = inserted
					M.has_recoloured = TRUE
				if(istype(inserted, /mob/living/silicon/robot))
					var/mob/living/silicon/robot/R = inserted
					R.has_recoloured = TRUE
				Destroy()
			if("drop")
				temp = ""
				// Cancel and delete temp item in picker mode (Lira, September 2025)
				if(picker_mode)
					picker_button = 3
					SStgui.close_uis(src)
					qdel(src)
					return TRUE
				Destroy()
			if("clear")
				// Erase in picker mode and return empty list (Lira, September 2025)
				if(picker_mode)
					picker_result_matrix = list()
					picker_button = 2
					SStgui.close_uis(src)
					qdel(src)
					return TRUE
				else
					inserted.remove_atom_colour(FIXED_COLOUR_PRIORITY)
					playsound(src, 'sound/effects/spray3.ogg', 50, 1)
					temp = "Cleared Successfully!"
					return TRUE
			if("set_matrix_color")
				color_matrix_last[params["color"]] = params["value"]
				return TRUE
			if("set_hue")
				build_hue = clamp(text2num(params["buildhue"]), 0, 360)
				return TRUE
			if("set_sat")
				build_sat = clamp(text2num(params["buildsat"]), -10, 10)
				return TRUE
			if("set_val")
				build_val = clamp(text2num(params["buildval"]), -10, 10)
				return TRUE

/datum/ColorMate/proc/do_paint(mob/user)
	var/color_to_use
	switch(active_mode)
		if(COLORMATE_TINT)
			color_to_use = activecolor
		if(COLORMATE_MATRIX)
			color_to_use = rgb_construct_color_matrix(
				text2num(color_matrix_last[1]),
				text2num(color_matrix_last[2]),
				text2num(color_matrix_last[3]),
				text2num(color_matrix_last[4]),
				text2num(color_matrix_last[5]),
				text2num(color_matrix_last[6]),
				text2num(color_matrix_last[7]),
				text2num(color_matrix_last[8]),
				text2num(color_matrix_last[9]),
				text2num(color_matrix_last[10]),
				text2num(color_matrix_last[11]),
				text2num(color_matrix_last[12]),
			)
		if(COLORMATE_HSV)
			color_to_use = color_matrix_hsv(build_hue, build_sat, build_val)
			color_matrix_last = color_to_use
	if(!color_to_use || !check_valid_color(color_to_use, user))
		to_chat(user, SPAN_NOTICE("Invalid color."))
		return FALSE
	inserted.add_atom_colour(color_to_use, FIXED_COLOUR_PRIORITY)
	playsound(src, 'sound/effects/spray3.ogg', 50, 1)
	return TRUE

/// Produces the preview image of the item, used in the UI, the way the color is not stacking is a sin.
/datum/ColorMate/proc/build_preview()
	if(inserted) //sanity
		var/list/cm
		switch(active_mode)
			if(COLORMATE_MATRIX)
				cm = rgb_construct_color_matrix(
					text2num(color_matrix_last[1]),
					text2num(color_matrix_last[2]),
					text2num(color_matrix_last[3]),
					text2num(color_matrix_last[4]),
					text2num(color_matrix_last[5]),
					text2num(color_matrix_last[6]),
					text2num(color_matrix_last[7]),
					text2num(color_matrix_last[8]),
					text2num(color_matrix_last[9]),
					text2num(color_matrix_last[10]),
					text2num(color_matrix_last[11]),
					text2num(color_matrix_last[12]),
				)
				if(!check_valid_color(cm, usr))
					return get_flat_icon(inserted, dir=SOUTH, no_anim=TRUE)

			if(COLORMATE_TINT)
				if(!check_valid_color(activecolor, usr))
					return get_flat_icon(inserted, dir=SOUTH, no_anim=TRUE)

			if(COLORMATE_HSV)
				cm = color_matrix_hsv(build_hue, build_sat, build_val)
				color_matrix_last = cm
				if(!check_valid_color(cm, usr))
					return get_flat_icon(inserted, dir=SOUTH, no_anim=TRUE)

		var/cur_color = inserted.color
		inserted.color = null
		inserted.color = (active_mode == COLORMATE_TINT ? activecolor : cm)
		var/icon/preview = get_flat_icon(inserted, dir=SOUTH, no_anim=TRUE)
		inserted.color = cur_color
		temp = ""

		. = preview

/datum/ColorMate/proc/check_valid_color(list/cm, mob/user)
	if(!islist(cm))		// normal
		var/list/HSV = ReadHSV(RGBtoHSV(cm))
		if(HSV[3] < minimum_normal_lightness)
			temp = "[cm] is too dark (Minimum lightness: [minimum_normal_lightness])"
			return FALSE
		return TRUE
	else	// matrix
		// We test using full red, green, blue, and white
		// A predefined number of them must pass to be considered valid
		var/passed = 0
#define COLORTEST(thestring, thematrix) passed += (ReadHSV(RGBtoHSV(RGBMatrixTransform(thestring, thematrix)))[3] >= minimum_matrix_lightness)
		COLORTEST("FF0000", cm)
		COLORTEST("00FF00", cm)
		COLORTEST("0000FF", cm)
		COLORTEST("FFFFFF", cm)
#undef COLORTEST
		if(passed < minimum_matrix_tests)
			temp = "Matrix is too dark. (passed [passed] out of [minimum_matrix_tests] required tests. Minimum lightness: [minimum_matrix_lightness])."
			return FALSE
		return TRUE

// Call colormate matrix picker (Lira, September 2025)
/proc/colormate_matrix_picker(mob/user, list/values, atom/movable/preview_item)
	if(!user)
		user = usr
	var/datum/ColorMate/CM = new /datum/ColorMate(user)
	CM.picker_mode = TRUE
	CM.picker_force_mode = COLORMATE_MATRIX
	CM.active_mode = COLORMATE_MATRIX
	if(islist(values) && length(values))
		CM.color_matrix_last = values.Copy()
	// Prefer previewing an item if provided, else fall back to user
	if(istype(preview_item))
		CM.inserted = preview_item
	else
		CM.inserted = user // Use user for validity checks/messages
	CM.tgui_interact(user)
	// Wait for user choice or close
	while(CM && !CM.picker_button)
		stoplag(1)
	var/list/ret = list("button" = 3, "matrix" = null)
	if(CM)
		if(CM.picker_button == 1)
			ret["button"] = 1
			ret["matrix"] = CM.picker_result_matrix
		else if(CM.picker_button == 2)
			ret["button"] = 2
			ret["matrix"] = list()
		else
			ret["button"] = 3
			ret["matrix"] = null
		qdel(CM)
	return ret
