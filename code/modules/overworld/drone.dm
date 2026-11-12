//RS FILE
/obj/drone_helm
	name = "RECS"
	desc = "It's the remote exocraft control system!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "tenna"
	var/obj/overworld_vehicle/drone/deployable
	var/obj/deployable_teleporter/linked_teleporter
	var/datum/mini_hud/drone/hud
	var/last_deploy = 0
	var/deploy_cooldown = 10 MINUTES

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
	if(user.loc == src)
		return
	if(contents.len)
		to_chat(user, SPAN_DANGER("It's already occupied."))
		return
	if(!tgui_alert(user,"Do you want to enter [src]?","[src]",list("Enter","Do not")) == "Enter")
		return
	if(contents.len)
		to_chat(user, SPAN_DANGER("It's already occupied."))
		return
	user.loc = src
	if(ishuman(user))
		if(user.hud_used)
			refresh_hud(user)
	if(deployable)
		if(drone_check())
			look(user)
		else
			tgui_alert(user, "The deployed drone is non-functional. A new drone will need to be deployed to continue operation. Press the deploy button.","[src]",list("Okay"))
	RegisterSignal(user, COMSIG_MOB_LOGIN, /obj/drone_helm/proc/refresh_hud, TRUE)
	update_health_hud()
	update_energy_hud()

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
	if(deployable.energy <= 0)
		to_chat(user, SPAN_DANGER("\The [deployable] doesn't respond..."))
		return
	deployable.driver = user
	user.set_machine(src)
	if(isliving(user))
		var/mob/living/L = user
		L.looking_elsewhere = 1
		L.handle_vision()
		L.client.perspective = EYE_PERSPECTIVE
		L.client.eye = deployable

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
		UnregisterSignal(L, COMSIG_MOB_LOGIN)
		if(!L.client)
			continue
	if(hud)
		QDEL_NULL(hud)

/obj/drone_helm/proc/refresh_hud(var/mob/living/carbon/human/driver)
	if(!driver)
		for(var/thing in contents)
			if(ishuman(thing))
				var/mob/living/carbon/human/H = thing
				if(!H.client)
					continue
				refresh_hud(H)
				return
	if(hud)
		QDEL_NULL(hud)
	hud = new /datum/mini_hud/drone(driver.hud_used, src)
	if(deployable?.on_map)
		hud.on_om()
	look(driver)

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
	if(last_deploy)
		if(last_deploy + deploy_cooldown > world.time)
			to_chat(user, SPAN_WARNING("\The [src] is still fabricating the next drone. It can not be launched yet."))
			return
	if(deployable)
		trash_deployable()
	var/turf/target
	var/list/potential_spawners = list()
	for(var/obj/effect/landmark/drone_launcher/L in landmarks_list)
		if(!istype(L))
			continue
		if(L.z != z)
			continue
		potential_spawners |= L
	potential_spawners += "Here"
	var/choice = tgui_input_list(user, "Where would you like the drone to be generated?", "DEPLOYING DRONE", potential_spawners)
	if(!choice)
		return
	if(choice == "Here")
		if(linked_teleporter)
			target = get_turf(linked_teleporter)
		else
			target = get_turf(src)
	else if(isobj(choice))
		target = get_turf(choice)
	if(!target)
		to_chat(user, SPAN_WARNING("An error has occured and a drone could not be generated. Contact a developer."))
		return
	deployable = new /obj/overworld_vehicle/drone(target)
	deployable.register_driver(user)
	RegisterSignal(deployable, COMSIG_ENERGY_RELAY, /obj/drone_helm/proc/update_energy_hud, TRUE)
	RegisterSignal(deployable, COMSIG_HEALTH_RELAY, /obj/drone_helm/proc/update_health_hud, TRUE)
	RegisterSignal(deployable, COMSIG_VEHICLE_DESTRUCTION, /obj/drone_helm/proc/vehicle_destroyed, TRUE)
	RegisterSignal(deployable, COMSIG_VEHICLE_POWER_OUT, /obj/drone_helm/proc/power_out, TRUE)
	hud.RegisterSignal(deployable, COMSIG_VEHICLE_ENTERED_OM, /datum/mini_hud/drone/proc/on_om, TRUE)
	hud.RegisterSignal(deployable, COMSIG_VEHICLE_EXITED_OM, /datum/mini_hud/drone/proc/off_om, TRUE)
	update_health_hud()
	update_energy_hud()

/obj/drone_helm/proc/trash_deployable()
	if(deployable)
		deployable.driver.unset_machine()
		UnregisterSignal(deployable, COMSIG_ENERGY_RELAY)
		UnregisterSignal(deployable, COMSIG_HEALTH_RELAY)
		QDEL_NULL(deployable)
	if(linked_teleporter.partner)
		qdel(linked_teleporter.partner)
	update_health_hud()
	update_energy_hud()

/obj/drone_helm/proc/report_energy()
	if(deployable)
		visible_message(span_green("[src] chirps, \"Deployable energy: [deployable.energy].\""))
	else
		to_chat(usr, SPAN_DANGER("You would need to deploy a drone before you can check its energy..."))

/obj/drone_helm/proc/report_health()
	if(deployable)
		visible_message(SPAN_OCCULT("[src] chirps, \"Deployable integrity: [deployable.health].\""))
	else
		to_chat(usr, SPAN_DANGER("You would need to deploy a drone before you can check its health..."))

/obj/drone_helm/proc/land()
	if(!deployable)
		return
	if(abs(deployable.momentum[1]) + abs(deployable.momentum[2]) > 0.25)
		to_chat(usr, SPAN_DANGER("Warning: unsafe landing speed. Aborting."))
		return
	deployable.momentum[1] = 0
	deployable.momentum[2] = 0
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
		for(var/obj/effect/landmark/drone_landsite/L in landmarks_list)
			if(!istype(L))
				continue
			if(!(L.z in v.map_z))
				if(!(L.z in v.extra_z_levels))
					continue
			var/turf/lt = get_turf(L)
			if(lt.check_density(FALSE,TRUE))
				continue
			destinations |= L

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

/obj/drone_helm/proc/power_out()
	visible_message(SPAN_WARNING("Warning: [deployable] power depleted. Drone lost."), runemessage = "Drone lost...")
	disconnect()

/obj/drone_helm/proc/disconnect()
	if(!deployable)
		return

	deployable.driver.unset_machine()
	deployable.driver = null

/obj/drone_helm/proc/drone_check()
	if(!deployable)
		return FALSE
	if(deployable.energy <= 0)
		return FALSE
	if(deployable.health <= 0)
		return FALSE
	return TRUE

/obj/drone_helm/proc/vehicle_destroyed()
	visible_message(SPAN_WARNING("Warning: [deployable] critical malfunction. Drone lost."), runemessage = "Drone lost...")
	trash_deployable()

/obj/drone_helm/proc/update_health_hud()
	if(!hud)
		return
	if(!deployable)
		hud.update_health(0)
	else
		hud.update_health(deployable.health)

/obj/drone_helm/proc/update_energy_hud()
	if(!hud)
		return
	if(!deployable)
		hud.update_energy(0)
	else
		hud.update_energy(deployable.energy)

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
	RegisterSignal(owner_console, COMSIG_ENERGY_RELAY, /datum/mini_hud/drone/proc/update_energy, TRUE)
	health = new ()
	owner_console.RegisterSignal(health, COMSIG_CLICK,/obj/drone_helm/proc/report_health, TRUE)
	RegisterSignal(owner_console, COMSIG_HEALTH_RELAY, /datum/mini_hud/drone/proc/update_health, TRUE)

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

/datum/mini_hud/drone/proc/update_health(var/our_health)
	health.update_health(our_health)

/datum/mini_hud/drone/proc/update_energy(var/our_energy)
	energy.update_energy(our_energy)

/datum/mini_hud/drone/proc/on_om()
	land.alpha = 255
	land.mouse_opacity = TRUE
	deploy.alpha = 50
	deploy.mouse_opacity = FALSE
/datum/mini_hud/drone/proc/off_om()
	land.alpha = 50
	land.mouse_opacity = FALSE
	deploy.alpha = 255
	deploy.mouse_opacity = TRUE

/obj/screen/drone
	icon = 'icons/rogue-star/overworld_drone_ui.dmi'
	icon_state = "eject"
	screen_loc = "CENTER-2:16,SOUTH+2:16"

/obj/screen/drone/deploy
	name = "Deploy"
	icon_state = "deploy"

/obj/screen/drone/deploy/Click()
	SEND_SIGNAL(src,COMSIG_CLICK)

/obj/screen/drone/eject
	name = "Eject"
	icon_state = "eject"

/obj/screen/drone/eject/MouseEntered(location, control, params)
	. = ..()
	flick("eject_on", src)

/obj/screen/drone/land
	name = "Land"
	icon_state = "land"
	alpha = 50
	mouse_opacity = FALSE

/obj/screen/drone/energy
	name = "Energy"
	icon_state = "energy_frame"
	var/static/icon_cache = list()

/obj/screen/drone/energy/proc/update_energy(var/our_value)
	our_value = round(our_value, 2)
	if(our_value < 0)
		our_value = 0

	var/iconkey = "energy-[our_value]"
	var/image/ourstate = icon_cache[iconkey]

	if(!ourstate)
		var/icon/bar = new('icons/rogue-star/overworld_drone_ui.dmi',"energy_bar")
		var/icon/frame = new('icons/rogue-star/overworld_drone_ui.dmi',"energy_frame")
		if(our_value < 100)
			var/icon/mask = new('icons/rogue-star/overworld_drone_ui.dmi',"mask")
			bar.Blend(mask,ICON_ADD,40 + our_value / 2)
		bar.Blend(frame,ICON_OVERLAY)
		ourstate = image(bar)
		ourstate.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE

		icon_cache[iconkey] = ourstate

	icon = ourstate


/obj/screen/drone/health
	name = "Health"
	icon_state = "health_frame"
	var/static/icon_cache = list()

/obj/screen/drone/health/proc/update_health(var/our_value)
	our_value = round(our_value, 2)
	if(our_value < 0)
		our_value = 0

	var/iconkey = "health-[our_value]"
	var/image/ourstate = icon_cache[iconkey]

	if(!ourstate)
		var/bar_state = "health_bar"
		switch(our_value)
			if(76 to INFINITY)
				bar_state = "health_bar"
			if(51 to 75)
				bar_state = "health_bar_yellow"
			if(26 to 50)
				bar_state = "health_bar_orange"
			else
				bar_state = "health_bar_red"
		var/icon/bar = new('icons/rogue-star/overworld_drone_ui.dmi',bar_state)
		var/icon/frame = new('icons/rogue-star/overworld_drone_ui.dmi',"health_frame")
		if(our_value < 100)
			var/icon/mask = new('icons/rogue-star/overworld_drone_ui.dmi',"mask")
			bar.Blend(mask,ICON_ADD,40 + our_value / 2)

		bar.Blend(frame,ICON_OVERLAY)
		ourstate = image(bar)
		ourstate.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE

		icon_cache[iconkey] = ourstate

	icon = ourstate

/obj/effect/landmark/drone_launcher
	name = "drone launcher"
	desc = "Launches drones."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "tenna"
	invisibility = 0
/obj/effect/landmark/drone_landsite
	name = "drone landsite"
	desc = "Drones land here"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "tenna"
