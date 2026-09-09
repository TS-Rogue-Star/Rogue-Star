//RS FILE - You can tell I haven't slept because I put comments on the file, I do that when I'm sleepy.

var/global/list/multipoint_triggerable_list = list()	//Rather than searching the whole world for triggerables when we trigger or reset, we just put them in one big list to go through.
var/global/list/multipoint_trigger_list = list()		// Used for admin-only reset verb (Lira, January 2026)

/obj/multipoint
	name = "DON'T USE ME"
	desc = "A base type for the multipoint trigger objects!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "box"

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

/obj/multipoint/barrier/dungeon_trigger(mob/user)
	trigger()

/obj/multipoint/barrier/dungeon_untrigger(mob/user)
	untrigger()

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
	if(density)
		return
	assess_activity()

/obj/multipoint/teleporter/untrigger()
	if(!density)
		return
	toggle_active()

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
	cut_overlays()
	. = ..()
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
	var/list/targlist = get_dungeon_pair()
	if(!targlist)
		return
	if(targlist.len <= 0)
		return
	var/datum/component/dungeon_mechanic/pair/P = pick(targlist)
	var/obj/target = P.parent
	teleport_to_opposite_side_or_randomize(to_teleport,src,target)

/obj/multipoint/teleporter/proc/toggle_active()
	density = !density
	if(density)
		visible_message(span_cult("With a flash of light \the [src] activates!"),runemessage = "FWOOM")
	else
		visible_message(SPAN_DANGER("\The [src] shuts down..."),runemessage = "...")
	update_icon()

/obj/multipoint/teleporter/proc/assess_activity()
	var/list/targs = get_dungeon_pair()
	if(!targs)
		return
	if(targs.len <= 0)
		return

	toggle_active()

/obj/multipoint/teleporter/dungeon_trigger(mob/user)
	assess_activity()

/obj/multipoint/teleporter/dungeon_lock(mob/user)
	if(!density)
		return
	density = FALSE
	update_icon()
	visible_message(SPAN_DANGER("\The [src] shuts down..."),runemessage = "...")

/obj/multipoint/teleporter/dungeon_pair()
	. = ..()

	if(.)
		assess_activity()

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
	multipoint_trigger_list |= src // Used for admin-only reset verb (Lira, January 2026)

/obj/multipoint_trigger/Initialize(mapload)
	. = ..()
	update_icon()	//We need our overlays

/obj/multipoint_trigger/Destroy()
	trigger_list -= src
	multipoint_trigger_list -= src // Used for admin-only reset verb (Lira, January 2026)
	. = ..()

/obj/multipoint_trigger/update_icon()
	cut_overlays()
	. = ..()
	if(!istriggered())
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
	SEND_SIGNAL(src,COMSIG_DUNGEON_TRIGGER,user)

/obj/multipoint_trigger/dungeon_trigger(mob/user)
	update_icon()
/obj/multipoint_trigger/dungeon_untrigger(mob/user)
	update_icon()

/obj/multipoint_trigger/Crossed(O)	//You stepped on it instead of clicking it, good work!
	trigger_check(O)
