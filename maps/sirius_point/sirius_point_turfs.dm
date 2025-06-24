//Moonbase turfs

/turf/simulated/open/vacuum/outdoors
	outdoors = 1

//Airless moonrock walls
/turf/simulated/mineral/moonbase
	color="#7ab6b6"
	temperature = TCMB
//Air-y moonrock walls
/turf/simulated/mineral/cave/moonbase
	color="#7ab6b6"

//Floors
/turf/simulated/mineral/floor/vacuum/moonbase
	icon = 'maps/sirius_point/sp_asteroid.dmi'
	icon_state = "asteroid"
	sand_icon_path = 'maps/sirius_point/sp_asteroid.dmi'
	sand_icon_state = "asteroid"
//	color="#8da1bb"
	edge_blending_priority = 4
	icon_edge = 'maps/sirius_point/sp_asteroid_edge.dmi'
	temperature = TCMB
/turf/simulated/floor/plating/external/moonbaseplating
	icon = 'maps/sirius_point/sp_asteroid.dmi'
	icon_state = "asteroidfloor"
	temperature = TCMB
/turf/simulated/floor/glass/reinforced/vacuum
	oxygen = 0
	nitrogen = 0
	temperature = TCMB

//outdoors versions of the above and some existing turfs
/turf/simulated/mineral/floor/vacuum/moonbase/outdoors
	outdoors = 1
/turf/simulated/floor/plating/external/moonbaseplating/outdoors
	outdoors = 1
/turf/simulated/floor/plating/external/outdoors
	outdoors = 1
/turf/simulated/floor/reinforced/airless/outdoors
	outdoors = 1
/turf/simulated/floor/glass/reinforced/vacuum/outdoors
	outdoors = 1

//Air-y moonrock floors for inside
/turf/simulated/mineral/floor/cave/moonbase
	icon = 'maps/sirius_point/sp_asteroid.dmi'
	icon_state = "asteroid"
	sand_icon_path = 'maps/sirius_point/sp_asteroid.dmi'
	sand_icon_state = "asteroid"
	edge_blending_priority = 4
	icon_edge = 'maps/sirius_point/sp_asteroid_edge.dmi'
/turf/simulated/floor/plating/moonbase
	icon = 'maps/sirius_point/sp_asteroid.dmi'
	icon_state = "asteroidfloor"

//Special turf to suck up the air
/turf/space/cracked_asteroid/moonbase
	icon = 'maps/sirius_point/sp_asteroid.dmi'
/turf/space/cracked_asteroid/moonbase/outdoors
	outdoors = 1

/turf/unsimulated/mineral/moonbase
	name = "impassable rock"
	color="#7ab6b6"
