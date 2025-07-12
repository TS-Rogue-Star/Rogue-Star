/obj/item/device/medigun_backpack/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Medigun", name)
		ui.open()

/obj/item/device/medigun_backpack/tgui_data(mob/user)
	var/mob/living/carbon/human/H = medigun.current_target
	var/patientname
	var/patienthealth = 0
	var/patientbruteloss = 0
	var/patientfireloss = 0
	var/patienttoxloss = 0
	var/patientoxyloss = 0

	//var/minhealth = 0
	if(scapacitor?.get_rating() < 5)
		gridstatus = 3
	if(H)
		patientname = H
		patienthealth = max(0, (H.health+abs(config.health_threshold_dead))/(H.maxHealth+abs(config.health_threshold_dead)))
		patientbruteloss = H.getBruteLoss()
		patientfireloss = H.getFireLoss()
		patienttoxloss = H.getToxLoss()
		patientoxyloss = H.getOxyLoss()
	var/list/data = list(
		"maintenance" = maintenance,
		"Generator" = charging,
		"tankmax" = tankmax,
		"powerCellStatus" = bcell ? bcell.percent() : null,
		"Gridstatus" = gridstatus,
		"PhoronStatus" = sbin ? phoronvol/chemcap : null,
		"BrutehealCharge" = scapacitor ? brutecharge : null,
		"BrutehealVol" = sbin ? brutevol : null,
		"BurnhealCharge" = scapacitor ? burncharge : null,
		"BurnhealVol" = sbin ? burnvol : null,
		"ToxhealCharge" = scapacitor ? toxcharge : null,
		"ToxhealVol" = sbin ? toxvol : null,
		"patientname" = smodule ? patientname : null,
		"patienthealth" = smodule ? patienthealth : null,
		"patientbrute" = smodule ? patientbruteloss : null,
		"patientburn" = smodule ? patientfireloss : null,
		"patienttox" = smodule ? patienttoxloss : null,
		"patientoxy" = smodule ? patientoxyloss : null,
		"examine_data" = get_examine_data()
		)
	return data

/obj/item/device/medigun_backpack/proc/get_examine_data()
	return list(
		"smodule" = smodule ? list("name" = smodule.name, "range" = medigun.beam_range, "rating" = smodule.get_rating()) : null,
		"smanipulator" = smanipulator ? list("name" = smanipulator.name, "rating" = smaniptier) : null,
		"slaser" = slaser ? list("name" = slaser.name, "rating" = slaser.get_rating()) : null,
		"scapacitor" = scapacitor ? list("name" = scapacitor.name, "chargecost" = chargecost, "tankmax" = tankmax, "rating" = scapacitor.get_rating()) : null,
		"sbin" = sbin ? list("name" = sbin.name, "chemcap" = chemcap, "rating" = sbin.get_rating()) : null
	)

/obj/item/device/medigun_backpack/tgui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE

	. = TRUE
	switch(action)
		if("gentoggle")
			ui_action_click()
			return TRUE

		if("cancel_healing")
			if(medigun)
				medigun.busy = FALSE
				return TRUE

		if("rem_smodule")
			if(!smodule || !maintenance)
				return FALSE
			smodule.forceMove(get_turf(loc))
			smodule = null
			to_chat(ui.user, span_notice("You remove the [smodule] from \the [src]."))
			update_icon()
			return TRUE

		if("rem_mani")
			if(!smanipulator || !maintenance)
				return FALSE
			STOP_PROCESSING(SSobj, src)
			smanipulator.forceMove(get_turf(loc))
			smanipulator = null
			smaniptier = 0
			to_chat(ui.user, span_notice("You remove the [smanipulator] from \the [src]."))
			update_icon()
			return TRUE

		if("rem_laser")
			if(!slaser || !maintenance)
				return FALSE
			slaser.forceMove(get_turf(loc))
			slaser = null
			to_chat(ui.user, span_notice("You remove the [slaser] from \the [src]."))
			update_icon()
			return TRUE

		if("rem_cap")
			if(!scapacitor || !maintenance)
				return FALSE
			STOP_PROCESSING(SSobj, src)
			scapacitor.forceMove(get_turf(loc))
			scapacitor = null
			to_chat(ui.user, span_notice("You remove the [scapacitor] from \the [src]."))
			update_icon()
			return TRUE

		if("rem_bin")
			if(!sbin || !maintenance)
				return FALSE
			STOP_PROCESSING(SSobj, src)
			sbin.forceMove(get_turf(loc))
			sbin = null
			sbintier = 0
			to_chat(ui.user, span_notice("You remove the [sbin] from \the [src]."))
			update_icon()
			return TRUE

/obj/item/device/medigun_backpack/ShiftClick(mob/user)
	. = ..()
	if(!medigun)
		return
	tgui_interact(user)
