GLOBAL_LIST_INIT(npc_alarm_words, list("attacking", "killing", "stabbing", "shooting", "murdering", "beating", "dangerous", "hostile", "armed"))

/datum/ai_holder/rsnpc/proc/known_names()
	. = list()
	for(var/key in opinions)
		. |= key
	for(var/datum/data/record/R in data_core.general)
		. |= R.fields["name"]

/proc/npc_reported(line, list/names)
	var/found
	for(var/word in GLOB.npc_alarm_words)
		if(!npc_has_words(line, "is [word]"))
			continue
		for(var/name in names)
			if(length(name) > length(found) && npc_has_words(line, "[name] is [word]"))
				found = name
	return found

/proc/npc_report_victim(line, attacker, speaker, list/names)
	for(var/word in GLOB.npc_alarm_words)
		if(npc_has_words(line, "[attacker] is [word] me"))
			return speaker
		for(var/name in names)
			if(name != attacker && npc_has_words(line, "[attacker] is [word] [name]"))
				return name
	return null

/datum/ai_holder/rsnpc/proc/hear_report(mob/living/speaker, line, via)
	if(!via)
		return FALSE
	var/list/names = known_names()
	var/reported = npc_reported(line, names)
	var/speaker_key = npc_person_key(speaker)
	if(!reported || reported == npc_person_key(holder) || reported == speaker_key)
		return FALSE
	var/victim = npc_report_victim(line, reported, speaker_key, names)
	if(victim && danger_of(victim) >= NPC_DANGEROUS)
		NPC_TRACE(src, NPC_TRACE_WITNESS, "heard [speaker] report [reported], but [victim] is dangerous")
		return TRUE
	var/liking = opinion_of(reported)
	if(liking >= npc_setting("friend_ignores_claims_at") && opinion_of(speaker) < liking)
		NPC_TRACE(src, NPC_TRACE_WITNESS, "didn't believe [speaker] about [reported]; they're my friend")
		return TRUE
	var/key = "report:\ref[speaker]:[reported]"
	if(noted(key))
		NPC_TRACE(src, NPC_TRACE_WITNESS, "ignored a report on [reported] from [speaker]; repeated too soon")
		return TRUE
	note(key, speaker.name, 2 MINUTES)
	add_danger(reported, npc_setting("report_points") * clamp(1 - liking / 100, 0, 1), "reported on the radio by [speaker]")
	change_opinion(reported, -10, "reported on the radio by [speaker]")
	return TRUE
