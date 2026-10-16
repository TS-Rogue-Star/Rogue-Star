/datum/npc_plan_node
	var/list/unmet
	var/list/steps
	var/cost = 0

/datum/npc_plan_node/New(list/unmet, list/steps, cost)
	src.unmet = unmet
	src.steps = steps
	src.cost = cost

/datum/npc_plan_search
	var/datum/ai_holder/rsnpc/ai_mind
	var/datum/npc_heap/open = new
	var/list/offers = list()
	var/list/best = list()
	var/tries = 0
	var/state = NPC_PLAN_SEARCHING
	var/asking = FALSE
	var/list/steps
	var/why
	var/missing

/datum/npc_plan_search/New(datum/ai_holder/rsnpc/ai_mind, list/goal, asking)
	src.ai_mind = ai_mind
	src.asking = asking
	var/list/unmet = list()
	for(var/fact in goal)
		if(!ai_mind.fact_true(fact))
			unmet += fact
	if(!length(unmet))
		state = NPC_PLAN_ALREADY_DONE
		return
	var/h = guess(unmet)
	if(isnull(h))
		state = NPC_PLAN_NONE
		why = "nothing gives [unmet[1]]"
		return
	open.add(new /datum/npc_plan_node(unmet, list(), 0), h, h)

/datum/npc_plan_search/proc/advance(budget)
	while(state == NPC_PLAN_SEARCHING && budget-- > 0)
		var/datum/npc_plan_node/N = open.take()
		if(!N)
			state = NPC_PLAN_NONE
			why = why || "no way to do it"
			break
		if(!length(N.unmet))
			steps = N.steps
			state = NPC_PLAN_FOUND
			break
		if(++tries > 50000)
			state = NPC_PLAN_NONE
			why = "too complex to work out"
			break
		var/fact = N.unmet[length(N.unmet)]
		for(var/datum/npc_action/A as anything in offers_for(fact))
			if(A in N.steps)
				continue
			var/list/unmet = N.unmet - A.gives
			for(var/need in A.needs)
				if(!(need in unmet) && !ai_mind.fact_true(need))
					unmet += need
			var/h = guess(unmet)
			if(isnull(h))
				continue
			var/c = N.cost + A.cost
			var/key = jointext(sortList(unmet.Copy()), "|")
			if(!isnull(best[key]) && best[key] <= c)
				continue
			best[key] = c
			open.add(new /datum/npc_plan_node(unmet, list(A) + N.steps, c), c + h, h)
	return state

/datum/npc_plan_search/proc/offers_for(fact)
	if(!isnull(offers[fact]))
		return offers[fact]
	var/list/found = list()
	for(var/datum/npc_action/A as anything in ai_mind.actions)
		if(A.last_resort && !asking)
			continue
		for(var/datum/npc_action/V as anything in A.variants(ai_mind, fact))
			if(!ai_mind.crossed_off("act:[V.key]"))
				found += V
	offers[fact] = found
	return found

/datum/npc_plan_search/proc/guess(list/unmet)
	. = 0
	for(var/fact in unmet)
		var/cheapest
		for(var/datum/npc_action/A as anything in offers_for(fact))
			if(isnull(cheapest) || A.cost < cheapest)
				cheapest = A.cost
		if(isnull(cheapest))
			why = "nothing provides [fact]"
			if(findtext(fact, "have:") == 1)
				missing = text2path(copytext(fact, 6))
			return null
		. += cheapest
