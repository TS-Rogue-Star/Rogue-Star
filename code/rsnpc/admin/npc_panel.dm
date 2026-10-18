/datum/tgui_module/npc_panel
	name = "NPC Panel"
	tgui_id = "NpcPanel"
	var/datum/ai_holder/rsnpc/ai_mind
	var/seen_filter = ""

/datum/tgui_module/npc_panel/New(datum/ai_holder/rsnpc/ai_mind)
	..()
	src.ai_mind = ai_mind

/datum/tgui_module/npc_panel/tgui_state(mob/user)
	return GLOB.tgui_admin_state

/datum/tgui_module/npc_panel/tgui_data(mob/user)
	var/list/data = list()
	var/mob/living/carbon/human/H = ai_mind?.holder
	if(QDELETED(ai_mind) || !H)
		data["gone"] = TRUE
		return data
	var/turf/T = get_turf(H)
	data["name"] = H.real_name
	data["job"] = H.job
	data["role"] = ai_mind.role?.name
	data["place"] = T ? "[get_area(T)] ([T.x], [T.y], [T.z])" : "nowhere"
	data["health"] = "[H.health] / [H.maxHealth]"
	data["state"] = H.stat == DEAD ? "dead" : (H.stat ? "out cold" : (H.client ? "player in control" : "awake"))
	data["nutrition"] = H.nutrition
	data["workplace"] = "[ai_mind.workplace || "none"]"
	data["trace"] = ai_mind.trace
	data["escaping"] = ai_mind.escaping
	data["control"] = ai_mind.reflex_in_control() || "planner"
	data["character"] = ai_mind.character ? "[ai_mind.character.id]" : "none"
	data["personality"] = length(ai_mind.personality) ? jointext(ai_mind.personality, ", ") : "none"

	var/list/needs = list()
	for(var/name in ai_mind.needs)
		var/datum/npc_need/N = ai_mind.needs[name]
		needs += list(list("name" = name, "level" = round(N.now(), 0.1), "pressure" = round(N.pressure(), 0.01), "settable" = name != NPC_NEED_HEALTH))
	data["needs"] = needs

	data["task"] = ai_mind.task?.name
	var/list/steps = list()
	for(var/datum/npc_action/A as anything in ai_mind.plan)
		steps += A.name
	data["plan"] = steps
	data["plan_step"] = ai_mind.plan_step
	data["planning"] = ai_mind.plan_search ? ai_mind.plan_search.tries : null

	data["destination"] = ai_mind.destination ? "[ai_mind.destination]" : null
	data["walk_why"] = ai_mind.walk_outcome_why
	data["path_left"] = length(ai_mind.path)
	data["route_left"] = length(ai_mind.route)

	var/list/tasks = list()
	for(var/i in 1 to length(ai_mind.tasks))
		var/datum/npc_task/K = ai_mind.tasks[i]
		var/why_zero
		if(world.time < K.slept_until)
			why_zero = "sleeping [round((K.slept_until - world.time) / 10)]s"
		else if(!K.can_start(ai_mind))
			why_zero = "can't start"
		else if(K.stopped(ai_mind))
			why_zero = "assigned stop work"
		tasks += list(list(
			"index" = i,
			"name" = K.name,
			"tier" = K.level(ai_mind),
			"score" = round(K.score(ai_mind), 0.01),
			"bored" = round(ai_mind.bored_amount(K.type), 0.01),
			"weight" = round(ai_mind.task_weight(K), 0.01),
			"sleeping" = world.time < K.slept_until,
			"why_zero" = why_zero,
			"current" = K == ai_mind.task,
		))
	data["tasks"] = tasks

	var/list/notes = list()
	var/list/crossed = list()
	for(var/key in ai_mind.notes)
		var/list/entry = ai_mind.notes[key]
		if(world.time > entry[2])
			continue
		var/list/row = list("key" = key, "value" = "[entry[1]]", "left" = round((entry[2] - world.time) / 10))
		if(findtext(key, "off:") == 1)
			row["key"] = copytext(key, 5)
			crossed += list(row)
		else
			notes += list(row)
	for(var/key in ai_mind.step_fails)
		crossed += list(list("key" = "act:[key]", "value" = "failed [ai_mind.step_fails[key]] of 3 times", "left" = null))
	data["notes"] = notes
	data["crossed"] = crossed

	var/list/promises = list()
	for(var/datum/npc_promise/P as anything in ai_mind.promises)
		var/mob/living/asked = P.asked?.resolve()
		promises += list(list(
			"what" = npc_kind_name(P.kind),
			"asked" = asked ? asked.name : (P.channel ? "the [P.channel] radio" : "nobody"),
			"who" = P.who_name || "nobody yet",
			"state" = P.state == NPC_PROMISE_AGREED ? "agreed" : "asked",
			"left" = round((P.until - world.time) / 10),
		))
	data["promises"] = promises

	var/list/opinions = list()
	for(var/key in ai_mind.opinions)
		var/datum/npc_person/P = ai_mind.opinions[key]
		var/danger = P.danger_now()
		opinions += list(list(
			"name" = P.key,
			"opinion" = round(P.opinion),
			"opinion_label" = ai_mind.opinion_label(P),
			"danger" = round(danger),
			"danger_label" = npc_danger_label(danger),
		))
	data["opinions"] = opinions

	var/list/assignments = list()
	for(var/datum/npc_assignment/A as anything in ai_mind.assignments)
		assignments += list(list("name" = A.name, "with" = A.asker_name, "left" = round((A.until - world.time) / 10)))
	data["assignments"] = assignments

	var/list/by_distance = list()
	for(var/key in ai_mind.seen)
		var/datum/npc_seen/S = ai_mind.seen[key]
		var/atom/K = S.kind
		if(seen_filter && !findtext("[initial(K.name)] [get_area(S.place)]", seen_filter))
			continue
		by_distance[S] = T ? get_dist(T, S.place) + abs(T.z - S.place.z) * 20 : 0
	sortTim(by_distance, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)
	var/list/seen = list()
	for(var/datum/npc_seen/S as anything in by_distance)
		if(length(seen) >= 60)
			break
		var/atom/K = S.kind
		seen += list(list(
			"what" = initial(K.name),
			"place" = "[get_area(S.place)] ([S.place.x], [S.place.y], [S.place.z])",
			"amount" = S.amount,
			"age" = round((world.time - S.seen_at) / 10),
			"kept" = S.kept,
		))
	data["seen"] = seen
	data["seen_total"] = length(ai_mind.seen)
	data["seen_matching"] = length(by_distance)
	data["seen_filter"] = seen_filter
	return data

/datum/tgui_module/npc_panel/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(..())
		return TRUE
	if(!check_rights(R_ADMIN) || QDELETED(ai_mind) || !ai_mind.holder)
		return TRUE
	var/what
	switch(action)
		if("trace")
			ai_mind.trace = !ai_mind.trace
			what = "turned tracing [ai_mind.trace ? "on" : "off"]"
		if("drop_task")
			what = "dropped task [ai_mind.task?.name]"
			ai_mind.clear_task()
		if("force_task", "wake_task", "task_weight")
			var/index = text2num(params["index"])
			if(!index || index < 1 || index > length(ai_mind.tasks))
				return TRUE
			var/datum/npc_task/K = ai_mind.tasks[index]
			switch(action)
				if("force_task")
					K.slept_until = 0
					ai_mind.switch_to(K, K.score(ai_mind))
					what = "forced task [K.name]"
				if("wake_task")
					K.slept_until = 0
					what = "woke task [K.name]"
				if("task_weight")
					var/value = tgui_input_number(usr, "Weight of [K.name]? 1 is normal.", "NPC Panel", ai_mind.task_weight(K), 100, 0)
					if(isnull(value) || QDELETED(ai_mind))
						return TRUE
					ai_mind.task_weights[K.type] = value
					what = "set the weight of task [K.name] to [value]"
		if("set_need")
			var/datum/npc_need/N = ai_mind.needs[params["name"]]
			if(!N)
				return TRUE
			var/value = tgui_input_number(usr, "Level of [params["name"]]?", "NPC Panel", round(N.now()), 1000, 0)
			if(isnull(value) || QDELETED(ai_mind))
				return TRUE
			N.set_level(value)
			what = "set need [params["name"]] to [value]"
		if("opinion", "danger")
			var/datum/npc_person/P = ai_mind.opinions[params["name"]]
			if(!P)
				return TRUE
			var/old = action == "opinion" ? P.opinion : P.danger_now()
			var/value = text2num(params["by"])
			if(isnull(value))
				value = tgui_input_number(usr, "[action == "opinion" ? "Opinion" : "Danger"] of [P.key]?", "NPC Panel", round(old), 100, action == "opinion" ? -100 : 0)
				if(isnull(value) || QDELETED(ai_mind))
					return TRUE
			else
				value += old
			if(action == "opinion")
				ai_mind.set_opinion(P, value, "set by an admin")
			else
				ai_mind.set_danger(P, value, "set by an admin")
			what = "set [action] of [P.key] from [round(old)] to [round(value)]"
		if("clear_crossed")
			var/list/off = list()
			for(var/key in ai_mind.notes)
				if(findtext(key, "off:") == 1)
					off += key
			ai_mind.notes -= off
			ai_mind.step_fails = list()
			what = "cleared all crossed-off things"
		if("clear_notes")
			ai_mind.notes = list()
			what = "cleared all notes"
		if("seen_filter")
			seen_filter = copytext(trim("[params["text"]]"), 1, 100)
	if(what)
		log_admin("[key_name(usr)] [what] on NPC [ai_mind.holder.real_name].")
		message_admins("[key_name_admin(usr)] [what] on NPC [ai_mind.holder.real_name].")
	return TRUE

/datum/ai_holder/rsnpc/proc/open_panel(mob/user)
	if(!panel)
		panel = new(src)
	panel.tgui_interact(user)

/mob/living/carbon/human/ai_controlled/rsnpc/station/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("npc_panel", "NPC Panel")

/mob/living/carbon/human/ai_controlled/rsnpc/station/vv_do_topic(list/href_list)
	. = ..()
	IF_VV_OPTION("npc_panel")
		if(!check_rights(R_ADMIN|R_EVENT))
			return
		var/datum/ai_holder/rsnpc/ai_mind = npc_ai_mind(src)
		ai_mind?.open_panel(usr)
