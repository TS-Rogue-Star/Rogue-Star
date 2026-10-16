/datum/npc_command/follow_me
	say = "follow me"
	repeat = 15 SECONDS
	obedience = 21

/datum/npc_command/follow_me/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.start_follow(speaker, "follow_agreed_follow")

/datum/npc_command/guard_me
	say = "guard me"
	repeat = 15 SECONDS
	obedience = 40

/datum/npc_command/guard_me/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.start_follow(speaker, npc_armed(ai_mind.holder, TRUE) ? "follow_agreed_guard" : "follow_agreed_but_unarmed")

/datum/npc_command/stop_following
	say = "stop following"
	repeat = 15 SECONDS

/datum/npc_command/stop_following/applies(datum/ai_holder/rsnpc/ai_mind)
	return !!ai_mind.assignment(/datum/npc_assignment/follow)

/datum/npc_command/stop_following/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.end_assignment(ai_mind.assignment(/datum/npc_assignment/follow), "[speaker] told me to stop", "follow_dismissed", speaker)

/datum/ai_holder/rsnpc/proc/start_follow(mob/living/M, group)
	var/datum/npc_assignment/follow/F = assignment(/datum/npc_assignment/follow)
	if(F?.asker?.resolve() == M)
		NPC_TRACE(src, NPC_TRACE_TALK, "already following [M]")
		return
	if(F)
		NPC_TRACE(src, NPC_TRACE_TALK, "can't follow [M]; following [F.asker_name]")
		say_line("follow_already_busy", list("name" = M.name, "other" = F.asker_name))
		return
	start_assignment(new /datum/npc_assignment/follow(M, null, npc_psetting("follow_minutes") MINUTES), group)

/datum/npc_assignment/follow
	weight = -5
	name = "follow"
	uses_legs = TRUE
	time_up_line = "follow_done"
	failed_line = "follow_unreachable"
	var/seen_at = 0
	var/warned = FALSE

/datum/npc_assignment/follow/New(mob/living/M, via, time)
	..()
	seen_at = world.time

/datum/npc_assignment/follow/proc/far(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/M = asker?.resolve()
	return !M || get_dist(M, ai_mind.holder) > 4 || !(M in ai_mind.look())

/datum/npc_assignment/follow/needs_legs(datum/ai_holder/rsnpc/ai_mind)
	return far(ai_mind)

/datum/npc_assignment/follow/wants_turn(datum/ai_holder/rsnpc/ai_mind)
	return far(ai_mind)

/datum/npc_assignment/follow/goal(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/M = asker?.resolve()
	return M ? list(NPC_FACT_NEAR(M)) : list()

/datum/npc_assignment/follow/check(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/M = asker?.resolve()
	if(ai_mind.active_request() != src)
		seen_at = world.time
		warned = FALSE
		return ..()
	var/sees = M && ai_mind.holder.stat == CONSCIOUS && (M in ai_mind.look())
	via = sees ? null : PUB_FREQ
	if(sees && M.stat == DEAD)
		ai_mind.end_assignment(src, "they died", "follow_leader_died")
		return
	if(sees && M.stat != CONSCIOUS)
		ai_mind.end_assignment(src, "they're out cold", "follow_leader_unconscious")
		return
	if(sees)
		seen_at = world.time
		warned = FALSE
	else if(world.time > seen_at + 30 SECONDS)
		ai_mind.end_assignment(src, "lost them", "follow_lost")
		return
	else if(world.time > seen_at + 10 SECONDS && !warned)
		warned = TRUE
		ai_mind.say_line("follow_falling_behind", blanks(), via)
	..()

/datum/npc_task/follow
	name = "follow"
	tier = NPC_TIER_NEEDS
	assignment_type = /datum/npc_assignment/follow

/datum/npc_task/follow/can_start(datum/ai_holder/rsnpc/ai_mind)
	var/datum/npc_assignment/follow/F = ai_mind.assignment(/datum/npc_assignment/follow)
	return ..() && F.far(ai_mind)

/datum/npc_task/follow/value(datum/ai_holder/rsnpc/ai_mind)
	return 100
