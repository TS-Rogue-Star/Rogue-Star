//Fires five times every second.

PROCESSING_SUBSYSTEM_DEF(fastprocess)
	name = "Fast Processing"
	wait = 2
	stat_tag = "FP"

/datum/controller/subsystem/processing/fastprocess/Recover()
	log_debug("[name] subsystem Recover().")
	if(SSfastprocess.current_thing)
		log_debug("current_thing was: (\ref[SSfastprocess.current_thing])[SSfastprocess.current_thing]([SSfastprocess.current_thing.type]) - currentrun: [SSfastprocess.currentrun.len] vs total: [SSfastprocess.processing.len]")
	var/list/old_processing = SSfastprocess.processing.Copy()
	for(var/datum/D in old_processing)
		if(CHECK_BITFIELD(D.datum_flags, DF_ISPROCESSING))
			processing |= D

// RS Add: Room Atmosphere Processing (Lira, October 2026)
/datum/controller/subsystem/processing/fastprocess/fire(resumed = FALSE)
	if(!resumed)
		flush_room_atmos_wakes()
	return ..()
