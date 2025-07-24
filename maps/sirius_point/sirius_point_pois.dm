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

///////////////////////
///////////////////////

/area/submap/glacier/prepper1
	name = "POI - Glacier Prepper Bunker"
	ambience = AMBIENCE_FOREBODING
/datum/map_template/surface/glacier/prepper1
	name = "Glacier Prepper Bunker"
	desc = "A little hideaway for someone with more time and money than sense."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_prepper1.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks1
	name = "POI - Rocks 1"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks1
	desc = "Some brown rocks and ore."
	mappath = 'maps/sirius_point/submaps/rocks1.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks2
	name = "POI - Rocks 2"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks2
	name = "POI - Rocks 2"
	desc = "Some moon rocks."
	mappath = 'maps/sirius_point/submaps/rocks2.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks3
	name = "POI - Rocks 3"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks3
	name = "POI - Rocks 3"
	desc = "Some moon rocks."
	mappath = 'maps/sirius_point/submaps/rocks3.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks4
	name = "POI - Rocks 4"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks4
	name = "POI - Rocks 4"
	desc = "Some moon rocks."
	mappath = 'maps/sirius_point/submaps/rocks4.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks5
	name = "POI - Rocks 5"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks5
	name = "POI - Rocks 5"
	desc = "Small cave with ore."
	mappath = 'maps/sirius_point/submaps/rocks5.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks6
	name = "POI - Rocks 6"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks6
	name = "POI - Rocks 6"
	desc = "Spiral moon rock with ore."
	mappath = 'maps/sirius_point/submaps/rocks6.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks7
	name = "POI - Rocks 7"
	ambience = AMBIENCE_RUINS
/datum/map_template/surface/moonbase/west_crater/rocks7
	name = "POI - Rocks 7"
	desc = "Strangely familiar rocks."
	mappath = 'maps/sirius_point/submaps/rocks7.dmm'
	cost = 10

/area/submap/moonbase/poi/west_crater/rocks8
	name = "POI - Rocks 8"
	ambience = AMBIENCE_RUINS
/area/submap/moonbase/poi/west_crater/rocks9
	name = "POI - Rocks 9"
	ambience = AMBIENCE_RUINS
/area/submap/moonbase/poi/west_crater/rocks10
	name = "POI - Rocks 10"
	ambience = AMBIENCE_RUINS
