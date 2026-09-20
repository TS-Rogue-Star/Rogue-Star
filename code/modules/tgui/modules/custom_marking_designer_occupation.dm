///////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Occupation /////
///////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
///////////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/custom_marking_designer
	var/occupation_save_in_progress = FALSE
	var/occupation_load_in_progress = FALSE
	var/occupation_preview_generation = 0
	var/occupation_preview_signature
	var/list/occupation_preview_cache = list()
	var/list/occupation_loadout_cache = list()

/proc/occupation_preference_prefix(datum/job/job)
	switch(job?.department_flag)
		if(CIVILIAN)
			return "job_civilian"
		if(MEDSCI)
			return "job_medsci"
		if(ENGSEC)
			return "job_engsec"
		if(TALON)
			return "job_talon"
	return null

/datum/tgui_module/custom_marking_designer/proc/get_occupation_jobs()
	var/list/jobs = list()
	for(var/name in SSjob.department_datums)
		var/datum/department/department = SSjob.department_datums[name]
		if(department.centcom_only)
			continue
		for(var/title in department.primary_jobs)
			var/datum/job/job = department.primary_jobs[title]
			if(!job.latejoin_only && occupation_preference_prefix(job))
				jobs[job.title] = job
	return jobs

/datum/tgui_module/custom_marking_designer/proc/prewarm_occupation_item_sources(list/sources, list/states)
	var/list/worn_paths = list()
	var/list/jobs = get_occupation_jobs()
	for(var/name in jobs)
		var/datum/job/job = jobs[name]
		var/list/titles = list(name)
		for(var/title in job.alt_titles)
			titles |= title
		for(var/title in titles)
			var/decl/hierarchy/outfit/outfit = job.get_outfit(null, title)
			if(!outfit)
				continue
			for(var/field in list("uniform", "suit", "back", "belt", "gloves", "shoes", "head", "mask", "l_ear", "r_ear", "glasses", "id", "suit_store", "backpack", "satchel_one", "satchel_two", "satchel_three", "messenger_bag", "sports_bag", "rig"))
				var/item_type = outfit.vars[field]
				if(ispath(item_type, /obj/item))
					worn_paths[item_type] = TRUE
			for(var/item_type in outfit.uniform_accessories)
				if(ispath(item_type, /obj/item))
					worn_paths[item_type] = TRUE
	var/atom/movable/template_holder = new(null)
	for(var/item_type as anything in worn_paths)
		custom_marking_yield_heartbeat(FALSE)
		var/obj/item/item_template
		try
			item_template = new item_type(template_holder)
		catch(var/exception/error)
			item_template = locate(item_type) in template_holder
			if(!item_template)
				log_debug("Occupation atlas could not inspect worn sources for [item_type]: [error.name]")
		if(item_template)
			note_static_gear_item_sources(sources, states, item_type, item_template)
			if(istype(item_template, /obj/item/clothing/head/fishing))
				note_static_gear_source_state(sources, states, item_template.item_icons[slot_head_str], null, TRUE)
			for(var/obj/item/clothing/accessory/accessory in item_template.contents)
				note_static_gear_item_sources(sources, states, accessory.type, accessory)
		for(var/obj/item/temporary_item in template_holder)
			qdel(temporary_item)
	qdel(template_holder)

/datum/tgui_module/custom_marking_designer/proc/get_occupation_snapshot()
	var/list/snapshot = list()
	for(var/prefix in list("job_civilian", "job_medsci", "job_engsec", "job_talon"))
		for(var/level in list("high", "med", "low"))
			var/field = "[prefix]_[level]"
			snapshot[field] = prefs.vars[field]
	snapshot["player_alt_titles"] = prefs.player_alt_titles?.Copy() || list()
	snapshot["alternate_option"] = prefs.alternate_option
	snapshot["spawnpoint"] = prefs.spawnpoint
	snapshot["vantag_volunteer"] = prefs.vantag_volunteer
	snapshot["vantag_preference"] = prefs.vantag_preference
	snapshot["persistence_settings"] = prefs.persistence_settings & PERSIST_SPAWN
	return snapshot

/datum/tgui_module/custom_marking_designer/proc/get_occupation_context_signature()
	if(!prefs)
		return null
	return md5(json_encode(list(get_equipment_catalog_signature(), prefs.age, prefs.organ_data?["brain"], prefs.identifying_gender, prefs.backbag, prefs.pdachoice, prefs.all_underwear, prefs.all_underwear_metadata, prefs.shoe_hater, prefs.gear, ispAI(prefs.client?.mob))))

/datum/tgui_module/custom_marking_designer/proc/get_occupation_revision()
	return md5(json_encode(list(get_occupation_snapshot(), get_occupation_context_signature())))

/datum/tgui_module/custom_marking_designer/proc/get_occupation_priority(datum/job/job)
	if(job.type == /datum/job/assistant)
		return (prefs.job_civilian_low & job.flag) ? 3 : 4
	for(var/level = 1 to 3)
		if(prefs.GetJobDepartment(job, level) & job.flag)
			return level
	return 4

/datum/tgui_module/custom_marking_designer/proc/build_occupation_values()
	var/list/priorities = list()
	var/list/titles = list()
	var/list/jobs = get_occupation_jobs()
	for(var/name in jobs)
		var/datum/job/job = jobs[name]
		priorities[name] = get_occupation_priority(job)
		titles[name] = prefs.GetPlayerAltTitle(job)
	return list("revision" = get_occupation_revision(), "priorities" = priorities, "titles" = titles, "alternate_option" = prefs.alternate_option, "spawnpoint" = prefs.spawnpoint, "persist_spawn" = !!(prefs.persistence_settings & PERSIST_SPAWN), "vantag_volunteer" = !!prefs.vantag_volunteer, "vantag_preference" = prefs.vantag_preference, "reset" = FALSE)

/datum/tgui_module/custom_marking_designer/proc/get_occupation_restriction(datum/job/job, mob/user)
	if(!user?.client)
		return "Occupation eligibility is unavailable."
	if(jobban_isbanned(user, job.title))
		return "Banned from this occupation."
	if(!job.player_old_enough(user.client))
		return "Available in [job.available_in_days(user.client)] days."
	if(!job.player_has_enough_playtime(user.client))
		return "Requires [round(job.available_in_playhours(user.client), 0.1)] more department play hours."
	if(!is_job_whitelisted(user, job.title))
		return "Whitelist required."
	if(job.is_species_banned(prefs.species, prefs.organ_data?["brain"]) == TRUE)
		return "This species or brain type cannot take this role."
	if((job.minimum_character_age || job.min_age_by_species) && prefs.age < job.get_min_age(prefs.species, prefs.organ_data?["brain"]))
		return "Minimum character age: [job.get_min_age(prefs.species, prefs.organ_data?["brain"])]."
	return null

/datum/tgui_module/custom_marking_designer/proc/build_occupation_hours(mob/user)
	var/list/categories = list()
	for(var/datum/job/job in SSjob.occupations)
		if(job.pto_type)
			categories |= job.pto_type
	var/list/played = user?.client?.play_hours
	var/list/pto = user?.client?.department_hours
	for(var/category in played)
		categories |= category
	for(var/category in pto)
		categories |= category
	var/list/result = list()
	for(var/category in sortList(categories))
		result += list(list("department" = category, "played" = isnum(played?[category]) ? played[category] : 0, "pto" = isnum(pto?[category]) ? pto[category] : 0))
	return result

/datum/tgui_module/custom_marking_designer/proc/build_occupation_catalog(mob/user)
	var/list/jobs = get_occupation_jobs()
	var/list/entries = list()
	var/list/departments = list()
	var/list/seen_departments = list()
	for(var/name in jobs)
		var/datum/job/job = jobs[name]
		var/datum/department/department = SSjob.get_primary_department_of_job(job)
		if(!(department.name in seen_departments))
			seen_departments += department.name
			departments += list(list("id" = department.name, "color" = department.color))
		var/list/titles = list(job.title)
		for(var/title in job.alt_titles)
			titles |= title
		var/list/descriptions = list()
		for(var/title in titles)
			var/list/paragraphs = list()
			for(var/paragraph in job.get_description_blurb(title))
				if(istext(paragraph))
					paragraphs += html_decode(strip_html_simple(replacetext(paragraph, "<br>", "\n")))
			descriptions[title] = paragraphs
		var/restriction = get_occupation_restriction(job, user)
		entries += list(list("id" = name, "department" = department.name, "assistant" = job.type == /datum/job/assistant, "available" = !restriction, "restriction" = restriction, "titles" = titles, "descriptions" = descriptions, "supervisors" = html_decode(strip_html_simple(job.supervisors || "")), "departments" = job.departments || list(), "manages" = job.departments_managed || list(), "wiki_url" = config.wikiurl ? "[config.wikiurl][job.title]" : null))
	var/list/spawnpoint_options = list()
	for(var/name in spawntypes)
		spawnpoint_options += name
	var/list/event_preference_options = list()
	for(var/preference in vantag_choices_list)
		event_preference_options += list(list("value" = preference, "label" = vantag_choices_list[preference]))
	return list("jobs" = entries, "departments" = departments, "hours" = build_occupation_hours(user), "suppress_job_preview" = ispAI(user), "spawnpoint_options" = spawnpoint_options, "event_preference_options" = event_preference_options)

/datum/tgui_module/custom_marking_designer/proc/validate_occupation_payload(list/values, mob/user, list/errors)
	if(!islist(values) || values["revision"] != get_occupation_revision())
		errors += "This Occupation draft is out of date. Reload saved Occupation and try again."
		return null
	var/list/jobs = get_occupation_jobs()
	var/list/priorities = values["priorities"]
	var/list/titles = values["titles"]
	if(!islist(priorities) || !islist(titles) || priorities.len != jobs.len || titles.len != jobs.len)
		errors += "Occupation must include every listed job and title."
		return null
	if(!(values["alternate_option"] in list(GET_RANDOM_JOB, BE_ASSISTANT, RETURN_TO_LOBBY)) || !(values["reset"] in list(TRUE, FALSE)))
		errors += "Choose a valid fallback option."
		return null
	if(!istext(values["spawnpoint"]) || !spawntypes[values["spawnpoint"]])
		errors += "Choose a valid spawn location."
		return null
	if(!(values["vantag_volunteer"] in list(TRUE, FALSE)))
		errors += "Choose a valid event participation setting."
		return null
	if(!istext(values["vantag_preference"]) || !(values["vantag_preference"] in vantag_choices_list))
		errors += "Choose a valid event preference."
		return null
	var/persistence_values = validate_designer_persistence_settings(prefs.persistence_settings, values, list("persist_spawn" = PERSIST_SPAWN))
	if(isnull(persistence_values))
		errors += "Choose a valid spawn persistence setting."
		return null
	var/datum/job/new_high
	for(var/name in jobs)
		var/datum/job/job = jobs[name]
		var/priority = priorities[name]
		var/title = titles[name]
		if(!isnum(priority) || !(priority in list(1, 2, 3, 4)) || (job.type == /datum/job/assistant && !(priority in list(3, 4))))
			errors += "Choose a valid preference for [name]."
			return null
		if(!istext(title) || (title != name && !(title in job.alt_titles)))
			errors += "Choose a valid alternate title for [name]."
			return null
		if(priority == 1)
			if(new_high)
				errors += "Only one occupation can have High priority."
				return null
			new_high = job
		if((priority < get_occupation_priority(job)) || (title != prefs.GetPlayerAltTitle(job) && title != name))
			var/restriction = get_occupation_restriction(job, user)
			if(restriction)
				errors += "[name]: [restriction]"
				return null
	var/list/staged = get_occupation_snapshot()
	var/list/alt_titles = staged["player_alt_titles"]
	for(var/prefix in list("job_civilian", "job_medsci", "job_engsec", "job_talon"))
		if(values["reset"])
			for(var/level in list("high", "med", "low"))
				staged["[prefix]_[level]"] = 0
		else if(new_high && get_occupation_priority(new_high) != 1)
			staged["[prefix]_med"] |= staged["[prefix]_high"]
			staged["[prefix]_high"] = 0
	if(values["reset"])
		alt_titles.Cut()
	var/list/levels = list("high", "med", "low")
	for(var/name in jobs)
		var/datum/job/job = jobs[name]
		var/prefix = occupation_preference_prefix(job)
		var/priority = priorities[name]
		var/title = titles[name]
		for(var/level in levels)
			staged["[prefix]_[level]"] &= ~job.flag
		if(priority <= 3)
			staged["[prefix]_[levels[priority]]"] |= job.flag
		alt_titles -= name
		if(title != name)
			alt_titles[name] = title
	staged["alternate_option"] = values["alternate_option"]
	staged["spawnpoint"] = values["spawnpoint"]
	staged["vantag_volunteer"] = values["vantag_volunteer"]
	staged["vantag_preference"] = values["vantag_preference"]
	staged["persistence_settings"] = persistence_values
	return staged

/datum/tgui_module/custom_marking_designer/proc/build_occupation_preview(datum/job/job, title)
	var/key = job ? "[job.title]\n[title]" : "none"
	if(occupation_preview_cache[key])
		return occupation_preview_cache[key]
	var/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin = get_static_gear_recipe_mannequin()
	var/static/list/layers = list(6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27)
	var/list/override = list("job" = job, "title" = title)
	var/list/gear = list("equipment" = list(), "job" = list(), "loadout" = list())
	var/list/tail_override
	var/exception/build_error
	try
		reset_mannequin_equipment(mannequin, layers)
		copy_preferences_to_mannequin_without_marking(mannequin)
		tail_override = apply_preview_tail_override(mannequin)
		for(var/mode in list(EQUIP_PREVIEW_EQUIPMENT, EQUIP_PREVIEW_JOB, EQUIP_PREVIEW_LOADOUT))
			reset_mannequin_equipment(mannequin, layers)
			var/family = mode == EQUIP_PREVIEW_EQUIPMENT ? "equipment" : (mode == EQUIP_PREVIEW_JOB ? "job" : "loadout")
			var/loadout_key = job ? job.title : "none"
			if(mode == EQUIP_PREVIEW_LOADOUT && occupation_loadout_cache[loadout_key])
				gear[family] = occupation_loadout_cache[loadout_key]
				continue
			if(mode == EQUIP_PREVIEW_EQUIPMENT)
				mannequin.update_underwear()
			prefs.equip_prepared_preview_mob(mannequin, mode, override)
			var/list/directions = list()
			for(var/dir in direction_order)
				directions["[dir]"] = build_static_gear_overlay_assets_for_layers(mannequin, dir, layers) || list()
			gear[family] = directions
			if(mode == EQUIP_PREVIEW_LOADOUT)
				occupation_loadout_cache[loadout_key] = directions
	catch(var/exception/error)
		build_error = error
	reset_mannequin_equipment(mannequin, layers)
	if(tail_override)
		restore_preview_tail_override(tail_override)
	if(build_error)
		throw build_error
	var/list/result = list("key" = key, "gear" = gear, "silicon" = job && (job.type == /datum/job/ai || job.type == /datum/job/cyborg))
	occupation_preview_cache[key] = result
	return result

/datum/tgui_module/custom_marking_designer/proc/stream_occupation_previews(mob/user, request_id, generation, signature, list/queue)
	set waitfor = FALSE
	var/next = 1
	var/sequence = 0
	while(next <= queue.len)
		sleep(world.tick_lag > 0 ? world.tick_lag : 1)
		CHECK_TICK
		if(QDELETED(src) || generation != occupation_preview_generation || signature != get_occupation_context_signature() || !SStgui.get_open_ui(user, src))
			return
		var/list/previews = list()
		var/exception/build_error
		acquire_preview_payload_build_lock()
		try
			if(generation != occupation_preview_generation || signature != get_occupation_context_signature())
				release_preview_payload_build_lock()
				return
			while(next <= queue.len && previews.len < 4)
				var/list/task = queue[next++]
				previews += list(build_occupation_preview(task["job"], task["title"]))
				if(TICK_CHECK)
					break
		catch(var/exception/error)
			build_error = error
		release_preview_payload_build_lock()
		if(QDELETED(src) || generation != occupation_preview_generation || signature != get_occupation_context_signature())
			return
		var/list/batch = list("request_id" = request_id, "recipe_signature" = signature, "sequence" = ++sequence, "previews" = previews, "complete" = next > queue.len || !!build_error)
		if(build_error)
			log_error("Character Designer Occupation previews failed: [build_error.name]")
			batch["error"] = "Some occupation outfits could not be loaded. Retry previews to continue."
		var/datum/tgui/ui = SStgui.get_open_ui(user, src)
		ui?.send_update(list("occupation_preview_batch" = batch))
		if(build_error)
			return

/datum/tgui_module/custom_marking_designer/proc/handle_occupation_action(action, list/params, mob/user)
	if(!(action in list("load_occupation", "save_occupation", "close_occupation")))
		return FALSE
	if(action == "close_occupation")
		if(!occupation_save_in_progress)
			SStgui.close_uis(src)
		return TRUE
	if(!prefs || !user)
		return TRUE
	var/request_id = params?["request_id"]
	var/saving = action == "save_occupation"
	var/list/response = list("request_id" = request_id)
	var/list/errors = list()
	var/list/queue = list()
	var/generation
	var/accepted = FALSE
	if(occupation_save_in_progress || occupation_load_in_progress)
		errors += "An Occupation request is already in progress."
	else
		occupation_save_in_progress = saving
		occupation_load_in_progress = !saving
		acquire_preview_payload_build_lock()
		try
			if(!SSjob.occupations.len)
				errors += "Occupations are still loading. Please try again."
			else if(saving)
				var/list/values = json_decode(params?["occupation"])
				var/list/staged = validate_occupation_payload(values, user, errors)
				if(islist(staged))
					for(var/field in staged)
						prefs.vars[field] = staged[field]
					accepted = TRUE
			if(!errors.len)
				response["values"] = build_occupation_values()
				response["catalog"] = build_occupation_catalog(user)
				var/signature = get_occupation_context_signature()
				response["context_signature"] = signature
				if(!saving)
					generation = ++occupation_preview_generation
					if(occupation_preview_signature != signature)
						occupation_preview_cache = list()
						occupation_loadout_cache = list()
						occupation_preview_signature = signature
					if(!custom_marking_gear_preview_cache_complete)
						response["preview_complete"] = TRUE
						errors += "Occupation outfit previews are unavailable. You can still edit and save your settings."
					else
						build_occupation_preview(null, null)
						var/datum/job/selected_job = prefs.get_loadout_preview_job()
						if(selected_job)
							build_occupation_preview(selected_job, prefs.GetPlayerAltTitle(selected_job))
						var/list/previews = list()
						for(var/key in occupation_preview_cache)
							previews += list(occupation_preview_cache[key])
						response["previews"] = previews
						var/list/jobs = get_occupation_jobs()
						for(var/name in jobs)
							var/datum/job/job = jobs[name]
							var/list/titles = list(job.title)
							for(var/title in job.alt_titles)
								titles |= title
							for(var/title in titles)
								if(!occupation_preview_cache["[name]\n[title]"])
									queue += list(list("job" = job, "title" = title))
						response["preview_complete"] = !queue.len
		catch(var/exception/error)
			log_error("Character Designer Occupation [action] failed: [error.name]")
			errors += "Occupation could not be processed. Please try again."
		release_preview_payload_build_lock()
		occupation_save_in_progress = FALSE
		occupation_load_in_progress = FALSE
	if(errors.len)
		response["error"] = jointext(errors, " ")
	if(saving)
		response["accepted"] = accepted
	var/datum/tgui/ui = SStgui.get_open_ui(user, src)
	ui?.send_update(list((saving ? "occupation_save_result" : "occupation_payload") = response, "occupation_context_signature" = get_occupation_context_signature(), "equipment_context_signature" = get_equipment_context_signature(), "loadout_context_signature" = get_loadout_context_signature()))
	if(ui && !saving && !errors.len && queue.len)
		stream_occupation_previews(user, request_id, generation, response["context_signature"], queue)
	if(accepted)
		try
			refresh_preferences_window_if_visible(TRUE)
		catch(var/exception/error)
			log_error("Occupation saved, but preferences refresh failed: [error.name]")
	return TRUE
