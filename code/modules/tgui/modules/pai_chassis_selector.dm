////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2025: New TGUI system for choosing your pAI chassis //
////////////////////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/pai_chassis_selector
	name = "Chassis Selection"
	tgui_id = "pAIChassisSelect"
	var/mob/living/silicon/pai/pai_host

/datum/tgui_module/pai_chassis_selector/New(var/host)
	. = ..()
	pai_host = host

/datum/tgui_module/pai_chassis_selector/tgui_status(mob/user, datum/tgui_state/state)
	if(!istype(pai_host))
		return STATUS_CLOSE
	return ..()

/datum/tgui_module/pai_chassis_selector/tgui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, tgui_id, name, parent_ui)
		ui.set_autoupdate(FALSE)
		ui.open()
	else
		ui.set_autoupdate(FALSE)

/datum/tgui_module/pai_chassis_selector/tgui_data(mob/user, datum/tgui/ui, datum/tgui_state/state)
	var/list/data = ..()

	if(!istype(pai_host))
		return data

	data["currentChassis"] = pai_host.get_current_chassis_name()
	data["currentChassisId"] = pai_host.chassis
	data["entries"] = pai_host.get_available_chassis_entries()

	return data

/datum/tgui_module/pai_chassis_selector/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(..())
		return TRUE

	if(!istype(pai_host))
		return TRUE

	switch(action)
		if("selectChassis")
			var/chassis_id = params["id"]
			var/finalize = text2num(params["finalize"])
			if(!istext(chassis_id) || !length(chassis_id))
				return TRUE
			if(!pai_host.apply_chassis_selection(chassis_id))
				to_chat(pai_host, "<span class='filter_warning'>Chassis selection failed.</span>")
				return TRUE
			if(finalize)
				SStgui.close_uis(src)
			else
				SStgui.update_uis(src)
			return TRUE

	return FALSE

/datum/tgui_module/pai_chassis_selector/Destroy()
	pai_host = null
	return ..()
