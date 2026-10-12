/datum/npc_assignment
	var/name = "assignment"
	var/datum/weakref/asker
	var/asker_name
	var/asker_key
	var/via
	var/started = 0
	var/until = 0
	var/failures = 0
	var/max_failures = 3
	var/failed_line
	var/uses_legs = FALSE
	var/time_up_line

/datum/npc_assignment/New(mob/living/M, via, time)
	asker = WEAKREF(M)
	asker_name = M.name
	asker_key = npc_person_key(M)
	src.via = via
	started = world.time
	until = world.time + time

/datum/npc_assignment/proc/blanks()
	return list("name" = asker_name)

/datum/npc_assignment/proc/goal(datum/ai_holder/complex_npc/ai_mind)
	return list()

/datum/npc_assignment/proc/ended(datum/ai_holder/complex_npc/ai_mind)
	return

/datum/npc_assignment/proc/check(datum/ai_holder/complex_npc/ai_mind)
	if(world.time > until)
		ai_mind.end_assignment(src, "time's up", time_up_line)

/datum/npc_assignment/proc/plan_failed(datum/ai_holder/complex_npc/ai_mind, why)
	if(++failures >= max_failures)
		ai_mind.end_assignment(src, why, failed_line)
		return
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "[name] for [asker_name] failed [failures] of [max_failures] times, trying again in 5s; [why]")

/datum/ai_holder/complex_npc/proc/assignment(type)
	for(var/datum/npc_assignment/A as anything in assignments)
		if(istype(A, type))
			return A
	return null

/datum/ai_holder/complex_npc/proc/start_assignment(datum/npc_assignment/A, group)
	for(var/datum/npc_assignment/old as anything in assignments.Copy())
		if(old.type == A.type || (A.uses_legs && old.uses_legs))
			end_assignment(old, "replaced by [A.name]")
	assignments += A
	NPC_TRACE(src, NPC_TRACE_TASK, "agreed to [A.name] for [A.asker_name]")
	if(group)
		say_line(group, A.blanks(), A.via)

/datum/ai_holder/complex_npc/proc/end_assignment(datum/npc_assignment/A, why, group, mob/living/by)
	assignments -= A
	NPC_TRACE(src, NPC_TRACE_TASK, "ended [A.name] for [A.asker_name]; [why]")
	A.ended(src)
	if(group)
		var/list/blanks = A.blanks()
		if(by)
			blanks["name"] = by.name
		say_line(group, blanks, by ? null : A.via)
	if(task?.assignment_type && istype(A, task.assignment_type))
		clear_task()

/datum/ai_holder/complex_npc/proc/check_assignments()
	for(var/datum/npc_assignment/A as anything in assignments.Copy())
		if(A in assignments)
			A.check(src)
