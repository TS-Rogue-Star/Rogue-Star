//RS FILE
/obj/listener
	name = "analogue accoustiphone"
	desc = "It looks kinda like some weird kind of ear."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "listener-statue"
	anchored = TRUE
	density = TRUE

	var/list/password_list = list()
	var/listener_id = null
	var/listener_global = FALSE
	var/listener_language

/obj/listener/attack_ghost(mob/user)
	. = ..()

	if(!user?.client?.holder) return
	var/list/choicelist = list("Add Password")
	if(password_list.len > 0)
		choicelist |= "Remove Password"
	choicelist |= "Set Language"
	if(listener_language)
		choicelist |= "Remove Language"
	choicelist |= "Trigger"
	choicelist |= "Untrigger"
	var/choice = tgui_input_list(user,"What will you do?",src.name,choicelist)
	if(!choice)
		return
	switch(choice)
		if("Add Password")
			choice = null
			choice = tgui_input_text(user,"What password?",src.name)
			if(choice)
				password_list |= choice
				log_admin("has added \"[choice]\" to [src] password_list")
		if("Remove Password")
			if(password_list.len <= 0)
				to_chat(user,SPAN_DANGER("There are no passwords set."))
				return
			choice = null
			choice = tgui_input_list(user,"Remove which?",src.name,password_list)
			if(choice)
				password_list -= choice
				to_chat(user,SPAN_NOTICE("[choice] has been removed from the password list."))
				log_admin("has removed \"[choice]\" from [src] password_list")
		if("Set Language")
			choice = null
			choice = tgui_input_list(user,"Which language should it listen for?",src.name,GLOB.all_languages)
			if(choice)
				listener_language = choice
		if("Remove Language")
			listener_language = null
		if("Trigger")
			trigger()
			log_admin("has manually triggered [src]")
		if("Untrigger")
			untrigger()
			log_admin("has untriggered [src]")

/obj/listener/hear_talk(mob/M, list/message_pieces, verb)
	. = ..()
	for(var/msg in message_pieces)
		var/datum/multilingual_say_piece/P = msg
		if(listener_language)
			if(listener_language != P.speaking.name)
				continue
		for(var/pw in password_list)
			if(isatom(pw))
				var/atom/ourpass = pw
				pw = ourpass.name
			if(findtext(P.message, pw))
				trigger()

/obj/listener/proc/trigger()
	action()
/obj/listener/proc/untrigger()
	action(FALSE)

/obj/listener/proc/action(var/trigger = TRUE)
	var/multipoint_triggered = FALSE
	for(var/obj/thing as obj in view(world.view,get_turf(src)))
		if(istype(thing,/obj/machinery/door/blast))
			var/obj/machinery/door/blast/B = thing
			if(listener_id == B.id)
				if(trigger)
					if(B.density)
						B.open()
				else
					if(!B.density)
						B.close()
			continue
		if(istype(thing,/obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/D = thing
			if(listener_id == D.id_tag)
				if(trigger)
					D.unlock()
					D.open()
					D.lock()
				else
					D.unlock()
					D.close()
					D.lock()
			continue
		if(istype(thing,/obj/event_obstical))
			var/obj/event_obstical/O = thing
			if(listener_id == O.id)
				if(trigger)
					if(O.density)
						O.post_trigger()
				else
					if(!O.density)
						O.post_trigger()
			continue
		if(istype(thing,/obj/structure/simple_door))
			var/obj/structure/simple_door/D = thing
			if(listener_id == D.lock_id)
				if(trigger)
					D.locked = FALSE
					D.Open()
				else
					D.Close()
					D.locked = TRUE
			continue
		if(istype(thing,/obj/multipoint))
			if(multipoint_triggered)
				continue
			multipoint_triggered = TRUE
			for(var/obj/multipoint/T in multipoint_triggerable_list)
				if(listener_id == T.trigger_id)
					if(trigger)
						T.trigger()
					else
						T.untrigger()
				continue
/obj/listener/wall
	icon_state = "listener"
	density = FALSE
