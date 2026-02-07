/obj/tally_box
	name = "Tally Box"
	desc = "A box for taking tallys!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "tallybox"

	anchored = TRUE

	var/static/list/tally_boxes = list() 		//A list of all the tallyboxes in the world
	var/static/list/global_tallied = list()		//A list of ckeys of all the people who have voted - we use ckeys so that people can't character hop to stuff the votes
	var/list/local_tallied = list()				//A list of the ckeys of people who voted with this box!
	var/allow_multiple = FALSE					//If true, then people can vote for more than one option
	var/configured = FALSE						//While false this will make the box ask you for configuration instead of tallying
	var/report_name								//The name the box will use to let people know what they are voting for

/obj/tally_box/Initialize()
	. = ..()
	if(!report_name)
		configured = FALSE
	else
		configured = TRUE
		tally_boxes |= src
		name = "[report_name] box"
		desc = "A box for taking tallies! [SPAN_NOTICE("This one is accepting tallies for [report_name]!")]"
		icon_state = "tallybox_s"

/obj/tally_box/Destroy()
	. = ..()
	tally_boxes -= src

/obj/tally_box/attack_hand(mob/user)
	. = ..()

	if(!isliving(user))
		to_chat(user,"You can't vote!")
		return

	if(!configured)
		if(report_name)
			configured = TRUE
			tally_boxes |= src
		else if(tgui_alert(user,"Would you like to register this [src] to accept votes for you?","Tally Box",list("Yes","No")) != "Yes")
			return
		if(!configured)
			report_name = user.real_name
			name = "[report_name] box"
			desc = "A box for taking tallies! [SPAN_NOTICE("This one is accepting tallies for [report_name]!")]"
			icon_state = "tallybox_s"
			configured = TRUE
			tally_boxes |= src
			to_chat(user,SPAN_NOTICE("You configured the tally box to accept votes for yourself!"))
			return
		else
			to_chat(user,SPAN_WARNING("Someone else already registered this box!"))
			return

	if(tgui_alert(user,"Would you like to vote for [report_name]?","Tally Box",list("Yes","No")) == "Yes")
		if(!allow_multiple)	//If we let them vote more than once then it's nbd
			for(var/obj/tally_box/box in tally_boxes)	//If we don't though, let's search for where they voted and remove their vote!
				if(user.ckey in box.local_tallied)
					box.local_tallied -= user.ckey

		local_tallied |= user.ckey
		global_tallied |= user.ckey
		to_chat(user,SPAN_NOTICE("You have registered your tally vote for [report_name]!"))

/obj/tally_box/verb/report_tally()
	set name = "Report Tally"
	set category = "Object"
	set desc = "Report the present tally!"
	set src in view(7)

	if(!ismob(usr))
		return

	var/mob/user = usr

	if(!user.client.holder)
		to_chat(user,SPAN_WARNING("No peeking!"))
		return

	var/list/subjects = tally_boxes.Copy()
	var/report = SPAN_DANGER("TALLY REPORT START:<br>")

	while(subjects.len)
		var/obj/tally_box/greatest = get_greatest(subjects)

		report += SPAN_NOTICE("[greatest.report_name] - [greatest.local_tallied.len]<br>")
		subjects -= greatest

	to_chat(user, report)
	if(tgui_alert(user,"Would you like to show the report to everyone?","Global report?",list("Yes","No")) == "Yes")
		to_world(report)

/obj/tally_box/proc/get_greatest(var/list/ourlist = list())

	if(!ourlist)
		log_and_message_admins("get_greatest was called on [src] - ([report_name]) but did not provide a list")
		return

	var/obj/tally_box/greatest

	for(var/obj/tally_box/T in ourlist)
		if(!T.configured)
			continue
		if(!greatest)
			greatest = T
			continue
		if(T.local_tallied.len > greatest.local_tallied.len)
			greatest = T
		if(T.local_tallied.len == greatest.local_tallied.len)
			continue

	return greatest

/////SCORE KEEPER/////

/obj/score_keeper
	name = "Score Keeper"
	desc = "It is keeping score!"
	icon = 'icons/rogue-star/misc_32x64.dmi'
	icon_state = "scorekeeper"

	anchored = TRUE
	pixel_y = 16
	plane = MOB_PLANE
	layer = MOB_LAYER

	var/configured = FALSE						//While false, the score keeper won't do anything
	var/score_type_paths = list()				//A list of type paths of an item that the score keeper is looking to collect
	var/list/scoreboard = list()				//A list of people's names and their associated scores.
	var/score_stock_locked = FALSE				//If true, will prevent new scoring items from being added when you click it with them
	var/list/msg_hist = list()
	var/firetime
	var/queued_msg

/obj/score_keeper/Initialize()
	. = ..()
	if(!score_type_paths)
		configured = FALSE
	else
		configured = TRUE

/obj/score_keeper/Destroy()
	. = ..()

/obj/score_keeper/process()
	if(!firetime)
		STOP_PROCESSING(SSobj,src)
		return
	if(world.time < firetime)
		return
	firetime = null
	for(var/mob/M in player_list)
		if(!istype(M,/mob/new_player))
			to_chat(M, "<h2 class='alert'>[src] Announcement</h2>")
			to_chat(M, "<span class='alert'>[queued_msg]</span>")
			M << 'sound/AI/preamble.ogg'
	queued_msg = null
	STOP_PROCESSING(SSobj,src)

/obj/score_keeper/attack_hand(mob/user)
	. = ..()

	if(!user.client.holder)
		report_score()
		return
	var/choice = tgui_alert(user,"What would you like to do?","[src] configuration",list("Report","Add","Remove","Change","Automate"))

	switch(choice)
		if("Report")
			report_score()

		if("Add")
			if(score_stock_locked)
				to_chat(user,SPAN_WARNING("score_stock_locked is enabled, no changes can be made at this time."))
				return
			choice = tgui_input_text(user,"Please enter a valid type path","Add scoring type")
			if(!choice) return
			var/backup = choice
			choice = text2path(choice)

			if(!choice)
				to_chat(user, SPAN_WARNING("[backup] is not a valid type path, and can not be added."))
				return

			var/score_val = tgui_input_number(user,"What score value would you like to associate with this type?","Add score value",1)

			score_type_paths[choice] = score_val

			to_chat(user, SPAN_NOTICE("Added [choice] with a score value of [score_type_paths[choice]] as a valid scoring option."))

		if("Remove")
			if(score_stock_locked)
				to_chat(user,SPAN_WARNING("score_stock_locked is enabled, no changes can be made at this time."))
				return
			choice = tgui_input_list(user,"Please select a type to remove","Remove type",score_type_paths)
			if(!choice) return

			score_type_paths -= choice

			to_chat(user, SPAN_NOTICE("Removed [choice] from the list of valid scoring items."))

		if("Change")
			if(score_stock_locked)
				to_chat(user,SPAN_WARNING("score_stock_locked is enabled, no changes can be made at this time."))
				return
			choice = tgui_input_list(user,"Please select a type to change the score value of","Change score value",score_type_paths)
			if(!choice) return

			var/score_val = tgui_input_number(user,"What score value would you like to associate with this type?","Change score value",score_type_paths[choice])
			if(!score_val) return

			score_type_paths[choice] = score_val

			to_chat(user, SPAN_NOTICE("Changed the score value for [choice] to [score_type_paths[choice]]."))
		if("Automate")
			if(firetime)
				choice = tgui_input_list(user,"[src] is configured to announce \"[choice]\".","Automation",list("Cancel Announcement","Announce Now","Nevermind"))
				if(choice == "Cancel Announcement")
					STOP_PROCESSING(SSobj,src)
					queued_msg = null
					firetime = null
					return
				else if(choice == "Announce Now")
					firetime = world.time
					return
				else return
			choice = null
			if(msg_hist.len)
				if(tgui_input_list(user,"Would you like to input a new message, or select a previously entered one?","Automation",list("New","Select")) == "Select")
					choice = tgui_input_list(user,"Select a previously entered message.","Automation",msg_hist)
			if(!choice)
				choice = tgui_input_text(user,"What would you like to announce?","Automation")
			if(!choice) return
			var/ourtime = tgui_input_number(user,"In how many minutes would you like this to be said?","Automation")
			if(!ourtime) return
			if(tgui_input_list(user,"[src] will announce \"[choice]\" in [ourtime] minutes. Is that okay?","Automation Confirmation",list("Cancel","Confirm")) != "Confirm")
				to_chat(user,"CANCELLED - \"[choice]\"")
				return
			queued_msg = choice
			msg_hist += choice
			firetime = world.time + (ourtime MINUTES)
			START_PROCESSING(SSobj,src)

		else return

/obj/score_keeper/attack_ghost(mob/user)
	. = ..()
	attack_hand(user)

/obj/score_keeper/attackby(obj/item/O, mob/user)
	. = ..()

	if(!isliving(user))
		return

	var/atom/check = submit_check(O,user)

	if(!check)
		return

	if(!(check.type in score_type_paths))
		if(user.client.holder && !score_stock_locked)
			if(tgui_alert(user,"Would you like to add this type of item as an item that can be scored with?","[src] configuration",list("Yes","No")) != "Yes") return

			var/score_val = tgui_input_number(user,"What score value would you like to associate with this type?","Change score value",1)

			score_type_paths[check.type] = score_val
			to_chat(user, SPAN_NOTICE("Added [check.type] with a score value of [score_type_paths[check.type]] as a valid scoring option."))
		return

	var/ourscore = scoreboard[user.real_name]

	ourscore += score_type_paths[check.type]

	scoreboard[user.real_name] = ourscore

	var/yup = pick(list("schlorps up", "nyomps", "licks", "inhales", "vores", "eats", "ingests", "accepts", "devours", "evaporates"))

	to_chat(user, "[SPAN_WARNING("\The [src] [yup] \the [check]!!!")] - [SPAN_NOTICE("Your score is now [scoreboard[user.real_name]].")]")

	if(check != O)
		qdel(O)
	qdel(check)

/obj/score_keeper/proc/submit_check(obj/item/O,mob/user)

	if(istype(O,/obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = O

		if(!isliving(G.affecting))	//Make sure that your grab has a mob and that it's the right kind
			return FALSE	//How did you even get here

		if(G.affecting.ckey)	//Let's only submit NPCs
			to_chat(user,SPAN_WARNING("\The [G.affecting] can not be submitted."))
			return FALSE

		return G.affecting

	if(istype(O,/obj/item/weapon/holder))
		var/obj/item/weapon/holder/H = O

		if(!H.held_mob)	//Let's make sure the holder has a mob
			return FALSE

		if(H.held_mob.ckey)	//Let's only submit NPCs
			to_chat(user,SPAN_WARNING("\The [H.held_mob] can not be submitted."))
			return FALSE

		return H.held_mob

	return O

/datum/modifier/autospeak
	name = "Autospeak"
	desc = "You are tracking someone!"

	stacks = MODIFIER_STACK_ALLOWED
	var/our_speech

/datum/modifier/autospeak/expire(silent)
	if(our_speech)
		holder.say(our_speech)
	. = ..()








/obj/score_keeper/verb/report_score()
	set name = "Report Score"
	set category = "Object"
	set desc = "Report the present scoreboard!"
	set src in view(7)

	if(!ismob(usr))
		return

	if(!configured)
		to_chat(usr,SPAN_WARNING("\The [src] isn't configured yet! Contact the event organizer!"))
		return

	var/mob/user = usr

	if(!user.client.holder)
		if(!(user in scoreboard))
			to_chat(user, "[SPAN_WARNING("You haven't registered a score yet.")]")
			return
		to_chat(user, "[SPAN_NOTICE("Your score is [scoreboard[user]].")]")
		return

	if(!scoreboard.len)
		to_chat(usr,SPAN_WARNING("No one has scored yet, so there is nothing to report."))
		return

	var/list/subjects = scoreboard.Copy()

	var/report = SPAN_DANGER("SCORE REPORT START:<br>")

	while(subjects.len)
		var/greatest = list_get_greatest(subjects)

		subjects -= greatest

		report += SPAN_NOTICE("[greatest] - [scoreboard[greatest]]<br>")

	to_chat(user, report)

	if(tgui_alert(user,"Would you like to show the report to everyone?","Global report?",list("Yes","No")) == "Yes")
		to_world(report)

/////DISPENSER/////

/obj/dispenser
	name = "Dispenser"
	desc = "It holds so many things!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "dispenser"

	anchored = TRUE
	density = TRUE

	var/dispense_type							//When clicked, it will give you one of these.
	var/list/dispensed = list()				//If you're on the list you can't take another right now.
	var/dispense_restrict = TRUE				//If true, the dispenser will only allow you to take one until the dispensed list is cleared.

/obj/dispenser/attack_hand(mob/living/user)
	. = ..()

	if(!dispense_type)
		to_chat(user, SPAN_WARNING("\The [src] is not configured! Please contact the event organizer."))
		return

	if(!isliving(user)) return


	if(dispense_restrict)
		if(user.client.holder)
			var/choice = tgui_alert(user,"Would you like to take an item, or reset the round?","[src]",list("Dispense","Reset"))
			if(!choice) return
			if(choice == "Reset")
				dispensed = list()
				to_chat(user, SPAN_NOTICE("The dispensed list has been cleared. Players will be able to collect new items."))
				return

		if(user.ckey in dispensed)
			to_chat(user, SPAN_WARNING("You have taken one too recently, wait until the event runner starts a new round to take another!"))
			return
		dispensed |= user.ckey

	var/obj/N = new dispense_type(get_turf(src))
	if(!user.get_active_hand())
		user.put_in_hands(N)

/obj/dispenser/attackby(obj/item/O, mob/user)
	. = ..()

	if(!isliving(user))
		return

	if(user.client.holder)
		if(tgui_alert(user,"Would you like \the [O] to be what is dispensed?","[src] configuration",list("Yes","No")) != "Yes") return

		dispense_type = O.type
		to_chat(user, SPAN_NOTICE("\The [src] will now dispense [O] - [dispense_type]"))
		return

/obj/dispenser/blue
	icon_state = "dispenser-b"
