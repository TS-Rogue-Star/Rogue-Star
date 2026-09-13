////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Custom marking background subsystem for queued tasks //
////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer Cache Enhancements ////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

// Background subsystem for custom marking work queues
SUBSYSTEM_DEF(custom_marking)
	name = "Custom Markings"
	wait = 1
	priority = FIRE_PRIORITY_DEFAULT
	flags = SS_BACKGROUND | SS_KEEP_TIMING
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/list/task_queue = list()
	var/static_atlas_prewarm_complete = FALSE
	var/static_atlas_prewarm_exhausted = FALSE
	var/static_atlas_finalization_attempts = 0
	var/static_atlas_persistent_cache_checked = FALSE
	var/static_atlas_persistent_cache_loaded = FALSE
	var/static_atlas_build_in_progress = FALSE

GLOBAL_VAR_INIT(custom_marking_allow_yield, FALSE)
GLOBAL_VAR_INIT(custom_marking_yield_budget, 0)
GLOBAL_VAR_INIT(custom_marking_yield_epoch, 0)
GLOBAL_VAR_INIT(custom_marking_static_atlas_building, FALSE)

/proc/report_custom_marking_atlas_fallback(fallback_path, reason, details = null, occurrences = 1)
	var/static/list/fallback_counts = list()
	var/resolved_path = istext(fallback_path) && length(fallback_path) ? fallback_path : "unknown"
	var/resolved_reason = istext(reason) && length(reason) ? reason : "unspecified atlas failure"
	var/count_key = "[resolved_path]|[resolved_reason]"
	var/previous_count = fallback_counts[count_key] || 0
	var/increment = isnum(occurrences) ? max(1, round(occurrences)) : 1
	var/current_count = previous_count + increment
	fallback_counts[count_key] = current_count
	var/should_report = !previous_count
	var/report_threshold = 10
	while(!should_report && report_threshold <= current_count)
		if(previous_count < report_threshold)
			should_report = TRUE
			break
		report_threshold *= 10
	if(!should_report)
		return current_count
	var/detail_suffix = istext(details) && length(details) ? " ([details])" : ""
	log_debug("CustomMarkings: Atlas fallback used (path=[resolved_path], total=[current_count]): [resolved_reason][detail_suffix].")
	return current_count

/proc/reset_custom_marking_static_atlas_caches()
	custom_marking_body_definition_cache = null
	custom_marking_basic_appearance_definition_cache = null
	custom_marking_visible_pixel_cache = null
	custom_marking_species_body_preview_cache = null
	custom_marking_species_catalog_cache = null
	custom_marking_species_icon_base_option_cache = null
	custom_marking_prosthetic_preview_cache_complete = FALSE
	custom_marking_gear_preview_cache_complete = FALSE
	custom_marking_static_source_digest_cache = list()
	custom_marking_static_source_digest_complete = TRUE

// Build global cache when server initializes (Lira, December 2025)
/datum/controller/subsystem/custom_marking/Initialize(timeofday)
	. = ..(timeofday)
	try_prewarm_custom_marking_caches()
	return .

/datum/controller/subsystem/custom_marking/Recover()
	task_queue = SScustom_marking.task_queue
	static_atlas_prewarm_complete = SScustom_marking.static_atlas_prewarm_complete
	static_atlas_prewarm_exhausted = SScustom_marking.static_atlas_prewarm_exhausted
	static_atlas_finalization_attempts = SScustom_marking.static_atlas_finalization_attempts
	static_atlas_persistent_cache_checked = SScustom_marking.static_atlas_persistent_cache_checked
	static_atlas_persistent_cache_loaded = SScustom_marking.static_atlas_persistent_cache_loaded
	subsystem_initialized = SScustom_marking.subsystem_initialized
	if(!static_atlas_prewarm_complete)
		addtimer(CALLBACK(src, PROC_REF(try_prewarm_custom_marking_caches), 1), 10, TIMER_UNIQUE | TIMER_NO_HASH_WAIT)

/datum/controller/subsystem/custom_marking/proc/finalize_static_atlas(datum/asset/spritesheet/custom_marking_designer/atlas = null)
	if(!istype(atlas))
		atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	return atlas.finalize()

/datum/controller/subsystem/custom_marking/proc/complete_static_atlas_prewarm(exhausted = FALSE, datum/asset/spritesheet/custom_marking_designer/atlas = null, report_failure = TRUE)
	if(!istype(atlas))
		atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/finalized = atlas.is_ready()
	atlas.accepting_assets = FALSE
	static_atlas_prewarm_exhausted = !!exhausted || !finalized
	static_atlas_prewarm_complete = TRUE
	if(finalized)
		log_debug("CustomMarkings: Canonical atlas finalized [atlas.get_frame_count()] unique frames from [atlas.get_requested_frame_count()] requests ([atlas.get_reused_frame_count()] reused) across [atlas.get_sheet_count()] family shards. [atlas.get_sheet_diagnostic_summary()]")
		if(!atlas.was_loaded_from_persistent_cache())
			try
				if(atlas.persist_finalized_cache())
					log_debug("CustomMarkings: Canonical atlas persistent cache stored ([atlas.get_frame_count()] frames, [atlas.get_sheet_count()] shards).")
				else if(atlas.get_persistent_cache_failure_reason())
					log_debug("CustomMarkings: Canonical atlas persistent cache was not stored: [atlas.get_persistent_cache_failure_reason()].")
			catch(var/exception/e)
				log_debug("CustomMarkings: Canonical atlas persistent cache could not be stored: [e].")
	else if(report_failure)
		report_custom_marking_atlas_fallback(
			"static-manifest-fallback-enabled",
			exhausted ? "cache prewarm exhausted before the canonical atlas became client-ready" : "canonical atlas construction failed before it became client-ready",
			"frames=[atlas.get_frame_count()], sheets=[atlas.get_sheet_count()], attempts=[static_atlas_finalization_attempts], failure=[atlas.finalization_failure_reason || "resources are not ready"]"
		)
	return finalized

/datum/controller/subsystem/custom_marking/proc/is_static_atlas_prewarm_pending()
	return !static_atlas_prewarm_complete

/datum/controller/subsystem/custom_marking/proc/is_static_atlas_terminal_fallback(datum/asset/spritesheet/custom_marking_designer/atlas = null)
	if(!static_atlas_prewarm_complete || !static_atlas_prewarm_exhausted)
		return FALSE
	if(!istype(atlas))
		atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	return !istype(atlas) || !atlas.is_ready()

// Retry static cache prewarming until accessory lists are ready (Lira, December 2025)
/datum/controller/subsystem/custom_marking/proc/try_prewarm_custom_marking_caches(retry = 0)
	if(static_atlas_prewarm_complete || static_atlas_build_in_progress)
		return
	if(static_atlas_inputs_ready())
		return build_static_atlas()
	if(retry >= 30)
		log_debug("CustomMarkings: Cache prewarm failed after [retry] attempts waiting for static catalog inputs.")
		return complete_static_atlas_prewarm(TRUE)
	addtimer(CALLBACK(src, PROC_REF(try_prewarm_custom_marking_caches), retry + 1), 10, TIMER_UNIQUE | TIMER_NO_HASH_WAIT)

/datum/controller/subsystem/custom_marking/proc/static_atlas_inputs_ready()
	return SSassets && islist(SSassets.cache) && body_marking_styles_list?.len && hair_styles_list?.len && facial_hair_styles_list?.len && ear_styles_list?.len && tail_styles_list?.len && wing_styles_list?.len && GLOB.hair_gradients?.len && GLOB.all_species?.len && GLOB.playable_species?.len && all_traits?.len && chargen_robolimbs?.len

/datum/controller/subsystem/custom_marking/proc/build_static_atlas_catalogs()
	build_custom_marking_canvas_background_cache()
	if(!islist(build_body_marking_definition_cache()) || !islist(build_basic_appearance_definition_cache()))
		return FALSE
	var/list/species_body_cache = build_custom_marking_species_body_preview_cache()
	if(!species_body_cache?.len || !build_custom_marking_prosthetic_preview_cache() || !build_custom_marking_gear_preview_cache())
		return FALSE
	var/list/species_catalog_cache = build_custom_marking_species_catalog_cache()
	return species_catalog_cache?.len && islist(custom_marking_species_icon_base_option_cache)

/datum/controller/subsystem/custom_marking/proc/build_static_atlas(force_rebuild = FALSE, report_failure = TRUE)
	set background = FALSE
	if(static_atlas_build_in_progress || GLOB.custom_marking_static_atlas_building || !static_atlas_inputs_ready())
		return FALSE
	static_atlas_build_in_progress = TRUE
	static_atlas_prewarm_complete = FALSE
	static_atlas_prewarm_exhausted = FALSE
	static_atlas_finalization_attempts = 0
	static_atlas_persistent_cache_loaded = FALSE
	var/previous_allow_yield = GLOB.custom_marking_allow_yield
	var/previous_yield_budget = GLOB.custom_marking_yield_budget
	GLOB.custom_marking_static_atlas_building = TRUE
	GLOB.custom_marking_allow_yield = FALSE
	GLOB.custom_marking_yield_budget = 0
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/succeeded = FALSE
	try
		for(var/attempt = 1 to 3)
			static_atlas_finalization_attempts = attempt
			reset_custom_marking_static_atlas_caches()
			atlas.reset_after_persistent_cache_miss()
			try
				if(attempt == 1 && !force_rebuild && !static_atlas_persistent_cache_checked)
					static_atlas_persistent_cache_checked = TRUE
					if(atlas.load_persistent_cache_for_validation())
						log_debug("CustomMarkings: Canonical atlas persistent cache candidate loaded; validating the live catalog.")
					else
						log_debug("CustomMarkings: Canonical atlas persistent cache miss: [atlas.get_persistent_cache_failure_reason()].")
				if(!build_static_atlas_catalogs())
					throw EXCEPTION("static catalogs did not finish building")
				if(atlas.is_persistent_cache_validation_pending())
					if(atlas.complete_persistent_cache_validation())
						static_atlas_persistent_cache_loaded = TRUE
						log_debug("CustomMarkings: Canonical atlas persistent cache hit ([atlas.get_frame_count()] frames, [atlas.get_sheet_count()] shards); pixel construction skipped.")
					else
						log_debug("CustomMarkings: Canonical atlas persistent cache invalidated: [atlas.get_persistent_cache_failure_reason()]. Rebuilding.")
						reset_custom_marking_static_atlas_caches()
						atlas.reset_after_persistent_cache_miss()
						if(!build_static_atlas_catalogs())
							throw EXCEPTION("static catalogs did not finish rebuilding")
				succeeded = finalize_static_atlas(atlas) && atlas.is_ready()
			catch(var/exception/e)
				atlas.fail_finalization(atlas.construction_failure_reason || "runtime during atlas construction: [e]")
			if(succeeded)
				break
			static_atlas_persistent_cache_loaded = FALSE
			if(attempt < 3)
				log_debug("CustomMarkings: Canonical atlas build attempt [attempt] failed: [atlas.finalization_failure_reason || "resources are not ready"]. Discarding failed sheets and rebuilding from scratch.")
		complete_static_atlas_prewarm(FALSE, atlas, report_failure)
	catch(var/exception/e)
		atlas.fail_finalization("runtime completing atlas construction: [e]")
		static_atlas_prewarm_complete = TRUE
		static_atlas_prewarm_exhausted = TRUE
		succeeded = FALSE
		log_debug("CustomMarkings: Canonical atlas build failed: [e].")
	GLOB.custom_marking_static_atlas_building = FALSE
	GLOB.custom_marking_allow_yield = previous_allow_yield
	GLOB.custom_marking_yield_budget = previous_yield_budget
	static_atlas_build_in_progress = FALSE
	return succeeded

/datum/controller/subsystem/custom_marking/proc/rebuild_static_atlas()
	if(static_atlas_build_in_progress || GLOB.custom_marking_static_atlas_building || !static_atlas_inputs_ready())
		return list("success" = FALSE, "reason" = "The static catalog is not ready or an atlas build is already running.")
	var/datum/asset/spritesheet/custom_marking_designer/previous_atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/list/previous_caches = capture_custom_marking_static_atlas_caches()
	var/previous_cache_loaded = static_atlas_persistent_cache_loaded
	var/started = REALTIMEOFDAY
	var/datum/asset/spritesheet/custom_marking_designer/atlas = new
	atlas.persistent_cache_enabled = previous_atlas.persistent_cache_enabled
	atlas.persistent_cache_path_override = previous_atlas.persistent_cache_path_override
	static_atlas_persistent_cache_checked = TRUE
	var/succeeded = build_static_atlas(TRUE, !previous_atlas.is_ready())
	var/retained_previous = !succeeded && previous_atlas.is_ready()
	if(retained_previous)
		GLOB.asset_datums[/datum/asset/spritesheet/custom_marking_designer] = previous_atlas
		restore_custom_marking_static_atlas_caches(previous_caches)
		static_atlas_prewarm_complete = TRUE
		static_atlas_prewarm_exhausted = FALSE
		static_atlas_persistent_cache_loaded = previous_cache_loaded
		log_debug("CustomMarkings: Manual atlas rebuild failed; the previous working atlas and static catalogs were retained.")
	else if(succeeded)
		for(var/client/C in GLOB.clients)
			C.prefs?.reset_custom_marking_caches(FALSE, FALSE)
	var/list/result = list(
		"success" = succeeded,
		"reason" = atlas.finalization_failure_reason,
		"frames" = atlas.get_frame_count(),
		"sheets" = atlas.get_sheet_count(),
		"attempts" = static_atlas_finalization_attempts,
		"seconds" = (REALTIMEOFDAY - started) / 10,
		"retained_previous" = retained_previous
	)
	if(retained_previous)
		qdel(atlas)
	else
		qdel(previous_atlas)
	return result

/datum/controller/subsystem/custom_marking/proc/reload_static_atlas()
	set background = FALSE
	if(static_atlas_build_in_progress || GLOB.custom_marking_static_atlas_building || !static_atlas_inputs_ready())
		return list("success" = FALSE, "reason" = "The static catalog is not ready or an atlas build is already running.")
	var/datum/asset/spritesheet/custom_marking_designer/previous_atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/list/previous_caches = capture_custom_marking_static_atlas_caches()
	var/previous_allow_yield = GLOB.custom_marking_allow_yield
	var/previous_yield_budget = GLOB.custom_marking_yield_budget
	var/started = REALTIMEOFDAY
	var/datum/asset/spritesheet/custom_marking_designer/atlas = new
	atlas.persistent_cache_enabled = previous_atlas.persistent_cache_enabled
	atlas.persistent_cache_path_override = previous_atlas.persistent_cache_path_override
	static_atlas_build_in_progress = TRUE
	GLOB.custom_marking_static_atlas_building = TRUE
	GLOB.custom_marking_allow_yield = FALSE
	GLOB.custom_marking_yield_budget = 0
	var/succeeded = FALSE
	var/reason
	try
		if(!atlas.load_persistent_cache_for_validation())
			throw EXCEPTION(atlas.get_persistent_cache_failure_reason())
		reset_custom_marking_static_atlas_caches()
		if(!build_static_atlas_catalogs())
			throw EXCEPTION("static catalogs did not finish validating")
		if(!atlas.complete_persistent_cache_validation() || !atlas.is_ready())
			throw EXCEPTION(atlas.get_persistent_cache_failure_reason() || "the imported atlas did not become client-ready")
		succeeded = TRUE
	catch(var/exception/e)
		reason = atlas.get_persistent_cache_failure_reason() || "runtime importing the atlas: [e]"
	if(succeeded)
		static_atlas_prewarm_complete = TRUE
		static_atlas_prewarm_exhausted = FALSE
		static_atlas_finalization_attempts = 0
		static_atlas_persistent_cache_checked = TRUE
		static_atlas_persistent_cache_loaded = TRUE
	else
		GLOB.asset_datums[/datum/asset/spritesheet/custom_marking_designer] = previous_atlas
		restore_custom_marking_static_atlas_caches(previous_caches)
	GLOB.custom_marking_static_atlas_building = FALSE
	GLOB.custom_marking_allow_yield = previous_allow_yield
	GLOB.custom_marking_yield_budget = previous_yield_budget
	static_atlas_build_in_progress = FALSE
	var/list/result = list(
		"success" = succeeded,
		"reason" = reason,
		"frames" = atlas.get_frame_count(),
		"sheets" = atlas.get_sheet_count(),
		"seconds" = (REALTIMEOFDAY - started) / 10,
		"retained_previous" = !succeeded && previous_atlas.is_ready()
	)
	if(succeeded)
		for(var/client/C in GLOB.clients)
			C.prefs?.reset_custom_marking_caches(FALSE, FALSE)
		log_debug("CustomMarkings: Canonical atlas imported from disk ([result["frames"]] frames, [result["sheets"]] shards, [result["seconds"]] seconds); pixel construction skipped.")
		qdel(previous_atlas)
	else
		log_debug("CustomMarkings: Canonical atlas import rejected: [reason]. Previous atlas state retained.")
		qdel(atlas)
	return result

/proc/capture_custom_marking_static_atlas_caches()
	return list(
		"body" = custom_marking_body_definition_cache,
		"basic" = custom_marking_basic_appearance_definition_cache,
		"visible" = custom_marking_visible_pixel_cache,
		"species_body" = custom_marking_species_body_preview_cache,
		"species_catalog" = custom_marking_species_catalog_cache,
		"icon_base" = custom_marking_species_icon_base_option_cache,
		"prosthetics" = custom_marking_prosthetic_preview_cache_complete,
		"gear" = custom_marking_gear_preview_cache_complete,
		"digests" = custom_marking_static_source_digest_cache,
		"digests_complete" = custom_marking_static_source_digest_complete
	)

/proc/restore_custom_marking_static_atlas_caches(list/caches)
	custom_marking_body_definition_cache = caches["body"]
	custom_marking_basic_appearance_definition_cache = caches["basic"]
	custom_marking_visible_pixel_cache = caches["visible"]
	custom_marking_species_body_preview_cache = caches["species_body"]
	custom_marking_species_catalog_cache = caches["species_catalog"]
	custom_marking_species_icon_base_option_cache = caches["icon_base"]
	custom_marking_prosthetic_preview_cache_complete = caches["prosthetics"]
	custom_marking_gear_preview_cache_complete = caches["gear"]
	custom_marking_static_source_digest_cache = caches["digests"]
	custom_marking_static_source_digest_complete = caches["digests_complete"]

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
