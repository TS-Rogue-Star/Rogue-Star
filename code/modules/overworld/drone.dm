//RS FILE
/obj/drone_helm
	name = "RECS"
	desc = "It's the remote exocraft control system!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "tenna"
	var/obj/overworld_vehicle/drone/deployable
	var/obj/deployable_teleporter/linked_teleporter
	var/datum/mini_hud/drone/hud

/obj/drone_helm/Initialize(mapload)
	. = ..()
	search_for_teleporter()

/obj/drone_helm/proc/search_for_teleporter()
	var/turf/to_search = locate(x,y+1,z)
	for(var/obj/O in to_search.contents)
		if(istype(O,/obj/deployable_teleporter))
			link_teleporter(O)
			return TRUE
	to_search = locate(x,y-1,z)
	for(var/obj/O in to_search.contents)
		if(istype(O,/obj/deployable_teleporter))
			link_teleporter(O)
			return TRUE
	to_search = locate(x+1,y,z)
	for(var/obj/O in to_search.contents)
		if(istype(O,/obj/deployable_teleporter))
			link_teleporter(O)
			return TRUE
	to_search = locate(x-1,y,z)
	for(var/obj/O in to_search.contents)
		if(istype(O,/obj/deployable_teleporter))
			link_teleporter(O)
			return TRUE
	return FALSE

/obj/drone_helm/proc/link_teleporter(var/obj/deployable_teleporter/our_teleporter)
	if(!our_teleporter)
		return FALSE

	linked_teleporter = our_teleporter
	linked_teleporter.deployable_item = FALSE

	RegisterSignal(linked_teleporter, COMSIG_PARENT_QDELETING, PROC_REF(unlink_teleporter), TRUE)

/obj/drone_helm/proc/unlink_teleporter()
	UnregisterSignal(linked_teleporter, COMSIG_PARENT_QDELETING)
	linked_teleporter = null

/obj/drone_helm/attack_hand(mob/living/user)
	. = ..()
	if(!user)
		return FALSE
	if(!isliving(user))
		return FALSE
	enter(user)

/obj/drone_helm/proc/enter(var/mob/living/carbon/human/user)
	if(contents.len || !user)
		to_chat(user, SPAN_DANGER("It's already occupied."))
		return FALSE
	user.loc = src
	if(ishuman(user))
		if(user.hud_used)
			if(!hud)
				hud = new /datum/mini_hud/drone(user.hud_used, src)
			else
				hud.apply_to_hud(user.hud_used)
//		user.client.screen |= hud
	look(user)

/obj/drone_helm/relaymove(mob/user, direction)
	if(deployable)
		deployable.relaymove(user, direction)

/obj/drone_helm/check_eye(var/mob/user)
	. = ..()
	if(user.loc != src)
		return FALSE
	return TRUE

/obj/drone_helm/proc/look(var/mob/user)
	if(!deployable || !user)
		return
	deployable.driver = user
	user.set_machine(src)
	if(isliving(user))
		var/mob/living/L = user
		L.looking_elsewhere = 1
		L.handle_vision()
		L.client.perspective = EYE_PERSPECTIVE
		L.client.eye = deployable

//	if(linked)
//		apply_visual(user)
//		user.reset_view(linked)
//		if(linked.real_appearance)
//			user.client?.images += linked.real_appearance


//	user.set_viewsize(world.view + extra_view)
//	GLOB.moved_event.register(user, src, /obj/machinery/computer/ship/proc/unlook)
	// TODO GLOB.stat_set_event.register(user, src, /obj/machinery/computer/ship/proc/unlook)
//	LAZYDISTINCTADD(viewers, WEAKREF(user))

/obj/drone_helm/verb/eject()
	set name = "Eject"
	set category = "Object"
	set src in view(1)

	var/turf/T = get_turf(src)
	if(deployable?.driver)
		deployable.driver.unset_machine()
		deployable.driver = null

	for(var/atom/movable/thing in contents)
		thing.forceMove(T)
		if(!isliving(thing))
			continue
		var/mob/living/L = thing
		if(!L.client)
			continue
		if(hud)
			L.hud_used.remove_minihud(hud)
//		L.client.screen -= hud

/obj/drone_helm/proc/deploy()
	set name = "Deploy"
	set category = "Object"

	var/mob/user = usr
	if(user.loc != src)
		return
	if(!deployable)
		generate_deployable(user)
		look(user)
		return
	else if(!linked_teleporter)
		search_for_teleporter()
		if(!linked_teleporter)
			to_chat(usr, SPAN_DANGER("\The [src] boops sadly. It is missing a teleporter to link to."))
			return
	else if(linked_teleporter.partner)
		var/choice = tgui_alert(user, "The teleporter is already linked. Do you want to move the teleporter or return the drone to the station?", "Deploy Alert", list("Move","Return"))
		if(!choice)
			return
		if(choice == "Move")
			var/turf/T = get_turf(linked_teleporter.partner)
			deployable.forceMove(T)
			deployable.register_driver(user)
			qdel(linked_teleporter.partner)
			deployable.locked = FALSE
			look()
			return
		if(choice == "Return")
			trash_deployable()
			return
	if(deployable.on_map)
		to_chat(user, SPAN_WARNING("You can't deploy the teleporter here, you need to land the drone first."))
		return

	var/obj/deployable_teleporter/drone/new_deployable = new(get_turf(deployable))
	deployable.locked = TRUE
	deployable.loc = new_deployable
	deployable.input_momentum = list(0,0)
	deployable.momentum = list(0,0)

	linked_teleporter.pair(new_deployable)
	eject()

/obj/drone_helm/proc/generate_deployable(var/mob/living/user)
	if(!user)
		return
	if(deployable)
		trash_deployable()
	deployable = new /obj/overworld_vehicle/drone(get_turf(src))
	deployable.register_driver(user)
	SEND_SIGNAL(src,COMSIG_HEALTH_RELAY,deployable.health)
	SEND_SIGNAL(src,COMSIG_ENERGY_RELAY,deployable.energy)

/obj/drone_helm/proc/trash_deployable()
	if(deployable)
		deployable.driver.unset_machine()
		QDEL_NULL(deployable)
	if(linked_teleporter.partner)
		qdel(linked_teleporter.partner)
	SEND_SIGNAL(src,COMSIG_HEALTH_RELAY,0)
	SEND_SIGNAL(src,COMSIG_ENERGY_RELAY,0)

/obj/drone_helm/proc/report_energy()
	visible_message(deployable.driver,span_green("[src] [deployable] energy: [deployable.energy]"))

/obj/drone_helm/proc/report_health()
	visible_message(deployable.driver,SPAN_OCCULT("[src] [deployable] integrity: [deployable.health]"))

/obj/drone_helm/proc/land()
	if(!deployable)
		return
	var/turf/T = get_turf(deployable)
	if(!T)
		return
	if(!istype(T, /turf/unsimulated/map))
		return
	var/mob/living/user = usr
	if(!isliving(user))
		return
	var/list/destinations = list()
	for(var/obj/effect/overmap/visitable/v in T.contents)
		if(!istype(v, /obj/effect/overmap/visitable))
			continue
		for(var/obj/effect/shuttle_landmark/landmark in v.generic_waypoints)
			var/turf/lt = get_turf(landmark)
			if(lt.check_density(FALSE,TRUE))
				continue
			destinations |= landmark

	if(!destinations.len)
		to_chat(user, SPAN_WARNING("There is nowhere to land here."))
		return
	var/obj/effect/overmap/visitable/our_dest = tgui_input_list(user, "Where will you land?", "Drone Landing", destinations)
	if(!our_dest)
		to_chat(user, SPAN_DANGER("Landing aborted"))
		return
	to_chat(user, span_green("\The [deployable] begins its landing approach..."))
	if(do_after(user, 10 SECONDS))
		if(deployable.loc != T)
			to_chat(user, SPAN_WARNING("\The [deployable] moved too far away and missed the landing site."))
			return
		deployable.forceMove(get_turf(our_dest))
		deployable.momentum = list(0,0)


///// HUD /////

/datum/mini_hud/drone
	var/obj/drone_helm/owner_console
	var/obj/screen/drone/energy/energy
	var/obj/screen/drone/health/health
	var/obj/screen/drone/deploy/deploy
	var/obj/screen/drone/eject/eject
	var/obj/screen/drone/land/land
	needs_processing = FALSE

/datum/mini_hud/drone/New(var/datum/hud/other, var/obj/drone_helm/owner)
	owner_console = owner
	energy = new ()
	owner_console.RegisterSignal(energy, COMSIG_CLICK, /obj/drone_helm/proc/report_energy, TRUE)
	RegisterSignal(owner_console, COMSIG_ENERGY_RELAY, PROC_REF(update_energy), TRUE)
	health = new ()
	owner_console.RegisterSignal(health, COMSIG_CLICK,/obj/drone_helm/proc/report_health, TRUE)
	RegisterSignal(owner_console, COMSIG_HEALTH_RELAY, PROC_REF(update_health), TRUE)

	deploy = new ()
	owner_console.RegisterSignal(deploy, COMSIG_CLICK, /obj/drone_helm/proc/deploy, TRUE)
	eject = new ()
	owner_console.RegisterSignal(eject, COMSIG_CLICK, /obj/drone_helm/verb/eject, TRUE)
	land = new ()
	owner_console.RegisterSignal(land, COMSIG_CLICK, /obj/drone_helm/proc/land, TRUE)
	screenobjs = list(energy, health, deploy, eject, land)

	for(var/obj/screen/S as anything in screenobjs)
		S.master = owner_console
	..()

/datum/mini_hud/drone/Destroy()
	owner_console.UnregisterSignal(energy, COMSIG_CLICK)
	owner_console.UnregisterSignal(health, COMSIG_CLICK)
	owner_console.UnregisterSignal(deploy, COMSIG_CLICK)
	owner_console.UnregisterSignal(eject, COMSIG_CLICK)
	owner_console.UnregisterSignal(land, COMSIG_CLICK)
	UnregisterSignal(owner_console,COMSIG_ENERGY_RELAY)
	UnregisterSignal(owner_console,COMSIG_HEALTH_RELAY)
	owner_console = null
	. = ..()

/datum/mini_hud/drone/proc/update_health()
	var/our_health = args[2]
	switch(our_health)
		if(90 to 100)
			health.icon_state = "health-5"
		if(70 to 89)
			health.icon_state = "health-4"
		if(40 to 69)
			health.icon_state = "health-3"
		if(20 to 39)
			health.icon_state = "health-2"
		if(1 to 19)
			health.icon_state = "health-1"
		else
			health.icon_state = "health-0"

/datum/mini_hud/drone/proc/update_energy()
	var/our_energy = args[2]
	switch(our_energy)
		if(90 to 100)
			energy.icon_state = "energy-5"
		if(70 to 89)
			energy.icon_state = "energy-4"
		if(40 to 69)
			energy.icon_state = "energy-3"
		if(20 to 39)
			energy.icon_state = "energy-2"
		if(1 to 19)
			energy.icon_state = "energy-1"
		else
			energy.icon_state = "energy-0"

/obj/screen/drone
	icon = 'icons/rogue-star/overworld.dmi'
	icon_state = "eject"

/obj/screen/drone/deploy
	name = "Deploy"
	icon_state = "deploy"
	screen_loc = ui_rig_airtoggle

/obj/screen/drone/deploy/Click()
	SEND_SIGNAL(src,COMSIG_CLICK)

/obj/screen/drone/eject
	name = "Eject"
	icon_state = "eject"
	screen_loc = ui_rig_airtoggle

/obj/screen/drone/land
	name = "Land"
	icon_state = "land"
	screen_loc = ui_rig_airtoggle

/obj/screen/drone/energy
	name = "Energy"
	icon_state = "energy-5"
	screen_loc = ui_rig_airtoggle

/obj/screen/drone/health
	name = "Health"
	icon_state = "health"
	screen_loc = ui_rig_airtoggle
