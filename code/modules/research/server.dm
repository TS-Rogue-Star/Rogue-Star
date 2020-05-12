/obj/machinery/rnd/server
	name = "\improper R&D Server"
	desc = "A computer system running a deep neural network that processes arbitrary information to produce data useable in the development of new technologies. In layman's terms, it makes research points."
	icon = 'icons/obj/machines/research_vr.dmi' //VOREStation Edit - New Icon
	icon_state = "RD-server-on"
	circuit = /obj/item/weapon/circuitboard/rdserver
	idle_power_usage = 100
	active_power_usage = 800
	req_access = list(access_rd) // Only the R&D can change server settings.

	var/datum/techweb/stored_research	// Really used only for logs nowadays
	// var/heat_health = 100
	// Interestig idea, should we keep this?
	// var/list/id_with_upload = list()	//List of R&D consoles with upload to server access.
	// var/list/id_with_download = list()	//List of R&D consoles with download from server access.

	//Code for point mining here.
	var/working = TRUE					// Temperature should break it.
	var/research_disabled = FALSE		// Flag to voluntarily disable generating research points
	var/server_id = 0					// Not really used for any useful purpose
	var/produces_heat = TRUE			// Flag to enable/disable heat production
	var/base_mining_income = 2
	var/current_temp = 0				// Current intern
	var/delay = 5						// Mining ticks between heat generation
	var/temp_tolerance_low = 0			// Minimum safe operating temperature (not implemented)
	var/temp_tolerance_high = T20C		// Maximum safe operating temperature
	var/temp_penalty_coefficient = 0.5	//1 = -1 points per degree above high tolerance. 0.5 = -0.5 points per degree above high tolerance.


/obj/machinery/rnd/server/Initialize()
	. = ..()
	name += " [num2hex(rand(1,65535), -1)]" //gives us a random four-digit hex number as part of the name. Y'know, for fluff.
	SSresearch.servers |= src
	stored_research = SSresearch.science_tech
	default_apply_parts()
	current_temp = get_env_temp()

/obj/machinery/rnd/server/Destroy()
	SSresearch.servers -= src
	return ..()

/obj/machinery/rnd/server/RefreshParts()
	var/tot_rating = 0
	for(var/obj/item/weapon/stock_parts/SP in src)
		tot_rating += SP.rating
	update_active_power_usage(initial(active_power_usage) / max(1, tot_rating))

/obj/machinery/rnd/server/update_icon()
	if(inoperable(EMPED))
		icon_state = "RD-server-off"
	else if(research_disabled)
		icon_state = "RD-server-halt"
	else
		icon_state = "RD-server-on"

/obj/machinery/rnd/server/power_change()
	if((. = ..()))
		refresh_working()
	return

/obj/machinery/rnd/server/proc/refresh_working()
	if(inoperable(EMPED) || research_disabled)
		working = FALSE
		update_use_power(USE_POWER_IDLE)
	else
		working = TRUE
		update_use_power(USE_POWER_ACTIVE)
	update_icon()

/obj/machinery/rnd/server/proc/toggle_disable()
	research_disabled = !research_disabled
	refresh_working()

/obj/machinery/rnd/server/proc/mine()
	current_temp = get_env_temp()
	if(!working)
		return 0
	if(delay)
		delay--
	else
		produce_heat()
		delay = initial(delay)
	. = base_mining_income
	var/penalty = max((get_env_temp() - temp_tolerance_high), 0) * temp_penalty_coefficient
	. = max(. - penalty, -base_mining_income)

/obj/machinery/rnd/server/proc/get_env_temp()
	var/datum/gas_mixture/environment = loc.return_air()
	return environment.temperature

/obj/machinery/rnd/server/emp_act(severity)
	stat |= EMPED
	addtimer(CALLBACK(src, .proc/unemp), 600)
	refresh_working()
	..()

/obj/machinery/rnd/server/proc/unemp()
	stat &= ~EMPED
	refresh_working()

/obj/machinery/rnd/server/proc/produce_heat()
	if(!produces_heat)
		return

	if(!use_power)
		return

	if(inoperable())
		var/turf/simulated/L = loc
		if(istype(L))
			var/datum/gas_mixture/env = L.return_air()
			var/datum/gas_mixture/removed = env.remove_ratio(0.25)
			if(removed)
				var/heat_produced = get_power_usage() // Obviously can't produce more heat than the machine draws from it's power source
				removed.add_thermal_energy(heat_produced)
			env.merge(removed)

/obj/machinery/rnd/server/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(default_deconstruction_screwdriver(user, O))
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	return ..()

/obj/machinery/rnd/server/centcom
	name = "Central R&D Database"
	server_id = -1

/obj/machinery/rnd/server/centcom/proc/update_connections()
	var/list/no_id_servers = list()
	var/list/server_ids = list()
	for(var/obj/machinery/rnd/server/S in machines)
		switch(S.server_id)
			if(-1)
				continue
			if(0)
				no_id_servers += S
			else
				server_ids += S.server_id

	for(var/obj/machinery/rnd/server/S in no_id_servers)
		var/num = 1
		while(!S.server_id)
			if(num in server_ids)
				num++
			else
				S.server_id = num
				server_ids += num
		no_id_servers -= S

/obj/machinery/computer/rdservercontrol
	name = "R&D Server Controller"
	desc = "Manage the research designs and servers. Can also modify upload/download permissions to R&D consoles."
	icon_keyboard = "rd_key"
	icon_screen = "rdcomp"
	light_color = "#a97faa"
	circuit = /obj/item/weapon/circuitboard/rdservercontrol
	var/screen = 0
	var/obj/machinery/rnd/server/temp_server
	var/list/servers = list()
	var/list/consoles = list()
	var/badmin = 0

/obj/machinery/computer/rdservercontrol/Topic(href, href_list)
	if((. = ..()))
		return

	add_fingerprint(usr)
	if(!allowed(usr) && !emagged)
		to_chat(usr, "<span class='warning'>You do not have the required access level</span>")
		return

	if (href_list["toggle"])
		var/obj/machinery/rnd/server/S = locate(href_list["toggle"]) in SSresearch.servers
		S.toggle_disable()

	updateUsrDialog()
	return

/obj/machinery/computer/rdservercontrol/proc/generate_ui()
	var/list/dat = list("<head><title>R&amp;D Server Control</title></head><body><div class='statusDisplay'>")
	dat += "<b>Connected Servers:</b>"
	dat += "<table><tr><th style='width:25%'><b>Server</b></th><th style='width:25%'><b>Operating Temp</b></th><th style='width:25%'><b>Status</b></th>"
	for(var/obj/machinery/rnd/server/S in global.machines)
		dat += "<tr><td style='width:25%'>[S.name]</td><td style='width:25%'>[S.current_temp]</td><td style='width:25%'>[S.inoperable(EMPED)?"Offline":"<A href='?src=[REF(src)];toggle=[REF(S)]'>([S.research_disabled? "<font color=red>Disabled" : "<font color=lightgreen>Online"]</font>)</A>"]</td><BR>"
	dat += "</table><br>"

	dat += "<b>Research Log</b><br>"
	var/datum/techweb/stored_research
	stored_research = SSresearch.science_tech
	if(stored_research.research_logs.len)
		dat += "<table BORDER='1'>"
		dat += "<tr><th><b>Entry</b></th><th><b>Research Name</b></th><th><b>Cost</b></th><th><b>Researcher Name</b></th><th><b>Console Location</b></th></tr>"
		for(var/i=stored_research.research_logs.len, i>0, i--)
			dat += "<tr><td>[i]</td>"
			for(var/j in stored_research.research_logs[i])
				dat += "<td>[j]</td>"
			dat +="</tr>"
		dat += "</table>"
	else
		dat += "<br>No history found."
	dat += "</div>"
	return dat.Join()

/obj/machinery/computer/rdservercontrol/attack_hand(mob/user as mob)
	if((. = ..()))
		return
	user.set_machine(src)
	var/datum/browser/popup = new(user, "server_control", src.name, 900, 620)
	popup.set_content(generate_ui())
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/computer/rdservercontrol/emag_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		playsound(src, 'sound/effects/sparks4.ogg', 75, 1)
		emagged = 1
		to_chat(user, "<span class='notice'>You you disable the security protocols.</span>")
		src.updateUsrDialog()
		return 1

/obj/machinery/rnd/server/robotics
	name = "Robotics R&D Server"
	// id_with_upload_string = "1;2"
	// id_with_download_string = "1;2"
	server_id = 2

/obj/machinery/rnd/server/core
	name = "Core R&D Server"
	// id_with_upload_string = "1"
	// id_with_download_string = "1"
	server_id = 1
