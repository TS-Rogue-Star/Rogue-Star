//RS FILE
#define SKILL_FISHING				"Fishing"

/mob/living/simple_mob/animal/passive/fish/proc/fished(var/mob/living/fisher)
	var/chance_time = rand(1,100)
	switch(chance_time)
		if(1 to 50)
			chance_time = rand(25,100)
		if(51 to 80)
			chance_time = rand(50,200)
		if(81,100)
			chance_time = rand(75,300)

	resize(chance_time * 0.01, FALSE, TRUE)

	if(!fisher)
		return
	if(!isliving(fisher))
		return
	if(!fisher.etching)
		return

	var/howmuch = round(size_multiplier)
	if(howmuch > 0)
		fisher.grant_xp(SKILL_FISHING, howmuch)


/mob/living/simple_mob/animal/passive/fish/examine(mob/user)
	. = ..()
	var/our_scale = size_multiplier * 100
	var/msg = ""
	switch(our_scale)
		if(-INFINITY to 50)
			msg = "It's tiny... "
		if(51 to 75)
			msg = "It's small. "
		if(76 to 125)
			msg = "It is average size. "
		if(126 to 200)
			msg = "It is rather big. "
		if(201 to INFINITY)
			msg = "It's HUGE! "
	msg += "([our_scale])"

	. += span_green(msg)

/obj/fish_score_keeper
	name = "Fish Tracker"
	desc = "It's keeping track of the fish."
	icon = 'icons/rogue-star/misc_32x64.dmi'
	icon_state = "scorekeeper"
	var/list/target_fish = list()
	var/list/scores = list()
	var/fish_locked = FALSE
	var/fish_exclusive = FALSE

/obj/fish_score_keeper/attackby(obj/item/O, mob/user)
	. = ..()
	if(istype(O, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = O
		if(istype(G.affecting, /mob/living/simple_mob/animal/passive/fish))
			var/mob/living/simple_mob/animal/passive/fish/F = G.affecting
			qdel(G)
			add_score(user, F)
			return
	if(istype(O, /obj/item/glass_jar))
		var/mob/living/simple_mob/animal/passive/fish/F
		for(var/thing in O.contents)
			if(istype(thing, /mob/living/simple_mob/animal/passive/fish))
				F = thing
				break
		if(F)
			if(add_score(user, F))
				var/obj/item/glass_jar/our_jar = O
				our_jar.contains = 0
				our_jar.update_icon()

/obj/fish_score_keeper/attack_hand(mob/user)
	if(!check_rights(R_FUN,FALSE,user))
		return FALSE

	. = ..()

	var/list/options = list()
	options += "Report"
	options += "Toggle Configure"
	options += "Toggle Exclusive"

	var/choice = tgui_alert(user,"What would you like to do?","[src] configuration",options)
	if(!choice)
		return
	switch(choice)
		if("Report")
			report(user)
		if("Toggle Configure")
			fish_locked = !fish_locked
			if(fish_locked)
				to_chat(user, SPAN_NOTICE("Disabled configuration mode, \the [src] will now accept fish for scoring."))
			else
				to_chat(user, SPAN_WARNING("Enabled configuration mode, \the [src] will no longer score fish. You can now use fish to manually set score modifiers."))
		if("Toggle Exclusive")
			fish_exclusive = !fish_exclusive
			if(fish_exclusive)
				to_chat(user, SPAN_WARNING("Enabled exclusive mode, \the [src] will now ONLY accept fish in its scoring list."))
			else
				to_chat(user, span_green("Disabled exclusive mode, \the [src] will now accept any fish. Fish that have not had a score set will use a multiplier of 1."))

/obj/fish_score_keeper/proc/add_score(var/mob/living/scorer, var/mob/living/simple_mob/animal/passive/fish/our_fish)
	if(!scorer || !our_fish)
		return FALSE
	if(fish_locked)
		var/mult = 1
		if(target_fish.len)
			if(our_fish.type in target_fish)
				mult = target_fish[our_fish.type]
			else if(fish_exclusive)
				to_chat(scorer, SPAN_DANGER("This fish is not one of the target fish and will not be accepted."))
				return FALSE
		var/our_score = scores[scorer.name]
		var/fish_score = our_fish.size_multiplier * mult
		var/new_score = our_score + fish_score
		scores[scorer.name] = new_score
		var/list/yummy_verbs = list("accepts","devours","ingests","scarfs","scromfs","slurps","gulps","gobbles")
		visible_message(SPAN_WARNING("\The [src] [pick(yummy_verbs)] \the [our_fish] for scoring... ([fish_score])"))
		to_chat(scorer, SPAN_OCCULT("New score: [new_score]"))
		qdel(our_fish)
		return TRUE
	else if(check_rights(R_FUN,FALSE))
		var/choice = tgui_input_number(scorer, "Input fish score multiplier", "Fishing Configuration", 1)
		if(!choice)
			to_chat(scorer, SPAN_WARNING("Cancelled configuration input."))
			return FALSE
		if(!isnum(choice))
			to_chat(scorer, SPAN_WARNING("Cancelled configuration input."))
			return FALSE
		to_chat(scorer, SPAN_OCCULT("Set [our_fish.type] score multiplier to [choice]. Any fish scored will have their size_multiplier rating multiplied by this number."))
		target_fish[our_fish.type] = choice
	else
		to_chat(SPAN_WARNING("\The [src] is in configuration mode right now and can not accept any fish. Tell the event organizer to flip the configuration switch."))
		return FALSE

/obj/fish_score_keeper/proc/report(var/mob/living/user)

	var/scoreland = SPAN_DANGER("FISHING SCOREBOARD BEGIN:<br>")
	scoreland = SPAN_OCCULT(report_my_list_please(scores))

	to_chat(user, scoreland)

	if(tgui_alert(user,"Would you like to show the report to everyone?","Global report?",list("Yes","No")) == "Yes")
		to_world(scoreland)

/obj/fish_score_keeper/proc/report_my_list_please(var/list/input)
	if(!input)
		return
	var/list/subjects = input.Copy()
	var/report = ""
	var/iterations = 0
	while(subjects.len)
		iterations ++
		var/greatest = list_get_greatest(subjects)	//I remembered that it exists, good work 03:33 me

		subjects -= greatest

		report += SPAN_NOTICE("[greatest] - [input[greatest]]<br>")

	if(iterations == 0)
		return FALSE
	return report
