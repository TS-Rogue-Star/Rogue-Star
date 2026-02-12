//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star February 2026: New system for transparency with close objects and effects //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define NEARBY_TRANSPARENCY_MASK_ICON_DEFAULT 'icons/effects/light_overlays/light_160.dmi'
#define NEARBY_TRANSPARENCY_MASK_ICON_LOOK_FOCUS 'icons/effects/light_overlays/light_64.dmi'
#define NEARBY_TRANSPARENCY_MASK_STATE "light"
#define NEARBY_TRANSPARENCY_BLOCKED_CHUNK_STATE "nearby_blocked_chunk"
#define NEARBY_TRANSPARENCY_BLOCKED_MARKER_ALPHA 255
#define NEARBY_TRANSPARENCY_LIGHTPOST_LAYER_OFFSET -2
#define NEARBY_TRANSPARENCY_BLOCKED_CHUNK_CACHE_LIMIT 4096

var/global/icon/nearby_transparency_mask_default
var/global/icon/nearby_transparency_mask_look_focus
var/global/list/nearby_transparency_blocked_chunk_cache = list()

var/global/list/nearby_transparency_supported_mob_plane_obj_types = typecacheof(list(
	/obj/structure/flora/tree,
	/obj/structure/lightpost,
))

/datum/component/nearby_transparency
	var/active = FALSE
	var/above_obj_filter
	var/obj/screen/plane_master/above_obj_pm
	var/above_mob_filter
	var/obj/screen/plane_master/above_mob_pm
	var/list/tracked_mob_plane_obj_images
	var/list/tracked_mob_plane_obj_hides
	var/list/tracked_blocked_turf_markers
	var/list/tracked_blocked_turf_marker_keys
	var/look_focus_active = FALSE

/datum/component/nearby_transparency/Initialize()
	. = ..()

	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_MOB_LOGOUT, PROC_REF(_on_logout), TRUE)
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(_on_logout), TRUE)
	RegisterSignal(parent, COMSIG_LOOK_FOCUS_START, PROC_REF(_on_look_focus_start), TRUE)
	RegisterSignal(parent, COMSIG_LOOK_RECENTER_COMPLETE, PROC_REF(_on_look_focus_end), TRUE)

/datum/component/nearby_transparency/Destroy(force)
	_disable()
	UnregisterSignal(parent, list(
		COMSIG_MOB_LOGOUT,
		COMSIG_PARENT_QDELETING,
		COMSIG_LOOK_FOCUS_START,
		COMSIG_LOOK_RECENTER_COMPLETE,
	))
	return ..()

/datum/component/nearby_transparency/proc/_ensure_masks()
	if(!nearby_transparency_mask_default)
		var/icon/default_mask = icon(NEARBY_TRANSPARENCY_MASK_ICON_DEFAULT, NEARBY_TRANSPARENCY_MASK_STATE)
		default_mask.ChangeOpacity(0.9)
		nearby_transparency_mask_default = default_mask
	if(!nearby_transparency_mask_look_focus)
		var/icon/look_focus_mask = icon(NEARBY_TRANSPARENCY_MASK_ICON_LOOK_FOCUS, NEARBY_TRANSPARENCY_MASK_STATE)
		look_focus_mask.ChangeOpacity(0.9)
		nearby_transparency_mask_look_focus = look_focus_mask

/datum/component/nearby_transparency/proc/_get_current_mask_icon()
	_ensure_masks()
	return look_focus_active ? nearby_transparency_mask_look_focus : nearby_transparency_mask_default

/datum/component/nearby_transparency/proc/_refresh_mask_filters()
	if(!active)
		return

	var/icon/current_mask = _get_current_mask_icon()

	if(above_mob_pm)
		if(above_mob_filter)
			above_mob_pm.filters -= above_mob_filter
		above_mob_filter = filter(type = "alpha", icon = current_mask, flags = MASK_INVERSE)
		above_mob_pm.filters += above_mob_filter

	if(above_obj_pm)
		if(above_obj_filter)
			above_obj_pm.filters -= above_obj_filter
		above_obj_filter = filter(type = "alpha", icon = current_mask, flags = MASK_INVERSE)
		above_obj_pm.filters += above_obj_filter

/datum/component/nearby_transparency/proc/_is_parent_look_focusing()
	var/mob/living/L = parent
	if(!istype(L))
		return FALSE
	for(var/datum/modifier/look_over_there/ignored in L.modifiers)
		return TRUE
	return FALSE

/datum/component/nearby_transparency/proc/_is_supported_mob_plane_obj(atom/A)
	if(!isobj(A))
		return FALSE
	if(!A.mouse_opacity)
		return FALSE
	if(A.plane == MOB_PLANE)
		return is_type_in_typecache(A, nearby_transparency_supported_mob_plane_obj_types)
	if(A.plane == ABOVE_OBJ_PLANE || A.plane == ABOVE_MOB_PLANE)
		return TRUE
	return FALSE

/datum/component/nearby_transparency/proc/_needs_mob_plane_replacement(obj/O)
	if(!O)
		return FALSE
	if(O.plane != MOB_PLANE)
		return FALSE
	return is_type_in_typecache(O, nearby_transparency_supported_mob_plane_obj_types)

/datum/component/nearby_transparency/proc/_get_hide_proxy_plane(obj/O)
	if(!O)
		return OBJ_PLANE
	if(O.plane == ABOVE_OBJ_PLANE)
		return OBJ_PLANE
	if(O.plane == ABOVE_MOB_PLANE)
		return MOB_PLANE
	return O.plane

/datum/component/nearby_transparency/proc/_get_replacement_plane(obj/O)
	if(!O)
		return ABOVE_MOB_PLANE
	if(_needs_mob_plane_replacement(O))
		return ABOVE_MOB_PLANE
	return O.plane

/datum/component/nearby_transparency/proc/_get_replacement_layer(obj/O)
	if(!O)
		return ABOVE_MOB_LAYER

	var/replacement_layer = O.layer
	if(_needs_mob_plane_replacement(O))
		if(istype(O, /obj/structure/lightpost))
			replacement_layer += NEARBY_TRANSPARENCY_LIGHTPOST_LAYER_OFFSET
	return replacement_layer

/datum/component/nearby_transparency/proc/_register_parent_runtime_signals()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(_on_parent_moved), TRUE)

/datum/component/nearby_transparency/proc/_unregister_parent_runtime_signals()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)

/datum/component/nearby_transparency/proc/_register_tracked_obj_signals(obj/O)
	RegisterSignal(O, COMSIG_ATOM_DIR_CHANGE, PROC_REF(_on_tracked_obj_dir_change), TRUE)
	RegisterSignal(O, COMSIG_ATOM_UPDATE_ICON, PROC_REF(_on_tracked_obj_appearance_change), TRUE)
	RegisterSignal(O, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(_on_tracked_obj_appearance_change), TRUE)
	RegisterSignal(O, COMSIG_MOVABLE_MOVED, PROC_REF(_on_tracked_obj_moved), TRUE)
	RegisterSignal(O, COMSIG_PARENT_QDELETING, PROC_REF(_on_tracked_obj_qdeleting), TRUE)

/datum/component/nearby_transparency/proc/_unregister_tracked_obj_signals(obj/O)
	UnregisterSignal(O, list(
		COMSIG_ATOM_DIR_CHANGE,
		COMSIG_ATOM_UPDATE_ICON,
		COMSIG_ATOM_UPDATE_OVERLAYS,
		COMSIG_MOVABLE_MOVED,
		COMSIG_PARENT_QDELETING,
	))

/datum/component/nearby_transparency/proc/_refresh_mob_plane_obj_image(obj/O)
	var/image/replacement = tracked_mob_plane_obj_images?[O]
	var/image/hide = tracked_mob_plane_obj_hides?[O]
	var/mob/M = parent
	if(!hide || !M || !M.client || !M.client.images)
		return

	if(!M.client.images.Find(hide))
		M.client.images += hide

	hide.appearance = O.appearance
	hide.appearance_flags |= RESET_COLOR
	hide.override = 1
	hide.alpha = 1
	hide.pixel_x = 0
	hide.pixel_y = 0
	hide.plane = _get_hide_proxy_plane(O)
	hide.layer = O.layer

	if(!replacement)
		replacement = image(O, O)
		replacement.override = 1
		if(!tracked_mob_plane_obj_images)
			tracked_mob_plane_obj_images = list()
		tracked_mob_plane_obj_images[O] = replacement
	if(!M.client.images.Find(replacement))
		M.client.images += replacement

	replacement.appearance = O.appearance
	replacement.appearance_flags |= RESET_COLOR
	if(_needs_mob_plane_replacement(O))
		var/list/remapped_overlays = _copy_and_remap_special_plane_overlays(O.overlays)
		if(remapped_overlays)
			replacement.overlays = remapped_overlays
	replacement.pixel_x = 0
	replacement.pixel_y = 0
	replacement.plane = _get_replacement_plane(O)
	replacement.layer = _get_replacement_layer(O)

/datum/component/nearby_transparency/proc/_copy_and_remap_special_plane_overlays(list/source_overlays)
	if(!source_overlays || !source_overlays.len)
		return null

	var/list/remapped
	for(var/i in 1 to source_overlays.len)
		var/overlay_entry = source_overlays[i]
		if(isnull(overlay_entry))
			continue

		var/mutable_appearance/overlay_copy = new /mutable_appearance(overlay_entry)

		if(overlay_copy.plane != PLANE_LIGHTING_ABOVE)
			continue

		if(!remapped)
			remapped = source_overlays.Copy()
		overlay_copy.plane = ABOVE_MOB_PLANE
		remapped[i] = overlay_copy

	return remapped

/datum/component/nearby_transparency/proc/_is_tracked_obj_blocking(obj/O)
	if(!O)
		return FALSE
	return !!O.density

/datum/component/nearby_transparency/proc/_build_blocked_marker_chunk(obj/O, effective_pixel_x, effective_pixel_y)
	if(!O || !O.icon)
		return null

	if(!isnum(effective_pixel_x) || !isnum(effective_pixel_y))
		effective_pixel_x = O.pixel_x
		effective_pixel_y = O.pixel_y
		if(ismovable(O))
			var/atom/movable/movable_obj = O
			effective_pixel_x += movable_obj.step_x
			effective_pixel_y += movable_obj.step_y

	var/list/chunk = _build_blocked_marker_chunk_from_icon(icon(O.icon, O.icon_state, O.dir), effective_pixel_x, effective_pixel_y)
	if(chunk)
		return chunk
	chunk = _build_blocked_marker_chunk_from_icon(icon(O.icon, O.icon_state, SOUTH), effective_pixel_x, effective_pixel_y)
	if(chunk)
		return chunk
	return _build_blocked_marker_chunk_from_icon(icon(O.icon, O.icon_state), effective_pixel_x, effective_pixel_y)

/datum/component/nearby_transparency/proc/_get_or_build_cached_blocked_marker_chunk(obj/O, cache_key, effective_pixel_x, effective_pixel_y)
	if(!O)
		return null

	if(!nearby_transparency_blocked_chunk_cache)
		nearby_transparency_blocked_chunk_cache = list()

	if(cache_key in nearby_transparency_blocked_chunk_cache)
		var/cached = nearby_transparency_blocked_chunk_cache[cache_key]
		return cached ? cached : null

	var/list/chunk = _build_blocked_marker_chunk(O, effective_pixel_x, effective_pixel_y)

	if(nearby_transparency_blocked_chunk_cache.len >= NEARBY_TRANSPARENCY_BLOCKED_CHUNK_CACHE_LIMIT)
		nearby_transparency_blocked_chunk_cache.Cut()

	nearby_transparency_blocked_chunk_cache[cache_key] = chunk ? chunk : FALSE
	return chunk

/datum/component/nearby_transparency/proc/_build_blocked_marker_chunk_from_icon(icon/full_icon, effective_pixel_x, effective_pixel_y)
	if(!full_icon)
		return null
	var/icon_width = full_icon.Width()
	var/icon_height = full_icon.Height()
	if(icon_width < 1 || icon_height < 1)
		return null

	var/visible_x1 = 1 - effective_pixel_x
	var/visible_y1 = 1 - effective_pixel_y
	var/visible_x2 = world.icon_size - effective_pixel_x
	var/visible_y2 = world.icon_size - effective_pixel_y

	var/crop_x1 = max(1, visible_x1)
	var/crop_y1 = max(1, visible_y1)
	var/crop_x2 = min(icon_width, visible_x2)
	var/crop_y2 = min(icon_height, visible_y2)
	if(crop_x1 > crop_x2 || crop_y1 > crop_y2)
		return null

	var/icon/chunk_icon = icon(full_icon)
	chunk_icon.Crop(crop_x1, crop_y1, crop_x2, crop_y2)
	var/chunk_width = chunk_icon.Width()
	var/chunk_height = chunk_icon.Height()
	if(chunk_width < 1 || chunk_height < 1)
		return null

	var/has_visible_pixel = FALSE
	for(var/py in 1 to chunk_height)
		for(var/px in 1 to chunk_width)
			if(chunk_icon.GetPixel(px, py))
				has_visible_pixel = TRUE
				break
		if(has_visible_pixel)
			break
	if(!has_visible_pixel)
		return null

	var/icon/chunk_render_icon = icon('icons/effects/effects.dmi', "nothing")
	chunk_render_icon.Crop(1, 1, chunk_width, chunk_height)
	chunk_render_icon.Insert(chunk_icon, NEARBY_TRANSPARENCY_BLOCKED_CHUNK_STATE, SOUTH, 1, FALSE)

	var/list/chunk = list()
	chunk["icon"] = chunk_render_icon
	chunk["state"] = NEARBY_TRANSPARENCY_BLOCKED_CHUNK_STATE
	chunk["pixel_x"] = crop_x1 + effective_pixel_x - 1
	chunk["pixel_y"] = crop_y1 + effective_pixel_y - 1
	return chunk

/datum/component/nearby_transparency/proc/_remove_blocked_marker_for_obj(obj/O)
	var/image/marker = tracked_blocked_turf_markers?[O]
	var/mob/M = parent
	if(M && M.client && marker)
		M.client.images -= marker
	if(tracked_blocked_turf_markers)
		tracked_blocked_turf_markers.Remove(O)
	if(tracked_blocked_turf_marker_keys)
		tracked_blocked_turf_marker_keys.Remove(O)

/datum/component/nearby_transparency/proc/_clear_blocked_markers()
	if(!tracked_blocked_turf_markers || !tracked_blocked_turf_markers.len)
		return

	var/list/to_clear = list()
	for(var/obj/O as anything in tracked_blocked_turf_markers)
		to_clear += O
	for(var/obj/O as anything in to_clear)
		_remove_blocked_marker_for_obj(O)

/datum/component/nearby_transparency/proc/_refresh_blocked_marker_for_obj(obj/O)
	var/mob/M = parent
	if(!O || !M || !M.client)
		return

	var/turf/T = get_turf(O)
	if(!_is_tracked_obj_blocking(O) || !T)
		_remove_blocked_marker_for_obj(O)
		return

	var/effective_pixel_x = O.pixel_x
	var/effective_pixel_y = O.pixel_y
	if(ismovable(O))
		var/atom/movable/movable_obj = O
		effective_pixel_x += movable_obj.step_x
		effective_pixel_y += movable_obj.step_y

	var/cache_key = "[O.icon]|[O.icon_state]|[O.color]|[O.alpha]|[O.dir]|[effective_pixel_x]|[effective_pixel_y]|[world.icon_size]"
	var/image/marker = tracked_blocked_turf_markers?[O]
	if(marker && tracked_blocked_turf_marker_keys?[O] == cache_key)
		marker.loc = T
		marker.plane = TURF_PLANE
		marker.layer = ABOVE_TURF_LAYER
		marker.alpha = NEARBY_TRANSPARENCY_BLOCKED_MARKER_ALPHA
		marker.color = null
		marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		if(!M.client.images.Find(marker))
			M.client.images += marker
		return

	var/list/chunk = _get_or_build_cached_blocked_marker_chunk(O, cache_key, effective_pixel_x, effective_pixel_y)
	if(!chunk)
		_remove_blocked_marker_for_obj(O)
		return

	if(!tracked_blocked_turf_markers)
		tracked_blocked_turf_markers = list()
	if(!tracked_blocked_turf_marker_keys)
		tracked_blocked_turf_marker_keys = list()

	var/icon/chunk_icon = chunk["icon"]
	var/chunk_state = chunk["state"]
	var/chunk_pixel_x = chunk["pixel_x"]
	var/chunk_pixel_y = chunk["pixel_y"]

	marker = tracked_blocked_turf_markers[O]
	if(!marker)
		marker = image(icon = chunk_icon, loc = T, icon_state = chunk_state)
		marker.plane = TURF_PLANE
		marker.layer = ABOVE_TURF_LAYER
		marker.alpha = NEARBY_TRANSPARENCY_BLOCKED_MARKER_ALPHA
		marker.color = null
		marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		marker.pixel_x = chunk_pixel_x
		marker.pixel_y = chunk_pixel_y
		tracked_blocked_turf_markers[O] = marker
		tracked_blocked_turf_marker_keys[O] = cache_key
		M.client.images += marker
		return

	marker.icon = chunk_icon
	marker.icon_state = chunk_state
	marker.loc = T
	marker.pixel_x = chunk_pixel_x
	marker.pixel_y = chunk_pixel_y
	marker.plane = TURF_PLANE
	marker.layer = ABOVE_TURF_LAYER
	marker.alpha = NEARBY_TRANSPARENCY_BLOCKED_MARKER_ALPHA
	marker.color = null
	marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	tracked_blocked_turf_marker_keys[O] = cache_key
	if(!M.client.images.Find(marker))
		M.client.images += marker

/datum/component/nearby_transparency/proc/_track_mob_plane_obj(obj/O)
	if(!O || tracked_mob_plane_obj_hides?[O])
		return

	var/mob/M = parent
	if(!M || !M.client)
		return

	if(!tracked_mob_plane_obj_hides)
		tracked_mob_plane_obj_hides = list()

	var/image/hide = image(O, O)
	hide.override = 1
	hide.alpha = 1
	hide.pixel_x = 0
	hide.pixel_y = 0
	hide.plane = _get_hide_proxy_plane(O)
	hide.layer = O.layer

	tracked_mob_plane_obj_hides[O] = hide

	if(!tracked_mob_plane_obj_images)
		tracked_mob_plane_obj_images = list()
	var/image/replacement = image(O, O)
	replacement.override = 1
	replacement.plane = _get_replacement_plane(O)
	replacement.layer = _get_replacement_layer(O)
	tracked_mob_plane_obj_images[O] = replacement

	_register_tracked_obj_signals(O)

	M.client.images += hide
	M.client.images += replacement
	_refresh_mob_plane_obj_image(O)
	_refresh_blocked_marker_for_obj(O)

/datum/component/nearby_transparency/proc/_untrack_mob_plane_obj(obj/O)
	var/image/hide = tracked_mob_plane_obj_hides?[O]
	var/image/replacement = tracked_mob_plane_obj_images?[O]
	var/mob/M = parent

	if(M && M.client)
		if(hide)
			M.client.images -= hide
		if(replacement)
			M.client.images -= replacement
	_remove_blocked_marker_for_obj(O)

	if(O)
		_unregister_tracked_obj_signals(O)
	if(tracked_mob_plane_obj_hides)
		tracked_mob_plane_obj_hides.Remove(O)
	if(tracked_mob_plane_obj_images)
		tracked_mob_plane_obj_images.Remove(O)

/datum/component/nearby_transparency/proc/_clear_tracked_mob_plane_objs()
	if(!tracked_mob_plane_obj_hides || !tracked_mob_plane_obj_hides.len)
		return

	var/list/to_clear = list()
	for(var/obj/O as anything in tracked_mob_plane_obj_hides)
		to_clear += O
	for(var/obj/O as anything in to_clear)
		_untrack_mob_plane_obj(O)

/datum/component/nearby_transparency/proc/_refresh_tracked_mob_plane_objs()
	var/mob/M = parent
	if(!M || !M.client)
		return

	var/list/nearby_supported = list()
	for(var/obj/O as anything in view(world.view, M))
		if(!_is_supported_mob_plane_obj(O))
			continue
		nearby_supported[O] = TRUE
		if(!tracked_mob_plane_obj_hides?[O])
			_track_mob_plane_obj(O)

	if(!tracked_mob_plane_obj_hides || !tracked_mob_plane_obj_hides.len)
		return

	var/list/to_remove = list()
	for(var/obj/O as anything in tracked_mob_plane_obj_hides)
		if(!nearby_supported[O])
			to_remove += O
	for(var/obj/O as anything in to_remove)
		_untrack_mob_plane_obj(O)

/datum/component/nearby_transparency/proc/_on_parent_moved(atom/movable/source, old_loc, direction, forced, movetime)
	SIGNAL_HANDLER
	_refresh_tracked_mob_plane_objs()

/datum/component/nearby_transparency/proc/_on_tracked_obj_dir_change(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER
	var/obj/O = source
	if(!istype(O))
		return
	if(!_is_supported_mob_plane_obj(O))
		_untrack_mob_plane_obj(O)
		return
	_refresh_mob_plane_obj_image(O)
	_refresh_blocked_marker_for_obj(O)

/datum/component/nearby_transparency/proc/_on_tracked_obj_appearance_change(atom/source)
	SIGNAL_HANDLER
	var/obj/O = source
	if(!istype(O))
		return
	if(!_is_supported_mob_plane_obj(O))
		_untrack_mob_plane_obj(O)
		return
	_refresh_mob_plane_obj_image(O)
	_refresh_blocked_marker_for_obj(O)

/datum/component/nearby_transparency/proc/_on_tracked_obj_moved(atom/movable/source, old_loc, direction, forced, movetime)
	SIGNAL_HANDLER
	var/obj/O = source
	if(!istype(O))
		return
	if(!_is_supported_mob_plane_obj(O))
		_untrack_mob_plane_obj(O)
		return
	_refresh_mob_plane_obj_image(O)
	_refresh_blocked_marker_for_obj(O)
	_refresh_tracked_mob_plane_objs()

/datum/component/nearby_transparency/proc/_on_tracked_obj_qdeleting(atom/source)
	SIGNAL_HANDLER
	var/obj/O = source
	if(!istype(O))
		return
	_untrack_mob_plane_obj(O)

/datum/component/nearby_transparency/proc/_on_look_focus_start()
	SIGNAL_HANDLER
	look_focus_active = TRUE
	_refresh_mask_filters()

/datum/component/nearby_transparency/proc/_on_look_focus_end()
	SIGNAL_HANDLER
	if(_is_parent_look_focusing())
		return
	look_focus_active = FALSE
	_refresh_mask_filters()

/datum/component/nearby_transparency/proc/_enable()
	var/mob/M = parent
	if(!M || !M.client || !M.plane_holder)
		return

	look_focus_active = _is_parent_look_focusing()

	if(!above_mob_pm)
		above_mob_pm = new
		above_mob_pm.plane = ABOVE_MOB_PLANE
		above_mob_pm.alpha = 255
		above_mob_pm.mouse_opacity = 0
		if(M.client)
			M.client.screen += above_mob_pm

	if(!above_obj_pm)
		above_obj_pm = new
		above_obj_pm.plane = ABOVE_OBJ_PLANE
		above_obj_pm.alpha = 255
		above_obj_pm.mouse_opacity = 0
		if(M.client)
			M.client.screen += above_obj_pm

	active = TRUE
	_refresh_mask_filters()
	_register_parent_runtime_signals()
	_refresh_tracked_mob_plane_objs()

/datum/component/nearby_transparency/proc/_disable()
	var/mob/M = parent
	_clear_tracked_mob_plane_objs()
	_clear_blocked_markers()
	_unregister_parent_runtime_signals()

	if(above_mob_pm && above_mob_filter)
		above_mob_pm.filters -= above_mob_filter
	if(above_mob_pm && M && M.client)
		M.client.screen -= above_mob_pm
	QDEL_NULL(above_mob_pm)
	if(above_obj_pm && above_obj_filter)
		above_obj_pm.filters -= above_obj_filter
	if(above_obj_pm && M && M.client)
		M.client.screen -= above_obj_pm
	QDEL_NULL(above_obj_pm)

	tracked_mob_plane_obj_images = null
	tracked_mob_plane_obj_hides = null
	tracked_blocked_turf_markers = null
	tracked_blocked_turf_marker_keys = null
	above_obj_filter = null
	above_mob_filter = null
	above_obj_pm = null
	active = FALSE

/datum/component/nearby_transparency/proc/_on_logout()
	SIGNAL_HANDLER
	Destroy()

/datum/component/nearby_transparency/proc/toggle()
	if(active)
		_disable()
	else
		_enable()

/client/verb/toggle_nearby_transparency()
	set name = "Nearby Transparency Toggle"
	set desc = "Toggle partial transparency for nearby objects (mobs excluded)."
	set category = "IC"
	var/mob/M = mob
	if(isnull(M))
		to_chat(usr, "<span class='warning'>You can't toggle this without a mob!</span>")
		return
	if(isobserver(M))
		to_chat(usr, "<span class='warning'>Ghosts can't use nearby transparency.</span>")
		return
	if(isnull(M.loc))
		to_chat(usr, "<span class='warning'>You can't toggle this in nullspace!</span>")
		return

	var/datum/component/nearby_transparency/fade = M.LoadComponent(/datum/component/nearby_transparency)
	fade.toggle()
	return fade.active
