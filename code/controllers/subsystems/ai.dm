SUBSYSTEM_DEF(ai)
	name = "AI"
	init_order = INIT_ORDER_AI
	priority = FIRE_PRIORITY_AI
	wait = 2 SECONDS
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/processing = list()
	var/list/currentrun = list()

	var/slept_mobs = 0
	var/list/process_z = list()
	// RS ADD
	var/deferred_fires = 0

/datum/controller/subsystem/ai/stat_entry(msg_prefix)
	..("P: [processing.len] | S: [slept_mobs] | D: [deferred_fires]") // RS EDIT

/datum/controller/subsystem/ai/fire(resumed = 0)
	if (!resumed)
		src.currentrun = processing.Copy()
		process_z.Cut()
		slept_mobs = 0
		var/level = 1
		while(process_z.len < GLOB.living_players_by_zlevel.len)
			process_z.len++
			process_z[level] = GLOB.living_players_by_zlevel[level].len
			level++

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/datum/ai_holder/A = currentrun[currentrun.len]
		--currentrun.len
		if(!A || QDELETED(A))
			continue
		if(A.busy)
			// RS ADD
			if(A.busy_since && (world.time - A.busy_since) > AI_BUSY_WATCHDOG)
				A.clear_stranded_busy()
			else
				continue

		var/mob/living/L = A.holder	//VOREStation Edit Start
		if(!L?.loc)
			continue

		if((get_z(L) && process_z[get_z(L)]) || !L.low_priority) //VOREStation Edit End
			A.handle_strategicals()
		else
			slept_mobs++
			A.set_stance(STANCE_IDLE)

		if(MC_TICK_CHECK)
			if(currentrun.len)	// RS ADD
				deferred_fires++
			return
