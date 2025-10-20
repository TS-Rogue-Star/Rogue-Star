///////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2025: New TGUI system for choosing your borg model //
///////////////////////////////////////////////////////////////////////////////////////////////

/datum/tgui_module/robot_module_selector
	name = "Module Selection"
	tgui_id = "CyborgModuleSelect"
	var/mob/living/silicon/robot/robot_host

/datum/tgui_module/robot_module_selector/New(var/host)
	. = ..()
	robot_host = host

/datum/tgui_module/robot_module_selector/tgui_status(mob/user, datum/tgui_state/state)
	if(!istype(robot_host))
		return STATUS_CLOSE
	return ..()

/datum/tgui_module/robot_module_selector/tgui_data(mob/user, datum/tgui/ui, datum/tgui_state/state)
	var/list/data = ..()

	if(!istype(robot_host))
		return data

	data["hasModule"] = !!robot_host.module
	data["currentModule"] = robot_host.modtype
	data["isShell"] = !!robot_host.shell
	data["modules"] = robot_host.get_available_module_entries()
	data["sprites"] = robot_host.get_available_sprite_entries()
	var/icon_tries = robot_host.icon_selection_tries
	if(isnull(icon_tries) || icon_tries < 0)
		icon_tries = 0
	data["iconSelected"] = !!robot_host.icon_selected
	data["iconSelectionTries"] = icon_tries
	data["currentSprite"] = robot_host.get_current_sprite_name()
	data["iconLocked"] = (!!robot_host.icon_selected && icon_tries <= 0)
	data["isTransforming"] = !!robot_host.notransform

	return data

/datum/tgui_module/robot_module_selector/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(..())
		return TRUE

	if(!istype(robot_host))
		return TRUE

	switch(action)
		if("selectModule")
			var/module_name = params["id"]
			if(!istext(module_name))
				return TRUE
			if(robot_host.module && robot_host.modtype == module_name)
				SStgui.update_uis(src)
				return TRUE
			if(robot_host.apply_module_selection(module_name))
				return TRUE
			to_chat(robot_host, "<span class='filter_warning'>Module selection failed.</span>")
			return TRUE
		if("selectSprite")
			var/sprite_id = params["id"]
			var/finalize = text2num(params["finalize"])
			if(!istext(sprite_id))
				return TRUE
			if(robot_host.notransform)
				to_chat(robot_host, "<span class='warning filter_warning'>Your chassis is still transforming. Please wait before choosing another icon.</span>")
				return TRUE
			if(finalize)
				var/datum/robot_sprite/selection = locate(sprite_id)
				if(!istype(selection))
					to_chat(robot_host, "<span class='filter_warning'>Icon selection failed.</span>")
					return TRUE

				if(robot_host.sprite_datum != selection)
					if(!robot_host.apply_sprite_selection(selection, FALSE, FALSE))
						to_chat(robot_host, "<span class='filter_warning'>Icon selection failed.</span>")
						return TRUE

				robot_host.icon_selection_tries = 0
				robot_host.icon_selected = TRUE
				var/datum/robot_sprite/current_sprite = robot_host.sprite_datum
				if(current_sprite && !istype(robot_host, /mob/living/silicon/robot/drone))
					robot_host.sprite_type = current_sprite.name
				if(robot_host.hands)
					robot_host.update_hud()
				to_chat(robot_host, "<span class='filter_notice'>Your icon has been set. You now require a module reset to change it.</span>")
				SStgui.close_uis(src)
				return TRUE
			if(robot_host.apply_sprite_selection_by_ref(sprite_id, TRUE, FALSE, FALSE))
				SStgui.update_uis(src)
			return TRUE

	return FALSE

/datum/tgui_module/robot_module_selector/tgui_close(mob/user)
	var/should_reopen = FALSE
	if(robot_host && robot_host.module && !robot_host.icon_selected)
		should_reopen = TRUE
		to_chat(robot_host, "<span class='warning filter_warning'>You closed the module selector before finalizing your icon. Click a sprite twice to lock it in.</span>")
	var/result = ..()
	if(should_reopen && robot_host && robot_host.client)
		addtimer(CALLBACK(src, PROC_REF(reopen_after_close)), 0)
	return result

/datum/tgui_module/robot_module_selector/proc/reopen_after_close()
	if(!robot_host || !robot_host.client)
		return
	if(istype(robot_host) && robot_host.notransform)
		addtimer(CALLBACK(src, PROC_REF(reopen_after_close)), 10)
		return
	tgui_interact(robot_host)

/datum/tgui_module/robot_module_selector/Destroy()
	robot_host = null
	return ..()
