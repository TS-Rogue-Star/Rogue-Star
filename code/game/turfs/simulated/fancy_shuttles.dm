/**
 * To map these, place down a fancy_shuttle_walls on the map and lay down /turf/simulated/wall/fancy_shuttle
 * everywhere that is included in the sprite. Up to you if you want to make some opacity=FALSE or density=FALSE
 * 
 * If you want flooring to look like the shuttle flooring, put /obj/effect/floor_decal/fancy_shuttle on all of it.
 * You can add your own decals on top of that. Just make sure to put the fancy_shuttle decal lowest.
 */

/**
 * Generic shuttle
 * North facing: W:5, H:9
 */
/obj/effect/fancy_shuttle
	name = "shuttle wall decorator"
	icon = 'icons/turf/fancy_shuttles/generic_preview.dmi'
	icon_state = "walls"
	plane = PLATING_PLANE
	layer = ABOVE_TURF_LAYER
	alpha = 90 // so you can see it a bit easier on the map if you placed walls properly
	var/split_file = 'icons/turf/fancy_shuttles/generic.dmi'
	var/icon/split_icon

/obj/effect/fancy_shuttle/Initialize()
	. = ..()
	icon_state = null
	split_icon = icon(split_file, null, dir)

/obj/effect/fancy_shuttle_floor_preview
	name = "shuttle floor preview"
	icon = 'icons/turf/fancy_shuttles/generic_preview.dmi'
	icon_state = "floors"
	plane = PLATING_PLANE
	layer = ABOVE_TURF_LAYER
	alpha = 90

/obj/effect/fancy_shuttle_floor_preview/Initialize()
	. = ..()
	return INITIALIZE_HINT_QDEL

// Only icon changes are damage
/turf/simulated/wall/fancy_shuttle
	icon = 'icons/turf/fancy_shuttles/_turf_helpers.dmi'
	icon_state = "hull"
	wall_masks = 'icons/turf/fancy_shuttles/_turf_helpers.dmi'
	var/area_override // If you want to search a different area for the shuttle icon holder
	var/mutable_appearance/under_MA

/turf/simulated/wall/fancy_shuttle/Initialize(mapload, materialtype, rmaterialtype, girdertype)
	icon_state = null
	. = ..()
	do_underlay()

/turf/simulated/wall/fancy_shuttle/pre_translate_A(turf/B)
	. = ..()
	if(under_MA)
		underlays -= under_MA
		under_MA = null

/turf/simulated/wall/fancy_shuttle/window
	opacity = FALSE
	icon_state = "hull_transparent"

/turf/simulated/wall/fancy_shuttle/nondense
	density = FALSE
	icon_state = "hull_nondense"

/turf/simulated/wall/fancy_shuttle/update_icon()
	if(!damage_overlays[1])
		generate_overlays()
	
	cut_overlays()
	var/area/area_to_search
	if(area_override)
		area_to_search = locate(area_to_search)
	else
		area_to_search = loc
	var/obj/effect/fancy_shuttle/F = locate() in area_to_search
	if(!F)
		warning("Fancy shuttle wall at [x],[y],[z] couldn't locate a helper in [loc]")
		return
	icon = F.split_icon
	icon_state = "walls [x - F.x],[y - F.y]"

	if(under_MA)
		underlays -= under_MA
		under_MA = null
	var/turf/path = get_base_turf_by_area(src) || /turf/space
	if(!ispath(path))
		warning("[src] has invalid baseturf '[get_base_turf_by_area(src)]' in area '[get_area(src)]'")
		path = /turf/space
	
	var/do_plane = ispath(path, /turf/space) ? SPACE_PLANE : null
	var/do_state = ispath(path, /turf/space) ? "white" : initial(path.icon_state)
	
	under_MA = mutable_appearance(initial(path.icon), do_state, layer = TURF_LAYER-0.02, plane = do_plane)
	under_MA.appearance_flags = RESET_ALPHA | RESET_COLOR
	underlays += under_MA

	if(damage != 0)
		var/integrity = material.integrity
		if(reinf_material)
			integrity += reinf_material.integrity

		var/overlay = round(damage / integrity * damage_overlays.len) + 1
		if(overlay > damage_overlays.len)
			overlay = damage_overlays.len

		add_overlay(damage_overlays[overlay])

/obj/effect/floor_decal/fancy_shuttle
	icon = 'icons/turf/fancy_shuttles/_turf_helpers.dmi'
	icon_state = "fancy_shuttle"
	var/icon_file
	var/area_override // If you want to search a different area for the shuttle icon holder

/obj/effect/floor_decal/fancy_shuttle/Initialize()
	var/area/area_to_search
	if(area_override)
		area_to_search = locate(area_to_search)
	else
		area_to_search = loc.loc // if you didn't put me on a turf then not even god can help you
	var/obj/effect/fancy_shuttle/F = locate() in area_to_search
	icon = F.split_icon
	icon_file = F.split_file
	icon_state = "floors [x - F.x],[y - F.y]"
	return ..()

/obj/effect/floor_decal/fancy_shuttle/get_cache_key(var/turf/T)
	return "[alpha]-[color]-[dir]-[icon_state]-[T.layer]-[icon_file]"

/**
 * Invisible engine (otherwise the same as normal)
 */
/obj/machinery/atmospherics/unary/engine/fancy_shuttle
	icon = 'icons/effects/effects.dmi'
	icon_state = "nothing"

/obj/machinery/ion_engine/fancy_shuttle
	icon = 'icons/effects/effects.dmi'
	icon_state = "nothing"

/obj/machinery/ion_engine/fancy_shuttle/add_glow()
	return

/**
 * Escape shuttle
 * North facing: W:15, H:27
 */
/obj/effect/fancy_shuttle/escape
	icon = 'icons/turf/fancy_shuttles/escape_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/escape.dmi'
/obj/effect/fancy_shuttle_floor_preview/escape
	icon = 'icons/turf/fancy_shuttles/escape_preview.dmi'

/**
 * Mining shuttle
 * North facing: W:18, H:24
 */
/obj/effect/fancy_shuttle/miner
	icon = 'icons/turf/fancy_shuttles/miner_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/miner.dmi'
/obj/effect/fancy_shuttle_floor_preview/miner
	icon = 'icons/turf/fancy_shuttles/miner_preview.dmi'

/**
 * Science shuttle
 * North facing: W:17, H:22
 */
/obj/effect/fancy_shuttle/science
	icon = 'icons/turf/fancy_shuttles/science_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/science.dmi'
/obj/effect/fancy_shuttle_floor_preview/science
	icon = 'icons/turf/fancy_shuttles/science_preview.dmi'

/**
 * Dropship
 * North facing: W:11, H:20
 */
/obj/effect/fancy_shuttle/dropship
	icon = 'icons/turf/fancy_shuttles/dropship_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/dropship.dmi'
/obj/effect/fancy_shuttle_floor_preview/dropship
	icon = 'icons/turf/fancy_shuttles/dropship_preview.dmi'

/**
 * Orange line tram
 * North facing: W:9, H:16
 */
/obj/effect/fancy_shuttle/orangeline
	icon = 'icons/turf/fancy_shuttles/orangeline_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/orangeline.dmi'
/obj/effect/fancy_shuttle_floor_preview/orangeline
	icon = 'icons/turf/fancy_shuttles/orangeline_preview.dmi'

/**
 * Delivery shuttle
 * North facing: W:8, H:10
 */
/obj/effect/fancy_shuttle/delivery
	icon = 'icons/turf/fancy_shuttles/delivery_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/delivery.dmi'
/obj/effect/fancy_shuttle_floor_preview/delivery
	icon = 'icons/turf/fancy_shuttles/delivery_preview.dmi'

/**
 * Wagon
 * North facing: W:5, H:13
 */
/obj/effect/fancy_shuttle/wagon
	icon = 'icons/turf/fancy_shuttles/wagon_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/wagon.dmi'
/obj/effect/fancy_shuttle_floor_preview/wagon
	icon = 'icons/turf/fancy_shuttles/wagon_preview.dmi'

/**
 * Lifeboat
 * North facing: W:5, H:10
 */
/obj/effect/fancy_shuttle/lifeboat
	icon = 'icons/turf/fancy_shuttles/lifeboat_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/lifeboat.dmi'
/obj/effect/fancy_shuttle_floor_preview/lifeboat
	icon = 'icons/turf/fancy_shuttles/lifeboat_preview.dmi'

/**
 * Pod
 * North facing: W:3, H:4
 */
/obj/effect/fancy_shuttle/escapepod
	icon = 'icons/turf/fancy_shuttles/pod_preview.dmi'
	split_file = 'icons/turf/fancy_shuttles/pod.dmi'
/obj/effect/fancy_shuttle_floor_preview/escapepod
	icon = 'icons/turf/fancy_shuttles/pod_preview.dmi'
