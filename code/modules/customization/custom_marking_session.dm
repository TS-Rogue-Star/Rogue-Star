//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Refactored to be more efficient with significant migration to TGUI //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Session wrapper for painting edits against a single marking frame
/datum/custom_marking_session
	var/datum/custom_marking/mark
	var/dir = NORTH
	var/datum/custom_marking_frame/frame
	var/pending_changes = FALSE

// Bind a painting session to a specific marking frame
/datum/custom_marking_session/New(datum/custom_marking/mark, dir, part)
	..()
	src.mark = mark
	src.dir = dir
	if(mark)
		var/normalized_part = mark.normalize_part(part)
		src.frame = mark.ensure_frame(dir, normalized_part)
	pending_changes = FALSE

// Expose the current composite grid for UI consumption
/datum/custom_marking_session/proc/get_grid()
	if(!frame)
		return null
	return frame.get_composite()

// Apply a client diff payload onto the active frame grid
/datum/custom_marking_session/proc/apply_client_diff(list/diff_entries, canvas_height)
	if(!frame)
		return FALSE
	if(!islist(diff_entries) || !diff_entries.len)
		return FALSE
	var/height = isnum(canvas_height) && canvas_height > 0 ? round(canvas_height) : frame.height
	if(height <= 0)
		height = frame.height
	var/list/layer = frame.ensure_layer(1)
	if(!islist(layer))
		return FALSE
	var/changed = FALSE
	for(var/entry in diff_entries)
		if(!islist(entry))
			continue
		var/x = round(entry["x"])
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
	return changed

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
