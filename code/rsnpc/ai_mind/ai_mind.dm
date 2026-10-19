/datum/ai_holder/rsnpc
	var/datum/npc_role/role
	var/datum/npc_character/character
	var/list/personality = list()
	var/trace = FALSE
	var/datum/tgui_module/npc_panel/panel
	var/area/workplace
	var/datum/npc_task/task
	var/list/tasks = list()
	var/list/task_weights = list()
	var/list/needs = list()
	var/list/bored = list()
	var/list/boredom_updated = list()
	var/list/actions = list()
	var/list/plan
	var/plan_step = 0
	var/datum/npc_plan_search/plan_search
	var/replans = 0
	var/list/step_fails = list()
	var/step_wait_until = 0
	var/list/in_sight = list()
	var/list/turfs_in_sight = list()
	var/list/danger_seen = list()
	var/list/air_seen = list()
	var/looked_at = 0
	var/list/seen = list()
	var/list/place_kinds = list()
	var/known_places_learned = FALSE
	var/list/notes = list()
	var/notes_cleaned = 0
	var/list/wanted_for_plan = list()
	var/list/promises = list()
	var/list/assignments = list()
	var/list/opinions = list()
	var/list/witnessed = list()
	var/list/blows_seen = list()
	var/when_protested = 0
	var/when_remarked = 0
	var/when_body_remarked = 0
	var/datum/weakref/last_attacker
	var/when_last_attacked = 0
	var/down_since = 0
	var/called_help_at = 0
	var/called_security_at = 0
	var/datum/weakref/threat
	var/threat_key
	var/threat_mode
	var/threat_seen_at = 0
	var/threat_dist = 0
	var/atom/threat_walk
	var/turf/threat_seen_turf
	var/panic_until = 0
	var/last_damage = 0
	var/self_extinguished_at = 0
	var/locker_escape_tried_at = 0
	var/datum/npc_held/held
	var/list/prey_inside = list()
	var/pred_scanned_at = 0
	var/record_id
	var/list/gear = list()
	var/list/last_held = list()
	var/datum/npc_room/shut_in_room
	var/shut_in_checks = 0
	var/shut_in_checked_at = 0
	var/list/say_queue = list()
	var/mob/living/replying_to
	var/list/replies = list()
	var/typing_until = 0
	var/walk_outcome_why
	var/walk_lost_target = FALSE
	var/walk_needs_suit = FALSE
	var/turf/destination_turf
	var/list/route
	var/datum/npc_path/path_search
	var/walk_wait = 0
	var/blocked_since = 0
	var/obj/machinery/door/door_tried
	var/door_tried_at = 0
	var/ladder_tried_at = 0
	var/turf/still_at
	var/still_since = 0
	var/button_wait_until = 0
	var/button_pressed_at = 0
	var/escaping = FALSE
	var/datum/npc_room/reach_from
	var/reach_at = 0
	var/list/reach_costs = list()
	var/list/reach_entries = list()
	var/escape_retry = 0

/proc/npc_ai_mind(mob/living/L)
	if(istype(L?.ai_holder, /datum/ai_holder/rsnpc))
		return L.ai_holder
	return null

/datum/ai_holder/rsnpc/proc/start()
	role = title_to_npc_role(holder.job)
	workplace = find_npc_workplace(holder.job)
	personality = character ? character.personality.Copy() : npc_roll_personality()
	for(var/task_type in role.task_types)
		var/datum/npc_task/T = new task_type
		tasks += T
		place_kinds |= T.uses
	for(var/action_type in role.action_types)
		actions += new action_type
	for(var/name in GLOB.npc_needs)
		var/need_type = GLOB.npc_needs[name]
		needs[name] = new need_type(src)
	learn_workplace()
	learn_known_places()
	note_gear()
	if(!GLOB.npc_violence)
		GLOB.npc_violence = new
	NPC_TRACE(src, NPC_TRACE_LIFE, "started as [holder.job] ([role.name])[character ? ", character [character.id]" : ""] in [get_area(holder)], workplace [workplace || "none"], personality [length(personality) ? jointext(personality, ", ") : "none"]")

/proc/find_npc_workplace(job_title)
	for(var/obj/effect/landmark/start/S in landmarks_list)
		if(S.name == job_title)
			return get_area(S)
	return null

/datum/ai_holder/rsnpc/Destroy()
	NPC_TRACE(src, NPC_TRACE_LIFE, "gone")
	leave_records()
	clear_task()
	QDEL_NULL(panel)
	for(var/name in needs)
		var/datum/npc_need/N = needs[name]
		N.ai_mind = null
	needs = list()
	role = null
	return ..()

/datum/ai_holder/rsnpc/handle_strategicals()
	if(!istype(holder) || QDELETED(holder))
		qdel(src)
		return
	if(holder.client)
		return
	handle_stance_strategical()

/datum/ai_holder/rsnpc/handle_tactics()
	if(!istype(holder) || QDELETED(holder))
		qdel(src)
		return
	if(holder.client)
		return
	handle_stance_tactical()

/datum/ai_holder/rsnpc/handle_stance_strategical()
	if(!(src in SSaifast.processing))
		start_fast_processing()
	call_for_help()
	check_assignments()
	if(!can_act())
		return
	if(isbelly(holder.loc))
		held_tick()
		clean_notes()
		return
	look()
	learn_known_places()
	check_gear()
	check_shut_in()
	held_tick()
	check_bellies()
	pred_scan()
	clean_notes()
	check_promises()
	choose_task()

/datum/ai_holder/rsnpc/handle_stance_tactical()
	if(holder.stat != CONSCIOUS)
		squelch()
		return
	speak_tick()
	if(isbelly(holder.loc))
		idle_talk()
		return
	if(fire_tick() || locker_tick())
		return
	if(!can_act())
		return
	reflex()
	if(!fight_tick() && !busy_talking())
		plan_tick()
	idle_talk()
	walk_tick()

/datum/ai_holder/rsnpc/holder_stat_change(mob, old_stat, new_stat)
	. = ..()
	if(new_stat == DEAD && old_stat != DEAD)
		NPC_TRACE(src, NPC_TRACE_LIFE, "died in [get_area(holder)]")
	else if(old_stat == DEAD && new_stat != DEAD)
		go_wake()
		NPC_TRACE(src, NPC_TRACE_LIFE, "rose from the grave")

/datum/ai_holder/rsnpc/react_to_attack(atom/movable/attacker, ignore_timers = FALSE)
	NPC_TRACE(src, NPC_TRACE_LIFE, "hit by [attacker]; health: [holder.health] / [holder.maxHealth]")
	if(isliving(attacker) && attacker != holder)
		bad_touch(attacker)
	return ..()
