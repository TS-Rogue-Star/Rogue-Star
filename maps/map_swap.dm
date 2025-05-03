//RS FILE removed because WIP
#ifdef RP_MAP
	#define DEFAULT_MAP /datum/map/groundbase
#else
	#define DEFAULT_MAP /datum/map/stellar_delight
#endif


//COMMON STUFF
#include "tether\tether_jobs.dm"
#include "offmap_vr\common_offmaps.dm"
#include "~map_system\maps_vr.dm"
#include "~map_system\maps_rs.dm"
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
//SP STUFF
#include "sirius_point/sirius_point_areas.dm"
#include "sirius_point/sirius_point_defines.dm"
#include "sirius_point/sirius_point_shuttle_defs.dm"
#include "sirius_point/sirius_point_telecomms.dm"
#include "sirius_point/sirius_point_things.dm"
#include "sirius_point/sirius_point_turfs.dm"
//Minitest STUFF
#include "virgo_minitest/virgo_minitest_defines.dm"
#include "virgo_minitest/virgo_minitest_shuttles.dm"
#include "virgo_minitest/virgo_minitest_sectors.dm"
