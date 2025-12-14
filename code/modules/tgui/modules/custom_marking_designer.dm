////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Refactor moving most of the work to TGUI and adding new options to overlay and replace parts //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: New body marking selection tab added //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define CUSTOM_MARKING_DEFAULT_WIDTH 32
#define CUSTOM_MARKING_DEFAULT_HEIGHT 32

#ifndef CUSTOM_MARKING_CANVAS_MAX_WIDTH
#define CUSTOM_MARKING_CANVAS_MAX_WIDTH 64
#endif
#ifndef CUSTOM_MARKING_CANVAS_MAX_HEIGHT
#define CUSTOM_MARKING_CANVAS_MAX_HEIGHT 64
#endif

#define BODY_MARKING_CHUNK_PENDING -7
#define BODY_MARKING_SELECTION_LIMIT 40

#ifndef CUSTOM_MARKING_CHECK_TICK
#define CUSTOM_MARKING_CHECK_TICK custom_marking_yield_heartbeat()
#define CUSTOM_MARKING_CHECK_TICK_DEFINED_IN_DESIGNER
#endif

// Shared cache for the global body marking definitions payload (Lira, December 2025)
var/global/list/custom_marking_body_definition_cache = null

// Helper used to build the cache (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/cache_builder/New()
	prefs = new /datum/preferences
	state_session_token = "cache"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	return

// Build body marking definition cache (Lira, December 2025)
/proc/build_body_marking_definition_cache()
	if(islist(custom_marking_body_definition_cache))
		return custom_marking_body_definition_cache
	if(!islist(body_marking_styles_list) || !body_marking_styles_list.len)
		return null
	var/datum/tgui_module/custom_marking_designer/cache_builder/helper = new
	custom_marking_body_definition_cache = helper.build_body_marking_definitions()
	return custom_marking_body_definition_cache

// TGUI module for editing and previewing custom markings
/datum/tgui_module/custom_marking_designer
	name = "Marking Designer"
	tgui_id = "CustomMarkingDesigner"

	var/datum/preferences/prefs // Owning preferences datum
	var/datum/custom_marking/mark // Marking being edited
	var/initial_tab = "custom" // Which tab to show on open
	var/active_tab = "custom" // Which tab the client is currently viewing
	var/last_preview_bundle_revision = 0 // Tracks latest preview revision sent with preview_sources
	var/allow_custom_tab = TRUE // Gate custom tab when no mark exists
	var/active_dir = NORTH // Active direction (NORTH/SOUTH/EAST/WEST)
	var/active_body_part // Currently active body part for editing
	var/is_new_mark = FALSE // Track whether this marking was created during this editor session
	var/list/initial_snapshot // Snapshot of serialized data for reverting
	var/list/direction_order // Direction order for UI
	var/list/sessions // Cached painting sessions by direction/part
	var/original_mark_id // Original ids/styles when the editor opened
	var/original_style_name // Original style name when the editor opened
	var/diff_sequence = 0 // Tracks incremental ids for live diffs
	var/session_token // Tokens for session/state coherence with the client
	var/state_session_token // Token for syncing local UI state
	var/body_part_layer_revision = 0 // Revisions for overlay layers
	var/preview_revision = 1 // Revisions for preview bundles
	var/body_preview_revision = 1 // Revisions for stripped body preview bundles
	var/mark_dirty = FALSE // Dirty flag for pending save
	var/body_markings_refresh_pending = FALSE // Defer body preview rebuild until body tab is opened
	var/list/reference_payload_cache // Cached mannequin payloads
	var/reference_cache_signature // Signature key for reference payload cache
	var/reference_mannequin_signature // Signature key for mannequin state cache
	var/reference_build_in_progress = FALSE // Prevent overlapping mannequin rebuilds
	var/list/reference_pending_request // Latest pending mannequin rebuild request
	var/list/body_reference_payload_cache // Cached stripped mannequin payloads for body tab
	var/body_reference_cache_signature // Signature key for stripped reference cache
	var/body_reference_mannequin_signature // Signature key for stripped mannequin state cache
	var/body_reference_build_in_progress = FALSE // Prevent overlapping stripped mannequin rebuilds
	var/list/body_reference_pending_request // Latest pending stripped mannequin rebuild request
	var/reference_asset_token_counter = 0 // Asset token generator
	var/list/icon_shift_map // Per-icon shift tracking
	var/body_marking_chunk_token // Active chunk token for body markings tab saves
	var/list/body_marking_chunk_buffer // Accumulator for chunked body marking payloads
	var/list/body_marking_chunk_order // Accumulator for body marking order across chunks
	var/body_marking_chunk_expected = 0 // Expected chunk count for current body marking save
	var/body_marking_chunk_received = 0 // Received chunk counter for current body marking save

// Broadcast a partial update about reference build state without forcing tgui_data  (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/broadcast_reference_build_state(state)
	var/key = "[REF(src)]"
	var/list/open_list = SStgui.open_uis_by_src?[key]
	if(!islist(open_list) || !open_list.len)
		return
	for(var/datum/tgui/ui in open_list)
		if(!ui || ui.src_object != src || !ui.user)
			continue
		ui.send_update(list("reference_build_in_progress" = !!state), TRUE)

// Use the standard always-open TGUI state for this editor
/datum/tgui_module/custom_marking_designer/tgui_state(mob/user)
	return GLOB.tgui_always_state

// Disable auto-updates; client drives refresh cadence
/datum/tgui_module/custom_marking_designer/tgui_interact(mob/user, datum/tgui/ui = null, datum/tgui/parent_ui = null)
	..(user, ui, parent_ui)
	var/datum/tgui/instanced_ui = SStgui.get_open_ui(user, src)
	if(instanced_ui)
		instanced_ui.set_autoupdate(FALSE)
	if(prefs)
		prefs.close_custom_marking_designer_loading()
	return instanced_ui

// Finalize edits and refresh previews when the UI closes
/datum/tgui_module/custom_marking_designer/tgui_close(mob/user)
	var/saved = save_marking_changes(mark_dirty, TRUE)
	. = ..()
	if(saved && prefs && user)
		prefs.skip_custom_marking_cache_invalidation_once = TRUE
		prefs.ShowChoices(user)
	if(prefs)
		prefs.custom_marking_designer_ui = null
	reset_body_marking_chunk_state()
	return .

// Set up the designer for an existing or newly created marking
/datum/tgui_module/custom_marking_designer/New(datum/preferences/pref, datum/custom_marking/existing, initial_tab_override = "custom", skip_mark_create = FALSE)
	..()
	prefs = pref
	if(prefs)
		reference_payload_cache = islist(prefs.custom_marking_reference_payload_cache) ? prefs.custom_marking_reference_payload_cache : null
		reference_cache_signature = prefs.custom_marking_reference_signature
		reference_mannequin_signature = prefs.custom_marking_reference_mannequin_signature
	else
		reference_payload_cache = null
		reference_cache_signature = null
		reference_mannequin_signature = null
	if(istext(initial_tab_override) && length(initial_tab_override))
		initial_tab = initial_tab_override
	else
		initial_tab = "custom"
	if(existing)
		mark = existing
	else if(!skip_mark_create)
		var/owner = pref?.client_ckey || pref?.client?.ckey || "custom"
		var/id = generate_custom_marking_id(owner)
		mark = new(id, "New Custom Marking", list(BP_TORSO), owner)
		mark.register()
		if(pref)
			LAZYINITLIST(pref.custom_markings)
			pref.custom_markings[mark.id] = mark
		is_new_mark = TRUE
	else
		mark = null
		is_new_mark = FALSE
	allow_custom_tab = !!mark
	if(!allow_custom_tab && initial_tab == "custom")
		initial_tab = "body"
	preview_revision = 1
	last_preview_bundle_revision = preview_revision
	active_tab = initial_tab
	initial_snapshot = mark?.to_save()
	if(mark)
		register_custom_marking_style(mark, TRUE)
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()
	direction_order = list(NORTH, SOUTH, EAST, WEST)
	sessions = list()
	active_body_part = default_body_part()
	session_token = REF(src)
	state_session_token = session_token

// Ensure there is always a valid body part focus for editing
/datum/tgui_module/custom_marking_designer/proc/default_body_part()
	if(mark?.body_parts && mark.body_parts.len)
		return mark.body_parts[1]
	if(mark)
		if(!mark.body_parts)
			mark.body_parts = list()
		if(!(BP_TORSO in mark.body_parts))
			mark.body_parts += BP_TORSO
			mark.ensure_part_frames(list(BP_TORSO))
	return BP_TORSO

// Toggle dirty flag for pending saves
/datum/tgui_module/custom_marking_designer/proc/set_mark_dirty(state)
	mark_dirty = !!state

// Fetch or create the painting session for the requested frame
/datum/tgui_module/custom_marking_designer/proc/get_session(dir, part = active_body_part)
	RETURN_TYPE(/datum/custom_marking_session)
	if(!mark)
		return null
	if(!sessions)
		sessions = list()
	var/key = mark.frame_key(dir, part)
	var/datum/custom_marking_session/session = sessions[key]
	if(!session)
		session = new(mark, dir, part)
		sessions[key] = session
	return session

// Commit a session and flag the mark as dirty when pixels were modified
/datum/tgui_module/custom_marking_designer/proc/commit_session(datum/custom_marking_session/session)
	if(session?.commit_pending())
		set_mark_dirty(TRUE)
		body_part_layer_revision++
		return TRUE
	return FALSE

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

// Make sure a part exists on the mark and sessions
/datum/tgui_module/custom_marking_designer/proc/ensure_body_part_registered(part)
	if(!mark)
		return FALSE
	var/normalized = mark.normalize_part(part)
	if(isnull(normalized))
		return FALSE
	if(!mark.body_parts)
		mark.body_parts = list()
	if(normalized in mark.body_parts)
		return TRUE
	mark.body_parts += normalized
	mark.ensure_part_frames(list(normalized))
	set_mark_dirty(TRUE)
	body_part_layer_revision++
	preview_revision++
	return TRUE

// Switch the editing context to a new body part
/datum/tgui_module/custom_marking_designer/proc/set_active_body_part(part)
	if(!mark)
		return
	var/normalized = mark.normalize_part(part)
	if(isnull(normalized))
		return
	if(normalized != active_body_part)
		commit_session(get_session(active_dir, active_body_part))
		active_body_part = normalized
		body_part_layer_revision++
		preview_revision++

// Apply replacement flags coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_part_replacement_payload(list/payload)
	if(!mark || !islist(payload))
		return FALSE
	var/changed = FALSE
	for(var/key in payload)
		if(isnull(key))
			continue
		var/value = payload[key]
		var/normalized = mark.normalize_part(key)
		if(isnull(normalized) || normalized == "generic")
			continue
		if(!ensure_body_part_registered(normalized))
			continue
		var/state = null
		if(isnum(value))
			state = !!value
		else if(istext(value))
			var/lower_value = lowertext(value)
			if(lower_value in list("1", "true", "yes", "on"))
				state = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				state = FALSE
		if(isnull(state))
			continue
		if(mark.is_part_replaced(normalized) == state)
			continue
		mark.set_part_replacement(normalized, state)
		changed = TRUE
	if(changed)
		set_mark_dirty(TRUE)
		preview_revision++
	return changed

// Apply render priority flags coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_part_render_priority_payload(list/payload)
	if(!mark || !islist(payload))
		return FALSE
	var/changed = FALSE
	var/list/current_map = mark?.get_render_priority_map()
	for(var/key in payload)
		if(isnull(key))
			continue
		var/value = payload[key]
		var/normalized = mark.normalize_part(key)
		if(isnull(normalized) || normalized == "generic")
			continue
		if(!ensure_body_part_registered(normalized))
			continue
		var/state_defined = FALSE
		var/state_value = null
		if(isnum(value))
			state_defined = TRUE
			state_value = !!value
		else if(istext(value))
			var/lower_value = lowertext(value)
			if(lower_value in list("1", "true", "yes", "on"))
				state_defined = TRUE
				state_value = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				state_defined = TRUE
				state_value = FALSE
		if(!state_defined)
			continue
		var/current_defined = islist(current_map) && (normalized in current_map)
		var/current = mark.is_part_render_priority(normalized)
		if(current_defined && current == state_value)
			continue
		if(mark.set_part_render_priority(normalized, state_value))
			changed = TRUE
	if(changed)
		set_mark_dirty(TRUE)
		preview_revision++
	return changed

// Apply canvas size overrides coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_part_canvas_size_payload(list/payload)
	if(!mark || !islist(payload))
		return FALSE
	var/changed = FALSE
	for(var/key in payload)
		if(isnull(key))
			continue
		var/value = payload[key]
		var/normalized = mark.normalize_part(key)
		if(isnull(normalized) || normalized == "generic")
			continue
		if(!ensure_body_part_registered(normalized))
			continue
		var/state_defined = FALSE
		var/state_value = null
		if(isnum(value))
			state_defined = TRUE
			state_value = !!value
		else if(istext(value))
			var/lower_value = lowertext(value)
			if(lower_value in list("1", "true", "yes", "on"))
				state_defined = TRUE
				state_value = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				state_defined = TRUE
				state_value = FALSE
		if(!state_defined)
			continue
		if(mark.is_part_large_canvas(normalized) == state_value)
			continue
		if(mark.set_part_canvas_size(normalized, state_value))
			changed = TRUE
	if(changed)
		set_mark_dirty(TRUE)
		body_part_layer_revision++
		preview_revision++
	return changed

// Drop body parts with no visible pixels across directions
/datum/tgui_module/custom_marking_designer/proc/prune_empty_body_parts()
	if(!mark || !islist(mark.body_parts) || !mark.body_parts.len)
		return FALSE
	var/list/dirs = list(NORTH, SOUTH, EAST, WEST)
	var/list/remove_parts = list()
	for(var/part in mark.body_parts.Copy())
		var/has_pixels = FALSE
		for(var/dir in dirs)
			var/datum/custom_marking_frame/frame = mark.get_frame(dir, part, FALSE)
			if(frame?.has_visible_pixels())
				has_pixels = TRUE
				break
		if(!has_pixels)
			remove_parts += part
	if(!remove_parts.len)
		return FALSE
	for(var/part in remove_parts)
		mark.body_parts -= part
		mark.clear_part_replacement(part)
		mark.clear_part_render_priority(part)
		var/list/size_map = mark.get_canvas_size_map()
		if(islist(size_map))
			size_map -= part
			if(!size_map.len && islist(mark.options))
				mark.options -= "large_canvas_parts"
		for(var/dir in dirs)
			var/session_key = mark.frame_key(dir, part)
			if(islist(sessions) && sessions[session_key])
				sessions -= session_key
		if(part != "generic" && islist(mark.frames))
			for(var/dir in dirs)
				var/frame_key_value = mark.frame_key(dir, part)
				if(frame_key_value && mark.frames?[frame_key_value])
					mark.frames -= frame_key_value
	body_part_layer_revision++
	preview_revision++
	set_mark_dirty(TRUE)
	return TRUE

// Keep preference body marking data aligned with editor selections
/datum/tgui_module/custom_marking_designer/proc/sync_preference_assignment()
	if(!prefs || !mark)
		return
	register_custom_marking_style(mark, TRUE)
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
	preview_revision++

// Register finished edits into prefs/custom markings
/datum/tgui_module/custom_marking_designer/proc/register_mark_with_prefs()
	if(!mark)
		return
	var/current_id = mark.register()
	if(prefs)
		LAZYINITLIST(prefs.custom_markings)
		if(islist(prefs.custom_markings))
			prefs.custom_markings[current_id] = mark
			if(original_mark_id && original_mark_id != current_id)
				prefs.custom_markings -= original_mark_id
	if(is_new_mark && !original_mark_id)
		original_mark_id = current_id
	var/current_style = mark.get_style_name()
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory(TRUE)
	if(prefs && islist(prefs.body_markings))
		if(original_style_name && original_style_name != current_style && prefs.body_markings[original_style_name])
			var/list/old_entry = prefs.body_markings[original_style_name]
			prefs.body_markings -= original_style_name
			if(!prefs.body_markings[current_style])
				prefs.body_markings[current_style] = old_entry
		var/list/current_entry = prefs.body_markings[current_style]
		if(islist(current_entry))
			current_entry["datum"] = style
			for(var/part in current_entry)
				if(!istext(part) || part == "color")
					continue
				var/list/details = current_entry[part]
				if(islist(details))
					details["datum"] = style
	original_style_name = current_style

// Commit edits, refresh caches, and update preview assets
/datum/tgui_module/custom_marking_designer/proc/save_marking_changes(force_save = TRUE, refresh_browser = FALSE, refresh_preview_assets = TRUE)
	if(!mark)
		return FALSE
	var/log_ckey = prefs?.client_ckey || prefs?.client?.ckey || mark?.owner_ckey || "unknown"
	var/committed = commit_all_sessions()
	var/pruned = prune_empty_body_parts()
	var/shrank = mark.shrink_large_parts_if_safe()
	if(shrank)
		set_mark_dirty(TRUE)
		body_part_layer_revision++
		preview_revision++
	if(!force_save && !mark_dirty && !committed && !pruned && !shrank)
		return FALSE
	var/needs_save = committed || mark_dirty || pruned || shrank
	if(!needs_save)
		return FALSE
	mark.bump_revision()
	log_debug("CustomMarkings: [log_ckey] saved marking '[mark?.name]' ([mark?.id]) rev=[mark?.style_revision]")
	register_mark_with_prefs()
	sync_preference_assignment()
	mark_dirty = FALSE
	is_new_mark = FALSE
	initial_snapshot = mark.to_save()
	if(prefs && !QDELETED(prefs))
		if(refresh_preview_assets || refresh_browser)
			prefs.skip_custom_marking_cache_invalidation_once = TRUE
		if(refresh_preview_assets)
			prefs.refresh_custom_marking_assets(TRUE, TRUE, mark, TRUE)
	if(refresh_preview_assets)
		preview_revision++
	if(refresh_browser && prefs)
		refresh_preferences_window_if_visible()
	return TRUE

// Refresh the legacy character setup browser and preview if it's already open (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/refresh_preferences_window_if_visible(refresh_preview = TRUE)
	if(!prefs)
		return FALSE
	var/mob/user = usr
	if(!user && prefs.client)
		user = prefs.client.mob
	if(!user || !user.client)
		return FALSE
	var/visible = winget(user, "preferences_window", "is-visible")
	if(istext(visible) && lowertext(visible) == "true")
		if(refresh_preview)
			INVOKE_ASYNC(prefs, /datum/preferences/proc/update_preview_icon, TRUE)
		INVOKE_ASYNC(prefs, /datum/preferences/proc/ShowChoices, user)
		return TRUE
	return FALSE

// Revert or remove edits depending on whether this is a new mark
/datum/tgui_module/custom_marking_designer/proc/discard_changes()
	if(!mark)
		return
	reset_body_marking_chunk_state()
	if(is_new_mark)
		if(prefs)
			prefs.custom_markings -= mark.id
		unregister_custom_marking_style(mark.id)
		GLOB.custom_markings_by_id -= mark.id
		mark = null
		sessions = list()
		SStgui.close_uis(src)
		return
	if(initial_snapshot)
		mark.from_save(initial_snapshot)
	register_custom_marking_style(mark, TRUE)
	sessions = list()
	is_new_mark = FALSE
	mark_dirty = FALSE
	body_part_layer_revision++
	preview_revision++
	active_body_part = default_body_part()
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()

// Build composite layers for each part in a direction
/datum/tgui_module/custom_marking_designer/proc/build_body_part_layers(dir)
	if(!mark?.body_parts || !mark.body_parts.len)
		return null
	var/list/layers = list()
	for(var/part in mark.body_parts)
		var/datum/custom_marking_frame/frame = mark.get_frame(dir, part, FALSE)
		var/list/composite = frame?.get_composite()
		if(islist(composite))
			layers[part] = composite
	return layers.len ? layers : null

// Pass static replacement dependency hints to the client
/datum/tgui_module/custom_marking_designer/proc/build_replacement_dependents_payload()
	if(!islist(GLOB.custom_marking_replacement_children) || !GLOB.custom_marking_replacement_children.len)
		return null
	var/list/result = list()
	for(var/parent in GLOB.custom_marking_replacement_children)
		if(isnull(parent))
			continue
		var/list/raw_children = GLOB.custom_marking_replacement_children[parent]
		if(!islist(raw_children) || !raw_children.len)
			continue
		var/list/child_entries = list()
		for(var/child in raw_children)
			if(!isnull(child))
				child_entries += child
		if(child_entries.len)
			result[parent] = child_entries
	return result.len ? result : null

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

// Resolve display strings for body part selections
/datum/tgui_module/custom_marking_designer/proc/get_body_part_label(part)
	if(!part)
		return "Generic"
	var/list/labels = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(labels && (part in labels))
		return labels[part]
	return capitalize(replacetext(part, "_", " "))

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
	data["width"] = get_canvas_width()
	data["height"] = get_canvas_height()
	data["max_width"] = CUSTOM_MARKING_CANVAS_MAX_WIDTH
	data["max_height"] = CUSTOM_MARKING_CANVAS_MAX_HEIGHT
	data["default_width"] = CUSTOM_MARKING_DEFAULT_WIDTH
	data["default_height"] = CUSTOM_MARKING_DEFAULT_HEIGHT
	var/list/replacement_dependents = build_replacement_dependents_payload()
	if(islist(replacement_dependents) && replacement_dependents.len)
		data["replacement_dependents"] = replacement_dependents
	var/list/canvas_backgrounds = build_canvas_background_options()
	if(islist(canvas_backgrounds) && canvas_backgrounds.len)
		data["canvas_backgrounds"] = canvas_backgrounds
		data["default_canvas_background"] = "default"
	return data

// Create backrounds for the custom markings designer
/datum/tgui_module/custom_marking_designer/proc/build_canvas_background_options()
	var/list/backgrounds = list(list(
		"id" = "default",
		"label" = "Default",
		"asset" = null
	))
	var/list/season_state_map = list(
		"spring" = "grass-spring4",
		"summer" = "grass-summer4",
		"fall" = "grass-autumn4",
		"winter" = "grass-winter4"
	)
	for(var/season in season_state_map)
		var/state = season_state_map[season]
		if(!istext(state) || !length(state))
			continue
		var/icon/I = icon('icons/seasonal/turf.dmi', state)
		if(!isicon(I))
			continue
		var/list/asset = build_icon_asset(I)
		if(!islist(asset))
			continue
		var/label = capitalize(season)
		if(season == "fall")
			label = "Fall"
		backgrounds += list(list(
			"id" = season,
			"label" = label,
			"asset" = asset
		))
	return backgrounds

// Provide the live editing payload for TGUI rendering
/datum/tgui_module/custom_marking_designer/tgui_data(mob/user)
	var/list/data = list()
	data["marking_id"] = mark?.id
	data["mark_name"] = mark?.name
	data["initial_tab"] = initial_tab
	if(!allow_custom_tab && active_tab == "custom")
		active_tab = "body"
	data["active_tab"] = active_tab
	data["allow_custom_tab"] = allow_custom_tab
	data["custom_marking_enable_disclaimer"] = prefs?.get_custom_markings_enable_disclaimer()
	data["active_dir"] = direction_label(active_dir)
	data["active_dir_key"] = active_dir
	data["is_new"] = is_new_mark
	var/datum/custom_marking_session/session = get_session(active_dir, active_body_part)
	data["grid"] = session ? session.get_grid() : null
	data["diff"] = null
	data["diff_seq"] = diff_sequence
	data["session_token"] = session_token
	data["state_token"] = state_session_token
	data["limited"] = FALSE
	data["finalized"] = FALSE
	data["can_finalize"] = FALSE
	data["width"] = get_canvas_width()
	data["height"] = get_canvas_height()
	data["max_width"] = CUSTOM_MARKING_CANVAS_MAX_WIDTH
	data["max_height"] = CUSTOM_MARKING_CANVAS_MAX_HEIGHT
	data["default_width"] = CUSTOM_MARKING_DEFAULT_WIDTH
	data["default_height"] = CUSTOM_MARKING_DEFAULT_HEIGHT
	data["active_canvas_width"] = mark ? mark.get_part_canvas_width(active_body_part) : get_canvas_width()
	data["active_canvas_height"] = mark ? mark.get_part_canvas_height(active_body_part) : get_canvas_height()
	data["selected_body_parts"] = mark?.body_parts?.Copy() || list()
	data["part_replacements"] = mark?.get_part_replacement_payload()
	data["part_render_priority"] = mark?.get_part_render_priority_payload()
	data["part_canvas_size"] = mark?.get_part_canvas_size_payload()
	data["active_body_part"] = active_body_part
	data["active_body_part_label"] = get_body_part_label(active_body_part)
	var/list/layers = build_body_part_layers(active_dir)
	if(islist(layers) && layers.len)
		data["body_part_layers"] = layers
		data["body_part_layer_order"] = mark?.body_parts?.Copy()
	data["body_part_layer_revision"] = body_part_layer_revision
	data["preview_revision"] = isnum(last_preview_bundle_revision) ? last_preview_bundle_revision : preview_revision
	if(active_tab == "custom")
		var/list/preview_bundle = build_preview_source_bundle()
		if(islist(preview_bundle))
			data["preview_sources"] = preview_bundle["dirs"]
			data["preview_revision"] = preview_bundle["revision"]
			last_preview_bundle_revision = preview_bundle["revision"]
	var/list/canvas_backgrounds_live = build_canvas_background_options()
	if(islist(canvas_backgrounds_live) && canvas_backgrounds_live.len)
		data["canvas_backgrounds"] = canvas_backgrounds_live
		data["default_canvas_background"] = "default"
	data["ui_locked"] = FALSE
	data["show_job_gear"] = !!(prefs?.equip_preview_mob & EQUIP_PREVIEW_JOB)
	data["show_loadout_gear"] = !!(prefs?.equip_preview_mob & EQUIP_PREVIEW_LOADOUT)
	data["reference_build_in_progress"] = reference_build_in_progress
	return data

// Build the payload for the standard body markings tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_body_markings_payload()
	var/list/yield_context = custom_marking_begin_manual_yield()
	if(!prefs)
		custom_marking_end_manual_yield(yield_context)
		return null
	var/list/payload = list()
	payload["digitigrade"] = !!prefs.digitigrade
	payload["body_marking_definitions"] = build_body_marking_definitions()
	var/list/original_body_markings = prefs.body_markings ? prefs.body_markings.Copy() : list()
	payload["body_markings"] = original_body_markings ? original_body_markings.Copy() : list()
	var/list/order = list()
	if(islist(original_body_markings))
		for(var/mark in original_body_markings)
			order += mark
	payload["order"] = order
	var/list/preview_bundle = null
	var/old_body_markings = prefs.body_markings
	prefs.body_markings = null
	preview_bundle = build_preview_source_bundle(TRUE)
	prefs.body_markings = old_body_markings
	if(islist(preview_bundle))
		payload["preview_sources"] = preview_bundle["dirs"]
		payload["preview_revision"] = preview_bundle["revision"]
	payload["preview_width"] = get_preview_canvas_width()
	payload["preview_height"] = get_preview_canvas_height()
	var/list/canvas_backgrounds_live = build_canvas_background_options()
	if(islist(canvas_backgrounds_live) && canvas_backgrounds_live.len)
		payload["canvas_backgrounds"] = canvas_backgrounds_live
		payload["default_canvas_background"] = "default"
	custom_marking_end_manual_yield(yield_context)
	return payload

// Normalize a part key from incoming params
/datum/tgui_module/custom_marking_designer/proc/resolve_action_part(list/params)
	if(mark)
		var/raw_part = params?["part"]
		if(istext(raw_part) && length(raw_part))
			var/normalized = mark.normalize_part(raw_part)
			if(istext(normalized) && length(normalized))
				return normalized
	if(active_body_part)
		return active_body_part
	return default_body_part()

// Echo diff + ack sequence back to the client
/datum/tgui_module/custom_marking_designer/proc/send_diff_ack(list/diff_payload, width, height, stroke_id = null, list/extra = null)
	diff_sequence++
	var/list/custom = list(
		"diff" = diff_payload,
		"diff_seq" = diff_sequence,
		"width" = width,
		"height" = height,
		"body_part_layer_revision" = body_part_layer_revision,
		"preview_revision" = preview_revision
	)
	if(!isnull(stroke_id))
		custom["stroke"] = stroke_id
	if(islist(extra))
		for(var/key in extra)
			custom[key] = extra[key]
	custom["grid"] = get_session(active_dir, active_body_part)?.get_grid()
	var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
	if(active_ui)
		active_ui.send_update(custom)
	else
		SStgui.update_uis(src, custom)

// Handle interactive actions from the TGUI frontend
/datum/tgui_module/custom_marking_designer/tgui_act(action, params)
	if(..())
		return TRUE
	var/handled = TRUE
	if(action == "set_active_tab")
		var/tab = params?["tab"]
		if(istext(tab) && length(tab))
			tab = lowertext(tab)
			if(!allow_custom_tab && tab == "custom")
				tab = "body"
			active_tab = tab
			if(active_tab == "custom")
				SStgui.update_uis(src)
		return TRUE
	if(action == "enable_custom_markings")
		if(!prefs)
			return TRUE
		var/datum/custom_marking/enabled_mark = prefs.ensure_primary_custom_marking()
		if(!istype(enabled_mark))
			return TRUE
		if(mark != enabled_mark)
			mark = enabled_mark
			is_new_mark = FALSE
			sessions = list()
			active_body_part = default_body_part()
			initial_snapshot = mark.to_save()
			original_mark_id = mark.id
			original_style_name = mark.get_style_name()
			body_part_layer_revision++
			preview_revision++
		allow_custom_tab = TRUE
		register_custom_marking_style(mark, TRUE)
		if(prefs)
			prefs.refresh_custom_marking_assets(FALSE, TRUE, mark, TRUE)
		refresh_preferences_window_if_visible(TRUE)
		SStgui.update_uis(src)
		return TRUE
	if(action == "apply_preview_diff")
		var/list/diff = params?["diff"]
		if(!islist(diff) || !diff.len)
			return TRUE
		var/dir_override = text2num(params?["dir"])
		if(!isnum(dir_override) || !dir_override)
			dir_override = active_dir
		var/part = resolve_action_part(params)
		ensure_body_part_registered(part)
		active_dir = dir_override
		set_active_body_part(part)
		var/datum/custom_marking_session/session = get_session(active_dir, part)
		var/list/diff_result = session?.apply_client_diff(diff, params?["height"], params?["width"])
		var/pixels_changed = FALSE
		var/canvas_changed = FALSE
		if(islist(diff_result))
			pixels_changed = !!diff_result["changed"]
			canvas_changed = !!diff_result["canvas_resized"]
		else
			pixels_changed = !!diff_result
		if(pixels_changed || canvas_changed)
			set_mark_dirty(TRUE)
			body_part_layer_revision++
			preview_revision++
		var/list/extra_update = null
		if(canvas_changed)
			extra_update = list(
				"part_canvas_size" = mark?.get_part_canvas_size_payload(),
				"part_render_priority" = mark?.get_part_render_priority_payload(),
				"active_canvas_width" = mark ? mark.get_part_canvas_width(active_body_part) : get_canvas_width(),
				"active_canvas_height" = mark ? mark.get_part_canvas_height(active_body_part) : get_canvas_height()
			)
		send_diff_ack(diff, params?["width"], params?["height"], params?["stroke"], extra_update)
		commit_session(session)
		if(canvas_changed)
			SStgui.update_uis(src)
	else if(action == "set_canvas_size")
		var/new_width = params?["width"]
		var/new_height = params?["height"]
		var/resized = FALSE
		if(mark)
			resized = mark.resize_canvas(new_width, new_height)
		if(resized)
			register_custom_marking_style(mark, TRUE)
			sessions = list()
			body_part_layer_revision++
			preview_revision++
			set_mark_dirty(TRUE)
		SStgui.update_uis(src)
		return TRUE
	else if(action == "set_part_canvas_size")
		if(!mark)
			return TRUE
		var/part = resolve_action_part(params)
		if(!ensure_body_part_registered(part))
			return TRUE
		var/state_value = params?["large"]
		var/desired = null
		if(isnum(state_value))
			desired = !!state_value
		else if(istext(state_value))
			var/lower_value = lowertext(state_value)
			if(lower_value in list("1", "true", "yes", "on"))
				desired = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				desired = FALSE
		if(isnull(desired))
			desired = !mark.is_part_large_canvas(part)
		if(mark.set_part_canvas_size(part, desired))
			register_custom_marking_style(mark, TRUE)
			set_mark_dirty(TRUE)
			body_part_layer_revision++
			preview_revision++
		SStgui.update_uis(src)
		return TRUE
	// Added to avoid race condition (Lira, November 2025)
	else if(action == "discard_and_close")
		discard_changes()
		SStgui.close_uis(src)
		return FALSE
	else if(action == "save_and_close")
		var/replacements_updated = apply_part_replacement_payload(params?["part_replacements"])
		var/priority_updated = apply_part_render_priority_payload(params?["part_render_priority"])
		var/canvas_updated = apply_part_canvas_size_payload(params?["part_canvas_size"])
		if(replacements_updated || priority_updated || canvas_updated)
			register_custom_marking_style(mark, TRUE)
		var/saved = save_marking_changes(TRUE, TRUE, FALSE)
		if(saved)
			body_markings_refresh_pending = TRUE
		SStgui.close_uis(src)
		return FALSE
	else if(action == "save_progress")
		var/replacements_updated = apply_part_replacement_payload(params?["part_replacements"])
		var/priority_updated = apply_part_render_priority_payload(params?["part_render_priority"])
		var/canvas_updated = apply_part_canvas_size_payload(params?["part_canvas_size"])
		if(replacements_updated || priority_updated || canvas_updated)
			register_custom_marking_style(mark, TRUE)
		var/saved = save_marking_changes(TRUE, TRUE, FALSE)
		if(saved)
			body_markings_refresh_pending = TRUE
		SStgui.update_uis(src)
	else if(action == "load_body_markings")
		if(body_markings_refresh_pending)
			if(mark)
				register_custom_marking_style(mark, FALSE)
			reference_cache_signature = null
			reference_mannequin_signature = null
			reference_payload_cache = null
			if(prefs)
				prefs.custom_marking_reference_signature = null
				prefs.custom_marking_reference_payload_cache = null
				prefs.custom_marking_reference_mannequin_signature = null
			body_markings_refresh_pending = FALSE
		var/list/body_payload = build_body_markings_payload()
		if(islist(body_payload))
			var/list/update = list("body_markings_payload" = body_payload)
			var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
			if(active_ui)
				active_ui.send_update(update)
			else
				SStgui.update_uis(src, update)
		return TRUE
	else if(action == "save_body_markings")
		var/close_ui = params?["close"]
		var/list/save_payload = resolve_body_marking_chunk_payload(params)
		if(save_payload == BODY_MARKING_CHUNK_PENDING)
			return TRUE
		if(islist(save_payload) && apply_body_marking_payload(save_payload))
			refresh_preferences_window_if_visible(TRUE)
			if(close_ui)
				SStgui.close_uis(src)
				return FALSE
			SStgui.update_uis(src)
		return TRUE
	else if(action == "close_body_markings")
		reset_body_marking_chunk_state()
		SStgui.close_uis(src)
		return FALSE
	else if(action == "discard_changes")
		discard_changes()
		SStgui.update_uis(src)
	else if(action == "view_raw_payload")
		handled = view_raw_marking_payload(usr, params)
	else if(action == "client_warning")
		handled = handle_client_warning(usr, params)
	else
		handled = FALSE
	return handled ? TRUE : FALSE

// Log and relay client-side warnings
/datum/tgui_module/custom_marking_designer/proc/handle_client_warning(mob/user, list/params)
	if(!islist(params))
		params = list()
	var/message = params?["message"]
	if(!istext(message) || !length(message))
		message = "Unspecified client warning."
	var/safe_message = sanitize_text(message)
	var/list/log_payload = list(
		"message" = message,
		"payload" = params
	)
	if(user)
		to_chat(user, span_warning(safe_message))
	log_tgui(user, "Custom Marking Designer client warning:\n[json_encode(log_payload)]")
	return TRUE

// Build the serialized payload that ends up inside preferences.sav
/datum/tgui_module/custom_marking_designer/proc/build_marking_save_payload()
	if(!mark)
		return null
	var/list/save_data = mark.to_save()
	if(!islist(save_data))
		return null
	var/key = mark.id || "custom_marking"
	if(prefs)
		if(mark.id)
			LAZYINITLIST(prefs.custom_markings)
			if(islist(prefs.custom_markings))
				prefs.custom_markings[mark.id] = mark
		var/list/prefs_payload = prefs.get_custom_markings_payload()
		if(islist(prefs_payload) && prefs_payload.len)
			return prefs_payload
	var/list/fallback = list()
	fallback[key] = save_data
	return fallback

// Present the raw JSON blob that lives in the savefile for this marking
/datum/tgui_module/custom_marking_designer/proc/view_raw_marking_payload(mob/user, params)
	if(!user || !mark)
		return FALSE
	commit_all_sessions()
	var/list/payload = build_marking_save_payload()
	if(!islist(payload) || !payload.len)
		to_chat(user, span_warning("Unable to build a save payload for this marking."))
		return FALSE
	var/json_text = json_encode(payload)
	if(!istext(json_text) || !length(json_text))
		to_chat(user, span_warning("Unable to encode the save payload as JSON."))
		return FALSE
	var/path_hint = prefs?.path
	if(!istext(path_hint) || !length(path_hint))
		path_hint = "data/player_saves/<ckey>/preferences.sav"
	var/style_name = mark?.get_style_name() || "Custom Marking"
	var/list/html_bits = list()
	html_bits += "<html><head><meta charset='utf-8'><title>Custom Marking Payload</title>"
	html_bits += "<style>body{background:#111;color:#ddd;font-family:Consolas,Menlo,monospace;font-size:13px;padding:10px;} h2{margin-top:0;} code{color:#8bf;} textarea{width:100%;height:70vh;background:#000;color:#0f0;border:1px solid #555;resize:vertical;padding:8px;box-sizing:border-box;}</style></head><body>"
	html_bits += "<h2>Raw Save Payload &mdash; [html_encode(style_name)]</h2>"
	html_bits += "<p>This JSON lives inside <code>[html_encode(path_hint)]</code> under the <code>custom_markings</code> entry.</p>"
	html_bits += "<textarea readonly spellcheck='false'>[html_encode(json_text)]</textarea>"
	html_bits += "</body></html>"
	var/html = jointext(html_bits, "")
	user << browse(html, "window=custom_marking_payload;size=720x600")
	return TRUE

// Resolve the current canvas width with sensible defaults
/datum/tgui_module/custom_marking_designer/proc/get_canvas_width()
	var/value = mark ? mark.get_effective_canvas_width() : CUSTOM_MARKING_DEFAULT_WIDTH
	return clamp_custom_marking_dimension(value, CUSTOM_MARKING_DEFAULT_WIDTH, CUSTOM_MARKING_CANVAS_MAX_WIDTH)

// Resolve the current canvas height with sensible defaults
/datum/tgui_module/custom_marking_designer/proc/get_canvas_height()
	var/value = mark ? mark.get_effective_canvas_height() : CUSTOM_MARKING_DEFAULT_HEIGHT
	return clamp_custom_marking_dimension(value, CUSTOM_MARKING_DEFAULT_HEIGHT, CUSTOM_MARKING_CANVAS_MAX_HEIGHT)

// Return the canvas width
/datum/tgui_module/custom_marking_designer/proc/get_preview_canvas_width()
	return CUSTOM_MARKING_CANVAS_MAX_WIDTH

// Return the canvas height
/datum/tgui_module/custom_marking_designer/proc/get_preview_canvas_height()
	return CUSTOM_MARKING_CANVAS_MAX_HEIGHT

// Build a map of composite grids for each part in a direction
/datum/tgui_module/custom_marking_designer/proc/build_custom_grid_map(dir, use_stripped_reference = FALSE)
	if(!mark)
		return list()
	var/list/result = list()
	var/list/parts = get_preview_part_order(dir, use_stripped_reference)
	if(!islist(parts) || !parts.len)
		parts = list("generic")
	for(var/part in parts)
		var/normalized_part = part
		if(part == "generic")
			normalized_part = null
		var/datum/custom_marking_frame/frame = mark.get_frame(dir, normalized_part, FALSE)
		var/list/composite_grid = null
		if(frame)
			composite_grid = frame.get_composite()
		result[part] = composite_grid
	return result

// Build ordering the client should use for preview layers
/datum/tgui_module/custom_marking_designer/proc/get_preview_part_order(dir_override = null, use_stripped_reference = FALSE)
	var/list/order = list("generic")
	var/list/reference_order = get_reference_part_order(dir_override, use_stripped_reference)
	if(islist(reference_order))
		for(var/ref_part in reference_order)
			if(!istext(ref_part) || !length(ref_part))
				continue
			if(ref_part == "generic")
				continue
			if(!(ref_part in order))
				order += ref_part
	var/list/label_order = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(islist(label_order))
		for(var/label_key in label_order)
			if(label_key == "generic")
				continue
			if(!(label_key in order))
				order += label_key
	if(islist(mark?.body_parts) && mark.body_parts.len)
		for(var/part in mark.body_parts)
			if(!istext(part) || !length(part))
				continue
			if(part == "generic")
				continue
			if(!(part in order))
				order += part
	return order

// Construct preview source payload for a specific direction
/datum/tgui_module/custom_marking_designer/proc/build_preview_source_for_dir(dir, use_stripped_reference = FALSE)
	var/list/entry = list(
		"dir" = dir,
		"label" = direction_label(dir)
	)
	var/list/payload = get_reference_payload_entry(dir, use_stripped_reference)
	if(islist(payload))
		var/list/part_assets = payload["part_assets"]
		if(islist(part_assets) && part_assets.len)
			entry["reference_part_assets"] = part_assets
		var/list/part_marking_assets = payload["part_marking_assets"]
		if(islist(part_marking_assets) && part_marking_assets.len)
			entry["reference_part_marking_assets"] = part_marking_assets
		var/list/overlay_assets = payload["overlay_assets"]
		if(islist(overlay_assets) && overlay_assets.len)
			entry["overlay_assets"] = overlay_assets
		var/list/body_asset = payload["body_asset"]
		if(islist(body_asset))
			entry["body_asset"] = body_asset
		var/list/composite_asset = payload["composite_asset"]
		if(islist(composite_asset))
			entry["composite_asset"] = composite_asset
		var/list/job_overlay_assets = payload["job_overlay_assets"]
		if(islist(job_overlay_assets) && job_overlay_assets.len)
			entry["job_overlay_assets"] = job_overlay_assets
		var/list/loadout_overlay_assets = payload["loadout_overlay_assets"]
		if(islist(loadout_overlay_assets) && loadout_overlay_assets.len)
			entry["loadout_overlay_assets"] = loadout_overlay_assets
		var/list/hidden_body_parts = payload["hidden_body_parts"]
		if(islist(hidden_body_parts))
			entry["hidden_body_parts"] = hidden_body_parts
		else
			entry["hidden_body_parts"] = list()
	var/list/custom_parts = build_custom_grid_map(dir, use_stripped_reference)
	if(islist(custom_parts))
		entry["custom_parts"] = custom_parts
	var/list/part_order = get_preview_part_order(dir, use_stripped_reference)
	if(islist(part_order) && part_order.len)
		entry["part_order"] = part_order
	return entry

// Build preview sources for all directions and bump revision on updates
/datum/tgui_module/custom_marking_designer/proc/build_preview_source_bundle(use_stripped_reference = FALSE)
	if(!prefs)
		return null
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/updated = ensure_reference_payload_bundle(get_preview_canvas_width(), get_preview_canvas_height(), use_stripped_reference)
	var/list/result = list()
	for(var/dir in dirs)
		var/list/entry = build_preview_source_for_dir(dir, use_stripped_reference)
		if(islist(entry))
			result += list(entry)
	if(updated)
		if(use_stripped_reference)
			body_preview_revision++
		else
			preview_revision++
	return list(
		"dirs" = result,
		"revision" = use_stripped_reference ? body_preview_revision : preview_revision
	)

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

// Build a stable signature for current body marking selections/colors
/datum/tgui_module/custom_marking_designer/proc/get_body_marking_cache_signature()
	if(!prefs)
		return null
	var/list/markings = prefs.body_markings
	if(!islist(markings) || !markings.len)
		return null
	var/list/sanitized = list()
	for(var/key in markings)
		if(!istext(key))
			continue
		var/list/entry = markings[key]
		if(!islist(entry))
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list?[key]
		if(!istype(style))
			style = entry["datum"]
		if(istype(style, /datum/sprite_accessory/marking/custom))
			continue
		var/list/out_entry = list()
		var/default_color = entry["color"]
		if(istext(default_color))
			out_entry["color"] = default_color
		var/list/parts = list()
		for(var/part in entry)
			if(part == "color" || part == "datum")
				continue
			if(!istext(part))
				continue
			var/list/details = entry[part]
			if(!islist(details))
				continue
			var/list/detail_signature = list()
			if("on" in details)
				detail_signature["on"] = !!details["on"]
			var/part_color = details["color"]
			if(istext(part_color))
				detail_signature["color"] = part_color
			if(detail_signature.len)
				parts[part] = detail_signature
		if(parts.len)
			out_entry["parts"] = parts
		sanitized[key] = out_entry
	if(!sanitized.len)
		return null
	return md5(json_encode(sanitized))

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
		),
		"preview_overlay_rev" = 1,
		"job_pref_high" = list(
			"civilian" = prefs.job_civilian_high,
			"medsci" = prefs.job_medsci_high,
			"engsec" = prefs.job_engsec_high
		),
		"equip_preview_mask" = prefs.equip_preview_mob,
		"gear_loadout" = prefs.gear?.Copy(),
		"player_alt_titles" = prefs.player_alt_titles?.Copy(),
		"body_markings" = get_body_marking_cache_signature()
	)
	if(islist(prefs.ear_secondary_colors))
		payload["ear_secondary_colors"] = prefs.ear_secondary_colors.Copy()
	if(islist(prefs.body_descriptors))
		payload["descriptors"] = prefs.body_descriptors.Copy()
	return json_encode(payload)

// Trigger a queued mannequin rebuild after the current one finishes
/datum/tgui_module/custom_marking_designer/proc/process_pending_reference_build()
	if(!islist(reference_pending_request))
		return
	var/list/pending = reference_pending_request
	reference_pending_request = null
	spawn(0)
		ensure_reference_payload_bundle(pending["width"], pending["height"])

// Trigger a queued stripped mannequin rebuild after the current one finishes (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/process_pending_body_reference_build()
	if(!islist(body_reference_pending_request))
		return
	var/list/pending = body_reference_pending_request
	body_reference_pending_request = null
	spawn(0)
		ensure_reference_payload_bundle(pending["width"], pending["height"], TRUE)

// Ensure cached reference payloads exist for each direction at the requested size
/datum/tgui_module/custom_marking_designer/proc/ensure_reference_payload_bundle(width, height, use_stripped_reference = FALSE)
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/target_signature = get_reference_cache_signature(width, height)
	var/build_in_progress = use_stripped_reference ? body_reference_build_in_progress : reference_build_in_progress
	var/list/pending_request = use_stripped_reference ? body_reference_pending_request : reference_pending_request
	if(build_in_progress)
		if(!islist(pending_request) || (pending_request["signature"] != target_signature))
			pending_request = list(
				"width" = width,
				"height" = height,
				"signature" = target_signature
			)
		if(use_stripped_reference)
			body_reference_pending_request = pending_request
		else
			reference_pending_request = pending_request
		custom_marking_end_manual_yield(yield_context)
		return FALSE
	if(use_stripped_reference)
		body_reference_build_in_progress = TRUE
		body_reference_pending_request = null
	else
		reference_build_in_progress = TRUE
		reference_pending_request = null
	var/updated = FALSE
	if(!prefs)
		if(use_stripped_reference)
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	if(width <= 0 || height <= 0)
		if(use_stripped_reference)
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	var/list/cache = use_stripped_reference ? body_reference_payload_cache : reference_payload_cache
	var/cache_signature = use_stripped_reference ? body_reference_cache_signature : reference_cache_signature
	var/mannequin_signature = use_stripped_reference ? body_reference_mannequin_signature : reference_mannequin_signature
	if(cache_signature != target_signature || !islist(cache))
		cache_signature = target_signature
		cache = list()
		if(!use_stripped_reference && prefs)
			prefs.custom_marking_reference_signature = cache_signature
			prefs.custom_marking_reference_payload_cache = cache
		updated = TRUE
	else if(!use_stripped_reference && prefs)
		if(prefs.custom_marking_reference_payload_cache != cache)
			prefs.custom_marking_reference_payload_cache = cache
		if(prefs.custom_marking_reference_signature != cache_signature)
			prefs.custom_marking_reference_signature = cache_signature
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/list/missing = list()
	for(var/dir in dirs)
		var/key = reference_payload_key(dir, width, height)
		if(!islist(cache[key]))
			missing += dir
	var/mob/living/carbon/human/dummy/mannequin/mannequin = get_reference_mannequin()
	if(!mannequin)
		if(use_stripped_reference)
			body_reference_payload_cache = cache
			body_reference_cache_signature = cache_signature
			body_reference_mannequin_signature = mannequin_signature
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_payload_cache = cache
			reference_cache_signature = cache_signature
			reference_mannequin_signature = mannequin_signature
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	if(missing.len && !use_stripped_reference)
		broadcast_reference_build_state(TRUE)
	var/original_ignore_hide = mannequin.ignore_sprite_accessory_body_hide
	mannequin.ignore_sprite_accessory_body_hide = TRUE
	if(!missing.len)
		mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
		if(use_stripped_reference)
			body_reference_payload_cache = cache
			body_reference_cache_signature = cache_signature
			body_reference_mannequin_signature = mannequin_signature
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_payload_cache = cache
			reference_cache_signature = cache_signature
			reference_mannequin_signature = mannequin_signature
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	var/static/list/gear_overlay_layers = list(
		9,  // SHOES_LAYER_ALT
		10, // UNIFORM_LAYER
		11, // ID_LAYER
		12, // SHOES_LAYER
		13, // GLOVES_LAYER
		14, // BELT_LAYER
		15, // SUIT_LAYER
		17, // GLASSES_LAYER
		18, // BELT_LAYER_ALT
		19, // SUIT_STORE_LAYER
		20, // BACK_LAYER
		25, // FACEMASK_LAYER
		26, // GLASSES_LAYER_ALT
		27  // HEAD_LAYER
	)
	var/original_disable = mannequin.disable_vore_layers
	mannequin.disable_vore_layers = TRUE
	if(!mannequin.dna)
		mannequin.dna = new /datum/dna(null)
	if(mannequin_signature != target_signature)
		copy_preferences_to_mannequin_without_marking(mannequin)
		mannequin_signature = target_signature
		if(!use_stripped_reference && prefs)
			prefs.custom_marking_reference_mannequin_signature = mannequin_signature
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
	clear_mannequin_preview_overlays(mannequin)
	for(var/dir in dirs)
		if(!(dir in missing))
			continue
		CUSTOM_MARKING_CHECK_TICK
		mannequin.set_dir(dir)
		mannequin.ImmediateOverlayUpdate()
		var/list/payload = build_reference_payload_internal(mannequin, dir, width, height)
		if(islist(payload) && prefs && islist(gear_overlay_layers) && gear_overlay_layers.len)
			prefs.dress_preview_mob(mannequin, TRUE, EQUIP_PREVIEW_JOB)
			mannequin.set_dir(dir)
			mannequin.ImmediateOverlayUpdate()
			payload["job_overlay_assets"] = build_overlay_assets_for_layers(mannequin, dir, width, height, gear_overlay_layers)
			mannequin.delete_inventory(TRUE)
			clear_mannequin_preview_overlays(mannequin)
			mannequin.ImmediateOverlayUpdate()
			prefs.dress_preview_mob(mannequin, TRUE, EQUIP_PREVIEW_LOADOUT)
			mannequin.set_dir(dir)
			mannequin.ImmediateOverlayUpdate()
			payload["loadout_overlay_assets"] = build_overlay_assets_for_layers(mannequin, dir, width, height, gear_overlay_layers)
			mannequin.delete_inventory(TRUE)
			clear_mannequin_preview_overlays(mannequin)
			mannequin.ImmediateOverlayUpdate()
		if(islist(payload))
			if(!islist(cache))
				cache = list()
			var/key = reference_payload_key(dir, width, height)
			if(key)
				cache[key] = payload
			updated = TRUE
	mannequin.disable_vore_layers = original_disable
	mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
	mannequin.delete_inventory(TRUE)
	mannequin.ImmediateOverlayUpdate()
	custom_marking_end_manual_yield(yield_context)
	if(use_stripped_reference)
		body_reference_payload_cache = cache
		body_reference_cache_signature = cache_signature
		body_reference_mannequin_signature = mannequin_signature
		body_reference_build_in_progress = FALSE
		process_pending_body_reference_build()
	else
		reference_payload_cache = cache
		reference_cache_signature = cache_signature
		reference_mannequin_signature = mannequin_signature
		reference_build_in_progress = FALSE
		broadcast_reference_build_state(FALSE)
		process_pending_reference_build()
	return updated

// Copy preferences to the mannequin while excluding the current custom marking
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
	ensure_default_tail_style(mannequin)

// Dictionary of tail styles to use with interface
/datum/tgui_module/custom_marking_designer/proc/ensure_default_tail_style(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!mannequin || mannequin.tail_style)
		return
	var/datum/species/species = mannequin.species
	if(!species)
		return
	var/static/list/species_tail_style_map = list(
		/datum/species/sergal = /datum/sprite_accessory/tail/sergaltaildc,
		/datum/species/akula = /datum/sprite_accessory/tail/special/akula,
		/datum/species/nevrean = /datum/sprite_accessory/tail/special/nevrean,
		/datum/species/hi_zoxxen = /datum/sprite_accessory/tail/special/foxdefault,
		/datum/species/fl_zorren = /datum/sprite_accessory/tail/fennec_tail,
		/datum/species/crew_shadekin = /datum/sprite_accessory/tail/shadekin_short,
		/datum/species/shadekin = /datum/sprite_accessory/tail/shadekin_short,
		/datum/species/xenohybrid = /datum/sprite_accessory/tail/xenohybrid_preview,
		/datum/species/xenochimera = /datum/sprite_accessory/tail/xenochimera_preview,
		/datum/species/harpy = /datum/sprite_accessory/tail/fantail,
		/datum/species/spider = /datum/sprite_accessory/tail/special/vasilissan_spiderlegs,
		/datum/species/vox = /datum/sprite_accessory/tail/special/vox
	)
	var/mapping_entry = species_tail_style_map[species.type]
	if(species.type == /datum/species/xenochimera)
		var/base_species_name = species.base_species
		if(istext(base_species_name) && base_species_name && base_species_name != SPECIES_XENOCHIMERA)
			mapping_entry = null
	if(!mapping_entry && istext(species.base_species))
		var/datum/species/base_species = GLOB.all_species?[species.base_species]
		if(istype(base_species))
			mapping_entry = species_tail_style_map[base_species.type]
	if(mapping_entry)
		var/datum/sprite_accessory/tail/default_style = tail_styles_list[mapping_entry]
		if(set_mannequin_tail_style(mannequin, default_style))
			return
	var/tail_state = species.tail
	if(!istext(tail_state) || !length(tail_state))
		return
	var/target_state = "[tail_state]_s"
	for(var/style_path in tail_styles_list)
		var/datum/sprite_accessory/tail/style = tail_styles_list[style_path]
		if(!istype(style))
			continue
		if(style.icon_state != target_state)
			continue
		if(set_mannequin_tail_style(mannequin, style))
			break

// Apply a tail style with default colors for previews
/datum/tgui_module/custom_marking_designer/proc/set_mannequin_tail_style(mob/living/carbon/human/dummy/mannequin/mannequin, datum/sprite_accessory/tail/style)
	if(!mannequin || !istype(style))
		return FALSE
	mannequin.tail_style = style
	mannequin.r_tail = mannequin.r_skin
	mannequin.g_tail = mannequin.g_skin
	mannequin.b_tail = mannequin.b_skin
	mannequin.r_tail2 = mannequin.r_skin
	mannequin.g_tail2 = mannequin.g_skin
	mannequin.b_tail2 = mannequin.b_skin
	mannequin.r_tail3 = mannequin.r_skin
	mannequin.g_tail3 = mannequin.g_skin
	mannequin.b_tail3 = mannequin.b_skin
	return TRUE

// Construct the payload for a single direction using a prepared mannequin
/datum/tgui_module/custom_marking_designer/proc/build_reference_payload_internal(mob/living/carbon/human/dummy/mannequin/mannequin, dir, width, height)
	if(!mannequin)
		return null
	var/icon/body_icon = icon(mannequin.icon, null, dir, 1, 0)
	var/list/body_asset = build_icon_asset(body_icon)
	var/icon/composite_icon = new/icon(body_icon)
	var/list/hidden_body_parts = list()
	if(islist(mannequin.organs))
		var/original_ignore_hide = mannequin.ignore_sprite_accessory_body_hide
		mannequin.ignore_sprite_accessory_body_hide = FALSE
		for(var/obj/item/organ/external/O in mannequin.organs)
			CUSTOM_MARKING_CHECK_TICK
			if(!istype(O))
				continue
			if(!O.is_hidden_by_markings())
				continue
			var/hidden_normalized = null
			if(istext(O.organ_tag) && length(O.organ_tag))
				hidden_normalized = lowertext(O.organ_tag)
			else if(isnum(O.organ_tag))
				hidden_normalized = "[O.organ_tag]"
			if(istext(hidden_normalized) && length(hidden_normalized) && !(hidden_normalized in hidden_body_parts))
				hidden_body_parts += hidden_normalized
		mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
	var/list/overlay_assets = list()
	if(islist(mannequin.overlays_standing))
		for(var/i = 1 to mannequin.overlays_standing.len)
			CUSTOM_MARKING_CHECK_TICK
			if(!should_include_preview_overlay_layer(i))
				continue
			var/entry = mannequin.overlays_standing[i]
			if(!entry)
				continue
			var/list/overlay_icons = list()
			collect_reference_overlays(overlay_icons, entry, dir)
			for(var/icon/overlay_icon as anything in overlay_icons)
				CUSTOM_MARKING_CHECK_TICK
				if(!istype(overlay_icon, /icon))
					continue
				var/is_large_overlay = (overlay_icon.Width() > CUSTOM_MARKING_DEFAULT_WIDTH) || (overlay_icon.Height() > CUSTOM_MARKING_DEFAULT_HEIGHT)
				if(is_large_overlay && (width > CUSTOM_MARKING_DEFAULT_WIDTH || height > CUSTOM_MARKING_DEFAULT_HEIGHT))
					offset_icon_shift(overlay_icon, 8, 0)
				var/list/overlay_asset = build_icon_asset(overlay_icon)
				if(islist(overlay_asset))
					var/list/overlay_entry = list(
						"asset" = overlay_asset,
						"layer" = i
					)
					var/overlay_slot = get_preview_character_overlay_slot(i)
					if(overlay_slot)
						overlay_entry["slot"] = overlay_slot
					overlay_assets += list(overlay_entry)
				if(!is_large_overlay)
					composite_icon.Blend(overlay_icon, ICON_OVERLAY)
	var/list/part_icons = list()
	var/list/part_marking_icons = list()
	var/list/part_order = list()
	var/normalized
	var/icon/directional_icon
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			CUSTOM_MARKING_CHECK_TICK
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
			var/check_digi = istype(O, /obj/item/organ/external/leg) || istype(O, /obj/item/organ/external/foot)
			var/digitigrade = FALSE
			if(check_digi)
				if(O.owner)
					digitigrade = O.owner.digitigrade
				else if(O.dna)
					digitigrade = O.dna.digitigrade
			directional_icon = get_directional_part_icon(O, dir, check_digi ? digitigrade : FALSE, TRUE)
			if(!isicon(directional_icon))
				continue
			if(O.pixel_x || O.pixel_y)
				directional_icon = shift_icon_for_reference(directional_icon, O.pixel_x, O.pixel_y)
			if(!directional_icon)
				continue
			var/icon/marking_overlay = null
			if(islist(O.markings))
				for(var/M in O.markings)
					var/list/mark_data = O.markings[M]
					if(!islist(mark_data) || !mark_data["on"])
						continue
					var/datum/sprite_accessory/marking/mark_style = mark_data["datum"]
					if(!istype(mark_style))
						mark_style = body_marking_styles_list?[M]
					if(!istype(mark_style))
						continue
					if(mark_style.render_above_body)
						continue
					if(check_digi)
						var/acceptance = mark_style.digitigrade_acceptance
						if(!(acceptance & (digitigrade ? MARKING_DIGITIGRADE_ONLY : MARKING_NONDIGI_ONLY)))
							continue
					var/mark_color = mark_data["color"]
					var/icon/mark_icon = get_cached_marking_icon(mark_style, O.organ_tag, mark_color, check_digi ? digitigrade : FALSE)
					if(!isicon(mark_icon))
						continue
					var/icon/mark_directional = icon(mark_icon, null, dir, 1, 0)
					if(!isicon(mark_directional))
						continue
					if(O.pixel_x || O.pixel_y)
						mark_directional = shift_icon_for_reference(mark_directional, O.pixel_x, O.pixel_y)
					if(!mark_directional)
						continue
					if(!marking_overlay)
						marking_overlay = new/icon(mark_directional)
					else
						marking_overlay.Blend(mark_directional, ICON_OVERLAY)
			var/icon/head_eye_overlay = build_reference_head_eye_overlay(O, dir)
			if(head_eye_overlay)
				var/icon/body_with_eyes = new/icon(directional_icon)
				body_with_eyes.Blend(head_eye_overlay, ICON_OVERLAY)
				directional_icon = body_with_eyes
			part_icons[normalized] = directional_icon
			if(marking_overlay)
				part_marking_icons[normalized] = marking_overlay
			if(!(normalized in part_order))
				part_order += normalized
	var/list/part_assets = list()
	var/list/part_marking_assets = list()
	if(islist(part_icons))
		for(var/part in part_icons)
			CUSTOM_MARKING_CHECK_TICK
			var/icon/part_icon = part_icons[part]
			if(!isicon(part_icon))
				continue
			var/list/part_asset = build_icon_asset(part_icon)
			if(islist(part_asset))
				part_assets[part] = part_asset
	if(islist(part_marking_icons))
		for(var/part in part_marking_icons)
			CUSTOM_MARKING_CHECK_TICK
			var/icon/mark_icon = part_marking_icons[part]
			if(!isicon(mark_icon))
				continue
			var/list/mark_asset = build_icon_asset(mark_icon)
			if(islist(mark_asset))
				part_marking_assets[part] = mark_asset
	var/list/composite_asset = build_icon_asset(composite_icon)
	if(islist(composite_asset))
		part_assets["generic"] = composite_asset
	return list(
		"body_asset" = body_asset,
		"composite_asset" = composite_asset,
		"overlay_assets" = overlay_assets,
		"part_assets" = part_assets,
		"part_marking_assets" = part_marking_assets,
		"part_order" = part_order,
		"hidden_body_parts" = hidden_body_parts
	)

// Build overlay assets restricted to a whitelist of layers (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_preview_overlay_slot(layer_index)
	if(!isnum(layer_index))
		return null
	switch(layer_index)
		if(9, 12) // SHOES_LAYER_ALT, SHOES_LAYER
			return "shoes"
		if(10) // UNIFORM_LAYER
			return "uniform"
		if(11) // ID_LAYER
			return "id"
		if(13) // GLOVES_LAYER
			return "gloves"
		if(14, 18) // BELT_LAYER, BELT_LAYER_ALT
			return "belt"
		if(15) // SUIT_LAYER
			return "suit"
		if(17, 26) // GLASSES_LAYER, GLASSES_LAYER_ALT
			return "glasses"
		if(19) // SUIT_STORE_LAYER
			return "suit_store"
		if(20) // BACK_LAYER
			return "back"
		if(25) // FACEMASK_LAYER
			return "mask"
		if(27) // HEAD_LAYER
			return "head"
	return null

// Layer overlay assets (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_overlay_assets_for_layers(mob/living/carbon/human/dummy/mannequin/mannequin, dir, width, height, list/allowed_layers)
	if(!mannequin || !islist(allowed_layers) || !allowed_layers.len)
		return null
	var/list/overlay_assets = list()
	if(islist(mannequin.overlays_standing))
		for(var/i = 1 to mannequin.overlays_standing.len)
			CUSTOM_MARKING_CHECK_TICK
			if(!(i in allowed_layers))
				continue
			var/entry = mannequin.overlays_standing[i]
			if(!entry)
				continue
			var/list/overlay_icons = list()
			collect_reference_overlays(overlay_icons, entry, dir, TRUE)
			if(!overlay_icons.len)
				continue
			var/slot = get_preview_overlay_slot(i)
			for(var/icon/overlay_icon as anything in overlay_icons)
				CUSTOM_MARKING_CHECK_TICK
				if(!istype(overlay_icon, /icon))
					continue
				var/is_large_overlay = (overlay_icon.Width() > CUSTOM_MARKING_DEFAULT_WIDTH) || (overlay_icon.Height() > CUSTOM_MARKING_DEFAULT_HEIGHT)
				if(is_large_overlay && (width > CUSTOM_MARKING_DEFAULT_WIDTH || height > CUSTOM_MARKING_DEFAULT_HEIGHT))
					offset_icon_shift(overlay_icon, 8, 0)
				var/list/overlay_asset = build_icon_asset(overlay_icon)
				if(islist(overlay_asset))
					var/list/overlay_entry = list(
						"asset" = overlay_asset,
						"layer" = i
					)
					if(slot)
						overlay_entry["slot"] = slot
					overlay_assets += list(overlay_entry)
	return overlay_assets.len ? overlay_assets : null

// Compose eye overlays for head references
/datum/tgui_module/custom_marking_designer/proc/build_reference_head_eye_overlay(obj/item/organ/external/O, dir)
	if(!istype(O, /obj/item/organ/external/head))
		return null
	var/obj/item/organ/external/head/head = O
	if(!istype(head))
		return null
	var/mob/living/carbon/human/human = head.owner
	if(!istype(human))
		return null
	var/datum/species/species = human.species
	if(!species)
		return null
	var/should_have_eyes = human.should_have_organ(O_EYES)
	var/has_eye_color = !!(species.appearance_flags & HAS_EYE_COLOR)
	if(!(head.eye_icon && head.eye_icon_location))
		return null
	if(!(should_have_eyes || has_eye_color))
		return null
	var/icon/eyes_icon = new/icon(head.eye_icon_location, head.eye_icon)
	var/obj/item/organ/internal/eyes/eyes = human.internal_organs_by_name[O_EYES]
	if(should_have_eyes)
		if(eyes)
			if(has_eye_color && islist(eyes.eye_colour) && eyes.eye_colour.len >= 3)
				eyes_icon.Blend(rgb(eyes.eye_colour[1], eyes.eye_colour[2], eyes.eye_colour[3]), ICON_ADD)
		else
			eyes_icon.Blend(rgb(128, 0, 0), ICON_ADD)
	else
		eyes_icon.Blend(rgb(human.r_eyes, human.g_eyes, human.b_eyes), ICON_ADD)
	var/icon/directional = icon(eyes_icon, null, dir, 1, 0)
	if(head.pixel_x || head.pixel_y)
		directional = shift_icon_for_reference(directional, head.pixel_x, head.pixel_y)
	return directional

// Convert an icon into a 2D color grid for painting overlays
/datum/tgui_module/custom_marking_designer/proc/get_reference_payload_entry(dir_override = null, use_stripped_reference = FALSE)
	if(!prefs)
		return null
	var/width = get_preview_canvas_width()
	var/height = get_preview_canvas_height()
	if(width <= 0 || height <= 0)
		return null
	var/dir = dir_override
	if(isnull(dir))
		dir = active_dir || NORTH
	ensure_reference_payload_bundle(width, height, use_stripped_reference)
	var/list/cache = use_stripped_reference ? body_reference_payload_cache : reference_payload_cache
	return cache?[reference_payload_key(dir, width, height)]

// Return part order from cached reference payload
/datum/tgui_module/custom_marking_designer/proc/get_reference_part_order(dir_override = null, use_stripped_reference = FALSE)
	var/list/payload = get_reference_payload_entry(dir_override, use_stripped_reference)
	if(!islist(payload))
		return null
	var/list/order = payload["part_order"]
	if(islist(order) && order.len)
		return order
	return null

// Recursively gather icons/images that contribute to the reference sprite
/datum/tgui_module/custom_marking_designer/proc/collect_reference_overlays(list/accum, datum/entry, dir, use_flatten = FALSE)
	if(!entry)
		return
	if(islist(entry))
		for(var/element in entry)
			collect_reference_overlays(accum, element, dir, use_flatten)
		return
	if(isicon(entry))
		var/icon/icon_copy = icon(entry, null, dir, 1, 0)
		accum += new/icon(icon_copy)
		return
	if(istype(entry, /image) || istype(entry, /mutable_appearance))
		var/icon/overlay_icon = reference_icon_from_image(entry, dir, use_flatten)
		if(!overlay_icon)
			return
		var/shift_x = 0
		var/shift_y = 0
		if(isdatum(entry))
			shift_x = entry:pixel_x
			shift_y = entry:pixel_y
		overlay_icon = shift_icon_for_reference(overlay_icon, shift_x, shift_y)
		accum += overlay_icon
		return

// Build directional icon for an organ, respecting gendered/digi rules
/datum/tgui_module/custom_marking_designer/proc/get_directional_part_icon(obj/item/organ/external/O, dir, digitigrade = FALSE, include_hidden = FALSE)
	if(!istype(O))
		return null
	var/original_gendered = O.gendered_icon
	var/force_ungendered = FALSE
	if(original_gendered && !organ_has_gendered_icon_state(O, digitigrade))
		O.gendered_icon = FALSE
		force_ungendered = TRUE
	var/icon/source_icon = O.get_icon()
	if(force_ungendered)
		O.gendered_icon = original_gendered
	if(!isicon(source_icon))
		return null
	var/icon/directional = icon(source_icon, null, dir, 1, 0)
	if(!icon_has_visible_pixels(directional))
		if(include_hidden)
			directional = get_unhidden_part_icon(O, dir, digitigrade)
		if(!icon_has_visible_pixels(directional))
			return null
	return directional

// Get part icon (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_unhidden_part_icon(obj/item/organ/external/O, dir, digitigrade = FALSE)
	if(!istype(O))
		return null
	var/mob/living/carbon/human/human = O.owner
	var/datum/species/species = human?.species
	if(!species)
		return null
	var/icon/icon_reference = resolve_organ_icon_resource(O, species, human, digitigrade)
	if(!icon_reference)
		return null
	var/state_name = O.icon_name
	if(!istext(state_name) || !length(state_name))
		return null
	if(O.gendered_icon && organ_has_gendered_icon_state(O, digitigrade))
		var/gender_suffix = get_organ_gender_suffix(O, human)
		if(istext(gender_suffix) && length(gender_suffix))
			state_name = "[state_name]_[gender_suffix]"
	var/icon/base_icon = icon(icon_reference, state_name, dir, 1, 0)
	if(!isicon(base_icon))
		return null
	O.apply_colouration(base_icon)
	return base_icon

// Check if a gendered icon state exists for an organ
/datum/tgui_module/custom_marking_designer/proc/organ_has_gendered_icon_state(obj/item/organ/external/O, digitigrade)
	if(!istype(O) || !O.gendered_icon)
		return TRUE
	var/mob/living/carbon/human/human = O.owner
	var/datum/species/species = human?.species
	if(!species)
		return TRUE
	var/gender_suffix = get_organ_gender_suffix(O, human)
	var/state_name = "[O.icon_name]_[gender_suffix]"
	if(!length(state_name))
		return TRUE
	var/icon/icon_reference = resolve_organ_icon_resource(O, species, human, digitigrade)
	if(!icon_reference)
		return TRUE
	var/list/state_list = icon_states(icon_reference)
	if(!islist(state_list) || !state_list.len)
		return TRUE
	return state_name in state_list

// Resolve the correct icon file for an organ in previews
/datum/tgui_module/custom_marking_designer/proc/resolve_organ_icon_resource(obj/item/organ/external/O, datum/species/species, mob/living/carbon/human/human, digitigrade)
	if(!istype(O))
		return null
	var/skip_forced_icon = O.skip_robo_icon || (digitigrade && O.digi_prosthetic)
	if(O.force_icon && !skip_forced_icon)
		return O.force_icon
	if((O.robotic >= ORGAN_ROBOT) && !skip_forced_icon)
		return 'icons/mob/human_races/robotic.dmi'
	if(O.is_hidden_by_markings())
		return 'icons/mob/human_races/r_blank.dmi'
	if(!species)
		return null
	if(digitigrade && species.icodigi)
		return species.icodigi
	return species.get_icobase(human, (O.status & ORGAN_MUTATED))

// Pick gender suffix for organ icon states
/datum/tgui_module/custom_marking_designer/proc/get_organ_gender_suffix(obj/item/organ/external/O, mob/living/carbon/human/human)
	if(istype(human) && human.gender == FEMALE)
		return "f"
	if(!istype(human))
		var/datum/dna/organ_dna = null
		if(O)
			organ_dna = O.dna
		if(istype(organ_dna) && organ_dna.GetUIState(DNA_UI_GENDER))
			return "f"
	return "m"

// Basic pixel visibility check for icons
/datum/tgui_module/custom_marking_designer/proc/icon_has_visible_pixels(icon/source)
	if(!isicon(source))
		return FALSE
	var/width = max(1, source.Width())
	var/height = max(1, source.Height())
	for(var/x = 1 to width)
		for(var/y = 1 to height)
			var/pixel = source.GetPixel(x, y)
			if(istext(pixel) && pixel != "#00000000" && length(pixel))
				return TRUE
	return FALSE

// Whitelist specific mannequin overlay indices for previews
/datum/tgui_module/custom_marking_designer/proc/should_include_preview_overlay_layer(layer_index)
	if(!isnum(layer_index))
		return FALSE
	var/static/list/allowed_layers = list(
		1,  // MUTATIONS_LAYER
		2,  // SKIN_LAYER
		3,  // BLOOD_LAYER
		4,  // MOB_DAM_LAYER
		5,  // SURGERY_LAYER
		7,  // TAIL_LOWER_LAYER
		8,  // WING_LOWER_LAYER
		16, // TAIL_UPPER_LAYER
		21, // HAIR_LAYER
		22, // HAIR_ACCESSORY_LAYER
		23, // EARS_LAYER
		24, // EYES_LAYER
		32, // WING_LAYER
		33, // TAIL_UPPER_LAYER_ALT
		34, // MODIFIER_EFFECTS_LAYER
		38, // VORE_BELLY_LAYER
		39, // VORE_TAIL_LAYER
		40  // CUSTOM_MARKING_LAYER
	)
	return layer_index in allowed_layers

// Return slow type(Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_preview_character_overlay_slot(layer_index)
	if(!isnum(layer_index))
		return null
	switch(layer_index)
		if(7)
			return "tail_lower"
		if(8)
			return "wing_lower"
		if(16)
			return "tail_upper"
		if(21)
			return "hair"
		if(22)
			return "hair_accessory"
		if(23)
			return "ears"
		if(24)
			return "eyes"
		if(32)
			return "wing_upper"
		if(33)
			return "tail_upper_alt"
		if(34)
			return "modifier"
		if(38)
			return "vore_belly"
		if(39)
			return "vore_tail"
		if(40)
			return "custom_marking"
	return null

// Gear-specific overlays for optional preview rendering (Lira, Decemeber 2025)
/datum/tgui_module/custom_marking_designer/proc/should_include_gear_overlay_layer(layer_index)
	if(!isnum(layer_index))
		return FALSE
	var/static/list/gear_layers = list(
		9,  // SHOES_LAYER_ALT
		10, // UNIFORM_LAYER
		11, // ID_LAYER
		12, // SHOES_LAYER
		13, // GLOVES_LAYER
		14, // BELT_LAYER
		15, // SUIT_LAYER
		17, // GLASSES_LAYER
		18, // BELT_LAYER_ALT
		19, // SUIT_STORE_LAYER
		20, // BACK_LAYER
		25, // FACEMASK_LAYER
		26, // GLASSES_LAYER_ALT
		27  // HEAD_LAYER
	)
	return layer_index in gear_layers

// Strip blood/damage overlays from mannequin to keep references clean
/datum/tgui_module/custom_marking_designer/proc/clear_mannequin_preview_overlays(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!mannequin)
		return
	var/static/list/layers_to_clear = list(3, 4, 5)
	for(var/index in layers_to_clear)
		if(mannequin.overlays_standing?[index])
			mannequin.remove_layer(index)
			mannequin.overlays_standing[index] = null

// Safely convert an appearance overlay (image/mutable appearance) into an icon for caching
/datum/tgui_module/custom_marking_designer/proc/reference_icon_from_image(var/source, dir, use_flatten = FALSE)
	if(!source || !isdatum(source))
		return null
	var/should_flatten = use_flatten || istype(source, /mutable_appearance)
	if(should_flatten)
		if(isnum(source:alpha) && source:alpha == 0)
			return null
		var/render_dir = dir
		if(!render_dir)
			render_dir = source:dir || SOUTH
		else if(source:dir && (source:dir & (source:dir - 1)) && !(render_dir & (render_dir - 1)))
			render_dir = source:dir
		var/icon/flat_icon = getFlatIcon(source, render_dir, source:icon, source:icon_state, source:blend_mode, TRUE, TRUE)
		if(!isicon(flat_icon))
			return null
		return flat_icon
	if(!istype(source, /image))
		return null
	var/image/img = source
	if(img.alpha == 0)
		return null
	var/icon/base_icon
	var/icon_path = img.icon
	var/icon_state = img.icon_state
	var/render_dir = dir
	if(!render_dir)
		render_dir = img.dir || SOUTH
	else if(img.dir && (img.dir & (img.dir - 1)) && !(render_dir & (render_dir - 1)))
		render_dir = img.dir
	if(icon_path)
		if(isicon(icon_path))
			base_icon = icon(icon_path, null, render_dir, 1, 0)
		else
			base_icon = icon(icon_path, icon_state, render_dir, 1, 0)
	else
		base_icon = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
	if(img.alpha && img.alpha < 255)
		base_icon.Blend(rgb(255, 255, 255, img.alpha), ICON_MULTIPLY)
	if(istext(img.color))
		base_icon.Blend(img.color, ICON_MULTIPLY)
	else if(islist(img.color) && length(img.color) >= 20)
		base_icon.MapColors(arglist(img.color))
	if(islist(img.overlays))
		for(var/overlay in img.overlays)
			var/icon/sub_icon = reference_icon_from_image(overlay, dir)
			if(!sub_icon)
				continue
			var/shift_x = 0
			var/shift_y = 0
			if(isdatum(overlay))
				shift_x = overlay:pixel_x
				shift_y = overlay:pixel_y
			sub_icon = shift_icon_for_reference(sub_icon, shift_x, shift_y)
			base_icon.Blend(sub_icon, ICON_OVERLAY)
	return base_icon

// Retrieve any accumulated pixel shift stored for an icon
/datum/tgui_module/custom_marking_designer/proc/get_icon_shift(icon/source)
	if(!isicon(source))
		return list("x" = 0, "y" = 0)
	if(!islist(icon_shift_map))
		icon_shift_map = list()
	var/ref_id = REF(source)
	if(!istext(ref_id))
		return list("x" = 0, "y" = 0)
	var/list/entry = icon_shift_map?[ref_id]
	if(!islist(entry))
		return list("x" = 0, "y" = 0)
	var/shift_x = entry["x"]
	var/shift_y = entry["y"]
	if(!isnum(shift_x))
		shift_x = 0
	if(!isnum(shift_y))
		shift_y = 0
	return list("x" = shift_x, "y" = shift_y)

// Track pixel shift metadata for cloned icons used in previews
/datum/tgui_module/custom_marking_designer/proc/set_icon_shift(icon/source, shift_x, shift_y)
	if(!isicon(source))
		return
	if(!islist(icon_shift_map))
		icon_shift_map = list()
	var/ref_id = REF(source)
	if(!istext(ref_id))
		return
	if(!isnum(shift_x))
		shift_x = 0
	if(!isnum(shift_y))
		shift_y = 0
	icon_shift_map[ref_id] = list("x" = shift_x, "y" = shift_y)

// Clear stored shift metadata for an icon
/datum/tgui_module/custom_marking_designer/proc/clear_icon_shift(icon/source)
	if(!isicon(source) || !islist(icon_shift_map))
		return
	var/ref_id = REF(source)
	if(!istext(ref_id))
		return
	icon_shift_map -= ref_id

// Set the offset for an icon
/datum/tgui_module/custom_marking_designer/proc/offset_icon_shift(icon/source, delta_x, delta_y)
	if(!isicon(source))
		return
	var/list/existing = get_icon_shift(source)
	var/current_x = isnum(existing?["x"]) ? existing["x"] : 0
	var/current_y = isnum(existing?["y"]) ? existing["y"] : 0
	set_icon_shift(source, current_x + delta_x, current_y + delta_y)

// Apply BYOND pixel offsets to a cloned icon for reference usage
/datum/tgui_module/custom_marking_designer/proc/shift_icon_for_reference(icon/source, shift_x, shift_y)
	if(!istype(source, /icon))
		return null
	var/icon/result = new/icon(source)
	var/pad_left = max(0, -shift_x)
	var/pad_bottom = max(0, -shift_y)
	if(pad_left || pad_bottom)
		var/icon/padded = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
		var/padded_width = max(1, result.Width() + pad_left)
		var/padded_height = max(1, result.Height() + pad_bottom)
		padded.Scale(padded_width, padded_height)
		padded.Blend(result, ICON_OVERLAY, 1 + pad_left, 1 + pad_bottom)
		result = padded
	var/list/original_shift = get_icon_shift(source)
	var/total_shift_x = original_shift["x"]
	var/total_shift_y = original_shift["y"]
	if(shift_x)
		if(shift_x > 0)
			result.Shift(EAST, shift_x)
		else
			result.Shift(WEST, -shift_x)
		total_shift_x += shift_x
	if(shift_y)
		if(shift_y > 0)
			result.Shift(NORTH, shift_y)
		else
			result.Shift(SOUTH, -shift_y)
		total_shift_y += shift_y
	set_icon_shift(result, total_shift_x, total_shift_y)
	return result

// Allocate a unique token for preview assets
/datum/tgui_module/custom_marking_designer/proc/allocate_reference_asset_token()
	if(reference_asset_token_counter >= 1000000)
		reference_asset_token_counter = 0
	reference_asset_token_counter++
	var/key_prefix = state_session_token
	if(!istext(key_prefix) || !length(key_prefix))
		key_prefix = "asset"
	return "[key_prefix]-[reference_asset_token_counter]"

// Bundle icon data as a payload for the client
/datum/tgui_module/custom_marking_designer/proc/build_icon_asset(icon/source)
	if(!isicon(source))
		return null
	var/list/icon_shift = get_icon_shift(source)
	var/shift_x = round(icon_shift?["x"])
	var/shift_y = round(icon_shift?["y"])
	var/list/payload = list(
		"token" = allocate_reference_asset_token(),
		"png" = icon2base64(source),
		"width" = source.Width(),
		"height" = source.Height(),
		"shift_x" = shift_x,
		"shift_y" = shift_y
	)
	clear_icon_shift(source)
	return payload

// Resolve category for a body marking
/datum/tgui_module/custom_marking_designer/proc/get_body_marking_category(marking_id)
	if(!istext(marking_id) || !length(marking_id))
		return "all"
	if(body_marking_heads && (marking_id in body_marking_heads))
		return "heads"
	if(body_marking_bodies && (marking_id in body_marking_bodies))
		return "bodies"
	if(body_marking_limbs && (marking_id in body_marking_limbs))
		return "limbs"
	if(body_marking_addons && (marking_id in body_marking_addons))
		return "addons"
	if(body_marking_skintone && (marking_id in body_marking_skintone))
		return "skintone"
	if(body_marking_teshari && (marking_id in body_marking_teshari))
		return "teshari"
	if(body_marking_vox && (marking_id in body_marking_vox))
		return "vox"
	if(body_marking_augment && (marking_id in body_marking_augment))
		return "augment"
	return "all"

// Helper to pick the default color for a marking
/datum/tgui_module/custom_marking_designer/proc/get_body_marking_default_color(datum/sprite_accessory/marking/style)
	if(istype(style) && !style.do_colouration)
		return "#FFFFFF"
	return "#000000"

// Build icon assets for each covered body part for a marking
/datum/tgui_module/custom_marking_designer/proc/build_marking_part_assets(datum/sprite_accessory/marking/style, dir, digitigrade = FALSE)
	if(!istype(style))
		return null
	var/icon/icon_source = digitigrade && style.digitigrade_icon ? style.digitigrade_icon : style.icon
	if(!icon_source)
		return null
	var/list/result = list()
	for(var/part in style.body_parts)
		CUSTOM_MARKING_CHECK_TICK
		if(!istext(part) || !length(part))
			continue
		var/state_name = "[style.icon_state]-[part]"
		var/list/state_list = icon_states(icon_source)
		if(!islist(state_list) || !(state_name in state_list))
			continue
		var/icon/mark_icon = icon(icon_source, state_name, dir, 1, 0)
		if(!isicon(mark_icon))
			continue
		if(!icon_has_visible_pixels(mark_icon))
			continue
		var/list/asset = build_icon_asset(mark_icon)
		if(!islist(asset))
			continue
		result[part] = asset
	return result

// Build the full set of body marking definitions for the UI
/datum/tgui_module/custom_marking_designer/proc/build_body_marking_definitions()
	if(islist(custom_marking_body_definition_cache))
		return custom_marking_body_definition_cache
	var/list/definitions = list()
	for(var/marking_id in body_marking_styles_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/sprite_accessory/marking/style = body_marking_styles_list[marking_id]
		if(!istype(style))
			continue
		var/list/def = list(
			"id" = marking_id,
			"name" = style.get_display_name(),
			"category" = get_body_marking_category(marking_id),
			"body_parts" = style.body_parts?.Copy() || list(),
			"hide_body_parts" = islist(style.hide_body_parts) ? style.hide_body_parts.Copy() : null,
			"do_colouration" = !!style.do_colouration,
			"color_blend_mode" = style.color_blend_mode,
			"render_above_body" = !!style.render_above_body,
			"render_above_body_parts" = islist(style.render_above_body_parts) ? style.render_above_body_parts.Copy() : null,
			"digitigrade_acceptance" = style.digitigrade_acceptance,
			"hide_from_gallery" = !!style.hide_from_marking_gallery,
			"default_color" = get_body_marking_default_color(style)
		)
		var/list/default_entry = prefs?.mass_edit_marking_list(marking_id, TRUE, TRUE, null, TRUE, def["default_color"])
		if(islist(default_entry))
			def["default_entry"] = default_entry
		var/list/dir_assets = list()
		var/list/dir_digi_assets = list()
		for(var/dir in list(NORTH, SOUTH, EAST, WEST))
			CUSTOM_MARKING_CHECK_TICK
			var/list/assets = build_marking_part_assets(style, dir, FALSE)
			if(islist(assets) && assets.len)
				dir_assets["[dir]"] = assets // numeric keys as associative to avoid sparse index runtimes
			CUSTOM_MARKING_CHECK_TICK
			var/list/digi_assets = build_marking_part_assets(style, dir, TRUE)
			if(islist(digi_assets) && digi_assets.len)
				dir_digi_assets["[dir]"] = digi_assets
		if(dir_assets.len)
			def["assets"] = dir_assets
		if(dir_digi_assets.len)
			def["digitigrade_assets"] = dir_digi_assets
		definitions += list(def)
	custom_marking_body_definition_cache = definitions
	return definitions

// Sanitize an incoming body marking entry from the client
/datum/tgui_module/custom_marking_designer/proc/sanitize_body_marking_entry(marking_id, datum/sprite_accessory/marking/style, list/incoming)
	if(!istext(marking_id) || !istype(style))
		return null
	var/default_color = get_body_marking_default_color(style)
	var/list/base_entry = prefs?.mass_edit_marking_list(marking_id, TRUE, TRUE, null, TRUE, default_color)
	if(!islist(base_entry))
		return null
	if(!islist(incoming))
		return base_entry
	if(incoming["color"])
		if(style.do_colouration)
			base_entry["color"] = sanitize_hexcolor(incoming["color"], default_color)
	for(var/part in incoming)
		if(part == "color")
			continue
		if(!istext(part))
			continue
		if(!(part in style.body_parts))
			continue
		var/list/part_state = base_entry[part]
		if(!islist(part_state))
			part_state = list("on" = TRUE, "color" = default_color)
		var/list/raw_part = incoming[part]
		if(islist(raw_part))
			if("on" in raw_part)
				part_state["on"] = !!raw_part["on"]
			if(style.do_colouration && raw_part["color"])
				part_state["color"] = sanitize_hexcolor(raw_part["color"], default_color)
		base_entry[part] = part_state
	return base_entry

// Reset any in-progress chunked body markings save
/datum/tgui_module/custom_marking_designer/proc/reset_body_marking_chunk_state()
	body_marking_chunk_token = null
	body_marking_chunk_buffer = null
	body_marking_chunk_order = null
	body_marking_chunk_expected = 0
	body_marking_chunk_received = 0

// Merge chunked payload data and return the full payload once complete
/datum/tgui_module/custom_marking_designer/proc/resolve_body_marking_chunk_payload(list/params)
	if(!islist(params))
		reset_body_marking_chunk_state()
		return null
	var/chunk_total = text2num_safe(params?["chunk_total"])
	var/chunk_index = text2num_safe(params?["chunk_index"])
	var/chunk_token = params?["chunk_id"]
	if(!istext(chunk_token) || !chunk_total || chunk_total <= 0 || isnull(chunk_index))
		reset_body_marking_chunk_state()
		return params
	if(chunk_total > 256)
		chunk_total = 256
	if(chunk_token != body_marking_chunk_token)
		reset_body_marking_chunk_state()
		body_marking_chunk_token = chunk_token
	body_marking_chunk_expected = max(body_marking_chunk_expected, chunk_total)
	if(islist(params?["order"]))
		body_marking_chunk_order = params["order"]
	var/list/chunk_map = params?["body_markings"]
	if(islist(chunk_map))
		if(!islist(body_marking_chunk_buffer))
			body_marking_chunk_buffer = list()
		for(var/id in chunk_map)
			if(istext(id))
				body_marking_chunk_buffer[id] = chunk_map[id]
	body_marking_chunk_received = max(body_marking_chunk_received, chunk_index + 1)
	if(body_marking_chunk_expected > 0 && body_marking_chunk_received >= body_marking_chunk_expected)
		var/list/final_map = islist(body_marking_chunk_buffer) ? body_marking_chunk_buffer : list()
		var/list/final_order = islist(body_marking_chunk_order) ? body_marking_chunk_order : list()
		if(!final_order.len && final_map.len)
			for(var/mark_id in final_map)
				final_order += mark_id
		reset_body_marking_chunk_state()
		return list(
			"body_markings" = final_map,
			"order" = final_order
		)
	return BODY_MARKING_CHUNK_PENDING

// Apply a body markings payload coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_body_marking_payload(list/params)
	if(!prefs)
		return FALSE
	var/list/incoming_map = params?["body_markings"]
	if(!islist(incoming_map))
		return FALSE
	var/list/order = params?["order"]
	var/list/ordered_marks = list()
	if(islist(order) && order.len)
		for(var/id in order)
			ordered_marks += id
	else
		for(var/id in incoming_map)
			ordered_marks += id
	var/list/new_payload = list()
	for(var/mark_id in ordered_marks)
		if(new_payload.len >= BODY_MARKING_SELECTION_LIMIT)
			break
		if(!istext(mark_id) || !incoming_map[mark_id])
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list[mark_id]
		if(!istype(style))
			continue
		var/list/sanitized = sanitize_body_marking_entry(mark_id, style, incoming_map[mark_id])
		if(!islist(sanitized))
			continue
		new_payload[mark_id] = sanitized
	prefs.body_markings = new_payload
	prefs.sanitize_body_styles()
	return TRUE

#undef BODY_MARKING_SELECTION_LIMIT
#undef CUSTOM_MARKING_DEFAULT_WIDTH
#undef CUSTOM_MARKING_DEFAULT_HEIGHT
#undef CUSTOM_MARKING_CANVAS_MAX_WIDTH
#undef CUSTOM_MARKING_CANVAS_MAX_HEIGHT
#ifdef CUSTOM_MARKING_CHECK_TICK_DEFINED_IN_DESIGNER
#undef CUSTOM_MARKING_CHECK_TICK
#undef CUSTOM_MARKING_CHECK_TICK_DEFINED_IN_DESIGNER
#endif
