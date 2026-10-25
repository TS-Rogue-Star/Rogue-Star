////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Terrain Appearance Batching //
////////////////////////////////////////////////////////////////////////////////

#define BAD_INIT_QDEL_BEFORE 1
#define BAD_INIT_DIDNT_INIT 2
#define BAD_INIT_SLEPT 4
#define BAD_INIT_NO_HINT 8

SUBSYSTEM_DEF(atoms)
	name = "Atoms"
	init_order = INIT_ORDER_ATOMS
	flags = SS_NO_FIRE

	var/static/initialized = INITIALIZATION_INSSATOMS
	// var/list/created_atoms // This is never used, so don't bother. ~Leshana
	var/static/old_initialized

	var/list/late_loaders
	var/list/created_atoms

	// RS Add Start: Terrain Appearance Batching (Lira, September 2026)
	var/terrain_initializing = TRUE
	var/list/terrain_icon_updates = list()
	// RS Add End

	var/list/BadInitializeCalls = list()

/datum/controller/subsystem/atoms/Initialize(timeofday)
	setupgenetics() //to set the mutations' place in structural enzymes, so initializers know where to put mutations.
	initialized = INITIALIZATION_INNEW_MAPLOAD
	to_world_log("Initializing objects")
	admin_notice("<span class='danger'>Initializing objects</span>", R_DEBUG)
	InitializeAtoms()
	finish_terrain_icon_updates() // RS Add: Terrain Appearance Batching (Lira, September 2026)
	return ..()

/datum/controller/subsystem/atoms/proc/InitializeAtoms(list/atoms)
	if(initialized == INITIALIZATION_INSSATOMS)
		return

	initialized = INITIALIZATION_INNEW_MAPLOAD

	LAZYINITLIST(late_loaders)

	var/count
	var/list/mapload_arg = list(TRUE)
	if(atoms)
		created_atoms = list()
		count = atoms.len
		for(var/atom/A as anything in atoms)
			if(!A.initialized)
				if(InitAtom(A, mapload_arg))
					atoms -= A
				CHECK_TICK
	else
		count = 0
		for(var/atom/A in world) // This must be world, since this operation adds all the atoms to their specific lists.
			if(!A.initialized)
				InitAtom(A, mapload_arg)
				++count
				CHECK_TICK

	log_world("Initialized [count] atoms")

	initialized = INITIALIZATION_INNEW_REGULAR

	if(late_loaders.len)
		for(var/atom/A as anything in late_loaders)
			A.LateInitialize()
			CHECK_TICK
		testing("Late initialized [late_loaders.len] atoms")
		late_loaders.Cut()

	// Nothing ever checks return value of this proc, so don't bother.  If this ever changes fix code in /atom/New() ~Leshana
	// if(atoms)
	// 	. = created_atoms + atoms
	// 	created_atoms = null

/datum/controller/subsystem/atoms/proc/InitAtom(atom/A, list/arguments)
	var/the_type = A.type
	if(QDELING(A))
		BadInitializeCalls[the_type] |= BAD_INIT_QDEL_BEFORE
		return TRUE

	var/start_tick = world.time

	var/result = A.Initialize(arglist(arguments))

	if(start_tick != world.time)
		BadInitializeCalls[the_type] |= BAD_INIT_SLEPT

	var/qdeleted = FALSE

	if(result != INITIALIZE_HINT_NORMAL)
		switch(result)
			if(INITIALIZE_HINT_LATELOAD)
				if(arguments[1])	//mapload
					late_loaders += A
				else
					A.LateInitialize()
			if(INITIALIZE_HINT_QDEL)
				qdel(A)
				qdeleted = TRUE
			else
				BadInitializeCalls[the_type] |= BAD_INIT_NO_HINT

	if(!A)	//possible harddel
		qdeleted = TRUE
	else if(!A.initialized)
		BadInitializeCalls[the_type] |= BAD_INIT_DIDNT_INIT

	return qdeleted || QDELING(A)

/datum/controller/subsystem/atoms/proc/map_loader_begin()
	old_initialized = initialized
	initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms/proc/map_loader_stop()
	initialized = old_initialized

/datum/controller/subsystem/atoms/Recover()
	// RS Add Start: Terrain Appearance Batching (Lira, September 2026)
	terrain_initializing = SSatoms.terrain_initializing
	terrain_icon_updates = SSatoms.terrain_icon_updates
	// RS Add End
	initialized = SSatoms.initialized
	if(initialized == INITIALIZATION_INNEW_MAPLOAD)
		InitializeAtoms()
	// RS Add Start: Terrain Appearance Batching (Lira, September 2026)
	if(initialized != INITIALIZATION_INSSATOMS)
		SSatoms.terrain_initializing = FALSE
		finish_terrain_icon_updates()
	// RS Add End
	old_initialized = SSatoms.old_initialized
	BadInitializeCalls = SSatoms.BadInitializeCalls

// RS Add: Terrain Appearance Batching (Lira, September 2026)
/datum/controller/subsystem/atoms/proc/queue_terrain_icon_update(turf/simulated/T, update_neighbors = FALSE)
	if(!terrain_initializing)
		return FALSE
	if(!T.terrain_icon_update_state)
		T.terrain_icon_update_state = 1
		terrain_icon_updates += T
	if(update_neighbors)
		if(istype(T, /turf/simulated/floor))
			for(var/turf/simulated/floor/F in range(T, 1))
				if(!F.terrain_icon_update_state)
					F.terrain_icon_update_state = 1
					terrain_icon_updates += F
		else if(istype(T, /turf/simulated/mineral))
			for(var/direction in alldirs)
				var/turf/simulated/N = get_step(T, direction)
				if(istype(N, /turf/simulated/mineral) || istype(N, /turf/simulated/wall/solidrock))
					if(!N.terrain_icon_update_state)
						N.terrain_icon_update_state = 1
						terrain_icon_updates += N
	return TRUE

// RS Add: Terrain Appearance Batching (Lira, September 2026)
/datum/controller/subsystem/atoms/proc/finish_terrain_icon_updates()
	terrain_initializing = FALSE
	for(var/turf/simulated/floor/F in terrain_icon_updates)
		if(!QDELETED(F))
			F.update_base_icon()
		CHECK_TICK
	for(var/turf/simulated/T in terrain_icon_updates)
		if(!QDELETED(T) && T.terrain_icon_update_state != 2)
			T.terrain_icon_update_state = 2
			T.update_icon()
		CHECK_TICK
	for(var/turf/simulated/T in terrain_icon_updates)
		T.terrain_icon_update_state = 0
		CHECK_TICK
	terrain_icon_updates = null

/datum/controller/subsystem/atoms/proc/InitLog()
	. = ""
	for(var/path in BadInitializeCalls)
		. += "Path : [path] \n"
		var/fails = BadInitializeCalls[path]
		if(fails & BAD_INIT_DIDNT_INIT)
			. += "- Didn't call atom/Initialize()\n"
		if(fails & BAD_INIT_NO_HINT)
			. += "- Didn't return an Initialize hint\n"
		if(fails & BAD_INIT_QDEL_BEFORE)
			. += "- Qdel'd in New()\n"
		if(fails & BAD_INIT_SLEPT)
			. += "- Slept during Initialize()\n"

/datum/controller/subsystem/atoms/Shutdown()
	var/initlog = InitLog()
	if(initlog)
		text2file(initlog, "[log_path]-initialize.log")

#undef BAD_INIT_QDEL_BEFORE
#undef BAD_INIT_DIDNT_INIT
#undef BAD_INIT_SLEPT
#undef BAD_INIT_NO_HINT
