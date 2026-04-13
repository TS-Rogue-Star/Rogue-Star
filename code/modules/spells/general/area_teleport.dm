/spell/area_teleport
	name = "Teleport"
	desc = "This spell teleports you to a type of area of your selection."

	school = "abjuration"
	charge_max = 600
	spell_flags = NEEDSCLOTHES
	invocation = "SCYAR NILA"
	invocation_type = SpI_SHOUT
	cooldown_min = 200 //100 deciseconds reduction per rank

	smoke_spread = 1
	smoke_amt = 5

	var/randomise_selection = 0 //if it lets the usr choose the teleport loc or picks it from the list
	var/invocation_area = 1 //if the invocation appends the selected area

	cast_sound = 'sound/effects/teleport.ogg'

	hud_state = "wiz_tele"

/spell/area_teleport/before_cast()
	return

// RS Edit: Area Tele Cleanup (Lira, April 2026)
/spell/area_teleport/choose_targets(mob/user = usr)
	if(!user)
		return
	if(!teleportlocs || !teleportlocs.len)
		rebuild_teleport_locs()
	if(!teleportlocs || !teleportlocs.len)
		var/turf/user_turf = get_turf(user)
		if(user_turf)
			rebuild_teleport_locs(list(user_turf.z))
	if(!teleportlocs || !teleportlocs.len)
		to_chat(user, "<span class='warning'>The spell matrix cannot find any teleport destinations.</span>")
		return

	var/A = null

	if(!randomise_selection)
		A = tgui_input_list(user, "Area to teleport to", "Teleport", teleportlocs)
	else
		A = pick(teleportlocs)
	if(!A)
		return

	var/area/thearea = null
	if(isarea(A))
		thearea = A
	else
		thearea = teleportlocs[A]
	if(!thearea)
		to_chat(user, "<span class='warning'>The spell matrix lost its destination lock. Please try again.</span>")
		return

	return list(thearea)

// RS Edit: Area Tele Cleanup (Lira, April 2026)
/spell/area_teleport/cast(list/targets, mob/user)
	if(!targets || !targets.len)
		return
	var/area/thearea = targets[1]
	if(!istype(thearea))
		return
	var/list/L = list()
	for(var/turf/T in get_current_area_turfs(thearea))
		if(!T.density)
			var/clear = 1
			for(var/obj/O in T)
				if(O.density)
					clear = 0
					break
			if(clear)
				L+=T

	if(!L.len)
		to_chat(user, "The spell matrix was unable to locate a suitable teleport destination for an unknown reason. Sorry.")
		return

	if(user && user.buckled)
		user.buckled.unbuckle_mob()

	var/list/possible_destinations = L.Copy()
	var/turf/attempt = null
	var/success = 0
	while(possible_destinations.len)
		attempt = pick(possible_destinations)
		success = user.forceMove(attempt)
		if(!success)
			possible_destinations.Remove(attempt)
		else
			break

	if(!success)
		to_chat(user, "The spell matrix was unable to complete the teleport. Please try again.")

	return

/spell/area_teleport/after_cast()
	return

// RS Edit: Area Tele Cleanup (Lira, April 2026)
/spell/area_teleport/invocation(mob/user, list/targets)
	var/area/chosenarea = null
	if(targets && targets.len)
		chosenarea = targets[1]
	if(!invocation_area || !istype(chosenarea))
		return ..()
	var/original_invocation = invocation
	invocation = "[invocation] [uppertext(chosenarea.name)]"
	. = ..()
	invocation = original_invocation
