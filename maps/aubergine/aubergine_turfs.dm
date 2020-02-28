// Baywalls
/turf/simulated/wall
	icon = 'icons/turf/bay_wall_masks.dmi'
	masks_icon = 'icons/turf/bay_wall_masks.dmi'

/turf/simulated/wall/can_join_with(var/turf/simulated/wall/W)
	if(istype(W, /turf/simulated/mineral))
		return TRUE
	return ..()

// Sand
/turf/simulated/floor/outdoors/sand
	name = "Sand"
	icon_state = "sand"
	VIRGO4_SET_ATMOS

/turf/simulated/floor/outdoors/sand/desert
	icon = 'icons/turf/desert.dmi'
	icon_state = "desert"

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