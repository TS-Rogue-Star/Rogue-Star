/// Ender Cables 2.0 ! USE THE PRESETS! Uses a fuckload of Multiiz deck relay code 'cuz it works
/obj/machinery/power/power_transmitter
	name = "Power Transmitter"
	desc = "A curious device utilizing bluespace and quantum entanglement to transfer electrical power great distances wirelessly. Do not lick while in operation."
	icon = 'icons/obj/machines/power/endertransmitter.dmi'
	icon_state = "transmitter_unsecured"
	anchored = FALSE
	density = TRUE
	unacidable = TRUE
	/// prevent regular nerds from turning it off
	req_access = list(access_engine_equip)
	/// ID requirements to link powernets
	var/id = null
	/// We're obviously a powernet user
	use_power = USE_POWER_OFF
	///Is the machine active?
	var/active = FALSE
	/// Circuit board path
	circuit = /obj/item/weapon/circuitboard/power_transmitter
	///did someone in Engineering do their job?
	var/locked = FALSE
	///Physical health remaining. Fragile equipment!
	var/integrity = 40
	/// Connection partner
	var/obj/machinery/power/power_transmitter/connection_buddy
	/// Current level to prevent infinite range mischief
	var/ranging_level = 0
	/// Preventing lighter cable connections
	can_change_cable_layer = FALSE
	///Heavy cable connections only
	cable_layer = CABLE_LAYER_4

/obj/machinery/power/power_transmitter/preset
	anchored = TRUE

/obj/machinery/power/power_transmitter/preset/poi
	anchored = TRUE
	active = TRUE
	locked = TRUE

/obj/machinery/power/power_transmitter/preset/engine
	id = "EngineToStation"

/obj/machinery/power/power_transmitter/preset/solar
	id = "SolarTransfer"

/obj/machinery/power/power_transmitter/preset/mining
	id = "MiningTransfer"

/obj/machinery/power/power_transmitter/should_have_node()
	return anchored

/obj/machinery/power/power_transmitter/Initialize(mapload)
	. = ..()
	GLOB.powertransmitters += src
	//Set the ranging_level if there's none.
	if(!ranging_level)
		//Defaults to our Z level!
		var/turf/position = get_turf(src)
		ranging_level = position.z

	addtimer(CALLBACK(src, PROC_REF(find_buddy)), 30)
	addtimer(CALLBACK(src, PROC_REF(refresh)), 50) //Wait a bit so we can find a valid partner, then get powering

/obj/machinery/power/power_transmitter/Destroy()
	. = ..()
	message_admins("Power Transmitter deleted at [COORD(src)] - [ADMIN_JMP(loc)]",0,1)
	log_game("Power Transmitter deleted at [COORD(src)].")
	investigate_log("<font color='red'>deleted</font> at [COORD(src)]","powernet")
	if(connection_buddy) //Lose connections
		connection_buddy.connection_buddy = null
	if(powernet)
		powernet = null
	GLOB.powertransmitters -= src

/obj/machinery/power/power_transmitter/forceMove(var/newloc)
	. = ..(newloc)
	ranging_level = z

/obj/machinery/power/power_transmitter/attack_hand(mob/user as mob)
	add_fingerprint(user)
	activate(user)

/obj/machinery/power/power_transmitter/proc/activate(mob/user as mob)
	if(anchored)
		if(!powernet)
			to_chat(user, "\The [src] isn't connected to a wire.")
			return FALSE
		if(!locked)
			active = !active
			if(!active)
				to_chat(user, "You turn off [src].")
				message_admins("Power Transmitter turned off by [key_name(user, user.client)], [ADMIN_QUE(user)], [ADMIN_JMP(src)]",0,1)
				log_game("Power Transmitter [COORD(src)] OFF by [key_name(user)]")
				investigate_log("turned <font color='red'>off</font> by [user.key] At [COORD(src)]", "powernet")
			else
				to_chat(user, "You turn on [src].")
				message_admins("Power Transmitter turned on by [key_name(user, user.client)], [ADMIN_QUE(user)], [ADMIN_JMP(src)]",0,1)
				log_game("Power Transmitter [COORD(src)] ON by [key_name(user)]")
				investigate_log("turned <font color='green'>on</font> by [user.key] At [COORD(src)]", "powernet")
			refresh()
		else
			to_chat(user, span_warning("The controls are locked!"))
	else
		to_chat(user, span_warning("\The [src] needs to be firmly secured to the floor first."))
		return FALSE

/obj/machinery/power/power_transmitter/process()
	if(stat & (BROKEN))
		icon_state = "transmitter_broken"
		return

	if(!anchored)
		active = FALSE
		icon_state = "transmitter_unsecured"
		if(connection_buddy)
			connection_buddy.connection_buddy = null
		connection_buddy = null
		return

	if(anchored)
		icon_state = "transmitter_secured"

	refresh()
	if(active)
		if(powernet && (powernet.avail <= 0))
			icon_state = "transmitter_error"
		else if(connection_buddy && connection_buddy.active && powernet && (powernet.avail > 0))
			icon_state = "transmitter_connected"

	if(active && (!connection_buddy || QDELETED(connection_buddy) || !connection_buddy.active))
		icon_state = "transmitter_error"
		find_buddy()

///Handles re-acquiring + merging powernets found by find_powernet()
/obj/machinery/power/power_transmitter/proc/refresh()
	if(connection_buddy && connection_buddy.id == id)
		connection_buddy.merge(src)

/obj/machinery/power/power_transmitter/proc/merge(obj/machinery/power/power_transmitter/PT)
	if(!PT)
		return
	if(!active || !PT.active)
		return	//we need to be turned on first!
	var/turf/merge_from = get_turf(PT)
	var/turf/merge_to = get_turf(src)

	var/obj/structure/cable/C = merge_from.get_cable_node()
	var/obj/structure/cable/XR = merge_to.get_cable_node()
	if(C && XR)
		merge_powernets(XR.powernet,C.powernet)//Bridge the powernets.

/obj/machinery/power/power_transmitter/proc/find_buddy(obj/machinery/power/power_transmitter/PT)
	if(!id)	//We don't have an ID code, don't bother continuing
		return FALSE

	if(!anchored)	//Can't work if we ain't secured or energized
		return FALSE

	var/turf/T = get_turf(src)
	if(!T || !istype(T))
		return FALSE
	connection_buddy = null //in case we're re-establishing
	powernet = null
	var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf
	if(C && C.powernet)
		C.powernet.add_machine(src) //Nice we're in.
		powernet = C.powernet

	//unlike deck relays, we're magic machines
	for(PT in GLOB.powertransmitters)
		var/list/range_connect = using_map.get_map_levels(ranging_level, TRUE, 1)
		if(PT && !(PT.z in range_connect))	//out of range
			continue
		if(PT && PT.id && PT.id == id)
			connection_buddy = PT
			PT.connection_buddy = src

/obj/machinery/power/power_transmitter/examine(mob/user)
	. = ..()
	if(id)
		. += "It is registered to the id tag of: [id]."
	. += "Use a multitool to set a new ID tag. The sender and reciever must be identical!"

/obj/machinery/power/power_transmitter/attackby(obj/item/W, mob/user)
	. = ..()
	if(default_unfasten_wrench(user, W, 40))
		update_cable_icons_on_turf(get_turf(src))
		return FALSE

	if(W.has_tool_quality(TOOL_MULTITOOL))
		if(!locked)
			var/new_ident = tgui_input_text(usr, "Enter a new ident tag.", "Power Transmitter", id, MAX_NAME_LEN)
			new_ident = sanitize(new_ident,MAX_NAME_LEN)
			if(new_ident && user.Adjacent(src))
				id = new_ident
			to_chat(user, span_notice("The id is now set to [id]"))
			return
		else
			to_chat(user, span_warning("Access denied."))
		return


	if(istype(W, /obj/item/weapon/card/id) || istype(W, /obj/item/device/pda))
		if(allowed(user))
			locked = !locked
			to_chat(user, span_notice("The controls are now [locked ? "locked." : "unlocked."]"))
		else
			to_chat(user, span_warning("Access denied."))
		return

/datum/design/circuit/power_transmitter
	name = "Power Transmittor"
	id = "power_transmitter"
	req_tech = list(TECH_DATA = 3, TECH_POWER = 5, TECH_ENGINEERING = 5, TECH_BLUESPACE = 4)
	build_path = /obj/item/weapon/circuitboard/power_transmitter
	sort_string = "PWTM"

/obj/item/weapon/circuitboard/power_transmitter
	name = T_BOARD("power transmitter")
	build_path = /obj/machinery/power/power_transmitter
	origin_tech = list(TECH_DATA = 3, TECH_ENGINEERING = 5, TECH_POWER = 5, TECH_BLUESPACE = 4)
	req_components = list(
							/obj/item/weapon/stock_parts/subspace/ansible = 1,
							/obj/item/weapon/smes_coil/super_io = 1,
							/obj/item/weapon/stock_parts/capacitor = 5,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/stack/cable_coil/heavyduty = 20
						)
