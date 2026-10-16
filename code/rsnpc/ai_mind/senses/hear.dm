/mob/living/carbon/human/ai_controlled/rsnpc/station/hear_say(list/message_pieces, verb = "says", italics = 0, mob/speaker = null, sound/speech_sound, sound_vol)
	. = ..()
	var/datum/ai_holder/rsnpc/ai_mind = npc_ai_mind(src)
	if(!ai_mind)
		return
	var/list/heard = combine_message(message_pieces, verb, speaker)
	ai_mind.hear_speech(speaker, heard["raw"], null)

/mob/living/carbon/human/ai_controlled/rsnpc/station/hear_radio(list/message_pieces, verb = "says", part_a, part_b, part_c, part_d, part_e, mob/speaker = null, hard_to_hear = 0, vname = "", radio_freq = 0)
	. = ..()
	if(hard_to_hear)
		return
	var/datum/ai_holder/rsnpc/ai_mind = npc_ai_mind(src)
	if(!ai_mind)
		return
	var/list/heard = combine_message(message_pieces, verb, speaker, radio = TRUE)
	ai_mind.hear_speech(speaker, heard["raw"], radio_freq)

/datum/ai_holder/rsnpc/proc/can_notice(mob/living/who)
	if(holder.client || holder.stat != CONSCIOUS || who == holder)
		return FALSE
	return istype(who) && who.stat != DEAD && (ishuman(who) || issilicon(who))

/datum/ai_holder/rsnpc/proc/can_hear(mob/living/speaker, via)
	if(!can_notice(speaker) || holder.is_deaf() || world.time < panic_until)
		return FALSE
	return via || (get_z(speaker) == get_z(holder) && get_dist(speaker, holder) <= 7)

/datum/ai_holder/rsnpc/proc/hear_speech(mob/living/speaker, text, via)
	if(!can_hear(speaker, via))
		return
	var/line = npc_clean_line(text)
	replying_to = speaker
	hear_lines(speaker, line, via)
	replying_to = null

/datum/ai_holder/rsnpc/proc/hear_lines(mob/living/speaker, line, via)
	hear_answer(speaker, line, via)
	hear_command(speaker, line, via)
	hear_report(speaker, line, via)
	hear_talk(speaker, line, via)
	hear_from_inside(speaker, line, via)
	var/list/name_matches = via ? null : list()
	hear_consent(speaker, line, via, name_matches)
	hear_hold_still(speaker, line, via, name_matches)
