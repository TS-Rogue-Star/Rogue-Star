////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Custom marking background subsystem for queued tasks //
////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ////////////
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
	var/static_atlas_persistent_cache_checked = FALSE
	var/static_atlas_persistent_cache_loaded = FALSE

GLOBAL_VAR_INIT(custom_marking_allow_yield, FALSE)
GLOBAL_VAR_INIT(custom_marking_yield_budget, 0)
GLOBAL_VAR_INIT(custom_marking_yield_epoch, 0)

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

// Build global cache when server initializes (Lira, December 2025)
/datum/controller/subsystem/custom_marking/Initialize(timeofday)
	. = ..(timeofday)
	try_prewarm_custom_marking_caches()
	return .

/datum/controller/subsystem/custom_marking/Recover()
	task_queue = SScustom_marking.task_queue
	static_atlas_prewarm_complete = SScustom_marking.static_atlas_prewarm_complete
	static_atlas_prewarm_exhausted = SScustom_marking.static_atlas_prewarm_exhausted
	static_atlas_persistent_cache_checked = SScustom_marking.static_atlas_persistent_cache_checked
	static_atlas_persistent_cache_loaded = SScustom_marking.static_atlas_persistent_cache_loaded
	subsystem_initialized = SScustom_marking.subsystem_initialized
	if(!static_atlas_prewarm_complete)
		addtimer(CALLBACK(src, PROC_REF(try_prewarm_custom_marking_caches), 1), 10, TIMER_UNIQUE | TIMER_NO_HASH_WAIT)

/datum/controller/subsystem/custom_marking/proc/finalize_static_atlas(datum/asset/spritesheet/custom_marking_designer/atlas = null)
	if(!istype(atlas))
		atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	return atlas.finalize()

/datum/controller/subsystem/custom_marking/proc/complete_static_atlas_prewarm(exhausted = FALSE, datum/asset/spritesheet/custom_marking_designer/atlas = null)
	if(static_atlas_prewarm_complete)
		if(!istype(atlas))
			atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
		return atlas.is_ready()
	if(!istype(atlas))
		atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/finalized = finalize_static_atlas(atlas)
	static_atlas_prewarm_exhausted = !!exhausted || !finalized
	static_atlas_prewarm_complete = TRUE
	if(finalized)
		log_debug("CustomMarkings: Canonical atlas finalized [atlas.get_frame_count()] unique frames from [atlas.get_requested_frame_count()] requests ([atlas.get_reused_frame_count()] reused) across [atlas.get_sheet_count()] family shards. [atlas.get_sheet_diagnostic_summary()]")
		if(!atlas.was_loaded_from_persistent_cache())
			if(atlas.persist_finalized_cache())
				log_debug("CustomMarkings: Canonical atlas persistent cache stored ([atlas.get_frame_count()] frames, [atlas.get_sheet_count()] shards).")
			else
				var/cache_failure_reason = atlas.get_persistent_cache_failure_reason()
				if(istext(cache_failure_reason) && length(cache_failure_reason))
					log_debug("CustomMarkings: Canonical atlas persistent cache was not stored: [cache_failure_reason].")
	else
		report_custom_marking_atlas_fallback(
			"static-manifest-fallback-enabled",
			exhausted ? "cache prewarm exhausted before the canonical atlas became client-ready" : "canonical atlas finalization failed before it became client-ready",
			"frames=[atlas.get_frame_count()], sheets=[atlas.get_sheet_count()]"
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
	var/body_ready = islist(body_marking_styles_list) && body_marking_styles_list.len
	var/basic_ready = islist(hair_styles_list) && hair_styles_list.len && islist(facial_hair_styles_list) && facial_hair_styles_list.len && islist(ear_styles_list) && ear_styles_list.len && islist(tail_styles_list) && tail_styles_list.len && islist(wing_styles_list) && wing_styles_list.len && islist(GLOB.hair_gradients) && GLOB.hair_gradients.len
	var/species_ready = islist(GLOB.all_species) && GLOB.all_species.len && islist(GLOB.playable_species) && GLOB.playable_species.len && islist(all_traits) && all_traits.len
	var/prosthetics_ready = islist(chargen_robolimbs) && chargen_robolimbs.len
	var/all_inputs_ready = body_ready && basic_ready && species_ready && prosthetics_ready
	var/needs_retry = FALSE
	var/datum/asset/spritesheet/custom_marking_designer/atlas = null
	build_custom_marking_canvas_background_cache()
	if(!all_inputs_ready)
		needs_retry = TRUE
	else
		atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
		if(!static_atlas_persistent_cache_checked)
			static_atlas_persistent_cache_checked = TRUE
			if(atlas.load_persistent_cache_for_validation())
				log_debug("CustomMarkings: Canonical atlas persistent cache candidate loaded; validating the live catalog.")
			else
				var/cache_miss_reason = atlas.get_persistent_cache_failure_reason()
				log_debug("CustomMarkings: Canonical atlas persistent cache miss: [cache_miss_reason].")
	if(all_inputs_ready && !islist(custom_marking_body_definition_cache))
		if(!islist(build_body_marking_definition_cache()))
			needs_retry = TRUE
	if(all_inputs_ready && !islist(custom_marking_basic_appearance_definition_cache))
		if(!islist(build_basic_appearance_definition_cache()))
			needs_retry = TRUE
	if(all_inputs_ready && (!islist(custom_marking_species_body_preview_cache) || !custom_marking_species_body_preview_cache.len))
		var/list/species_body_cache = build_custom_marking_species_body_preview_cache()
		if(!islist(species_body_cache) || !species_body_cache.len)
			needs_retry = TRUE
	if(all_inputs_ready && !custom_marking_prosthetic_preview_cache_complete)
		if(!build_custom_marking_prosthetic_preview_cache())
			needs_retry = TRUE
	if(all_inputs_ready && !custom_marking_gear_preview_cache_complete)
		if(!build_custom_marking_gear_preview_cache())
			needs_retry = TRUE
	if(all_inputs_ready && (!islist(custom_marking_species_catalog_cache) || !custom_marking_species_catalog_cache.len || !islist(custom_marking_species_icon_base_option_cache)))
		var/list/species_catalog_cache = build_custom_marking_species_catalog_cache()
		if(!islist(species_catalog_cache) || !species_catalog_cache.len)
			needs_retry = TRUE
	if(!needs_retry)
		if(!istype(atlas))
			atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
		if(atlas.is_persistent_cache_validation_pending())
			if(atlas.complete_persistent_cache_validation())
				static_atlas_persistent_cache_loaded = TRUE
				log_debug("CustomMarkings: Canonical atlas persistent cache hit ([atlas.get_frame_count()] frames, [atlas.get_sheet_count()] shards); pixel construction skipped.")
				complete_static_atlas_prewarm(FALSE, atlas)
				return
			var/cache_failure_reason = atlas.get_persistent_cache_failure_reason()
			log_debug("CustomMarkings: Canonical atlas persistent cache invalidated: [cache_failure_reason]. Rebuilding.")
			reset_custom_marking_static_atlas_caches()
			atlas.reset_after_persistent_cache_miss()
			static_atlas_persistent_cache_loaded = FALSE
			return try_prewarm_custom_marking_caches(retry)
		complete_static_atlas_prewarm(FALSE, atlas)
		return
	if(retry >= 30)
		log_debug("CustomMarkings: Cache prewarm failed after [retry] attempts (body=[body_marking_styles_list?.len], hair=[hair_styles_list?.len], facial=[facial_hair_styles_list?.len], gradients=[GLOB.hair_gradients?.len], ear=[ear_styles_list?.len], tail=[tail_styles_list?.len], wing=[wing_styles_list?.len], prosthetics=[chargen_robolimbs?.len], species=[GLOB.playable_species?.len]/[GLOB.all_species?.len], traits=[all_traits?.len], species_body_cache=[custom_marking_species_body_preview_cache?.len], prosthetic_cache=[custom_marking_prosthetic_preview_cache_complete], gear_cache=[custom_marking_gear_preview_cache_complete], species_catalog_cache=[custom_marking_species_catalog_cache?.len], icon_base_cache=[custom_marking_species_icon_base_option_cache?.len]).")
		complete_static_atlas_prewarm(TRUE)
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
