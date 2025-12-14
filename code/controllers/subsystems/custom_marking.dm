////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Custom marking background subsystem for queued tasks //
////////////////////////////////////////////////////////////////////////////////////////////////////////

// Background subsystem for custom marking work queues
SUBSYSTEM_DEF(custom_marking)
	name = "Custom Markings"
	wait = 1
	priority = FIRE_PRIORITY_DEFAULT
	flags = SS_BACKGROUND | SS_KEEP_TIMING
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/list/task_queue = list()

GLOBAL_VAR_INIT(custom_marking_allow_yield, FALSE)
GLOBAL_VAR_INIT(custom_marking_yield_budget, 0)
GLOBAL_VAR_INIT(custom_marking_yield_epoch, 0)

// Build global cache when server initializes (Lira, December 2025)
/datum/controller/subsystem/custom_marking/Initialize(timeofday)
	. = ..(timeofday)
	if(!islist(build_body_marking_definition_cache()))
		addtimer(CALLBACK(GLOBAL_PROC, /proc/build_body_marking_definition_cache), 10, TIMER_UNIQUE | TIMER_NO_HASH_WAIT)
	return .

// Process queued callbacks while honoring MC tick limits
/datum/controller/subsystem/custom_marking/fire(resumed = FALSE)
	if(!task_queue.len)
		return
	var/previous_flag = GLOB.custom_marking_allow_yield
	GLOB.custom_marking_allow_yield = TRUE
	GLOB.custom_marking_yield_budget = 0
	while(task_queue.len)
		var/datum/callback/cb = task_queue[1]
		task_queue.Cut(1, 2)
		if(!cb)
			continue
		try
			cb.Invoke()
		catch(var/exception)
			GLOB.custom_marking_allow_yield = previous_flag
			qdel(cb)
			throw exception
		qdel(cb)
		if(MC_TICK_CHECK)
			GLOB.custom_marking_allow_yield = previous_flag
			return
	GLOB.custom_marking_allow_yield = previous_flag
	GLOB.custom_marking_yield_budget = 0

// Queue a callback for deferred custom marking execution
/datum/controller/subsystem/custom_marking/proc/queue_callback(datum/callback/cb)
	if(!cb)
		return FALSE
	if(flags & SS_NO_FIRE || !can_fire)
		return FALSE
	LAZYINITLIST(task_queue)
	task_queue += cb
	if(state == SS_IDLE)
		enqueue()
	return TRUE
