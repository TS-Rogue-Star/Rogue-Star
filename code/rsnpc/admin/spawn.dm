GLOBAL_LIST_INIT(npc_test_crew, list(
	/datum/job/chef = "Luigi Mangiare",
	/datum/job/hydro = "Old MacDonald",
	/datum/job/bartender = "Porza Lott",
	/datum/job/janitor = "Slipp Slyde",
	/datum/job/librarian = "Rita Booke",
	/datum/job/chaplain = "Pastor Sermo",
	/datum/job/lawyer = "Arby Tration",
	/datum/job/engineer = "Zapp Shockawitz",
	/datum/job/atmos = "Kant Breethe",
	/datum/job/doctor = "Sawyer Bones",
	/datum/job/paramedic = "Amby Lanza",
	/datum/job/chemist = "Khloe Hydrate",
	/datum/job/psychiatrist = "Siggy Mund",
	/datum/job/officer = "Renta Copp",
	/datum/job/warden = "Lockie Brigg",
	/datum/job/detective = "Ferret Emmout",
	/datum/job/scientist = "Theo Ritical",
	/datum/job/roboticist = "Chopin Borgem",
	/datum/job/cargo_tech = "Karg O'Tech",
	/datum/job/mining = "Min Ing",
	/datum/job/assistant = "Grey Short",
	/datum/job/intern = "Kammon Foader",
))

/proc/spawn_npc_worker(turf/T, job_title, species_name, gender_choice, name_choice, manifest, datum/npc_character/character)
	var/mob/living/carbon/human/ai_controlled/rsnpc/station/W = new(T, job_title, species_name, gender_choice, name_choice, character)
	if(QDELETED(W))
		return null
	if(manifest)
		data_core.manifest_inject(W)
		var/datum/ai_holder/rsnpc/ai_mind = npc_ai_mind(W)
		var/datum/job/J = SSjob.get_job(W.mind?.assigned_role)
		var/list/records = J?.offmap_spawn ? data_core.hidden_general : data_core.general
		for(var/datum/data/record/R in records)
			if(ai_mind && R.fields["name"] == W.real_name)
				ai_mind.record_id = R.fields["id"]
	return W

/datum/ai_holder/rsnpc/proc/leave_records()
	if(!record_id)
		return
	var/name
	for(var/list/records in list(data_core.general, data_core.hidden_general, data_core.medical, data_core.hidden_medical, data_core.security, data_core.hidden_security, data_core.locked))
		for(var/datum/data/record/R in records.Copy())
			if(R.fields["id"] == record_id)
				name = name || R.fields["name"]
				records -= R
				qdel(R)
	PDA_Manifest.Cut()
	message_admins("RSNPC [name] left the round and was taken off the crew manifest and records.")
	record_id = null

/proc/npc_job_titles()
	. = list()
	for(var/datum/job/J as anything in SSjob.occupations)
		if(J.mob_type & JOB_CARBON)
			. += J.title
	. = sortList(.)

/proc/npc_arrival_points(job_title)
	. = list()
	for(var/name in using_map.allowed_spawns)
		var/datum/spawnpoint/S = spawntypes[name]
		if(S && length(S.turfs) && S.check_job_spawning(job_title))
			. += S

/proc/npc_spawn_places(job_title)
	. = list(NPC_PLACE_ARRIVAL)
	for(var/datum/spawnpoint/S as anything in npc_arrival_points(job_title))
		. += S.display_name
	. += list(NPC_PLACE_WORKPLACE, NPC_PLACE_HERE)

/proc/npc_spawn_turf(job_title, where, turf/here)
	var/list/locs = list()
	switch(where)
		if(NPC_PLACE_HERE)
			locs += here
		if(NPC_PLACE_WORKPLACE)
			for(var/obj/effect/landmark/start/S in landmarks_list)
				if(S.name == job_title)
					locs += get_turf(S)
		if(NPC_PLACE_ARRIVAL)
			var/list/points = npc_arrival_points(job_title)
			if(length(points))
				var/datum/spawnpoint/P = pick(points)
				locs += P.turfs
		else
			for(var/datum/spawnpoint/P as anything in npc_arrival_points(job_title))
				if(P.display_name == where)
					locs += P.turfs
	if(!length(locs))
		return null
	shuffle_inplace(locs)
	for(var/turf/T as anything in locs)
		if(!(locate(/mob/living) in T))
			return T
	return locs[1]

/client/proc/npc_spawn_crewman()
	set category = "Special Verbs"
	set name = "Spawn NPC Crewman"
	set desc = "Spawn a NPC crewperson."

	if(!check_rights(R_SPAWN))
		return
	var/datum/npc_character/character
	var/list/characters = npc_characters()
	if(GLOB.npc_character_problems)
		to_chat(src, "<span class='warning'>[GLOB.npc_character_problems] character file\s could not be loaded; see the server log.</span>")
	if(length(characters))
		var/list/choices = list()
		var/list/names = list()
		for(var/id in characters)
			var/datum/npc_character/C = characters[id]
			var/label = "[C.job] - [C.name] ([id])"
			choices[label] = C
			names += label
		var/who = tgui_input_list(src, "Who?", "Spawn NPC Crewman", list(NPC_GENERIC_WORKER) + sortList(names))
		if(!who)
			return
		character = choices[who]
	var/job_title = character?.job
	var/species_name
	var/gender_choice
	var/count = 1
	if(!character)
		job_title = tgui_input_list(src, "Job?", "Spawn NPC Crewman", npc_job_titles())
		if(!job_title)
			return
		species_name = tgui_input_list(src, "Species?", "Spawn NPC Crewman", list("Random") + GLOB.npc_species)
		if(!species_name)
			return
		gender_choice = tgui_input_list(src, "Gender?", "Spawn NPC Crewman", list("Random", MALE, FEMALE))
		if(!gender_choice)
			return
		count = tgui_input_number(src, "Quantity?", "Spawn NPC Crewman", 1, 20, 1, round_value = TRUE)
		if(!count)
			return
	var/where = tgui_input_list(src, "Where?", "Spawn NPC Crewman", npc_spawn_places(job_title))
	if(!where)
		return
	var/answer = tgui_alert(src, "Add to manifest??", "Spawn NPC Crewman", list("Yes", "No"))
	if(!answer)
		return
	var/name_choice
	if(count == 1 && !character)
		name_choice = sanitizeName(tgui_input_text(src, "Name? Leave blank for a random one.", "Spawn NPC Crewman"))
	for(var/i in 1 to count)
		var/turf/T = npc_spawn_turf(job_title, where, get_turf(mob))
		if(!T)
			to_chat(src, "<span class='warning'>No [lowertext(where)] for [job_title].</span>")
			return
		var/mob/living/W = spawn_npc_worker(T, job_title, species_name == "Random" ? null : species_name, gender_choice == "Random" ? null : gender_choice, name_choice, answer == "Yes", character)
		if(!W)
			to_chat(src, "<span class='warning'>Could not make a [job_title].</span>")
			return
		log_admin("[key_name(src)] spawned NPC [job_title] [W.real_name] in [get_area(W)] [COORD(W)].")
		message_admins("[key_name_admin(src)] spawned NPC [job_title] [W.real_name]. [ADMIN_FLW(W)]")

/client/proc/npc_spawn_test_crew()
	set category = "Special Verbs"
	set name = "Spawn NPC Test Crew"
	set desc = "Spawn a whole NPC test crew."

	if(!check_rights(R_SPAWN))
		return
	if(tgui_alert(src, "Spawn [length(GLOB.npc_test_crew)] NPCs at the arrival points? (WARNING: DO NO MORE THAN ONCE PER ROUND, AND IT WILL LAG)", "Spawn NPC Test Crew", list("Yes", "No")) != "Yes")
		return
	var/list/created = list()
	var/list/failed = list()
	for(var/job_type in GLOB.npc_test_crew)
		var/datum/job/J = SSjob.get_job_type(job_type)
		if(!J)
			failed += "[job_type]: invalid job"
			continue
		var/turf/T = npc_spawn_turf(J.title, NPC_PLACE_ARRIVAL, get_turf(mob))
		if(!T)
			failed += "[J.title]: couldn't find [lowertext(NPC_PLACE_ARRIVAL)]"
			continue
		var/list/picks = list()
		for(var/id in npc_characters())
			var/datum/npc_character/C = GLOB.npc_characters[id]
			if(C.job == J.title && findtext(id, "example_") != 1)
				picks += C
		var/mob/living/W = spawn_npc_worker(T, J.title, null, null, GLOB.npc_test_crew[job_type], TRUE, length(picks) ? pick(picks) : null)
		if(!W)
			failed += "[J.title]: couldn't make"
			continue
		created += "[W.real_name], [J.title] [ADMIN_FLW(W)]"
	to_chat(src, "<span class='notice'><b>Test crew:</b><br>[jointext(created, "<br>")]</span>")
	if(length(failed))
		to_chat(src, "<span class='warning'><b>Not placed:</b><br>[jointext(failed, "<br>")]</span>")
	log_admin("[key_name(src)] spawned the NPC test crew ([length(created)] placed, [length(failed)] not) at [lowertext(NPC_PLACE_ARRIVAL)].")
	message_admins("[key_name_admin(src)] spawned the NPC test crew: [length(created)] placed, [length(failed)] failed.")
