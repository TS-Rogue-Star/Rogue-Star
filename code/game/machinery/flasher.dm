// It is a gizmo that flashes a small area
/obj/machinery/flasher
	name = "Mounted flash"
	desc = "A wall-mounted flashbulb device."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "mflash1"
	layer = ABOVE_WINDOW_LAYER
	var/id = null
	var/range = 2 //this is roughly the size of brig cell
	var/disable = 0
	var/last_flash = 0 //Don't want it getting spammed like regular flashes
	var/strength = 10 //How weakened targets are when flashed.
	var/base_state = "mflash"
	var/halloss_per_flash = 30 // RS ADD
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 2

/obj/machinery/flasher/portable //Portable version of the flasher. Only flashes when anchored
	name = "portable flasher"
	desc = "A portable flashing device. Wrench to activate and deactivate. Cannot detect slow movements."
	icon_state = "pflash1"
	strength = 8
	anchored = FALSE
	base_state = "pflash"
	density = TRUE

/obj/machinery/flasher/power_change()
	..()
	if(!(stat & NOPOWER))
		icon_state = "[base_state]1"
//		sd_SetLuminosity(2)
	else
		icon_state = "[base_state]1-p"
//		sd_SetLuminosity(0)

//Don't want to render prison breaks impossible
/obj/machinery/flasher/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(W.is_wirecutter())
		add_fingerprint(user)
		disable = !disable
		if(disable)
			user.visible_message("<span class='warning'>[user] has disconnected the [src]'s flashbulb!</span>", "<span class='warning'>You disconnect the [src]'s flashbulb!</span>")
		if(!disable)
			user.visible_message("<span class='warning'>[user] has connected the [src]'s flashbulb!</span>", "<span class='warning'>You connect the [src]'s flashbulb!</span>")

//Let the AI trigger them directly.
/obj/machinery/flasher/attack_ai()
	if(anchored)
		return flash()
	else
		return

/obj/machinery/flasher/proc/flash()
	if(!(powered()))
		return

	if((disable) || (last_flash && world.time < last_flash + 150))
		return

	playsound(src, 'sound/weapons/flash.ogg', 100, 1)
	flick("[base_state]_flash", src)
	last_flash = world.time
	use_power(1500)

	for(var/mob/living/O in viewers(src, null))
		if(get_dist(src, O) > range || O.is_incorporeal())
			continue

		var/flash_time = strength // RS EDIT
		if(istype(O, /mob/living/carbon/human)) // NIF Check!
			var/mob/living/carbon/human/L = O
			if(L.nif && L.nif.flag_check(NIF_V_FLASHPROT,NIF_FLAGS_VISION))
				L.nif.notify("High intensity light detected, and blocked!",TRUE)
				continue

		if(iscarbon(O)) // Carbon mobs
			var/mob/living/carbon/C = O
			if(C.stat != DEAD)
				var/safety = C.eyecheck()
				if(safety <= 0)
					if(ishuman(C))
						var/mob/living/carbon/human/H = C
						flash_time *= H.species.flash_mod

						if(flash_time != 0)
							H.Confuse(flash_time + 2)
							H.Blind(flash_time)
							H.eye_blurry = max(H.eye_blurry, flash_time + 5)
							H.flash_eyes()
							H.adjustHalLoss(halloss_per_flash * (strength / 5)) // Should take four flashes to stun.
							H.apply_damage(strength * H.species.flash_burn/5, BURN, BP_HEAD, 0, 0, "Photon burns")
		else if(issilicon(O)) // Silicon mobs.
			var/mob/living/silicon/S = O
			if (isrobot(S))
				var/mob/living/silicon/robot/R = S
				if (R.has_active_type(/obj/item/borg/combat/shield))
					var/obj/item/borg/combat/shield/shield = locate() in R
					if (shield && shield.active)
						shield.adjust_flash_count(R, 1)
						continue
			S.Weaken(rand(5,10)) // END RS EDIT

/obj/machinery/flasher/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return
	if(prob(75/severity))
		flash()
	..(severity)

obj/machinery/flasher/process() // RS ADD
	if(disable || !anchored || (last_flash && world.time < last_flash + 150))
		return
	for (var/mob/living/O in viewers(src,null))
		if (get_dist(src, O) <= range && O.m_intent != "walk" && !(O.is_incorporeal()) && !(O.lying))
			flash()

/obj/machinery/flasher/portable/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(W.is_wrench())
		add_fingerprint(user)
		anchored = !anchored

		if(!anchored)
			user.show_message(text("<span class='warning'>[src] can now be moved.</span>"))
			cut_overlays()
			unsense_proximity(callback = /atom/proc/HasProximity)

		else if(anchored)
			user.show_message(text("<span class='warning'>[src] is now secured.</span>"))
			add_overlay("[base_state]-s")
			sense_proximity(callback = /atom/proc/HasProximity)


/obj/machinery/button/flasher
	name = "flasher button"
	desc = "A remote control switch for a mounted flasher."

/obj/machinery/button/flasher/attack_hand(mob/user as mob)

	if(..())
		return

	use_power(5)

	active = 1
	icon_state = "launcheract"

	for(var/obj/machinery/flasher/M in machines)
		if(M.id == id)
			spawn()
				M.flash()

	sleep(50)

	icon_state = "launcherbtt"
	active = 0

	return
