#if !defined(USING_MAP_DATUM)

	//COMMON STUFF
	#include "tether\tether_jobs.dm"
	#include "offmap_vr\common_offmaps.dm"
	#include "~map_system\maps_vr.dm"
	#include "common\map_events.dm"

	//SD STUFF
	#include "stellar_delight/stellar_delight_areas.dm"
	#include "stellar_delight/stellar_delight_defines.dm"
	#include "stellar_delight/stellar_delight_jobs.dm"
	#include "stellar_delight/stellar_delight_shuttle_defs.dm"
	#include "stellar_delight/stellar_delight_telecomms.dm"
	#include "stellar_delight/stellar_delight_things.dm"
	#include "stellar_delight/stellar_delight_turfs.dm"
	//GB STUFF
	#include "groundbase/groundbase_areas.dm"
	#include "groundbase/groundbase_defines.dm"
	#include "groundbase/groundbase_shuttles.dm"
	#include "groundbase/groundbase_telecomms.dm"
	#include "groundbase/groundbase_things.dm"
	#include "groundbase/groundbase_poi_stuff.dm"
	#include "groundbase/groundbase_wilds.dm"

/*
	#if !AWAY_MISSION_TEST //Don't include these for just testing away missions
		#include "stellar_delight/stellar_delight0.dmm"
		#include "stellar_delight/stellar_delight1.dmm"
		#include "stellar_delight/stellar_delight2.dmm"
		#include "stellar_delight/stellar_delight3.dmm"
		#include "groundbase/rp-z1.dmm"
		#include "groundbase/rp-z2.dmm"
		#include "groundbase/rp-z3.dmm"
		#include "groundbase/rp-z4.dmm"//RP lateloads the 4 wilds Z-levels first no matter what, so the engine satellite needs to load here or things break

	#endif
*/
#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Stellar Delight

#endif
