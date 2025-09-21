
///////////
// EASEL //
///////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2025 to make painting more authentic and add a new drawing tablet with a variety of advanced functions //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/structure/easel
	name = "easel"
	desc = "Only for the finest of art!"
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "easel"
	density = TRUE
	//resistance_flags = FLAMMABLE
	//max_integrity = 60
	var/obj/item/canvas/painting = null

//Adding canvases
/obj/structure/easel/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/canvas))
		var/obj/item/canvas/canvas = I
		user.drop_from_inventory(canvas)
		painting = canvas
		canvas.forceMove(get_turf(src))
		canvas.layer = layer+0.1
		user.visible_message("<span class='notice'>[user] puts \the [canvas] on \the [src].</span>","<span class='notice'>You place \the [canvas] on \the [src].</span>")
	else
		return ..()


//Stick to the easel like glue
/obj/structure/easel/Move()
	var/turf/T = get_turf(src)
	. = ..()
	if(painting && painting.loc == T) //Only move if it's near us.
		painting.forceMove(get_turf(src))
	else
		painting = null

/obj/item/canvas
	name = "canvas"
	desc = "Draw out your soul on this canvas!"
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "11x11"
	//flags_1 = UNPAINTABLE_1
	//resistance_flags = FLAMMABLE
	var/width = 11
	var/height = 11
	var/canvas_color = "#ffffff" //empty canvas color
	var/used = FALSE
	var/painting_name = "Untitled Artwork" //Painting name, this is set after framing.
	var/finalized = FALSE //Blocks edits
	var/author_name
	var/author_ckey
	var/icon_generated = FALSE
	var/icon/generated_icon
	///boolean that blocks persistence from saving it. enabled from printing copies, because we do not want to save copies.
	var/no_save = FALSE

	/// From the origin of the turf we're on, where should the left of the canvas pixel be
	var/framed_offset_x = 11
	/// From the origin of the turf we're on, where should the bottom of the canvas be
	var/framed_offset_y = 10
	/// The frame takes the painting's offset, then moves this X offset
	var/frame_offset_x = -1
	/// The frame takes the painting's offset, then moves this Y offset
	var/frame_offset_y = -1

	pixel_x = 10
	pixel_y = 9

	// RS Add Start: Additional variables to support painting enhancements (Lira, September 2025)

	// Support multiple layers
	var/list/layers
	var/active_layer = 1
	var/list/layer_visible

	// Support undo function
	var/list/history
	var/history_limit = 50
	var/list/pending_changes

	// Prevent same brushstroke from effecting pixel multiple times
	var/cur_stroke_id
	var/stroke_dedup = FALSE
	var/list/stroke_visited

	// Strength of brush stroke
	var/analog_strength = 1

	// RS Add End

/obj/item/canvas/Initialize()
	. = ..()
	reset_grid()
	history = list() // RS Add: Initialize undo stack (Lira, September 2025)
	if(!islist(layer_visible)) // RS Add: Start with all layers visible (Lira, September 2025)
		layer_visible = list(TRUE, TRUE, TRUE)
	desc += " (Canvas size is [width]x[height].)" // RSEdit - Add canvas size into the canvas description

/obj/item/canvas/proc/reset_grid()
	layers = new/list(3) // RS Edit: Layers instead of grid (Lira, September 2025)
	for(var/i = 1 to 3) // RS Add: Iterate through layers (Lira, September 2025)
		layers[i] = new/list(width) // RS Add: Initialize layer width (Lira, September 2025)
		for(var/x in 1 to width)
			layers[i][x] = new/list(height) // RS Add: Initialize layer height (Lira, September 2025)
			for(var/y in 1 to height)
				layers[i][x][y] = null // RS Edit: Construct layered grid (Lira, September 2025)
	if(!islist(layer_visible))
		layer_visible = list(TRUE, TRUE, TRUE)

/obj/item/canvas/attack_self(mob/user)
	. = ..()
	tgui_interact(user)

/obj/item/canvas/dropped(mob/user)
	pixel_x = initial(pixel_x)
	pixel_y = initial(pixel_y)
	return ..()

/obj/item/canvas/tgui_state(mob/user)
	if(finalized)
		return GLOB.tgui_physical_obscured_state
	else
		return GLOB.tgui_default_state

/obj/item/canvas/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Canvas", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/canvas/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/paint_palette))
		var/choice = tgui_alert(user, "Adjusting the base color of this canvas will replace ALL pixels with the selected color. Are you sure?", "Confirm Color Fill", list("Yes", "No"))
		if(choice == "No")
			return
		var/basecolor = input(user, "Select a base color for the canvas:", "Base Color", canvas_color) as null|color
		if(basecolor && Adjacent(user) && user.get_active_hand() == I)
			canvas_color = basecolor
			reset_grid()
			user.visible_message("[user] smears paint on [src], covering the entire thing in paint.", "You smear paint on [src], changing the color of the entire thing.", runemessage = "smears paint")
			update_appearance()
			return

	if(user.a_intent == I_HELP)
		tgui_interact(user)
	else
		return ..()

/obj/item/canvas/tgui_data(mob/user)
	. = ..()

	// RS Edit Start: Grid now built from layers (Lira, September 2025)
	if(!islist(layers) || !islist(layers[1]) || !islist(layers[2]) || !islist(layers[3]))
		reset_grid()
	.["grid"] = get_composite_grid_preview()
	// RS Edit End

	.["name"] = painting_name
	.["finalized"] = finalized

	//RS Add Start: Expended to support painting enhancements (Lira, September 2025)
	.["active_layer"] = active_layer
	.["layer_visible"] = layer_visible
	.["can_undo"] = islist(history) && history.len > 0
	.["limited"] = TRUE
	.["can_finalize"] = TRUE
	var/obj/item/I = null
	if(user)
		I = user.get_active_hand()
	var/held = get_paint_tool_color(I)
	.["held_color"] = "#000000"
	if(held)
		.["held_color"] = held
	var/obj/item/paint_brush/brush = null
	if(user)
		if(istype(user.get_active_hand(), /obj/item/paint_brush))
			brush = user.get_active_hand()
		else if(istype(user.get_inactive_hand(), /obj/item/paint_brush))
			brush = user.get_inactive_hand()
	var/obj/item/active_item = null
	var/obj/item/inactive_item = null
	if(user)
		active_item = user.get_active_hand()
		inactive_item = user.get_inactive_hand()
	var/has_palette = istype(active_item, /obj/item/paint_palette) || istype(inactive_item, /obj/item/paint_palette)
	.["brush_color"] = null
	if(brush)
		.["brush_color"] = brush.selected_color
	.["can_set_brush_color"] = FALSE
	if(brush && (istype(brush, /obj/item/paint_brush/organic) || has_palette))
		.["can_set_brush_color"] = TRUE
	// RS Add End

// RS Add: Determine final color for each pixel with multiple layers (Lira, September 2025)
/obj/item/canvas/proc/get_composite_color(x, y)
	if(!islist(layers) || layers.len < 3)
		return canvas_color
	for(var/i=3, i>=1, i--)
		var/list/G = layers[i]
		if(!islist(G))
			continue
		if(x < 1 || x > G.len)
			continue
		var/list/row = G[x]
		if(!islist(row))
			continue
		if(y < 1 || y > row.len)
			continue
		var/C = row[y]
		if(C)
			return C
	return canvas_color

// RS Add: Determine current pixel color based on visible layers (Lira September 2025)
/obj/item/canvas/proc/get_composite_color_preview(x, y)
	if(!islist(layers) || layers.len < 3)
		return canvas_color
	var/list/vis = layer_visible
	for(var/i=3, i>=1, i--)
		if(islist(vis) && vis.len >= i && !vis[i])
			continue
		var/list/G = layers[i]
		if(!islist(G))
			continue
		if(x < 1 || x > G.len)
			continue
		var/list/row = G[x]
		if(!islist(row))
			continue
		if(y < 1 || y > row.len)
			continue
		var/C = row[y]
		if(C)
			return C
	return canvas_color

// RS Add: Build the current visible grid (Lira, September 2025)
/obj/item/canvas/proc/get_composite_grid_preview()
	var/list/out = new/list(width)
	for(var/x in 1 to width)
		out[x] = new/list(height)
		for(var/y in 1 to height)
			out[x][y] = get_composite_color_preview(x, y)
	return out

/obj/item/canvas/examine(mob/user)
	. = ..()
	tgui_interact(user)

/obj/item/canvas/tgui_act(action, params)
	. = ..()
	if(. || finalized)
		return
	var/mob/user = usr
	switch(action)
		if("paint")
			var/obj/item/I = user.get_active_hand()
			var/x = text2num(params["x"])
			var/y = text2num(params["y"])

			// RS Add Start: Updated paint function with a continuous brush stroke (Lira, September 2025)
			var/size = text2num(params["size"])
			var/mode = "normal"
			var/_blend = params["blend"]
			if(_blend)
				mode = lowertext("[_blend]")
			var/strength = text2num(params["strength"])
			if(isnum(strength))
				analog_strength = clamp(strength, 0, 1)
			// RS Add End

			var/color = null // RS Edit: Start color at null (Lira, September 2025)
			if(mode != "erase") // RS Add: Add if line to leave null if erase mode (Lira, September 2025)
				color = get_paint_tool_color(I)
				if(!color)
					return FALSE

			// RS Add Start: Updated paint function with continuous brush stroke (Lira, September 2025)
			var/sid = params["stroke"]
			if(sid)
				ensure_stroke(sid)
			else
				stroke_dedup = FALSE
				pending_changes = list()
			if(!isnum(size) || size < 1)
				size = 1
			if(size <= 1)
				apply_point(x, y, color, mode)
			else
				draw_brush(x, y, size, color, mode)
			// RS Add End

			used = TRUE
			update_appearance()

			// RS Add: Add stroke to history (Lira, September 2025)
			if(!sid)
				commit_history()

			. = TRUE

		// RS Add: New line function inspired by Virgo line function; creates a straight line (Lira, September 2025)
		if("line")
			var/obj/item/I = user.get_active_hand()
			var/x1 = clamp(text2num(params["x1"]), 1, width)
			var/y1 = clamp(text2num(params["y1"]), 1, height)
			var/x2 = clamp(text2num(params["x2"]), 1, width)
			var/y2 = clamp(text2num(params["y2"]), 1, height)
			var/size = text2num(params["size"])
			var/mode = "normal"
			var/_blend2 = params["blend"]
			if(_blend2)
				mode = lowertext("[_blend2]")
			var/color = null
			if(mode != "erase")
				color = get_paint_tool_color(I)
				if(!color)
					return FALSE
			var/strength2 = text2num(params["strength"])
			if(isnum(strength2))
				analog_strength = clamp(strength2, 0, 1)
			var/sid2 = params["stroke"]
			if(sid2)
				ensure_stroke(sid2)
			else
				stroke_dedup = FALSE
				pending_changes = list()
			if(!isnum(size) || size < 1)
				size = 1
			draw_line(x1, y1, x2, y2, color, size, mode)
			used = TRUE
			update_appearance()
			if(!sid2)
				commit_history()
			. = TRUE
		// RS Add: New fill function inspired by Virgo fill function; fills canvas with a color (Lira, September 2025)
		if("fill")
			pending_changes = list()
			var/obj/item/I = user.get_active_hand()
			var/color = get_paint_tool_color(I)
			if(!color)
				return FALSE
			var/x = clamp(text2num(params["x"]), 1, width)
			var/y = clamp(text2num(params["y"]), 1, height)
			var/mode = "normal"
			var/_blend3 = params["blend"]
			if(_blend3)
				mode = lowertext("[_blend3]")
			if(mode == "analog")
				var/strength3 = text2num(params["strength"])
				if(isnum(strength3))
					analog_strength = clamp(strength3, 0, 1)
				else
					analog_strength = 0.5
			stroke_dedup = FALSE
			if(mode == "add" || mode == "multiply" || mode == "analog")
				flood_fill_blend(x, y, color, mode)
			else
				flood_fill(x, y, color)
			used = TRUE
			update_appearance()
			commit_history()
			. = TRUE
		// RS Add: New eyedropper function that copies color from canvas (Lira, September 2025)
		if("eyedropper")
			var/x = clamp(text2num(params["x"]), 1, width)
			var/y = clamp(text2num(params["y"]), 1, height)
			var/newcolor = get_composite_color(x, y)
			if(!istext(newcolor))
				return FALSE
			var/obj/item/paint_brush/brush = null
			if(istype(user.get_active_hand(), /obj/item/paint_brush))
				brush = user.get_active_hand()
			else if(istype(user.get_inactive_hand(), /obj/item/paint_brush))
				brush = user.get_inactive_hand()
			if(!brush)
				return FALSE
			var/obj/item/active_item = user.get_active_hand()
			var/obj/item/inactive_item = user.get_inactive_hand()
			var/has_palette = istype(active_item, /obj/item/paint_palette) || istype(inactive_item, /obj/item/paint_palette)
			if(!(istype(brush, /obj/item/paint_brush/organic) || has_palette))
				return FALSE
			brush.update_paint(newcolor)
			if(istype(brush, /obj/item/paint_brush/organic) && istype(user, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = user
				brush.color = newcolor
				H.species.artist_color = newcolor
			SStgui.update_uis(src)
			. = TRUE
		if("finalize")
			. = TRUE
			if(!finalized)
				// RS Add Start: Make sure all layers are visible (Lira, September 2025)
				if(!islist(layer_visible))
					layer_visible = list(TRUE, TRUE, TRUE)
				else
					for(var/i in 1 to 3)
						layer_visible[i] = TRUE
				// RS Add End
				finalize(user)
				SStgui.update_uis(src) // RS Add: Update UI after finalizing (Lira, September 2025)
		// RS Add: Implement undo button (Lira, September 2025)
		if("undo")
			. = undo_last()
		// RS Add: Track strokes (Lira, September 2025)
		if("commit_stroke")
			commit_history()
			stroke_dedup = FALSE
			stroke_visited = null
			cur_stroke_id = null
			. = TRUE
		// RS Add: Implement layer settings (Lira, September 2025)
		if("set_layer")
			var/L = clamp(text2num(params["layer"]), 1, 3)
			if(L && L != active_layer)
				active_layer = L
				SStgui.update_uis(src)
			. = TRUE
		// RS Add: Implement layer visibility settings (Lira, September 2025)
		if("set_layer_visible")
			var/L2 = clamp(text2num(params["layer"]), 1, 3)
			var/vis = params["visible"]
			if(!islist(layer_visible))
				layer_visible = list(TRUE, TRUE, TRUE)
			if(L2)
				layer_visible[L2] = (isnum(vis) ? (vis != 0) : !!vis)
			SStgui.update_uis(src)
			. = TRUE
		// RS Add: Implement color picker in UI (Lira, September 2025)
		if("pick_color_dialog")
			var/obj/item/paint_brush/brush = null
			if(istype(user.get_active_hand(), /obj/item/paint_brush))
				brush = user.get_active_hand()
			else if(istype(user.get_inactive_hand(), /obj/item/paint_brush))
				brush = user.get_inactive_hand()
			if(!brush)
				return FALSE
			var/obj/item/active_item = user.get_active_hand()
			var/obj/item/inactive_item = user.get_inactive_hand()
			var/has_palette = istype(active_item, /obj/item/paint_palette) || istype(inactive_item, /obj/item/paint_palette)
			if(!(istype(brush, /obj/item/paint_brush/organic) || has_palette))
				return FALSE
			var/default_color = brush.selected_color
			var/newcolor = input(user, "Select a new paint color:", "Base Color", default_color) as null|color
			if(!newcolor)
				return FALSE
			brush.update_paint(newcolor)
			if(istype(brush, /obj/item/paint_brush/organic) && istype(user, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = user
				brush.color = newcolor
				H.species.artist_color = newcolor
			SStgui.update_uis(src)
			. = TRUE
		// RS Add: Support color pick in UI (Lira, September 2025)
		if("pick_color")
			var/newcolor = params["color"]
			if(!istext(newcolor))
				return FALSE
			var/obj/item/paint_brush/brush = null
			if(istype(user.get_active_hand(), /obj/item/paint_brush))
				brush = user.get_active_hand()
			else if(istype(user.get_inactive_hand(), /obj/item/paint_brush))
				brush = user.get_inactive_hand()
			if(!brush)
				return FALSE
			var/obj/item/active_item = user.get_active_hand()
			var/obj/item/inactive_item = user.get_inactive_hand()
			var/has_palette = istype(active_item, /obj/item/paint_palette) || istype(inactive_item, /obj/item/paint_palette)
			if(!(istype(brush, /obj/item/paint_brush/organic) || has_palette))
				return FALSE
			brush.update_paint(newcolor)
			if(istype(brush, /obj/item/paint_brush/organic) && istype(user, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = user
				brush.color = newcolor
				H.species.artist_color = newcolor
			SStgui.update_uis(src)
			. = TRUE

/obj/item/canvas/proc/finalize(mob/user)
	finalized = TRUE
	author_name = user.real_name
	author_ckey = user.ckey
	generate_proper_overlay()
	try_rename(user)

/obj/item/canvas/proc/update_appearance()
	cut_overlays()
	if(icon_generated)
		var/mutable_appearance/detail = mutable_appearance(generated_icon)
		detail.pixel_x = 1
		detail.pixel_y = 1
		add_overlay(detail)
		return
	if(!used)
		return

	var/mutable_appearance/detail = mutable_appearance(icon, "[icon_state]wip")
	detail.pixel_x = 1
	detail.pixel_y = 1
	add_overlay(detail)

// RS Add: New draw line function (Lira, September 2025)
/obj/item/canvas/proc/draw_line(x1, y1, x2, y2, color, size, mode)
	var/dx = abs(x2 - x1)
	var/dy = abs(y2 - y1)
	var/sx = x1 < x2 ? 1 : -1
	var/sy = y1 < y2 ? 1 : -1
	var/err = dx - dy
	var/cx = x1
	var/cy = y1
	if(!isnum(size) || size < 1)
		size = 1
	while(TRUE)
		if(cx >= 1 && cx <= width && cy >= 1 && cy <= height)
			if(size <= 1)
				apply_point(cx, cy, color, mode)
			else
				draw_brush(cx, cy, size, color, mode)
		if(cx == x2 && cy == y2)
			break
		var/e2 = 2 * err
		if(e2 > -dy)
			err -= dy
			cx += sx
		if(e2 < dx)
			err += dx
			cy += sy

// RS Add: Brush function (Lira, September 2025)
/obj/item/canvas/proc/draw_brush(cx, cy, size, color, mode)
	if(size <= 1)
		if(cx >= 1 && cx <= width && cy >= 1 && cy <= height)
			apply_point(cx, cy, color, mode)
		return
	var/start_x = cx - round((size - 1) / 2)
	var/start_y = cy - round((size - 1) / 2)
	for(var/dx in 0 to size - 1)
		for(var/dy in 0 to size - 1)
			var/x = start_x + dx
			var/y = start_y + dy
			if(x >= 1 && x <= width && y >= 1 && y <= height)
				apply_point(x, y, color, mode)

// RS Add: Fill function (Lira, September 2025)
/obj/item/canvas/proc/flood_fill(start_x, start_y, new_color)
	if(start_x < 1 || start_x > width || start_y < 1 || start_y > height)
		return
	var/list/G = layers[active_layer]
	if(!islist(G))
		reset_grid(); G = layers[active_layer]
	if(!islist(G[start_x]))
		G[start_x] = new/list(height)
	var/old_color = G[start_x][start_y]
	if(old_color == new_color)
		return
	var/list/qx = list()
	var/list/qy = list()
	qx += start_x
	qy += start_y
	while(qx.len)
		var/x = qx[1]
		var/y = qy[1]
		qx.Cut(1,2)
		qy.Cut(1,2)
		if(x < 1 || x > width || y < 1 || y > height)
			continue
		if(!islist(G[x]))
			G[x] = new/list(height)
		if(G[x][y] != old_color)
			continue
		apply_point(x, y, new_color, "normal")
		qx += x + 1; qy += y
		qx += x - 1; qy += y
		qx += x;     qy += y + 1
		qx += x;     qy += y - 1

// RS Add: Fill when blending colors (Lira, September 2025)
/obj/item/canvas/proc/flood_fill_blend(start_x, start_y, sel_color, mode)
	if(start_x < 1 || start_x > width || start_y < 1 || start_y > height)
		return
	var/list/G = layers[active_layer]
	if(!islist(G))
		reset_grid(); G = layers[active_layer]
	if(!islist(G[start_x]))
		G[start_x] = new/list(height)
	var/target = G[start_x][start_y]
	var/list/qx = list(start_x)
	var/list/qy = list(start_y)
	var/list/visited = list()
	while(qx.len)
		var/x = qx[1]
		var/y = qy[1]
		qx.Cut(1,2)
		qy.Cut(1,2)
		if(x < 1 || x > width || y < 1 || y > height)
			continue
		var/key = "[x],[y]"
		if(visited[key])
			continue
		visited[key] = TRUE
		if(!islist(G[x]))
			G[x] = new/list(height)
		if(G[x][y] != target)
			continue
		apply_point(x, y, sel_color, mode)
		qx += x + 1; qy += y
		qx += x - 1; qy += y
		qx += x;     qy += y + 1
		qx += x;     qy += y - 1

// RS Add: Apply color to pixel when blending (Lira, September 2025)
/obj/item/canvas/proc/apply_point(px, py, new_color, mode)
	if(px < 1 || px > width || py < 1 || py > height)
		return
	if(stroke_dedup && (mode == "add" || mode == "multiply" || mode == "analog" || mode == "erase"))
		if(!islist(stroke_visited))
			stroke_visited = list()
		var/skey = "[px],[py]"
		if(stroke_visited[skey])
			return
		stroke_visited[skey] = TRUE
	var/list/G = layers[active_layer]
	if(!islist(G))
		reset_grid(); G = layers[active_layer]
	if(!islist(G[px]))
		G[px] = new/list(height)
	var/layer_old = G[px][py]
	var/base_old = layer_old
	if(isnull(base_old))
		base_old = canvas_color
	var/new_val
	if(mode == "add")
		var/added = blend_add(base_old, new_color)
		new_val = mix_colors(base_old, added, analog_strength)
	else if(mode == "multiply")
		var/mult = blend_multiply(base_old, new_color)
		new_val = mix_colors(base_old, mult, analog_strength)
	else if(mode == "analog")
		new_val = blend_analog(base_old, new_color, analog_strength)
	else if(mode == "erase")
		new_val = null
	else
		new_val = new_color
	if(layer_old == new_val)
		return
	if(islist(pending_changes))
		pending_changes += list(list(px, py, layer_old, new_val, active_layer))
	G[px][py] = new_val

// RS Add: Track history (Lira, September 2025)
/obj/item/canvas/proc/commit_history()
	if(!islist(history) || !islist(pending_changes))
		pending_changes = null; return
	if(!pending_changes.len)
		pending_changes = null; return
	history += list(pending_changes)
	if(history.len > history_limit)
		history.Cut(1,2)
	pending_changes = null

// RS Add: Undo function (Lira, September 2025)
/obj/item/canvas/proc/undo_last()
	if(!islist(history) || !history.len)
		return FALSE
	var/list/entry = history[history.len]
	history.Cut(history.len, history.len+1)
	for(var/i = 1 to entry.len)
		var/list/ch = entry[i]
		var/x = ch[1]
		var/y = ch[2]
		var/old_val = ch[3]
		var/L = ch[5]
		if(L < 1 || L > 3)
			continue
		var/list/G = layers[L]
		if(!islist(G))
			continue
		if(!islist(G[x]))
			G[x] = new/list(height)
		G[x][y] = old_val
	update_appearance()
	return TRUE

// RS Add: Maintain continuous stroke (Lira, September 2025)
/obj/item/canvas/proc/ensure_stroke(sid)
	var/text_id = "[sid]"
	if(cur_stroke_id != text_id)
		cur_stroke_id = text_id
		stroke_visited = new/list(width, height)
		pending_changes = list()
	stroke_dedup = TRUE

// RS Add: Additive color math (Lira, September 2025)
/obj/item/canvas/proc/blend_add(cur_hex, add_hex)
	if(!istext(cur_hex) || !istext(add_hex))
		return cur_hex
	if(length(cur_hex) != 7 || copytext(cur_hex,1,2) != "#")
		return cur_hex
	if(length(add_hex) != 7 || copytext(add_hex,1,2) != "#")
		return cur_hex
	var/r1 = hex2num(copytext(cur_hex, 2, 4))
	var/g1 = hex2num(copytext(cur_hex, 4, 6))
	var/b1 = hex2num(copytext(cur_hex, 6, 8))
	var/r2 = hex2num(copytext(add_hex, 2, 4))
	var/g2 = hex2num(copytext(add_hex, 4, 6))
	var/b2 = hex2num(copytext(add_hex, 6, 8))
	var/r = min(255, r1 + r2)
	var/g = min(255, g1 + g2)
	var/b = min(255, b1 + b2)
	return "#[num2hex(r, 2)][num2hex(g, 2)][num2hex(b, 2)]"

// RS Add: Multiplicative color math (Lira, September 2025)
/obj/item/canvas/proc/blend_multiply(cur_hex, mul_hex)
	if(!istext(cur_hex) || !istext(mul_hex))
		return cur_hex
	if(length(cur_hex) != 7 || copytext(cur_hex,1,2) != "#")
		return cur_hex
	if(length(mul_hex) != 7 || copytext(mul_hex,1,2) != "#")
		return cur_hex
	var/r1 = hex2num(copytext(cur_hex, 2, 4))
	var/g1 = hex2num(copytext(cur_hex, 4, 6))
	var/b1 = hex2num(copytext(cur_hex, 6, 8))
	var/r2 = hex2num(copytext(mul_hex, 2, 4))
	var/g2 = hex2num(copytext(mul_hex, 4, 6))
	var/b2 = hex2num(copytext(mul_hex, 6, 8))
	var/r = round((r1 * r2) / 255)
	var/g = round((g1 * g2) / 255)
	var/b = round((b1 * b2) / 255)
	return "#[num2hex(r, 2)][num2hex(g, 2)][num2hex(b, 2)]"

// RS Add: Transform and mix colors (Lira, September 2025)
/obj/item/canvas/proc/mix_colors(base_hex, top_hex, t)
	if(!istext(base_hex) || !istext(top_hex))
		return base_hex
	if(length(base_hex) != 7 || copytext(base_hex,1,2) != "#")
		return base_hex
	if(length(top_hex) != 7 || copytext(top_hex,1,2) != "#")
		return base_hex
	if(!isnum(t)) t = 1
	t = clamp(t, 0, 1)
	// Parse sRGB
	var/r1s = hex2num(copytext(base_hex, 2, 4)) / 255
	var/g1s = hex2num(copytext(base_hex, 4, 6)) / 255
	var/b1s = hex2num(copytext(base_hex, 6, 8)) / 255
	var/r2s = hex2num(copytext(top_hex, 2, 4)) / 255
	var/g2s = hex2num(copytext(top_hex, 4, 6)) / 255
	var/b2s = hex2num(copytext(top_hex, 6, 8)) / 255
	// Convert to linear
	var/r1 = srgb_to_linear_component(r1s)
	var/g1 = srgb_to_linear_component(g1s)
	var/b1 = srgb_to_linear_component(b1s)
	var/r2 = srgb_to_linear_component(r2s)
	var/g2 = srgb_to_linear_component(g2s)
	var/b2 = srgb_to_linear_component(b2s)
	// Linear interpolation
	var/rm = r1 + (r2 - r1) * t
	var/gm = g1 + (g2 - g1) * t
	var/bm = b1 + (b2 - b1) * t
	// Back to sRGB
	var/ro = linear_to_srgb_component(rm)
	var/go = linear_to_srgb_component(gm)
	var/bo = linear_to_srgb_component(bm)
	var/r8 = round(max(0, min(1, ro)) * 255)
	var/g8 = round(max(0, min(1, go)) * 255)
	var/b8 = round(max(0, min(1, bo)) * 255)
	return "#[num2hex(r8, 2)][num2hex(g8, 2)][num2hex(b8, 2)]"

// RS Add: Analog color blend (Lira, September 2025)
/obj/item/canvas/proc/blend_analog(cur_hex, mix_hex, weight)
	if(!istext(cur_hex) || !istext(mix_hex))
		return cur_hex
	if(length(cur_hex) != 7 || copytext(cur_hex,1,2) != "#")
		return cur_hex
	if(length(mix_hex) != 7 || copytext(mix_hex,1,2) != "#")
		return cur_hex
	if(!isnum(weight)) weight = 0.5
	if(weight < 0) weight = 0
	if(weight > 1) weight = 1
	// Parse sRGB
	var/r1_s = hex2num(copytext(cur_hex, 2, 4)) / 255
	var/g1_s = hex2num(copytext(cur_hex, 4, 6)) / 255
	var/b1_s = hex2num(copytext(cur_hex, 6, 8)) / 255
	var/r2_s = hex2num(copytext(mix_hex, 2, 4)) / 255
	var/g2_s = hex2num(copytext(mix_hex, 4, 6)) / 255
	var/b2_s = hex2num(copytext(mix_hex, 6, 8)) / 255
	// Convert to linear
	var/r1 = srgb_to_linear_component(r1_s)
	var/g1 = srgb_to_linear_component(g1_s)
	var/b1 = srgb_to_linear_component(b1_s)
	var/r2 = srgb_to_linear_component(r2_s)
	var/g2 = srgb_to_linear_component(g2_s)
	var/b2 = srgb_to_linear_component(b2_s)
	// Tiny floor so pure black can still be influenced
	var/eps = 0.001
	if(r1 < eps) r1 = eps
	if(g1 < eps) g1 = eps
	if(b1 < eps) b1 = eps
	if(r2 < eps) r2 = eps
	if(g2 < eps) g2 = eps
	if(b2 < eps) b2 = eps
	var/iw = 1 - weight
	// Geometric mean per channel
	var/rm = (r1 ** iw) * (r2 ** weight)
	var/gm = (g1 ** iw) * (g2 ** weight)
	var/bm = (b1 ** iw) * (b2 ** weight)
	// Back to sRGB
	var/ro = linear_to_srgb_component(rm)
	var/go = linear_to_srgb_component(gm)
	var/bo = linear_to_srgb_component(bm)
	// Clamp and to hex
	var/r8 = round(max(0, min(1, ro)) * 255)
	var/g8 = round(max(0, min(1, go)) * 255)
	var/b8 = round(max(0, min(1, bo)) * 255)
	return "#[num2hex(r8, 2)][num2hex(g8, 2)][num2hex(b8, 2)]"

// RS Add: Convert sRGB to linear helper (Lira, September 2025)
/obj/item/canvas/proc/srgb_to_linear_component(s)
	if(s <= 0) return 0
	if(s <= 0.04045)
		return s / 12.92
	return ((s + 0.055) / 1.055) ** 2.4

// RS Add: Convert linear to sRGB helper (Lira, September 2025)
/obj/item/canvas/proc/linear_to_srgb_component(l)
	if(l <= 0) return 0
	if(l < 0.0031308)
		return 12.92 * l
	return 1.055 * (l ** (1/2.4)) - 0.055

/obj/item/canvas/proc/generate_proper_overlay()
	if(icon_generated)
		return
	var/png_filename = "data/persistent/paintings/temp_painting.png"
	var/result = rustg_dmi_create_png(png_filename,"[width]","[height]",get_data_string())
	if(result)
		CRASH("Error generating painting png : [result]")
	generated_icon = new(png_filename)
	icon_generated = TRUE
	update_appearance()

/obj/item/canvas/proc/get_data_string()
	var/list/data = list()
	for(var/y in 1 to height)
		for(var/x in 1 to width)
			data += get_composite_color(x, y) // RS Edit: Tweak for painting update (Lira, September 2025)
	return data.Join("")

//Todo make this element ?
/obj/item/canvas/proc/get_paint_tool_color(obj/item/I)
	if(!I)
		return
	if(istype(I, /obj/item/paint_brush))
		var/obj/item/paint_brush/P = I
		return P.selected_color
	else if(istype(I, /obj/item/weapon/pen/crayon))
		var/obj/item/weapon/pen/crayon/crayon = I
		return crayon.colour
	else if(istype(I, /obj/item/weapon/pen))
		var/obj/item/weapon/pen/P = I
		switch(P.colour)
			if("black")
				return "#000000"
			if("blue")
				return "#0000ff"
			if("red")
				return "#ff0000"
		return P.colour
	else if(istype(I, /obj/item/weapon/soap) || istype(I, /obj/item/weapon/reagent_containers/glass/rag))
		return canvas_color

/obj/item/canvas/proc/try_rename(mob/user)
	var/new_name = stripped_input(user,"What do you want to name the painting?", max_length = 250)
	if(new_name != painting_name && new_name && CanUseTopic(user, GLOB.tgui_physical_state))
		painting_name = new_name
		// RS Add Start: Ask if the user wants to sign the work
		var/choice = tgui_alert(user, "Would you like to sign your work?", "Sign Artwork", list("Yes", "No"))
		if(choice == "Yes")
			painting_name = "[painting_name], by [user.real_name]"
		// RS Add End
		SStgui.update_uis(src)

/obj/item/canvas/nineteen_nineteen
	icon_state = "19x19"
	width = 19
	height = 19
	pixel_x = 5
	pixel_y = 10
	framed_offset_x = 8
	framed_offset_y = 9

/obj/item/canvas/twentythree_nineteen
	icon_state = "23x19"
	width = 23
	height = 19
	pixel_x = 4
	pixel_y = 10
	framed_offset_x = 6
	framed_offset_y = 8

/obj/item/canvas/twentythree_twentythree
	icon_state = "23x23"
	width = 23
	height = 23
	pixel_x = 5
	pixel_y = 9
	framed_offset_x = 5
	framed_offset_y = 6

/obj/item/canvas/twentyfour_twentyfour
	//name = "ai universal standard canvas"					// Uncomment this when AI can actually
	//desc = "Besides being very large, the AI can accept these as a display from their internal database after you've hung it up." // Not yet
	icon_state = "24x24"
	width = 24
	height = 24
	pixel_x = 2
	pixel_y = 2
	framed_offset_x = 4
	framed_offset_y = 4
	frame_offset_x = -2
	frame_offset_y = -2

//RS Add Start: New drawing tablet (Lira, September 2025)

/obj/item/canvas/drawing_tablet
	name = "drawing tablet"
	desc = "A digital art tablet for painting.  Can be inserted into a photocopier to print your finished work!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "dtablet_off"
	// Give the tablet a larger working area by default
	width = 24
	height = 24
	var/selected_color = "#000000"
	pixel_x = 0
	pixel_y = 0

/obj/item/canvas/drawing_tablet/tgui_data(mob/user)
	. = ..()
	.["limited"] = FALSE
	.["can_finalize"] = FALSE
	.["brush_color"] = selected_color
	.["can_set_brush_color"] = TRUE
	if(!.["held_color"])
		.["held_color"] = selected_color
	return .

/obj/item/canvas/drawing_tablet/tgui_interact(mob/user, datum/tgui/ui)
	icon_state = "dtablet_on"
	return ..()

/obj/item/canvas/drawing_tablet/tgui_close(mob/user)
	. = ..()
	icon_state = "dtablet_off"
	return .

/obj/item/canvas/drawing_tablet/tgui_act(action, params)
	if(action == "pick_color_dialog")
		var/default_color = selected_color
		var/newcolor = input(usr, "Select a new paint color:", "Base Color", default_color) as null|color
		if(!newcolor)
			return FALSE
		selected_color = newcolor
		SStgui.update_uis(src)
		return TRUE
	if(action == "pick_color")
		var/newcolor2 = params["color"]
		if(!istext(newcolor2))
			return FALSE
		selected_color = newcolor2
		SStgui.update_uis(src)
		return TRUE
	if(action == "clear_confirm")
		var/choice = tgui_alert(usr, "Clear the entire canvas? This cannot be undone.", "Confirm Clear", list("Yes", "No"))
		if(choice != "Yes")
			return FALSE
		action = "clear"
	if(action == "clear")
		// Wipe the tablet: clear layers, history and in-progress strokes
		reset_grid()
		history = list()
		pending_changes = null
		stroke_dedup = FALSE
		stroke_visited = null
		cur_stroke_id = null
		used = FALSE
		update_appearance()
		SStgui.update_uis(src)
		return TRUE
	if(action == "eyedropper")
		var/x = clamp(text2num(params["x"]), 1, width)
		var/y = clamp(text2num(params["y"]), 1, height)
		var/newcolor3 = get_composite_color(x, y)
		if(!istext(newcolor3))
			return FALSE
		selected_color = newcolor3
		SStgui.update_uis(src)
		return TRUE
	return ..()

/obj/item/canvas/drawing_tablet/get_paint_tool_color(obj/item/I)
	var/C = ..(I)
	if(C)
		return C
	return selected_color

//RS Add End

/obj/item/paint_brush
	name = "artist's paintbrush"
	desc = "When you really want to put together a masterpiece!"
	description_info = "Hit this on a palette to set the color, and use it on a canvas to paint with that color."
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "brush"
	var/selected_color = "#000000"
	var/image/color_drop
	var/hud_level = FALSE

/obj/item/paint_brush/Initialize()
	. = ..()
	color_drop = image(icon, null, "brush_color")
	color_drop.color = selected_color

// When picked up
/obj/item/paint_brush/hud_layerise()
	. = ..()
	hud_level = TRUE
	update_paint()

// When put down
/obj/item/paint_brush/reset_plane_and_layer()
	. = ..()
	hud_level = FALSE
	update_paint()

/obj/item/paint_brush/proc/update_paint(var/new_color)
	if(new_color)
		selected_color = new_color
		color_drop.color = new_color

	cut_overlays()
	if(hud_level)
		add_overlay(color_drop)

/obj/item/paint_palette
	name = "artist's palette"
	desc = "Helps to have a paintbrush, too."
	description_info = "You can hit this on a canvas to set the entire canvas color (but note that it will wipe out any works in progress). You can hit a paintbrush on this to set the color."
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "palette"

/obj/item/paint_palette/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/paint_brush))
		var/obj/item/paint_brush/P = W
		var/newcolor = input(user, "Select a new paint color:", "Paint Palette", P.selected_color) as null|color
		if(newcolor && Adjacent(user, P) && Adjacent(user, src))
			P.update_paint(newcolor)
			if(istype(W, /obj/item/paint_brush/organic) && istype(user, /mob/living/carbon/human)) //RS Add, accounts for organic paintbrushes being used on palettes.
				var/mob/living/carbon/human/H = user
				P.color = newcolor
				H.species.artist_color = newcolor //RS add End
	else
		return ..()

/obj/item/frame/painting
	name = "painting frame"
	desc = "The perfect showcase for your favorite deathtrap memories."
	icon = 'icons/obj/decals.dmi'
	refund_amt = 5
	refund_type = /obj/item/stack/material/wood
	icon_state = "frame-empty"
	build_machine_type = /obj/structure/sign/painting

/obj/structure/sign/painting
	name = "Painting"
	desc = "Art or \"Art\"? You decide."
	icon = 'icons/obj/decals.dmi'
	icon_state = "frame-empty"
	var/base_icon_state = "frame"
	//custom_materials = list(/datum/material/wood = 2000)
	//buildable_sign = FALSE
	///Canvas we're currently displaying.
	var/obj/item/canvas/current_canvas
	///Description set when canvas is added.
	var/desc_with_canvas
	var/persistence_id
	var/loaded = FALSE
	var/curator = "nobody! Report bug if you see this."
	var/static/list/art_appreciators = list()

//Presets for art gallery mapping, for paintings to be shared across stations
/obj/structure/sign/painting/public
	name = "\improper Public Painting Exhibit mounting"
	desc = "For art pieces hung by the public."
	desc_with_canvas = "A piece of art (or \"art\"). Anyone could've hung it."
	persistence_id = "public"

/obj/structure/sign/painting/library_secure
	name = "\improper Curated Painting Exhibit mounting"
	desc = "For masterpieces hand-picked by the librarian."
	desc_with_canvas = "A masterpiece hand-picked by the librarian, supposedly."
	persistence_id = "library"
	req_one_access = list(access_library)
	curator = "Librarian"

/obj/structure/sign/painting/chapel_secure
	name = "\improper Religious Painting Exhibit mounting"
	desc = "For masterpieces hand-picked by the chaplain."
	desc_with_canvas = "A masterpiece hand-picked by the chaplain, supposedly."
	persistence_id = "chapel"
	req_one_access = list(access_chapel_office)
	curator = "Chaplain"

/obj/structure/sign/painting/library_private // keep your smut away from prying eyes, or non-librarians at least
	name = "\improper Private Painting Exhibit mounting"
	desc = "For art pieces deemed too subversive or too illegal to be shared outside of librarians."
	desc_with_canvas = "A painting hung away from lesser minds."
	persistence_id = "library_private"
	req_one_access = list(access_library)
	curator = "Librarian"

/obj/structure/sign/painting/away_areas // for very hard-to-get-to areas
	name = "\improper Remote Painting Exhibit mounting"
	desc = "For art pieces made in the depths of space."
	desc_with_canvas = "A painting hung where only the determined can reach it."
	persistence_id = "away_area"

/obj/structure/sign/painting/Initialize(mapload, dir, building)
	. = ..()
	if(persistence_id)
		SSpersistence.painting_frames += src
	if(dir)
		set_dir(dir)
	if(building)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -30 : 30)
		pixel_y = (dir & 3)? (dir ==1 ? -30 : 30) : 0

/obj/structure/sign/painting/Destroy()
	. = ..()
	SSpersistence.painting_frames -= src

/obj/structure/sign/painting/attackby(obj/item/I, mob/user, params)
	if(!current_canvas && istype(I, /obj/item/canvas))
		frame_canvas(user, I)
	else if(current_canvas && current_canvas.painting_name == initial(current_canvas.painting_name) && istype(I,/obj/item/weapon/pen))
		try_rename(user)
	else if(current_canvas && I.is_wirecutter())
		unframe_canvas(user)
	else
		return ..()

/obj/structure/sign/painting/examine(mob/user)
	. = ..()
	if(persistence_id)
		. += "<span class='notice'>Any painting placed here will be archived at the end of the shift.</span>"

	if(current_canvas)
		current_canvas.tgui_interact(user)
		. += "<span class='notice'>Use wirecutters to remove the painting.</span>"
		. += "<span class='notice'>Paintings hung here are curated based on interest. The more often someone EXAMINEs the painting, the longer it will stay in rotation.</span>"
		// Painting loaded and persistent frame, give a hint about removal safety
		if(persistence_id)
			if(loaded)
				. += "<span class='warning'>Don't worry, the currently framed painting has already been entered into the archives and can be safely removed. It will still be used on future shifts.</span>"
				back_of_the_line(user)
			else
				. += "<span class='warning'>This painting has not been entered into the archives yet. Removing it will prevent that from happening.</span>"

/obj/structure/sign/painting/proc/frame_canvas(mob/user,obj/item/canvas/new_canvas)
	if(!allowed(user))
		to_chat(user, "<span class='notice'>Access lock prevents you from putting a painting into this frame. Ask [curator] for help!</span>")
		return
	if(user.drop_from_inventory(new_canvas, src))
		current_canvas = new_canvas
		if(!current_canvas.finalized)
			current_canvas.finalize(user)
		to_chat(user,"<span class='notice'>You frame [current_canvas].</span>")
		update_appearance()

/obj/structure/sign/painting/proc/unframe_canvas(mob/living/user)
	if(!allowed(user))
		to_chat(user, "<span class='notice'>Access lock prevents you from removing paintings from this frame. Ask [curator] ((or admins)) for help!</span>")
		return
	if(current_canvas)
		current_canvas.forceMove(drop_location())
		current_canvas = null
		loaded = FALSE
		to_chat(user, "<span class='notice'>You remove the painting from the frame.</span>")
		update_appearance()

/obj/structure/sign/painting/proc/try_rename(mob/user)
	if(current_canvas.painting_name == initial(current_canvas.painting_name))
		current_canvas.try_rename(user)

/obj/structure/sign/painting/proc/update_appearance()
	name = current_canvas ? "painting - [current_canvas.painting_name]" : initial(name)
	desc = current_canvas ? desc_with_canvas : initial(desc)
	icon_state = "[base_icon_state]-[current_canvas?.generated_icon ? "hidden" : "empty"]"

	cut_overlays()

	if(!current_canvas?.generated_icon)
		return

	. = list()
	var/mutable_appearance/MA = mutable_appearance(current_canvas.generated_icon)
	MA.pixel_x = current_canvas.framed_offset_x
	MA.pixel_y = current_canvas.framed_offset_y
	. += MA
	var/mutable_appearance/frame = mutable_appearance(current_canvas.icon,"[current_canvas.icon_state]frame")
	frame.pixel_x = current_canvas.framed_offset_x + current_canvas.frame_offset_x
	frame.pixel_y = current_canvas.framed_offset_y + current_canvas.frame_offset_y
	. += frame

	add_overlay(.)

/obj/item/canvas/proc/fill_grid_from_icon(icon/I)
	var/h = I.Height() + 1
	for(var/x in 1 to width)
		for(var/y in 1 to height)
			layers[1][x][y] = I.GetPixel(x,h-y) //RS Edit: Update for layers (Lira, September 2025)

/**
 * Loads a painting from SSpersistence. Called globally by said subsystem when it inits
 *
 * Deleting paintings leaves their json, so this proc will remove the json and try again if it finds one of those.
 */
/obj/structure/sign/painting/proc/load_persistent()
	if(!persistence_id || !LAZYLEN(SSpersistence.unpicked_paintings))
		return

	var/list/painting_category = list()
	for (var/list/P in SSpersistence.unpicked_paintings)
		if(P["persistence_id"] == persistence_id)
			painting_category[++painting_category.len] = P

	var/list/painting
	while(!painting)
		if(!length(painting_category))
			return //aborts loading anything this category has no usable paintings
		var/list/chosen = pick(painting_category)
		if(!fexists("data/persistent/paintings/[persistence_id]/[chosen["md5"]].png")) //shitmin deleted this art, lets remove json entry to avoid errors
			painting_category -= list(chosen)
			SSpersistence.unpicked_paintings -= list(chosen)
			continue //and try again
		painting = chosen
		SSpersistence.unpicked_paintings -= list(chosen)

	var/title = painting["title"]
	var/author_name = painting["author"]
	var/author_ckey = painting["ckey"]
	var/png = "data/persistent/paintings/[persistence_id]/[painting["md5"]].png"
	var/icon/I = new(png)
	var/obj/item/canvas/new_canvas
	var/w = I.Width()
	var/h = I.Height()

	for(var/T in typesof(/obj/item/canvas))
		new_canvas = T
		if(initial(new_canvas.width) == w && initial(new_canvas.height) == h)
			new_canvas = new T(src)
			break

	if(!new_canvas)
		warning("Couldn't find a canvas to match [w]x[h] of painting")
		return

	new_canvas.fill_grid_from_icon(I)
	new_canvas.generated_icon = I
	new_canvas.icon_generated = TRUE
	new_canvas.finalized = TRUE
	new_canvas.painting_name = title
	new_canvas.author_name = author_name
	new_canvas.author_ckey = author_ckey
	new_canvas.name = "painting - [title]"
	current_canvas = new_canvas
	loaded = TRUE
	update_appearance()

/*
 * Recursive Proc. If given no arguments, requests user to input arguments with warning that generating the list may be res intensive
 * Upon generating arguments, calls itself and spawns the painting
 * Ideally called using the vvar dropdown admin verb and used using debugging the SSpersistence list to minimize lag
 * usr must have an admin holder (ergo: only staff may use this)
 * TODO: create a machine in the library for curators to spawn canvases and refactor this to use the proc used there.
 * For now, we do it this way because calling this on a canvas itself might cause issues due to the whole dimension thing.
*/
/obj/structure/sign/painting/proc/admin_lateload_painting(var/spawn_specific = 0, var/which_painting = 0)
	if(!usr.client.holder)
		return 0
	if(spawn_specific && isnum(which_painting))
		var/list/painting = SSpersistence.all_paintings[which_painting]
		var/title = painting["title"]
		var/author_name = painting["author"]
		var/author_ckey = painting["ckey"]
		var/persistence_id = painting["persistence_id"]
		var/png = "data/persistent/paintings/[persistence_id]/[painting["md5"]].png"
		to_chat(usr, span_notice("The chosen painting is the following \n\n \
		Title: [title] \n \
		Author's Name: [author_name]. \n \
		Author's CKey: [author_ckey]"))
		if(tgui_alert(usr, "Check your chat log (if filtering for notices, check where you don't) for painting details.",
		"Is this the painting you want?", list("Yes", "No")) == "No")
			return 0
		if(!fexists("data/persistent/paintings/[persistence_id]/[painting["md5"]].png"))
			to_chat(usr, span_warning("Chosen painting could not be loaded! Incident was logged, but no action taken at this time"))
			log_debug("[usr] tried to spawn painting of list id [which_painting] in all_paintings list and associated file could not be found. \n \
			Painting was titled [title] by [author_ckey] of [persistence_id]")
			return 0

		var/icon/I = new(png)
		var/obj/item/canvas/new_canvas
		var/w = I.Width()
		var/h = I.Height()
		for(var/T in typesof(/obj/item/canvas))
			new_canvas = T
			if(initial(new_canvas.width) == w && initial(new_canvas.height) == h)
				new_canvas = new T(src)
				break

		if(!new_canvas)
			warning("Couldn't find a canvas to match [w]x[h] of painting")
			return 0

		new_canvas.fill_grid_from_icon(I)
		new_canvas.generated_icon = I
		new_canvas.icon_generated = TRUE
		new_canvas.finalized = TRUE
		new_canvas.painting_name = title
		new_canvas.author_name = author_name
		new_canvas.author_ckey = author_ckey
		new_canvas.name = "painting - [title]"
		current_canvas = new_canvas
		loaded = TRUE
		update_appearance()
		log_and_message_admins("spawned painting from [author_ckey] with title [title]", usr)

	else

		if(tgui_alert(usr, "No painting list ID was given. You may obtain such by debugging SSPersistence and checking the all_paintings entry. \
		If you do not wish to do that, you may request a list to be generated of painting titles. This might be resource intensive. \
		Proceed? It will likely have over 500 entries", "Generate list?", list("Proceed!", "Cancel")) == "Cancel")
			return

		log_debug("[usr] generated list of paintings from SSPersistence")
		var/list/paintings = list()
		var/current = 1
		for(var/entry in SSpersistence.all_paintings)
			var/key = "[entry["title"]] by [entry["author"]]"
			paintings[key] = current
			current += 1

		var/choice = tgui_input_list(usr, "Choose which painting to spawn!", "Spawn painting", paintings, null)
		if(!choice)
			return 0
		admin_lateload_painting(1, paintings[choice])




/obj/structure/sign/painting/proc/save_persistent()
	if(!persistence_id || !current_canvas || current_canvas.no_save)
		return
	if(sanitize_filename(persistence_id) != persistence_id)
		stack_trace("Invalid persistence_id - [persistence_id]")
		return
	if(!current_canvas.painting_name)
		current_canvas.painting_name = "Untitled Artwork"

	var/data = current_canvas.get_data_string()
	var/md5 = md5(lowertext(data))
	for(var/list/entry in SSpersistence.all_paintings)
		if(entry["md5"] == md5 && entry["persistence_id"] == persistence_id)
			return
	var/png_directory = "data/persistent/paintings/[persistence_id]/"
	var/png_path = png_directory + "[md5].png"
	var/result = rustg_dmi_create_png(png_path,"[current_canvas.width]","[current_canvas.height]",data)

	if(result)
		CRASH("Error saving persistent painting: [result]")

	SSpersistence.all_paintings += list(list(
		"persistence_id" = persistence_id,
		"title" = current_canvas.painting_name,
		"md5" = md5,
		"author" = current_canvas.author_name,
		"ckey" = current_canvas.author_ckey
	))

/obj/structure/sign/painting/proc/back_of_the_line(mob/user)
	if(user.ckey in art_appreciators)
		return
	if(!persistence_id || !current_canvas || current_canvas.no_save)
		return
	var/data = current_canvas.get_data_string()
	var/md5 = md5(lowertext(data))
	for(var/list/entry in SSpersistence.all_paintings)
		if(entry["md5"] == md5 && entry["persistence_id"] == persistence_id)
			SSpersistence.all_paintings.Remove(list(entry))
			SSpersistence.all_paintings.Add(list(entry))
			art_appreciators += user.ckey
			to_chat(user, "<span class='notice'>Showing interest in this painting renews its position in the curator database.</span>")

/obj/structure/sign/painting/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("removepainting", "Remove Persistent Painting")

/obj/structure/sign/painting/vv_do_topic(list/href_list)
	. = ..()
	if(href_list["removepainting"])
		if(!check_rights(NONE))
			return
		var/mob/user = usr
		if(!persistence_id || !current_canvas)
			to_chat(user,"<span class='warning'>This is not a persistent painting.</span>")
			return
		var/md5 = md5(lowertext(current_canvas.get_data_string()))
		var/author = current_canvas.author_ckey
		var/list/filenames_found = list()
		for(var/list/entry in SSpersistence.all_paintings)
			if(entry["md5"] == md5)
				filenames_found += "data/persistent/paintings/[entry["persistence_id"]]/[entry["md5"]].png"
				SSpersistence.all_paintings -= list(entry)
		for(var/png in filenames_found)
			if(fexists(png))
				fdel(png)
		for(var/obj/structure/sign/painting/P in SSpersistence.painting_frames)
			if(P.current_canvas && md5(P.current_canvas.get_data_string()) == md5)
				QDEL_NULL(P.current_canvas)
				P.update_appearance()
		loaded = FALSE
		log_and_message_admins("<span class='notice'>[key_name_admin(user)] has deleted persistent painting made by [author].</span>")

/obj/structure/sign/painting/unfasten(mob/user)
	if(current_canvas)
		to_chat(user,SPAN_WARNING("You have to remove the painting before you can take down the frame!"))
		return
	. = ..()
