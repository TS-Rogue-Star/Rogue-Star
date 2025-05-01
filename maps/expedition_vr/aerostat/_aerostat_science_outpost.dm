#include "../../submaps/pois_vr/aerostat/virgo2.dm"

/obj/effect/overmap/visitable/sector/virgo2
	name = "Virgo 2"
	desc = "Includes the Remmi Aerostat and associated ground mining complexes."
	scanner_desc = @{"[i]Stellar Body[/i]: Virgo 2
[i]Class[/i]: R-Class Planet
[i]Habitability[/i]: Low (High Temperature, Toxic Atmosphere)
[b]Notice[/b]: Planetary environment not suitable for life. Landing may be hazardous."}
	icon_state = "globe"
	in_space = 0
	initial_generic_waypoints = list()	//RS EDIT
	known = TRUE
	icon_state = "chlorine"

	skybox_icon = 'icons/skybox/virgo2.dmi'
	skybox_icon_state = "v2"
	skybox_pixel_x = 0
	skybox_pixel_y = 0

/obj/effect/overmap/visitable/sector/virgo2/Initialize()
	for(var/obj/effect/overmap/visitable/ship/stellar_delight/sd in world)
		docking_codes = sd.docking_codes
	. = ..()

// -- Datums -- //

/datum/shuttle/autodock/ferry/aerostat/New(_name)	//RS ADD START - Map swap related
	if(using_map.name == "StellarDelight")
		docking_controller_tag = "aerostat_shuttle_airlock"
	. = ..()	//RS ADD END

/datum/random_map/noise/ore/virgo2
	descriptor = "virgo 2 ore distribution map"
	deep_val = 0.2
	rare_val = 0.1

/datum/random_map/noise/ore/virgo2/check_map_sanity()
	return 1 //Totally random, but probably beneficial.

// -- Objs -- //

/obj/machinery/computer/shuttle_control/aerostat_shuttle
	name = "aerostat ferry control console"
	shuttle_tag = "Aerostat Ferry"
	ai_control = TRUE

/obj/tether_away_spawner/aerostat_inside
	name = "Aerostat Indoors Spawner"
	faction = "aerostat_inside"
	atmos_comp = TRUE
	prob_spawn = 100
	prob_fall = 50
	//guard = 20
	mobs_to_pick_from = list(
		/mob/living/simple_mob/mechanical/hivebot/ranged_damage/basic = 3,
		/mob/living/simple_mob/mechanical/hivebot/ranged_damage/ion = 1,
		/mob/living/simple_mob/mechanical/hivebot/ranged_damage/laser = 3,
		/mob/living/simple_mob/vore/aggressive/corrupthound = 1
	)

/obj/tether_away_spawner/aerostat_surface
	name = "Aerostat Surface Spawner"
	faction = "aerostat_surface"
	atmos_comp = TRUE
	prob_spawn = 100
	prob_fall = 50
	//guard = 20
	mobs_to_pick_from = list(
		/mob/living/simple_mob/vore/jelly = 6,
		/mob/living/simple_mob/mechanical/viscerator = 6,
		/mob/living/simple_mob/vore/aggressive/corrupthound = 3,
		/mob/living/simple_mob/vore/oregrub = 2,
		/mob/living/simple_mob/vore/oregrub/lava = 1
	)

/obj/structure/old_roboprinter
	name = "old drone fabricator"
	desc = "Built like a tank, still working after so many years."
	icon = 'icons/obj/machines/drone_fab.dmi'
	icon_state = "drone_fab_idle"
	anchored = TRUE
	density = TRUE

/obj/structure/metal_edge
	name = "metal underside"
	desc = "A metal wall that extends downwards."
	icon = 'icons/turf/cliff.dmi'
	icon_state = "metal"
	anchored = TRUE
	density = FALSE

// -- Areas -- //

//The aerostat itself
/area/offmap/aerostat
	name = "\improper Away Mission - Aerostat Outside"
	icon_state = "away"
	base_turf = /turf/unsimulated/floor/sky/virgo2_sky
	requires_power = FALSE
	dynamic_lighting = FALSE

/area/offmap/aerostat/inside
	name = "\improper Away Mission - Aerostat Inside"
	icon_state = "crew_quarters"
	base_turf = /turf/simulated/floor/plating/virgo2
	requires_power = TRUE
	dynamic_lighting = TRUE
//	forced_ambience = list('sound/ambience/tension/tension.ogg', 'sound/ambience/tension/argitoth.ogg', 'sound/ambience/tension/burning_terror.ogg')

/area/offmap/aerostat/solars
	name = "\improper Away Mission - Aerostat Solars"
	icon_state = "crew_quarters"
	base_turf = /turf/simulated/floor/plating/virgo2
	dynamic_lighting = FALSE

/area/offmap/aerostat/inside
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "blublasqu"

/area/offmap/aerostat/inside/toxins
	name = "Toxins Lab"
	icon_state = "purwhisqu"

/area/offmap/aerostat/inside/xenoarch
	name = "Xenoarchaeolegy Lab"
	icon_state = "yelwhisqu"
/area/offmap/aerostat/inside/xenoarch/chamber
	name = "Xenoarchaeolegy Vent Chamber"

/area/offmap/aerostat/inside/genetics
	name = "Genetics Lab"
	icon_state = "grewhisqu"

/area/offmap/aerostat/inside/telesci
	name = "Telescience Lab"
	icon_state = "bluwhisqu"

/area/offmap/aerostat/inside/atmos
	name = "Atmospherics"
	icon_state = "orawhisqu"

/area/offmap/aerostat/inside/firingrange
	name = "Firing Range"
	icon_state = "orawhisqu"

/area/offmap/aerostat/inside/miscstorage
	name = "Miscellaneous Storage"
	icon_state = "orawhisqu"

/area/offmap/aerostat/inside/virology
	name = "Virology Lab"
	icon_state = "yelwhicir"

/area/offmap/aerostat/inside/south
	name = "Miscellaneous Labs A"
	icon_state = "blublasqu"

/area/offmap/aerostat/inside/south/b
	name = "Miscellaneous Labs B"
	icon_state = "blublasqu"

/area/offmap/aerostat/inside/powercontrol
	name = "Power Control"
	icon_state = "orawhicir"

/area/offmap/aerostat/inside/westhall
	name = "West Hall"
	icon_state = "orablacir"
/area/offmap/aerostat/inside/easthall
	name = "East Hall"
	icon_state = "orablacir"

/area/offmap/aerostat/inside/northchamb
	name = "North Chamber"
	icon_state = "orablacir"
/area/offmap/aerostat/inside/southchamb
	name = "South Chamber"
	icon_state = "orablacir"

/area/offmap/aerostat/inside/drillstorage
	name = "Drill Storage"
	icon_state = "orablacir"

/area/offmap/aerostat/inside/zorrenoffice
	name = "Zorren Reception"
	icon_state = "orablacir"

/area/offmap/aerostat/inside/lobby
	name = "Lobby"
	icon_state = "orablacir"
/area/offmap/aerostat/inside/xenobiolab
	name = "Xenobiology Lab"
	icon_state = "orablacir"

/area/offmap/aerostat/inside/airlock
	name = "Airlock"
	icon_state = "redwhicir"
/area/offmap/aerostat/inside/airlock/north
	name = "North Airlock"
/area/offmap/aerostat/inside/airlock/east
	name = "East Airlock"
/area/offmap/aerostat/inside/airlock/west
	name = "West Airlock"
/area/offmap/aerostat/inside/airlock/south
	name = "South Airlock"

/area/offmap/aerostat/inside/arm/ne
	name = "North-East Solar Arm"
/area/offmap/aerostat/inside/arm/nw
	name = "North-West Solar Arm"
/area/offmap/aerostat/inside/arm/se
	name = "South-East Solar Arm"
/area/offmap/aerostat/inside/arm/sw
	name = "South-West Solar Arm"

/area/offmap/aerostat/glassgetsitsownarea
	name = "Aerostat Glass"
	icon_state = "crew_quarters"
	base_turf = /turf/unsimulated/floor/sky/virgo2_sky
	dynamic_lighting = FALSE
