///////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Resize Aura Optimization //
///////////////////////////////////////////////////////////////////////////

/datum/component/resize_aura
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/cached_appearance
	var/cached_has_layers
	var/list/aura_templates
	var/next_pulse = 0
	var/last_use = 0
	var/cache_lifetime = 30 SECONDS

/datum/component/resize_aura/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	last_use = world.time
	addtimer(CALLBACK(src, PROC_REF(expire_cache)), cache_lifetime)

/datum/component/resize_aura/Destroy(force, silent)
	clear_templates()
	cached_appearance = null
	cached_has_layers = null
	return ..()

/datum/component/resize_aura/proc/clear_templates()
	for(var/image/template as anything in aura_templates)
		if(template)
			qdel(template)
	aura_templates = null

/datum/component/resize_aura/proc/filter_appearance_planes(image/current_appearance)
	for(var/process_set in 0 to 1)
		var/list/layers = process_set ? current_appearance.overlays : current_appearance.underlays
		if(!length(layers))
			continue
		var/list/visible_layers = list()
		for(var/image/layer as anything in layers)
			if(!layer || (layer.plane != FLOAT_PLANE && layer.plane != current_appearance.plane))
				continue
			visible_layers += layer
		if(process_set)
			current_appearance.overlays = visible_layers
		else
			current_appearance.underlays = visible_layers
	return current_appearance.appearance

/datum/component/resize_aura/proc/get_template(growing)
	var/mob/living/owner = parent
	var/image/current_appearance = image(owner.appearance)
	current_appearance.transform = null
	current_appearance.dir = SOUTH
	var/current_has_layers = !!(length(current_appearance.overlays) || length(current_appearance.underlays))
	var/current_key = filter_appearance_planes(current_appearance)
	if(cached_appearance != current_key || cached_has_layers != current_has_layers)
		clear_templates()
		cached_appearance = current_key
		cached_has_layers = current_has_layers
	if(!aura_templates)
		aura_templates = list(null, null)
	var/template_index = growing ? 1 : 2
	if(!aura_templates[template_index])
		aura_templates[template_index] = build_aura_image(owner, color = growing ? "#2222FF" : "#FF2222", offset = growing ? 0 : 10)
	return aura_templates[template_index]

/datum/component/resize_aura/proc/play(change, duration)
	last_use = world.time
	if(!change || world.time < next_pulse)
		return
	var/anim_duration = 5
	var/loops = max(1, CEILING(duration / anim_duration, 1))
	next_pulse = world.time + anim_duration * loops
	return animate_aura(parent, anim_duration = anim_duration, loops = loops, grow_to = change > 0 ? 2 : 0.5, aura_template = get_template(change > 0))

/datum/component/resize_aura/proc/expire_cache()
	var/remaining = max(last_use + cache_lifetime, next_pulse) - world.time
	if(remaining > 0)
		addtimer(CALLBACK(src, PROC_REF(expire_cache)), remaining)
		return
	qdel(src)
