//RS FILE

var/global/list/event_barrier_list = list()

/obj/barrier
	name = "barrier"
	desc = "You might need more than one person to push passed!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "barrier-5"

	anchored = TRUE
	density = TRUE

	color = "#ea98ff"
	plane = PLANE_LIGHTING_ABOVE
	var/barrier_id = "barrier"		//Use this to set which triggers are connected to eachother and the barrier they are connected to

/obj/barrier/New(loc, ...)
	. = ..()
	event_barrier_list |= src

/obj/barrier/Initialize()
	var/area/A = get_area(src)

	if(A)
		A.block_phase_shift = TRUE

/obj/barrier/Destroy()
	event_barrier_list -= src
	. = ..()

/obj/barrier_trigger
	name = "mysterious switch"
	desc = "All of these need to be touched to lower the barrier!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "crystal_key"

	anchored = TRUE
	density = FALSE

	var/triggered_key						//When you press a key, you can't press another key
	var/static/list/trigger_list = list()	//A list of our fellow triggers to iterate through
	var/barrier_id = "barrier"				//Customize this to set which triggers are connected to eachother and the barrier they are connected to
	var/triggered_state = "crystal_key_spent"
	var/untriggered_state = "crystal_key"

/obj/barrier_trigger/New(loc, ...)
	. = ..()
	trigger_list |= src
	icon_state = untriggered_state

/obj/barrier_trigger/Destroy()
	trigger_list -= src
	. = ..()

/obj/barrier_trigger/Click(location, control, params)
	. = ..()
	var/list/P = params2list(params)
	if(P["shift"] || P["ctrl"] || P["middle"] || P["alt"])
		return
	if(!Adjacent(usr))
		return
	if(!isliving(usr))
		return
	if(!user.ckey)	//Players only
		return
	var/mob/living/L = usr
	L.visible_message("\The [L] touches \the [src]...","You touch \the [src]...",runemessage = "tuch...")
	trigger_check(usr)

/obj/barrier_trigger/proc/trigger_check(var/mob/living/user)
	if(!isliving(user))
		return
	if(!user.ckey)	//Players only
		return
	var/msg = TRUE
	if(!triggered_key)
		visible_message("\The [src] clicks audibly as it is triggered...",runemessage = "click...")
		triggered_key = user.ckey
		icon_state = triggered_state
		msg = FALSE

	var/list/keys = list()
	var/list/triggers = list()
	var/triggered_triggers = 0
	for(var/obj/barrier_trigger/T in trigger_list)
		if(barrier_id == T.barrier_id)
			triggers |= T
			if(T.triggered_key)
				triggered_triggers ++
				keys |= T.triggered_key

	if(keys.len == triggers.len)
		trigger()
		return TRUE
	if(triggers.len == triggered_triggers)
		for(var/obj/barrier_trigger/T in triggers)
			T.triggered_key = null
			T.icon_state = untriggered_state
			T.visible_message("\The [src] CLACKs audibly as it resets!",runemessage = "CLACK")
		return TRUE
	if(msg)
		to_chat(user,SPAN_WARNING("\The [src] seems to have already been triggered. Perhaps you need someone else to push the other switches?"))
		return TRUE

/obj/barrier_trigger/proc/trigger()
	for(var/obj/barrier/B in event_barrier_list)
		if(B.barrier_id == barrier_id)
			B.density = FALSE
			B.alpha = 75
			B.plane = PLANE_ADMIN_SECRET

/obj/barrier_trigger/verb/reset()
	for(var/obj/barrier/B in event_barrier_list)
		if(B.barrier_id == barrier_id)
			B.density = TRUE
			B.alpha = 255
			B.plane = PLANE_LIGHTING_ABOVE

	for(var/obj/barrier_trigger/T in trigger_list)
		if(T.barrier_id == barrier_id)
			T.triggered_key = null
			T.icon_state = T.untriggered_state

/obj/barrier_trigger/Crossed(O)
	trigger_check(O)

/client/proc/reset_barrier_trigger(var/obj/barrier_trigger/T as obj in view(view))
	set category = "Fun"
	set name = "Reset Barrier Trigger"
	T.reset()
