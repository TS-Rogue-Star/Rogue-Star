//RS FILE - You can tell I haven't slept because I put comments on the file, I do that when I'm sleepy.

var/global/list/event_barrier_list = list()	//Rather than searching the whole world for barriers when we trigger or reset, we just put them in one big list to go through.

/obj/barrier
	name = "barrier"
	desc = "You might need more than one person to push passed!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "barrier-5"

	anchored = TRUE
	density = TRUE

	color = "#fc033d"
	plane = PLANE_LIGHTING_ABOVE
	var/barrier_id = "barrier"		//Use this to set which triggers are connected to eachother and the barrier they are connected to

/obj/barrier/New(loc, ...)
	. = ..()
	event_barrier_list |= src

/obj/barrier/Initialize()
	var/area/A = get_area(src)

	if(A)
		A.block_phase_shift = TRUE	//I'm picking on shadekin again. If I put a barrier in a place, I probably do not want them zooming passed it.

/obj/barrier/Destroy()
	event_barrier_list -= src
	. = ..()

/obj/barrier_trigger
	name = "mysterious switch"
	desc = "All of these need to be touched to lower the barrier!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "button"

	anchored = TRUE
	density = FALSE

	pixel_y = -2

	var/triggered_key						//When you press a key, you can't press another key
	var/static/list/trigger_list = list()	//A list of our fellow triggers to iterate through
	var/barrier_id = "barrier"				//Customize this to set which triggers are connected to eachother and the barrier they are connected to
	var/triggered_state = "button-p"
	var/untriggered_state = "button"
	var/doubles = FALSE						//If false, the trigger will not allow you to activate a linked trigger if you have already activated one. Any that are true will not care if you pushed another
	var/overlay_state = "button-g"
	var/barrier_color = "#fc033d"
	var/static/list/overlays_cache = list()

/obj/barrier_trigger/puzzle	//Laziness activated
	doubles = TRUE

/obj/barrier_trigger/New(loc, ...)
	. = ..()
	trigger_list |= src

/obj/barrier_trigger/Initialize(mapload)
	. = ..()
	update_icon()	//We need our overlays

/obj/barrier_trigger/Destroy()
	trigger_list -= src
	. = ..()

/obj/barrier_trigger/update_icon()
	. = ..()
	if(!triggered_key)
		icon_state = untriggered_state
		if(!overlay_state)
			return
		var/combine_key = "[overlay_state]-[barrier_color]"
		var/image/our_overlay = overlays_cache[combine_key]
		if(!our_overlay)
			our_overlay = image(icon,null,overlay_state)
			our_overlay.color = barrier_color
			our_overlay.plane = PLANE_LIGHTING_ABOVE
			our_overlay.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = our_overlay
		add_overlay(our_overlay)
	else
		cut_overlays()
		icon_state = triggered_state

/obj/barrier_trigger/Click(location, control, params)	//You clicked it instead of stepping on it, what a weirdo, you don't know where it's been (it doesn't move)
	. = ..()
	if(triggered_key)	//Already pushed, don't care
		to_chat(usr, SPAN_WARNING("\The [src] seems to have already been activated."))
		return
	var/list/P = params2list(params)	//Since we're doing click, there are other things you can do with click, so let's make sure we're not doing them
	if(P["shift"] || P["ctrl"] || P["middle"] || P["alt"])
		return
	if(!Adjacent(usr))	//Also you have to be next to it.
		return
	if(!isliving(usr))	//Also no ghosts.
		return
	var/mob/living/user = usr
	if(!user.ckey)	//Players only, don't want no dang mouse pushing the button, no red panda either, get OUT OF HERE dude
		return
	var/mob/living/L = usr
	L.visible_message("\The [L] touches \the [src]...","You touch \the [src]...",runemessage = "tuch...")	//tuch is the funniest word I ever saw
	trigger_check(usr)	//You fucking did it man great job

/obj/barrier_trigger/proc/trigger_check(var/mob/living/user)
	if(triggered_key)	//Button already been pushed, don't bother
		return
	if(!isliving(user))	//No ghosts or whatever
		return
	if(!user.ckey)	//Players only
		return
	var/key_detect = FALSE	//If true, we discovered the user's ckey on one of the triggers we care about
	var/list/triggers = list()	//We will gather a list of our triggers to compare to how many are triggered
	var/triggered_triggers = 0	//This is what we will compare triggers against.
	for(var/obj/barrier_trigger/T in trigger_list)
		if(barrier_id == T.barrier_id)	//If our barrier_id is the same then we're controlling the same thing so we'll count it!
			triggers |= T
			if(T.triggered_key)	//Someone pushed it
				triggered_triggers ++	//Count it!
				if(T.triggered_key == user.ckey)	//It's our user!!!
					key_detect = TRUE

	if(key_detect && !doubles)	//We have already pushed another button. - If doubles, then we don't care if another button was pushed, it'll still push.
		if(!triggered_key)	//This button has not been pushed though, let's give a hint instead of doing nothing.
			to_chat(user,SPAN_WARNING("\The [src] very unsatisfyingly does nothing when you interact with it. Perhaps someone else needs to interact with this one."))
		return

	if(!triggered_key)	//Our button wasn't pushed already and we did the checks we needed to see if we are allowed to push the button!
		visible_message("\The [src] clicks audibly as it is triggered...",runemessage = "click...")	//nice
		triggered_key = user.ckey	//We register the ckey so that you can't do shenanigans.
		triggered_triggers ++	//Don't forget to count yourself, you might be the last one!
		update_icon()
	if(triggers.len == triggered_triggers)	//We know how many triggers are connected, and how many have been pushed! If the number is the same, then they're all pushed!
		trigger()	//Woo!

/obj/barrier_trigger/proc/trigger()
	for(var/obj/barrier/B in event_barrier_list)
		if(B.barrier_id == barrier_id)
			B.density = FALSE
			B.alpha = 75
			B.plane = PLANE_ADMIN_SECRET	//We'll just hide it instead of deleting it that way we can reset it if we need.

/obj/barrier_trigger/verb/reset()	//Maybe you want to bring the barrier back up for whatever reason!
	for(var/obj/barrier/B in event_barrier_list)
		if(B.barrier_id == barrier_id)
			B.density = TRUE
			B.alpha = 255
			B.plane = PLANE_LIGHTING_ABOVE

	for(var/obj/barrier_trigger/T in trigger_list)
		if(T.barrier_id == barrier_id)
			T.triggered_key = null
			T.update_icon()

/obj/barrier_trigger/Crossed(O)	//You stepped on it instead of clicking it, good work!
	trigger_check(O)

/client/proc/reset_barrier_trigger(var/obj/barrier_trigger/T as obj in view(view))	//You can right click it to reset the trigger, it resets all of the ones connected to it
	set category = "Fun"
	set name = "Reset Barrier Trigger"
	T.reset()
