/turf/simulated/floor/tiled/virgo4
	name = "outdoor floor"
	outdoors = TRUE
	edge_blending_priority = 1
	VIRGO4_SET_ATMOS

/turf/simulated/floor/tiled/virgo4/update_icon()
	..()
	update_icon_edge()

// Sand
/turf/simulated/floor/outdoors/sand
	name = "sand"
	icon_state = "sand"
	edge_blending_priority = 2
	turf_layers = list(
		/turf/simulated/floor/outdoors/rocks,
		/turf/simulated/floor/outdoors/dirt
	)
	
	var/grass_chance = 2 //"Grass"
	var/list/grass_types = list(
		/obj/structure/flora/tree/palm,
	)

	VIRGO4_SET_ATMOS

/turf/simulated/floor/outdoors/sand/wet
	name = "wet sand"
	icon = 'icons/turf/flooring/asteroid.dmi'
	icon_state = "asteroid"
	edge_blending_priority = 3

/turf/simulated/floor/outdoors/sand/desert
	name = "hot sand"
	icon = 'icons/turf/desert.dmi'
	icon_state = "desert"
	edge_blending_priority = 0

/turf/simulated/floor/outdoors/sand/desert/Initialize()
	if(prob(5))
		icon_state = "desert[rand(0,4)]"

	. = ..()

// Toasty sand
/turf/simulated/floor/outdoors/basalt
	name = "blasted desert"
	desc = "You probably shouldn't venture out this far."
	icon = 'icons/turf/outdoors.dmi'
	icon_state = "basalt0"
	VIRGO4_SET_ATMOS

/turf/simulated/floor/outdoors/basalt/Initialize()
	if(prob(10))
		icon_state = "basalt[rand(1,12)]"

	. = ..()

// Feesh
/turf/simulated/floor/water/indoors/virgo4
	outdoors = TRUE
	VIRGO4_SET_ATMOS