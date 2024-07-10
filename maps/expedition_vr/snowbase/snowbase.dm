a////////////////////////////////////////////////////////////////////////////////////////////////////
//overmap node
/obj/effect/overmap/visitable/sector/snowbaseplanet
	name = "944 November"
	desc = "Home to ice, snow, and more ice."
	scanner_desc = @{"[i]Stellar Body[/i]: 944 November
[i]Class[/i]: Captured Exoplanet
[i]Habitability[/i]: Low (Extreme Low Temperature)
[b]Notice[/b]: Arctic survival gear is required. Contact traffic control for weather advisories."}
	icon_state = "frozen"
	in_space = 0
	initial_generic_waypoints = list("snowbase_surface_e", "snowbase_surface_w")
	extra_z_levels = list(Z_LEVEL_GLACIER)
	known = TRUE

////////////////////////////////////////////////////////////////////////////////////////////////////
//oregen
//This is a special subtype of the thing that generates ores on a map
//It will generate more rich ores because of the lower numbers than the normal one
/datum/random_map/noise/ore/snowbasemine
	descriptor = "snowbase mine ore distribution map"
	deep_val = 0.6 //More riches, normal is 0.7 and 0.8
	rare_val = 0.5

////////////////////////////////////////////////////////////////////////////////////////////////////
//areas
/area/tether_away/snowbase/
	name = "Away Mission - Snowbase"
	icon_state = "away"
	lightswitch = FALSE
	base_turf = /turf/simulated/floor/outdoors/snow/snowbase

/area/tether_away/snowbase/outside
	name = "Snowbase - Outside"
	ambience = list('sound/music/main.ogg', 'sound/ambience/maintenance/maintenance4.ogg', 'sound/ambience/sif/sif1.ogg', 'sound/ambience/ruins/ruins1.ogg')

/area/tether_away/snowbase/outside/glacier
	name = "Snowbase - Glacier"

/area/tether_away/snowbase/outside/glacier/unexplored
	name = "Snowbase - Unexplored Glacier"

/area/tether_away/snowbase/hall
	name = "Snowbase - Hallway"
	lightswitch = 1

/area/tether_away/snowbase/mess
	name = "Snowbase - Mess hall"
	lightswitch = 1

/area/tether_away/snowbase/kitchen
	name = "Snowbase - Kitchen"

/area/tether_away/snowbase/medbay
	name = "Snowbase - Medbay"
	lightswitch = 1

/area/tether_away/snowbase/morgue
	name = "Snowbase - Morgue"

/area/tether_away/snowbase/surgery
	name = "Snowbase - Surgical Suite"

/area/tether_away/snowbase/research
	name = "Snowbase - Research"

/area/tether_away/snowbase/security
	name = "Snowbase - Security"
	lightswitch = 1

/area/tether_away/snowbase/armory
	name = "Snowbase - Armory"

/area/tether_away/snowbase/closet
	name = "Snowbase - Emergency Storage"

/area/tether_away/snowbase/fuelstorage
	name = "Snowbase - Fuel Storage"

/area/tether_away/snowbase/multipurposeroom
	name = "Snowbase - Multipurpose Room"
	lightswitch = 1

/area/tether_away/snowbase/engineering
	name = "Snowbase - Engineering Bay"
	lightswitch = 1

/area/tether_away/snowbase/reactor
	name = "Snowbase - Reactor Room"

/area/tether_away/snowbase/atmospherics
	name = "Snowbase - Atmospherics"
	lightswitch = 1

/area/tether_away/snowbase/janitor
	name = "Snowbase - Janitorial"

/area/tether_away/snowbase/mining
	name = "Snowbase - Refinery"

/area/tether_away/snowbase/shelter
	name = "Snowbase - Warming Shelter"
	lightswitch = 1

/area/tether_away/snowbase/garage
	name = "Snowbase - Garage"
	lightswitch = 1

////////////////////////////////////////////////////////////////////////////////////////////////////
//This is either a hacky workaround or an elegant solution to the atmosphere problems - code credit to Aronai
//Atmosphere properties
#define SNOWBASE_ONE_ATMOSPHERE		101.3 //kPa
#define SNOWBASE_AVG_TEMP			243.15 //kelvin

#define SNOWBASE_PER_N2			0.80 //percent
#define SNOWBASE_PER_O2			0.20
#define SNOWBASE_PER_N2O		0.00 //Currently no capacity to 'start' a turf with this. See turf.dm
#define SNOWBASE_PER_CO2		0.00
#define SNOWBASE_PER_PHORON		0.00

//Math only beyond this point
#define SNOWBASE_MOL_PER_TURF		(SNOWBASE_ONE_ATMOSPHERE*CELL_VOLUME/(SNOWBASE_AVG_TEMP*R_IDEAL_GAS_EQUATION))
#define SNOWBASE_MOL_N2				(SNOWBASE_MOL_PER_TURF * SNOWBASE_PER_N2)
#define SNOWBASE_MOL_O2				(SNOWBASE_MOL_PER_TURF * SNOWBASE_PER_O2)
#define SNOWBASE_MOL_N2O			(SNOWBASE_MOL_PER_TURF * SNOWBASE_PER_N2O)
#define SNOWBASE_MOL_CO2			(SNOWBASE_MOL_PER_TURF * SNOWBASE_PER_CO2)
#define SNOWBASE_MOL_PHORON			(SNOWBASE_MOL_PER_TURF * SNOWBASE_PER_PHORON)

//Turfmakers
#define SNOWBASE_SET_ATMOS	nitrogen=SNOWBASE_MOL_N2;oxygen=SNOWBASE_MOL_O2;carbon_dioxide=SNOWBASE_MOL_CO2;phoron=SNOWBASE_MOL_PHORON;temperature=SNOWBASE_AVG_TEMP
#define SNOWBASE_TURF_CREATE(x)	x/snowbase/nitrogen=SNOWBASE_MOL_N2;x/snowbase/oxygen=SNOWBASE_MOL_O2;x/snowbase/carbon_dioxide=SNOWBASE_MOL_CO2;x/snowbase/phoron=SNOWBASE_MOL_PHORON;x/snowbase/temperature=SNOWBASE_AVG_TEMP

SNOWBASE_TURF_CREATE(/turf/unsimulated/wall/planetary)

////////////////////////////////////////////////////////////////////////////////////////////////////
//cold turfs
/turf/simulated/floor/outdoors/snow/snowbase
	SNOWBASE_SET_ATMOS

/turf/simulated/floor/outdoors/ice/snowbase
	SNOWBASE_SET_ATMOS

/turf/simulated/mineral/floor/icey/snowbase
	SNOWBASE_SET_ATMOS

/turf/simulated/mineral/crystal_shiny/snowbase
	SNOWBASE_SET_ATMOS

/turf/simulated/mineral/crystal_shiny/snowbase/ignore_mapgen
	ignore_mapgen = 1
	SNOWBASE_SET_ATMOS

/turf/simulated/mineral/floor/icey/snowbase/ignore_mapgen
	ignore_mapgen = 1
	SNOWBASE_SET_ATMOS

/turf/simulated/floor/plating/snowbase
	name = "plating"
	SNOWBASE_SET_ATMOS