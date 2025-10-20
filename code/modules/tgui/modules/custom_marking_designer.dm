//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define CUSTOM_MARKING_DEFAULT_WIDTH 32
#define CUSTOM_MARKING_DEFAULT_HEIGHT 32

/datum/tgui_module/custom_marking_designer
	name = "Custom Marking Designer"
	tgui_id = "CustomMarkingDesigner"

	var/datum/preferences/prefs // Owning preferences datum
	var/datum/custom_marking/mark // Marking being edited
	var/active_dir = NORTH 	// Active direction key (NORTH/SOUTH/EAST/WEST)
	var/brush_color = "#FFFFFF" // Brush color in hex
	var/is_new_mark = FALSE // Track whether this marking was created during this editor session
	var/list/initial_snapshot // Snapshot of serialized data for reverting
	var/list/direction_order // Direction order for UI
	var/list/sessions // Cached painting sessions by direction
	var/active_body_part // Currently active body part for editing
	var/original_mark_id // Original id of the marking when the editor opened
	var/original_style_name // Style label associated with the original mark id
	var/list/reference_payload_cache // Cached species reference payload keyed by direction and re solution
	var/reference_cache_signature // Signature of the prefs data used when building the reference cache
	var/preview_updates_suppressed = FALSE // Suppress preview icon refreshes while the editor is active
	var/preview_refresh_pending = FALSE // Track whether a preview refresh should run once suppression lifts
	var/pending_pref_sync = FALSE // Defer preference_list regeneration until save/close
	var/list/preview_overlay_cache // Stores preview overlay images keyed by direction
	var/reference_mannequin_signature // Tracks last signature applied to the reference mannequin
	var/mark_dirty = FALSE // Track whether changes need to be persisted
	var/layer_cache_dirty = TRUE // Track whether body layer overlays need regeneration
	var/list/cached_body_part_layers // Cached UI grids for body parts in the active direction
	var/list/cached_body_part_order // Cached ordering of body parts as presented to the UI
	var/cached_body_part_dir // Direction key associated with cached layer data
	var/body_part_layer_revision = 0 // Tracks updates for faded body part overlays
	var/diff_sequence = 0 // Tracks incremental ids for live diffs

// Use the standard always-open TGUI state for this editor
/datum/tgui_module/custom_marking_designer/tgui_state(mob/user)
	return GLOB.tgui_always_state

// Finalize edits and refresh previews when the UI closes
/datum/tgui_module/custom_marking_designer/tgui_close(mob/user)
	if(preview_updates_suppressed)
		preview_updates_suppressed = FALSE
	if(preview_refresh_pending)
		refresh_preview_icon(TRUE)
	var/saved = save_marking_changes(mark_dirty)
	. = ..()
	if(saved && prefs && user)
		prefs.ShowChoices(user)
	if(prefs)
		prefs.custom_marking_designer_ui = null
	return .

// Ensure there is always a valid body part focus for editing
/datum/tgui_module/custom_marking_designer/proc/default_body_part()
	if(mark?.body_parts && mark.body_parts.len)
		return mark.body_parts[1]
	if(mark)
		if(!mark.body_parts)
			mark.body_parts = list()
		if(!(BP_TORSO in mark.body_parts))
			mark.body_parts += BP_TORSO
			register_custom_marking_style(mark)
			mark.invalidate_bake()
	return BP_TORSO

// Switch the editing context to a new body part and sync state
/datum/tgui_module/custom_marking_designer/proc/set_active_body_part(part, force = FALSE)
	if(!mark)
		return
	var/normalized = mark.normalize_part(part)
	if(isnull(normalized))
		return
	if(!mark.body_parts)
		mark.body_parts = list()
	var/added_new_part = FALSE
	if(!(normalized in mark.body_parts))
		mark.body_parts += normalized
		register_custom_marking_style(mark)
		mark.invalidate_bake()
		added_new_part = TRUE
	var/previous = active_body_part
	if(!force && previous == normalized)
		return
	var/datum/custom_marking_session/current = null
	if(previous)
		var/key = session_key(active_dir, previous)
		if(sessions && sessions[key])
			current = sessions[key]
	var/committed = commit_session(current)
	active_body_part = normalized
	if(added_new_part)
		mark_dirty = TRUE
		clear_preview_overlay()
		if(!ensure_pref_marking_entry(normalized))
			pending_pref_sync = TRUE
		reference_mannequin_signature = null
		if(prefs)
			prefs.custom_marking_reference_mannequin_signature = null
		layer_cache_dirty = TRUE
	get_active_session()
	if(!added_new_part && !committed)
		SStgui.update_uis(src)
		return
	if(committed)
		layer_cache_dirty = TRUE
	SStgui.update_uis(src)

// Keep preference body marking data aligned with editor selections
/datum/tgui_module/custom_marking_designer/proc/sync_preference_assignment()
	if(!prefs || !mark)
		return
	register_custom_marking_style(mark)
	var/style_name = mark.get_style_name()
	if(!style_name)
		return
	LAZYINITLIST(prefs.body_markings)
	var/list/current = prefs.body_markings?[style_name]
	if(!islist(current))
		prefs.body_markings[style_name] = prefs.mass_edit_marking_list(style_name)
		current = prefs.body_markings[style_name]
	if(!islist(current))
		return
	var/default_color = current["color"]
	if(!istext(default_color))
		default_color = "#FFFFFF"
	var/list/desired_parts = mark.body_parts && mark.body_parts.len ? mark.body_parts : list()
	for(var/part in desired_parts)
		if(!(part in current) || !islist(current[part]))
			current[part] = list("on" = TRUE, "color" = default_color)
	var/list/remove_queue = list()
	for(var/part in current)
		if(!istext(part) || part == "color")
			continue
		if(!(part in desired_parts))
			remove_queue += part
	for(var/part in remove_queue)
		current -= part
	prefs.prune_disallowed_body_markings()
	if(islist(prefs.body_markings))
		var/list/stale = list()
		LAZYINITLIST(body_marking_styles_list)
		for(var/key in prefs.body_markings)
			if(!istext(key))
				continue
			if(!(key in body_marking_styles_list))
				stale += key
		for(var/key in stale)
			prefs.body_markings -= key
	pending_pref_sync = FALSE
	reference_mannequin_signature = null
	if(prefs)
		prefs.custom_marking_reference_mannequin_signature = null
	refresh_preview_icon()

// Update the underlying preference preview when edits occur
/datum/tgui_module/custom_marking_designer/proc/refresh_preview_icon(force = FALSE, skip_asset_refresh = FALSE)
	if(!prefs)
		return
	if(pending_pref_sync && !force)
		return
	if(preview_updates_suppressed && !force)
		preview_refresh_pending = TRUE
		return
	preview_refresh_pending = FALSE
	INVOKE_ASYNC(src, /datum/tgui_module/custom_marking_designer/proc/do_refresh_preview_icon, force, skip_asset_refresh)

// Ensure the sprite accessory cache is warm before editing
/datum/tgui_module/custom_marking_designer/proc/precache_preview_assets()
	if(!mark)
		return
	preview_updates_suppressed = TRUE
	var/datum/custom_marking/target = mark
	INVOKE_ASYNC(src, /datum/tgui_module/custom_marking_designer/proc/do_precache_preview_assets, target)

// Caching
/datum/tgui_module/custom_marking_designer/proc/do_precache_preview_assets(datum/custom_marking/target)
	if(QDELETED(src))
		return
	var/datum/custom_marking/mark_ref = target
	if(!istype(mark_ref))
		mark_ref = mark
	if(!istype(mark_ref) || QDELETED(mark_ref))
		return
	if(prefs && !QDELETED(prefs))
		prefs.refresh_custom_marking_assets(FALSE, TRUE, mark_ref)
	else
		var/datum/sprite_accessory/marking/custom/style = mark_ref.ensure_sprite_accessory(TRUE)
		style?.invalidate_cache()
		style?.regenerate_if_needed()
		if(prefs && !QDELETED(prefs))
			prefs.update_preview_icon()
	preview_updates_suppressed = FALSE
	if(preview_refresh_pending)
		preview_refresh_pending = FALSE
	if(!mark_ref?.has_visible_pixels())
		return
	INVOKE_ASYNC(src, /datum/tgui_module/custom_marking_designer/proc/do_refresh_preview_icon, FALSE, TRUE)

// Refresh preview
/datum/tgui_module/custom_marking_designer/proc/do_refresh_preview_icon(force = FALSE, skip_asset_refresh = FALSE)
	if(QDELETED(src))
		return
	if(!prefs || QDELETED(prefs))
		return
	var/force_refresh = !skip_asset_refresh && (force || pending_pref_sync)
	var/datum/custom_marking/current_mark = mark
	if(force_refresh)
		prefs.refresh_custom_marking_assets(TRUE, TRUE, current_mark)
		update_preview_overlay(TRUE)
	else
		update_preview_overlay(force)

// Initialize editor state and optionally bind an existing marking
/datum/tgui_module/custom_marking_designer/New(datum/preferences/pref, datum/custom_marking/existing)
	..()
	prefs = pref
	if(prefs)
		var/list/shared_cache = prefs.custom_marking_reference_payload_cache
		if(islist(shared_cache))
			reference_payload_cache = shared_cache
		else
			reference_payload_cache = null
		reference_cache_signature = prefs.custom_marking_reference_signature
		reference_mannequin_signature = prefs.custom_marking_reference_mannequin_signature
	else
		reference_payload_cache = null
	if(!istext(reference_cache_signature))
		reference_cache_signature = null
		if(prefs)
			prefs.custom_marking_reference_signature = null
	if(!islist(reference_payload_cache))
		reference_payload_cache = null
		if(prefs)
			prefs.custom_marking_reference_payload_cache = null
	if(!istext(reference_mannequin_signature))
		reference_mannequin_signature = null
		if(prefs)
			prefs.custom_marking_reference_mannequin_signature = null
	sessions = list()
	direction_order = list(NORTH, SOUTH, EAST, WEST)
	clear_preview_overlay()
	preview_updates_suppressed = TRUE
	preview_refresh_pending = FALSE
	layer_cache_dirty = TRUE
	cached_body_part_layers = null
	cached_body_part_order = null
	cached_body_part_dir = null
	if(existing)
		mark = existing
	else
		var/owner = pref?.client_ckey || pref?.client?.ckey || "custom"
		var/id = generate_custom_marking_id(owner)
		mark = new(id, "New Custom Marking", list(BP_TORSO), owner)
		mark.register()
		if(pref)
			LAZYINITLIST(pref.custom_markings)
			pref.custom_markings[mark.id] = mark
		is_new_mark = TRUE
	initial_snapshot = mark.to_save()
	register_custom_marking_style(mark)
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()
	active_body_part = default_body_part()
	sync_preference_assignment()
	precache_preview_assets()
	pending_pref_sync = FALSE

// Fetch or create the painting session for the requested frame
/datum/tgui_module/custom_marking_designer/proc/get_session(dir, part = active_body_part)
	if(!mark)
		return null
	if(!sessions)
		sessions = list()
	var/key = session_key(dir, part)
	var/datum/custom_marking_session/session = sessions[key]
	if(!session)
		session = new(mark, dir, part)
		sessions[key] = session
	apply_reference_overlay(session, dir, part)
	return session

// Refresh static reference payloads for the requester
/datum/tgui_module/custom_marking_designer/proc/push_reference_static_data(mob/user)
	if(!user)
		return FALSE
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	var/refs_changed = ensure_reference_payload_bundle(width, height)
	update_tgui_static_data(user)
	return refs_changed

// Associate the best-fit reference overlay grid with a session
/datum/tgui_module/custom_marking_designer/proc/apply_reference_overlay(datum/custom_marking_session/session, dir, part)
	if(!session)
		return
	var/list/storage_parts = get_reference_storage_part_grids(dir)
	var/list/overlay = null
	if(islist(storage_parts))
		if(istext(part) && length(part))
			var/lower_part = lowertext(part)
			overlay = storage_parts[lower_part]
		if(!islist(overlay) && isnum(part))
			overlay = storage_parts["[part]"]
		if(!islist(overlay))
			overlay = storage_parts["generic"]
	if(!islist(overlay))
		overlay = get_reference_storage_grid(dir)
	session.set_reference_overlay(overlay)

// Produce the lookup key used to cache painting sessions
/datum/tgui_module/custom_marking_designer/proc/session_key(dir, part)
	if(mark)
		return mark.frame_key(dir, part)
	var/dir_component
	if(isnum(dir) && dir)
		dir_component = "[dir]"
	else
		dir_component = "[NORTH]"
	var/part_component = (istext(part) && length(part)) ? part : "generic"
	return "[dir_component]|[part_component]"

// Convenience helper to fetch the UI's current session
/datum/tgui_module/custom_marking_designer/proc/get_active_session()
	return get_session(active_dir, active_body_part)

// Commit a session and flag the mark as dirty when pixels were modified
/datum/tgui_module/custom_marking_designer/proc/commit_session(datum/custom_marking_session/session)
	if(!session)
		return FALSE
	if(session.commit_pending())
		mark_dirty = TRUE
		layer_cache_dirty = TRUE
		return TRUE
	return FALSE

// Persist changes when auto-saving opportunities arise
/datum/tgui_module/custom_marking_designer/proc/maybe_auto_save()
	if(!mark || !mark_dirty)
		return FALSE
	save_marking_changes(TRUE, TRUE)
	return TRUE

// Flush pending brush strokes across every cached session
/datum/tgui_module/custom_marking_designer/proc/commit_all_sessions()
	if(!islist(sessions))
		return FALSE
	var/committed = FALSE
	for(var/key in sessions)
		var/datum/custom_marking_session/session = sessions[key]
		if(commit_session(session))
			committed = TRUE
	return committed

// Drop body parts that no longer contain any painted pixels across every direction
/datum/tgui_module/custom_marking_designer/proc/prune_empty_body_parts()
	if(!mark)
		return FALSE
	if(!islist(mark.body_parts) || !mark.body_parts.len)
		return FALSE
	var/list/dirs = list(NORTH, SOUTH, EAST, WEST)
	var/list/remove_parts = list()
	var/list/parts_snapshot = mark.body_parts.Copy()
	for(var/part in parts_snapshot)
		var/has_pixels = FALSE
		for(var/dir in dirs)
			var/datum/custom_marking_frame/frame = mark.get_frame(dir, part, FALSE)
			if(frame?.has_visible_pixels())
				has_pixels = TRUE
				break
		if(has_pixels)
			continue
		remove_parts += part
	if(!remove_parts.len)
		return FALSE
	var/style_name = mark.get_style_name()
	for(var/part in remove_parts)
		mark.body_parts -= part
		if(islist(sessions))
			for(var/dir in dirs)
				var/session_key_value = session_key(dir, part)
				if(session_key_value && sessions[session_key_value])
					sessions -= session_key_value
		if(part != "generic" && islist(mark.frames))
			for(var/dir in dirs)
				var/frame_key = mark.frame_key(dir, part)
				if(frame_key && mark.frames?[frame_key])
					mark.frames -= frame_key
		if(style_name && prefs && islist(prefs.body_markings))
			var/list/style_entry = prefs.body_markings[style_name]
			if(islist(style_entry))
				style_entry -= part
	layer_cache_dirty = TRUE
	cached_body_part_layers = null
	cached_body_part_order = null
	cached_body_part_dir = null
	body_part_layer_revision++
	pending_pref_sync = TRUE
	mark.invalidate_bake()
	mark_dirty = TRUE
	return TRUE

// Commit edits and refresh caches so the preview stays in sync
/datum/tgui_module/custom_marking_designer/proc/save_marking_changes(force_save = TRUE, refresh_browser = FALSE)
	if(!mark)
		return FALSE
	var/committed = commit_all_sessions()
	var/pruned = prune_empty_body_parts()
	if(!force_save && !mark_dirty && !committed)
		return FALSE
	var/needs_revision = committed || mark_dirty || pruned
	if(!needs_revision)
		return FALSE
	mark.bump_revision()
	recreate_existing_marking()
	finalize_changes(force_save)
	var/datum/custom_marking/mark_ref = mark
	if(prefs && !QDELETED(prefs))
		INVOKE_ASYNC(prefs, /datum/preferences/proc/refresh_custom_marking_assets, force_save, TRUE, mark_ref)
	else
		var/datum/sprite_accessory/marking/custom/style = mark_ref?.ensure_sprite_accessory(TRUE)
		style?.invalidate_cache()
		style?.regenerate_if_needed()
		if(prefs && !QDELETED(prefs))
			prefs.update_preview_icon()
	refresh_preview_icon(force_save, TRUE)
	mark_dirty = FALSE
	if(refresh_browser && prefs)
		var/mob/user = usr
		if(!user && prefs.client)
			user = prefs.client.mob
		if(user && user.client)
			var/visible = winget(user, "preferences_window", "is-visible")
			if(istext(visible) && lowertext(visible) == "true")
				INVOKE_ASYNC(prefs, /datum/preferences/proc/ShowChoices, user)
	return TRUE

// Rebuild marking ids and list entries when edits change metadata
/datum/tgui_module/custom_marking_designer/proc/recreate_existing_marking()
	if(!mark)
		return
	mark.register()
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory(TRUE)
	var/current_id = mark.id
	if(!current_id)
		return
	if(prefs)
		LAZYINITLIST(prefs.custom_markings)
		if(islist(prefs.custom_markings))
			prefs.custom_markings[current_id] = mark
			if(original_mark_id && original_mark_id != current_id)
				prefs.custom_markings -= original_mark_id
	if(is_new_mark)
		return
	if(!original_mark_id)
		original_mark_id = current_id
	var/current_style = mark.get_style_name()
	if(!original_style_name)
		original_style_name = current_style
	if(current_style != original_style_name)
		var/old_entry_found = FALSE
		if(prefs && islist(prefs.body_markings))
			var/list/body_markings_order = list()
			var/list/body_markings_values = list()
			for(var/key in prefs.body_markings)
				body_markings_order += key
				body_markings_values[key] = prefs.body_markings[key]
			var/list/old_entry = body_markings_values[original_style_name]
			if(islist(old_entry))
				old_entry_found = TRUE
				var/list/rebuilt = list()
				for(var/key in body_markings_order)
					if(key == original_style_name)
						rebuilt[current_style] = old_entry
						continue
					var/value = body_markings_values[key]
					if(isnull(value))
						continue
					rebuilt[key] = value
				if(!(current_style in rebuilt))
					rebuilt[current_style] = old_entry
				prefs.body_markings = rebuilt
				var/datum/sprite_accessory/marking/new_marking_datum = style
				if(!new_marking_datum)
					new_marking_datum = body_marking_styles_list?[current_style]
				if(new_marking_datum)
					for(var/part in old_entry)
						if(!istext(part) || part == "color")
							continue
						var/list/details = old_entry[part]
						if(islist(details))
							details["datum"] = new_marking_datum
			if(!old_entry_found)
				pending_pref_sync = TRUE
	var/datum/sprite_accessory/marking/new_style_datum = style
	if(!new_style_datum)
		new_style_datum = body_marking_styles_list?[current_style]
	if(prefs && islist(prefs.body_markings) && new_style_datum)
		var/list/current_entry = prefs.body_markings[current_style]
		if(islist(current_entry))
			for(var/part in current_entry)
				if(!istext(part) || part == "color")
					continue
				var/list/details = current_entry[part]
				if(islist(details))
					details["datum"] = new_style_datum
	prefs?.prune_disallowed_body_markings()
	original_style_name = current_style
	original_mark_id = current_id

// Produce user-friendly labels for directional buttons
/datum/tgui_module/custom_marking_designer/proc/direction_label(dir)
	switch(dir)
		if(NORTH)
			return "North"
		if(SOUTH)
			return "South"
		if(EAST)
			return "East"
		if(WEST)
			return "West"
	return "Unknown"

// Supply invariant data such as directions and reference grids to the UI
/datum/tgui_module/custom_marking_designer/tgui_static_data(mob/user)
	var/list/data = ..()
	var/list/dirs = list()
	for(var/dir in direction_order)
		dirs += list(list("dir" = dir, "label" = direction_label(dir)))
	data["directions"] = dirs
	var/list/parts = list()
	var/list/labels = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(!labels || !labels.len)
		labels = list(
			BP_HEAD = "Head",
			BP_TORSO = "Upper Body",
			BP_GROIN = "Lower Body",
			BP_R_ARM = "Right Arm",
			BP_L_ARM = "Left Arm",
			BP_R_HAND = "Right Hand",
			BP_L_HAND = "Left Hand",
			BP_R_LEG = "Right Leg",
			BP_L_LEG = "Left Leg",
			BP_R_FOOT = "Right Foot",
			BP_L_FOOT = "Left Foot"
		)
	for(var/part in labels)
		parts += list(list("id" = part, "label" = labels[part]))
	data["body_parts"] = parts
	var/canvas_width = mark ? mark.width : CUSTOM_MARKING_DEFAULT_WIDTH
	var/canvas_height = mark ? mark.height : CUSTOM_MARKING_DEFAULT_HEIGHT
	data["width"] = canvas_width
	data["height"] = canvas_height
	var/list/reference_grid = get_reference_grid()
	if(islist(reference_grid))
		data["reference"] = reference_grid
	var/list/reference_parts = get_reference_part_grids()
	if(islist(reference_parts) && reference_parts.len)
		data["reference_parts"] = reference_parts
	return data

// Provide the live editing payload for TGUI rendering
/datum/tgui_module/custom_marking_designer/tgui_data(mob/user)
	var/list/data = list()
	data["marking_id"] = mark?.id
	data["active_dir"] = direction_label(active_dir)
	data["active_dir_key"] = active_dir
	data["is_new"] = is_new_mark
	var/datum/custom_marking_session/session = get_active_session()
	var/list/grid = null
	if(session)
		grid = build_ui_grid_from_composite(session.get_grid())
	data["grid"] = grid
	data["diff"] = null
	data["diff_seq"] = diff_sequence
	var/list/layer_bundle = build_other_part_layers()
	if(islist(layer_bundle))
		var/list/other_layers = layer_bundle["layers"]
		if(islist(other_layers))
			for(var/_key in other_layers)
				data["body_part_layers"] = other_layers
				break
		var/list/layer_order = layer_bundle["order"]
		if(islist(layer_order) && layer_order.len)
			data["body_part_layer_order"] = layer_order.Copy()
	data["body_part_layer_revision"] = body_part_layer_revision
	data["brush_color"] = brush_color
	data["can_undo"] = session?.can_undo() || FALSE
	data["can_set_brush_color"] = TRUE
	data["limited"] = FALSE
	data["finalized"] = FALSE
	data["can_finalize"] = FALSE
	data["width"] = get_canvas_width()
	data["height"] = get_canvas_height()
	var/list/selected_parts = list()
	if(mark?.body_parts)
		for(var/part in mark.body_parts)
			selected_parts += part
	data["selected_body_parts"] = selected_parts
	data["active_body_part"] = active_body_part
	data["active_body_part_label"] = get_body_part_label(active_body_part)
	return data

// Create canvas grid
/datum/tgui_module/custom_marking_designer/proc/build_ui_grid_from_composite(list/raw_grid)
	if(!islist(raw_grid))
		return null
	var/w = get_canvas_width()
	var/h = get_canvas_height()
	if(w <= 0 || h <= 0)
		return null
	var/list/result = new/list(w)
	for(var/x in 1 to w)
		var/list/ui_column = new/list(h)
		var/list/raw_column = (raw_grid.len >= x) ? raw_grid[x] : null
		for(var/y in 1 to h)
			var/color = null
			if(islist(raw_column) && raw_column.len >= y)
				color = raw_column[y]
			if(!istext(color))
				color = "#00000000"
			var/ui_y = storage_to_canvas_y(y)
			if(ui_y)
				ui_column[ui_y] = color
		result[x] = ui_column
	return result

// Build frame layers
/datum/tgui_module/custom_marking_designer/proc/build_other_part_layers()
	if(!mark?.body_parts || !mark.body_parts.len)
		return null
	var/dir = active_dir || NORTH
	if(layer_cache_dirty || cached_body_part_dir != dir || !islist(cached_body_part_order))
		cached_body_part_layers = list()
		cached_body_part_order = list()
		for(var/part in mark.body_parts)
			cached_body_part_order += part
			var/datum/custom_marking_frame/frame = mark.get_frame(dir, part, FALSE)
			if(!frame)
				continue
			var/list/ui_grid = build_ui_grid_from_composite(frame.get_composite())
			if(islist(ui_grid))
				cached_body_part_layers[part] = ui_grid
		cached_body_part_dir = dir
		layer_cache_dirty = FALSE
		body_part_layer_revision++
	if(!islist(cached_body_part_layers))
		return null
	var/list/filtered = list()
	if(islist(cached_body_part_order))
		for(var/part in cached_body_part_order)
			if(part == active_body_part)
				continue
			var/list/ui_grid = cached_body_part_layers?[part]
			if(!islist(ui_grid))
				continue
			filtered[part] = ui_grid
	return list("layers" = filtered, "order" = cached_body_part_order?.Copy())

// Resolve the current canvas width with sensible defaults
/datum/tgui_module/custom_marking_designer/proc/get_canvas_width()
	return max(1, mark ? mark.width : CUSTOM_MARKING_DEFAULT_WIDTH)

// Resolve the current canvas height with sensible defaults
/datum/tgui_module/custom_marking_designer/proc/get_canvas_height()
	return max(1, mark ? mark.height : CUSTOM_MARKING_DEFAULT_HEIGHT)

// Translate storage grid coordinates into UI facing coordinates
/datum/tgui_module/custom_marking_designer/proc/storage_to_canvas_y(y)
	if(!isnum(y))
		return null
	var/h = get_canvas_height()
	var/result = h - y + 1
	if(result < 1 || result > h)
		return null
	return result

// Convert UI coordinates back into storage indices
/datum/tgui_module/custom_marking_designer/proc/canvas_to_storage_y(y)
	if(!isnum(y))
		return null
	var/h = get_canvas_height()
	var/result = h - y + 1
	if(result < 1 || result > h)
		return null
	return result

// Remove any overlays we added to the live character preview
/datum/tgui_module/custom_marking_designer/proc/clear_preview_overlay()
	if(!islist(preview_overlay_cache) || !preview_overlay_cache.len)
		return
	if(!prefs?.char_render_holders)
		preview_overlay_cache.Cut()
		return
	for(var/key in preview_overlay_cache)
		var/list/overlays = preview_overlay_cache[key]
		if(!LAZYLEN(overlays))
			continue
		var/obj/screen/setup_preview/holder = prefs.char_render_holders?[key]
		if(!holder)
			continue
		var/mutable_appearance/MA
		if(holder.appearance)
			MA = new /mutable_appearance(holder.appearance)
		else
			MA = new /mutable_appearance(holder)
		for(var/image/img in overlays)
			MA.overlays -= img
		holder.appearance = MA
	preview_overlay_cache.Cut()
	body_part_layer_revision++

// Overlay the current custom marking onto the existing preview holders
/datum/tgui_module/custom_marking_designer/proc/update_preview_overlay(force_style_refresh = FALSE)
	clear_preview_overlay()
	if(pending_pref_sync)
		return
	if(!prefs || !prefs.char_render_holders)
		return
	if(!mark)
		return
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory()
	if(!style)
		return
	if(force_style_refresh)
		style.invalidate_cache()
	style.regenerate_if_needed()
	if(!isicon(style.icon))
		return
	var/list/style_states = icon_states(style.icon)
	if(!islist(style_states))
		style_states = list()
	if(!preview_overlay_cache)
		preview_overlay_cache = list()
	var/list/mark_data = null
	if(islist(prefs.body_markings))
		mark_data = prefs.body_markings[style.name]
	var/global_mark_color = null
	if(islist(mark_data))
		global_mark_color = mark_data?["color"]
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/overlay_layer = BODY_LAYER + 2
	var/has_pixels = mark?.has_visible_pixels()
	for(var/dir in dirs)
		var/obj/screen/setup_preview/holder = prefs.char_render_holders?["[dir]"]
		if(!holder)
			continue
		var/appearance/holder_appearance = holder.appearance
		var/mutable_appearance/MA
		if(holder_appearance)
			MA = new /mutable_appearance(holder_appearance)
		else
			MA = new /mutable_appearance(holder)
		var/overlay_plane = MA.plane
		if(isnull(overlay_plane))
			overlay_plane = holder_appearance ? holder_appearance.plane : holder.plane
		if(isnull(overlay_plane))
			overlay_plane = PLANE_PLAYER_HUD
		MA.dir = dir
		holder.dir = dir
		var/list/new_overlays = list()
		if(islist(mark_data))
			for(var/part in mark_data)
				if(part == "color")
					continue
				var/list/details = mark_data[part]
				if(!islist(details) || !details["on"])
					continue
				var/state = part ? "[style.icon_state]-[part]" : "[style.icon_state]-generic"
				if(style_states.len && !(state in style_states))
					continue
				var/image/img = image(style.icon, state)
				if(!istype(img))
					continue
				img.dir = dir
				img.layer = overlay_layer
				img.plane = overlay_plane
				var/mark_color = islist(details) ? details["color"] : null
				if(!istext(mark_color))
					mark_color = global_mark_color
				if(istext(mark_color))
					img.color = mark_color
				new_overlays += img
		else if(has_pixels)
			var/default_state = "[style.icon_state]-generic"
			if(!(style_states.len) || (default_state in style_states))
				var/image/default_img = image(style.icon, default_state)
				if(istype(default_img))
					default_img.dir = dir
					default_img.layer = overlay_layer
					default_img.plane = overlay_plane
					if(istext(global_mark_color))
						default_img.color = global_mark_color
					new_overlays += default_img
		if(!LAZYLEN(new_overlays))
			var/placeholder_state = style.icon_state
			if(style_states.len && !(placeholder_state in style_states))
				placeholder_state = "[style.icon_state]-generic"
			var/image/placeholder = image(style.icon, placeholder_state)
			if(istype(placeholder))
				placeholder.dir = dir
				placeholder.layer = overlay_layer
				placeholder.plane = overlay_plane
				if(has_pixels && istext(global_mark_color))
					placeholder.color = global_mark_color
				else
					placeholder.color = "#00000000"
				new_overlays += placeholder
		if(LAZYLEN(new_overlays))
			preview_overlay_cache["[dir]"] = new_overlays
			MA.overlays |= new_overlays
		else
			preview_overlay_cache -= "[dir]"
		holder.appearance = MA
		holder.dir = dir

// Ensure the preferences list has an entry for the specified body part
/datum/tgui_module/custom_marking_designer/proc/ensure_pref_marking_entry(part)
	if(!prefs || !mark)
		return FALSE
	var/style_name = mark.get_style_name()
	if(!style_name)
		return FALSE
	LAZYINITLIST(prefs.body_markings)
	var/list/mark_entry = prefs.body_markings?[style_name]
	if(!islist(mark_entry))
		mark_entry = prefs.mass_edit_marking_list(style_name)
		prefs.body_markings[style_name] = mark_entry
	if(!islist(mark_entry))
		return FALSE
	var/default_color = mark_entry?["color"]
	if(!istext(default_color))
		default_color = "#FFFFFF"
	if(!islist(mark_entry[part]))
		mark_entry[part] = list("on" = TRUE, "color" = default_color)
	return TRUE

// Build a stable cache signature that incorporates sprite dimensions
/datum/tgui_module/custom_marking_designer/proc/get_reference_cache_signature(width, height)
	return "[get_reference_signature()]#[width]x[height]"

// Produce the cache key for a direction/dimension pairing
/datum/tgui_module/custom_marking_designer/proc/reference_payload_key(dir, width, height)
	if(!dir)
		dir = NORTH
	return "[dir]-[width]x[height]"

// Derive the mannequin cache key for building reference previews
/datum/tgui_module/custom_marking_designer/proc/get_reference_mannequin_key()
	var/key = prefs?.client_ckey || prefs?.client?.ckey
	if(!key)
		key = "custom_marking"
	return "[key]-markref"

// Fetch (or create) the mannequin used for reference baking
/datum/tgui_module/custom_marking_designer/proc/get_reference_mannequin()
	var/key = get_reference_mannequin_key()
	if(!key)
		return null
	return get_mannequin(key)

// Build a hashable payload describing the preview sprite context
/datum/tgui_module/custom_marking_designer/proc/get_reference_signature()
	if(!prefs)
		return ""
	var/list/payload = list(
		"species" = prefs.species,
		"custom_species" = prefs.custom_species,
		"custom_base" = prefs.custom_base,
		"gender" = prefs.biological_gender,
		"digitigrade" = prefs.digitigrade,
		"s_tone" = prefs.s_tone,
		"r_skin" = prefs.r_skin,
		"g_skin" = prefs.g_skin,
		"b_skin" = prefs.b_skin,
		"synth_color" = prefs.synth_color,
		"r_synth" = prefs.r_synth,
		"g_synth" = prefs.g_synth,
		"b_synth" = prefs.b_synth,
		"hair_style" = prefs.h_style,
		"hair_color" = list(prefs.r_hair, prefs.g_hair, prefs.b_hair),
		"hair_gradient" = list("style" = prefs.grad_style, "color" = list(prefs.r_grad, prefs.g_grad, prefs.b_grad)),
		"facial_style" = prefs.f_style,
		"facial_color" = list(prefs.r_facial, prefs.g_facial, prefs.b_facial),
		"tail_style" = prefs.tail_style,
		"tail_colors" = list(
			list(prefs.r_tail, prefs.g_tail, prefs.b_tail),
			list(prefs.r_tail2, prefs.g_tail2, prefs.b_tail2),
			list(prefs.r_tail3, prefs.g_tail3, prefs.b_tail3)
		),
		"wing_style" = prefs.wing_style,
		"wing_colors" = list(
			list(prefs.r_wing, prefs.g_wing, prefs.b_wing),
			list(prefs.r_wing2, prefs.g_wing2, prefs.b_wing2),
			list(prefs.r_wing3, prefs.g_wing3, prefs.b_wing3)
		),
		"ear_style" = prefs.ear_style,
		"ear_secondary_style" = prefs.ear_secondary_style,
		"ear_colors" = list(
			list(prefs.r_ears, prefs.g_ears, prefs.b_ears),
			list(prefs.r_ears2, prefs.g_ears2, prefs.b_ears2),
			list(prefs.r_ears3, prefs.g_ears3, prefs.b_ears3)
		)
	)
	if(islist(prefs.ear_secondary_colors))
		payload["ear_secondary_colors"] = prefs.ear_secondary_colors.Copy()
	if(islist(prefs.body_descriptors))
		payload["descriptors"] = prefs.body_descriptors.Copy()
	return json_encode(payload)



// Convert UI-oriented grids back into storage ordering
/datum/tgui_module/custom_marking_designer/proc/ui_reference_to_storage(list/ui_grid, width, height)
	if(!islist(ui_grid) || width <= 0 || height <= 0)
		return null
	var/list/storage = new/list(width)
	for(var/x in 1 to width)
		var/list/ui_column = ui_grid[x]
		if(!islist(ui_column))
			continue
		var/list/storage_column = new/list(height)
		for(var/storage_y in 1 to height)
			var/ui_y = storage_to_canvas_y(storage_y)
			if(!ui_y)
				continue
			storage_column[storage_y] = ui_column[ui_y]
		storage[x] = storage_column
	return storage


// Ensure cached reference payloads exist for each direction at the requested size
/datum/tgui_module/custom_marking_designer/proc/ensure_reference_payload_bundle(width, height)
	var/updated = FALSE
	if(!prefs)
		return updated
	if(width <= 0 || height <= 0)
		return updated
	if(pending_pref_sync)
		sync_preference_assignment()
	var/signature = get_reference_cache_signature(width, height)
	if(reference_cache_signature != signature || !islist(reference_payload_cache))
		reference_cache_signature = signature
		reference_payload_cache = list()
		if(prefs)
			prefs.custom_marking_reference_signature = reference_cache_signature
			prefs.custom_marking_reference_payload_cache = reference_payload_cache
		updated = TRUE
	else if(prefs)
		if(prefs.custom_marking_reference_payload_cache != reference_payload_cache)
			prefs.custom_marking_reference_payload_cache = reference_payload_cache
		if(prefs.custom_marking_reference_signature != reference_cache_signature)
			prefs.custom_marking_reference_signature = reference_cache_signature
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/list/missing = list()
	for(var/dir in dirs)
		var/key = reference_payload_key(dir, width, height)
		if(!islist(reference_payload_cache[key]))
			missing += dir
	if(!missing.len)
		return updated
	var/mob/living/carbon/human/dummy/mannequin/mannequin = get_reference_mannequin()
	if(!mannequin)
		return updated
	var/original_disable = mannequin.disable_vore_layers
	mannequin.disable_vore_layers = TRUE
	if(!mannequin.dna)
		mannequin.dna = new /datum/dna(null)
	if(reference_mannequin_signature != signature)
		copy_preferences_to_mannequin_without_marking(mannequin)
		reference_mannequin_signature = signature
		if(prefs)
			prefs.custom_marking_reference_mannequin_signature = reference_mannequin_signature
	mannequin.delete_inventory(TRUE)
	if(islist(mannequin.all_underwear))
		mannequin.all_underwear.Cut()
	if(islist(mannequin.hide_underwear))
		mannequin.hide_underwear.Cut()
	mannequin.update_underwear()
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			if(!istype(O))
				continue
			O.update_icon()
	mannequin.force_update_limbs()
	mannequin.update_icons_body()
	mannequin.update_mutations()
	mannequin.update_skin()
	mannequin.update_hair()
	mannequin.update_tail_showing()
	mannequin.update_wing_showing()
	mannequin.ImmediateOverlayUpdate()
	for(var/dir in dirs)
		if(!(dir in missing))
			continue
		mannequin.set_dir(dir)
		mannequin.ImmediateOverlayUpdate()
		var/list/payload = build_reference_payload_internal(mannequin, dir, width, height)
		if(islist(payload))
			reference_payload_cache[reference_payload_key(dir, width, height)] = payload
			updated = TRUE
	mannequin.disable_vore_layers = original_disable
	mannequin.delete_inventory(TRUE)
	mannequin.ImmediateOverlayUpdate()
	return updated

// Copy preferences to the mannequin while temporarily excluding the current custom marking
/datum/tgui_module/custom_marking_designer/proc/copy_preferences_to_mannequin_without_marking(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!prefs || !mannequin)
		return
	var/list/original_body_markings = prefs.body_markings
	var/list/temp_body_markings = null
	var/style_name = mark?.get_style_name()
	if(istext(style_name) && length(style_name) && islist(original_body_markings) && (style_name in original_body_markings))
		temp_body_markings = original_body_markings.Copy()
		temp_body_markings -= style_name
		prefs.body_markings = temp_body_markings
	prefs.copy_to(mannequin)
	if(temp_body_markings)
		prefs.body_markings = original_body_markings

// Construct the payload for a single direction using a prepared mannequin
/datum/tgui_module/custom_marking_designer/proc/build_reference_payload_internal(mob/living/carbon/human/dummy/mannequin/mannequin, dir, width, height)
	if(!mannequin)
		return null
	var/icon/ref_icon = icon(mannequin.icon, null, dir)
	var/list/overlay_icons = list()
	if(islist(mannequin.overlays_standing))
		for(var/i = 1 to mannequin.overlays_standing.len)
			collect_reference_overlays(overlay_icons, mannequin.overlays_standing[i], dir)
	for(var/icon/overlay_icon as anything in overlay_icons)
		if(!istype(overlay_icon, /icon))
			continue
		ref_icon.Blend(overlay_icon, ICON_OVERLAY)
	var/list/part_icons = list()
	var/normalized
	var/icon/directional_icon
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			if(!istype(O))
				continue
			normalized = null
			directional_icon = null
			if(istext(O.organ_tag) && length(O.organ_tag))
				normalized = lowertext(O.organ_tag)
			else if(isnum(O.organ_tag))
				normalized = "[O.organ_tag]"
			if(isnull(normalized))
				continue
			var/icon/organ_icon = O.get_icon()
			if(!isicon(organ_icon))
				continue
			directional_icon = icon(organ_icon, null, dir)
			if(!isicon(directional_icon))
				continue
			if(O.pixel_x || O.pixel_y)
				var/icon/shifted_icon = new /icon(directional_icon)
				if(O.pixel_x)
					if(O.pixel_x > 0)
						shifted_icon.Shift(EAST, O.pixel_x)
					else
						shifted_icon.Shift(WEST, -O.pixel_x)
				if(O.pixel_y)
					if(O.pixel_y > 0)
						shifted_icon.Shift(NORTH, O.pixel_y)
					else
						shifted_icon.Shift(SOUTH, -O.pixel_y)
				directional_icon = shifted_icon
			if(!directional_icon)
				continue
			part_icons[normalized] = directional_icon
	var/list/result_grid = icon_to_reference_grid(ref_icon, width, height)
	var/list/part_grids = list()
	if(islist(part_icons))
		for(var/part in part_icons)
			var/icon/part_icon = part_icons[part]
			if(!isicon(part_icon))
				continue
			var/list/part_grid = icon_to_reference_grid(part_icon, width, height)
			if(islist(part_grid))
				part_grids[part] = part_grid
	part_grids["generic"] = result_grid
	var/list/storage_parts = list()
	for(var/part_key in part_grids)
		var/list/part_ui = part_grids[part_key]
		var/list/storage_grid = ui_reference_to_storage(part_ui, width, height)
		if(islist(storage_grid))
			storage_parts[part_key] = storage_grid
	var/list/storage_generic = storage_parts?["generic"]
	return list(
		"grid" = result_grid,
		"parts" = part_grids,
		"storage" = storage_generic,
		"storage_parts" = storage_parts
	)

// Convert an icon into a 2D color grid for painting overlays
/datum/tgui_module/custom_marking_designer/proc/icon_to_reference_grid(icon/ref_icon, width, height)
	if(!isicon(ref_icon))
		return null
	var/icon_width = ref_icon.Width()
	var/icon_height = ref_icon.Height()
	if(icon_width <= 0 || icon_height <= 0)
		return null
	var/x_offset = round((icon_width - width) / 2)
	var/y_offset = max(0, icon_height - height)
	var/list/result = new/list(width)
	for(var/x in 1 to width)
		var/list/column = new/list(height)
		for(var/y in 1 to height)
			var/ui_y = storage_to_canvas_y(y)
			if(!ui_y)
				continue
			var/source_x = x + x_offset
			var/source_y = y + y_offset
			if(source_x < 1 || source_x > icon_width)
				continue
			if(source_y < 1 || source_y > icon_height)
				continue
			var/pixel = ref_icon.GetPixel(source_x, source_y)
			if(istext(pixel) && length(pixel))
				column[ui_y] = lowertext(pixel)
		result[x] = column
	return result

// Fetch the cached base overlay grid for the active direction
/datum/tgui_module/custom_marking_designer/proc/get_reference_grid()
	if(!prefs)
		return null
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	if(width <= 0 || height <= 0)
		return null
	ensure_reference_payload_bundle(width, height)
	var/dir = active_dir || NORTH
	var/list/payload = reference_payload_cache?[reference_payload_key(dir, width, height)]
	if(!islist(payload))
		return null
	var/list/grid = payload["grid"]
	if(!islist(grid))
		return null
	return grid

// Provide part-specific overlays for the UI reference menu
/datum/tgui_module/custom_marking_designer/proc/get_reference_part_grids()
	if(!prefs)
		return null
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	if(width <= 0 || height <= 0)
		return null
	ensure_reference_payload_bundle(width, height)
	var/dir = active_dir || NORTH
	var/list/payload = reference_payload_cache?[reference_payload_key(dir, width, height)]
	if(!islist(payload))
		return null
	var/list/parts = payload["parts"]
	if(!islist(parts) || !parts.len)
		return null
	return parts


// Recursively gather icons/images that contribute to the reference sprite
/datum/tgui_module/custom_marking_designer/proc/collect_reference_overlays(list/accum, datum/entry, dir)
	if(!entry)
		return
	if(islist(entry))
		for(var/element in entry)
			collect_reference_overlays(accum, element, dir)
		return
	if(isicon(entry))
		var/icon/icon_copy = icon(entry, null, dir)
		accum += new/icon(icon_copy)
		return
	if(istype(entry, /image))
		var/image/img = entry
		var/icon/overlay_icon = reference_icon_from_image(img, dir)
		if(!overlay_icon)
			return
		overlay_icon = shift_icon_for_reference(overlay_icon, img.pixel_x, img.pixel_y)
		accum += overlay_icon
		return

// Retrieve storage-space overlays and cache them by direction
/datum/tgui_module/custom_marking_designer/proc/get_reference_storage_grid(dir_override = null)
	if(!prefs)
		return null
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	if(width <= 0 || height <= 0)
		return null
	var/dir = dir_override
	if(isnull(dir))
		dir = active_dir || NORTH
	ensure_reference_payload_bundle(width, height)
	var/list/payload = reference_payload_cache?[reference_payload_key(dir, width, height)]
	if(!islist(payload))
		return null
	var/list/storage = payload["storage"]
	if(islist(storage))
		return storage
	var/list/ui_grid = payload["grid"]
	if(!islist(ui_grid))
		return null
	storage = ui_reference_to_storage(ui_grid, width, height)
	if(islist(storage))
		payload["storage"] = storage
	return storage


// Cache per-body-part storage grids for the current direction
/datum/tgui_module/custom_marking_designer/proc/get_reference_storage_part_grids(dir_override = null)
	if(!prefs)
		return null
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	if(width <= 0 || height <= 0)
		return null
	var/dir = dir_override
	if(isnull(dir))
		dir = active_dir || NORTH
	ensure_reference_payload_bundle(width, height)
	var/list/payload = reference_payload_cache?[reference_payload_key(dir, width, height)]
	if(!islist(payload))
		return null
	var/list/storage_parts = payload["storage_parts"]
	if(islist(storage_parts) && storage_parts.len)
		return storage_parts
	var/list/parts_ui = payload["parts"]
	if(!islist(parts_ui))
		return null
	storage_parts = list()
	for(var/part_key in parts_ui)
		var/list/part_grid = parts_ui[part_key]
		var/list/storage_grid = ui_reference_to_storage(part_grid, width, height)
		if(islist(storage_grid))
			storage_parts[part_key] = storage_grid
	payload["storage_parts"] = storage_parts
	return storage_parts


// Safely convert an image overlay into an icon for caching
/datum/tgui_module/custom_marking_designer/proc/reference_icon_from_image(image/source, dir)
	if(!source)
		return null
	if(source.alpha == 0)
		return null
	var/icon/base_icon
	var/icon_path = source.icon
	var/icon_state = source.icon_state
	var/render_dir = dir
	if(!render_dir)
		render_dir = source.dir || SOUTH
	else if(source.dir && (source.dir & (source.dir - 1)) && !(render_dir & (render_dir - 1)))
		render_dir = source.dir
	if(icon_path)
		if(isicon(icon_path))
			base_icon = icon(icon_path, null, render_dir)
		else
			base_icon = icon(icon_path, icon_state, render_dir)
	else
		base_icon = icon('icons/effects/effects.dmi', "nothing")
	if(source.alpha && source.alpha < 255)
		base_icon.Blend(rgb(255, 255, 255, source.alpha), ICON_MULTIPLY)
	if(istext(source.color))
		base_icon.Blend(source.color, ICON_MULTIPLY)
	else if(islist(source.color) && length(source.color) >= 20)
		base_icon.MapColors(arglist(source.color))
	if(islist(source.overlays))
		for(var/image/sub_overlay in source.overlays)
			var/icon/sub_icon = reference_icon_from_image(sub_overlay, dir)
			if(!sub_icon)
				continue
			sub_icon = shift_icon_for_reference(sub_icon, sub_overlay.pixel_x, sub_overlay.pixel_y)
			base_icon.Blend(sub_icon, ICON_OVERLAY)
	return base_icon

// Apply BYOND pixel offsets to a cloned icon for reference usage
/datum/tgui_module/custom_marking_designer/proc/shift_icon_for_reference(icon/source, shift_x, shift_y)
	if(!istype(source, /icon))
		return null
	if(!shift_x && !shift_y)
		return new/icon(source)
	var/icon/result = new/icon(source)
	if(shift_x)
		if(shift_x > 0)
			result.Shift(EAST, shift_x)
		else
			result.Shift(WEST, -shift_x)
	if(shift_y)
		if(shift_y > 0)
			result.Shift(NORTH, shift_y)
		else
			result.Shift(SOUTH, -shift_y)
	return result

// Resolve display strings for body part selections
/datum/tgui_module/custom_marking_designer/proc/get_body_part_label(part)
	if(!part)
		return "Generic"
	var/list/labels = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(labels && (part in labels))
		return labels[part]
	return capitalize(replacetext(part, "_", " "))

// Handle all interactive actions triggered from the TGUI frontend
/datum/tgui_module/custom_marking_designer/tgui_act(action, params)
	if(..())
		return TRUE
	var/handled = TRUE
	if(action == "set_dir")
		var/new_dir = text2num(params["dir"])
		if(new_dir && new_dir != active_dir)
			var/canvas_width = get_canvas_width()
			var/canvas_height = get_canvas_height()
			var/refs_changed_dir = ensure_reference_payload_bundle(canvas_width, canvas_height)
			var/datum/custom_marking_session/current_session = get_active_session()
			var/committed = commit_session(current_session)
			active_dir = new_dir
			layer_cache_dirty = TRUE
			var/datum/custom_marking_session/next_session = get_active_session()
			apply_reference_overlay(next_session, active_dir, active_body_part)
			var/mob/user_dir = usr
			var/pushed_refs_dir = refs_changed_dir
			if(user_dir)
				pushed_refs_dir = push_reference_static_data(user_dir) || pushed_refs_dir
			update_preview_overlay()
			if(!committed)
				refresh_preview_icon()
			if(committed)
				save_marking_changes(TRUE, TRUE)
			else if(mark_dirty)
				if(!maybe_auto_save())
					save_marking_changes(TRUE, TRUE)
			else if(pushed_refs_dir)
				update_preview_overlay()
	else if(action == "set_brush_color")
		var/new_color = params["color"]
		if(istext(new_color))
			brush_color = new_color
	else if(action == "paint")
		handled = handle_canvas_paint(params)
	else if(action == "line")
		handled = handle_canvas_line(params)
	else if(action == "fill")
		handled = handle_canvas_fill(params)
	else if(action == "commit_stroke")
		var/datum/custom_marking_session/session = get_active_session()
		if(session)
			if(commit_session(session))
				refresh_preview_icon()
	else if(action == "pick_color_dialog")
		var/default_color = brush_color || "#FFFFFF"
		var/new_color = input(usr, "Select a new brush color:", "Brush Color", default_color) as null|color
		if(new_color)
			brush_color = new_color
		handled = TRUE
	else if(action == "pick_color")
		var/new_hex = params["color"]
		if(istext(new_hex) && length(new_hex))
			brush_color = new_hex
		handled = TRUE
	else if(action == "undo")
		var/datum/custom_marking_session/session = get_active_session()
		if(session?.undo())
			mark_dirty = TRUE
			layer_cache_dirty = TRUE
			refresh_preview_icon()
	else if(action == "clear_confirm")
		if(tgui_alert(usr, "Clear the entire marking? This cannot be undone.", "Confirm Clear", list("Yes", "No")) != "Yes")
			return TRUE
		var/datum/custom_marking_session/session = get_active_session()
		if(session?.clear())
			mark_dirty = TRUE
			layer_cache_dirty = TRUE
			refresh_preview_icon()
	else if(action == "clear")
		var/datum/custom_marking_session/session = get_active_session()
		if(session?.clear())
			mark_dirty = TRUE
			layer_cache_dirty = TRUE
			refresh_preview_icon()
	else if(action == "eyedropper")
		var/datum/custom_marking_session/session = get_active_session()
		if(session)
			var/x = text2num(params["x"])
			var/y = canvas_to_storage_y(text2num(params["y"]))
			var/color = session.current_color_at(x, y)
			if(!istext(color))
				var/list/reference_grid = get_reference_grid()
				if(islist(reference_grid))
					var/list/column = reference_grid[x]
					if(islist(column))
						var/ui_y = storage_to_canvas_y(y)
						if(ui_y)
							color = column[ui_y]
			if(istext(color))
				brush_color = color
	else if(action == "set_body_part" || action == "toggle_body_part")
		var/part = params["part"]
		if(isnull(part))
			return TRUE
		set_active_body_part(part)
		set_active_body_part(part, TRUE)
	else if(action == "discard_changes")
		discard_changes()
	else if(action == "delete_marking")
		delete_marking()
	else if(action == "export_png")
		handled = export_active_frame_png(usr)
	else if(action == "export_dmi")
		handled = export_marking_dmi(usr)
	else if(action == "import_png")
		handled = import_active_frame_png(usr)
	else if(action == "import_dmi")
		handled = import_marking_dmi(usr)
	else if(action == "save")
		save_marking_changes(TRUE, TRUE)
	else if(action == "save_and_close")
		SStgui.close_uis(src)
	else
		handled = FALSE
	if(!handled)
		return FALSE
	var/defer_global_update = (action == "paint" || action == "line" || action == "fill")
	if(defer_global_update)
		var/raw_stroke = params["stroke"]
		if(!isnull(raw_stroke) && length("[raw_stroke]"))
			return FALSE
	SStgui.update_uis(src)
	return FALSE

// Save the active frame as a PNG download for the player
/datum/tgui_module/custom_marking_designer/proc/export_active_frame_png(mob/user)
	if(!user || !mark)
		return FALSE
	var/datum/custom_marking_session/session = get_active_session()
	if(session && session.commit_pending())
		mark_dirty = TRUE
	var/list/frame_info = mark.resolve_frame_components(active_dir, active_body_part)
	var/export_dir = frame_info?["dir"]
	var/export_part = frame_info?["part"]
	var/datum/custom_marking_frame/frame = mark.get_frame(export_dir, export_part)
	if(!frame)
		return FALSE
	var/list/grid = frame.get_composite()
	if(!islist(grid))
		return FALSE
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	var/icon/base_icon = icon('icons/mob/human_races/markings.dmi', "blank")
	base_icon.Scale(width, height)
	var/has_pixels = FALSE
	for(var/x in 1 to width)
		if(!islist(grid[x]))
			continue
		for(var/y in 1 to height)
			var/color = grid[x][y]
			if(!istext(color))
				continue
			var/hex = cm_normalize_hex(color)
			if(!hex)
				continue
			base_icon.DrawBox(hex, x, y, x, y)
			has_pixels = TRUE
	if(!has_pixels)
		to_chat(user, span_warning("No painted pixels found for this frame; exported image will be blank."))
	var/icon/export_icon = icon()
	export_icon.Insert(new/icon(base_icon), "export", SOUTH)
	export_icon = icon(export_icon, "export", SOUTH)
	var/base_name = mark?.name || "custom_marking"
	base_name = sanitize_filename(lowertext(replacetext(base_name, " ", "_")))
	if(!length(base_name))
		base_name = "custom_marking"
	var/part_token = export_part && export_part != "generic" ? export_part : "generic"
	part_token = sanitize_filename(replacetext(lowertext(part_token), " ", "_"))
	var/dir_label = lowertext(direction_label(export_dir))
	dir_label = sanitize_filename(replacetext(dir_label, " ", ""))
	var/file_name = "[base_name]_[part_token]_[dir_label].png"
	var/success = FALSE
	if(user.client)
		user << ftp(export_icon, file_name)
		success = TRUE
	if(success)
		to_chat(user, span_notice("Preparing download for [file_name]..."))
	else
		to_chat(user, span_warning("Could not start download; client connection missing."))
	return TRUE

// Package the entire marking into a DMI archive for download
/datum/tgui_module/custom_marking_designer/proc/export_marking_dmi(mob/user)
	if(!user || !mark)
		return FALSE
	commit_all_sessions()
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory()
	if(!style)
		return FALSE
	style.invalidate_cache()
	var/icon/raw_icon = style.build_composite_icon("export")
	if(!raw_icon)
		return FALSE
	var/icon/export_icon = icon()
	var/list/frames = mark.frames
	var/has_state = FALSE
	if(islist(frames))
		for(var/key in frames)
			var/list/info = mark.resolve_frame_components(key, null)
			if(!islist(info))
				continue
			var/state_dir = info["dir"]
			if(!state_dir)
				state_dir = SOUTH
			var/state_part = info["part"]
			if(!istext(state_part) || !length(state_part))
				state_part = "generic"
			var/state_name = "export-[state_part]"
			var/icon/state_icon = icon(raw_icon, state_name, state_dir)
			if(!isicon(state_icon))
				continue
			export_icon.Insert(new/icon(state_icon), state_name, state_dir)
			has_state = TRUE
	if(!has_state)
		to_chat(user, span_warning("No custom marking states found to export."))
		return FALSE
	var/base_name = mark?.name || "custom_marking"
	base_name = sanitize_filename(lowertext(replacetext(base_name, " ", "_")))
	if(!length(base_name))
		base_name = "custom_marking"
	var/file_name = "[base_name]_full.dmi"
	var/success = FALSE
	if(user.client)
		user << ftp(export_icon, file_name)
		success = TRUE
	if(success)
		to_chat(user, span_notice("Preparing download for [file_name]..."))
	else
		to_chat(user, span_warning("Could not start download; client connection missing."))
	return TRUE

// Allow users to import a PNG as the current frame artwork
/datum/tgui_module/custom_marking_designer/proc/import_active_frame_png(mob/user)
	if(!user || !mark)
		return FALSE
	commit_all_sessions()
	var/selection = input(user, "Select a PNG to import for this body part and direction.", "Import Custom Marking PNG") as null|file
	if(!selection)
		return TRUE
	var/icon/source_icon
	try
		source_icon = icon(selection)
	catch
		source_icon = null
	if(!isicon(source_icon))
		to_chat(user, span_warning("That file could not be read as an image."))
		return TRUE
	var/icon/canvas = new/icon(source_icon)
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	if(width <= 0 || height <= 0)
		to_chat(user, span_warning("Invalid canvas dimensions for this marking."))
		return TRUE
	if(canvas.Width() != width || canvas.Height() != height)
		canvas.Scale(width, height)
	var/datum/custom_marking_session/session = get_active_session()
	if(session && session.commit_pending())
		mark_dirty = TRUE
	var/list/frame_info = mark.resolve_frame_components(active_dir, active_body_part)
	var/import_dir = frame_info?["dir"]
	var/import_part = frame_info?["part"]
	var/datum/custom_marking_frame/frame = mark.ensure_frame(import_dir, import_part)
	if(!frame)
		return FALSE
	frame.reset()
	var/list/layer = frame.ensure_layer(1)
	var/has_pixels = FALSE
	for(var/x in 1 to width)
		for(var/y in 1 to height)
			var/storage_y = y
			if(storage_y < 1 || storage_y > height)
				continue
			var/pixel = canvas.GetPixel(x, y)
			var/value = null
			if(istext(pixel) && length(pixel))
				var/alpha = 255
				if(length(pixel) >= 9)
					var/alpha_hex = copytext(pixel, 8, 10)
					if(length(alpha_hex))
						alpha = hex2num(alpha_hex)
				if(alpha > 0)
					var/hex = cm_normalize_hex(pixel)
					if(hex)
						value = hex
			layer[x][storage_y] = value
			if(!isnull(value))
				has_pixels = TRUE
	frame.invalidate()
	mark.invalidate_bake()
	register_custom_marking_style(mark)
	sync_preference_assignment()
	var/session_key_value = session_key(import_dir, import_part)
	if(islist(sessions))
		sessions -= session_key_value
	refresh_preview_icon()
	if(!has_pixels)
		to_chat(user, span_warning("PNG import completed, but no opaque pixels were found."))
	else
		to_chat(user, span_notice("PNG import applied to current direction and body part."))
	initial_snapshot = mark.to_save()
	mark_dirty = FALSE
	return TRUE

// Import a multi-frame DMI into the current custom marking
/datum/tgui_module/custom_marking_designer/proc/import_marking_dmi(mob/user)
	if(!user || !mark)
		return FALSE
	commit_all_sessions()
	var/selection = input(user, "Select a DMI file to import for this marking.", "Import Custom Marking DMI") as null|file
	if(!selection)
		return TRUE
	var/icon/source_icon
	try
		source_icon = icon(selection)
	catch
		source_icon = null
	if(!isicon(source_icon))
		to_chat(user, span_warning("That file could not be read as a DMI icon."))
		return TRUE
	var/icon/raw_icon = new/icon(source_icon)
	var/list/state_names = icon_states(raw_icon)
	if(!islist(state_names) || !state_names.len)
		to_chat(user, span_warning("The selected DMI did not contain any icon states."))
		return TRUE
	var/list/new_frames = list()
	var/list/imported_parts = list()
	var/import_width = 0
	var/import_height = 0
	for(var/state_name in state_names)
		if(!istext(state_name))
			continue
		var/lower = lowertext(state_name)
		if(!dd_hasprefix(lower, "export-"))
			continue
		var/part_suffix = copytext(lower, 8)
		if(!length(part_suffix))
			part_suffix = "generic"
		var/normalized_part = mark.normalize_part(part_suffix, "generic")
		if(isnull(normalized_part))
			normalized_part = "generic"
		if(normalized_part != "generic" && !(normalized_part in imported_parts))
			imported_parts += normalized_part
		for(var/dir in list(NORTH, SOUTH, EAST, WEST))
			var/icon/state_icon = icon(raw_icon, state_name, dir)
			if(!isicon(state_icon))
				continue
			if(!import_width || !import_height)
				import_width = state_icon.Width()
				import_height = state_icon.Height()
			if(import_width <= 0 || import_height <= 0)
				continue
			if(state_icon.Width() != import_width || state_icon.Height() != import_height)
				state_icon.Scale(import_width, import_height)
			var/datum/custom_marking_frame/frame = new(import_width, import_height)
			var/list/layer = frame.ensure_layer(1)
			for(var/x in 1 to import_width)
				for(var/y in 1 to import_height)
					var/storage_y = y
					if(storage_y < 1 || storage_y > import_height)
						continue
					var/pixel = state_icon.GetPixel(x, y)
					var/value = null
					if(istext(pixel) && length(pixel))
						var/alpha = 255
						if(length(pixel) >= 9)
							var/alpha_hex = copytext(pixel, 8, 10)
							if(length(alpha_hex))
								alpha = hex2num(alpha_hex)
						if(alpha > 0)
							var/hex = cm_normalize_hex(pixel)
							if(hex)
								value = hex
					layer[x][storage_y] = value
			frame.invalidate()
			var/key = mark.frame_key(dir, normalized_part)
			new_frames[key] = frame
	if(!new_frames.len)
		to_chat(user, span_warning("No states prefixed with 'export-' were found in that DMI."))
		return TRUE
	if(import_width > 0 && import_height > 0)
		mark.width = import_width
		mark.height = import_height
	mark.frames = new_frames
	mark.invalidate_bake()
	if(imported_parts.len)
		mark.body_parts = imported_parts.Copy()
	if(islist(mark.body_parts) && mark.body_parts.len)
		if(!active_body_part || !(active_body_part in mark.body_parts))
			active_body_part = mark.body_parts[1]
	sessions = list()
	register_custom_marking_style(mark)
	sync_preference_assignment()
	refresh_preview_icon()
	var/datum/custom_marking_session/new_session = get_active_session()
	apply_reference_overlay(new_session, active_dir, active_body_part)
	push_reference_static_data(user)
	initial_snapshot = mark.to_save()
	mark_dirty = FALSE
	to_chat(user, span_notice("Custom marking updated from imported DMI."))
	return TRUE

// Process freehand brush strokes from the client canvas
/datum/tgui_module/custom_marking_designer/proc/handle_canvas_paint(params)
	var/datum/custom_marking_session/session = get_active_session()
	if(!session)
		return FALSE
	var/stroke = params["stroke"]
	var/mode = lowertext(params["blend"])
	var/strength = text2num(params["strength"])
	if(!isnum(strength))
		strength = (mode == "analog") ? 0.5 : 1
	else
		strength = CLAMP(strength, 0, 1)
	var/color = brush_color
	if(mode == "erase")
		color = null
	session.prepare_stroke(stroke, color, mode, strength)
	var/x = text2num(params["x"])
	var/y = canvas_to_storage_y(text2num(params["y"]))
	var/size = max(1, round(text2num(params["size"]) || 1))
	if(!isnum(x) || !isnum(y))
		return FALSE
	if(size <= 1)
		session.apply_point(x, y, color, mode, strength)
	else
		session.draw_brush(x, y, size, color, mode, strength)
	push_live_diff(session, stroke)
	if(!params["stroke"])
		if(commit_session(session))
			refresh_preview_icon()
	return TRUE

// Render straight lines between two canvas points
/datum/tgui_module/custom_marking_designer/proc/handle_canvas_line(params)
	var/datum/custom_marking_session/session = get_active_session()
	if(!session)
		return FALSE
	var/stroke = params["stroke"]
	var/mode = lowertext(params["blend"])
	var/strength = text2num(params["strength"])
	if(!isnum(strength))
		strength = (mode == "analog") ? 0.5 : 1
	else
		strength = CLAMP(strength, 0, 1)
	var/color = brush_color
	if(mode == "erase")
		color = null
	session.prepare_stroke(stroke, color, mode, strength)
	var/x1 = text2num(params["x1"])
	var/y1 = canvas_to_storage_y(text2num(params["y1"]))
	var/x2 = text2num(params["x2"])
	var/y2 = canvas_to_storage_y(text2num(params["y2"]))
	var/size = max(1, round(text2num(params["size"]) || 1))
	if(!(isnum(x1) && isnum(y1) && isnum(x2) && isnum(y2)))
		return FALSE
	session.draw_line(x1, y1, x2, y2, size, color, mode, strength)
	push_live_diff(session, stroke)
	var/stroke_id = text2num(stroke)
	if(!stroke_id)
		if(commit_session(session))
			refresh_preview_icon()
	return TRUE

// Execute fill operations originating from the canvas UI
/datum/tgui_module/custom_marking_designer/proc/handle_canvas_fill(params)
	var/datum/custom_marking_session/session = get_active_session()
	if(!session)
		return FALSE
	var/mode = lowertext(params["blend"])
	var/strength = text2num(params["strength"])
	if(!isnum(strength))
		strength = (mode == "analog") ? 0.5 : 1
	else
		strength = CLAMP(strength, 0, 1)
	var/color = brush_color
	if(mode == "erase")
		color = null
	session.prepare_stroke(null, color, mode, strength)
	var/x = text2num(params["x"])
	var/y = canvas_to_storage_y(text2num(params["y"]))
	if(!(isnum(x) && isnum(y)))
		return FALSE
	session.fill(x, y, color, mode, strength)
	push_live_diff(session, null)
	if(commit_session(session))
		refresh_preview_icon()
	return TRUE

// Send incremental pixel updates to the active painter
/datum/tgui_module/custom_marking_designer/proc/push_live_diff(datum/custom_marking_session/session, stroke_id)
	if(!session)
		return
	var/list/raw = session.pull_live_diff()
	if(!islist(raw) || !raw.len)
		return
	var/list/diff_payload = list()
	var/width = get_canvas_width()
	var/height = get_canvas_height()
	for(var/list/change in raw)
		var/dx = change["x"]
		var/dy = change["y"]
		if(!isnum(dx) || !isnum(dy))
			continue
		var/ui_y = storage_to_canvas_y(dy)
		if(!isnum(ui_y))
			continue
		var/new_value = change["color"]
		if(!istext(new_value))
			new_value = "#00000000"
		else
			var/hex = cm_normalize_hex(new_value)
			if(hex)
				new_value = hex
			else
				new_value = "#00000000"
		diff_payload += list(list("x" = dx, "y" = ui_y, "color" = new_value))
	if(!diff_payload.len)
		return
	diff_sequence++
	var/list/custom = list("diff" = diff_payload, "diff_seq" = diff_sequence, "width" = width, "height" = height)
	if(stroke_id)
		custom["stroke"] = stroke_id
	var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
	if(active_ui)
		active_ui.send_update(custom)

// Roll back edits to the last committed snapshot or delete new marks

/datum/tgui_module/custom_marking_designer/proc/discard_changes()
	if(!mark)
		return
	if(is_new_mark)
		if(prefs)
			prefs.custom_markings -= mark.id
		unregister_custom_marking_style(mark.id)
		GLOB.custom_markings_by_id -= mark.id
		mark = null
		original_style_name = null
		sessions = list()
		layer_cache_dirty = TRUE
		cached_body_part_layers = null
		cached_body_part_order = null
		cached_body_part_dir = null
		SStgui.close_uis(src)
		return
	if(initial_snapshot)
		mark.from_save(initial_snapshot)
	register_custom_marking_style(mark)
	sessions = list()
	is_new_mark = FALSE
	active_body_part = default_body_part()
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()
	pending_pref_sync = FALSE
	clear_preview_overlay()
	reference_mannequin_signature = null
	if(prefs)
		prefs.custom_marking_reference_mannequin_signature = null
	mark_dirty = FALSE
	layer_cache_dirty = TRUE
	cached_body_part_layers = null
	cached_body_part_order = null
	cached_body_part_dir = null

// Permanently remove the custom marking from preferences
/datum/tgui_module/custom_marking_designer/proc/delete_marking()
	if(!mark)
		return
	var/id = mark.id
	var/delegated = FALSE
	if(prefs && id)
		prefs.remove_custom_marking(id)
		delegated = TRUE
		if(QDELETED(src))
			return
	if(!delegated && id)
		unregister_custom_marking_style(id)
		GLOB.custom_markings_by_id -= id
	mark = null
	sessions = list()
	SStgui.close_uis(src)
	active_body_part = null
	original_mark_id = null
	original_style_name = null
	pending_pref_sync = FALSE
	clear_preview_overlay()
	reference_mannequin_signature = null
	if(prefs)
		prefs.custom_marking_reference_mannequin_signature = null
	mark_dirty = FALSE
	layer_cache_dirty = TRUE
	cached_body_part_layers = null
	cached_body_part_order = null
	cached_body_part_dir = null

// Register finished edits and refresh preference assignments
/datum/tgui_module/custom_marking_designer/proc/finalize_changes(force_save)
	if(!mark)
		return
	mark.register()
	initial_snapshot = mark.to_save()
	is_new_mark = FALSE
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()
	if(pending_pref_sync)
		sync_preference_assignment()
	else
		refresh_preview_icon()

#undef CUSTOM_MARKING_DEFAULT_WIDTH
#undef CUSTOM_MARKING_DEFAULT_HEIGHT
