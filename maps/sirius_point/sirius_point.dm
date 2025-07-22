#if !defined(USING_MAP_DATUM)

	#include "sirius_point_defines.dm"
	#include "sirius_point_shuttle_defs.dm"
	#include "sirius_point_telecomms.dm"
	#include "sirius_point_things.dm"
	#include "sirius_point_turfs.dm"
	#include "sirius_point_events.dm"
	#include "sirius_point_areas.dm"
	#include "sirius_point_pois.dm"
	#include "..\offmap_vr\common_offmaps.dm"
	#include "..\tether\tether_jobs.dm"

	#if !AWAY_MISSION_TEST //Don't include these for just testing away missions
		#include "sirius_point1.dmm"
		#include "sirius_point2.dmm"
		#include "sirius_point3.dmm"
		#include "sirius_point_east.dmm"
		#include "sirius_point_west.dmm"
		#include "sirius_point_mining.dmm"
	#endif

	#define USING_MAP_DATUM /datum/map/sirius_point

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Sirius Point

#endif
