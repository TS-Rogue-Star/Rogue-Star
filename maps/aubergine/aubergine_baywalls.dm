// Baywalls
/turf/simulated/wall
	icon = 'icons/turf/bay_wall_masks.dmi'
	masks_icon = 'icons/turf/bay_wall_masks.dmi'
	var/list/other_connections = list("0", "0", "0", "0")

	var/list/blend_turfs = list(/turf/simulated/wall/cult, /turf/simulated/wall/wood, /turf/simulated/mineral)
	var/list/blend_objects = list(/obj/machinery/door, /obj/structure/wall_frame, /obj/structure/grille, /obj/structure/window/reinforced/full, /obj/structure/window/reinforced/polarized/full, /obj/structure/window/shuttle, ,/obj/structure/window/phoronbasic/full, /obj/structure/window/phoronreinforced/full) // Objects which to blend with
	var/list/noblend_objects = list(/obj/machinery/door/window) //Objects to avoid blending with (such as children of listed blend objects.

	var/stripe_color = null

/turf/simulated/wall/update_icon()
	if(!material)
		return

	if(!damage_overlays[1]) //list hasn't been populated; note that it is always of fixed length, so we must check for membership.
		generate_overlays()

	cut_overlays()

	var/image/I
	var/base_color = material.icon_colour // paint_color ? paint_color : material.icon_colour
	if(!density)
		I = image(masks_icon, "[material.icon_base]fwall_open")
		I.color = base_color
		add_overlay(I)
		return

	for(var/i = 1 to 4)
		I = image(masks_icon, "[material.icon_base][wall_connections[i]]", dir = 1<<(i-1))
		I.color = base_color
		add_overlay(I)
		if(other_connections[i] != "0")
			I = image(masks_icon, "[material.icon_base]_other[wall_connections[i]]", dir = 1<<(i-1))
			I.color = base_color
			add_overlay(I)

	if(reinf_material)
		var/reinf_color = reinf_material.icon_colour // paint_color ? paint_color : reinf_material.icon_colour
		if(construction_stage != null && construction_stage < 6)
			I = image(masks_icon, "reinf_construct-[construction_stage]")
			I.color = reinf_color
			add_overlay(I)
		else
			if("[reinf_material.icon_reinf]0" in icon_states(masks_icon))
				// Directional icon
				for(var/i = 1 to 4)
					I = image(masks_icon, "[reinf_material.icon_reinf][wall_connections[i]]", dir = 1<<(i-1))
					I.color = reinf_color
					add_overlay(I)
			else
				I = image(masks_icon, reinf_material.icon_reinf)
				I.color = reinf_color
				add_overlay(I)

	/* Should probably be implemented...
	var/image/texture = material.get_wall_texture()
	if(texture)
		add_overlay(texture)
	if(stripe_color)
		for(var/i = 1 to 4)
			if(other_connections[i] != "0")
				I = image('icons/turf/bay_wall_masks.dmi', "stripe_other[wall_connections[i]]", dir = 1<<(i-1))
			else
				I = image('icons/turf/bay_wall_masks.dmi', "stripe[wall_connections[i]]", dir = 1<<(i-1))
			I.color = stripe_color
			add_overlay(I)
	*/

	if(damage != 0)
		var/integrity = material.integrity
		if(reinf_material)
			integrity += reinf_material.integrity

		var/overlay = round(damage / integrity * damage_overlays.len) + 1
		if(overlay > damage_overlays.len)
			overlay = damage_overlays.len

		add_overlay(damage_overlays[overlay])
	return

/turf/simulated/wall/generate_overlays()
	var/alpha_inc = 256 / damage_overlays.len

	for(var/i = 1; i <= damage_overlays.len; i++)
		var/image/img = image(icon = 'icons/turf/eris_walls.dmi', icon_state = "overlay_damage")
		img.blend_mode = BLEND_MULTIPLY
		img.alpha = (i * alpha_inc) - 1
		damage_overlays[i] = img

/turf/simulated/wall/update_connections(propagate = 0)
	if(!material)
		return
	var/list/wall_dirs = list()
	var/list/other_dirs = list()

	for(var/turf/simulated/wall/W in orange(src, 1))
		switch(can_join_with(W))
			if(0)
				continue
			if(1)
				wall_dirs += get_dir(src, W)
			if(2)
				wall_dirs += get_dir(src, W)
				other_dirs += get_dir(src, W)
		if(propagate)
			W.update_connections()
			W.update_icon()

	for(var/turf/T in orange(src, 1))
		var/success = 0
		for(var/obj/O in T)
			for(var/b_type in blend_objects)
				if(istype(O, b_type))
					success = 1
				for(var/nb_type in noblend_objects)
					if(istype(O, nb_type))
						success = 0
				if(success)
					break
			if(success)
				break

		if(success)
			wall_dirs += get_dir(src, T)
			if(get_dir(src, T) in GLOB.cardinal)
				other_dirs += get_dir(src, T)

	wall_connections = dirs_to_corner_states(wall_dirs)
	other_connections = dirs_to_corner_states(other_dirs)

/turf/simulated/wall/can_join_with(var/turf/simulated/wall/W)
	if(material && W.material && material.icon_base == W.material.icon_base)
		if((reinf_material && W.reinf_material) || (!reinf_material && !W.reinf_material))
			return 1
		return 2
	for(var/wb_type in blend_turfs)
		if(istype(W, wb_type))
			return 2

