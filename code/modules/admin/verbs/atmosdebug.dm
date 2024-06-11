/client/proc/atmosscan()
	set category = "Mapping"
	set name = "Check Piping"
	set background = 1
	if(!src.holder)
		return

	feedback_add_details("admin_verb","CP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

	if(tgui_alert(usr, "WARNING: This command should not be run on a live server. Do you want to continue?", "Check Piping", list("No", "Yes")) == "No")
		return

	to_chat(usr, "Checking for disconnected pipes...")
	//all plumbing - yes, some things might get stated twice, doesn't matter.
	for (var/obj/machinery/atmospherics/plumbing in machines)
		if (plumbing.nodealert)
			to_chat(usr, "<span class='filter_adminlog warning'>Unconnected [plumbing.name] located at [COORD(plumbing)], [get_area(plumbing.loc)] [ADMIN_COORDJMP(plumbing)]</span>")

	//Manifolds
	for (var/obj/machinery/atmospherics/pipe/manifold/pipe in machines)
		if (!pipe.node1 || !pipe.node2 || !pipe.node3)
			to_chat(usr, "<span class='filter_adminlog warning'>Unconnected [pipe.name] located at [COORD(pipe)], [get_area(pipe.loc)] [ADMIN_COORDJMP(pipe)]</span>")

	//Pipes
	for (var/obj/machinery/atmospherics/pipe/simple/pipe in machines)
		if (!pipe.node1 || !pipe.node2)
			to_chat(usr, "<span class='filter_adminlog warning'>Unconnected [pipe.name] located at [COORD(pipe)], [get_area(pipe.loc)] [ADMIN_COORDJMP(pipe)]</span>")

	to_chat(usr, "Checking for overlapping pipes...")
	next_turf:
		for(var/turf/T in world)
			for(var/dir in cardinal)
				var/list/connect_types = list(1 = 0, 2 = 0, 3 = 0)
				for(var/obj/machinery/atmospherics/pipe in T)
					if(dir & pipe.initialize_directions)
						for(var/connect_type in pipe.connect_types)
							connect_types[connect_type] += 1
						if(connect_types[1] > 1 || connect_types[2] > 1 || connect_types[3] > 1)
							to_chat(usr, "<span class='filter_adminlog warning'>Overlapping pipe ([pipe.name]) located at [COORD(T)], [get_area(T.loc)] [ADMIN_COORDJMP(T)]</span>")
							continue next_turf
	to_chat(usr, "Done")

/client/proc/powerdebug()
	set category = "Mapping"
	set name = "Check Power"
	if(!src.holder)
		return

	feedback_add_details("admin_verb","CPOW") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	var/list/results = list()

	for (var/datum/powernet/PN in powernets)
		if(!length(PN.nodes))
			if(PN.cables && (PN.cables.len > 1))
				var/obj/structure/cable/C = PN.cables[1]
				results += "Powernet with no nodes! Example cable at [COORD(C)], [get_area(C.loc)] [ADMIN_COORDJMP(C)]"

		if (!PN.cables || (PN.cables.len < 5))
			if(PN.cables && (PN.cables.len >= 1))
				var/obj/structure/cable/C = PN.cables[1]
				results += "Powernet with fewer than 5 cables! Example cable at [COORD(C)], [get_area(C.loc)][ADMIN_COORDJMP(C)]"

	for(var/turf/T in world.contents)
		var/cable_layers //cache all cable layers (which are bitflags) present
		for(var/obj/structure/cable/C in T.contents)
			if(cable_layers & C.cable_layer)
				results += "Doubled wire at [COORD(C)], [get_area(C.loc)] [ADMIN_COORDJMP(C)]"
			else
				cable_layers |= C.cable_layer
		var/obj/machinery/power/terminal/term = locate(/obj/machinery/power/terminal) in T.contents
		if(term)
			var/obj/structure/cable/C = locate(/obj/structure/cable) in T.contents
			if(!C)
				results += "Unwired terminal at [COORD(term)], [get_area(term.loc)] [ADMIN_COORDJMP(term)]"

	for(var/obj/machinery/power/apc/power in GLOB.apcs)
		if(!power.terminal)
			results += "APC with no terminals! at [COORD(power)], [get_area(power.loc)][ADMIN_COORDJMP(power)]"

	for(var/obj/machinery/power/smes/power in GLOB.smeses)
		if(!power.terminalconnections)
			results += "SMES with no terminals! at [COORD(power)], [get_area(power.loc)][ADMIN_COORDJMP(power)]"
	to_chat(usr, "[results.Join("\n")]")
