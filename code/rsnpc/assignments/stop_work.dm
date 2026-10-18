/datum/npc_command/stop_work
	say = "stop work"
	obedience = 21

/datum/npc_command/stop_work/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	if(ai_mind.assignment(/datum/npc_assignment/stop_work))
		ai_mind.say_line("already_stopped_work", list("name" = speaker.name))
		return
	ai_mind.start_assignment(new /datum/npc_assignment/stop_work(speaker, null, ai_mind.npc_psetting("stop_work_minutes") MINUTES), "stop_work_agreed")
	if(ai_mind.task?.stopped(ai_mind))
		ai_mind.clear_task()

/datum/npc_command/back_to_work
	say = "back to work"

/datum/npc_command/back_to_work/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/datum/npc_assignment/stop_work/A = ai_mind.assignment(/datum/npc_assignment/stop_work)
	if(!A)
		ai_mind.say_line("stop_work_never_stopped", list("name" = speaker.name))
		return
	ai_mind.end_assignment(A, "[speaker] released me to work again", "stop_work_released", speaker)

/datum/npc_assignment/stop_work
	state = TRUE
	name = "stop work"
	time_up_line = "stop_work_done"
