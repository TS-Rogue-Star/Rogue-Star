/////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star October 2026: Computer and Related Machinery Idle Processing //
/////////////////////////////////////////////////////////////////////////////////////////////////

// POWERNET SENSOR MONITORING CONSOLE
// Connects to powernet sensors and loads data from them. Shows this data to the user.
// Newly supports NanoUI.


/obj/machinery/computer/power_monitor
	processing_enabled = TRUE // RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
	processing_on_demand = TRUE // RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
	name = "Power Monitoring Console"
	desc = "Computer designed to remotely monitor power levels around the station"
	icon_keyboard = "power_key"
	icon_screen = "power_monitor"
	light_color = "#ffcc33"

	//computer stuff
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/weapon/circuitboard/powermonitor
	var/alerting = 0
	use_power = USE_POWER_IDLE
	idle_power_usage = 300
	active_power_usage = 300
	var/datum/tgui_module/power_monitor/power_monitor

// Checks the sensors for alerts. If change (alerts cleared or detected) occurs, calls for icon update.
/obj/machinery/computer/power_monitor/process()
	var/alert = check_warnings()
	if(alert != alerting)
		alerting = !alerting
		update_icon()
	return PROCESS_KILL // RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/* VOREStation Move - Moved to VR File
// Updates icon of this computer according to current status.
/obj/machinery/computer/power_monitor/update_icon()
	if(!(stat & (NOPOWER|BROKEN)))
		if(alerting)
			icon_screen = "[initial(icon_screen)]"
		else
			icon_screen = "[initial(icon_screen)]_warn"
	..()
*/
// On creation automatically connects to active sensors. This is delayed to ensure sensors already exist.
/obj/machinery/computer/power_monitor/New()
	..()
	power_monitor = new(src)
	// RS Add Start: Computer and Related Machinery Idle Processing (Lira, October 2026)
	RegisterSignal(SSdcs, list(COMSIG_GLOB_POWER_WARNING_CHANGED, COMSIG_GLOB_POWER_TOPOLOGY_CHANGED), PROC_REF(wake_processing))
	RegisterSignal(SSdcs, COMSIG_GLOB_POWER_SENSORS_CHANGED, PROC_REF(refresh_power_sensors))
	// RS Add End

// On user click opens the UI of this computer.
/obj/machinery/computer/power_monitor/attack_hand(mob/user)
	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER))
		return
	tgui_interact(user)

// Uses dark magic to operate the NanoUI of this computer.
/obj/machinery/computer/power_monitor/tgui_interact(mob/user, var/datum/tgui/ui = null)
	power_monitor.tgui_interact(user, ui)

// Verifies if any warnings were registered by connected sensors.
/obj/machinery/computer/power_monitor/proc/check_warnings()
	for(var/obj/machinery/power/sensor/S in power_monitor.grid_sensors)
		if(S.check_grid_warning())
			return 1
	return 0

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/power_monitor/proc/refresh_power_sensors()
	SIGNAL_HANDLER
	power_monitor?.refresh_sensors()
	wake_processing()

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/power_monitor/Moved(atom/old_loc, direction, forced = FALSE)
	. = ..()
	refresh_power_sensors()

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/power_monitor/Destroy()
	UnregisterSignal(SSdcs, list(COMSIG_GLOB_POWER_WARNING_CHANGED, COMSIG_GLOB_POWER_TOPOLOGY_CHANGED, COMSIG_GLOB_POWER_SENSORS_CHANGED))
	QDEL_NULL(power_monitor)
	return ..()
