////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star June 2026: Overlay caching and DMI improvements //
////////////////////////////////////////////////////////////////////////////////////

/proc/vore_fullscreen_icon_files(colorized = FALSE)
	if(colorized)
		return list('icons/mob/screen_full_colorized_vore.dmi', 'icons/rogue-star/screen_full_colorized_vore.dmi')
	return list('icons/mob/screen_full_vore.dmi', 'icons/rogue-star/screen_full_vore.dmi')

/proc/vore_fullscreen_overlay_icon_files()
	return list('icons/mob/screen_full_colorized_vore_overlays.dmi', 'icons/rogue-star/screen_full_colorized_vore_overlays.dmi')

/proc/vore_icon_files_cache_key(list/icon_files)
	return jointext(icon_files, "|")

/proc/vore_is_placeholder_fullscreen_icon_state(icon_state)
	return icon_state == "tummyhere" || icon_state == "tummyhere_nc"

/proc/vore_icon_states_from_files(list/icon_files)
	var/static/list/state_cache = list()
	var/cache_key = vore_icon_files_cache_key(icon_files)
	var/list/states = state_cache[cache_key]
	if(!states)
		states = list()
		for(var/icon_file in icon_files)
			states |= cached_icon_states(icon_file)
		states -= "tummyhere"
		states -= "tummyhere_nc"
		state_cache[cache_key] = states
	return states

/proc/vore_icon_state_file_map(list/icon_files)
	var/static/list/state_file_cache = list()
	var/cache_key = vore_icon_files_cache_key(icon_files)
	var/list/state_files = state_file_cache[cache_key]
	if(!state_files)
		state_files = list()
		for(var/icon_file in icon_files)
			for(var/icon_state in cached_icon_states(icon_file))
				if(vore_is_placeholder_fullscreen_icon_state(icon_state))
					continue
				if(!state_files[icon_state])
					state_files[icon_state] = icon_file
		state_file_cache[cache_key] = state_files
	return state_files

/proc/vore_icon_file_for_state(icon_state, list/icon_files)
	var/list/state_files = vore_icon_state_file_map(icon_files)
	var/icon_file = state_files[icon_state]
	if(icon_file)
		return icon_file
	return icon_files[1]

/proc/vore_icon_state_exists(icon_state, list/icon_files)
	var/list/state_files = vore_icon_state_file_map(icon_files)
	return !!state_files[icon_state]

/proc/vore_fullscreen_icon_states(colorized = FALSE)
	var/list/states = vore_icon_states_from_files(vore_fullscreen_icon_files(colorized))
	return states.Copy()

/proc/vore_fullscreen_icon(icon_state, colorized = FALSE)
	return vore_icon_file_for_state(icon_state, vore_fullscreen_icon_files(colorized))

/proc/vore_fullscreen_icon_state_exists(icon_state, colorized = FALSE)
	return vore_icon_state_exists(icon_state, vore_fullscreen_icon_files(colorized))

/proc/vore_fullscreen_overlay_icon_states()
	var/list/states = vore_icon_states_from_files(vore_fullscreen_overlay_icon_files())
	return states.Copy()

/proc/vore_fullscreen_overlay_icon(icon_state)
	return vore_icon_file_for_state(icon_state, vore_fullscreen_overlay_icon_files())

/proc/vore_fullscreen_overlay_icon_state_exists(icon_state)
	return vore_icon_state_exists(icon_state, vore_fullscreen_overlay_icon_files())
