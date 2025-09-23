//backpack item
/obj/item/device/continuous_medigun
	name = "protoype bluespace medigun backpack"
	desc = "Contains a bluespace medigun, this portable unit digitizes and stores chems and battery power used by the attached gun."
	icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_override = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_state = "mg-backpack"
	item_state = "mg-backpack-onmob"
	slot_flags = SLOT_BACK
	force = 5
	throwforce = 6
	preserve_item = TRUE
	w_class = ITEMSIZE_HUGE
	unacidable = TRUE
	origin_tech = list(TECH_BIO = 4, TECH_POWER = 2, TECH_BLUESPACE = 4)
	action_button_name = "Remove/Replace medigun"

	var/obj/item/device/bork_medigun/linked/medigun
	var/obj/item/weapon/cell/bcell = /obj/item/weapon/cell
	var/obj/item/weapon/cell/ccell = null
	var/obj/item/weapon/stock_parts/matter_bin/sbin = /obj/item/weapon/stock_parts/matter_bin
	var/obj/item/weapon/stock_parts/scanning_module/smodule = /obj/item/weapon/stock_parts/scanning_module
	var/obj/item/weapon/stock_parts/manipulator/smanipulator = /obj/item/weapon/stock_parts/manipulator
	var/obj/item/weapon/stock_parts/capacitor/scapacitor = /obj/item/weapon/stock_parts/capacitor
	var/obj/item/weapon/stock_parts/micro_laser/slaser = /obj/item/weapon/stock_parts/micro_laser
	var/charging = FALSE
	var/brutecharge = 0
	var/toxcharge = 0
	var/burncharge = 0
	var/brutevol = 0
	var/toxvol = 0
	var/burnvol = 0
	var/chemcap = 60
	var/tankmax = 30
	var/containsgun = TRUE
	var/maintenance = FALSE
	var/smaniptier = 1
	var/sbintier = 1
	var/gridstatus = 0
	var/chargecap = 1000
	var/compact = 0
	var/busy = FALSE
	var/kenzie = FALSE

//belt item
/obj/item/device/continuous_medigun/compact
	name = "prototype bluespace medigun backpack - compact"
	desc = "Contains a compact version of the bluespace medigun able to be used one handed, this portable unit digitizes and stores chems and battery power used by the attached gun."
	icon_state = "mg-belt"
	item_state = "mg-belt-onmob"
	compact = TRUE
	w_class = ITEMSIZE_LARGE
	slot_flags = SLOT_BELT
	/*scapacitor = /obj/item/weapon/stock_parts/capacitor/adv
	smanipulator = /obj/item/weapon/stock_parts/manipulator/nano
	smodule = /obj/item/weapon/stock_parts/scanning_module/adv
	slaser = /obj/item/weapon/stock_parts/micro_laser/high
	bcell = /obj/item/weapon/cell/apc*/ //For CMO version later
	/*tankmax = 60
	brutecharge = 60
	toxcharge = 60
	burncharge = 60
	chemcap = 120
	brutevol = 120
	toxvol = 120
	burnvol = 120
	chargecap = 5000*/


/obj/item/weapon/paper/continuous_medigun_manual
	name = "Bluespace LongRange Experimental Medigun manual"
	info = {"<h4>Bluespace Longrange  Experimental Medigun</h4>
	<p></p>
	<p>A prototype bluespace medigun in development by BORK</p>
	<p></p>
	<br />
	<ul>
		<li>Hello and welcome to your quick field guide for the Blem</li>
		<li>Device accepts power cells, feel free to bother security!</li>
		<li>Device is refilled using chems, namely Bicaridine, Dylovene, and Kelotane.</li>
		<li>Device must be worn to use, backpack variant will fit on your back, while the compact one may be worn as a belt.</li>
		<li>Device comes with an intuitive and detailed user interface, Just look at the screen for a readout. ((There is an icon on the top left of your screen))</li>
		<li>Usage is simple, take the medigun into your hands and point at the target you wish to heal, unit will do the rest.</li>
		<li>Device may be upgraded with parts obtained from science, ensure the maintenance hatch is open before installing.</li>
		<li>You may open the hatch with either a screwdriver, or through the user interface.</li>
		<li>Once the maintenance hatch is open, you may either eject everything with a crowbar, or through the user interface under the convienient parts tab.</li>
		<li>Go forth and spread healthiness, Were counting on you and your feedback to produce a better product!</li>
		<li>Please forward any feedback and complaints to 'Sari Bork' CEO of Bork Industries.</li>
	</ul>"}

/obj/item/device/continuous_medigun_modkit
	name = "Continuous Medigun upgrade kit"
	desc = "A kit containing all the needed tools and parts to upgrade the BLEM."
	icon_state = "modkit"


/obj/item/device/continuous_medigun/proc/is_twohanded()
	return !compact

/obj/item/device/continuous_medigun/proc/apc_charge()
	gridstatus = 0
	var/area/A = get_area(src)
	if(!istype(A) || !A.powered(EQUIP))
		return FALSE
	gridstatus = 1
	if(bcell && (bcell.charge < bcell.maxcharge))
		var/cur_charge = bcell.charge
		var/delta = min(50, bcell.maxcharge-cur_charge)
		bcell.give(delta)
		A.use_power_oneoff(delta*100, EQUIP)
		gridstatus = 2
	return TRUE


/obj/item/device/continuous_medigun/proc/do_upgrade()
	name = "prototype bluespace medigun backpack - compact"
	desc = "Contains a compact version of the bluespace medigun able to be used one handed, this portable unit digitizes and stores chems and battery power used by the attached gun."
	icon_state = "mg-belt"
	item_state = "mg-belt-onmob"
	compact = TRUE
	w_class = ITEMSIZE_LARGE
	slot_flags = SLOT_BELT
	update_icon()
	playsound(src,'sound/items/change_drill.ogg',25,1)


/obj/item/device/continuous_medigun/proc/adjust_brutevol(modifier)
	if(modifier > brutevol)
		modifier = brutevol
	if(modifier > (tankmax - brutecharge))
		modifier = tankmax - brutecharge
	brutevol -= modifier
	brutecharge += modifier

/obj/item/device/continuous_medigun/proc/adjust_burnvol(modifier)
	if(modifier > burnvol)
		modifier = burnvol
	if(modifier > (tankmax - burncharge))
		modifier = tankmax - burncharge
	burnvol -= modifier
	burncharge += modifier

/obj/item/device/continuous_medigun/proc/adjust_toxvol(modifier)
	if(modifier > toxvol)
		modifier = toxvol
	if(modifier > (tankmax - toxcharge))
		modifier = tankmax - toxcharge
	toxvol -= modifier
	toxcharge += modifier

/obj/item/device/continuous_medigun/process()
	if(!bcell)
		return

	if(bcell.charge >= 10)
		var/icon_needs_update = FALSE
		if(brutecharge < tankmax && brutevol > 0 && (bcell.checked_use(smaniptier * 2)))
			adjust_brutevol(smaniptier * 2)
			icon_needs_update = TRUE
		if(burncharge < tankmax && burnvol > 0 && (bcell.checked_use(smaniptier * 2)))
			adjust_burnvol(smaniptier * 2)
			icon_needs_update = TRUE
		if(toxcharge < tankmax && toxvol > 0 && (bcell.checked_use(smaniptier * 2)))
			adjust_toxvol(smaniptier * 2)
			icon_needs_update = TRUE
		//Alien tier
		if(sbintier >= 5 && medigun.busy == MEDIGUN_IDLE && (bcell.charge >= 10))
			if(brutevol < chemcap && (bcell.checked_use(10)))
				icon_needs_update = TRUE
				brutevol ++
			if(burnvol < chemcap && (bcell.checked_use(10)))
				icon_needs_update = TRUE
				burnvol ++
			if(toxvol < chemcap && (bcell.checked_use(10)))
				icon_needs_update = TRUE
				toxvol ++

		if(icon_needs_update)
			update_icon()
	/*else if(!charging && ccell && ccell.check_charge(50))
		if(ismob(loc))
			to_chat(loc, span_warning("The Inserted Cell clicks as it charges the capacitor."))
		charging = TRUE*/

	if(scapacitor.get_rating() >= 5)
		if(apc_charge())
			charging = FALSE
			return
		charging = TRUE

	if(!charging || !ccell)
		return
	var/missing = min(50, bcell.amount_missing())
	if((missing > 0))
		if(ccell && ccell.checked_use(missing))
			bcell.give(missing)
			update_icon()
			return

		//if(ismob(loc))
			//to_chat(loc, span_notice("The Cell is out of power."))
		charging = FALSE

/obj/item/device/continuous_medigun/get_cell()
	return bcell

/obj/item/device/continuous_medigun/update_icon()
	. = ..()
	cut_overlays()
	if((bcell.percent() <= 5 ))
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "no_battery"))
	else if((bcell.percent() <= 25 && bcell.percent() > 5))
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "low_battery"))

	if(brutevol <= 0 && brutecharge > 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "red"))
	else if(brutecharge <= 0 && brutevol <= 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "redstrike-blink"))

	if(toxvol <= 0 && toxcharge > 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "green"))
	else if(toxcharge <= 0 && toxvol <= 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "greenstrike-blink"))

	if(burnvol <= 0 && burncharge > 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "orange"))
	else if(burncharge <= 0 && burnvol <= 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "orangestrike-blink"))

/obj/item/device/continuous_medigun/proc/replace_icon(inhand)
	var/sprite = "-backpack"
	if(compact)
		sprite = "-belt"
	var/special = null
	if(kenzie)
		special = "-kenzie"
	if(inhand)
		icon_state = "mg[sprite]-deployed[special]"
		item_state = "mg[sprite]-deployed-onmob[special]"
		if(is_twohanded())
			medigun.icon_state = "medblaster[special]"
			medigun.base_icon_state = "medblaster[special]"
			medigun.wielded_item_state = "medblaster[special]-wielded"
			medigun.update_icon()
			to_chat(world, span_notice("Inhand, twohand"))
		else
			medigun.icon_state = "medblaster-compact[special]"
			medigun.base_icon_state = "medblaster-compact[special]"
			medigun.wielded_item_state = ""
			medigun.update_icon()
			to_chat(world, span_notice("Inhand, onehand"))
	else if(is_twohanded())
		icon_state = "mg[sprite][special]"
		item_state = "mg[sprite]-onmob[special]"
		medigun.icon_state = "medblaster[special]"
		medigun.base_icon_state = "medblaster[special]"
		to_chat(world, span_notice("onback, twohand"))
	else
		icon_state = "mg[sprite][special]"
		item_state = "mg[sprite]-onmob[special]"
		medigun.icon_state = "medblaster-compact[special]"
		medigun.base_icon_state = "medblaster-compact[special]"
		to_chat(world, span_notice("onback, onehand"))

	update_icon()

/obj/item/device/continuous_medigun/Initialize(mapload)
	. = ..()
	if(ispath(medigun))
		medigun = new medigun(src, src)
	else
		medigun = new(src, src)
	/*if(!is_twohanded())
		medigun.beam_range = 4*/
	if(ispath(bcell))
		bcell = new bcell(src)
		bcell.charge = 0
	if(ispath(sbin))
		sbin = new sbin(src)
	if(ispath(smodule))
		smodule = new smodule(src)
		START_PROCESSING(SSobj, src)
	if(ispath(smanipulator))
		smanipulator = new smanipulator(src)
	if(ispath(scapacitor))
		scapacitor = new scapacitor(src)
	if(ispath(slaser))
		slaser = new slaser(src)
	update_icon()


/obj/item/device/continuous_medigun/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(medigun)
	QDEL_NULL(bcell)
	QDEL_NULL(smodule)
	QDEL_NULL(smanipulator)
	QDEL_NULL(scapacitor)
	QDEL_NULL(slaser)
	. = ..()

/obj/item/device/continuous_medigun/equipped(var/mob/user, var/slot)

	//to_chat(world, span_notice("bark [user.real_name] \ [slot] \ [user.ckey]"))
	if(slot == slot_back || slot == slot_belt || slot == slot_s_store)
		if(user.real_name == "Kenzie Houser" && user.ckey == "memewuff")
			kenzie = TRUE
			to_chat(user, span_notice("Epic Lasagna Wolf Detected, Engaging BAD ASS MODE."))
		else
			kenzie = FALSE
			//to_chat(world, span_notice("Not Kenzie"))
		replace_icon()
	..()

/*
/obj/item/device/continuous_medigun/AltClick(mob/user)
	if(charging)
		to_chat(usr, span_notice("You disable the phoron generator."))
		charging = FALSE
		return

	if(phoronvol > 0)
		to_chat(usr, span_notice("You enable the phoron generator."))
		charging = TRUE
		return

	to_chat(usr, span_warning("Not Enough Phoron stored."))

*/


/obj/item/device/continuous_medigun/emp_act(severity)
	. = ..()
	if(bcell)
		bcell.emp_act(severity)
	if(ccell)
		ccell.emp_act(severity)

/obj/item/device/continuous_medigun/attack_hand(mob/user)
	/*if(maintenance)
		maintenance = FALSE
		to_chat(user, span_notice("You close the maintenance hatch on \the [src]."))
		return*/

	if(loc == user)
		toggle_medigun()
		return

	..()

/obj/item/device/continuous_medigun/MouseDrop()
	if(ismob(src.loc))
		if(!CanMouseDrop(src))
			return
		var/mob/M = src.loc
		if(!M.unEquip(src))
			return
		src.add_fingerprint(usr)
		M.put_in_any_hand_if_possible(src)



/obj/item/device/continuous_medigun/attackby(obj/item/weapon/W, mob/user, params)
	if(refill_reagent(W, user))
		return
	if(W == medigun)
		//to_chat(user, span_warning("backpack clicked with gun"))
		reattach_medigun(user)
		return
	if(istype(W, /obj/item/device/continuous_medigun_modkit))
		if(slot_check())
			to_chat(user, span_notice("Please place \the [src] on the ground before upgrading."))
			return
		to_chat(user, span_notice("You convert and upgrade \the [src] to be more compact."))
		do_upgrade()
		medigun.wielded_item_state = ""
		medigun.wielded = FALSE
		medigun.item_state_slots.Cut()
		qdel(W)
	if(W.is_crowbar() && maintenance)
		if(smodule )
			smodule.forceMove(get_turf(loc))
			smodule = null

		if(smanipulator)
			STOP_PROCESSING(SSobj, src)
			smanipulator.forceMove(get_turf(loc))
			smanipulator = null
			smaniptier = 0

		if(slaser)
			slaser.forceMove(get_turf(loc))
			slaser = null

		if(scapacitor)
			STOP_PROCESSING(SSobj, src)
			scapacitor.forceMove(get_turf(loc))
			scapacitor = null

		if(sbin)
			STOP_PROCESSING(SSobj, src)
			sbin.forceMove(get_turf(loc))
			sbin = null
			sbintier = 0

		to_chat(user, span_notice("You remove the Components from \the [src]."))
		update_icon()
		return TRUE

	if(W.is_screwdriver())
		if(!maintenance)
			maintenance = TRUE
			to_chat(user, span_notice("You open the maintenance hatch on \the [src]."))
			reattach_medigun(user)
			return

		maintenance = FALSE
		to_chat(user, span_notice("You close the maintenance hatch on \the [src]."))
		return
	if(istype(W, /obj/item/weapon/cell/device))
		busy = TRUE
		if(!do_after(user, 10))
			busy = FALSE
			return
		busy = FALSE
		if(!user.unEquip(W))
			return
		if(ccell)
			if(!user.put_in_hands(ccell))
				ccell.forceMove(get_turf(loc))
			to_chat(user, span_notice("You Swap the [W] for \the [ccell]."))
			playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
		if(!ccell)
			to_chat(user, span_notice("You install the [W] into \the [src]."))
			playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
		W.forceMove(src)
		ccell = W
		charging = TRUE
		return


	if(maintenance)
		if(busy == FALSE)
			if(istype(W, /obj/item/weapon/stock_parts/scanning_module))
				if(smodule)
					if(W.type == smodule.type)
						to_chat(user, span_notice("\The [src] already has a [W]."))
						return
				busy = TRUE
				if(!do_after(user, 10))
					busy = FALSE
					return
				busy = FALSE
				if(!user.unEquip(W))
					return
				if(smodule)
					if(!user.put_in_hands(smodule))
						smodule.forceMove(get_turf(loc))
					to_chat(user, span_notice("You Swap the [W] for \the [smodule]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				if(!smodule)
					to_chat(user, span_notice("You install the [W] into \the [src]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				W.forceMove(src)
				smodule = W
				medigun.beam_range = 3+smodule.get_rating()
				update_icon()
				return

			if(istype(W, /obj/item/weapon/stock_parts/manipulator))
				if(smanipulator)
					if(W.type == smanipulator.type)
						to_chat(user, span_notice("\The [src] already has a [smanipulator]."))
						return
				busy = TRUE
				if(!do_after(user, 10))
					busy = FALSE
					return
				busy = FALSE
				if(!user.unEquip(W))
					return
				if(smanipulator)
					if(!user.put_in_hands(smanipulator))
						smanipulator.forceMove(get_turf(loc))
					to_chat(user, span_notice("You Swap the [W] for \the [smanipulator]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				if(!smanipulator)
					to_chat(user, span_notice("You install the [W] into \the [src]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				W.forceMove(src)
				smanipulator = W
				smaniptier = smanipulator.get_rating()
				if(sbin && scapacitor)START_PROCESSING(SSobj, src)
				update_icon()
				return

			if(istype(W, /obj/item/weapon/stock_parts/micro_laser))
				if(slaser)
					if(W.type == slaser.type)
						to_chat(user, span_notice("\The [src] already has a [slaser]."))
						return
				busy = TRUE
				if(!do_after(user, 10))
					busy = FALSE
					return
				busy = FALSE
				if(!user.unEquip(W))
					return
				if(slaser)
					if(!user.put_in_hands(slaser))
						slaser.forceMove(get_turf(loc))
					to_chat(user, span_notice("You Swap the [W] for \the [slaser]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				if(!slaser)
					to_chat(user, span_notice("You install the [W] into \the [src]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				W.forceMove(src)
				slaser = W
				update_icon()
				return

			if(istype(W, /obj/item/weapon/stock_parts/capacitor))
				if(scapacitor)
					if(W.type == scapacitor.type)
						to_chat(user, span_notice("\The [src] already has a [scapacitor]."))
						return
				busy = TRUE
				if(!do_after(user, 10))
					busy = FALSE
					return
				busy = FALSE
				if(!user.unEquip(W))
					return
				if(scapacitor)
					if(!user.put_in_hands(scapacitor))
						scapacitor.forceMove(get_turf(loc))
					to_chat(user, span_notice("You Swap the [W] for \the [scapacitor]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				if(!scapacitor)
					to_chat(user, span_notice("You install the [W] into \the [src]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				W.forceMove(src)
				scapacitor = W
				var/scaptier = scapacitor.get_rating()
				if(scaptier == 1)
					chargecap = 1000
					bcell.maxcharge = 1000
					if(bcell.charge > chargecap)
						bcell.charge = chargecap
				else if(scaptier == 2)
					chargecap = 2000
					bcell.maxcharge = 2000
					if(bcell.charge > chargecap)
						bcell.charge = chargecap
				else if(scaptier == 3)
					chargecap = 3000
					bcell.maxcharge = 3000
					if(bcell.charge > chargecap)
						bcell.charge = chargecap
				else if(scaptier == 4)
					chargecap = 4000
					bcell.maxcharge = 4000
					if(bcell.charge > chargecap)
						bcell.charge = chargecap
				else if(scaptier == 5)
					chargecap = 5000
					bcell.maxcharge = 5000
					if(bcell.charge > chargecap)
						bcell.charge = chargecap

				if(sbin && smanipulator)START_PROCESSING(SSobj, src)
				update_icon()
				return

			if(istype(W, /obj/item/weapon/stock_parts/matter_bin))
				if(sbin)
					if(W.type == sbin.type)
						to_chat(user, span_notice("\The [src] already has a matter bin."))
						return
				busy = TRUE
				if(!do_after(user, 10))
					busy = FALSE
					return
				busy = FALSE
				if(!user.unEquip(W))
					return
				if(sbin)
					if(!user.put_in_hands(sbin))
						sbin.forceMove(get_turf(loc))
					to_chat(user, span_notice("You Swap the [W] for \the [sbin]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				if(!sbin)
					to_chat(user, span_notice("You install the [W] into \the [src]."))
					playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
				W.forceMove(src)
				sbin = W
				sbintier = sbin.get_rating()
				if(sbintier >= 5)
					chemcap = 300
					tankmax = 150
				else
					chemcap = 60*(sbintier)
					tankmax = 30*sbintier
				if(brutecharge > chemcap)
					brutecharge = chemcap
				if(burncharge > chemcap)
					burncharge = chemcap
				if(toxcharge > chemcap)
					toxcharge = chemcap
				if(brutecharge > tankmax)
					brutecharge = tankmax
				if(burncharge > tankmax)
					burncharge = tankmax
				if(toxcharge > tankmax)
					toxcharge = tankmax
				if(scapacitor && smanipulator)START_PROCESSING(SSobj, src)
				update_icon()
				return

	return ..()


/obj/item/device/continuous_medigun/proc/refill_reagent(var/obj/item/weapon/container, mob/user)
	. = FALSE
	if(!maintenance && (istype(container, /obj/item/weapon/reagent_containers/glass/beaker) || istype(container, /obj/item/weapon/reagent_containers/glass/bottle)))

		if(!(container.flags & OPENCONTAINER))
			to_chat(user, span_warning("You need to open the [container] first!"))
			return

		var/reagentwhitelist = list("bicaridine", "anti_toxin", "kelotane", "dermaline")//, "tricordrazine")

		for(var/G in container.reagents.reagent_list)
			var/datum/reagent/R = G
			var/modifier = 1
			var/totransfer = 0
			var/name = ""

			if(R.id in reagentwhitelist)
				switch(R.id)
					if("bicaridine")
						name = "bruteheal"
						modifier = 4
						totransfer = chemcap - brutevol
					if("anti_toxin")
						name = "toxheal"
						modifier = 4
						totransfer = chemcap - toxvol
					if("kelotane")
						name = "burnheal"
						modifier = 4
						totransfer = chemcap - burnvol
					if("dermaline")
						name = "burnheal"
						modifier = 8
						totransfer = chemcap - burnvol
					/*if("phoron")
						name = "phoron"
						modifier = 1
						totransfer = chemcap - phoronvol*/ //Changed to battery cell
					/*if("tricordrazine")
						name = "tricordrazine"
						modifier = 1
						if((brutevol != chemcap) && (burnvol != chemcap) && (toxvol != chemcap))
							totransfer = 1  //tempcheck to get past the totransfer check
						else
							totransfer = 0*/
				if(totransfer <= 0)
					to_chat(user, span_notice("The [src] cannot accept anymore [name]!"))
				totransfer = min(totransfer, container.reagents.get_reagent_amount(R.id) * modifier)

				switch(R.id)
					if("bicaridine")
						brutevol += totransfer
					if("anti_toxin")
						toxvol += totransfer
					if("kelotane")
						burnvol += totransfer
					if("dermaline")
						burnvol += totransfer
					//if("phoron")
					//	phoronvol += totransfer
					/*if("tricordrazine") //Tricord too problematic
						var/maxamount = container.reagents.get_reagent_amount(R.id)
						var/amountused
						var/oldbrute = brutevol
						var/oldburn = burnvol
						var/oldtox = toxvol

						while(maxamount > 0)
							if(brutevol >= chemcap && burnvol >= chemcap && toxvol >= chemcap)
								break
							maxamount --
							amountused++
							totransfer ++
							if(brutevol < chemcap)
								brutevol ++
							if(burnvol < chemcap)
								burnvol ++
							if(toxvol < chemcap)
								toxvol ++
						var/readout = "You add [amountused] units of [R.name] to the [src]. \n The [src] Stores "
						var/readoutadditions = FALSE
						if(oldbrute != brutevol)
							readout += "[round(brutevol - oldbrute)] U of bruteheal vol"
							readoutadditions = TRUE
						if(oldburn != burnvol)
							if(readoutadditions)
								readout += ", "
							readout += "[round(burnvol - oldburn)] U of burnheal vol"
							readoutadditions = TRUE
						if(oldtox != toxvol)
							if(readoutadditions)
								readout += ", "
							readout += "[round(toxvol - oldtox)] U of toxheal vol"
						if(oldbrute != brutevol || oldburn != burnvol || oldtox != toxvol)to_chat(user, span_notice("[readout]."))*/
				if(totransfer > 0)
					if(R.id != "tricordrazine")
						to_chat(user, span_notice("You add [totransfer / modifier] units of [R.name] to [src]. \n [src] stores [round(totransfer)] U of [name]."))
					container.reagents.remove_reagent(R.id, totransfer / modifier)
					playsound(src, 'sound/weapons/empty.ogg', 50, 1)
				update_icon()
				. = TRUE
	return

//checks that the base unit is in the correct slot to be used
/obj/item/device/continuous_medigun/proc/slot_check()
	var/mob/M = loc
	if(!istype(M))
		return FALSE //not equipped

	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_back) == src)
		return TRUE
	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_s_store) == src)
		return TRUE
	if((slot_flags & SLOT_BELT) && M.get_equipped_item(slot_belt) == src)
		return TRUE
	return FALSE

/obj/item/device/continuous_medigun/dropped(mob/user)
	..()
	kenzie = FALSE
	replace_icon()
	reattach_medigun(user) //medigun attached to a base unit should never exist outside of their base unit or the mob equipping the base unit

/obj/item/device/continuous_medigun/proc/reattach_medigun(mob/user)
	if(containsgun)
		return
	containsgun = TRUE
	if(!medigun)
		return
	if(medigun.busy)
		medigun.busy = MEDIGUN_IDLE
	replace_icon()
	user.update_inv_back()
	if(ismob(medigun.loc))
		var/mob/M = medigun.loc
		if(M.drop_from_inventory(medigun, src))
			to_chat(user, span_notice("\The [medigun] snaps back into the main unit."))
		return
	//do_after(user, 2, ignore_movement = TRUE)
	medigun.forceMove(src)
	to_chat(user, span_notice("\The [medigun] snaps back into the main unit."))

/obj/item/device/continuous_medigun/proc/checked_use(var/charge_amt)
	return (bcell && bcell.checked_use(charge_amt))
