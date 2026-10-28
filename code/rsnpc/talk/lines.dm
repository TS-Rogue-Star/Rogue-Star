GLOBAL_LIST_INIT(npc_say_lines, list(
	"say_whereabouts_idle" = list("I'm idle in %place%."),
	"say_whereabouts_doing" = list("I'm doing %task% in %place%."),
	"say_doing" = list("%task%."),
	"say_doing_idle" = list("I'm idle."),
	"say_wellbeing_fine" = list("I'm fine."),
	"say_wellbeing_health" = list("I'm injured."),
	"say_wellbeing_hunger" = list("I'm hungry."),
	"say_wellbeing_relaxation" = list("I'm tired."),
	"request_food" = list("%name%, can I get something to eat?"),
	"request_drink" = list("%name%, can I get something to drink?"),
	"request_treatment" = list("%name%, I'm hurt in %place%, can you treat me?"),
	"request_passage" = list("I'm stuck in %place%. The %thing% won't open. Can you let me out?"),
	"narrate_let_out" = list("Getting out.."),
	"narrate_raise_shutters" = list("Opening the shutters."),
	"gear_lost" = list("I can't find my %thing%."),
	"say_handover_thanks" = list("Thanks, %name%."),
	"say_offer_declined" = list("I don't want that."),
	"say_brush_off" = list("Not now."),
	"opinion_liked" = list("I like you, %name%."),
	"opinion_disliked" = list("I dislike you, %name%."),
	"say_opinion_loved" = list("%name%? I love them."),
	"say_opinion_liked" = list("%name%? I like them."),
	"say_opinion_neutral" = list("%name%? I'm neutral towards them."),
	"say_opinion_disliked" = list("%name%? I don't like them."),
	"say_opinion_hated" = list("%name%? I hate them."),
	"say_opinion_wary" = list("I'm wary of them though.'"),
	"say_opinion_dangerous" = list("They're dangerous though."),
	"say_opinion_unknown" = list("%name%? Literally who?"),
	"say_opinion_nobody" = list("Who?"),
	"say_recall_violence" = list("I saw %name% attack %other%."),
	"say_recall_violence_justified" = list("I saw %name% attack %other% but it was valid."),
	"say_recall_death" = list("I saw %name% dead."),
	"say_witness_nothing" = list("Nothing."),
	"witness_violence" = list("Stop that!"),
	"witness_violence_friend" = list("Stop that! I like %other%!"),
	"witness_violence_justified" = list("That violence was valid."),
	"witness_body" = list("%name% is dead!"),
	"alarm_witness" = list("Security! %name% is attacking %other% in %place%!"),
	"help_attacked" = list("Security! %name% is attacking me in %place%!"),
	"help_hurt" = list("Medic! I'm hurt in %place%!"),
	"help_stuck" = list("I can't move. I'm in %place%."),
	"protest_mild" = list("Hey!"),
	"protest_grabbed" = list("Let go of me!"),
	"protest_escalating" = list("Back off, %name%."),
	"threat_confront" = list("%name%! Stay where you are!"),
	"threat_avoid" = list("Staying away from %name%."),
	"narrate_retreat" = list("Get away from me!"),
	"refuse_threat" = list("I won't because you're too threatening %name%."),
	"refuse_dislike" = list("I won't because I dislike you %name%."),
	"refuse_esteem" = list("I won't because you can't command me, %name%."),
	"follow_agreed_follow" = list("Following you, %name%."),
	"follow_agreed_guard" = list("Guarding you, %name%."),
	"follow_agreed_but_unarmed" = list("I'll guard you, %name%, but I'm unarmed."),
	"follow_already_busy" = list("I'm  already following %other%."),
	"follow_dismissed" = list("Dismissed from following by %name%."),
	"follow_done" = list("I've followed long enough, %name%."),
	"follow_falling_behind" = list("Wait for me, %name%."),
	"give_here" = list("Giving you it %name%."),
	"give_none" = list("Don't have that  %name%."),
	"follow_lost" = list("I lost you, %name%."),
	"follow_unreachable" = list("I can't get to you, %name%."),
	"follow_leader_died" = list("Oh no! %name% is dead!"),
	"follow_leader_unconscious" = list("%name%? My leader is unconscious."),
	"hold_still_agreed" = list("Holding still."),
	"hold_still_done" = list("I've held still long enough."),
	"hold_still_broken" = list("Can't hold still, I have to move."),
	"hold_still_released" = list("Released from holding still, %name%."),
	"stop_work_agreed" = list("Stopping work, %name%."),
	"already_stopped_work" = list("I already stopped, %name%."),
	"stop_work_done" = list("I've stopped work for long enough."),
	"stop_work_never_stopped" = list("I never stopped, %name%."),
	"stop_work_released" = list("Back to work by your direction, %name%."),
	"summons_where" = list("Where are you summoning me, %name%?"),
	"summons_no_post" = list("I don't have a post, %name%."),
	"summons_already_at_post" = list("I'm already at my post, %name%."),
	"summons_agreed_room" = list("On my way to %place%, %name%."),
	"summons_agreed_post" = list("Going back to my post, %name%."),
	"summons_arrived_room" = list("I'm in %place%, %name%."),
	"summons_arrived_post" = list("Back at my post."),
	"summons_done_room" = list("I'm done with coming to %place%, %name%."),
	"summons_gave_up" = list("Sorry, %name%. I couldn't get to %place%."),
	"summons_cant_get_there" = list("I can't get into %place%, %name%."),
	"need_for_job" = list("I need %a:thing% to %task%, %name%."),
	"need_gave_up" = list("I can't %task% without %a:thing%, %name%."),
	"need_nothing" = list("Nothing, %name%."),
	"talk_hello" = list("%name%, hello."),
	"talk_hello_back" = list("Hello, %name%."),
	"talk_busy" = list("Too busy to talk %name%."),
	"talk_busy_talking" = list("Can't talk, %name%, I'm talking to %other%."),
	"talk_small_talk" = list("Working hard, or hardly working?", "Quiet today.", "Sounds like a case of the Mondays.", "Another day in paradise."),
	"talk_prompt" = list("You still there %name%?"),
	"talk_signoff" = list("Bye, %name%. Good talk."),
	"talk_cut_short" = list("Bye, %name%. Seems you're busy."),
	"talk_interrupted" = list("Bye, %name%. Something interrupted me."),
	"talk_farewell_back" = list("Bye, %name%."),
	"eat_yes" = list("Yes eat me %name%."),
	"eat_no" = list("No don't eat me %name%."),
	"digest_yes" = list("Yes digest me %name%."),
	"digest_no" = list("No, don't digest me %name%."),
	"held_belly_active_happy" = list("It's so squishy in here!"),
	"held_belly_neutral_happy" = list("It's comfy in here."),
	"held_belly_active_neutral" = list("%name%, can you let me out?"),
	"held_belly_neutral_neutral" = list("%name%, can you let me out?"),
	"held_belly_neutral_upset" = list("Let me out, %name%!"),
	"held_belly_active_upset" = list("Let me out! Now!"),
	"held_belly_inactive_upset" = list("Please, %name%, let me out."),
	"held_grab_active_happy" = list("So firm, %name%."),
	"held_grab_neutral_happy" = list("This is fine."),
	"held_grab_active_neutral" = list("%name%, can you let go?"),
	"held_grab_neutral_neutral" = list("%name%, can you let go?"),
	"held_grab_neutral_upset" = list("Let go of me, %name%!"),
	"held_grab_active_upset" = list("Let go of me! Now!"),
	"held_grab_inactive_upset" = list("Please, %name%, let go."),
	"held_released_happy" = list("That was fun, %name%!"),
	"held_released_neutral" = list("Thanks, %name%."),
	"held_released_upset" = list("About time!"),
	"held_betrayed" = list("I didn't agree to this %name%!"),
	"pred_ask" = list("%name%, can I eat you?"),
	"pred_heard_yes" = list("Come here %name%."),
	"pred_heard_no" = list("Fine %name%."),
	"pred_no_answer" = list("Guess that's a no %name%."),
	"pred_force" = list("I'm gonna eat you %name%."),
	"pred_tighten" = list("Hold still, %name%."),
	"pred_regrab" = list("Stop wriggling %name%!"),
	"pred_give_up" = list("More trouble than you're worth %name%."),
	"pred_to_digest_ordered" = list("Digest %name%? If you say so."),
	"pred_to_digest_agreed" = list("Time to digest, %name%."),
	"pred_to_digest_cold" = list("Time to get rid of you, %name%!"),
	"pred_to_digest_hungry" = list("Sorry %name%, but I'm hungry..."),
	"pred_to_hold" = list("Okay, %name%, I'll hold you."),
	"pred_digested" = list("Rest in pudge, %name%."),
	"pred_ask_digest" = list("%name%, can I digest you?"),
	"pred_offer_out" = list("%name%, I'm going to digest, ask if you want out."),
	"pred_digest_declined" = list("Out you come then %name%."),
	"pred_swallowed_agreed" = list("Make yourself comfortable %name%?"),
	"pred_swallowed_other" = list("Hold still."),
	"pred_arrived" = list("I didn't even have to swallow %name%..."),
	"pred_thank_feeder" = list("Thanks for feeding me %other%, %name%."),
	"pred_answer_plea" = list("I hear your plea %name%."),
	"pred_answer_struggle" = list("Settle down, %name%!"),
	"pred_release_asked" = list("I'll let you out %name%."),
	"pred_refuse" = list("You're staying in there, %name%."),
	"pred_invite_cant" = list("I respect people's preferences %name%."),
	"pred_invite_full" = list("I'm full %name%, Ask later."),
	"pred_invite_no" = list("Not now, %name%."),
	"pred_invite_yes" = list("Sure thing, %name%."),
	"pred_order_no" = list("I won't eat anyone for you %name%."),
	"pred_order_nobody" = list("Didn't eat anyone named that, %name%."),
	"pred_release_yes" = list("Fine, %name%, I'll let %other% out."),
	"pred_hold_yes" = list("Fine %name%, holding %other%."),
	"pred_digest_yes" = list("Fine %name%, I'll digest %other%."),
	"pred_eat_yes" = list("Fine %name%, I'll eat %other%."),
	"pred_eat_nobody" = list("I don't see them %name%."),
	"assignment_queued" = list("I'll do that later, %name%."),
	"assignment_queue_full" = list("I have too much of a backlog %name%."),
	"assignment_dropped" = list("Can't do %task% for you after all %name%, I'm too busy."),
))

GLOBAL_LIST_INIT(npc_line_shapes, list(
	"talk_hello" = "hello",
	"talk_hello_back" = "hello",
	"talk_signoff" = "bye",
	"talk_cut_short" = "bye",
	"talk_interrupted" = "bye",
	"talk_farewell_back" = "bye",
	"eat_yes" = "yes",
	"eat_no" = "no",
	"digest_yes" = "yes",
	"digest_no" = "no",
	"pred_ask" = "can i eat you",
	"pred_ask_digest" = "can i digest you",
))

/hook/startup/proc/check_npc_lines()
	for(var/group in GLOB.npc_say_lines)
		var/list/lines = GLOB.npc_say_lines[group]
		for(var/line in lines.Copy())
			var/why = npc_line_fault(line, group)
			if(why)
				log_npc_config(group, "line '[line]' [why]; dropped.")
				lines -= line
	return TRUE

/proc/npc_line_fault(line, group)
	var/list/parts = splittext(trim(line), "%")
	if(!(length(parts) % 2))
		return "has a % without its pair"
	var/whole = ""
	for(var/i in 1 to length(parts))
		whole += (i % 2) ? parts[i] : " x "
	whole = npc_clean_line(whole)
	if(!(group in list("alarm_witness", "help_attacked")))
		for(var/word in GLOB.npc_alarm_words)
			if(npc_has_words(whole, "x is [word]"))
				return "would be heard as an attack report"
	if(length(parts) > 1 && parts[1] == "" && (parts[2] in list("place", "thing")))
		return "must not begin with %[parts[2]]%"
	var/named = length(parts) > 1 && parts[1] == "" && parts[2] == "name"
	var/rest = ""
	for(var/i in (named ? 3 : 1) to length(parts))
		rest += (i % 2) ? parts[i] : " x "
	rest = npc_clean_line(rest)
	var/allowed = GLOB.npc_line_shapes[group]
	for(var/answer in list(NPC_ANSWER_YES, NPC_ANSWER_NO, NPC_ANSWER_HELLO, NPC_ANSWER_BYE, NPC_ANSWER_GOODBYE))
		if(npc_starts_with(rest, answer) && answer != allowed)
			return "would be heard as the answer \"[answer]\""
	if(!named)
		return null
	for(var/datum/npc_command/C as anything in GLOB.npc_commands)
		if(npc_starts_with(rest, C.say) && C.say != allowed)
			return "would be heard as the command \"[C.say]\""
	return null

/proc/npc_fill_line(line, list/blanks)
	blanks = blanks || list()
	var/list/parts = splittext(line, "%")
	. = ""
	for(var/i in 1 to length(parts))
		var/part = parts[i]
		if(i % 2)
			. += part
			continue
		var/blank = copytext(part, 1, 3) == "a:" ? copytext(part, 3) : part
		if(isnull(blanks[blank]))
			log_npc_config("lines", "line '[line]' needs %[part]%, which doesn't apply here; not said.")
			return null
		var/value = "[blanks[blank]]"
		if(blank != part)
			value = "[(lowertext(copytext(value, 1, 2)) in list("a", "e", "i", "o", "u")) ? "an" : "a"] [value]"
		. += value
