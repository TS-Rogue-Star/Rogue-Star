GLOBAL_LIST_INIT(npc_emotes, list(
	"wave" = list("waves"),
))

/proc/npc_emote_in(line)
	for(var/emote in GLOB.npc_emotes)
		for(var/word in GLOB.npc_emotes[emote])
			if(npc_has_words(line, word))
				return emote
	return null

/datum/ai_holder/rsnpc/on_hear_emote(mob/living/speaker, message)
	if(!findtext(message, "class='emote'") || !can_notice(speaker) || !(speaker in look()))
		return
	var/line = npc_clean_line(message)
	if(!npc_named_in(line, holder, TRUE))
		return
	var/emote = npc_emote_in(line)
	if(!emote)
		return
	if(!friendly_to(speaker))
		NPC_TRACE(src, NPC_TRACE_TALK, "ignored [emote] from [speaker]; don't like them")
		return
	var/key = "emote:\ref[speaker]"
	if(noted(key))
		NPC_TRACE(src, NPC_TRACE_TALK, "ignored [emote] from [speaker]; repeated too soon")
		return
	note(key, speaker.name, npc_psetting("emote_reply_seconds") SECONDS)
	NPC_TRACE(src, NPC_TRACE_TALK, "saw [emote] from [speaker]")
	speak("*[emote] [speaker.name]", 0)
