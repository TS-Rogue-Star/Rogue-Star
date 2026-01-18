//RS FILE

/obj/item/objective
	name = "objective"
	desc = "Some kind of objective object"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "crystal_key"

	var/target = null

/obj/item/objective/Moved(atom/old_loc, direction, forced, movetime)
	. = ..()
	if(!target)
		return
	if(!loc)
		return
	if(loc == target)
		trigger()

/obj/item/objective/proc/trigger()
	return

/obj/item/objective/proc/report()
	if(!loc)
		to_chat(usr, SPAN_DANGER("[src] has no loc, and so is probably inaccessible. It will now be deleted, so you may want to remake it."))
		qdel(src)
		return

	var/msg = "[src] - "

	if(!isturf(loc))
		msg += "[SPAN_NOTICE(loc)] - "

	var/turf/T = get_turf(src)

	to_chat(usr, "[msg] - [T.loc] - [ADMIN_COORDJMP(T)]")

/client/proc/report_all_objectives()
	set name = "Report Objectives"
	set desc = "Have all the objective objects tell you where they are!"
	set category = "Fun"

	if(!check_rights(R_ADMIN|R_MOD|R_DEBUG|R_EVENT))
		return

	for(var/obj/item/objective/O in world)
		O.report()

/obj/item/objective/flag
	w_class = ITEMSIZE_NO_CONTAINER
	var/turf/startloc
	var/resets = TRUE
	var/announces = TRUE

/obj/item/objective/flag/Initialize()
	. = ..()
	startloc = get_turf(src)

/obj/item/objective/flag/trigger()
	if(!target)
		return
	if(target == loc)
		score()

/obj/item/objective/flag/proc/score()
	anchored = TRUE
	log_and_message_admins("[src] has been captured.")
	if(announces)
		for(var/mob/M in player_list)
			if(!istype(M,/mob/new_player))
				to_chat(M, "<h2 class='alert'>SCORE!!!</h2>")
				to_chat(M, "<span class='alert'>[src] has been captured in [target] and will soon reset.</span>")
				M << 'sound/AI/preamble.ogg'
	if(ismob(loc))
		var/mob/M = loc
		M.drop_from_inventory(src)
	loc = startloc
	anchored = FALSE
