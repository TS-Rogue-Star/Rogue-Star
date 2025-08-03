// This is so CI can validate PoIs, and ensure future changes don't break PoIs, as PoIs are loaded at runtime and the compiler can't catch errors.
// When adding a new PoI, please add it to this list.
#if MAP_TEST
#include "glacier_prepper1.dmm"
#endif

/area/submap/moonbase/poi
	name = "POI - Sirius Point"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "orawhisqu"
	ambience = AMBIENCE_RUINS
	flags = AREA_FLAG_IS_NOT_PERSISTENT
	sound_env = SOUND_ENVIRONMENT_MOUNTAINS
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase/outdoors

/area/submap/moonbase/poi/west_crater
	name = "POI - Sirius Point"
/area/submap/moonbase/poi/east_crater
	name = "POI - Sirius Point"

/datum/map_template/surface/moonbase/west_crater
	name = "West Crater Content"
	desc = "Old buildings and homes near Charon Reach."
/datum/map_template/surface/moonbase/east_crater
	name = "East Crater Content"
	desc = "Ruins, outlaw camps, and wrecks in the shipbreaking basin."

/////////////////
// West Crater //
/////////////////

/area/submap/moonbase/poi/west_crater/rocks1
	name = "POI - Rocks 1"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks1
	desc = "Some brown rocks and ore."
	mappath = 'maps/sirius_point/submaps/rocks1.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks2
	name = "POI - Rocks 2"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks2
	name = "POI - Rocks 2"
	desc = "Some moon rocks."
	mappath = 'maps/sirius_point/submaps/rocks2.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks3
	name = "POI - Rocks 3"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks3
	name = "POI - Rocks 3"
	desc = "Some moon rocks."
	mappath = 'maps/sirius_point/submaps/rocks3.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks4
	name = "POI - Rocks 4"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks4
	name = "POI - Rocks 4"
	desc = "Some moon rocks."
	mappath = 'maps/sirius_point/submaps/rocks4.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks5
	name = "POI - Rocks 5"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks5
	name = "POI - Rocks 5"
	desc = "Small cave with ore."
	mappath = 'maps/sirius_point/submaps/rocks5.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks6
	name = "POI - Rocks 6"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks6
	name = "POI - Rocks 6"
	desc = "Spiral moon rock with ore."
	mappath = 'maps/sirius_point/submaps/rocks6.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks7
	name = "POI - Rocks 7"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks7
	name = "POI - Rocks 7"
	desc = "Strangely familiar rocks."
	mappath = 'maps/sirius_point/submaps/rocks7.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/rocks8
	name = "POI - Rocks 8"
	ambience = AMBIENCE_RUINS
/area/submap/moonbase/poi/west_crater/rocks9
	name = "POI - Rocks 9"
	ambience = AMBIENCE_RUINS
/area/submap/moonbase/poi/west_crater/rocks10
	name = "POI - Rocks 10"
	ambience = AMBIENCE_RUINS

/area/submap/moonbase/poi/west_crater/rovercharging
	name = "POI - Rover Charging"
	ambience = AMBIENCE_TECH_RUINS
	requires_power = 1
/datum/map_template/surface/moonbase/west_crater/rovercharging
	name = "POI - Rover Charging Station"
	desc = "Rover recharging station."
	mappath = 'maps/sirius_point/submaps/rovercharging.dmm'
	cost = 15

/area/submap/moonbase/poi/west_crater/home1
	name = "POI - Home 1"
	ambience = AMBIENCE_TECH_RUINS
	requires_power = 1
/datum/map_template/surface/moonbase/west_crater/home1
	name = "POI - Home 1"
	desc = "A nice home on the moon."
	mappath = 'maps/sirius_point/submaps/home1.dmm'
	cost = 15

/area/submap/moonbase/poi/west_crater/home2
	name = "POI - Home 2"
	ambience = AMBIENCE_TECH_RUINS
	requires_power = 1
/datum/map_template/surface/moonbase/west_crater/home2
	name = "POI - Home 2"
	desc = "Some cheap apartments on the moon."
	mappath = 'maps/sirius_point/submaps/home2.dmm'
	cost = 15

/area/submap/moonbase/poi/west_crater/garden1
	name = "POI - Hydroponics 1"
	ambience = AMBIENCE_TECH_RUINS
	requires_power = 1
/datum/map_template/surface/moonbase/west_crater/garden1
	name = "POI - Hydroponics 1"
	desc = "A hydroponics facility."
	mappath = 'maps/sirius_point/submaps/garden1.dmm'
	cost = 15

/area/submap/moonbase/poi/west_crater/garden2
	name = "POI - Hydroponics 2"
	ambience = AMBIENCE_TECH_RUINS
	requires_power = 1
/datum/map_template/surface/moonbase/west_crater/garden2
	name = "POI - Hydroponics 2"
	desc = "A hydroponics facility."
	mappath = 'maps/sirius_point/submaps/garden2.dmm'
	cost = 15

/area/submap/moonbase/poi/west_crater/garden3
	name = "POI - Hydroponics 3"
	ambience = AMBIENCE_TECH_RUINS
	requires_power = 1
/datum/map_template/surface/moonbase/west_crater/garden3
	name = "POI - Hydroponics 3"
	desc = "A hydroponics facility."
	mappath = 'maps/sirius_point/submaps/garden3.dmm'
	cost = 15

/area/submap/moonbase/poi/west_crater/construction1
	name = "POI - Construction Site 1"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/construction1
	name = "POI - Construction Site 1"
	desc = "Old construction ruins."
	mappath = 'maps/sirius_point/submaps/construction1.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/construction2
	name = "POI - Construction Site 2"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/construction2
	name = "POI - Construction Site 2"
	desc = "Old construction ruins."
	mappath = 'maps/sirius_point/submaps/construction2.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/construction3
	name = "POI - Construction Site 3"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/construction3
	name = "POI - Construction Site 3"
	desc = "Old construction ruins."
	mappath = 'maps/sirius_point/submaps/construction3.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/construction4
	name = "POI - Construction Site 4"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/construction4
	name = "POI - Construction Site 4"
	desc = "Old construction ruins."
	mappath = 'maps/sirius_point/submaps/construction4.dmm'
	cost = 10
	fixed_orientation = FALSE

/area/submap/moonbase/poi/west_crater/construction5
	name = "POI - Construction Site 5"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/construction5
	name = "POI - Construction Site 5"
	desc = "Old construction ruins."
	mappath = 'maps/sirius_point/submaps/construction5.dmm'
	cost = 10
	fixed_orientation = FALSE

////////////////
// East Crater//
////////////////
