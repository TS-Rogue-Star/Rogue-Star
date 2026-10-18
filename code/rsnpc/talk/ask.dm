GLOBAL_LIST_INIT(npc_supply_access, list(
	/obj/item/weapon/reagent_containers/food/snacks = access_kitchen,
	/obj/item/weapon/reagent_containers/food/drinks = access_bar,
	"treatment" = access_medical,
))

GLOBAL_LIST_INIT(npc_ask_lines, list(
	/obj/item/weapon/reagent_containers/food/snacks = "request_food",
	/obj/item/weapon/reagent_containers/food/drinks = "request_drink",
	"treatment" = "request_treatment",
))

GLOBAL_LIST_INIT(npc_department_channels, list(
	DEPARTMENT_COMMAND = "Command",
	DEPARTMENT_SECURITY = "Security",
	DEPARTMENT_ENGINEERING = "Engineering",
	DEPARTMENT_MEDICAL = "Medical",
	DEPARTMENT_RESEARCH = "Science",
	DEPARTMENT_CARGO = "Supply",
	DEPARTMENT_CIVILIAN = "Service",
))

/proc/npc_job_of(mob/M)
	return M?.mind?.assigned_role

/proc/npc_manifest_job(mob/M)
	return M ? npc_manifest_job_named(M.name) : null

/proc/npc_manifest_job_named(name)
	for(var/datum/data/record/R in data_core.general)
		if(R.fields["name"] == name)
			return R.fields["real_rank"]
	return null

/proc/npc_kind_is(kind, of)
	return kind == of || (ispath(kind) && ispath(of) && ispath(kind, of))

/proc/npc_kind_name(kind)
	if(!ispath(kind))
		return "[kind]"
	var/atom/K = kind
	while(K && !trim(initial(K.name)))
		K = type2parent(K)
	return K ? trim(initial(K.name)) : "something"

/proc/npc_can_supply(job_title, kind)
	var/datum/job/J = job_title && SSjob.get_job(job_title)
	if(!J || J.departments_managed)
		return FALSE
	for(var/supplied in GLOB.npc_supply_access)
		if(npc_kind_is(kind, supplied) && (GLOB.npc_supply_access[supplied] in J.minimal_access))
			return TRUE
	return FALSE

/proc/npc_supplying_jobs(kind)
	. = list()
	for(var/datum/data/record/R in data_core.general)
		var/title = R.fields["real_rank"]
		if(npc_can_supply(title, kind))
			. |= title

/datum/ai_holder/rsnpc/proc/person_to_ask(kind)
	var/mob/living/best
	for(var/mob/living/M in look())
		if(!can_notice(M) || crossed_off("ask:\ref[M]") || !npc_can_supply(npc_manifest_job(M), kind))
			continue
		if(!best || get_dist(holder, M) < get_dist(holder, best))
			best = M
	return best

/datum/ai_holder/rsnpc/proc/ask_for(kind, mob/living/person, title, channel)
	var/time = say_line(GLOB.npc_ask_lines[kind], list("name" = person ? person.name : title, "place" = "[get_area(holder)]"), channel ? radiochannels[channel] : null)
	if(!time)
		return null
	var/datum/npc_promise/P = new
	P.kind = kind
	P.task = task
	P.asked = person ? WEAKREF(person) : null
	P.channel = channel
	P.until = world.time + time + 60 SECONDS
	promises += P
	NPC_TRACE(src, NPC_TRACE_TALK, "asked [person || "[title] on [channel]"] for [npc_kind_name(kind)]")
	return P

/datum/npc_action/ask
	name = "ask"
	cost = 20
	last_resort = TRUE
	var/mob/living/person
	var/title
	var/channel
	var/datum/npc_promise/promise
	var/walked = FALSE
	var/area/walked_to

/datum/npc_action/ask/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	var/kind
	if(fact == NPC_FACT_TREATED)
		kind = "treatment"
	else if(findtext(fact, "have:") == 1)
		kind = text2path(copytext(fact, 6))
	if(!kind || !GLOB.npc_ask_lines[kind] || npc_can_supply(npc_job_of(ai_mind.holder), kind))
		return list()
	var/datum/npc_action/ask/A = copy(null, cost, null, list(fact))
	A.want = kind
	var/list/open = ai_mind.open_promises(kind)
	if(length(open))
		A.promise = open[1]
		A.name = "wait for [A.promise.who_name || "an answer"]"
		A.key = "[A.key]:waiting"
		return list(A)
	A.person = ai_mind.person_to_ask(kind)
	if(A.person)
		A.name = "ask [A.person]"
		A.key = "[A.key]:\ref[A.person]"
		return list(A)
	if(!ai_mind.in_the_room() || !ai_mind.radio_key(PUB_FREQ) || ai_mind.crossed_off("ask:radio:[kind]"))
		return list()
	var/list/titles = npc_supplying_jobs(kind)
	if(!length(titles))
		return list()
	A.title = titles[1]
	var/datum/job/J = SSjob.get_job(A.title)
	A.channel = (length(J.departments) && GLOB.npc_department_channels[J.departments[1]]) || "Common"
	A.name = "radio [A.title]"
	A.key = "[A.key]:radio"
	return list(A)

/datum/npc_action/ask/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(ai_mind.fact_true(gives[1]))
		return NPC_DONE
	if(!promise)
		promise = ai_mind.ask_for(want, person, title, channel)
		if(!promise)
			why = "no line to ask with"
			return NPC_CANT_DO
		return NPC_RUNNING
	if(!(promise in ai_mind.promises))
		why = promise.why
		return NPC_CANT_DO
	if(promise.state == NPC_PROMISE_AGREED && !walked)
		walked = TRUE
		var/area/A = find_npc_workplace(npc_manifest_job(promise.who?.resolve()))
		if(promise.channel && A && get_area(ai_mind.holder) != A)
			walked_to = A
	if(walked_to && !npc_arrived(ai_mind.holder, walked_to) && head_to(ai_mind, walked_to) != NPC_RUNNING)
		why = "couldn't get to [walked_to]: [why]"
		return NPC_CANT_DO
	idle = !ai_mind.destination
	return NPC_RUNNING
