//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Refactored to be more efficient /////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ///////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Schema version for serialized custom marking payloads
#define CUSTOM_MARKING_VERSION 1

// Default canvas resolution for humanoid overlays
#define CUSTOM_MARKING_CANVAS_WIDTH  32
#define CUSTOM_MARKING_CANVAS_HEIGHT 32

// Maximum canvas resolution allowed by the designer
#define CUSTOM_MARKING_CANVAS_MAX_WIDTH 64
#define CUSTOM_MARKING_CANVAS_MAX_HEIGHT 64

// Convenience macro to iterate over cardinal directions in painting payloads
#define CUSTOM_MARKING_DIRECTIONS list(NORTH, SOUTH, EAST, WEST)

// Maximum number of expensive pixel operations we perform before forcing a yield
#define CUSTOM_MARKING_DRAW_BATCH 2048

#define CUSTOM_MARKING_CHECK_TICK custom_marking_yield_heartbeat()

// Option keys stored on datum/custom_marking.options
#define CUSTOM_MARKING_OPTION_RENDER_ON_TOP "render_on_top"
#define CUSTOM_MARKING_OPTION_REPLACE_MAP "replace_parts"
#define CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP "render_priority_parts"
#define CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP "large_canvas_parts"

// Global registry for custom markings, populated at runtime
GLOBAL_LIST_INIT(custom_markings_by_id, list())

// Maps custom marking ids to generated sprite accessory datums
GLOBAL_LIST_INIT(custom_marking_styles, list())

// Display labels for organ tags supported by the custom marking editor
GLOBAL_LIST_INIT(custom_marking_part_labels, list(
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
))

// Replacement helpers: cascade child organs when a parent part is replaced
GLOBAL_LIST_INIT(custom_marking_replacement_children, list(
	BP_L_ARM = list(BP_L_HAND),
	BP_R_ARM = list(BP_R_HAND),
	BP_L_LEG = list(BP_L_FOOT),
	BP_R_LEG = list(BP_R_FOOT)
))

// Throttle custom marking work so large redraws can span multiple ticks via SScustom_marking
/proc/custom_marking_force_yield()
	var/delay = world.tick_lag
	if(delay <= 0)
		delay = 1
	GLOB.custom_marking_yield_epoch++
	stoplag(delay)

// Track yield budget and force pauses when painting work exceeds thresholds
/proc/custom_marking_yield_heartbeat(force = FALSE)
	if(!GLOB.custom_marking_allow_yield)
		return
	if(force)
		GLOB.custom_marking_yield_budget = 0
		custom_marking_force_yield()
		return
	GLOB.custom_marking_yield_budget++
	if(TICK_CHECK || GLOB.custom_marking_yield_budget >= CUSTOM_MARKING_DRAW_BATCH)
		GLOB.custom_marking_yield_budget = 0
		custom_marking_force_yield()

// Temporarily enable yielding for synchronous helpers that aren't running inside SScustom_marking
/proc/custom_marking_begin_manual_yield()
	var/list/context = list(
		"allow" = GLOB.custom_marking_allow_yield,
		"budget" = GLOB.custom_marking_yield_budget
	)
	GLOB.custom_marking_allow_yield = TRUE
	GLOB.custom_marking_yield_budget = 0
	return context

// Restore the previous yield context after manual work
/proc/custom_marking_end_manual_yield(list/context)
	if(!islist(context))
		return
	if("allow" in context)
		GLOB.custom_marking_allow_yield = context["allow"]
	if("budget" in context)
		GLOB.custom_marking_yield_budget = context["budget"]

// Generate unique custom marking id
/proc/generate_custom_marking_id(owner_ckey)
	var/raw = "[owner_ckey]-[world.time]-[rand(1, 1000000000)]-[world.realtime]"
	return lowertext("[owner_ckey]-[md5(raw)]")

// Safely insert an icon state with retry logic to avoid corruption
/proc/custom_marking_insert_icon(icon/target, icon/source, state_name, dir, max_attempts = 3)
	if(!istype(target, /icon) || !istype(source, /icon))
		return null
	if(!istext(state_name) || !length(state_name))
		state_name = "custom_marking"
	var/icon/current_source = source
	var/icon/current_target = target
	for(var/attempt in 1 to max_attempts)
		var/original_allow = GLOB.custom_marking_allow_yield
		GLOB.custom_marking_allow_yield = FALSE
		var/success = FALSE
		try
			current_target.Insert(current_source, state_name, dir)
			success = TRUE
		catch(var/exception/e)
			if(attempt >= max_attempts)
				stack_trace("CustomMarkings: Failed to insert custom marking state [state_name] dir [dir] (attempt [attempt]): [e]")
				GLOB.custom_marking_allow_yield = original_allow
				return current_target
			current_source = new/icon(current_source)
			current_target = new/icon(current_target)
			custom_marking_force_yield()
		GLOB.custom_marking_allow_yield = original_allow
		if(success)
			return current_target
	return current_target

// Generate a fresh id for the marking based on the owner
/datum/custom_marking/proc/reseed_identifier(owner_override = null)
	var/seed_owner = owner_override || owner_ckey || "custom"
	if(!istext(seed_owner) || !length(seed_owner))
		seed_owner = "custom"
	var/new_id = generate_custom_marking_id(seed_owner)
	if(!new_id)
		return FALSE
	if(id && id == new_id)
		return FALSE
	id = new_id
	bake_hash = null
	return TRUE

// Register or update a custom marking style within global accessory lists
/proc/register_custom_marking_style(datum/custom_marking/mark, defer_regeneration = FALSE)
	if(!istype(mark))
		return null
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory(defer_regeneration)
	if(!style)
		return null
	LAZYINITLIST(body_marking_styles_list)
	if(islist(body_marking_styles_list))
		for(var/key in body_marking_styles_list)
			if(body_marking_styles_list[key] == style && key != mark.get_style_name())
				body_marking_styles_list -= key
	var/style_name = mark.get_style_name()
	style.name = style_name
	style.sorting_group = MARKINGS_TATSCAR
	style.genetic = FALSE
	if(mark.owner_ckey)
		style.ckeys_allowed = list(mark.owner_ckey)
	else
		style.ckeys_allowed = null
	style.do_colouration = FALSE
	style.color_blend_mode = ICON_MULTIPLY
	body_marking_styles_list[style_name] = style
	LAZYINITLIST(body_marking_nopersist_list)
	body_marking_nopersist_list[style_name] = style
	LAZYINITLIST(body_marking_addons)
	body_marking_addons[style_name] = style
	var/list/aux_lists = list(body_marking_nopersist_list, body_marking_addons)
	for(var/list/L in aux_lists)
		if(!islist(L))
			continue
		for(var/key in L)
			if(L[key] == style && key != style_name)
				L -= key
	return style

// Remove a custom marking style from global lists
/proc/unregister_custom_marking_style(id)
	if(!id)
		return
	var/datum/sprite_accessory/marking/custom/style = GLOB.custom_marking_styles[id]
	if(!style)
		return
	if(islist(body_marking_styles_list))
		for(var/key in body_marking_styles_list)
			if(body_marking_styles_list[key] == style)
				body_marking_styles_list -= key
	if(islist(body_marking_nopersist_list))
		for(var/key in body_marking_nopersist_list)
			if(body_marking_nopersist_list[key] == style)
				body_marking_nopersist_list -= key
	if(islist(body_marking_addons))
		for(var/key in body_marking_addons)
			if(body_marking_addons[key] == style)
				body_marking_addons -= key
	clear_cached_marking_icons_for_style(style)
	GLOB.custom_marking_styles -= id

// Safe numeric coercion helper
/proc/text2num_safe(value)
	if(isnum(value))
		return value
	if(istext(value))
		return text2num(value)
	return null

// Clamp canvas dimensions to sane bounds
/proc/clamp_custom_marking_dimension(value, default_value, max_value)
	var/result = isnum(value) ? round(value) : default_value
	result = max(1, result)
	result = min(max_value, result)
	return result

// Definition for player-authored custom markings and paint data
/datum/custom_marking
	var/id // Stable identifier, unique within save scope
	var/name // Player-owned display name
	var/owner_ckey // Owning player ckey for administration and clean-up purposes
	var/list/body_parts // Organ tags this marking applies to
	var/list/options // Optional metadata/options
	var/width = CUSTOM_MARKING_CANVAS_WIDTH // Width of painting grids (default 32x32)
	var/height = CUSTOM_MARKING_CANVAS_HEIGHT // Height of painting grids (default 32x32)
	var/list/frames // Dictionary: dir (NORTH/SOUTH/EAST/WEST) => /datum/custom_marking_frame
	var/version = CUSTOM_MARKING_VERSION // Schema version for serialization
	var/bake_hash // Cached hash used to invalidate baked icons when painting changes
	var/style_revision = 0 // Bumped each time the paint payload is persisted


// Produce the user-facing style label derived from the mark id
/datum/custom_marking/proc/get_style_name()
	var/base = name || "Custom Marking"
	var/hash_seed = id || ""
	if(!length(hash_seed))
		hash_seed = "[owner_ckey]-[world.time]"
	var/hash = uppertext(copytext(md5(hash_seed), 1, 7))
	var/revision = isnum(style_revision) ? style_revision : 0
	return "[base] (Custom [hash]-[revision])"

// Initialize a new custom marking with sanitized body part metadata
/datum/custom_marking/New(id, name, list/body_parts, owner_ckey)
	..()
	src.id = id
	src.name = name || "Custom Marking"
	src.owner_ckey = owner_ckey
	src.body_parts = list()
	if(body_parts)
		for(var/part in body_parts)
			if(isnull(part))
				continue
			var/normalized = normalize_part(part)
			if(isnull(normalized))
				continue
			if(!(normalized in src.body_parts))
				src.body_parts += normalized
	if(!src.body_parts.len)
		src.body_parts += BP_TORSO
	src.options = list()
	src.frames = list()
	ensure_part_frames(src.body_parts)

// Resolve arbitrary direction inputs into canonical cardinal constants
/datum/custom_marking/proc/normalize_dir(dir, fallback = NORTH)
	if(isnum(dir) && dir)
		return dir
	if(istext(dir))
		var/parsed = text2num_safe(dir)
		if(parsed)
			return parsed
		switch(lowertext(dir))
			if("north")
				return NORTH
			if("south")
				return SOUTH
			if("east")
				return EAST
			if("west")
				return WEST
	if(!isnull(fallback))
		return fallback
	return null

// Normalize body part identifiers into lowercase string keys
/datum/custom_marking/proc/normalize_part(part, fallback = null)
	var/default = fallback
	if(isnull(default))
		default = "generic"
	if(istext(part))
		if(length(part))
			return lowertext(part)
		return default
	if(isnum(part))
		return "[part]"
	return default

// Split combined direction/part keys into explicit components
/datum/custom_marking/proc/resolve_frame_components(dir, part)
	var/result_dir = normalize_dir(dir, null)
	var/result_part = null
	if(istext(dir) && findtext(dir, "|"))
		var/list/chunks = splittext(dir, "|")
		if(chunks.len)
			result_dir = normalize_dir(chunks[1], null)
		if(isnull(part) && chunks.len >= 2)
			result_part = normalize_part(chunks[2], null)
	if(isnull(result_dir))
		result_dir = normalize_dir(null, NORTH)
	if(isnull(result_part))
		result_part = normalize_part(part, null)
	return list("dir" = result_dir, "part" = normalize_part(result_part, null))

// Build the associative key used to store frame payloads
/datum/custom_marking/proc/frame_key(dir, part = null)
	var/list/info = resolve_frame_components(dir, part)
	return "[info["dir"]]|[info["part"]]"

// Ensure all required frames exist for the given body parts and directions
/datum/custom_marking/proc/ensure_part_frames(list/parts = null)
	if(!islist(frames))
		frames = list()
	var/list/normalized_parts = list()
	if(islist(parts))
		for(var/part in parts)
			if(isnull(part))
				continue
			var/normalized = normalize_part(part, null)
			if(isnull(normalized))
				continue
			if(!(normalized in normalized_parts))
				normalized_parts += normalized
	if(!normalized_parts.len)
		normalized_parts = list("generic")
	else if(!("generic" in normalized_parts))
		normalized_parts += "generic"
	var/list/directions = CUSTOM_MARKING_DIRECTIONS
	if(!islist(directions) || !directions.len)
		directions = list(NORTH, SOUTH, EAST, WEST)
	for(var/dir in directions)
		if(!isnum(dir))
			continue
		for(var/part in normalized_parts)
			ensure_frame(dir, part)
	return TRUE

// Lazily create a painting frame and inherit generic data when needed
/datum/custom_marking/proc/ensure_frame(dir, part = null)
	var/list/info = resolve_frame_components(dir, part)
	var/dir_value = info["dir"]
	var/part_value = info["part"]
	var/key = frame_key(dir_value, part_value)
	if(!islist(frames))
		frames = list()
	var/datum/custom_marking_frame/frame = frames[key]
	var/frame_width = get_part_canvas_width(part_value)
	var/frame_height = get_part_canvas_height(part_value)
	if(istype(frame))
		if(frame.width != frame_width || frame.height != frame_height)
			frame.resize(frame_width, frame_height)
		return frame
	frame = new /datum/custom_marking_frame(frame_width, frame_height)
	if(part_value != "generic")
		var/base_key = frame_key(dir_value, "generic")
		var/datum/custom_marking_frame/base = frames[base_key]
		if(istype(base))
			frame.copy_from(base)
			if(frame.width != frame_width || frame.height != frame_height)
				frame.resize(frame_width, frame_height)
	frames[key] = frame
	return frame

// Retrieve an existing frame, falling back to generic data when allowed
/datum/custom_marking/proc/get_frame(dir, part = null, create = TRUE)
	if(!islist(frames))
		frames = list()
	var/list/info = resolve_frame_components(dir, part)
	var/dir_value = info["dir"]
	var/part_value = info["part"]
	var/key = frame_key(dir_value, part_value)
	var/datum/custom_marking_frame/frame = frames[key]
	if(istype(frame))
		var/frame_width = get_part_canvas_width(part_value)
		var/frame_height = get_part_canvas_height(part_value)
		if(frame.width != frame_width || frame.height != frame_height)
			frame.resize(frame_width, frame_height)
		return frame
	if(!create)
		if(part_value != "generic")
			var/fallback_key = frame_key(dir_value, "generic")
			var/datum/custom_marking_frame/fallback = frames[fallback_key]
			if(istype(fallback))
				return fallback
		return null
	return ensure_frame(dir_value, part_value)

// Resize canvas dimensions and crop/pad existing frames
/datum/custom_marking/proc/resize_canvas(new_width, new_height)
	var/base_width = clamp_custom_marking_dimension(new_width, get_base_canvas_width(), CUSTOM_MARKING_CANVAS_MAX_WIDTH)
	var/base_height = clamp_custom_marking_dimension(new_height, get_base_canvas_height(), CUSTOM_MARKING_CANVAS_MAX_HEIGHT)
	var/changed = (base_width != width) || (base_height != height)
	width = base_width
	height = base_height
	if(!islist(frames))
		frames = list()
	for(var/key in frames)
		var/datum/custom_marking_frame/frame = frames[key]
		if(!istype(frame))
			continue
		var/list/components = resolve_frame_components(key, null)
		var/part = components?["part"]
		var/target_width = get_part_canvas_width(part)
		var/target_height = get_part_canvas_height(part)
		if(frame.resize(target_width, target_height))
			changed = TRUE
	if(changed)
		bump_revision()
	return changed

// Resolve the default canvas width for non-expanded parts
/datum/custom_marking/proc/get_base_canvas_width()
	return clamp_custom_marking_dimension(width, CUSTOM_MARKING_CANVAS_WIDTH, CUSTOM_MARKING_CANVAS_MAX_WIDTH)

// Resolve the default canvas height for non-expanded parts
/datum/custom_marking/proc/get_base_canvas_height()
	return clamp_custom_marking_dimension(height, CUSTOM_MARKING_CANVAS_HEIGHT, CUSTOM_MARKING_CANVAS_MAX_HEIGHT)

// Track which parts should use the expanded 64x64 canvas
/datum/custom_marking/proc/get_canvas_size_map(create = FALSE)
	if(!islist(options))
		if(!create)
			return null
		options = list()
	var/list/map = options[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP]
	if(!islist(map) && create)
		map = list()
		options[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP] = map
	return map

// Determine whether any parts are flagged for the larger canvas
/datum/custom_marking/proc/has_large_canvas_parts()
	var/list/map = options?[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP]
	if(!islist(map) || !map.len)
		return FALSE
	for(var/part in map)
		if(map[part])
			return TRUE
	return FALSE

// Check whether a specific part should use a 64x64 canvas
/datum/custom_marking/proc/is_part_large_canvas(part)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	var/list/map = options?[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP]
	if(!islist(map))
		return FALSE
	return !!map[normalized]

// Resolve the target canvas width for a part
/datum/custom_marking/proc/get_part_canvas_width(part)
	return is_part_large_canvas(part) ? CUSTOM_MARKING_CANVAS_MAX_WIDTH : get_base_canvas_width()

// Resolve the target canvas height for a part
/datum/custom_marking/proc/get_part_canvas_height(part)
	return is_part_large_canvas(part) ? CUSTOM_MARKING_CANVAS_MAX_HEIGHT : get_base_canvas_height()

// Resolve the maximum canvas width needed for the marking
/datum/custom_marking/proc/get_effective_canvas_width()
	var/result = get_base_canvas_width()
	if(has_large_canvas_parts())
		result = max(result, CUSTOM_MARKING_CANVAS_MAX_WIDTH)
	return result

// Resolve the maximum canvas height needed for the marking
/datum/custom_marking/proc/get_effective_canvas_height()
	var/result = get_base_canvas_height()
	if(has_large_canvas_parts())
		result = max(result, CUSTOM_MARKING_CANVAS_MAX_HEIGHT)
	return result

// Determine whether this marking should render on top of all body sprites
/datum/custom_marking/proc/is_render_above_body()
	return !!(islist(options) && options[CUSTOM_MARKING_OPTION_RENDER_ON_TOP])

// Toggle the render priority flag
/datum/custom_marking/proc/set_render_above_body(state)
	if(!islist(options))
		options = list()
	if(state)
		options[CUSTOM_MARKING_OPTION_RENDER_ON_TOP] = TRUE
	else
		options -= CUSTOM_MARKING_OPTION_RENDER_ON_TOP
	var/list/priority_map = options?[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP]
	if(!islist(priority_map) || !priority_map.len)
		return
	var/list/remove_queue = list()
	for(var/key in priority_map)
		if(priority_map[key] == !!state)
			remove_queue += key
	for(var/key in remove_queue)
		priority_map -= key
	if(!priority_map.len)
		options -= CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP

// Accessor for per-part render priority overrides
/datum/custom_marking/proc/get_render_priority_map(create = FALSE)
	if(!islist(options))
		if(!create)
			return null
		options = list()
	var/list/map = options[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP]
	if(!islist(map) && create)
		map = list()
		options[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP] = map
	return map

// Determine whether a part has a render priority override
/datum/custom_marking/proc/is_part_render_priority(part)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	if(is_part_large_canvas(normalized))
		return TRUE
	var/list/map = options?[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP]
	if(!islist(map))
		return is_render_above_body()
	if(!(normalized in map))
		return is_render_above_body()
	return !!map[normalized]

// Toggle a per-part render priority override
/datum/custom_marking/proc/set_part_render_priority(part, state)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	if(!islist(body_parts) || !(normalized in body_parts))
		return FALSE
	var/override_defined = !isnull(state)
	var/force_on_top = is_part_large_canvas(normalized)
	if(force_on_top && override_defined && !state)
		return FALSE
	var/list/map = options?[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP]
	if(!override_defined)
		if(islist(map))
			map -= normalized
			if(!map.len && islist(options))
				options -= CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP
		return TRUE
	map = get_render_priority_map(TRUE)
	map[normalized] = !!state
	return TRUE

// Reset an override to follow the global default
/datum/custom_marking/proc/clear_part_render_priority(part)
	return set_part_render_priority(part, null)

// Build a lookup of parts that should render above the body
/datum/custom_marking/proc/get_render_priority_part_list(copy_list = TRUE)
	var/list/map = options?[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP]
	var/default_state = is_render_above_body()
	var/list/candidates = list()
	if(islist(body_parts))
		for(var/part in body_parts)
			if(!(part in candidates))
				candidates += part
	if(islist(map))
		for(var/entry in map)
			if(!(entry in candidates))
				candidates += entry
	var/list/result = list()
	for(var/part in candidates)
		if(isnull(part) || part == "generic")
			continue
		var/value = islist(map) ? map[part] : null
		var/force_on_top = is_part_large_canvas(part)
		var/on_top = force_on_top ? TRUE : (isnull(value) ? default_state : !!value)
		if(on_top)
			result[part] = TRUE
	return copy_list ? result.Copy() : result

// Present overrides for UI consumption
/datum/custom_marking/proc/get_part_render_priority_payload()
	var/list/map = options?[CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP]
	var/list/size_map = options?[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP]
	if((!islist(map) || !map.len) && (!islist(size_map) || !size_map.len))
		return null
	var/list/result = list()
	if(islist(map))
		for(var/part in map)
			if(isnull(part) || part == "generic")
				continue
			if(!islist(body_parts) || !(part in body_parts))
				continue
			var/force_on_top = is_part_large_canvas(part)
			result[part] = force_on_top ? TRUE : !!map[part]
	if(islist(size_map))
		for(var/part in size_map)
			if(isnull(part) || part == "generic")
				continue
			if(!islist(body_parts) || !(part in body_parts))
				continue
			if(size_map[part])
				result[part] = TRUE
	return result.len ? result : null

// Toggle whether a part should use the expanded 64x64 canvas
/datum/custom_marking/proc/set_part_canvas_size(part, state)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	if(!islist(body_parts) || !(normalized in body_parts))
		return FALSE
	var/use_large = !!state
	var/list/map = get_canvas_size_map(TRUE)
	var/current = !!map[normalized]
	if(use_large)
		map[normalized] = TRUE
	else
		map -= normalized
		if(!map.len && islist(options))
			options -= CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP
	var/changed = (use_large != current)
	if(islist(frames))
		for(var/key in frames)
			var/datum/custom_marking_frame/frame = frames[key]
			if(!istype(frame))
				continue
			var/list/components = resolve_frame_components(key, null)
			var/frame_part = components?["part"]
			if(frame_part != normalized)
				continue
			if(frame.resize(get_part_canvas_width(normalized), get_part_canvas_height(normalized)))
				changed = TRUE
	if(use_large)
		set_part_render_priority(normalized, TRUE)
	else
		set_part_render_priority(normalized, FALSE)
	if(changed)
		bump_revision()
	return changed

// Determine whether any direction for this part spills outside the base canvas
/datum/custom_marking/proc/part_has_pixels_outside_base(part)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	var/base_width = get_base_canvas_width()
	var/base_height = get_base_canvas_height()
	var/list/dirs = CUSTOM_MARKING_DIRECTIONS
	if(!islist(dirs) || !dirs.len)
		dirs = list(NORTH, SOUTH, EAST, WEST)
	for(var/dir in dirs)
		if(!isnum(dir))
			continue
		var/datum/custom_marking_frame/frame = get_frame(dir, normalized, FALSE)
		if(!frame)
			continue
		if(frame.has_pixels_outside_area(base_width, base_height))
			return TRUE
	return FALSE

// Attempt to shrink oversized canvases back to the base size when safe
/datum/custom_marking/proc/shrink_large_parts_if_safe(list/limit_parts = null)
	var/list/map = options?[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP]
	if(!islist(map) || !map.len)
		return FALSE
	var/changed = FALSE
	for(var/part in map)
		if(isnull(part) || part == "generic")
			continue
		if(limit_parts && !(part in limit_parts))
			continue
		if(!map[part])
			continue
		if(part_has_pixels_outside_base(part))
			continue
		if(set_part_canvas_size(part, FALSE))
			changed = TRUE
	return changed

// Present per-part canvas sizing overrides for UI consumption
/datum/custom_marking/proc/get_part_canvas_size_payload()
	var/list/map = options?[CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP]
	if(!islist(map))
		return null
	var/list/result = list()
	for(var/part in map)
		if(isnull(part) || part == "generic")
			continue
		if(islist(body_parts) && !(part in body_parts))
			continue
		if(map[part])
			result[part] = TRUE
	return result.len ? result : null

// Accessor for the replacement map stored inside options
/datum/custom_marking/proc/get_replacement_map(create = FALSE)
	if(!islist(options))
		if(!create)
			return null
		options = list()
	var/list/map = options[CUSTOM_MARKING_OPTION_REPLACE_MAP]
	if(!islist(map) && create)
		map = list()
		options[CUSTOM_MARKING_OPTION_REPLACE_MAP] = map
	return map

// Determine whether a specific part should be replaced entirely by this marking
/datum/custom_marking/proc/is_part_replaced(part)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	var/list/map = options?[CUSTOM_MARKING_OPTION_REPLACE_MAP]
	if(!islist(map))
		return FALSE
	return !!map[normalized]

// Toggle whether a part is replaced by this marking
/datum/custom_marking/proc/set_part_replacement(part, state, cascade = TRUE)
	var/normalized = normalize_part(part, null)
	if(isnull(normalized) || normalized == "generic")
		return FALSE
	if(!islist(body_parts) || !(normalized in body_parts))
		return FALSE
	var/list/map = get_replacement_map(TRUE)
	if(isnull(state))
		if(islist(map))
			map -= normalized
			if(!map.len && islist(options))
				options -= CUSTOM_MARKING_OPTION_REPLACE_MAP
		return TRUE
	map[normalized] = !!state
	if(cascade && islist(GLOB.custom_marking_replacement_children))
		var/list/children = GLOB.custom_marking_replacement_children?[normalized]
		if(islist(children))
			for(var/child in children)
				set_part_replacement(child, state, FALSE)
	return TRUE

// Clear replacement flags for parts that are no longer valid
/datum/custom_marking/proc/clear_part_replacement(part)
	return set_part_replacement(part, null)

// Build a list of organ tags that should be hidden when rendering
/datum/custom_marking/proc/get_replacement_part_list(copy_list = TRUE)
	var/list/map = options?[CUSTOM_MARKING_OPTION_REPLACE_MAP]
	if(!islist(map) || !map.len)
		return list()
	var/list/result = list()
	for(var/part in map)
		if(!map[part])
			continue
		if(part == "generic")
			continue
		if(islist(body_parts) && !(part in body_parts))
			continue
		result += part
	if(copy_list)
		return result.Copy()
	return result

// Present a sanitized payload describing replacement state per part
/datum/custom_marking/proc/get_part_replacement_payload()
	var/list/map = options?[CUSTOM_MARKING_OPTION_REPLACE_MAP]
	if(!islist(map))
		return null
	var/list/result = list()
	for(var/part in map)
		if(isnull(part) || part == "generic")
			continue
		if(islist(body_parts) && !(part in body_parts))
			continue
		result[part] = !!map[part]
	return result.len ? result : list()

// Clear cached bake data so future renders refresh the artwork
/datum/custom_marking/proc/invalidate_bake()
	bake_hash = null
	var/datum/sprite_accessory/marking/custom/style = GLOB.custom_marking_styles[id]
	if(style)
		style.invalidate_cache()
	style = null
	GLOB.custom_marking_styles -= id

// Serialize the marking definition for preference persistence
/datum/custom_marking/proc/to_save()
	var/list/out = list()
	out["id"] = id
	out["name"] = name
	out["owner_ckey"] = owner_ckey
	out["body_parts"] = body_parts?.Copy()
	out["options"] = options?.Copy()
	out["width"] = get_base_canvas_width()
	out["height"] = get_base_canvas_height()
	out["version"] = CUSTOM_MARKING_VERSION
	out["style_revision"] = style_revision
	var/list/frame_payload = list()
	if(islist(frames))
		for(var/dir_key in frames)
			var/datum/custom_marking_frame/frame = frames[dir_key]
			if(!istype(frame))
				continue
			var/list/components = resolve_frame_components(dir_key, null)
			if(!islist(components))
				continue
			var/part_name = components["part"]
			if(part_name == "generic")
				continue
			var/save_key = frame_key(dir_key)
			frame_payload[save_key] = frame?.to_save()
	out["frames"] = frame_payload
	return out

// Rehydrate a marking definition from stored preference data
/datum/custom_marking/proc/from_save(list/data)
	if(!islist(data))
		return
	id = data["id"]
	name = data["name"] || "Custom Marking"
	owner_ckey = data["owner_ckey"]
	var/list/raw_parts = data["body_parts"]
	body_parts = list()
	if(islist(raw_parts))
		for(var/part in raw_parts)
			if(isnull(part))
				continue
			var/normalized = normalize_part(part)
			if(isnull(normalized))
				continue
			if(!(normalized in body_parts))
				body_parts += normalized
	if(!body_parts.len)
		body_parts += BP_TORSO
	options = data["options"] ? data["options"] : list()
	width = clamp_custom_marking_dimension(data["width"], CUSTOM_MARKING_CANVAS_WIDTH, CUSTOM_MARKING_CANVAS_MAX_WIDTH)
	height = clamp_custom_marking_dimension(data["height"], CUSTOM_MARKING_CANVAS_HEIGHT, CUSTOM_MARKING_CANVAS_MAX_HEIGHT)
	version = data["version"] || 0
	style_revision = text2num_safe(data["style_revision"]) || 0
	var/list/frame_payload = data["frames"]
	frames = list()
	if(islist(frame_payload))
		for(var/dir_key in frame_payload)
			var/list/components = resolve_frame_components(dir_key, null)
			if(!islist(components))
				continue
			var/part_name = components["part"]
			if(part_name == "generic")
				continue
			var/list/raw = frame_payload[dir_key]
			if(!islist(raw))
				continue
			var/datum/custom_marking_frame/frame = new(get_part_canvas_width(part_name), get_part_canvas_height(part_name))
			frame.from_save(raw)
			var/save_key = frame_key(dir_key)
			frames[save_key] = frame
	ensure_part_frames(body_parts)
	if(version < CUSTOM_MARKING_VERSION)
		upgrade(version)
	version = CUSTOM_MARKING_VERSION

// Provide a hook for upgrading serialized payloads between versions
/datum/custom_marking/proc/upgrade(old_version)
	// Placeholder for future migration hooks
	return

// Bump the style revision to force downstream caches to pick up new icon states
/datum/custom_marking/proc/bump_revision()
	if(!isnum(style_revision))
		style_revision = 0
	style_revision++
	invalidate_bake()

// Insert the marking into runtime registries for immediate use
/datum/custom_marking/proc/register()
	if(!id)
		CRASH("custom_marking lacks id")
	GLOB.custom_markings_by_id[id] = src
	register_custom_marking_style(src)
	return id

// Pixel check
/datum/custom_marking/proc/has_visible_pixels()
	if(!islist(frames) || !frames.len)
		return FALSE
	for(var/key in frames)
		var/datum/custom_marking_frame/frame = frames[key]
		if(frame?.has_visible_pixels())
			return TRUE
	return FALSE

// Return the runtime sprite_accessory associated with this marking
/datum/custom_marking/proc/ensure_sprite_accessory(defer_regeneration = FALSE)
	if(!id)
		return null
	var/datum/sprite_accessory/marking/custom/style = GLOB.custom_marking_styles[id]
	if(!style)
		style = new /datum/sprite_accessory/marking/custom(src, defer_regeneration)
	else
		style.source = src
	style.update_registration(!defer_regeneration)
	GLOB.custom_marking_styles[id] = style
	return style

// Track layered pixel data and caches for a single direction view
/datum/custom_marking_frame
	var/width
	var/height
	var/list/layers
	var/list/composite_cache

// Initialize frame dimensions and allocate default layers
/datum/custom_marking_frame/New(width = CUSTOM_MARKING_CANVAS_WIDTH, height = CUSTOM_MARKING_CANVAS_HEIGHT)
	..()
	src.width = isnum(width) ? max(1, round(width)) : CUSTOM_MARKING_CANVAS_WIDTH
	src.height = isnum(height) ? max(1, round(height)) : CUSTOM_MARKING_CANVAS_HEIGHT
	reset()

// Allocate an empty column-major grid for one paint layer
/datum/custom_marking_frame/proc/build_layer()
	var/list/layer = list()
	layer.len = width
	for(var/x in 1 to width)
		var/list/column = list()
		column.len = height
		layer[x] = column
	return layer

// Rebuild paint layer and clear caches
/datum/custom_marking_frame/proc/reset()
	layers = list()
	layers.len = 1
	for(var/i in 1 to layers.len)
		layers[i] = build_layer()
	invalidate()

// Frame pixel check
/datum/custom_marking_frame/proc/has_visible_pixels()
	if(!islist(layers))
		return FALSE
	for(var/list/layer in layers)
		if(!islist(layer))
			continue
		for(var/list/column in layer)
			if(!islist(column))
				continue
			for(var/pixel in column)
				if(istext(pixel) && length(pixel))
					return TRUE
	return FALSE

// Check whether any painted pixels live outside a target area
/datum/custom_marking_frame/proc/has_pixels_outside_area(base_width, base_height)
	if(!isnum(base_width) || !isnum(base_height))
		return FALSE
	var/target_width = round(base_width)
	var/target_height = round(base_height)
	if(target_width >= width && target_height >= height)
		return FALSE
	var/x_offset = round((width - target_width) / 2)
	if(x_offset < 0)
		x_offset = 0
	var/min_x = max(1, 1 + x_offset)
	var/max_x = min(width, target_width + x_offset)
	var/min_y = 1
	var/max_y = min(height, target_height)
	if(min_x <= 1 && max_x >= width && min_y <= 1 && max_y >= height)
		return FALSE
	if(!islist(layers))
		return FALSE
	for(var/list/layer in layers)
		if(!islist(layer))
			continue
		for(var/x in 1 to width)
			CUSTOM_MARKING_CHECK_TICK
			var/list/column = layer[x]
			if(!islist(column))
				continue
			for(var/y in 1 to height)
				var/pixel = column[y]
				if(!istext(pixel) || !length(pixel))
					continue
				if(x < min_x || x > max_x || y < min_y || y > max_y)
					return TRUE
	return FALSE

// Copy pixel payloads from another frame into this one
/datum/custom_marking_frame/proc/copy_from(datum/custom_marking_frame/other)
	if(!istype(other))
		return
	width = other.width
	height = other.height
	reset()
	var/list/source_layer = other.ensure_layer(1)
	var/list/target_layer = ensure_layer(1)
	for(var/x in 1 to width)
		CUSTOM_MARKING_CHECK_TICK
		for(var/y in 1 to height)
			target_layer[x][y] = source_layer[x][y]
	invalidate()

// Guarantee that a requested layer exists with proper sizing
/datum/custom_marking_frame/proc/ensure_layer(layer_index)
	if(layer_index < 1)
		layer_index = 1
	if(!islist(layers))
		layers = list()
	var/expected_len = max(1, layer_index)
	if(layers.len < expected_len)
		layers.len = expected_len
	if(layer_index > layers.len || !islist(layers[layer_index]))
		layers[layer_index] = build_layer()
	var/list/layer = layers[layer_index]
	if(layer.len != width)
		layers[layer_index] = build_layer()
		layer = layers[layer_index]
	for(var/x in 1 to width)
		var/list/column = layer[x]
		if(!islist(column) || column.len != height)
			var/list/new_column = list()
			new_column.len = height
			if(islist(column))
				for(var/y in 1 to min(height, column.len))
					new_column[y] = column[y]
			layer[x] = new_column
	return layer

// Resize the frame while preserving overlapping pixels
/datum/custom_marking_frame/proc/resize(new_width, new_height)
	var/target_width = isnum(new_width) ? max(1, round(new_width)) : width
	var/target_height = isnum(new_height) ? max(1, round(new_height)) : height
	if(target_width == width && target_height == height)
		return FALSE
	var/original_width = width
	if(!islist(layers))
		reset()
	if(!islist(layers))
		return FALSE
	var/x_offset = round((target_width - original_width) / 2)
	var/y_offset = 0
	var/list/new_layers = list()
	new_layers.len = max(1, layers.len)
	for(var/i in 1 to new_layers.len)
		var/list/source_layer = ensure_layer(i)
		var/list/new_layer = list()
		new_layer.len = target_width
		for(var/x in 1 to target_width)
			var/list/new_column = list()
			new_column.len = target_height
			var/source_x = x - x_offset
			if(source_x >= 1 && source_x <= source_layer.len)
				var/list/source_column = source_layer[source_x]
				if(islist(source_column))
					for(var/y in 1 to target_height)
						var/source_y = y - y_offset
						if(source_y < 1 || source_y > source_column.len)
							continue
						new_column[y] = source_column[source_y]
			new_layer[x] = new_column
		new_layers[i] = new_layer
	layers = new_layers
	width = target_width
	height = target_height
	invalidate()
	return TRUE

// Fetch the stored color at a coordinate from a given layer
/datum/custom_marking_frame/proc/get_pixel(x, y, layer_index = 1)
	var/list/layer = ensure_layer(layer_index)
	if(x < 1 || x > width || y < 1 || y > height)
		return null
	return layer[x][y]

// Write a color value into the specified layer cell
/datum/custom_marking_frame/proc/set_pixel(x, y, color, layer_index = 1)
	if(x < 1 || x > width || y < 1 || y > height)
		return
	var/list/layer = ensure_layer(layer_index)
	layer[x][y] = color
	invalidate()

// Update the cached composite value for a single coordinate
/datum/custom_marking_frame/proc/update_composite_pixel(x, y)
	if(x < 1 || x > width || y < 1 || y > height)
		return
	if(!islist(composite_cache))
		return
	if(composite_cache.len < x || !islist(composite_cache[x]))
		var/list/new_column = new/list(height)
		if(composite_cache.len < x)
			composite_cache.len = width
		composite_cache[x] = new_column
	var/list/cache_column = composite_cache[x]
	if(cache_column.len < y)
		cache_column.len = height
	var/value = null
	for(var/i in length(layers) to 1 step -1)
		var/list/grid = layers[i]
		if(!islist(grid))
			continue
		var/list/column = grid[x]
		if(!islist(column))
			continue
		var/pixel = column[y]
		if(!isnull(pixel))
			value = pixel
			break
	cache_column[y] = value

// Mark composite caches dirty after edits
/datum/custom_marking_frame/proc/invalidate()
	composite_cache = null

// Serialize all layers so they can be saved with preferences
/datum/custom_marking_frame/proc/to_save()
	var/list/out = list()
	out["layers"] = layers
	return out

// Restore paint layers from serialized preference data
/datum/custom_marking_frame/proc/from_save(list/data)
	if(!islist(data))
		return
	var/list/new_layers = data["layers"]
	if(islist(new_layers))
		if(islist(new_layers[1]))
			layers = list()
			layers.len = 1
			layers[1] = new_layers[1]
		else
			reset()
	else
		reset()
	// Ensure structural integrity
	for(var/i in 1 to max(1, layers.len))
		ensure_layer(i)
	invalidate()

// Build or return the cached flattened pixel grid for rendering
/datum/custom_marking_frame/proc/get_composite()
	if(composite_cache)
		return composite_cache
	var/list/result = new/list(width)
	for(var/x in 1 to width)
		CUSTOM_MARKING_CHECK_TICK
		result[x] = new/list(height)
		for(var/y in 1 to height)
			CUSTOM_MARKING_CHECK_TICK
			for(var/i in length(layers) to 1 step -1)
				var/list/Grid = layers[i]
				if(!islist(Grid))
					continue
				var/list/Column = Grid[x]
				if(!islist(Column))
					continue
				var/pixel = Column[y]
				if(!isnull(pixel))
					result[x][y] = pixel
					break
	if(!composite_cache)
		composite_cache = result
	return result

// Runtime sprite accessory that references a custom marking datum
/datum/sprite_accessory/marking/custom
	name = "Custom Marking"
	icon = null
	icon_state = null
	color_blend_mode = ICON_MULTIPLY
	body_parts = list()
	hide_from_marking_gallery = TRUE
	digitigrade_acceptance = MARKING_ALL_LEGS
	var/datum/custom_marking/source
	var/icon/generated_icon
	var/cache_hash

// Custom marking display name
/datum/sprite_accessory/marking/custom/get_display_name()
	return "Custom Marking Layer"

// Bind the sprite accessory to a specific custom marking datum
/datum/sprite_accessory/marking/custom/New(datum/custom_marking/source, defer_regeneration = FALSE)
	src.source = source
	src.body_parts = source?.body_parts?.Copy() || list()
	update_registration(!defer_regeneration)

// Keep the sprite accessory metadata in sync with the source datum
/datum/sprite_accessory/marking/custom/proc/update_registration(regenerate = TRUE)
	if(!source)
		return
	name = "[source.name]"
	body_parts = source.body_parts?.Copy() || list()
	render_above_body = source.is_render_above_body()
	render_above_body_parts = source.get_render_priority_part_list()
	hide_body_parts = source.get_replacement_part_list()
	if(regenerate)
		regenerate_if_needed()

// Generate a stable hash representing the current painting payload
/datum/sprite_accessory/marking/custom/proc/get_cache_key()
	if(source?.bake_hash)
		return source.bake_hash
	var/hash_input = list(source?.id, source?.name, source?.get_effective_canvas_width(), source?.get_effective_canvas_height())
	var/list/parts = source?.body_parts?.Copy() || list()
	hash_input += list(list("parts" = parts))
	var/list/hash_dirs = CUSTOM_MARKING_DIRECTIONS
	for(var/dir in hash_dirs)
		CUSTOM_MARKING_CHECK_TICK
		if(parts.len)
			for(var/part in parts)
				var/datum/custom_marking_frame/frame = source.get_frame(dir, part, FALSE)
				if(!frame)
					frame = source.get_frame(dir, null, FALSE)
				hash_input += list(list(dir, part, frame?.layers))
		else
			var/datum/custom_marking_frame/generic_frame = source.get_frame(dir, null, FALSE)
			hash_input += list(list(dir, "generic", generic_frame?.layers))
	source.bake_hash = md5(json_encode(hash_input))
	return source.bake_hash

// Rebuild the backing icon file when the cached hash changes
/datum/sprite_accessory/marking/custom/proc/regenerate_if_needed()
	if(!source || !source.id)
		generated_icon = null
		icon = null
		digitigrade_icon = null
		icon_state = null
		preview_state = null
		cache_hash = null
		return
	var/new_hash = get_cache_key()
	if(cache_hash && cache_hash == new_hash && generated_icon)
		return
	cache_hash = new_hash
	var/hash_suffix = cache_hash ? copytext(cache_hash, 1, 9) : "00000000"
	var/base_state = "custom_[source.id]_[hash_suffix]"
	generated_icon = build_composite_icon(base_state)
	if(!generated_icon)
		icon = null
		digitigrade_icon = null
		icon_state = null
		preview_state = null
		return
	icon = generated_icon
	digitigrade_icon = generated_icon
	icon_state = base_state
	var/list/preview_parts = source.body_parts?.Copy()
	var/preview_suffix = (preview_parts && preview_parts.len) ? preview_parts[1] : "generic"
	if(!istext(preview_suffix) || !length(preview_suffix))
		preview_suffix = "generic"
	preview_state = "[base_state]-[preview_suffix]"

// Bake per-direction icon states for the custom paint job
/datum/sprite_accessory/marking/custom/proc/build_composite_icon(base_state)
	var/original_allow = GLOB.custom_marking_allow_yield
	var/icon/result = null
	if(!source || !source.id)
		GLOB.custom_marking_allow_yield = original_allow
		return result
	var/desired_width = source?.get_effective_canvas_width() || CUSTOM_MARKING_CANVAS_WIDTH
	if(!isnum(desired_width) || desired_width < 1)
		desired_width = CUSTOM_MARKING_CANVAS_WIDTH
	var/desired_height = source?.get_effective_canvas_height() || CUSTOM_MARKING_CANVAS_HEIGHT
	if(!isnum(desired_height) || desired_height < 1)
		desired_height = CUSTOM_MARKING_CANVAS_HEIGHT
	var/list/render_queue = list()
	for(var/dir in CUSTOM_MARKING_DIRECTIONS)
		CUSTOM_MARKING_CHECK_TICK
		var/list/parts = source.body_parts?.Copy()
		if(!parts || !parts.len)
			parts = list(null)
		for(var/part in parts)
			CUSTOM_MARKING_CHECK_TICK
			var/datum/custom_marking_frame/frame = source.get_frame(dir, part)
			if(!frame)
				continue
			var/list/grid = frame.get_composite()
			if(!islist(grid))
				continue
			var/state_name = part ? "[base_state]-[part]" : "[base_state]-generic"
			render_queue += list(list("dir" = dir, "grid" = grid, "state" = state_name))
	var/restore_allow = original_allow
	GLOB.custom_marking_allow_yield = FALSE
	try
		result = icon('icons/mob/human_races/markings.dmi', "blank")
		result.Scale(desired_width, desired_height)
		var/target_width = result.Width()
		var/target_height = result.Height()
		if(target_width < 1)
			target_width = CUSTOM_MARKING_CANVAS_WIDTH
		if(target_height < 1)
			target_height = CUSTOM_MARKING_CANVAS_HEIGHT
		for(var/list/job in render_queue)
			var/job_dir = job?["dir"]
			var/list/job_grid = job?["grid"]
			var/job_state = job?["state"]
			if(!islist(job_grid) || !istext(job_state))
				continue
			var/icon/new_result = render_custom_marking_state(result, job_grid, job_state, job_dir, target_width, target_height)
			if(istype(new_result, /icon))
				result = new_result
	catch(var/exception/e)
		GLOB.custom_marking_allow_yield = restore_allow
		throw e
	GLOB.custom_marking_allow_yield = restore_allow
	return result

// Render a single directional state into the composite icon
/datum/sprite_accessory/marking/custom/proc/render_custom_marking_state(icon/target, list/grid, state_name, dir, target_width, target_height)
	if(!istype(target, /icon) || !islist(grid))
		return target
	if(target_width < 1 || target_height < 1)
		return target
	var/original_allow = GLOB.custom_marking_allow_yield
	GLOB.custom_marking_allow_yield = TRUE
	var/icon/frame_icon = icon('icons/mob/human_races/markings.dmi', "blank")
	frame_icon.Scale(target_width, target_height)
	var/icon/current_target = target
	var/last_yield_epoch = GLOB.custom_marking_yield_epoch
	var/grid_width = grid.len
	var/x_offset = max(0, round((target_width - grid_width) / 2))
	var/y_offset = 0 // keep the bottom of smaller canvases aligned so 32x32 parts don't shift when mixed with 64x64
	try
		for(var/x in 1 to grid_width)
			CUSTOM_MARKING_CHECK_TICK
			if(last_yield_epoch != GLOB.custom_marking_yield_epoch)
				frame_icon = new/icon(frame_icon)
				current_target = new/icon(current_target)
				last_yield_epoch = GLOB.custom_marking_yield_epoch
			var/list/column = grid[x]
			if(!islist(column))
				continue
			var/draw_x = x + x_offset
			if(draw_x < 1 || draw_x > target_width)
				continue
			for(var/y in 1 to column.len)
				CUSTOM_MARKING_CHECK_TICK
				if(last_yield_epoch != GLOB.custom_marking_yield_epoch)
					frame_icon = new/icon(frame_icon)
					current_target = new/icon(current_target)
					last_yield_epoch = GLOB.custom_marking_yield_epoch
				var/draw_y = y + y_offset
				if(draw_y < 1 || draw_y > target_height)
					continue
				var/color = column[y]
				if(!istext(color))
					continue
				frame_icon.DrawBox(color, draw_x, draw_y, draw_x, draw_y)
		if(frame_icon.Width() != target_width || frame_icon.Height() != target_height)
			frame_icon.Scale(target_width, target_height)
		current_target = custom_marking_insert_icon(current_target, frame_icon, state_name, dir, 3)
		if(!istype(current_target, /icon))
			return target
		if(last_yield_epoch != GLOB.custom_marking_yield_epoch)
			frame_icon = new/icon(frame_icon)
			current_target = new/icon(current_target)
			last_yield_epoch = GLOB.custom_marking_yield_epoch
	catch(var/exception/e)
		GLOB.custom_marking_allow_yield = original_allow
		throw e
	GLOB.custom_marking_allow_yield = original_allow
	return current_target

// Clear generated icon caches so they rebuild on next use.
/datum/sprite_accessory/marking/custom/proc/invalidate_cache()
	cache_hash = null
	generated_icon = null
	clear_cached_marking_icons_for_style(src)

#undef CUSTOM_MARKING_VERSION
#undef CUSTOM_MARKING_CANVAS_WIDTH
#undef CUSTOM_MARKING_CANVAS_HEIGHT
#undef CUSTOM_MARKING_DIRECTIONS
#undef CUSTOM_MARKING_DRAW_BATCH
#undef CUSTOM_MARKING_CHECK_TICK
#undef CUSTOM_MARKING_OPTION_RENDER_ON_TOP
#undef CUSTOM_MARKING_OPTION_REPLACE_MAP
#undef CUSTOM_MARKING_OPTION_RENDER_PRIORITY_MAP
#undef CUSTOM_MARKING_OPTION_LARGE_CANVAS_MAP
