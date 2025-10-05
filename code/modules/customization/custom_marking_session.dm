//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/custom_marking_session
	var/datum/custom_marking/mark
	var/dir = NORTH
	var/datum/custom_marking_frame/frame
	var/body_part
	var/history_limit = 50
	var/list/history
	var/list/pending_changes
	var/stroke_dedup = FALSE
	var/list/stroke_visited
	var/current_stroke_id
	var/list/stroke_active_layer
	var/stroke_cached_color_value
	var/stroke_cached_hex
	var/stroke_cached_mode_value
	var/stroke_cached_strength_value = 1
	var/list/live_diff
	var/list/reference_overlay

// Bind a painting session to a specific marking frame
/datum/custom_marking_session/New(datum/custom_marking/mark, dir, part)
	..()
	src.mark = mark
	src.dir = dir
	if(mark)
		src.body_part = mark.normalize_part(part)
		src.frame = mark.ensure_frame(dir, body_part)
	history = list()
	pending_changes = list()

// Expose the current composite grid for UI consumption
/datum/custom_marking_session/proc/get_grid()
	if(!frame)
		return null
	return frame.get_composite()

// Cache a reference sprite grid for lighting and eyedropper use
/datum/custom_marking_session/proc/set_reference_overlay(list/grid)
	reference_overlay = grid

// Retrieve a color from the cached reference overlay
/datum/custom_marking_session/proc/get_reference_color(x, y)
	if(!islist(reference_overlay))
		return null
	var/list/column = reference_overlay[x]
	if(!islist(column))
		return null
	return column[y]

// Apply a single pixel update according to the active brush mode
/datum/custom_marking_session/proc/apply_point(x, y, color, mode = null, strength = 1)
	if(!frame)
		return
	if(!isnum(x) || !isnum(y))
		return
	if(x < 1 || x > frame.width || y < 1 || y > frame.height)
		return
	if(stroke_dedup)
		if(!islist(stroke_visited))
			stroke_visited = list()
		var/key = "[x]-[y]"
		if(stroke_visited[key])
			return
		stroke_visited[key] = TRUE
	var/list/layer = stroke_active_layer
	if(!islist(layer) || layer.len != frame?.width)
		layer = frame?.ensure_layer(1)
		stroke_active_layer = layer
	if(!islist(layer))
		return
	var/list/column = layer[x]
	if(!islist(column))
		layer = frame.ensure_layer(1)
		stroke_active_layer = layer
		column = layer[x]
	if(!islist(column))
		return
	var/old = column[y]
	var/reference_color = isnull(old) ? get_reference_color(x, y) : null
	var/mode_key = stroke_cached_mode_value
	if(!istext(mode_key) && istext(mode))
		mode_key = lowertext(mode)
	else if(istext(mode_key))
		mode_key = lowertext(mode_key)
	var/weight = stroke_cached_strength_value
	if(!isnum(weight))
		weight = isnum(strength) ? CLAMP(strength, 0, 1) : 1
	var/needs_recalc = FALSE
	if(color != stroke_cached_color_value || mode_key != stroke_cached_mode_value || weight != stroke_cached_strength_value)
		needs_recalc = TRUE
	var/new_hex = stroke_cached_hex
	if(needs_recalc)
		if(mode_key == "erase")
			new_hex = null
		else
			new_hex = cm_normalize_hex(color)
		stroke_cached_color_value = color
		stroke_cached_mode_value = mode_key
		stroke_cached_strength_value = weight
		stroke_cached_hex = new_hex
	var/new_color_value
	if(mode_key == "erase")
		new_color_value = null
	else
		if(!new_hex)
			return
		new_color_value = resolve_pixel_color_from_hex(old, new_hex, mode_key, weight, reference_color)
	if(old == new_color_value)
		return
	column[y] = new_color_value
	if(!pending_changes)
		pending_changes = list()
	pending_changes += list(list("x" = x, "y" = y, "old" = old, "new" = new_color_value))
	if(frame)
		frame.update_composite_pixel(x, y)
		if(!islist(live_diff))
			live_diff = list()
		live_diff += list(list("x" = x, "y" = y, "color" = new_color_value))

// Stamp a square brush footprint using the active drawing mode
/datum/custom_marking_session/proc/draw_brush(x, y, size, color, mode = null, strength = 1)
	if(size <= 1)
		apply_point(x, y, color, mode, strength)
		return
	var/offset = round((size - 1) / 2)
	var/start_x = x - offset
	var/start_y = y - offset
	if(!(size % 2))
		start_y -= 1
	for(var/dx in 0 to size - 1)
		var/ix = start_x + dx
		for(var/dy in 0 to size - 1)
			var/iy = start_y + dy
			apply_point(ix, iy, color, mode, strength)

// Paint a line
/datum/custom_marking_session/proc/draw_line(x1, y1, x2, y2, size, color, mode = null, strength = 1)
	var/dx = abs(x2 - x1)
	var/dy = abs(y2 - y1)
	var/sx = x1 < x2 ? 1 : -1
	var/sy = y1 < y2 ? 1 : -1
	var/err = dx - dy
	var/cx = x1
	var/cy = y1
	while(TRUE)
		if(size <= 1)
			apply_point(cx, cy, color, mode, strength)
		else
			draw_brush(cx, cy, size, color, mode, strength)
		if(cx == x2 && cy == y2)
			break
		var/e2 = err * 2
		if(e2 > -dy)
			err -= dy
			cx += sx
		if(e2 < dx)
			err += dx
			cy += sy

// Flood fill contiguous pixels
/datum/custom_marking_session/proc/fill(x, y, color, mode = null, strength = 1)
	if(!frame)
		return
	if(x < 1 || x > frame.width || y < 1 || y > frame.height)
		return
	var/original = frame.get_pixel(x, y)
	var/fallback = isnull(original) ? get_reference_color(x, y) : null
	var/target_color = resolve_pixel_color(original, color, mode, strength, fallback)
	if(original == target_color)
		return
	var/list/queue = list(list(x, y))
	var/list/visited = list("[x]-[y]" = TRUE)
	while(queue.len)
		var/list/node = queue[1]
		queue.Cut(1, 2)
		var/nx = node[1]
		var/ny = node[2]
		var/current = frame.get_pixel(nx, ny)
		if(current != original)
			continue
		apply_point(nx, ny, color, mode, strength)
		for(var/dir_offset in list(list(1,0), list(-1,0), list(0,1), list(0,-1)))
			var/tx = nx + dir_offset[1]
			var/ty = ny + dir_offset[2]
			if(tx < 1 || tx > frame.width || ty < 1 || ty > frame.height)
				continue
			var/key = "[tx]-[ty]"
			if(visited[key])
				continue
			visited[key] = TRUE
			queue += list(list(tx, ty))

// Set up bookkeeping for a new brush stroke
/datum/custom_marking_session/proc/prepare_stroke(stroke, color = null, mode = null, strength = 1)
	if(isnull(stroke))
		stroke_dedup = FALSE
		stroke_visited = null
		current_stroke_id = null
		pending_changes = list()
		live_diff = list()
	else
		var/id = "[stroke]"
		if(current_stroke_id != id)
			current_stroke_id = id
			stroke_visited = list()
			pending_changes = list()
			live_diff = list()
		stroke_dedup = TRUE
	var/mode_key = istext(mode) ? lowertext(mode) : null
	var/weight = isnum(strength) ? CLAMP(strength, 0, 1) : 1
	if(color != stroke_cached_color_value || mode_key != stroke_cached_mode_value || weight != stroke_cached_strength_value)
		if(mode_key == "erase")
			stroke_cached_hex = null
		else
			stroke_cached_hex = cm_normalize_hex(color)
	stroke_cached_color_value = color
	stroke_cached_mode_value = mode_key
	stroke_cached_strength_value = weight
	if(frame)
		if(!islist(stroke_active_layer) || stroke_active_layer.len != frame.width)
			stroke_active_layer = frame.ensure_layer(1)
	else
		stroke_active_layer = null
/datum/custom_marking_session/proc/pull_live_diff()
	if(!islist(live_diff) || !live_diff.len)
		return null
	var/list/out = live_diff
	live_diff = list()
	return out

// Push accumulated pixel edits into the undo history and report whether anything changed
/datum/custom_marking_session/proc/commit_pending()
	if(!pending_changes || !pending_changes.len)
		return FALSE
	while(history.len >= history_limit)
		history.Cut(1, 2)
	history += list(pending_changes)
	pending_changes = list()
	frame.invalidate()
	if(mark)
		mark.invalidate_bake()
	return TRUE

// Revert the most recent committed stroke
/datum/custom_marking_session/proc/undo()
	if(!history || !history.len)
		return FALSE
	var/list/last = history[history.len]
	history.Cut(history.len, history.len + 1)
	for(var/list/change in last)
		frame.set_pixel(change["x"], change["y"], change["old"])
	frame.invalidate()
	return TRUE

// Erase the entire frame and reset stroke bookkeeping
/datum/custom_marking_session/proc/clear()
	if(!frame)
		return FALSE
	pending_changes = list()
	var/list/all_changes = list()
	var/committed = FALSE
	for(var/x in 1 to frame.width)
		for(var/y in 1 to frame.height)
			var/old = frame.get_pixel(x, y)
			if(isnull(old))
				continue
			frame.set_pixel(x, y, null)
			all_changes += list(list("x" = x, "y" = y, "old" = old, "new" = null))
	if(all_changes.len)
		pending_changes = all_changes
		committed = commit_pending()
	stroke_dedup = FALSE
	stroke_visited = null
	current_stroke_id = null
	stroke_active_layer = null
	stroke_cached_color_value = null
	stroke_cached_hex = null
	stroke_cached_mode_value = null
	stroke_cached_strength_value = 1
	live_diff = list()
	history = list()
	return committed || !!all_changes.len

// Report whether there is any undo history to consume
/datum/custom_marking_session/proc/can_undo()
	return !!(history && history.len)

// Return the paint color currently stored at a coordinate
/datum/custom_marking_session/proc/current_color_at(x, y)
	if(!frame)
		return null
	return frame.get_pixel(x, y)

// Combine brush parameters and blend mode into a final color
/datum/custom_marking_session/proc/resolve_pixel_color(old_color, new_color, blend_mode, strength, fallback_color = null)
	var/mode = istext(blend_mode) ? lowertext(blend_mode) : null
	if(mode == "erase")
		return null
	var/new_hex = cm_normalize_hex(new_color)
	if(!new_hex)
		return null
	var/weight = isnum(strength) ? CLAMP(strength, 0, 1) : 1
	return resolve_pixel_color_from_hex(old_color, new_hex, mode, weight, fallback_color)

// Combine resolved base and stroke colors
/datum/custom_marking_session/proc/resolve_pixel_color_from_hex(old_color, new_hex, mode, strength, fallback_color = null)
	if(mode == "erase")
		return null
	if(isnull(new_hex))
		return null
	var/base_hex = cm_normalize_hex(old_color)
	if(!base_hex && fallback_color)
		base_hex = cm_normalize_hex(fallback_color)
	if(!base_hex)
		base_hex = new_hex
	var/weight = isnum(strength) ? CLAMP(strength, 0, 1) : 1
	switch(mode)
		if("add")
			var/added = cm_blend_add(base_hex, new_hex)
			if(!added)
				added = new_hex
			var/mixed = cm_mix_colors(base_hex, added, weight)
			return mixed || added
		if("multiply")
			var/mult = cm_blend_multiply(base_hex, new_hex)
			if(!mult)
				mult = new_hex
			var/mixed2 = cm_mix_colors(base_hex, mult, weight)
			return mixed2 || mult
		if("analog")
			return cm_blend_analog(base_hex, new_hex, weight)
		if("erase")
			return null
	return new_hex

// Validate color inputs and enforce #RRGGBB format
/proc/cm_normalize_hex(value)
	if(!istext(value))
		return null
	if(copytext(value, 1, 2) != "#")
		return null
	var/len = length(value)
	if(len >= 8)
		return lowertext(copytext(value, 1, 8))
	if(len == 7)
		return lowertext(value)
	return null

// Perform additive blending between colors
/proc/cm_blend_add(base_hex, add_hex)
	var/base = cm_normalize_hex(base_hex)
	var/add = cm_normalize_hex(add_hex)
	if(!base || !add)
		return null
	var/r1 = hex2num(copytext(base, 2, 4))
	var/g1 = hex2num(copytext(base, 4, 6))
	var/b1 = hex2num(copytext(base, 6, 8))
	var/r2 = hex2num(copytext(add, 2, 4))
	var/g2 = hex2num(copytext(add, 4, 6))
	var/b2 = hex2num(copytext(add, 6, 8))
	var/r = min(255, r1 + r2)
	var/g = min(255, g1 + g2)
	var/b = min(255, b1 + b2)
	return "#[num2hex(r, 2)][num2hex(g, 2)][num2hex(b, 2)]"

// Multiply two colors as part of brush blending
/proc/cm_blend_multiply(base_hex, mul_hex)
	var/base = cm_normalize_hex(base_hex)
	var/mul = cm_normalize_hex(mul_hex)
	if(!base || !mul)
		return null
	var/r1 = hex2num(copytext(base, 2, 4))
	var/g1 = hex2num(copytext(base, 4, 6))
	var/b1 = hex2num(copytext(base, 6, 8))
	var/r2 = hex2num(copytext(mul, 2, 4))
	var/g2 = hex2num(copytext(mul, 4, 6))
	var/b2 = hex2num(copytext(mul, 6, 8))
	var/r = round((r1 * r2) / 255)
	var/g = round((g1 * g2) / 255)
	var/b = round((b1 * b2) / 255)
	return "#[num2hex(r, 2)][num2hex(g, 2)][num2hex(b, 2)]"

// Blend between two colors using linear
/proc/cm_mix_colors(base_hex, top_hex, weight)
	var/base = cm_normalize_hex(base_hex)
	var/top = cm_normalize_hex(top_hex)
	if(!base || !top)
		return null
	if(!isnum(weight))
		weight = 1
	weight = CLAMP(weight, 0, 1)
	var/r1s = hex2num(copytext(base, 2, 4)) / 255
	var/g1s = hex2num(copytext(base, 4, 6)) / 255
	var/b1s = hex2num(copytext(base, 6, 8)) / 255
	var/r2s = hex2num(copytext(top, 2, 4)) / 255
	var/g2s = hex2num(copytext(top, 4, 6)) / 255
	var/b2s = hex2num(copytext(top, 6, 8)) / 255
	var/r1 = cm_srgb_to_linear_component(r1s)
	var/g1 = cm_srgb_to_linear_component(g1s)
	var/b1 = cm_srgb_to_linear_component(b1s)
	var/r2 = cm_srgb_to_linear_component(r2s)
	var/g2 = cm_srgb_to_linear_component(g2s)
	var/b2 = cm_srgb_to_linear_component(b2s)
	var/rm = r1 + (r2 - r1) * weight
	var/gm = g1 + (g2 - g1) * weight
	var/bm = b1 + (b2 - b1) * weight
	var/ro = cm_linear_to_srgb_component(rm)
	var/go = cm_linear_to_srgb_component(gm)
	var/bo = cm_linear_to_srgb_component(bm)
	var/r8 = round(max(0, min(1, ro)) * 255)
	var/g8 = round(max(0, min(1, go)) * 255)
	var/b8 = round(max(0, min(1, bo)) * 255)
	return "#[num2hex(r8, 2)][num2hex(g8, 2)][num2hex(b8, 2)]"

// Generate an analog color between two tones for shading
/proc/cm_blend_analog(base_hex, mix_hex, weight)
	var/base = cm_normalize_hex(base_hex)
	var/mix = cm_normalize_hex(mix_hex)
	if(!base || !mix)
		return mix
	if(!isnum(weight))
		weight = 0.5
	weight = CLAMP(weight, 0, 1)
	var/r1s = hex2num(copytext(base, 2, 4)) / 255
	var/g1s = hex2num(copytext(base, 4, 6)) / 255
	var/b1s = hex2num(copytext(base, 6, 8)) / 255
	var/r2s = hex2num(copytext(mix, 2, 4)) / 255
	var/g2s = hex2num(copytext(mix, 4, 6)) / 255
	var/b2s = hex2num(copytext(mix, 6, 8)) / 255
	var/r1 = cm_srgb_to_linear_component(r1s)
	var/g1 = cm_srgb_to_linear_component(g1s)
	var/b1 = cm_srgb_to_linear_component(b1s)
	var/r2 = cm_srgb_to_linear_component(r2s)
	var/g2 = cm_srgb_to_linear_component(g2s)
	var/b2 = cm_srgb_to_linear_component(b2s)
	var/eps = 0.001
	if(r1 < eps) r1 = eps
	if(g1 < eps) g1 = eps
	if(b1 < eps) b1 = eps
	if(r2 < eps) r2 = eps
	if(g2 < eps) g2 = eps
	if(b2 < eps) b2 = eps
	var/iw = 1 - weight
	var/rm = (r1 ** iw) * (r2 ** weight)
	var/gm = (g1 ** iw) * (g2 ** weight)
	var/bm = (b1 ** iw) * (b2 ** weight)
	var/ro = cm_linear_to_srgb_component(rm)
	var/go = cm_linear_to_srgb_component(gm)
	var/bo = cm_linear_to_srgb_component(bm)
	var/r8 = round(max(0, min(1, ro)) * 255)
	var/g8 = round(max(0, min(1, go)) * 255)
	var/b8 = round(max(0, min(1, bo)) * 255)
	return "#[num2hex(r8, 2)][num2hex(g8, 2)][num2hex(b8, 2)]"

// Convert an sRGB component to linear
/proc/cm_srgb_to_linear_component(s)
	if(s <= 0)
		return 0
	if(s <= 0.04045)
		return s / 12.92
	return ((s + 0.055) / 1.055) ** 2.4

// Convert a linear color component back to sRGB
/proc/cm_linear_to_srgb_component(l)
	if(l <= 0)
		return 0
	if(l < 0.0031308)
		return 12.92 * l
	return 1.055 * (l ** (1/2.4)) - 0.055