/datum/tgui_module/adv_teleport
	name = "Adv Teleport Control"
	tgui_id = "AdvTeleporter"

/datum/tgui_module/adv_teleport/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/nanomaps),
	)

/datum/tgui_module/adv_teleport/tgui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE
		
	if(action && !issilicon(usr))
		playsound(tgui_host(), "terminal_type", 50, 1)

	switch(action)
		if("mapClick")
			var/scalarX = params["byondX"]
			var/scalarY = params["byondY"]
			world.log << "ScalarX: [scalarX]"
			world.log << "ScalarY: [scalarY]"
			var/coordX = round(scalarX*world.maxx)+1
			var/coordY = round(scalarY*world.maxy)+1
			var/coordZ = ui.map_z_level
			var/turf/T = locate(coordX,coordY,coordZ)
			world.log << "Turf: [T] at assummed [coordX],[coordY],[coordZ]"

		if("setZLevel")
			ui.set_map_z_level(params["mapZLevel"])
			return TRUE

/datum/tgui_module/adv_teleport/tgui_interact(mob/user, datum/tgui/ui = null)
	var/z = get_z(user)
	var/list/map_levels = using_map.get_map_levels(z, TRUE, om_range = DEFAULT_OVERMAP_RANGE)
	
	if(!map_levels.len)
		to_chat(user, "<span class='warning'>The advanced teleporter doesn't seem like it'll work here.</span>")
		if(ui)
			ui.close()
		return null

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, tgui_id, name)
		ui.autoupdate = TRUE
		ui.open()


/datum/tgui_module/adv_teleport/tgui_data(mob/user)
	var/data[0]

	data["isAI"] = isAI(user)

	var/z = get_z(user)
	var/list/map_levels = uniquelist(using_map.get_map_levels(z, TRUE, om_range = DEFAULT_OVERMAP_RANGE))
	data["map_levels"] = map_levels

	return data
