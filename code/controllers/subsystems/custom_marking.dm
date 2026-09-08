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
	var/needs_retry = FALSE
	if(!islist(build_body_marking_definition_cache()))
		needs_retry = TRUE
	if(!islist(build_basic_appearance_definition_cache()))
		needs_retry = TRUE
	build_custom_marking_canvas_background_cache()
	if(needs_retry)
		addtimer(CALLBACK(src, PROC_REF(try_prewarm_custom_marking_caches), 1), 20, TIMER_UNIQUE | TIMER_NO_HASH_WAIT)
	return .

// Retry static cache prewarming until accessory lists are ready (Lira, December 2025)
/datum/controller/subsystem/custom_marking/proc/try_prewarm_custom_marking_caches(retry = 0)
	var/body_ready = islist(body_marking_styles_list) && body_marking_styles_list.len
	var/basic_ready = islist(hair_styles_list) && hair_styles_list.len && islist(facial_hair_styles_list) && facial_hair_styles_list.len
	var/needs_retry = FALSE
	if(body_ready && !islist(custom_marking_body_definition_cache))
		if(!islist(build_body_marking_definition_cache()))
			needs_retry = TRUE
	else if(!body_ready)
		needs_retry = TRUE
	if(basic_ready && !islist(custom_marking_basic_appearance_definition_cache))
		if(!islist(build_basic_appearance_definition_cache()))
			needs_retry = TRUE
	else if(!basic_ready)
		needs_retry = TRUE
	if(!needs_retry)
		return
	if(retry >= 30)
		log_debug("CustomMarkings: Cache prewarm failed after [retry] attempts (body=[body_marking_styles_list?.len], hair=[hair_styles_list?.len], facial=[facial_hair_styles_list?.len], ear=[ear_styles_list?.len], tail=[tail_styles_list?.len], wing=[wing_styles_list?.len]).")
		return
	addtimer(CALLBACK(src, PROC_REF(try_prewarm_custom_marking_caches), retry + 1), 10)

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
