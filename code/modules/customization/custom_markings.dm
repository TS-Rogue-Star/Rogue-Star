//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Schema version for serialized custom marking payloads
#define CUSTOM_MARKING_VERSION 1

// Default canvas resolution for humanoid overlays
#define CUSTOM_MARKING_CANVAS_WIDTH  32
#define CUSTOM_MARKING_CANVAS_HEIGHT 32

// Convenience macro to iterate over cardinal directions in painting payloads
#define CUSTOM_MARKING_DIRECTIONS list(NORTH, SOUTH, EAST, WEST)

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

// Generate unique custom marking id
/proc/generate_custom_marking_id(owner_ckey)
	var/raw = "[owner_ckey]-[world.time]-[rand(1, 1000000000)]-[world.realtime]"
	return lowertext("[owner_ckey]-[md5(raw)]")

// Register or update a custom marking style within global accessory lists
/proc/register_custom_marking_style(datum/custom_marking/mark)
	if(!istype(mark))
		return null
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory()
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

// Lazily create a painting frame and inherit generic data when needed
/datum/custom_marking/proc/ensure_frame(dir, part = null)
	var/list/info = resolve_frame_components(dir, part)
	var/dir_value = info["dir"]
	var/part_value = info["part"]
	var/key = frame_key(dir_value, part_value)
	if(!islist(frames))
		frames = list()
	var/datum/custom_marking_frame/frame = frames[key]
	if(!istype(frame))
		var/frame_width = isnum(width) ? max(1, round(width)) : CUSTOM_MARKING_CANVAS_WIDTH
		var/frame_height = isnum(height) ? max(1, round(height)) : CUSTOM_MARKING_CANVAS_HEIGHT
		frame = new /datum/custom_marking_frame(frame_width, frame_height)
		if(part_value != "generic")
			var/base_key = frame_key(dir_value, "generic")
			var/datum/custom_marking_frame/base = frames[base_key]
			if(istype(base))
				frame.copy_from(base)
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
		return frame
	if(!create)
		if(part_value != "generic")
			var/fallback_key = frame_key(dir_value, "generic")
			var/datum/custom_marking_frame/fallback = frames[fallback_key]
			if(istype(fallback))
				return fallback
		return null
	return ensure_frame(dir_value, part_value)

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
	out["width"] = width
	out["height"] = height
	out["version"] = CUSTOM_MARKING_VERSION
	out["style_revision"] = style_revision
	var/list/frame_payload = list()
	if(islist(frames))
		for(var/dir_key in frames)
			var/datum/custom_marking_frame/frame = frames[dir_key]
			if(!istype(frame))
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
	width = max(1, text2num_safe(data["width"]) || CUSTOM_MARKING_CANVAS_WIDTH)
	height = max(1, text2num_safe(data["height"]) || CUSTOM_MARKING_CANVAS_HEIGHT)
	version = data["version"] || 0
	style_revision = text2num_safe(data["style_revision"]) || 0
	var/list/frame_payload = data["frames"]
	frames = list()
	if(islist(frame_payload))
		for(var/dir_key in frame_payload)
			var/list/raw = frame_payload[dir_key]
			if(!islist(raw))
				continue
			var/datum/custom_marking_frame/frame = new(width, height)
			frame.from_save(raw)
			var/save_key = frame_key(dir_key)
			frames[save_key] = frame
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

// Rebuild every paint layer and clear caches
/datum/custom_marking_frame/proc/reset()
	layers = list()
	layers.len = 3
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

// Copy pixel payloads from another frame into this one
/datum/custom_marking_frame/proc/copy_from(datum/custom_marking_frame/other)
	if(!istype(other))
		return
	width = other.width
	height = other.height
	reset()
	var/max_layers = max(layers.len, other.layers?.len || 0)
	for(var/i in 1 to max_layers)
		var/list/source_layer = other.ensure_layer(i)
		var/list/target_layer = ensure_layer(i)
		for(var/x in 1 to width)
			for(var/y in 1 to height)
				target_layer[x][y] = source_layer[x][y]
	invalidate()

// Guarantee that a requested layer exists with proper sizing
/datum/custom_marking_frame/proc/ensure_layer(layer_index)
	if(layer_index < 1)
		layer_index = 1
	if(!islist(layers))
		layers = list()
	var/expected_len = max(3, layer_index)
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
		layers = new_layers
	else
		reset()
	// Ensure structural integrity
	for(var/i in 1 to max(3, layers.len))
		ensure_layer(i)
	invalidate()

// Build or return the cached flattened pixel grid for rendering
/datum/custom_marking_frame/proc/get_composite()
	if(composite_cache)
		return composite_cache
	var/list/result = new/list(width)
	for(var/x in 1 to width)
		result[x] = new/list(height)
		for(var/y in 1 to height)
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
	if(regenerate)
		regenerate_if_needed()

// Generate a stable hash representing the current painting payload
/datum/sprite_accessory/marking/custom/proc/get_cache_key()
	if(source?.bake_hash)
		return source.bake_hash
	var/hash_input = list(source?.id, source?.name, source?.width, source?.height)
	var/list/parts = source?.body_parts?.Copy() || list()
	hash_input += list(list("parts" = parts))
	var/list/hash_dirs = CUSTOM_MARKING_DIRECTIONS
	for(var/dir in hash_dirs)
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
	if(!source || !source.id)
		return null
	var/icon/result = icon('icons/mob/human_races/markings.dmi', "blank")
	result.Scale(source.width, source.height)
	for(var/dir in CUSTOM_MARKING_DIRECTIONS)
		var/list/parts = source.body_parts?.Copy()
		if(!parts || !parts.len)
			parts = list(null)
		for(var/part in parts)
			var/datum/custom_marking_frame/frame = source.get_frame(dir, part)
			if(!frame)
				continue
			var/list/grid = frame.get_composite()
			if(!islist(grid))
				continue
			var/icon/frame_icon = icon('icons/mob/human_races/markings.dmi', "blank")
			frame_icon.Scale(source.width, source.height)
			for(var/x in 1 to source.width)
				for(var/y in 1 to source.height)
					var/color = grid[x][y]
					if(!istext(color))
						continue
					frame_icon.DrawBox(color, x, y, x, y)
			var/state_name = part ? "[base_state]-[part]" : "[base_state]-generic"
			result.Insert(frame_icon, state_name, dir)
	return result

// Clear generated icon caches so they rebuild on next use.
/datum/sprite_accessory/marking/custom/proc/invalidate_cache()
	cache_hash = null
	generated_icon = null
	clear_cached_marking_icons_for_style(src)

#undef CUSTOM_MARKING_VERSION
#undef CUSTOM_MARKING_CANVAS_WIDTH
#undef CUSTOM_MARKING_CANVAS_HEIGHT
#undef CUSTOM_MARKING_DIRECTIONS
