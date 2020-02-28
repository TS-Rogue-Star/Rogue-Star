#if !defined(USING_MAP_DATUM)

	#include "aubergine_defines.dm"
	#include "aubergine_turfs.dm"
	#include "aubergine_doors.dm"
	#include "aubergine_bayicons.dm"
	#include "aubergine_helpers.dm"
	#include "aubergine_wallframes.dm"
	#include "aubergine_windows.dm"
	//#include "aubergine_phoronlock.dm"
	#include "aubergine_areas.dm"
	//#include "aubergine_areas2.dm"
	//#include "aubergine_shuttle_defs.dm"
	//#include "aubergine_shuttles.dm"
	//#include "aubergine_telecomms.dm"

	#include "aubergine-01.dmm"

	//#include "submaps/_aubergine_submaps.dm"

	#define USING_MAP_DATUM /datum/map/aubergine

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Aubergine

#endif