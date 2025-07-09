/datum/modifier/medbeameffect
	name = "medgunffect"
	desc = "You're being regenerated"
	mob_overlay_state = "medigun_effect"
	stacks = MODIFIER_STACK_EXTEND
	pain_immunity = TRUE
	bleeding_rate_percent = 0.1 //only a little
	incoming_oxy_damage_percent = 0

/obj/item/device/bork_medigun
	name = "Bork Medical Beam Disperser"
	desc = "A highly advanced beam gun, designed for progressive and gradual healing of damaged tissue."
	icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_state = "medblaster"
	var/wielded_item_state = "medblaster-wielded"
	var/base_icon_state = "medblaster"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand_guns_rs.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand_guns_rs.dmi',
		)
	w_class = ITEMSIZE_HUGE
	force = 0
	var/beam_range = 3 // How many tiles away it can scan. Changing this also changes the box size.
	var/busy = FALSE // Set to true when scanning, to stop multiple scans.
	var/wielded = 0
	var/current_target
	var/mgcmo
	canremove = 0

//backpack item
/obj/item/device/medigun_backpack
	name = "Bork Medical Beam Backpack Unit"
	desc = "A highly advanced beam gun unit, designed for progressive and gradual healing of damaged tissue."
	icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_override = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_state = "mg-backpack"
	item_state = "mg-backpack-onmob"
	slot_flags = SLOT_BACK
	force = 5
	throwforce = 6
	preserve_item = 1
	w_class = ITEMSIZE_HUGE
	unacidable = TRUE
	origin_tech = list(TECH_BIO = 4, TECH_POWER = 2, TECH_BLUESPACE = 4)
	action_button_name = "Remove/Replace medigun"

	var/obj/item/device/bork_medigun/linked/medigun
	var/obj/item/weapon/cell/bcell = /obj/item/weapon/cell/apc
	var/obj/item/weapon/stock_parts/matter_bin/sbin = /obj/item/weapon/stock_parts/matter_bin
	var/obj/item/weapon/stock_parts/scanning_module/smodule = /obj/item/weapon/stock_parts/scanning_module
	var/obj/item/weapon/stock_parts/manipulator/smanipulator = /obj/item/weapon/stock_parts/manipulator
	var/obj/item/weapon/stock_parts/capacitor/scapacitor = /obj/item/weapon/stock_parts/capacitor
	var/obj/item/weapon/stock_parts/micro_laser/slaser = /obj/item/weapon/stock_parts/micro_laser
	var/phoronvol = 0
	var/charging = 0
	var/brutecharge = 0
	var/toxcharge = 0
	var/burncharge = 0
	var/brutevol = 0
	var/toxvol = 0
	var/burnvol = 0
	var/chemcap = 60
	var/tankmax = 30
	var/chargecost = 25
	var/bpcmo = 0
	var/containsgun = 1
	var/maintenance
	var/smaniptier = 1
	var/sbintier = 1
	var/regen = 0
	var/gridstatus = 0

//backpack item
/obj/item/device/medigun_backpack/cmo
	name = "Bork Medical Beam Backpack Unit CMO"
	desc = "An even more  advanced beam gun unit, designed for progressive and gradual healing of damaged tissue."
	icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_override = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_state = "mg-backpack_cmo"
	item_state = "mg-backpack_cmo-onmob"
	slot_flags = SLOT_BACK
	force = 5
	throwforce = 6
	preserve_item = 1
	w_class = ITEMSIZE_HUGE
	unacidable = TRUE
	action_button_name = "Remove/Replace medigun"
	scapacitor = /obj/item/weapon/stock_parts/capacitor/adv
	smanipulator = /obj/item/weapon/stock_parts/manipulator/nano
	smodule = /obj/item/weapon/stock_parts/scanning_module/adv
	slaser = /obj/item/weapon/stock_parts/micro_laser/high
	chargecost = 20
	chemcap = 120
	tankmax = 60
	brutecharge = 40
	toxcharge = 40
	burncharge = 40
	brutevol = 60
	toxvol = 60
	burnvol = 60
	bpcmo = 1



/obj/item/device/medigun_backpack/tgui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Medigun", name) // 510, 460
		ui.open()

/obj/item/device/medigun_backpack/tgui_data(mob/user)
	var/mob/living/carbon/human/H = medigun.current_target
	var/patientname = "No Target"
	var/patienthealth = 0
	var/patientbruteloss = 0
	var/patientfireloss = 0
	var/patienttoxloss = 0
	var/patientoxyloss = 0
	//var/minhealth = 0
	if(scapacitor.get_rating() < 5)
		gridstatus = 3
	if(H)
		patientname = H
		patienthealth = max(0, (H.health+abs(config.health_threshold_dead))/(H.maxHealth+abs(config.health_threshold_dead)))
		to_chat(world, "<span class='notice'>Bark [patienthealth] Bark</span>")
		patientbruteloss = H.getBruteLoss()
		patientfireloss = H.getFireLoss()
		patienttoxloss = H.getToxLoss()
		patientoxyloss = H.getOxyLoss()
	var/list/data = list(
		"Generator" = charging,
		"powerCellStatus" = bcell ? bcell.percent() : null,
		"Gridstatus" = gridstatus,
		"PhoronStatus" = sbin ? 100.0*(phoronvol/chemcap) : null,
		"BrutehealCharge" = scapacitor ? 100.0*(brutecharge/tankmax) : null,
		"BrutehealVol" = sbin ? brutevol : null,
		"BurnhealCharge" = scapacitor ? 100.0*(burncharge/tankmax) : null,
		"BurnhealVol" = sbin ? burnvol : null,
		"ToxhealCharge" = scapacitor ? 100.0*(toxcharge/tankmax) : null,
		"ToxhealVol" = sbin ? toxvol : null,
		"patientname" = smodule ? patientname : null,
		"patienthealth" = smodule ? 100 * patienthealth : null,
		"patientbrute" = smodule ? patientbruteloss : null,
		"patientburn" = smodule ? patientfireloss : null,
		"patienttox" = smodule ? patienttoxloss : null,
		"patientoxy" = smodule ? patientoxyloss : null
		)
	return data


/obj/item/device/medigun_backpack/tgui_act(action, params)
	if(..())
		return TRUE

	. = TRUE
	switch(action)
		if("gentoggle")
			ui_action_click()


/obj/item/device/medigun_backpack/examine(mob/user)
	. = ..()
	tgui_interact(user)
	if(Adjacent(user))
		if(maintenance)
			. += "<span class='warning'>The Maintenance hatch is open.</span>"
		if(bcell)
			. += "<span class='notice'>The [bcell.name] is [round(bcell.percent())]% charged.</span>"
		if(!bcell)
			. += "<span class='warning'>It does not have a power source installed.</span>"
		if(maintenance)
			if(smodule)
				if(smodule.get_rating() >= 5)
					. += "<span class='notice'>It has a [smodule.name] installed, device will function within [medigun.beam_range] tiles and through walls.</span>"
				else
					. += "<span class='notice'>It has a [smodule.name] installed, device will function within [medigun.beam_range] tiles.</span>"
			if(!smodule)
				. += "<span class='warning'>It is missing a scanning module.</span>"

			if(smanipulator)
				if(smaniptier >=  5)
					. += "<span class='notice'>It has a [smanipulator.name] installed, chem digitizing is now 125% Efficient.</span>"
				else
					. += "<span class='notice'>It has a [smanipulator.name] installed, chem digitizing is now [(smaniptier/4)*100]% Efficient.</span>"
			if(!smanipulator)
				. += "<span class='warning'>It is missing a manipulator.</span>"
			if(slaser)
				if(slaser.get_rating() >= 5)
					. += "<span class='notice'>It has a [slaser.name] installed and can heal [slaser.get_rating()] damage per cycle, and will stop bleeding and pain while beam focused.</span>"
				else
					. += "<span class='notice'>It has a [slaser.name] installed and can heal [slaser.get_rating()] damage per cycle.</span>"
			if(!slaser)
				. += "<span class='warning'>It is missing a laser.</span>"
			if(scapacitor)
				var/captier = scapacitor.get_rating()
				if(captier < 5)
					. += "<span class='notice'>It has a [scapacitor.name] installed, battery charge will now drain at [chargecost] per second, and grants a heal charge capacity of [tankmax] per type.</span>"
				else
					. += "<span class='notice'>It has a [scapacitor.name] installed, battery charge will now drain at [chargecost] per second, the cell will recharge from the local power grid, it also grants a heal charge capacity of [tankmax] per type.</span>"
			if(!scapacitor)
				. += "<span class='warning'>It is missing a capacitor, you may not digitize chems.</span>"
			if(sbin)
				if(smodule.get_rating() >= 5)
					. += "<span class='notice'>It has a [sbin.name] installed, can hold [chemcap] reserve chems, will slowly generate chems in exchange for power.</span>"
				else
					. += "<span class='notice'>It has a [sbin.name] installed, can hold [chemcap] reserve chems.</span>"
			if(!sbin)
				. += "<span class='warning'>It is missing a matter bin.</span>"
		if(sbin && scapacitor)
			. += "<span class='notice'>The <font color = 'red'>Bruteheal</font> charge meter reads, main:(<font color = 'red'>[brutecharge]</font> / <font color = 'red'>[tankmax]</font>) Reserve: (<font color = 'red'>[brutevol]</font> / <font color = 'red'>[chemcap]</font>)</span>"
			. += "<span class='notice'>The <font color = '#FFA500'>Burnheal</font> charge meter reads, main:(<font color = '#FFA500'>[burncharge]</font> / <font color = '#FFA500'>[tankmax]</font>) Reserve: (<font color = '#FFA500'>[burnvol]</font> / <font color = '#FFA500'>[chemcap]</font>)</span>"
			. += "<span class='notice'>The <font color = 'green'>Toxheal</font> charge meter reads, main:(<font color = 'green'>[toxcharge]</font> / <font color = 'green'>[tankmax]</font>) Reserve: (<font color = 'green'>[toxvol]</font> / <font color = 'green'>[chemcap]</font>)</span>"
			. += "<span class='notice'>The <font color = '#e100ffad'>Phoron</font> tank meter reads: (<font color = '#e100ffad'>[phoronvol]</font> / <font color = '#e100ffad'>[chemcap]</font>)</span>"



/obj/item/device/medigun_backpack/proc/apc_charge()
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

/obj/item/device/medigun_backpack/process()
	var/modifier
	if(bcell.charge >= 10)
		regen = 0
		if(brutecharge < tankmax && brutevol > 0 && (bcell.checked_use(5)))
			modifier = smaniptier * 2
			if(modifier > brutevol)
				modifier = brutevol
			if(modifier > (tankmax - brutecharge))
				modifier = tankmax - brutecharge
			brutevol -= modifier
			regen = 1
			brutecharge += modifier
		if(burncharge < tankmax && burnvol > 0 && (bcell.checked_use(5)))
			modifier = smaniptier * 2
			if(modifier > burnvol)
				modifier = burnvol
			if(modifier > (tankmax - burncharge))
				modifier = tankmax - burncharge
			burnvol -= modifier
			regen = 1
			burncharge += modifier
		if(toxcharge < tankmax && toxvol > 0 && (bcell.checked_use(5)))
			modifier = smaniptier * 2
			if(modifier > toxvol)
				modifier = toxvol
			if(modifier > (tankmax - toxcharge))
				modifier = tankmax - toxcharge
			toxvol -= modifier
			regen = 1
			toxcharge += modifier
		//Alien tier
		if(sbintier >= 5 && medigun.busy == 0  && (bcell.charge >= 10))
			if(brutevol < chemcap && (bcell.checked_use(10)))
				regen = 1
				brutevol ++
			if(burnvol < chemcap && (bcell.checked_use(10)))
				regen = 1
				burnvol ++
			if(toxvol < chemcap && (bcell.checked_use(10)))
				regen = 1
				toxvol ++
		if(regen == 1)
			update_icon()
			//to_chat(world, "<span class='notice'>Regenned.</span>")
	if(bcell && scapacitor.get_rating()>= 5 && charging == 0)
		apc_charge()
	if(bcell && charging)
		if((bcell.amount_missing() >= 50))
			if(phoronvol > 0)
				phoronvol --
				bcell.give(50)
				update_icon()
			else
				if(ismob(loc))
					var/mob/user = loc
					to_chat(user, span("notice", "The phoron generator sputters then stops."))
				charging = 0

/obj/item/device/medigun_backpack/get_cell()
	return bcell

/obj/item/device/medigun_backpack/update_icon()
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
		//to_chat(world, span("warning", "brute empty"))
	if(toxvol <= 0 && toxcharge > 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "green"))
	else if(toxcharge <= 0 && toxvol <= 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "greenstrike-blink"))
		//to_chat(world, span("warning", "tox empty"))
	if(burnvol <= 0 && burncharge > 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "orange"))
	else if(burncharge <= 0 && burnvol <= 0)
		add_overlay(image('code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', "orangestrike-blink"))
		//to_chat(world, span("warning", "burn  empty"))


/obj/item/device/bork_medigun/update_twohanding()
	//to_chat(world, span("warning", "Twohanding"))
	var/mob/living/M = loc
	if(istype(M) && M.item_is_in_hands(src) && !M.hands_are_full())
		wielded = 1
		//to_chat(world, span("warning", "Wielded"))
		name = "[initial(name)] (wielded)"
	else
		wielded = 0
		//to_chat(world, span("warning", "Not wielded"))
		name = initial(name)
	update_held_icon()
	..()

/obj/item/device/bork_medigun/update_held_icon()
	if(wielded_item_state)
		var/mob/living/M = loc
		if(istype(M))
			if(M.can_wield_item(src) && src.is_held_twohanded(M))
				LAZYSET(item_state_slots, slot_l_hand_str, wielded_item_state)
				LAZYSET(item_state_slots, slot_r_hand_str, wielded_item_state)
			else
				LAZYSET(item_state_slots, slot_l_hand_str, initial(item_state))
				LAZYSET(item_state_slots, slot_r_hand_str, initial(item_state))
		..()
/obj/item/device/medigun_backpack/New()
	..()
	if(ispath(medigun))
		medigun = new medigun(src, src)
	else
		medigun = new(src, src)
	if(bpcmo)
		medigun.beam_range = 4
	if(ispath(bcell))
		bcell = new bcell(src)
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


/obj/item/device/medigun_backpack/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(medigun)
	QDEL_NULL(bcell)
	QDEL_NULL(smodule)
	QDEL_NULL(smanipulator)
	QDEL_NULL(scapacitor)
	QDEL_NULL(slaser)



/obj/item/device/medigun_backpack/ui_action_click()
	if(charging)
		to_chat(usr, span("notice", "You disable the phoron generator."))
		charging = 0
	else
		if(phoronvol > 0)
			to_chat(usr, span("notice", "You enable the phoron generator."))
			charging = 1
		else
			to_chat(usr, span("warning", "Not Enough Phoron stored."))
/obj/item/device/medigun_backpack/attack_hand(mob/user)
	if(loc == user)
		toggle_medigun()
	else
		..()

/obj/item/device/medigun_backpack/MouseDrop()
	if(ismob(src.loc))
		if(!CanMouseDrop(src))
			return
		var/mob/M = src.loc
		if(!M.unEquip(src))
			return
		src.add_fingerprint(usr)
		M.put_in_any_hand_if_possible(src)
		/*icon_state = "mg-backpack"
		item_state = "mg-backpack-onmob"
		update_icon() //success
		usr.update_inv_back()*/


/obj/item/device/medigun_backpack/attackby(obj/item/weapon/W, mob/user, params)
	if(!maintenance && (istype(W, /obj/item/weapon/reagent_containers/glass/beaker) || istype(W, /obj/item/weapon/reagent_containers/glass/bottle)))

		playsound(src, 'sound/weapons/empty.ogg', 50, 1)
		var/reagentwhitelist = list("bicaridine", "anti_toxin", "kelotane", "dermaline", "phoron")//, "tricordrazine")

		for(var/G in W.reagents.reagent_list)
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
					if("phoron")
						name = "phoron"
						modifier = 1
						totransfer = chemcap - phoronvol
					/*if("tricordrazine")
						name = "tricordrazine"
						modifier = 1
						if((brutevol != chemcap) && (burnvol != chemcap) && (toxvol != chemcap))
							totransfer = 1  //tempcheck to get past the totransfer check
						else
							totransfer = 0*/
				if(totransfer <= 0)
					to_chat(user, span("notice", "The [src] cannot accept anymore [name]!"))
				totransfer = min(totransfer,W.reagents.get_reagent_amount(R.id) * modifier)
				switch(R.id)
					if("bicaridine")
						brutevol += totransfer
					if("anti_toxin")
						toxvol += totransfer
					if("kelotane")
						burnvol += totransfer
					if("dermaline")
						burnvol += totransfer
					if("phoron")
						phoronvol += totransfer
					/*if("tricordrazine") //Tricord too problematic
						var/maxamount = W.reagents.get_reagent_amount(R.id)
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
						if(oldbrute != brutevol || oldburn != burnvol || oldtox != toxvol)to_chat(user, span("notice", "[readout]."))*/
				if(totransfer > 0)
					if(R.id != "tricordrazine")
						to_chat(user, span("notice", "You add [totransfer / modifier] units of [R.name] to the [src]. \n The [src] stores [round(totransfer)] U of [name]."))
					W.reagents.remove_reagent(R.id, totransfer / modifier)
				update_icon()
	if(W == medigun)
		//to_chat(user, "<span class='warning'>backpack clicked with gun</span>")
		reattach_medigun(user)
	else if(W.is_screwdriver())
		if(!maintenance)
			maintenance = 1
			to_chat(user, "<span class='notice'>You open the maintenance hatch on \the [src].</span>")
			if(!containsgun)
				reattach_medigun(user)
			return
		else
			var/list/installedparts
			installedparts = list("close hatch")
			//if(bcell)
			//	installedparts.Add("cell")
			if(smodule)
				installedparts.Add("scanning module")
			if(sbin)
				installedparts.Add("matter bin")
			if(scapacitor)
				installedparts.Add("capacitor")
			if(smanipulator)
				installedparts.Add("manipulator")
			if(slaser)
				installedparts.Add("laser")
			var/menuchoice = tgui_input_list(user, "Which Module would you like to remove?", "Parts and options:", installedparts)

			if(menuchoice == "close hatch")
				maintenance = 0
				to_chat(user, "<span class='notice'>You close the maintenance hatch on \the [src].</span>")
				return
			/*else if(menuchoice == "cell")
				bcell.update_icon()
				bcell.forceMove(get_turf(src.loc))
				bcell = null
				to_chat(user, "<span class='notice'>You remove the cell from \the [src].</span>")
				update_icon()
				return*/
			else if(menuchoice == "matter bin")
				sbin.update_icon()
				sbin.forceMove(get_turf(src.loc))
				sbin = null
				sbintier = 0
				to_chat(user, "<span class='notice'>You remove the [sbin] from \the [src].</span>")
				update_icon()
				STOP_PROCESSING(SSobj, src)
				return
			else if(menuchoice == "scanning module")
				smodule.update_icon()
				smodule.forceMove(get_turf(src.loc))
				smodule = null
				to_chat(user, "<span class='notice'>You remove the [smodule] from \the [src].</span>")
				update_icon()
				return
			else if(menuchoice == "capacitor")
				scapacitor.update_icon()
				scapacitor.forceMove(get_turf(src.loc))
				scapacitor = null
				to_chat(user, "<span class='notice'>You remove the [scapacitor] from \the [src].</span>")
				STOP_PROCESSING(SSobj, src)
				update_icon()
				return
			else if(menuchoice == "manipulator")
				smanipulator.update_icon()
				smanipulator.forceMove(get_turf(src.loc))
				smanipulator = null
				smaniptier = 0
				STOP_PROCESSING(SSobj, src)
				to_chat(user, "<span class='notice'>You remove the [smanipulator] from \the [src].</span>")
				update_icon()
				return
			else if(menuchoice == "laser")
				slaser.update_icon()
				slaser.forceMove(get_turf(src.loc))
				slaser = null
				to_chat(user, "<span class='notice'>You remove the [slaser] from \the [src].</span>")
				update_icon()
				return
	if(maintenance)
		/*if(istype(W, /obj/item/weapon/cell))
			if(bcell)
				to_chat(user, "<span class='notice'>\The [src] already has a cell.</span>")
			else
				if(!user.unEquip(W))
					return
				W.forceMove(src)
				bcell = W
				to_chat(user, "<span class='notice'>You install a cell in \the [src].</span>")
				update_icon()*/
		if(istype(W, /obj/item/weapon/stock_parts/scanning_module))
			if(smodule)
				to_chat(user, "<span class='notice'>\The [src] already has a scanning module.</span>")
			else
				if(!user.unEquip(W))
					return
				W.forceMove(src)
				smodule = W
				to_chat(user, "<span class='notice'>You install the [W] into \the [src].</span>")
				medigun.beam_range = 3+smodule.get_rating()
				update_icon()
		else if(istype(W, /obj/item/weapon/stock_parts/manipulator))
			if(smanipulator)
				to_chat(user, "<span class='notice'>\The [src] already has a manipulator.</span>")
			else
				if(!user.unEquip(W))
					return
				W.forceMove(src)
				smanipulator = W
				smaniptier = smanipulator.get_rating()
				if(sbin && scapacitor)START_PROCESSING(SSobj, src)
				to_chat(user, "<span class='notice'>You install the [W] into \the [src].</span>")

				update_icon()
		else if(istype(W, /obj/item/weapon/stock_parts/micro_laser))
			if(slaser)
				to_chat(user, "<span class='notice'>\The [src] already has a micro laser.</span>")
			else
				if(!user.unEquip(W))
					return
				W.forceMove(src)
				slaser = W
				to_chat(user, "<span class='notice'>You install the [W] into \the [src].</span>")

				update_icon()
		else if(istype(W, /obj/item/weapon/stock_parts/capacitor))
			if(scapacitor)
				to_chat(user, "<span class='notice'>\The [src] already has a capacitor.</span>")
			else
				if(!user.unEquip(W))
					return
				W.forceMove(src)
				scapacitor = W
				var/scaptier = scapacitor.get_rating()
				chargecost = 30-(5*scaptier)
				if(scaptier >= 5)
					tankmax = 150
				else
					tankmax = 30*scaptier
				if(brutecharge > tankmax)
					brutecharge = tankmax
				if(burncharge > tankmax)
					burncharge = tankmax
				if(toxcharge > tankmax)
					toxcharge = tankmax
				if(sbin && smanipulator)START_PROCESSING(SSobj, src)
				to_chat(user, "<span class='notice'>You install the [W] into \the [src].</span>")
				update_icon()
		else if(istype(W, /obj/item/weapon/stock_parts/matter_bin))
			if(sbin)
				to_chat(user, "<span class='notice'>\The [src] already has a matter bin.</span>")
			else
				if(!user.unEquip(W))
					return
				W.forceMove(src)
				sbin = W
				sbintier = sbin.get_rating()
				if(sbintier >= 5)
					chemcap = 300
				else
					chemcap = 60*(sbintier)
				if(brutecharge > chemcap)
					brutecharge = chemcap
				if(burncharge > chemcap)
					burncharge = chemcap
				if(toxcharge > chemcap)
					toxcharge = chemcap
				if(scapacitor && smanipulator)START_PROCESSING(SSobj, src)
				to_chat(user, "<span class='notice'>You install the [W] into \the [src].</span>")
				update_icon()

	else
		return ..()


/obj/item/device/bork_medigun/linked
	var/obj/item/device/medigun_backpack/medigun_base_unit

/obj/item/device/bork_medigun/linked/New(newloc, var/obj/item/device/medigun_backpack/backpack)
	medigun_base_unit = backpack
	if(medigun_base_unit.bpcmo)
		icon_state = "medblaster_cmo"
		base_icon_state = "medblaster_cmo"
		wielded_item_state = ""
		item_icons = list(
			slot_l_hand_str = 'icons/mob/items/lefthand_guns_rs.dmi',
			slot_r_hand_str = 'icons/mob/items/righthand_guns_rs.dmi',
			)
		update_icon()
	..(newloc)

/obj/item/device/bork_medigun/linked/Destroy()
	if(medigun_base_unit)
		//ensure the base unit's icon updates
		if(medigun_base_unit.medigun == src)
			medigun_base_unit.medigun = null
			if(medigun_base_unit.bpcmo)
				medigun_base_unit.icon_state = "mg-backpack_cmo"
				medigun_base_unit.item_state = "mg-backpack_cmo-onmob"
			else
				medigun_base_unit.icon_state = "mg-backpack"
				medigun_base_unit.item_state = "mg-backpack-onmob"
			medigun_base_unit.update_icon()
			usr.update_inv_back()
		medigun_base_unit = null
	return ..()


/obj/item/device/bork_medigun/linked/forceMove(atom/destination) //Forcemove override, ugh
	//to_chat(world, "<span class='warning'>forcemove</span>")
	//to_chat(world, "<span class='warning'>[destination]</span>")
	if(destination == medigun_base_unit || destination == medigun_base_unit.loc || isturf(destination))
		. = doMove(destination, 0, 0)
		if(isturf(destination))
			for(var/atom/A as anything in destination) // If we can't scan the turf, see if we can scan anything on it, to help with aiming.
				if(istype(A,/obj/structure/closet ))
					break
			//to_chat(world, "<span class='warning'>isturf</span>")
			if(ismob(medigun_base_unit.loc))
				var/mob/user = medigun_base_unit.loc
				//to_chat(world, "<span class='warning'>[user] eats ass</span>")
				medigun_base_unit.reattach_medigun(user)


/obj/item/device/bork_medigun/linked/dropped(mob/user)
	..() //update twohanding

	if(medigun_base_unit.containsgun == 0)
		//to_chat(user, "<span class='warning'>[loc]</span>")
		if(medigun_base_unit)

			//to_chat(user, "<span class='warning'>Dropped</span>")
			medigun_base_unit.reattach_medigun(user) //medigun attached to a base unit should never exist outside of their base unit or the mob equipping the base unit


/obj/item/device/medigun_backpack/verb/toggle_medigun()
	set name = "Toggle medigun"
	set category = "Object"
	var/mob/living/carbon/human/user = usr
	if(maintenance)
		to_chat(user, "<span class='warning'>Please close the maintenance hatch with a screwdriver first.</span>")
		return

	if(!medigun)
		to_chat(user, "<span class='warning'>The medigun is missing!</span>")
		return

	if(medigun.loc != src)
		//to_chat(user, "<span class='warning'>location not source</span>")
		reattach_medigun(user) //Remove from their hands and back onto the medigun unit
		return

	if(!slot_check())
		to_chat(user, "<span class='warning'>You need to equip [src] before taking out [medigun].</span>")
	else
		if(!usr.put_in_hands(medigun)) //Detach the medigun into the user's hands
			to_chat(user, "<span class='warning'>You need a free hand to hold the medigun!</span>")
		else
			containsgun = 0
			icon_state = "mg-backpack-deployed"
			item_state = "mg-backpack-deployed-onmob"
			//to_chat(user, "<span class='warning'>Deploy</span>")
			update_icon() //success
			if(!bpcmo)
				medigun.update_twohanding()
			usr.update_inv_back()



//checks that the base unit is in the correct slot to be used
/obj/item/device/medigun_backpack/proc/slot_check()
	var/mob/M = loc
	if(!istype(M))
		return 0 //not equipped

	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_back) == src)
		return 1
	if((slot_flags & SLOT_BELT) && M.get_equipped_item(slot_belt) == src)
		return 1
	//VOREStation Add Start - RIGSuit compatability
	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_s_store) == src)
		return 1
	if((slot_flags & SLOT_BELT) && M.get_equipped_item(slot_s_store) == src)
		return 1
	//VOREStation Add End

	return 0

/obj/item/device/medigun_backpack/dropped(mob/user)
	..()
	//to_chat(user, "<span class='warning'>Dropped backpack</span>")
	reattach_medigun(user) //medigun attached to a base unit should never exist outside of their base unit or the mob equipping the base unit

/obj/item/device/medigun_backpack/proc/reattach_medigun(mob/user)
	//to_chat(world, "<span class='warning'>Null</span>")
	//to_chat(user, "<span class='notice'>[user]</span>")
	//to_chat(user, "<span class='notice'>[medigun.loc]</span>")
	//to_chat(user, "<span class='notice'>[src]</span>")
	if(containsgun == 0)
		//to_chat(world, "<span class='warning'>doesnt contain gun</span>")
		containsgun = 1
		if(!medigun)
			//to_chat(world, "<span class='warning'>return</span>")
			return
		if(bpcmo)
			icon_state = "mg-backpack_cmo"
			item_state = "mg-backpack_cmo-onmob"
		else
			icon_state = "mg-backpack"
			item_state = "mg-backpack-onmob"
		//to_chat(user, "<span class='notice'>just before medigun busy</span>")
		if(medigun.busy)
			medigun.busy = 0
		update_icon()
		user.update_inv_back()
		//to_chat(user, "<span class='notice'>just before ismob</span>")
		if(ismob(medigun.loc))
			//to_chat(user, "<span class='notice'>ismob</span>")
			var/mob/M = medigun.loc
			if(M.drop_from_inventory(medigun, src))
				to_chat(user, "<span class='notice'>\The [medigun] snaps back into the main unit.</span>")
		else
			//to_chat(user, "<span class='notice'>!ismob</span>")
			medigun.forceMove(src)
			to_chat(user, "<span class='notice'>\The [medigun] snaps back into the main unit.</span>")


/obj/item/device/bork_medigun/linked/proc/check_charge(var/charge_amt)
	return 0

/obj/item/device/bork_medigun/linked/check_charge(var/charge_amt)
	return (medigun_base_unit.bcell && medigun_base_unit.bcell.check_charge(charge_amt))

/obj/item/device/bork_medigun/linked/proc/checked_use(var/charge_amt)
	return 0

/obj/item/device/bork_medigun/linked/checked_use(var/charge_amt)
	return (medigun_base_unit.bcell && medigun_base_unit.bcell.checked_use(charge_amt))

/obj/item/device/medigun_backpack/proc/checked_use(var/charge_amt)
	return 0

/obj/item/device/medigun_backpack/checked_use(var/charge_amt)
	return (bcell && bcell.checked_use(charge_amt))

/obj/item/device/bork_medigun/linked/attack_self(mob/living/user)
	if(!medigun_base_unit.bpcmo)update_twohanding()
	if(busy)
		busy = !busy


/obj/item/device/bork_medigun/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)// && loc != get_turf)
		return
	else
		return ..()


/obj/item/device/bork_medigun/linked/proc/should_stop(var/mob/living/target, var/mob/living/user, var/active_hand)
	if(!target ||  !user || !active_hand || !istype(target) || !istype(user) || !busy)
		return TRUE

	if((user.get_active_hand() != active_hand || wielded == 0) && medigun_base_unit.bpcmo == 0)
		to_chat(user, span("warning", "Please keep your hands free!"))
		return TRUE

	if(user.incapacitated(INCAPACITATION_DEFAULT))
		return TRUE

	if(target.isSynthetic())
		to_chat(user, span("warning", "Target is not organic."))
		return TRUE

	//if(get_dist(user, target) > beam_range)
	if(!(target in range(beam_range, user)) || (!(target in view(10, user)) && !(medigun_base_unit.smodule.get_rating() >= 5)))
		to_chat(user, span("warning", "You are too far away from \the [target] to heal them, Or they are not in view. Get closer."))
		return TRUE

	if(!isliving(target))
		//to_chat(user, span("warning", "\the [target] is not a valid target."))
		return TRUE

	if(!ishuman(target))
		return TRUE

	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.stat >= DEAD)
			to_chat(user, span("warning", "\the [target] is deceased!"))
			return TRUE

		/*if(!H.getBruteLoss() && !H.getFireLoss() && !H.getToxLoss())// && !H.getOxyLoss()) // No point Wasting fuel/power if target healed
			playsound(src, 'sound/machines/ping.ogg', 50)
			to_chat(user, span("warning", "\the [target] is fully healed."))
			return TRUE
		*/
	return FALSE

/obj/item/device/bork_medigun/linked/afterattack(atom/target, mob/user, proximity_flag)
	// Things that invalidate the scan immediately.
	if(isturf(target))
		for(var/atom/A as anything in target) // If we can't scan the turf, see if we can scan anything on it, to help with aiming.
			if(isliving(A))
				target = A
				break
	if(!medigun_base_unit.bpcmo)
		update_twohanding()
	if(busy && !(target == current_target) && isliving(target))
		to_chat(user, span("warning", "\The [src] is already targeting something."))
		return

	if(!isliving(target))
		//to_chat(user, span("warning", "\the [target] is not a valid target."))
		return

	//var/mob/living/L = target
	if(!medigun_base_unit.smanipulator)
		to_chat(user, "<span class='warning'>\The [src] Blinks a red error light, Manipulator missing.</span>")
		return
	if(!medigun_base_unit.scapacitor)
		to_chat(user, "<span class='warning'>\The [src] Blinks a blue error light, capacitor missing.</span>")
		return
	if(!medigun_base_unit.slaser)
		to_chat(user, "<span class='warning'>\The [src] Blinks an orange error light, laser missing.</span>")
		return
	if(!medigun_base_unit.smodule)
		to_chat(user, "<span class='warning'>\The [src] Blinks a pink error light, scanning module missing.</span>")
		return
	if(!checked_use(medigun_base_unit.chargecost))
		to_chat(user, "<span class='warning'>\The [src] doesn't have enough charge left to do that.</span>")
		return
	if(get_dist(target, user) > beam_range)
		to_chat(user, span("warning", "You are too far away from \the [target] to affect it. Get closer."))
		return

	if(target == current_target && busy)
		busy = FALSE
		return
	if(target == user)
		to_chat(user, span("warning", "Cant heal yourself."))
		return
	if(!(target in range(beam_range, user)) || (!(target in view(10, user)) && !medigun_base_unit.smodule))
		to_chat(user, span("warning", "You are too far away from \the [target] to heal them, Or they are not in view. Get closer."))
		return
	current_target = target
	busy = TRUE
	update_icon()
	var/datum/beam/scan_beam = user.Beam(target, icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', icon_state = "medbeam_basic", time = 6000)
	var/filter = filter(type = "outline", size = 1, color = "#037ffc")
	var/list/box_segments = list()
	var/active_hand = user.get_active_hand()
	playsound(src, 'sound/weapons/wave.ogg', 50)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		to_chat(user, span("notice", "Locking on to [H]"))
		to_chat(H, span("warning", "[user] is targetting you with their medigun"))
		if(user.client)
			box_segments = draw_box(target, beam_range, user.client)
			color_box(box_segments, "#037ffc", 5)
		var/ishealing = 0
		while(!should_stop(H, user, active_hand))
			//stoplag(15)
			if(do_after(user,10,ignore_movement = 1))
				var/washealing = ishealing // Did we heal last cycle
				ishealing = 0 // The default is 'we didn't heal this cycle'
				if(!checked_use(medigun_base_unit.chargecost))
					to_chat(user, "<span class='warning'>\The [src] doesn't have enough charge left to do that.</span>")
					break
				var/lastier = medigun_base_unit.slaser.get_rating()
				if(lastier >= 5)
					H.add_modifier(/datum/modifier/medbeameffect, 2 SECONDS)

				var/healmod = lastier
				if(H.getBruteLoss())
					healmod = round(min(lastier,medigun_base_unit.brutecharge,H.getBruteLoss()))
					if(medigun_base_unit.brutecharge >= healmod)
						H.adjustBruteLoss(-healmod)
						medigun_base_unit.brutecharge -= healmod
						ishealing = 1
				if(H.getFireLoss())
					healmod = round(min(lastier,medigun_base_unit.burncharge,H.getFireLoss()))
					if(medigun_base_unit.burncharge >= healmod)
						H.adjustFireLoss(-healmod)
						medigun_base_unit.burncharge -= healmod
						ishealing = 1
				if(H.getToxLoss())
					healmod = round(min(lastier,medigun_base_unit.toxcharge,H.getToxLoss()))
					if(medigun_base_unit.toxcharge >= healmod)
						H.adjustToxLoss(-healmod)
						medigun_base_unit.toxcharge -= healmod
						ishealing = 1
				var/treated = 0
				for(var/name in list(BP_HEAD, BP_L_HAND, BP_R_HAND, BP_L_ARM, BP_R_ARM, BP_L_FOOT, BP_R_FOOT, BP_L_LEG, BP_R_LEG, BP_GROIN, BP_TORSO))
					var/obj/item/organ/external/O = H.organs_by_name[name]
					for(var/datum/wound/W in O.wounds)
						if (W.internal)
							continue
						if (W.bandaged && W.disinfected)
							continue
						if (W.damage_type == BRUISE || W.damage_type == CUT || W.damage_type == PIERCE)
							if(medigun_base_unit.brutecharge >= 1)
								if(W.damage <= 1)
									O.wounds -= W
									medigun_base_unit.brutecharge -= 1
								else
									W.damage -= healmod
									medigun_base_unit.brutecharge -= healmod
								O.update_damages()
								treated = 1
						if (W.damage_type == BURN)
							if(medigun_base_unit.burncharge >= 1)
								if(W.damage <= 1)
									O.wounds -= W
									medigun_base_unit.burncharge -= 1
								treated = 1
						if(treated)
							break
				//if(medigun_base_unit.brutecharge <= 0 || medigun_base_unit.burncharge <= 0 || medigun_base_unit.toxcharge <= 0)
				medigun_base_unit.update_icon()
				//if(medigun_base_unit.slaser.get_rating() >= 5)

				if(ishealing != washealing) // Either we stopped or started healing this cycle
					if(ishealing)
						target.filters += filter
					else
						target.filters -= filter



	busy = FALSE
	current_target = null

	// Now clean up the effects.
	update_icon()
	QDEL_NULL(scan_beam)
	target.filters -= filter
	if(user.client) // If for some reason they logged out mid-scan the box will be gone anyways.
		delete_box(box_segments, user.client)





#define ICON_SIZE 32

// Draws a box showing the limits of movement while scanning something.
// Only the client supplied will see the box.
/obj/item/device/bork_medigun/proc/draw_box(atom/A, box_size, client/C)
	. = list()
	// Things moved with pixel_[x|y] will move the box, so this is to correct that.
	var/pixel_x_correction = -A.pixel_x
	var/pixel_y_correction = -A.pixel_y

	// First, place the bottom-left corner.
	. += draw_line(A, SOUTHWEST, (-box_size * ICON_SIZE) + pixel_x_correction, (-box_size * ICON_SIZE) + pixel_y_correction, C)

	// Make a line on the bottom, going right.
	for(var/i = 1 to (box_size * 2) - 1)
		var/x_displacement = (-box_size * ICON_SIZE) + (ICON_SIZE * i) + pixel_x_correction
		var/y_displacement = (-box_size * ICON_SIZE) + pixel_y_correction
		. += draw_line(A, SOUTH, x_displacement, y_displacement, C)

	// Bottom-right corner.
	. += draw_line(A, SOUTHEAST, (box_size * ICON_SIZE) + pixel_x_correction, (-box_size * ICON_SIZE) + pixel_y_correction, C)

	// Second line, for the right side going up.
	for(var/i = 1 to (box_size * 2) - 1)
		var/x_displacement = (box_size * ICON_SIZE) + pixel_x_correction
		var/y_displacement = (-box_size * ICON_SIZE) + (ICON_SIZE * i) + pixel_y_correction
		. += draw_line(A, EAST, x_displacement, y_displacement, C)

	// Top-right corner.
	. += draw_line(A, NORTHEAST, (box_size * ICON_SIZE) + pixel_x_correction, (box_size * ICON_SIZE) + pixel_y_correction, C)

	// Third line, for the top, going right.
	for(var/i = 1 to (box_size * 2) - 1)
		var/x_displacement = (-box_size * ICON_SIZE) + (ICON_SIZE * i) + pixel_x_correction
		var/y_displacement = (box_size * ICON_SIZE) + pixel_y_correction
		. += draw_line(A, NORTH, x_displacement, y_displacement, C)

	// Top-left corner.
	. += draw_line(A, NORTHWEST, (-box_size * ICON_SIZE) + pixel_x_correction, (box_size * ICON_SIZE) + pixel_y_correction, C)

	// Fourth and last line, for the left side going up.
	for(var/i = 1 to (box_size * 2) - 1)
		var/x_displacement = (-box_size * ICON_SIZE) + pixel_x_correction
		var/y_displacement = (-box_size * ICON_SIZE) + (ICON_SIZE * i) + pixel_y_correction
		. += draw_line(A, WEST, x_displacement, y_displacement, C)

#undef ICON_SIZE

// Draws an individual segment of the box.
/obj/item/device/bork_medigun/proc/draw_line(atom/A, line_dir, line_pixel_x, line_pixel_y, client/C)
	var/image/line = image(icon = 'icons/effects/effects.dmi', loc = A, icon_state = "stripes", dir = line_dir)
	line.pixel_x = line_pixel_x
	line.pixel_y = line_pixel_y
	line.plane = PLANE_FULLSCREEN // It's technically a HUD element but it doesn't need to show above item slots.
	line.appearance_flags = RESET_TRANSFORM|RESET_COLOR|RESET_ALPHA|NO_CLIENT_COLOR|TILE_BOUND
	line.alpha = 125
	C.images += line
	return line

// Removes the box that was generated before from the client.
/obj/item/device/bork_medigun/proc/delete_box(list/box_segments, client/C)
	for(var/i in box_segments)
		C.images -= i
		qdel(i)

/obj/item/device/bork_medigun/proc/color_box(list/box_segments, new_color, new_time)
	for(var/i in box_segments)
		animate(i, color = new_color, time = new_time)
