//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Refactored to be more efficient with significant migration to TGUI //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Session wrapper for painting edits against a single marking frame
/datum/custom_marking_session
	var/datum/custom_marking/mark
	var/dir = NORTH
	var/part
	var/datum/custom_marking_frame/frame
	var/pending_changes = FALSE

// Bind a painting session to a specific marking frame
/datum/custom_marking_session/New(datum/custom_marking/mark, dir, part)
	..()
	src.mark = mark
	src.dir = dir
	if(mark)
		var/normalized_part = mark.normalize_part(part)
		src.part = normalized_part
		src.frame = mark.ensure_frame(dir, normalized_part)
	pending_changes = FALSE

// Expose the current composite grid for UI consumption
/datum/custom_marking_session/proc/get_grid()
	if(!frame)
		return null
	return frame.get_composite()

// Apply a client diff payload onto the active frame grid
/datum/custom_marking_session/proc/apply_client_diff(list/diff_entries, canvas_height, canvas_width = null)
	if(!frame)
		return FALSE
	if(!islist(diff_entries) || !diff_entries.len)
		return FALSE
	var/height = isnum(canvas_height) && canvas_height > 0 ? round(canvas_height) : frame.height
	if(height <= 0)
		height = frame.height
	var/ui_width = isnum(canvas_width) && canvas_width > 0 ? round(canvas_width) : null
	var/x_offset = 0
	if(ui_width && frame?.width && ui_width != frame.width)
		x_offset = round((ui_width - frame.width) / 2)
	var/can_resize_part = mark && istext(part) && part != "generic"
	var/current_large = can_resize_part ? mark.is_part_large_canvas(part) : FALSE
	var/effective_width = ui_width ? ui_width : frame.width
	var/needs_expand = FALSE
	if(can_resize_part && !current_large && ((effective_width && effective_width > frame.width) || (height && height > frame.height)))
		for(var/entry in diff_entries)
			if(!islist(entry))
				continue
			var/ui_x = round(entry["x"])
			var/ui_y = round(entry["y"])
			if(!isnum(ui_x) || !isnum(ui_y))
				continue
			if(ui_x < 1 || ui_x > effective_width || ui_y < 1 || ui_y > height)
				continue
			var/x = ui_x - x_offset
			var/y = height - ui_y + 1
			if((effective_width > frame.width && (x < 1 || x > frame.width)) || (height > frame.height && (y < 1 || y > frame.height)))
				needs_expand = TRUE
				break
	var/canvas_changed = FALSE
	var/expanded = FALSE
	if(can_resize_part && needs_expand)
		if(mark.set_part_canvas_size(part, TRUE))
			canvas_changed = TRUE
			expanded = TRUE
			current_large = TRUE
		frame = mark.ensure_frame(dir, part)
		if(ui_width && frame?.width && ui_width != frame.width)
			x_offset = round((ui_width - frame.width) / 2)
		else
			x_offset = 0
	var/list/layer = frame.ensure_layer(1)
	if(!islist(layer))
		return FALSE
	var/changed = FALSE
	for(var/entry in diff_entries)
		if(!islist(entry))
			continue
		var/x = round(entry["x"])
		if(x_offset)
			x -= x_offset
		var/ui_y = round(entry["y"])
		if(!isnum(x) || !isnum(ui_y))
			continue
		var/y = height - ui_y + 1
		if(x < 1 || x > frame.width || y < 1 || y > frame.height)
			continue
		var/list/column = layer[x]
		if(!islist(column))
			column = list()
			column.len = frame.height
			layer[x] = column
		if(column.len < frame.height)
			column.len = frame.height
		var/raw_color = entry["color"]
		var/new_color = null
		if(istext(raw_color) && length(raw_color))
			if(raw_color == "#00000000")
				new_color = null
			else
				new_color = cm_normalize_hex(raw_color)
		var/old = column[y]
		if(old == new_color)
			continue
		column[y] = new_color
		frame.update_composite_pixel(x, y)
		pending_changes = TRUE
		changed = TRUE
	return list(
		"changed" = changed,
		"canvas_resized" = canvas_changed,
		"expanded" = expanded,
		"shrunk" = FALSE
	)

// Flush pending grid edits and invalidate caches
/datum/custom_marking_session/proc/commit_pending()
	if(!pending_changes)
		return FALSE
	pending_changes = FALSE
	frame.invalidate()
	if(mark)
		mark.invalidate_bake()
	return TRUE

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
