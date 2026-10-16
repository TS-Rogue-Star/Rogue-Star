GLOBAL_LIST_INIT(npc_recall_lines, list(
	"say_recall_violence_justified",
	"say_recall_violence",
	"say_recall_death",
))

GLOBAL_LIST_INIT(npc_wellbeing_lines, list(
	NPC_NEED_HEALTH = "say_wellbeing_health",
	NPC_NEED_HUNGER = "say_wellbeing_hunger",
	NPC_NEED_REST = "say_wellbeing_relaxation",
))

/datum/npc_command/where_are_you
	say = "where are you"
	radio = TRUE
	repeat = 5 SECONDS

/datum/npc_command/where_are_you/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/list/blanks = list("name" = speaker.name, "place" = "[get_area(ai_mind.holder)]")
	if(!ai_mind.task)
		ai_mind.say_line("say_whereabouts_idle", blanks, via)
		return
	blanks["task"] = ai_mind.task.name
	ai_mind.say_line("say_whereabouts_doing", blanks, via)

/datum/npc_command/what_are_you_doing
	say = "what are you doing"
	radio = TRUE
	repeat = 8 SECONDS
	friendly = TRUE

/datum/npc_command/what_are_you_doing/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	if(!ai_mind.task)
		ai_mind.say_line("say_doing_idle", list("name" = speaker.name), via)
		return
	ai_mind.say_line("say_doing", list("name" = speaker.name, "task" = ai_mind.task.name), via)

/datum/npc_command/how_are_you
	say = "how are you"
	radio = TRUE
	repeat = 8 SECONDS
	friendly = TRUE

/datum/npc_command/how_are_you/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/group = "say_wellbeing_fine"
	var/worst = 0.35
	for(var/need in GLOB.npc_wellbeing_lines)
		var/pressure = ai_mind.need_pressure(need)
		if(pressure > worst)
			worst = pressure
			group = GLOB.npc_wellbeing_lines[need]
	ai_mind.say_line(group, list("name" = speaker.name), via)

/datum/npc_command/what_do_you_think_of
	say = "what do you think of"
	radio = TRUE
	repeat = 8 SECONDS
	friendly = TRUE

/datum/npc_command/what_do_you_think_of/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	for(var/key in ai_mind.opinions)
		if(npc_clean_line(key) != rest)
			continue
		var/datum/npc_person/P = ai_mind.opinions[key]
		var/group = "say_opinion_neutral"
		if(P.opinion >= ai_mind.npc_psetting("opinion_loved_at"))
			group = "say_opinion_loved"
		else if(P.opinion >= ai_mind.npc_psetting("opinion_liked_at"))
			group = "say_opinion_liked"
		else if(P.opinion <= ai_mind.npc_psetting("opinion_hated_at"))
			group = "say_opinion_hated"
		else if(P.opinion <= ai_mind.npc_psetting("opinion_disliked_at"))
			group = "say_opinion_disliked"
		ai_mind.say_line(group, list("name" = P.key), via)
		var/danger = P.danger_now()
		if(danger >= NPC_DANGEROUS)
			ai_mind.say_line("say_opinion_dangerous", list("name" = P.key), via)
		else if(danger >= NPC_WARY)
			ai_mind.say_line("say_opinion_wary", list("name" = P.key), via)
		return
	for(var/datum/data/record/R in data_core.general)
		if(npc_clean_line(R.fields["name"]) == rest)
			ai_mind.say_line("say_opinion_unknown", list("name" = R.fields["name"]), via)
			return
	ai_mind.say_line("say_opinion_nobody", list("name" = speaker.name), via)

/datum/npc_command/did_you_see_anything
	say = "did you see anything"
	repeat = 8 SECONDS
	friendly = TRUE

/datum/npc_command/did_you_see_anything/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/datum/npc_event/E = ai_mind.memory_for(speaker)
	if(!E)
		ai_mind.say_line("say_witness_nothing", list("name" = speaker.name), via)
		return
	ai_mind.tell_memory(E, speaker, via)

/datum/ai_holder/rsnpc/proc/memory_for(mob/living/M)
	var/key = npc_person_key(M)
	var/datum/npc_event/best
	for(var/datum/npc_event/E as anything in witnessed)
		if(E.told >= 2 || (key in E.told_to) || E.key == key || E.other_key == key)
			continue
		if(!best || E.kind > best.kind)
			best = E
	return best

/datum/ai_holder/rsnpc/proc/tell_memory(datum/npc_event/E, mob/living/M, via)
	E.told++
	E.told_to += npc_person_key(M)
	say_line(GLOB.npc_recall_lines[E.kind], list("name" = E.name, "other" = E.other), via)

/datum/npc_command/what_do_you_need
	say = "what do you need"
	radio = TRUE
	repeat = 8 SECONDS

/datum/npc_command/what_do_you_need/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/list/blanks = list("name" = speaker.name)
	var/list/missing = ai_mind.plan_missing()
	if(length(missing))
		var/obj/item/kind = text2path(copytext(missing[1], 6))
		blanks["thing"] = initial(kind.name)
		blanks["task"] = ai_mind.task.name
		ai_mind.say_line("need_for_job", blanks, via)
		return
	var/key = ai_mind.gave_up_key()
	if(key)
		var/obj/item/kind = text2path(copytext(key, 10))
		var/datum/npc_task/given_up = ai_mind.noted(key)
		blanks["thing"] = initial(kind.name)
		blanks["task"] = initial(given_up.name)
		ai_mind.say_line("need_gave_up", blanks, via)
		return
	ai_mind.say_line("need_nothing", blanks, via)
