GLOBAL_LIST_INIT(npc_droppable_lines, list(
	"witness_violence", "witness_violence_friend", "witness_violence_justified", "witness_body",
	"protest_mild", "protest_grabbed", "protest_escalating", "opinion_liked", "opinion_disliked",
	"threat_confront", "threat_avoid", "narrate_retreat", "narrate_raise_shutters", "gear_lost",
	"say_handover_thanks", "talk_small_talk", "talk_prompt", "pred_tighten", "pred_regrab",
	"pred_arrived", "pred_swallowed_agreed", "pred_swallowed_other", "pred_thank_feeder",
	"pred_answer_plea", "pred_answer_struggle", "pred_digested",
	"held_belly_active_happy", "held_belly_neutral_happy", "held_belly_active_neutral",
	"held_belly_neutral_neutral", "held_belly_neutral_upset", "held_belly_active_upset",
	"held_belly_inactive_upset", "held_grab_active_happy", "held_grab_neutral_happy",
	"held_grab_active_neutral", "held_grab_neutral_neutral", "held_grab_neutral_upset",
	"held_grab_active_upset", "held_grab_inactive_upset",
))

/datum/ai_holder/rsnpc/proc/in_the_room()
	return isturf(holder.loc)

/datum/ai_holder/rsnpc/proc/busy_talking()
	return length(say_queue) || typing_until

/datum/ai_holder/rsnpc/proc/say_line(group, list/blanks, via)
	if(replying_to)
		var/datum/npc_assignment/talk/T = assignment(/datum/npc_assignment/talk)
		if(T?.asker?.resolve() != replying_to)
			replies += list(list(group, blanks, via, world.time, WEAKREF(replying_to)))
			return 1
	var/list/lines = (character && character.say[group]) || GLOB.npc_say_lines[group]
	if(!length(lines))
		NPC_TRACE(src, NPC_TRACE_TALK, "no lines in [group]")
		return FALSE
	var/text = npc_fill_line(pick(lines), blanks)
	if(!text)
		return FALSE
	var/key = radio_key(via)
	var/time = length(splittext(text, " ")) * npc_psetting("typing_seconds_per_word") SECONDS
	speak(key ? "[key] [text]" : text, time, !(group in GLOB.npc_droppable_lines))
	return time

/datum/ai_holder/rsnpc/proc/say_now(group, list/blanks, via)
	var/mob/living/was = replying_to
	replying_to = null
	. = say_line(group, blanks, via)
	replying_to = was

/datum/ai_holder/rsnpc/proc/radio_key(via)
	if(!via || !ishuman(holder))
		return null
	var/mob/living/carbon/human/body = holder
	for(var/obj/item/device/radio/headset/H in list(body.l_ear, body.r_ear))
		if(!H.on)
			continue
		var/channel = get_frequency_name(via)
		if(via != H.frequency && (channel in H.channels))
			var/key = get_radio_key_from_channel(channel)
			if(key)
				return key
		return ";"
	return null

/datum/ai_holder/rsnpc/proc/speak(text, time, keep = FALSE)
	say_queue += list(list(text, time, world.time, keep))

/datum/ai_holder/rsnpc/proc/speak_tick()
	if(!length(say_queue) || world.time < typing_until)
		return
	if(!typing_until)
		for(var/list/old as anything in say_queue.Copy())
			if(old[4] || world.time <= old[3] + 5 SECONDS)
				continue
			say_queue -= list(old)
			NPC_TRACE(src, NPC_TRACE_TALK, "didn't say \"[old[1]]\"; the moment passed")
		if(!length(say_queue))
			return
	var/list/entry = say_queue[1]
	if(!typing_until && entry[2])
		typing_until = world.time + entry[2]
		holder.set_typing_indicator(TRUE)
		return
	typing_until = 0
	holder.set_typing_indicator(FALSE)
	say_queue.Cut(1, 2)
	INVOKE_ASYNC(holder, TYPE_PROC_REF(/mob, say), entry[1])

/datum/ai_holder/rsnpc/proc/squelch()
	if(!length(say_queue))
		return
	NPC_TRACE(src, NPC_TRACE_TALK, "dropped [length(say_queue)] lines")
	say_queue.Cut()
	typing_until = 0
	holder.set_typing_indicator(FALSE)

/datum/ai_holder/rsnpc/proc/next_reply()
	var/list/first
	for(var/list/R as anything in replies.Copy())
		if(world.time > R[4] + 30 SECONDS)
			replies -= list(R)
			NPC_TRACE(src, NPC_TRACE_TALK, "never said [R[1]]; too late")
			continue
		if(findtext(R[1], "say_doing") == 1 || findtext(R[1], "say_whereabouts") == 1 || findtext(R[1], "say_wellbeing") == 1)
			return R
		first = first || R
	return first

/datum/npc_task/answer
	name = "answer someone"
	tier = NPC_TIER_SOCIAL

/datum/npc_task/answer/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !!ai_mind.next_reply()

/datum/npc_task/answer/value(datum/ai_holder/rsnpc/ai_mind)
	var/list/R = ai_mind.next_reply()
	var/datum/weakref/W = R?[5]
	var/mob/living/M = W?.resolve()
	if(M && (ai_mind.opinion_of(M) <= ai_mind.npc_psetting("opinion_disliked_at") || ai_mind.danger_of(M) >= NPC_WARY))
		return 40
	return 115

/datum/npc_task/answer/goal(datum/ai_holder/rsnpc/ai_mind)
	return list("answered")

/datum/npc_task/answer/fact_true(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact == "answered")
		return !ai_mind.next_reply() && !ai_mind.busy_talking()
	return null

/datum/npc_action/answer
	name = "answer"

/datum/npc_action/answer/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != "answered")
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/answer/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(ai_mind.busy_talking())
		return NPC_RUNNING
	var/list/R = ai_mind.next_reply()
	if(!R)
		return NPC_DONE
	ai_mind.replies -= list(R)
	ai_mind.say_line(R[1], R[2], R[3])
	return NPC_RUNNING

/datum/ai_holder/rsnpc/proc/idle_talk()
	var/datum/npc_action/A = plan && plan_step <= length(plan) ? plan[plan_step] : null
	if(!(isbelly(holder.loc) || A?.idle || task?.idle) || busy_talking())
		return
	var/list/R = next_reply()
	if(!R)
		return
	replies -= list(R)
	say_line(R[1], R[2], R[3])
