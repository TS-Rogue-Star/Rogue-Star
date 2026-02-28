////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star February 2026: Close all lockers on current z-level //
////////////////////////////////////////////////////////////////////////////////////////

/datum/admin_secret_item/fun_secret/close_all_lockers_current_z
	name = "Close All Lockers (Current Z-Level)"
	log = 0

/datum/admin_secret_item/fun_secret/close_all_lockers_current_z/execute(var/mob/user)
	. = ..()
	if(!.)
		return

	var/turf/user_turf = get_turf(user)
	if(!user_turf)
		to_chat(user, "<span class='warning'>Error: Could not determine your current z-level.</span>")
		return

	var/target_z = user_turf.z
	var/open_lockers = 0
	var/closed_lockers = 0

	for(var/obj/structure/closet/locker in world)
		if(!isturf(locker.loc))
			continue
		if(locker.z != target_z)
			continue
		if(!locker.opened)
			continue

		open_lockers++
		if(locker.close())
			closed_lockers++

	to_chat(user, "<span class='notice'>Closed [closed_lockers] of [open_lockers] open lockers on z-level [target_z].</span>")
	log_and_message_admins("closed [closed_lockers] of [open_lockers] open lockers on z-level [target_z].", user)
