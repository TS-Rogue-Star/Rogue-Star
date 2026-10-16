/datum/npc_personality
	var/name
	var/opposite
	var/list/sets = list()
	var/list/times = list()
	var/list/task_weights = list()

/datum/npc_personality/diligent
	name = "diligent"
	opposite = "lazy"
	task_weights = list(/datum/npc_task/work = 1.3, /datum/npc_task/take_break = 0.6, /datum/npc_task/consume/drink = 0.6)

/datum/npc_personality/lazy
	name = "lazy"
	opposite = "diligent"
	task_weights = list(/datum/npc_task/work = 0.7, /datum/npc_task/take_break = 1.5, /datum/npc_task/consume/drink = 1.5)

/datum/npc_personality/gluttonous
	name = "gluttonous"
	opposite = "austere"
	times = list("hunger_setpoint" = 1.3, "starving_threshold" = 0.7)
	task_weights = list(/datum/npc_task/consume = 1.3)

/datum/npc_personality/austere
	name = "austere"
	opposite = "gluttonous"
	times = list("hunger_setpoint" = 0.7, "starving_threshold" = 1.3)
	task_weights = list(/datum/npc_task/consume = 0.7)

/datum/npc_personality/curious
	name = "curious"
	opposite = "conventional"
	times = list("boredom_per_task" = 1.5)
	task_weights = list(/datum/npc_task/stroll = 1.5)

/datum/npc_personality/conventional
	name = "conventional"
	opposite = "curious"
	times = list("boredom_per_task" = 0.5)
	task_weights = list(/datum/npc_task/stroll = 0.6)

/datum/npc_personality/brave
	name = "brave"
	opposite = "timid"
	sets = list("obedience_base" = 10, "flee_health" = 0.2, "witness_speak_chance" = 80)
	times = list("panic_damage" = 1.5)

/datum/npc_personality/timid
	name = "timid"
	opposite = "brave"
	sets = list("obedience_base" = 40, "flee_health" = 0.55, "witness_speak_chance" = 15, "violence_excuse_share" = 0.5)
	times = list("panic_damage" = 0.6)

/datum/npc_personality/sociable
	name = "sociable"
	opposite = "solitary"
	sets = list("social_floor" = -60)
	times = list("talk_remarks" = 4, "talk_again_minutes" = 0.5, "talk_gap_seconds" = 0.5)

/datum/npc_personality/solitary
	name = "solitary"
	opposite = "sociable"
	sets = list("social_floor" = 10)
	times = list("talk_again_minutes" = 2, "talk_gap_seconds" = 2)

/datum/npc_personality/forgiving
	name = "forgiving"
	opposite = "grudging"
	sets = list("obedience_opinion_weight" = 0.3, "witness_memory_minutes" = 15)
	times = list("opinion_loss_scale" = 0.5)

/datum/npc_personality/grudging
	name = "grudging"
	opposite = "forgiving"
	sets = list("obedience_opinion_weight" = 1, "witness_memory_minutes" = 60)
	times = list("opinion_loss_scale" = 1.5)

/datum/npc_personality/pred
	name = "pred"
	opposite = "prey"
	sets = list("pred_hunger_motive" = 1, "pred_accept_line" = -0.5, "pred_release_margin" = 0.3, "pred_digest_line" = 0.9, "pred_offer_line" = -0.3, "prey_desire" = -0.3, "heal_belly_opinion_per_minute" = 0)

/datum/npc_personality/prey
	name = "prey"
	opposite = "pred"
	sets = list("prey_desire" = 0.3, "digest_needed_trust" = 15, "held_digest_reluctance" = 0)

GLOBAL_LIST_INIT(npc_personalities, npc_make_personalities())

/proc/npc_make_personalities()
	. = list()
	for(var/path in subtypesof(/datum/npc_personality))
		var/datum/npc_personality/P = new path
		.[P.name] = P

/proc/npc_roll_personality()
	. = list()
	var/list/words = GLOB.npc_personalities.Copy()
	for(var/i in 1 to 2)
		var/word = pick(words)
		var/datum/npc_personality/P = words[word]
		words -= list(word, P.opposite)
		. += word

/datum/ai_holder/rsnpc/proc/npc_psetting(key)
	if(character && (key in character.numbers))
		return character.numbers[key]
	for(var/word in personality)
		var/datum/npc_personality/P = GLOB.npc_personalities[word]
		if(key in P.sets)
			return P.sets[key]
	. = npc_setting(key)
	for(var/word in personality)
		var/datum/npc_personality/P = GLOB.npc_personalities[word]
		if(key in P.times)
			. *= P.times[key]

/datum/ai_holder/rsnpc/proc/task_weight(datum/npc_task/T)
	if(T.type in task_weights)
		return task_weights[T.type]
	. = 1
	for(var/word in personality)
		var/datum/npc_personality/P = GLOB.npc_personalities[word]
		for(var/path in P.task_weights)
			if(istype(T, path))
				. *= P.task_weights[path]
