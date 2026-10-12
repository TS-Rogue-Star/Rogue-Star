/datum/ai_holder/complex_npc/proc/say_line(group, list/blanks, via)
	var/list/lines = (character && character.say[group]) || GLOB.npc_say_lines[group]
	if(!length(lines))
		NPC_TRACE(src, NPC_TRACE_TALK, "no lines in [group]")
		return FALSE
	var/text = npc_fill_line(pick(lines), blanks)
	if(!text)
		return FALSE
	var/key = radio_key(via)
	var/time = length(splittext(text, " ")) * npc_psetting("typing_seconds_per_word") SECONDS
	speak(key ? "[key] [text]" : text, time)
	return time

/datum/ai_holder/complex_npc/proc/radio_key(via)
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

/datum/ai_holder/complex_npc/proc/speak(text, time)
	say_queue += list(list(text, time, world.time))

/datum/ai_holder/complex_npc/proc/speak_tick()
	if(!length(say_queue) || world.time < typing_until)
		return
	if(!typing_until)
		for(var/list/old as anything in say_queue.Copy())
			if(world.time <= old[3] + 5 SECONDS)
				break
			say_queue.Cut(1, 2)
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

/datum/ai_holder/complex_npc/proc/squelch()
	if(!length(say_queue))
		return
	NPC_TRACE(src, NPC_TRACE_TALK, "dropped [length(say_queue)] lines")
	say_queue.Cut()
	typing_until = 0
	holder.set_typing_indicator(FALSE)
