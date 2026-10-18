/datum/npc_assignment
	var/name = "assignment"
	var/datum/weakref/asker
	var/datum/weakref/from
	var/asker_name
	var/asker_key
	var/via
	var/started = 0
	var/until = 0
	var/failures = 0
	var/max_failures = 3
	var/failed_line
	var/uses_legs = FALSE
	var/urgent = FALSE
	var/state = FALSE
	var/weight = 0
	var/importance = 0
	var/time_up_line

/datum/npc_assignment/New(mob/living/M, via, time, mob/living/from)
	asker = WEAKREF(M)
	src.from = WEAKREF(from || M)
	asker_name = M.name
	asker_key = npc_person_key(M)
	src.via = via
	started = world.time
	until = world.time + time

/datum/npc_assignment/proc/blanks()
	return list("name" = asker_name)

/datum/npc_assignment/proc/goal(datum/ai_holder/rsnpc/ai_mind)
	return list()

/datum/npc_assignment/proc/needs_legs(datum/ai_holder/rsnpc/ai_mind)
	return uses_legs

/datum/npc_assignment/proc/wants_turn(datum/ai_holder/rsnpc/ai_mind)
	return TRUE

/datum/npc_assignment/proc/ended(datum/ai_holder/rsnpc/ai_mind)
	return

/datum/npc_assignment/proc/check(datum/ai_holder/rsnpc/ai_mind)
	if(world.time > until)
		ai_mind.end_assignment(src, "time's up", time_up_line)

/datum/npc_assignment/proc/plan_failed(datum/ai_holder/rsnpc/ai_mind, why)
	if(++failures >= max_failures)
		ai_mind.end_assignment(src, why, failed_line)
		return
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "[name] for [asker_name] failed [failures] of [max_failures] times, trying again in 5s; [why]")

/datum/ai_holder/rsnpc/proc/active_request()
	var/datum/npc_assignment/best
	for(var/datum/npc_assignment/A as anything in assignments)
		if(!A.state && A.wants_turn(src) && (!best || A.importance > best.importance))
			best = A
	return best

/datum/ai_holder/rsnpc/proc/assignment(type)
	var/datum/npc_assignment/R = active_request()
	if(istype(R, type))
		return R
	for(var/datum/npc_assignment/A as anything in assignments)
		if(istype(A, type))
			return A
	return null

/datum/ai_holder/rsnpc/proc/importance_of(datum/npc_assignment/A)
	var/mob/living/M = A.from?.resolve()
	. = A.weight + (A.urgent ? 100 : 0)
	if(M && M != holder)
		. += npc_psetting("obedience_base") + opinion_of(M) * npc_psetting("obedience_opinion_weight") + rank_bonus(M)

/datum/ai_holder/rsnpc/proc/start_assignment(datum/npc_assignment/A, group)
	A.importance = importance_of(A)
	var/list/requests = list()
	for(var/datum/npc_assignment/old as anything in assignments.Copy())
		if(old.type == A.type && (A.state || old.asker_key == A.asker_key))
			end_assignment(old, "replaced by [A.name]")
		else if(!old.state)
			requests += old
	var/datum/npc_assignment/before = active_request()
	if(!A.state && length(requests) >= 5)
		var/datum/npc_assignment/least
		for(var/datum/npc_assignment/R as anything in requests)
			if(!least || R.importance < least.importance)
				least = R
		if(A.importance <= least.importance)
			NPC_TRACE(src, NPC_TRACE_TASK, "turned down [A.name] for [A.asker_name]; too much to do")
			say_line("assignment_queue_full", A.blanks(), A.via)
			return FALSE
		end_assignment(least, "pushed out by [A.name]", "assignment_dropped")
	assignments += A
	var/datum/npc_assignment/now = active_request()
	var/queued = !A.state && now && now != A
	NPC_TRACE(src, NPC_TRACE_TASK, "agreed to [A.name] for [A.asker_name] ([round(A.importance)])[queued ? ", after [now.name]" : ""][before && now == A && before != A ? ", putting [before.name] aside" : ""]")
	if(queued)
		say_line("assignment_queued", A.blanks(), A.via)
	else if(group)
		say_now(group, A.blanks(), A.via)
	return TRUE

/datum/ai_holder/rsnpc/proc/end_assignment(datum/npc_assignment/A, why, group, mob/living/by)
	assignments -= A
	NPC_TRACE(src, NPC_TRACE_TASK, "ended [A.name] for [A.asker_name]; [why]")
	A.ended(src)
	if(group)
		var/list/blanks = A.blanks()
		blanks["task"] = A.name
		if(by)
			blanks["name"] = by.name
		say_line(group, blanks, by ? null : A.via)
	if(task?.assignment_type && istype(A, task.assignment_type))
		clear_task()

/datum/ai_holder/rsnpc/proc/check_assignments()
	for(var/datum/npc_assignment/A as anything in assignments.Copy())
		if(A in assignments)
			A.check(src)
