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

/datum/map_template/surface/west_crater
	name = "West Crater Content"
	desc = "Old buildings and homes near Charon Reach."
/datum/map_template/surface/east_crater
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
