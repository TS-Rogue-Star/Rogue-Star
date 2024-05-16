
/proc/power_failure(var/announce = TRUE)
	var/list/skipped_areas = list(/area/ai)

	for(var/obj/machinery/power/smes/S in machines)
		var/area/current_area = get_area(S)
		if(current_area.type in skipped_areas || !(S.z in using_map.station_levels))
			continue
		S.charge = 0
		S.output_level = 0
		S.outputting = FALSE
		S.update_icon()
		S.power_change()

	for(var/obj/machinery/power/apc/C in machines)
		if(!C.is_critical && C.cell && (C.z in using_map.station_levels))
			C.cell.charge = 0

//	playsound_z(3, 'sound/effects/powerloss.ogg')

	sleep(100)
	if(announce)
		command_announcement.Announce("Abnormal activity detected in [station_name()]'s power system. As a precaution, power must be shut down for an indefinite duration.", "Critical Power Failure", new_sound = 'sound/AI/poweroff.ogg')

/proc/power_restore(var/announce = TRUE)
	var/list/skipped_areas = list(/area/ai)

	for(var/obj/machinery/power/smes/S in machines)
		var/area/current_area = get_area(S)
		if(current_area.type in skipped_areas || isNotStationLevel(S.z))
			continue
		S.charge = S.capacity
		S.output_level = S.output_level_max
		S.outputting = TRUE
		S.update_icon()
		S.power_change()

	for(var/obj/machinery/power/apc/C in machines)
		if(!C.is_critical && C.cell && (C.z in using_map.station_levels))
			C.cell.charge = C.cell.maxcharge

	sleep(100)
	if(announce)
		command_announcement.Announce("Power has been restored. Reason: Unknown.", "Power Systems Nominal", new_sound = 'sound/AI/poweron.ogg')

/proc/power_restore_quick(var/announce = TRUE)

	for(var/obj/machinery/power/smes/S in machines)
		if(!S.is_critical && (S.z in using_map.station_levels))
			continue
		S.charge = S.capacity
		S.output_level = S.output_level_max
		S.output_attempt = TRUE
		S.input_attempt = TRUE
		S.update_icon()
		S.power_change()

	sleep(100)
	if(announce)
		command_announcement.Announce("Power has been restored. Reason: Unknown.", "Power Systems Nominal", new_sound = 'sound/AI/poweron.ogg')

/proc/power_restore_everything(var/announce = TRUE)

	for(var/obj/machinery/power/smes/S in machines)
		S.charge = S.capacity
		S.output_level = S.output_level_max
		S.outputting = TRUE
		S.update_icon()
		S.power_change()

	for(var/obj/machinery/power/apc/C in machines)
		if(C.cell)
			C.cell.charge = C.cell.maxcharge

	sleep(100)
	if(announce)
		command_announcement.Announce("Power has been restored. Reason: Unknown.", "Power Systems Nominal", new_sound = 'sound/AI/poweron.ogg')
