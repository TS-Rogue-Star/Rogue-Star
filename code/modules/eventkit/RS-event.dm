/client/proc/toggle_event_verb()
	set category = "Fun"
	set name = "Toggle Event Verb"
	set desc = "Add or remove an event verb from someone"
	set popup_menu = FALSE

	if(!check_rights(R_FUN))
		return
	var/list/possible_verbs = list(
		/mob/living/proc/blue_shift
		)

	var/choice = tgui_input_list(usr, "Which verb would you like to add/remove?", "Event Verb", possible_verbs)

	if(!choice)
		return

	var/list/targets = list()

	for(var/mob/living/l in player_list)
		if(!isliving(l))
			continue
		targets |= l

	var/mob/living/target = tgui_input_list(usr, "Who's verb will you adjust?", "Target", targets)

	if(!target)
		return

	if(choice in target.verbs)
		if(tgui_alert(usr, "[target] has access to [choice] already. Would you like to remove this verb from them?", "Remove Verb",list("No","Yes")) == "Yes")
			target.verbs.Remove(choice)
			to_chat(usr,"<span class = 'warning'>Removed [choice] from [target].</span>")
	else
		if(tgui_alert(usr, "Would you like to add [choice] to [target]?", "Add Verb",list("No","Yes")) == "Yes")
			target.verbs.Add(choice)
			to_chat(usr,"<span class = 'warning'>Added [choice] to [target].</span>")

/mob/living/proc/blue_shift()
	set name = "Blue Shift"
	set category = "Abilities"
	set desc = "Toggles ghost-like invisibility (Don't abuse this)"

	if(invisibility == INVISIBILITY_OBSERVER)
		invisibility = initial(invisibility)
		to_chat(src, "<span class='notice'>You are now visible.</span>")
		alpha = max(alpha + 100, 255)
	else
		invisibility = INVISIBILITY_OBSERVER
		to_chat(src, "<span class='danger'><b>You are now as invisible.</b></span>")
		alpha = max(alpha - 100, 0)

	var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
	sparks.set_up(5, 0, src)
	sparks.attach(loc)
	sparks.start()
	visible_message("<span class='warning'>Electrical sparks manifest from nowhere around \the [src]!</span>")
	qdel(sparks)
