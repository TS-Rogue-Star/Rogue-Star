/datum/ai_holder/rsnpc/proc/choose_task()
	if(reflex_in_control())
		return
	var/datum/npc_task/best
	var/best_score = 0
	var/best_level = 0
	for(var/datum/npc_task/T as anything in tasks)
		var/s = T.score(src)
		if(s <= 0)
			continue
		var/level = T.level(src)
		if(!best || level > best_level || (level == best_level && s > best_score))
			best = T
			best_score = s
			best_level = level
	if(task && best != task)
		var/now = task.score(src)
		var/finishing = task.must_finish(src)
		if(task.stopped(src) && !finishing)
			NPC_TRACE(src, NPC_TRACE_TASK, "dropping [task.name]; told to stop")
			clear_task()
		else if(best)
			var/level = task.level(src)
			if(level == best_level && best_score <= now * 1.25)
				return
			if(best_level < NPC_TIER_NEEDS && finishing)
				return
			NPC_TRACE(src, NPC_TRACE_TASK, "dropping [task.name] ([now]) for [best.name] ([best_score])")
	if(!best || best == task)
		return
	switch_to(best, best_score)

/datum/ai_holder/rsnpc/proc/switch_to(datum/npc_task/T, score)
	clear_task()
	task = T
	replans = 0
	NPC_TRACE(src, NPC_TRACE_TASK, "starting [T.name] ([score])")

/datum/ai_holder/rsnpc/proc/task_done()
	NPC_TRACE(src, NPC_TRACE_TASK, "finished [task.name]")
	add_bored(task.type)
	clear_task()

/datum/ai_holder/rsnpc/proc/plan_finished()
	if(task.assignment_type)
		clear_plan()
		step_wait_until = world.time + 1 SECOND
		return
	task_done()

/datum/ai_holder/rsnpc/proc/plan_failed(why, no_plan)
	step_wait_until = world.time + 5 SECONDS
	var/datum/npc_assignment/A = task.assignment_type ? assignment(task.assignment_type) : null
	if(A)
		A.plan_failed(src, why)
		return
	if(task.level(src) == NPC_TIER_SURVIVAL)
		for(var/datum/npc_task/T as anything in tasks)
			if(T != task && T.level(src) == NPC_TIER_SURVIVAL && T.score(src) > 0)
				NPC_TRACE(src, NPC_TRACE_TASK, "putting off [task.name] for [T.name]; [why]")
				task.slept_until = world.time + 5 SECONDS
				clear_task()
				return
		NPC_TRACE(src, NPC_TRACE_TASK, "[task.name] failed, trying again in 5s; [why]")
		return
	if(no_plan || ++replans >= 3)
		task_failed(no_plan ? why : "3 plans failed; [why]")

/datum/ai_holder/rsnpc/proc/task_failed(why)
	NPC_TRACE(src, NPC_TRACE_TASK, "gave up [task.name]: [why], sleeping for [task.fail_sleep / 10]s")
	task.slept_until = world.time + task.fail_sleep
	clear_task()

/datum/ai_holder/rsnpc/proc/clear_task()
	if(!task)
		return
	clear_plan()
	task = null

/datum/ai_holder/rsnpc/proc/bored_amount(type)
	return max(0, bored[type] - (world.time - boredom_updated[type]) / (4 MINUTES))

/datum/ai_holder/rsnpc/proc/bored_factor(type)
	return 1 / (1 + bored_amount(type))

/datum/ai_holder/rsnpc/proc/add_bored(type)
	bored[type] = bored_amount(type) + npc_psetting("boredom_per_task")
	boredom_updated[type] = world.time
