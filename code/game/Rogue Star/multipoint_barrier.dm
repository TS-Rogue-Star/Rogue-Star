//RS FILE - You can tell I haven't slept because I put comments on the file, I do that when I'm sleepy.

var/global/list/multipoint_triggerable_list = list()	//Rather than searching the whole world for triggerables when we trigger or reset, we just put them in one big list to go through.

/obj/multipoint
	name = "DON'T USE ME"
	desc = "A base type for the multipoint trigger objects!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "box"

	var/trigger_id = "REPLACE ME"		//Use this to set which triggers are connected to eachother and the object they are connected to

/obj/multipoint/New(loc, ...)
	. = ..()
	multipoint_triggerable_list |= src

/obj/multipoint/Destroy()
	multipoint_triggerable_list -= src
	. = ..()

/obj/multipoint/proc/trigger()
	return

/obj/multipoint/proc/untrigger()
	return

/////BARRIER/////
/obj/multipoint/barrier
	name = "barrier"
	desc = "You might need more than one person to push passed!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "barrier-5"

	anchored = TRUE
	density = TRUE

	color = "#fc033d"
	plane = PLANE_LIGHTING_ABOVE
	trigger_id = "barrier"		//Use this to set which triggers are connected to eachother and the barrier they are connected to

/obj/multipoint/barrier/Initialize()
	var/area/A = get_area(src)

	if(A)
		A.block_phase_shift = TRUE	//I'm picking on shadekin again. If I put a barrier in a place, I probably do not want them zooming passed it.

/obj/multipoint/barrier/trigger()
	density = FALSE
	alpha = 75
	plane = PLANE_ADMIN_SECRET	//We'll just hide it instead of deleting it that way we can reset it if we need.

/obj/multipoint/barrier/untrigger()
	density = TRUE
	alpha = 255
	plane = PLANE_LIGHTING_ABOVE

/////TELEPORTER/////
/obj/multipoint/teleporter
	name = "mysterious pad"
	desc = "A smooth pad embellished with impossibly complicated etchings..."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "teleporter"

	anchored = TRUE

	var/teleport_id = "teleporter"
	var/static/list/teleporters_list = list()
	var/active_state = "teleporter"
	var/inactive_state = "teleporter"
	var/teleporter_overlay = "teleporter_glow"
	var/teleporter_overlay_color = "#ff82d5"
	var/static/list/overlays_cache = list()

/obj/multipoint/teleporter/trigger()
	density = FALSE
	assess_activity()

/obj/multipoint/teleporter/untrigger()
	density = TRUE
	toggle_active()

/obj/multipoint/teleporter/New(loc, ...)
	. = ..()
	teleporters_list |= src

/obj/multipoint/teleporter/Destroy()
	teleporters_list -= src
	. = ..()

/obj/multipoint/teleporter/Bumped(AM)
	. = ..()

	teleport(AM)

/obj/multipoint/teleporter/attack_hand(mob/living/user)
	. = ..()
	if(!density)
		to_chat(usr, SPAN_WARNING("\The [src] doesn't respond."))
		return
	if(!Adjacent(usr))	//Also you have to be next to it.
		return

	teleport(usr)

/obj/multipoint/teleporter/attack_ghost(mob/user)
	. = ..()
	if(!density)
		if(!check_rights(R_FUN))
			return
	teleport(usr)

/obj/multipoint/teleporter/update_icon()
	. = ..()
	cut_overlays()
	if(density)
		icon_state = active_state
		if(!teleporter_overlay)
			return
		var/combine_key = "[teleporter_overlay]-[teleporter_overlay_color]"
		var/image/our_overlay = overlays_cache[combine_key]
		if(!our_overlay)
			our_overlay = image(icon,null,teleporter_overlay)
			our_overlay.color = teleporter_overlay_color
			our_overlay.plane = PLANE_LIGHTING_ABOVE
			our_overlay.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = our_overlay
		add_overlay(our_overlay)
		set_light(3, 0.75, teleporter_overlay_color)

	else
		icon_state = inactive_state
		set_light(0)

/obj/multipoint/teleporter/proc/teleport(var/to_teleport)
	if(!to_teleport)
		return
	var/list/targlist = list()
	for(var/obj/multipoint/teleporter/tele in teleporters_list)
		if(tele == src)
			continue
		if(tele.teleport_id == teleport_id)
			targlist |= tele

	if(targlist.len <= 0)
		toggle_active()
	teleport_to_opposite_side_or_randomize(to_teleport,src,pick(targlist))

/obj/multipoint/teleporter/proc/toggle_active()
	density = !density
	if(density)
		visible_message(span_cult("With a flash of light \the [src] activates!"),runemessage = "FWOOM")
	else
		visible_message(SPAN_DANGER("\The [src] shuts down..."),runemessage = "...")
	update_icon()

/obj/multipoint/teleporter/proc/assess_activity()
	for(var/obj/multipoint/teleporter/tele in teleporters_list)
		if(tele == src)
			continue
		if(tele.teleport_id == teleport_id)
			toggle_active()
			return

/////DA BUTTAN/////
/obj/multipoint_trigger
	name = "mysterious switch"
	desc = "All of these need to be touched to lower the barrier!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "button"

	anchored = TRUE
	density = FALSE

	pixel_y = -2

	var/triggered_key						//When you press a key, you can't press another key
	var/static/list/trigger_list = list()	//A list of our fellow triggers to iterate through
	var/trigger_id = "REPLACE ME"			//Customize this to set which triggers are connected to eachother and the barrier they are connected to
	var/triggered_state = "button-p"
	var/untriggered_state = "button"
	var/doubles = FALSE						//If false, the trigger will not allow you to activate a linked trigger if you have already activated one. Any that are true will not care if you pushed another
	var/overlay_state = "button-g"
	var/barrier_color = "#fc033d"
	var/static/list/overlays_cache = list()

/obj/multipoint_trigger/puzzle	//Laziness activated
	doubles = TRUE

/obj/multipoint_trigger/New(loc, ...)
	. = ..()
	trigger_list |= src

/obj/multipoint_trigger/Initialize(mapload)
	. = ..()
	update_icon()	//We need our overlays

/obj/multipoint_trigger/Destroy()
	trigger_list -= src
	. = ..()

/obj/multipoint_trigger/update_icon()
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

/obj/multipoint_trigger/Click(location, control, params)	//You clicked it instead of stepping on it, what a weirdo, you don't know where it's been (it doesn't move)
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

/obj/multipoint_trigger/proc/trigger_check(var/mob/living/user)
	if(triggered_key)	//Button already been pushed, don't bother
		return
	if(!isliving(user))	//No ghosts or whatever
		return
	if(!user.ckey)	//Players only
		return
	var/key_detect = FALSE	//If true, we discovered the user's ckey on one of the triggers we care about
	var/list/triggers = list()	//We will gather a list of our triggers to compare to how many are triggered
	var/triggered_triggers = 0	//This is what we will compare triggers against.
	for(var/obj/multipoint_trigger/T in trigger_list)
		if(trigger_id == T.trigger_id)	//If our trigger_id is the same then we're controlling the same thing so we'll count it!
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

/obj/multipoint_trigger/proc/trigger()
	for(var/obj/multipoint/T in multipoint_triggerable_list)
		if(T.trigger_id == trigger_id)
			T.trigger()

/obj/multipoint_trigger/verb/reset()	//Maybe you want to bring the barrier back up for whatever reason!
	for(var/obj/multipoint/T in multipoint_triggerable_list)
		if(T.trigger_id == trigger_id)
			T.untrigger()

	for(var/obj/multipoint_trigger/T in trigger_list)
		if(T.trigger_id == trigger_id)
			T.triggered_key = null
			T.update_icon()

/obj/multipoint_trigger/Crossed(O)	//You stepped on it instead of clicking it, good work!
	trigger_check(O)

/client/proc/reset_multipoint_trigger(var/obj/multipoint_trigger/T as obj in view(view))	//You can right click it to reset the trigger, it resets all of the ones connected to it
	set category = "Fun"
	set name = "Reset Barrier Trigger"
	T.reset()
