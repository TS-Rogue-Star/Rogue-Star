// the SMES
// stores power

/obj/machinery/power/smes
	name = "power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit."
	icon_state = "smes"
	icon = 'icons/obj/power_vr.dmi'
	density = TRUE
	anchored = TRUE
	unacidable = TRUE
	use_power = USE_POWER_OFF
	var/capacity = 5 MEGAWATTS		//Maximum amount of power it can hold
	var/charge = 1 MEGAWATTS		//Current amount of power it holds

	var/input_attempt = FALSE //attempting to charge ?
	var/inputting = 0
	var/input_level = SMESSTARTCHARGELVL //amount of power the SMES attempts to charge by, 50kW
	var/input_level_max = SMESMAXCHARGELEVEL //cap on input level 250kW
	var/input_available = 0 //amount of charge available from input last tick

	var/output_attempt = TRUE //attempting to output ?
	var/outputting = 0
	var/output_level = SMESSTARTOUTLVL //amount of power the SMES attempts to output, 50kW
	var/output_level_max = SMESMAXOUTPUT // cap on output level 250kW
	var/output_used = 0 //amount of power actually outputted. may be less than output_level if the powernet returns excess power

	//Baycode snowflake
	//Holders for powerout event.
	var/last_output_attempt	= 0
	var/last_input_attempt	= 0
	var/last_charge			= 0

	//For icon overlay updates
	var/last_disp
	var/last_chrg
	var/last_onln

	var/damage = 0
	var/maxdamage = SMESHEALTHPOOL // Relatively resilient, given how expensive it is, but once destroyed produces small explosion.

	var/input_cut = FALSE
	var/input_pulsed = FALSE
	var/output_cut = FALSE
	var/output_pulsed = FALSE
	var/target_load = 0

	var/name_tag
	var/should_be_mapped = TRUE // If this is set to FALSE it will send out warning on New()
	var/grid_check = FALSE // If true, suspends all I/O.
	var/is_critical = FALSE

	//Multi-terminal support
	var/building_terminal = FALSE //Potential duplicate mitigator.
	var/obj/machinery/power/terminal/terminal1
	var/obj/machinery/power/terminal/terminal2
	var/obj/machinery/power/terminal/terminal3	//max of three extras 'cuz this is very silly.
	var/list/terminalconnections = list()
		//Three layers of cables = one terminal per layer, but each direction is on a different layer to make powernets less shit. Shouldn't be stackable.
	//Buildable Vars
	var/max_coils = SMESMAXCOIL			//30M capacity, 1.5MW input/output when fully upgraded /w default coils
	var/cur_coils = SMESDEFAULTSTART	// Current amount of installed coils
	var/safeties_enabled = TRUE			// If 0 modifications can be done without discharging the SMES, at risk of critical failure.
	var/failing = FALSE					// If 1 critical failure has occured and SMES explosion is imminent.
	var/datum/wires/smes/wires
	circuit = /obj/item/weapon/circuitboard/smes
	clicksound = "switch"
	var/grounding = TRUE				// Cut to quickly discharge, at cost of "minor" electrical issues in output powernet.
	var/RCon = TRUE						// Cut to disable AI and remote control.
	var/RCon_tag = "NO_TAG"				// RCON tag, change to show it on SMES Remote control console.

/obj/machinery/power/smes/examine(user)
	..()
	var/list/msg
	if(panel_open)
		msg += "<span class='notice'>The maintenance hatch is open.</span>"
	if(!terminalconnections.len)
		msg += "<span class='warning'>This SMES has no power terminals!</span>"
	for(var/obj/machinery/power/terminal/connected in terminalconnections)
		if(connected == terminal1)
			msg += "<span class='notice'>Terminal 1 is connected.</span>"
		else if(connected == terminal2)
			msg += "<span class='notice'>Terminal 2 is connected.</span>"
		else if(connected == terminal3)
			msg += "<span class='notice'>Terminal 3 is connected.</span>"
	to_chat(user, msg)

/obj/machinery/power/smes/Initialize(mapload)
	. = ..()
	GLOB.smeses += src
	add_nearby_terminals()
	if(!(terminalconnections.len)) //nothing connected, probably a map error!
		stat |= BROKEN
		return
	if(!powernet)
		connect_to_network()
	if(!should_be_mapped)
		var/turf/turf = get_turf(src)
		warning("Non-buildable or Non-magical SMES at [COORD(turf)]")
		return

	wires = new /datum/wires/smes(src)

	component_parts = list()
	component_parts += new /obj/item/stack/cable_coil(src,30)
	component_parts += new /obj/item/weapon/circuitboard/smes(src)

	// Allows for mapped-in SMESs with larger capacity/IO
	for(var/i = 1, i <= cur_coils, i++)
		component_parts += new /obj/item/weapon/smes_coil(src)

	recalc_coils()
	update_icon()

/obj/machinery/power/smes/Destroy()
	if(SSticker.IsRoundInProgress())
		var/turf/turf = get_turf(src)
		message_admins("[src] deleted at [ADMIN_COORDJMP(src)]")
		log_game("[src] deleted at [COORD(turf)]")
		investigate_log("deleted at [COORD(turf)]")
	if(terminal1)
		disconnect_terminal(terminal1)
	if(terminal2)
		disconnect_terminal(terminal2)
	if(terminal3)
		disconnect_terminal(terminal3)

	qdel(wires)
	wires = null
	for(var/datum/tgui_module/rcon/R in world)
		R.FindDevices()
	GLOB.smeses -= src
	return ..()

///let's ensure we also scoop up our pre-mapped friends.
/obj/machinery/power/smes/proc/add_nearby_terminals()
	for(var/d in GLOB.cardinal)
		var/turf/T = get_step(src, d)
		for(var/obj/machinery/power/terminal/term in T)
			if(term && term.dir == turn(d, 180) && !term.master && term.cable_layer)
				if(term.cable_layer == CABLE_LAYER_1)
					terminal1 = term
				else if(term.cable_layer == CABLE_LAYER_2)
					terminal2 = term
				else if(term.cable_layer == CABLE_LAYER_3 || term.cable_layer == CABLE_LAYER_4)
					terminal3 = term
				terminalconnections |= term
				term.master = src
				term.connect_to_network()

/obj/machinery/power/smes/proc/check_terminals()
	if(!terminalconnections.len)
		return FALSE
	return TRUE

/obj/machinery/power/smes/add_avail(var/amount)
	if(..(amount))
		powernet.newavail += amount
		return TRUE
	return 0

/obj/machinery/power/smes/update_icon()
	cut_overlays()
	icon_state = "[initial(icon_state)]"
	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]-off"
		return

	if(failing)
		add_overlay("[initial(icon_state)]-crit")
		return

	if(panel_open)
		icon_state = "[initial(icon_state)]-o"
		return	//It's off, so don't draw any icons

	add_overlay("[initial(icon_state)]-op[outputting]")

	if(inputting == 2)
		add_overlay("[initial(icon_state)]-oc2")
	else if (inputting == 1)
		add_overlay("[initial(icon_state)]-oc1")
	else
		if(input_attempt)
			add_overlay("[initial(icon_state)]-oc0")

	var/clevel = chargedisplay()
	if(clevel>0)
		add_overlay("[initial(icon_state)]-og[clevel]")
	return

/obj/machinery/power/smes/RefreshParts()
	recalc_coils()

/// Updates properties (IO, capacity, etc.) of this SMES by checking internal components.
/obj/machinery/power/smes/proc/recalc_coils()
	if ((cur_coils <= max_coils) && (cur_coils >= 1))
		capacity = 0
		input_level_max = 0
		output_level_max = 0
		for(var/obj/item/weapon/smes_coil/C in component_parts)
			capacity += C.ChargeCapacity
			input_level_max += C.IOCapacity
			output_level_max += C.IOCapacity
		charge = between(0, charge, capacity)
		return TRUE
	return FALSE

/obj/machinery/power/smes/proc/Percentage()
	if(!capacity)
		return 0
	return round(100.0*charge/capacity, 0.1)

/obj/machinery/power/smes/proc/chargedisplay()
	return round(5.5*charge/(capacity ? capacity : 5e6))

/obj/machinery/power/smes/proc/input_power(var/percentage, var/obj/machinery/power/terminal/term)
	var/to_input = target_load * (percentage/100)
	to_input = between(0, to_input, target_load)
	if(percentage == 100)
		inputting = 2
	else if(percentage)
		inputting = 1
	// else inputting = 0, as set in process()

	var/inputted = term.powernet.draw_power(min(to_input, input_level - input_available))
	add_charge(inputted)
	input_available += inputted

// Mostly in place due to child types that may store power in other way (PSUs)
/obj/machinery/power/smes/proc/add_charge(var/amount)
	charge += amount*SMESRATE

/obj/machinery/power/smes/proc/remove_charge(var/amount)
	charge -= amount*SMESRATE

/obj/machinery/power/smes/process()
	if(stat & BROKEN)
		return

	// This causes the SMES to quickly discharge if we aren't grounded, and has small chance of breaking lights connected to APCs in the powernet.
	if(!grounding && (Percentage() > 5))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
		charge -= (output_level_max * SMESRATE)
		if(prob(1)) // Small chance of overload occuring since grounding is disabled.
			apcs_overload(0,10)

	//store machine state to see if we need to update the icon overlays
	var/last_disp = chargedisplay()
	var/last_chrg = inputting
	var/last_onln = outputting

	// only update icon if state changed
	if(last_disp != chargedisplay() || last_chrg != inputting || last_onln != outputting)
		update_icon()

	//inputting
	if(terminalconnections && input_attempt && (!input_pulsed && !input_cut) && !grid_check)
		for(var/obj/machinery/power/terminal/connected in terminalconnections)
			var/input_available = FALSE
			target_load = CLAMP((capacity-charge)/SMESRATE, 0, input_level)	// Amount we will request from the powernet.
			if(!connected.powernet)
				continue
			input_available = TRUE
			connected.powernet.load += target_load
			if(!input_available)
				target_load = 0 // We won't input any power without powernet connection.
			inputting = FALSE

	output_used = 0
	//outputting
	if(output_attempt && (!output_pulsed && !output_cut) && powernet && charge && !grid_check)
		output_used = min( charge/SMESRATE, output_level)		//limit output to that stored
		remove_charge(output_used)			// reduce the storage (may be recovered in /restore() if excessive)
		add_avail(output_used)				// add output to powernet (smes side)
		outputting = 2
	else if(!powernet || !charge)
		outputting = 1
	else
		output_used = 0

// called after all power processes are finished
// restores charge level to smes if there was excess this ptick
/obj/machinery/power/smes/proc/restore(var/percent_load)
	if(stat & BROKEN)
		return

	if(!outputting)
		output_used = 0
		return

	var/total_restore = output_used * (percent_load / 100) // First calculate amount of power used from our output
	total_restore = between(0, total_restore, output_used) // Now clamp the value between 0 and actual output, just for clarity.
	total_restore = output_used - total_restore			   // And, at last, subtract used power from outputted power, to get amount of power we will give back to the SMES.

	// now recharge this amount
	var/clev = chargedisplay()

	add_charge(total_restore)				// restore unused power
	powernet.netexcess -= total_restore		// remove the excess from the powernet, so later SMESes don't try to use it

	output_used -= total_restore

	if(clev != chargedisplay() ) //if needed updates the icons overlay
		update_icon()
	return

// create a terminal object pointing towards the SMES
// wires will attach to this
// We've done our sanity checks in the attackby, and nothing else should call it.
/obj/machinery/power/smes/proc/make_terminal(mob/user, turf/turf, terminal_cable_layer = cable_layer)
	to_chat(user, "<span class='filter_notice'><span class='notice'>You start adding cable to the [src].</span></span>")
	if(terminal_cable_layer)
		if(terminal_cable_layer == CABLE_LAYER_1)
			terminal1 = new/obj/machinery/power/terminal/layer1(turf)
			terminal1.set_dir(get_dir(turf,src))
			terminal1.master = src
			terminalconnections += terminal1
		else if(terminal_cable_layer == CABLE_LAYER_2)
			terminal2 = new/obj/machinery/power/terminal(turf)
			terminal2.set_dir(get_dir(turf,src))
			terminal2.master = src
			terminalconnections += terminal2
		else if(terminal_cable_layer == CABLE_LAYER_3 || terminal_cable_layer == CABLE_LAYER_4 )
			terminal3 = new/obj/machinery/power/terminal/layer3(turf)
			terminal3.set_dir(get_dir(turf,src))
			terminal3.master = src
			terminalconnections += terminal3
		if(stat && BROKEN)
			stat &= ~BROKEN
		visible_message(\
			"[user.name] has built a power terminal.",\
			"<span class='notice'>You build the power terminal.</span>")
		return TRUE
	else if(!terminalconnections.len) //no more terminals? Broken machine, clearly.
		stat |= BROKEN
		return FALSE

/obj/machinery/power/smes/proc/get_terminal_slot(terminalslot)
	if(terminalslot == CABLE_LAYER_1)
		return terminal1
	else if(terminalslot == CABLE_LAYER_2)
		return terminal2
	else if(terminalslot == CABLE_LAYER_3 || terminalslot == CABLE_LAYER_3)
		return terminal3

/obj/machinery/power/smes/disconnect_terminal(terminalslot)
	var/terminalplace = get_terminal_slot(terminalslot) //which terminal are we disconnecting?
	if(terminalplace)
		terminalconnections -= terminalplace
		terminalplace = null
	if(!terminalconnections.len) //no more terminals? Broken machine, clearly.
		stat |= BROKEN

/obj/machinery/power/smes/draw_power(var/amount)
	var/drained = 0
	if(terminalconnections)
		for(var/obj/machinery/power/terminal/connected in terminalconnections)
			if(connected)
				if(!connected.powernet)
					continue
				if((amount - drained) <= 0)
					return 0
				drained += connected.draw_power(amount)
	return drained

/obj/machinery/power/smes/should_have_node()
	return TRUE

///AI requires the RCON wire to be intact to operate the SMES.
/obj/machinery/power/smes/attack_ai(mob/user)
	add_fingerprint(user)
	if(RCon)
		tgui_interact(user)
	else // RCON wire cut
		to_chat(usr, "<span class='warning'>Connection error: Destination Unreachable.</span>")

	// Cyborgs standing next to the SMES can play with the wiring.
	if(isrobot(usr) && Adjacent(usr) && panel_open)
		wires.Interact(usr)

/obj/machinery/power/smes/attack_hand(mob/user)
	add_fingerprint(user)
	if(panel_open)
		wires.Interact(usr)
	else
		tgui_interact(user)


/obj/machinery/power/smes/attackby(var/obj/item/weapon/W, var/mob/user)
	if (failing)	//TODO: Allow engineering to fix failing SMES units. Maybe with a Tesla grounding rod and a stick? because fuck you for hardcoding this
		to_chat(user, "<span class='warning'>The [src]'s indicator lights are flashing wildly. It seems to be overloaded! Touching it now is probably not a good idea.</span>")
		return
	//opening using screwdriver
	if(default_deconstruction_screwdriver(user, W))
		update_icon()
		return

	if(W.has_tool_quality(TOOL_MULTITOOL))
		var/newtag = tgui_input_text(user, "Enter new RCON tag. Use \"NO_TAG\" to disable RCON or leave empty to cancel.", "SMES RCON system", "", MAX_NAME_LEN)
		newtag = sanitize(newtag,MAX_NAME_LEN)
		if(newtag)
			RCon_tag = newtag
			to_chat(user, "<span class='notice'>You changed the RCON tag to: [newtag]</span>")
			return
		// Charged above 1% and safeties are enabled.
		if((charge > (capacity/100)) && safeties_enabled)
			to_chat(user, "<span class='warning'>The safety circuit of [src] is preventing modifications while there is charge stored!</span>")
			return

		if (output_attempt || input_attempt)
			to_chat(user, "<span class='warning'>Turn off the [src] first!</span>")
			return

	// Probability of failure if safety circuit is disabled (in %)
	var/failure_probability = round((charge / capacity) * 100)

	// If failure probability is below 5% it's usually safe to do modifications
	if (failure_probability < 5)
		failure_probability = 0

	if(W.has_tool_quality(TOOL_CROWBAR))
		if (terminalconnections.len)
			to_chat(user, "<span class='warning'>You have to disassemble the connections first!</span>")
			return

		playsound(src, W.usesound, 50, 1)
		to_chat(user, "<span class='warning'>You begin to disassemble the [src]!</span>")
		if (do_after(usr, (100 * cur_coils) * W.toolspeed)) // More coils = takes longer to disassemble. It's complex so largest one with 5 coils will take 50s with a normal crowbar
			if (failure_probability && prob(failure_probability))
				total_system_failure(failure_probability, user)
				return

			to_chat(user, "<font color='red'>You have disassembled the SMES cell!</font>")
			dismantle()
			return

	//changing direction using wrench
	if(W.has_tool_quality(TOOL_WRENCH))
		disconnect_terminal(terminalconnections)	//clear 'em all.
		set_dir(turn(dir, 270)) //flip it turnways
		var/turf/turf = get_step(src, dir)
		for(var/obj/machinery/power/terminal/term in turf)
			if(term)
				add_nearby_terminals() //reconnect things. You silly bean.
				to_chat(user, span_notice("Terminal found."))
				break	//we attempt a connection in all directions, of all layers. and handle adding it. so let's just keep going.
			else if(!terminalconnections.len) //sanity in case they got destroyed.
				to_chat(user, span_alert("No power terminals found."))
				stat |= BROKEN
				update_icon()
				return

		update_icon()
		return

	if (!panel_open)
		to_chat(user, "<span class='filter_notice'><span class='warning'>You need to open access hatch on [src] first!</span></span>")
		return FALSE

	if(W.has_tool_quality(TOOL_WELDER))
		var/obj/item/weapon/weldingtool/WT = W
		if(!WT.isOn())
			to_chat(user, "<span class='filter_notice'>Turn on \the [WT] first!</span>")
			return FALSE
		if(!damage)
			to_chat(user, "<span class='filter_notice'>\The [src] is already fully repaired.</span>")
			return FALSE
		if(WT.remove_fuel(0,user) && do_after(user, damage, src))
			to_chat(user, "<span class='filter_notice'>You repair all structural damage to \the [src]</span>")
			damage = 0
		return FALSE

	else if(W.has_tool_quality(TOOL_CABLE_COIL) && !building_terminal)
		var/obj/item/stack/cable_coil/C = W
		var/dir = get_dir(user,src)
		if(ISDIAGONALDIR(dir))//we don't want diagonal click
			return

		var/turf/T = get_turf(user)
		if(isspace(T))
			to_chat(user, "<span class='warning'>You can't secure this item in open space!</span>")

		if (!T.is_plating()) //is the floor plating removed ?
			to_chat(user, "<span class='warning'>You must first remove the floor plating!</span>")
			return

		if(!panel_open)
			to_chat(user, "<span class='warning'>You must open the maintenance panel first!</span>")
			return

		if(C && C.target_layer)
			if(get_terminal_slot(C.target_layer))
				to_chat(user, "<span class='warning'>This SMES already has a power terminal on this layer!</span>")
				return

		if(C.get_amount() < 10)
			to_chat(user, "<span class='warning'>You need more wires!</span>")
			return

		if(get_terminal_slot(C.target_layer))
			to_chat(user, "<span class='warning'>There is already a terminal plugged into this layer!</span>")
			return
		var/terminal_cable_layer = GLOB.cable_name_to_layer[C.target_layer]

		to_chat(user, "<span class='notice'>You start building the power terminal...</span>")
		playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)

		if(!do_after(user, 50))
			return
		if(!C || C.get_amount() < 10)
			return
		var/obj/structure/cable/N = T.get_cable_node(terminal_cable_layer) //get the connecting node cable, if there's one
		if (prob(50))
			electrocute_mob(usr, N, N, 1, TRUE)

		C.use(10)
		//build the terminal and link it to the network
		if(make_terminal(user, T, terminal_cable_layer))
			connect_to_network()
		return FALSE

	else if(W.has_tool_quality(TOOL_WIRECUTTER))
		if(panel_open)
			var/obj/machinery/power/terminal/term = (locate() in user.loc) //You gotta stand on the turf
			if(term)
				term.dismantle(user, W, term.cable_layer)
			else
				to_chat(user, "<span class='notice'>You must stand on top of the power terminal you wish to remove.</span>")
				return FALSE

	else if(istype(W, /obj/item/weapon/smes_coil))
		if(cur_coils < max_coils)
			if(failure_probability && prob(failure_probability))
				total_system_failure(failure_probability, user)
				return

			to_chat(user, "You install the coil into the SMES unit!")
			user.drop_from_inventory(W, src)
			cur_coils ++
			component_parts += W
			W.loc = src
			recalc_coils()
		else
			to_chat(user, "<span class='filter_notice'><span class='notice'>You can't insert more coils into this SMES unit!</span></span>")

	return ..()

/obj/machinery/power/smes/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Smes", name)
		ui.open()

/obj/machinery/power/smes/tgui_data()
	var/list/data = list(
		"capacity" = capacity,
		"capacityPercent" = round(100*charge/capacity, 0.1),
		"charge" = charge,
		"inputAttempt" = input_attempt,
		"inputting" = inputting,
		"inputLevel" = input_level,
		"inputLevel_text" = DisplayPower(input_level),
		"inputLevelMax" = input_level_max,
		"inputAvailable" = input_available,
		"outputAttempt" = output_attempt,
		"outputting" = outputting,
		"outputLevel" = output_level,
		"outputLevel_text" = DisplayPower(output_level),
		"outputLevelMax" = output_level_max,
		"outputUsed" = output_used,
	)
	return data

/obj/machinery/power/smes/tgui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("tryinput")
			input_attempt = !input_attempt
			log_smes(usr)
			update_icon()
			. = TRUE
		if("tryoutput")
			output_attempt = !output_attempt
			log_smes(usr)
			update_icon()
			. = TRUE
		if("input")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "min")
				target = 0
				. = TRUE
			else if(target == "max")
				target = input_level_max
				. = TRUE
			else if(adjust)
				target = input_level + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				input_level = clamp(target, 0, input_level_max)
				log_smes(usr)
		if("output")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "min")
				target = 0
				. = TRUE
			else if(target == "max")
				target = output_level_max
				. = TRUE
			else if(adjust)
				target = output_level + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				output_level = clamp(target, 0, output_level_max)
				log_smes(usr)

/obj/machinery/power/smes/proc/inputting(var/do_input)
	input_attempt = do_input
	if(!input_attempt)
		inputting = FALSE

/obj/machinery/power/smes/proc/outputting(var/do_output)
	output_attempt = do_output
	if(!output_attempt)
		outputting = FALSE

/obj/machinery/power/smes/proc/log_smes(mob/user)
	investigate_log("Input/Output: [input_level]/[output_level] | Charge: [charge] | Output-mode: [output_attempt?"ON":"OFF"] | Input-mode: [input_attempt?"AUTO":"OFF"] by [user ? key_name(user) : "outside forces"] | At [src.loc]")

/obj/machinery/power/smes/proc/tgui_set_io(io, target, adjust)
	if(target == "min")
		target = 0
		. = TRUE
	else if(target == "max")
		target = output_level_max
		. = TRUE
	else if(adjust)
		target = output_level + adjust
		. = TRUE
	else if(text2num(target) != null)
		target = text2num(target)
		. = TRUE
	if(.)
		switch(io)
			if(SMES_TGUI_INPUT)
				set_input(target)
			if(SMES_TGUI_OUTPUT)
				set_output(target)

/obj/machinery/power/smes/take_damage(var/amount)
	amount = max(0, round(amount))
	damage += amount
	if(damage > maxdamage)
		visible_message("<span class='filter_notice'><span class='danger'>\The [src] explodes in large shower of sparks and smoke!</span></span>")
		// Depending on stored charge percentage cause damage.
		switch(Percentage())
			if(75 to INFINITY)
				explosion(get_turf(src), 1, 2, 4)
			if(40 to 74)
				explosion(get_turf(src), 0, 2, 3)
			if(5 to 39)
				explosion(get_turf(src), 0, 1, 2)
		qdel(src) // Either way we want to ensure the SMES is deleted.

/obj/machinery/power/smes/emp_act(severity)
	inputting(rand(0,1))
	outputting(rand(0,1))
	output_level = rand(0, output_level_max)
	input_level = rand(0, input_level_max)
	charge -= 1e6/severity
	if (charge < 0)
		charge = 0
	update_icon()
	..()

/obj/machinery/power/smes/bullet_act(var/obj/item/projectile/Proj)
	take_damage(Proj.get_structure_damage())

/obj/machinery/power/smes/ex_act(var/severity)
	// Two strong explosions will destroy a SMES.
	// Given the SMES creates another explosion on it's destruction it sounds fairly reasonable.
	take_damage(250 / severity)

/proc/rate_control(var/S, var/V, var/C, var/Min=1, var/Max=5, var/Limit=null)
	var/href = "<A href='?src=\ref[S];rate control=1;[V]"
	var/rate = "[href]=-[Max]'>-</A>[href]=-[Min]'>-</A> [(C?C : 0)] [href]=[Min]'>+</A>[href]=[Max]'>+</A>"
	if(Limit) return "[href]=-[Limit]'>-</A>"+rate+"[href]=[Limit]'>+</A>"
	return rate


/obj/machinery/power/smes/can_terminal_dismantle()
	. = panel_open ? TRUE : FALSE

// Proc: toggle_input()
// Parameters: None
// Description: Switches the input on/off depending on previous setting
/obj/machinery/power/smes/proc/toggle_input()
	inputting(!input_attempt)
	update_icon()

// Proc: toggle_output()
// Parameters: None
// Description: Switches the output on/off depending on previous setting
/obj/machinery/power/smes/proc/toggle_output()
	outputting(!output_attempt)
	update_icon()

// Proc: set_input()
// Parameters: 1 (new_input - New input value in Watts)
// Description: Sets input setting on this SMES. Trims it if limits are exceeded.
/obj/machinery/power/smes/proc/set_input(var/new_input = 0)
	input_level = between(0, new_input, input_level_max)
	update_icon()

// Proc: set_output()
// Parameters: 1 (new_output - New output value in Watts)
// Description: Sets output setting on this SMES. Trims it if limits are exceeded.
/obj/machinery/power/smes/proc/set_output(var/new_output = 0)
	output_level = between(0, new_output, output_level_max)
	update_icon()

///WELCOME TO HELL
// Proc: total_system_failure()
// Parameters: 2 (intensity - how strong the failure is, user - person which caused the failure)
// Description: Checks the sensors for alerts. If change (alerts cleared or detected) occurs, calls for icon update.
/obj/machinery/power/smes/proc/total_system_failure(var/intensity = 0, var/mob/user)
	// SMESs store very large amount of power. If someone screws up (ie: Disables safeties and attempts to modify the SMES) very bad things happen.
	// Bad things are based on charge percentage.
	// Possible effects:
	// Sparks - Lets out few sparks, mostly fire hazard if phoron present. Otherwise purely aesthetic.
	// Shock - Depending on intensity harms the user. Insultated Gloves protect against weaker shocks, but strong shock bypasses them.
	// EMP Pulse - Lets out EMP pulse discharge which screws up nearby electronics.
	// Light Overload - X% chance to overload each lighting circuit in connected powernet. APC based.
	// APC Failure - X% chance to destroy APC causing very weak explosion too. Won't cause hull breach or serious harm.
	// SMES Explosion - X% chance to destroy the SMES, in moderate explosion. May cause small hull breach.

	if (!intensity)
		return

	var/mob/living/carbon/human/h_user = user
	if (!istype(h_user))
		return

	// Preparations
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	// Check if user has protected gloves.
	var/user_protected = FALSE
	if(h_user.gloves)
		var/obj/item/clothing/gloves/G = h_user.gloves
		if(G.siemens_coefficient == 0)
			user_protected = TRUE
	log_game("SMES FAILURE: <b>[COORD(loc)]</b> User: [usr.ckey], Intensity: [intensity]/100 ")
	message_admins("SMES FAILURE: <b>[COORD(loc)]</b> User: [usr.ckey], Intensity: [intensity]/100 - <A HREF='?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;[ADMIN_COORDJMP(src)]'>JMP</a>")

	var/used_hand = h_user.hand?"l_hand":"r_hand"

	switch (intensity)
		if (0 to 15)
			// Small overcharge
			// Sparks, Weak shock
			s.set_up(2, 1, src)
			if (user_protected && prob(80))
				to_chat(h_user, "A small electrical arc almost burns your hand. Luckily you had your gloves on!")
			else
				to_chat(h_user, "A small electrical arc sparks and burns your hand as you touch the [src]!")
				h_user.adjustFireLossByPart(rand(5,10), used_hand)
				h_user.Weaken(2)

		if (16 to 35)
			// Medium overcharge
			// Sparks, Medium shock, Weak EMP
			s.set_up(4,1,src)
			if (user_protected && prob(25))
				to_chat(h_user, "A medium electrical arc sparks and almost burns your hand. Luckily you had your gloves on!")
			else
				to_chat(h_user, "A medium electrical arc sparks as you touch the [src], severely burning your hand!")
				h_user.adjustFireLossByPart(rand(10,25), used_hand)
				h_user.Weaken(5)
			spawn()
				empulse(get_turf(src), 1, 2, 3, 4)

		if (36 to 60)
			// Strong overcharge
			// Sparks, Strong shock, Strong EMP, 10% light overload. 1% APC failure
			s.set_up(7,1,src)
			if (user_protected)
				to_chat(h_user, "A strong electrical arc sparks between you and [src], ignoring your gloves and burning your hand!")
				h_user.adjustFireLossByPart(rand(25,60), used_hand)
				h_user.Weaken(8)
			else
				to_chat(h_user, "A strong electrical arc sparks between you and [src], knocking you out for a while!")
				h_user.electrocute_act(rand(35,75), src, def_zone = BP_TORSO)
			spawn()
				empulse(get_turf(src), 6, 8, 12, 16)
			apcs_overload(1, 10)
			ping("Caution. Output regulator malfunction. Uncontrolled discharge detected.")

		if (61 to INFINITY)
			// Massive overcharge
			// Sparks, Near - instantkill shock, Strong EMP, 25% light overload, 5% APC failure. 50% of SMES explosion. This is bad.
			s.set_up(10,1,src)
			to_chat(h_user, "A massive electrical arc sparks between you and [src]. The last thing you can think about is \"Oh shit...\"")
			// Remember, we have few gigajoules of electricity here.. Turn them into crispy toast.
			h_user.electrocute_act(rand(150,195), src, def_zone = BP_TORSO)
			spawn()
				empulse(get_turf(src), 32, 64)
			apcs_overload(5, 25)
			ping("Caution. Output regulator malfunction. Significant uncontrolled discharge detected.")

			if (prob(50))
				// Added admin-notifications so they can stop it when griffed.
				log_game("SMES explosion imminent.")
				message_admins("SMES explosion imminent.")
				ping("DANGER! Magnetic containment field unstable! Containment field failure imminent!")
				failing = TRUE
				update_icon()
				// 30 - 60 seconds and then BAM!
				spawn(rand(30 SECONDS, 60 SECONDS))
					if(!failing) // Admin can manually set this var back to 0 to stop overload, for use when griffed.
						update_icon()
						ping("Magnetic containment stabilised.")
						return
					ping("DANGER! Magnetic containment field failure in 3 ... 2 ... 1 ...")
					explosion(get_turf(src),1,2,4,8)
					// Not sure if this is necessary, but just in case the SMES *somehow* survived..
					qdel(src)

	s.start()
	charge = 0



// Proc: apcs_overload()
// Parameters: 2 (failure_chance - chance to actually break the APC, overload_chance - Chance of breaking lights)
// Description: Damages output powernet by power surge. Destroys few APCs and lights, depending on parameters.
/obj/machinery/power/smes/proc/apcs_overload(var/failure_chance, var/overload_chance)
	if (!powernet)
		return

	for(var/obj/machinery/power/terminal/T in powernet.nodes)
		if(istype(T.master, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/A = T.master
			if (prob(overload_chance))
				A.overload_lighting()
			if (prob(failure_chance))
				A.set_broken()
