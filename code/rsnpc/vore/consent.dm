GLOBAL_LIST_INIT(npc_consent_phrases, list(
	npc_clean_line("can i eat you"),
	npc_clean_line("can i digest you"),
	npc_clean_line("eat me"),
	npc_clean_line("digest me"),
))

/datum/ai_holder/rsnpc/proc/has_personality(word)
	return word in personality

/proc/npc_vore_allowed(mob/living/pred, mob/living/prey, digest)
	if(!prey.devourable || (digest && !prey.digestable) || !npc_vore_check(pred, prey))
		return FALSE
	return prey.client || prey.ssd_vore || !prey.player_login_key_log

/datum/ai_holder/rsnpc/proc/note_consent(prey_key, pred_key, digest)
	note("agreed_eat:[prey_key]:[pred_key]", pred_key, 5 MINUTES)
	if(digest)
		note("agreed_digest:[prey_key]:[pred_key]", pred_key, 5 MINUTES)
	NPC_TRACE(src, NPC_TRACE_WITNESS, "[prey_key] agreed to be [digest ? "digested" : "eaten"] by [pred_key]")

/datum/ai_holder/rsnpc/proc/note_vore_question(mob/living/asked, mob/living/asker, digest)
	note("vore_question:[npc_person_key(asked)]:[npc_person_key(asker)]", digest ? "digest" : "eat", 45 SECONDS)

/datum/ai_holder/rsnpc/proc/hear_consent(mob/living/speaker, line, via, list/name_matches)
	if(via)
		return
	var/list/phrases = GLOB.npc_consent_phrases
	var/has_request = FALSE
	for(var/phrase in phrases)
		if(npc_has_words_clean(line, phrase))
			has_request = TRUE
			break
	var/list/people
	if(has_request)
		people = look_people() + holder
		for(var/mob/living/M in people)
			if(M == speaker || !npc_is_person(M))
				continue
			var/rest = npc_after_name(line, M, name_matches, M == holder)
			if(isnull(rest))
				continue
			if(npc_starts_with_clean(rest, phrases[1]))
				note_vore_question(M, speaker, FALSE)
			else if(npc_starts_with_clean(rest, phrases[2]))
				note_vore_question(M, speaker, TRUE)
			else if(npc_starts_with_clean(rest, phrases[3]))
				note_consent(npc_person_key(speaker), npc_person_key(M), FALSE)
			else if(npc_starts_with_clean(rest, phrases[4]))
				note_consent(npc_person_key(speaker), npc_person_key(M), TRUE)
	var/prefix = "vore_question:[npc_person_key(speaker)]:"
	for(var/key in notes.Copy())
		if(findtext(key, prefix) != 1)
			continue
		var/kind = noted(key)
		if(!kind)
			continue
		var/asker_key = copytext(key, length(prefix) + 1)
		var/rest = line
		if(isnull(people))
			people = look_people() + holder
		for(var/mob/living/A in people)
			if(npc_person_key(A) == asker_key)
				var/after_name = npc_after_name(line, A, name_matches)
				if(!isnull(after_name))
					rest = after_name
		if(npc_starts_with(rest, NPC_ANSWER_YES))
			notes -= key
			note_consent(npc_person_key(speaker), asker_key, kind == "digest")
		else if(npc_starts_with(rest, NPC_ANSWER_NO))
			notes -= key

/datum/ai_holder/rsnpc/proc/agreed(mob/living/prey, mob/living/pred, digest)
	return noted("agreed_[digest ? "digest" : "eat"]:[npc_person_key(prey)]:[npc_person_key(pred)]")

/datum/ai_holder/rsnpc/proc/wait_to_be_eaten(mob/living/M)
	if(isturf(holder.loc) && !holds_still_for(npc_person_key(M)))
		start_assignment(new /datum/npc_assignment/hold_still(M, null, npc_psetting("hold_still_minutes") MINUTES))

/datum/ai_holder/rsnpc/proc/eat_willingness(mob/living/M)
	. = 1.5 * opinion_of(M) / 100 - min(1, danger_of(M) / NPC_DANGEROUS) + npc_psetting("prey_desire")

/datum/npc_command/can_i_eat_you
	say = "can i eat you"

/datum/npc_command/can_i_eat_you/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/mob/living/me = ai_mind.holder
	var/list/blanks = list("name" = speaker.name)
	if(!isturf(me.loc))
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "ignored \"[say]\" from [speaker]; I'm inside someone")
		return
	if(npc_vore_allowed(speaker, me, FALSE) && ai_mind.eat_willingness(speaker) >= ai_mind.npc_psetting("prey_agree_threshold"))
		ai_mind.note_consent(npc_person_key(me), npc_person_key(speaker), FALSE)
		ai_mind.say_line("eat_yes", blanks)
		ai_mind.wait_to_be_eaten(speaker)
		return
	ai_mind.note("refused_eat:[npc_person_key(speaker)]", speaker.name, 5 MINUTES)
	ai_mind.say_line("eat_no", blanks)

/datum/npc_command/can_i_digest_you
	say = "can i digest you"

/datum/npc_command/can_i_digest_you/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/mob/living/me = ai_mind.holder
	var/list/blanks = list("name" = speaker.name)
	var/obj/belly/B = me.loc
	if(!isturf(me.loc) && !(istype(B) && B.owner == speaker))
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "ignored \"[say]\" from [speaker]; I'm inside someone else")
		return
	var/willing = ai_mind.eat_willingness(speaker) - ai_mind.npc_psetting("held_digest_reluctance")
	if(npc_vore_allowed(speaker, me, TRUE) && willing >= ai_mind.npc_psetting("prey_agree_threshold") && ai_mind.opinion_of(speaker) >= ai_mind.npc_psetting("digest_needed_trust"))
		ai_mind.note_consent(npc_person_key(me), npc_person_key(speaker), TRUE)
		ai_mind.say_line("digest_yes", blanks)
		ai_mind.wait_to_be_eaten(speaker)
		return
	ai_mind.note("refused_digest:[npc_person_key(speaker)]", speaker.name, 5 MINUTES)
	ai_mind.say_line("digest_no", blanks)

/datum/npc_command/eat_me
	say = "eat me"

/datum/npc_command/eat_me/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.answer_invite(speaker, FALSE)

/datum/npc_command/digest_me
	say = "digest me"

/datum/npc_command/digest_me/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.answer_invite(speaker, TRUE)

/datum/ai_holder/rsnpc/proc/answer_invite(mob/living/M, digest)
	var/list/blanks = list("name" = M.name)
	if(!isturf(M.loc))
		NPC_TRACE(src, NPC_TRACE_TALK, "ignored invite from [M]; they're inside someone")
		return
	var/why
	var/group = "pred_invite_no"
	if(!npc_vore_allowed(holder, M, digest) || !npc_can_stand(M.loc) || !isturf(holder.loc))
		why = "their settings or where they stand forbid it"
		group = "pred_invite_cant"
	else if(!room_for(M) || (!digest && digesting_any()))
		why = "no room"
		group = "pred_invite_full"
	else if(opinion_of(M) <= npc_psetting("opinion_disliked_at") || danger_of(M) >= NPC_WARY)
		why = "I don't trust them"
	else if(!digest && ask_score(M) < npc_psetting("pred_accept_line"))
		why = "I don't want to eat them"
	else if(digest && (pred_hunger() < 0.1 || pred_hunger() * npc_psetting("pred_hunger_motive") - opinion_of(M) / 100 * npc_psetting("pred_feelings_motive") + 1 < digest_line()))
		why = "I don't want to digest them"
	if(why)
		NPC_TRACE(src, NPC_TRACE_TALK, "turned down \"[digest ? "digest" : "eat"] me\" from [M]; [why]")
		say_line(group, blanks)
		return
	var/datum/npc_assignment/eat_prey/A = new(M, null, 2 MINUTES)
	A.name = "eat [M]"
	A.mode = "agreed"
	A.digest = digest
	start_assignment(A, "pred_invite_yes")
