/*
Research and Development (R&D) Console

This is the main work horse of the R&D system. It contains the menus/controls for the Destructive Analyzer, Protolathe, and Circuit
imprinter. It also contains the /datum/research holder with all the known/possible technology paths and device designs.

Basic use: When it first is created, it will attempt to link up to related devices within 3 squares. It'll only link up if they
aren't already linked to another console. Any consoles it cannot link up with (either because all of a certain type are already
linked or there aren't any in range), you'll just not have access to that menu. In the settings menu, there are menu options that
allow a player to attempt to re-sync with nearby consoles. You can also force it to disconnect from a specific console.

The imprinting and construction menus do NOT require toxins access to access but all the other menus do. However, if you leave it
on a menu, nothing is to stop the person from using the options on that menu (although they won't be able to change to a different
one). You can also lock the console on the settings menu if you're feeling paranoid and you don't want anyone messing with it who
doesn't have toxins access.

When a R&D console is destroyed or even partially disassembled, you lose all research data on it. However, there are two ways around
this dire fate:
- The easiest way is to go to the settings menu and select "Sync Database with Network." That causes it to upload (but not download)
it's data to every other device in the game. Each console has a "disconnect from network" option that'll will cause data base sync
operations to skip that console. This is useful if you want to make a "public" R&D console or, for example, give the engineers
a circuit imprinter with certain designs on it and don't want it accidentally updating. The downside of this method is that you have
to have physical access to the other console to send data back. Note: An R&D console is on CentCom so if a random griffan happens to
cause a ton of data to be lost, an admin can go send it back.
- The second method is with Technology Disks and Design Disks. Each of these disks can hold a single technology or design datum in
it's entirety. You can then take the disk to any R&D console and upload it's data to it. This method is a lot more secure (since it
won't update every console in existence) but it's more of a hassle to do. Also, the disks can be stolen.
*/

/obj/machinery/computer/rdconsole
	name = "R&D control console"
	desc = "Science, in a computer! Experiment results not guaranteed."
	icon_keyboard = "rd_key"
	icon_screen = "rdcomp"
	light_color = "#a97faa"
	circuit = /obj/item/weapon/circuitboard/rdconsole
	var/datum/techweb/stored_research					//Reference to global science techweb.
	var/obj/item/weapon/disk/tech_disk/t_disk = null	//Stores the technology disk.
	var/obj/item/weapon/disk/design_disk/d_disk = null	//Stores the design disk.

	var/obj/machinery/r_n_d/destructive_analyzer/linked_destroy = null	//Linked Destructive Analyzer
	var/obj/machinery/r_n_d/protolathe/linked_lathe = null				//Linked Protolathe
	var/obj/machinery/r_n_d/circuit_imprinter/linked_imprinter = null	//Linked Circuit Imprinter

	var/screen = 1.0	//Which screen is currently showing.
	var/id = 0			//ID of the computer (for server restrictions).
	var/sync = 1		//If sync = 0, it doesn't show up on Server Control Console

	req_access = list(access_research)	//Data and setting manipulation requires scientist access.

	var/protofilter //String to filter protolathe designs by
	var/circuitfilter //String to filter circuit designs by

/obj/machinery/computer/rdconsole/proc/CallMaterialName(var/ID)
	var/return_name = ID
	switch(return_name)
		if("metal")
			return_name = "Metal"
		if("glass")
			return_name = "Glass"
		if("gold")
			return_name = "Gold"
		if("silver")
			return_name = "Silver"
		if("phoron")
			return_name = "Solid Phoron"
		if("uranium")
			return_name = "Uranium"
		if("diamond")
			return_name = "Diamond"
	return return_name

/obj/machinery/computer/rdconsole/proc/CallReagentName(var/ID)
	var/return_name = ID
	var/datum/reagent/temp_reagent
	for(var/R in (typesof(/datum/reagent) - /datum/reagent))
		temp_reagent = null
		temp_reagent = new R()
		if(temp_reagent.id == ID)
			return_name = temp_reagent.name
			qdel(temp_reagent)
			temp_reagent = null
			break
	return return_name

/obj/machinery/computer/rdconsole/proc/SyncRDevices() //Makes sure it is properly sync'ed up with the devices attached to it (if any).
	for(var/obj/machinery/r_n_d/D in range(3, src))
		if(D.linked_console != null || D.panel_open)
			continue
		if(istype(D, /obj/machinery/r_n_d/destructive_analyzer))
			if(linked_destroy == null)
				linked_destroy = D
				D.linked_console = src
		else if(istype(D, /obj/machinery/r_n_d/protolathe))
			if(linked_lathe == null)
				linked_lathe = D
				D.linked_console = src
		else if(istype(D, /obj/machinery/r_n_d/circuit_imprinter))
			if(linked_imprinter == null)
				linked_imprinter = D
				D.linked_console = src
	return

/obj/machinery/computer/rdconsole/Initialize()
	. = ..()
	stored_research = SSresearch.science_tech
	stored_research.consoles_accessing[src] = TRUE
	SyncRDevices()

/obj/machinery/computer/rdconsole/Destroy()
	if(stored_research)
		stored_research.consoles_accessing -= src
	if(linked_destroy)
		linked_destroy.linked_console = null
		linked_destroy = null
	if(linked_lathe)
		linked_lathe.linked_console = null
		linked_lathe = null
	if(linked_imprinter)
		linked_imprinter.linked_console = null
		linked_imprinter = null
	if(t_disk)
		t_disk.forceMove(drop_location(src))
		t_disk = null
	if(d_disk)
		d_disk.forceMove(drop_location(src))
		d_disk = null
	return ..()

/obj/machinery/computer/rdconsole/attackby(var/obj/item/weapon/D as obj, var/mob/user as mob)
	if(istype(D, /obj/item/research_notes))
		var/obj/item/research_notes/R = D
		stored_research.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = R.value))
		playsound(src,'sound/machines/copier.ogg', 100, TRUE)
		qdel(R)
		updateUsrDialog()
		return TRUE
	//Loading a disk into it.
	if(istype(D, /obj/item/weapon/disk))
		if(t_disk || d_disk)
			to_chat(user, "A disk is already loaded into the machine.")
			return

		if(istype(D, /obj/item/weapon/disk/tech_disk))
			t_disk = D
		else if (istype(D, /obj/item/weapon/disk/design_disk))
			d_disk = D
		else
			to_chat(user, "<span class='notice'>Machine cannot accept disks in that format.</span>")
			return
		if(!user.unEquip(D, target = src))
			to_chat(user, "<span class='warning'>[D] is stuck to your hand!</span>")
			d_disk = t_disk = null
			return
		to_chat(user, "<span class='notice'>You add \the [D] to the machine.</span>")
	else
		//The construction/deconstruction of the console code.
		return ..()

	src.updateUsrDialog()
	return

/obj/machinery/computer/rdconsole/emp_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		playsound(src.loc, 'sound/effects/sparks4.ogg', 75, 1)
		emagged = 1
		to_chat(user, "<span class='notice'>You you disable the security protocols.</span>")
		return 1

/obj/machinery/computer/rdconsole/Topic(href, href_list)
	if(..())
		return 1

	add_fingerprint(usr)

	usr.set_machine(src)
	if((screen < 1 || (screen == 1.6 && href_list["menu"] != "1.0")) && (!allowed(usr) && !emagged)) //Stops people from HREF exploiting out of the lock screen, but allow it if they have the access.
		to_chat(usr, "Unauthorized Access")
		return

	if(href_list["menu"]) //Switches menu screens. Converts a sent text string into a number. Saves a LOT of code.
		var/temp_screen = text2num(href_list["menu"])
		if(temp_screen <= 1.1 || (3 <= temp_screen && 4.9 >= temp_screen) || allowed(usr) || emagged) //Unless you are making something, you need access.
			screen = temp_screen
		else
			to_chat(usr, "Unauthorized Access.")

	else if(href_list["updt_tech"]) //Update the research holder with information from the technology disk.
		screen = 0.0
		spawn(5 SECONDS)
			screen = 1.2
			files.AddTech2Known(t_disk.stored)
			updateUsrDialog()
			griefProtection() //Update CentCom too

	else if(href_list["clear_tech"]) //Erase data on the technology disk.
		t_disk.stored = null

	else if(href_list["eject_tech"]) //Eject the technology disk.
		t_disk.loc = loc
		t_disk = null
		screen = 1.0

	else if(href_list["copy_tech"]) //Copys some technology data from the research holder to the disk.
		for(var/datum/tech/T in files.known_tech)
			if(href_list["copy_tech_ID"] == T.id)
				t_disk.stored = T
				break
		screen = 1.2

	else if(href_list["updt_design"]) //Updates the research holder with design data from the design disk.
		screen = 0.0
		spawn(5 SECONDS)
			screen = 1.4
			files.AddDesign2Known(d_disk.blueprint)
			updateUsrDialog()
			griefProtection() //Update CentCom too

	else if(href_list["clear_design"]) //Erases data on the design disk.
		d_disk.blueprint = null

	else if(href_list["eject_design"]) //Eject the design disk.
		d_disk.loc = loc
		d_disk = null
		screen = 1.0

	else if(href_list["copy_design"]) //Copy design data from the research holder to the design disk.
		for(var/datum/design/D in files.known_designs)
			if(href_list["copy_design_ID"] == D.id)
				d_disk.blueprint = D
				break
		screen = 1.4

	else if(href_list["eject_item"]) //Eject the item inside the destructive analyzer.
		if(linked_destroy)
			if(linked_destroy.busy)
				to_chat(usr, "<span class='notice'>The destructive analyzer is busy at the moment.</span>")

			else if(linked_destroy.loaded_item)
				linked_destroy.loaded_item.loc = linked_destroy.loc
				linked_destroy.loaded_item = null
				linked_destroy.icon_state = "d_analyzer"
				screen = 2.1

	else if(href_list["deconstruct"]) //Deconstruct the item in the destructive analyzer and update the research holder.
		if(linked_destroy)
			if(linked_destroy.busy)
				to_chat(usr, "<span class='notice'>The destructive analyzer is busy at the moment.</span>")
			else
				if(alert("Proceeding will destroy loaded item. Continue?", "Destructive analyzer confirmation", "Yes", "No") == "No" || !linked_destroy)
					return
				linked_destroy.busy = 1
				screen = 0.1
				updateUsrDialog()
				flick("d_analyzer_process", linked_destroy)
				spawn(2.4 SECONDS)
					if(linked_destroy)
						linked_destroy.busy = 0
						if(!linked_destroy.loaded_item)
							to_chat(usr, "<span class='notice'>The destructive analyzer appears to be empty.</span>")
							screen = 1.0
							return

						for(var/T in linked_destroy.loaded_item.origin_tech)
							files.UpdateTech(T, linked_destroy.loaded_item.origin_tech[T])
						if(linked_lathe && linked_destroy.loaded_item.matter) // Also sends salvaged materials to a linked protolathe, if any.
							for(var/t in linked_destroy.loaded_item.matter)
								if(t in linked_lathe.materials)
									linked_lathe.materials[t] += min(linked_lathe.max_material_storage - linked_lathe.TotalMaterials(), linked_destroy.loaded_item.matter[t] * linked_destroy.decon_mod)

						linked_destroy.loaded_item = null
						for(var/obj/I in linked_destroy.contents)
							for(var/mob/M in I.contents)
								M.death()
							if(istype(I,/obj/item/stack/material))//Only deconsturcts one sheet at a time instead of the entire stack
								var/obj/item/stack/material/S = I
								if(S.get_amount() > 1)
									S.use(1)
									linked_destroy.loaded_item = S
								else
									qdel(S)
									linked_destroy.icon_state = "d_analyzer"
							else
								if(I != linked_destroy.circuit && !(I in linked_destroy.component_parts))
									qdel(I)
									linked_destroy.icon_state = "d_analyzer"

						use_power(linked_destroy.active_power_usage)
						screen = 1.0
						updateUsrDialog()

	else if(href_list["lock"]) //Lock the console from use by anyone without tox access.
		if(allowed(usr))
			screen = text2num(href_list["lock"])
		else
			to_chat(usr, "Unauthorized Access.")

	else if(href_list["sync"]) //Sync the research holder with all the R&D consoles in the game that aren't sync protected.
		screen = 0.0
		if(!sync)
			to_chat(usr, "<span class='notice'>You must connect to the network first.</span>")
		else
			griefProtection() //Putting this here because I dont trust the sync process
			spawn(3 SECONDS)
				if(src)
					for(var/obj/machinery/r_n_d/server/S in machines)
						var/server_processed = 0
						if((id in S.id_with_upload) || istype(S, /obj/machinery/r_n_d/server/centcom))
							for(var/datum/tech/T in files.known_tech)
								S.files.AddTech2Known(T)
							for(var/datum/design/D in files.known_designs)
								S.files.AddDesign2Known(D)
							S.files.RefreshResearch()
							server_processed = 1
						if((id in S.id_with_download) && !istype(S, /obj/machinery/r_n_d/server/centcom))
							for(var/datum/tech/T in S.files.known_tech)
								files.AddTech2Known(T)
							for(var/datum/design/D in S.files.known_designs)
								files.AddDesign2Known(D)
							files.RefreshResearch()
							server_processed = 1
						if(!istype(S, /obj/machinery/r_n_d/server/centcom) && server_processed)
							S.produce_heat()
					screen = 1.6
					updateUsrDialog()

	else if(href_list["togglesync"]) //Prevents the console from being synced by other consoles. Can still send data.
		sync = !sync

	else if(href_list["build"]) //Causes the Protolathe to build something.
		if(linked_lathe)
			var/datum/design/being_built = null
			for(var/datum/design/D in files.known_designs)
				if(D.id == href_list["build"])
					being_built = D
					break
			if(being_built)
				linked_lathe.addToQueue(being_built)

	else if(href_list["buildfive"]) //Causes the Protolathe to build 5 of something.
		if(linked_lathe)
			var/datum/design/being_built = null
			for(var/datum/design/D in files.known_designs)
				if(D.id == href_list["buildfive"])
					being_built = D
					break
			if(being_built)
				for(var/i = 1 to 5)
					linked_lathe.addToQueue(being_built)

		screen = 3.1

	else if(href_list["protofilter"])
		var/filterstring = input(usr, "Input a filter string, or blank to not filter:", "Design Filter", protofilter) as null|text
		if(!Adjacent(usr))
			return
		if(isnull(filterstring)) //Clicked Cancel
			return
		if(filterstring == "") //Cleared value
			protofilter = null
		protofilter = sanitize(filterstring, 25)

	else if(href_list["circuitfilter"])
		var/filterstring = input(usr, "Input a filter string, or blank to not filter:", "Design Filter", circuitfilter) as null|text
		if(!Adjacent(usr))
			return
		if(isnull(filterstring)) //Clicked Cancel
			return
		if(filterstring == "") //Cleared value
			circuitfilter = null
		circuitfilter = sanitize(filterstring, 25)

	else if(href_list["imprint"]) //Causes the Circuit Imprinter to build something.
		if(linked_imprinter)
			var/datum/design/being_built = null
			for(var/datum/design/D in files.known_designs)
				if(D.id == href_list["imprint"])
					being_built = D
					break
			if(being_built)
				linked_imprinter.addToQueue(being_built)
		screen = 4.1

	else if(href_list["disposeI"] && linked_imprinter)  //Causes the circuit imprinter to dispose of a single reagent (all of it)
		linked_imprinter.reagents.del_reagent(href_list["dispose"])

	else if(href_list["disposeallI"] && linked_imprinter) //Causes the circuit imprinter to dispose of all it's reagents.
		linked_imprinter.reagents.clear_reagents()

	else if(href_list["removeI"] && linked_lathe)
		linked_imprinter.removeFromQueue(text2num(href_list["removeI"]))

	else if(href_list["disposeP"] && linked_lathe)  //Causes the protolathe to dispose of a single reagent (all of it)
		linked_lathe.reagents.del_reagent(href_list["dispose"])

	else if(href_list["disposeallP"] && linked_lathe) //Causes the protolathe to dispose of all it's reagents.
		linked_lathe.reagents.clear_reagents()

	else if(href_list["removeP"] && linked_lathe)
		linked_lathe.removeFromQueue(text2num(href_list["removeP"]))

	else if(href_list["lathe_ejectsheet"] && linked_lathe) //Causes the protolathe to eject a sheet of material
		linked_lathe.eject(href_list["lathe_ejectsheet"], text2num(href_list["amount"]))

	else if(href_list["imprinter_ejectsheet"] && linked_imprinter) //Causes the protolathe to eject a sheet of material
		linked_imprinter.eject(href_list["imprinter_ejectsheet"], text2num(href_list["amount"]))

	else if(href_list["find_device"]) //The R&D console looks for devices nearby to link up with.
		screen = 0.0
		spawn(10)
			SyncRDevices()
			screen = 1.7
			updateUsrDialog()

	else if(href_list["disconnect"]) //The R&D console disconnects with a specific device.
		switch(href_list["disconnect"])
			if("destroy")
				linked_destroy.linked_console = null
				linked_destroy = null
			if("lathe")
				linked_lathe.linked_console = null
				linked_lathe = null
			if("imprinter")
				linked_imprinter.linked_console = null
				linked_imprinter = null

	else if(href_list["reset"]) //Reset the R&D console's database.
		griefProtection()
		var/choice = alert("R&D Console Database Reset", "Are you sure you want to reset the R&D console's database? Data lost cannot be recovered.", "Continue", "Cancel")
		if(choice == "Continue")
			screen = 0.0
			qdel(files)
			files = new /datum/research(src)
			spawn(20)
				screen = 1.6
				updateUsrDialog()

	else if (href_list["print"]) //Print research information
		screen = 0.5
		spawn(20)
			var/obj/item/weapon/paper/PR = new/obj/item/weapon/paper
			PR.name = "list of researched technologies"
			PR.info = "<center><b>[station_name()] Science Laboratories</b>"
			PR.info += "<h2>[ (text2num(href_list["print"]) == 2) ? "Detailed" : null] Research Progress Report</h2>"
			PR.info += "<i>report prepared at [stationtime2text()] station time</i></center><br>"
			if(text2num(href_list["print"]) == 2)
				PR.info += GetResearchListInfo()
			else
				PR.info += GetResearchLevelsInfo()
			PR.info_links = PR.info
			PR.icon_state = "paper_words"
			PR.loc = src.loc
			spawn(10)
				screen = ((text2num(href_list["print"]) == 2) ? 5.0 : 1.1)
				updateUsrDialog()

	updateUsrDialog()
	return

/obj/machinery/computer/rdconsole/proc/GetResearchLevelsInfo()
	var/list/dat = list()
	dat += "<UL>"
	for(var/datum/tech/T in files.known_tech)
		if(T.level < 1)
			continue
		dat += "<LI>"
		dat += "[T.name]"
		dat += "<UL>"
		dat +=  "<LI>Level: [T.level]"
		dat +=  "<LI>Summary: [T.desc]"
		dat += "</UL>"
	return dat.Join()

/obj/machinery/computer/rdconsole/proc/GetResearchListInfo()
	var/list/dat = list()
	dat += "<UL>"
	for(var/datum/design/D in files.known_designs)
		if(D.build_path)
			dat += "<LI><B>[D.name]</B>: [D.desc]"
	dat += "</UL>"
	return dat.Join()

/obj/machinery/computer/rdconsole/proc/generate_ui()
	var/list/dat = list()

	switch(screen) //A quick check to make sure you get the right screen when a device is disconnected.
		if(2 to 2.9)
			if(linked_destroy == null)
				screen = 2.0
			else if(linked_destroy.loaded_item == null)
				screen = 2.1
			else
				screen = 2.2
		if(3 to 3.9)
			if(linked_lathe == null)
				screen = 3.0
		if(4 to 4.9)
			if(linked_imprinter == null)
				screen = 4.0

	switch(screen)

		//////////////////////R&D CONSOLE SCREENS//////////////////
		if(0.0)
			dat += "Updating Database..."

		if(0.1)
			dat += "Processing and Updating Database..."

		if(0.2)
			dat += "SYSTEM LOCKED<BR><BR>"
			dat += "<A href='?src=\ref[src];lock=1.6'>Unlock</A>"

		if(0.3)
			dat += "Constructing Prototype. Please Wait..."

		if(0.4)
			dat += "Imprinting Circuit. Please Wait..."

		if(0.5)
			dat += "Printing Research Information. Please Wait..."

		if(1.0) //Main Menu
			dat += "Main Menu:<BR><BR>"
			dat += "Loaded disk: "
			dat += (t_disk || d_disk) ? (t_disk ? "technology storage disk" : "design storage disk") : "none"
			dat += "<HR><UL>"
			dat += "<LI><A href='?src=\ref[src];menu=1.1'>Current Research Levels</A>"
			dat += "<LI><A href='?src=\ref[src];menu=5.0'>View Researched Technologies</A>"
			if(t_disk)
				dat += "<LI><A href='?src=\ref[src];menu=1.2'>Disk Operations</A>"
			else if(d_disk)
				dat += "<LI><A href='?src=\ref[src];menu=1.4'>Disk Operations</A>"
			else
				dat += "<LI><span class='linkOff'>Disk Operations</span>"
			if(linked_destroy)
				dat += "<LI><A href='?src=\ref[src];menu=2.2'>Destructive Analyzer Menu</A>"
			if(linked_lathe)
				dat += "<LI><A href='?src=\ref[src];menu=3.1'>Protolathe Construction Menu</A>"
			if(linked_imprinter)
				dat += "<LI><A href='?src=\ref[src];menu=4.1'>Circuit Construction Menu</A>"
			dat += "<LI><A href='?src=\ref[src];menu=1.6'>Settings</A>"
			dat += "</UL>"

		//////////////////// TECHWEB SCREENS ////////////////////////////
		if(1.1) //Research viewer

			if(RDSCREEN_TECHWEB)
				ui += ui_techweb()
			if(RDSCREEN_TECHWEB_NODEVIEW)
				ui += ui_techweb_nodeview()
			if(RDSCREEN_TECHWEB_DESIGNVIEW)
				ui += ui_techweb_designview()

			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];print=1'>Print This Page</A><HR>"
			dat += "Current Research Levels:<BR><BR>"
			dat += GetResearchLevelsInfo()
			dat += "</UL>"

		if(1.2) //Technology Disk Menu

			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "Disk Contents: (Technology Data Disk)<BR><BR>"
			if(t_disk.stored == null)
				dat += "The disk has no data stored on it.<HR>"
				dat += "Operations: "
				dat += "<A href='?src=\ref[src];menu=1.3'>Load Tech to Disk</A> || "
			else
				dat += "Name: [t_disk.stored.name]<BR>"
				dat += "Level: [t_disk.stored.level]<BR>"
				dat += "Description: [t_disk.stored.desc]<HR>"
				dat += "Operations: "
				dat += "<A href='?src=\ref[src];updt_tech=1'>Upload to Database</A> || "
				dat += "<A href='?src=\ref[src];clear_tech=1'>Clear Disk</A> || "
			dat += "<A href='?src=\ref[src];eject_tech=1'>Eject Disk</A>"

		if(1.3) //Technology Disk submenu
			dat += "<BR><A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=1.2'>Return to Disk Operations</A><HR>"
			dat += "Load Technology to Disk:<BR><BR>"
			dat += "<UL>"
			for(var/datum/tech/T in files.known_tech)
				dat += "<LI>[T.name] "
				dat += "\[<A href='?src=\ref[src];copy_tech=1;copy_tech_ID=[T.id]'>copy to disk</A>\]"
			dat += "</UL>"

		if(1.4) //Design Disk menu.
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			if(d_disk.blueprint == null)
				dat += "The disk has no data stored on it.<HR>"
				dat += "Operations: "
				dat += "<A href='?src=\ref[src];menu=1.5'>Load Design to Disk</A> || "
			else
				dat += "Name: [d_disk.blueprint.name]<BR>"
				switch(d_disk.blueprint.build_type)
					if(IMPRINTER) dat += "Lathe Type: Circuit Imprinter<BR>"
					if(PROTOLATHE) dat += "Lathe Type: Proto-lathe<BR>"
				dat += "Required Materials:<BR>"
				for(var/M in d_disk.blueprint.materials)
					if(copytext(M, 1, 2) == "$") dat += "* [copytext(M, 2)] x [d_disk.blueprint.materials[M]]<BR>"
					else dat += "* [M] x [d_disk.blueprint.materials[M]]<BR>"
				dat += "<HR>Operations: "
				dat += "<A href='?src=\ref[src];updt_design=1'>Upload to Database</A> || "
				dat += "<A href='?src=\ref[src];clear_design=1'>Clear Disk</A> || "
			dat += "<A href='?src=\ref[src];eject_design=1'>Eject Disk</A>"

		if(1.5) //Technology disk submenu
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=1.4'>Return to Disk Operations</A><HR>"
			dat += "Load Design to Disk:<BR><BR>"
			dat += "<UL>"
			for(var/datum/design/D in files.known_designs)
				if(D.build_path)
					dat += "<LI>[D.name] "
					dat += "<A href='?src=\ref[src];copy_design=1;copy_design_ID=[D.id]'>\[copy to disk\]</A>"
			dat += "</UL>"

		if(1.6) //R&D console settings
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "R&D Console Setting:<HR>"
			dat += "<UL>"
			if(sync)
				dat += "<LI><A href='?src=\ref[src];sync=1'>Sync Database with Network</A><BR>"
				dat += "<LI><A href='?src=\ref[src];togglesync=1'>Disconnect from Research Network</A><BR>"
			else
				dat += "<LI><A href='?src=\ref[src];togglesync=1'>Connect to Research Network</A><BR>"
			dat += "<LI><A href='?src=\ref[src];menu=1.7'>Device Linkage Menu</A><BR>"
			dat += "<LI><A href='?src=\ref[src];lock=0.2'>Lock Console</A><BR>"
			dat += "<LI><A href='?src=\ref[src];reset=1'>Reset R&D Database</A><BR>"
			dat += "<UL>"

		if(1.7) //R&D device linkage
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=1.6'>Settings Menu</A><HR>"
			dat += "R&D Console Device Linkage Menu:<BR><BR>"
			dat += "<A href='?src=\ref[src];find_device=1'>Re-sync with Nearby Devices</A><HR>"
			dat += "Linked Devices:"
			dat += "<UL>"
			if(linked_destroy)
				dat += "<LI>Destructive Analyzer <A href='?src=\ref[src];disconnect=destroy'>(Disconnect)</A>"
			else
				dat += "<LI>(No Destructive Analyzer Linked)"
			if(linked_lathe)
				dat += "<LI>Protolathe <A href='?src=\ref[src];disconnect=lathe'>(Disconnect)</A>"
			else
				dat += "<LI>(No Protolathe Linked)"
			if(linked_imprinter)
				dat += "<LI>Circuit Imprinter <A href='?src=\ref[src];disconnect=imprinter'>(Disconnect)</A>"
			else
				dat += "<LI>(No Circuit Imprinter Linked)"
			dat += "</UL>"

		////////////////////DESTRUCTIVE ANALYZER SCREENS////////////////////////////
		if(2.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "NO DESTRUCTIVE ANALYZER LINKED TO CONSOLE<BR><BR>"

		if(2.1)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "No Item Loaded. Standing-by...<BR><HR>"

		if(2.2)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "Deconstruction Menu<HR>"
			dat += "Name: [linked_destroy.loaded_item.name]<BR>"
			dat += "Origin Tech:"
			dat += "<UL>"
			for(var/T in linked_destroy.loaded_item.origin_tech)
				dat += "<LI>[CallTechName(T)] [linked_destroy.loaded_item.origin_tech[T]]"
				for(var/datum/tech/F in files.known_tech)
					if(F.name == CallTechName(T))
						dat += " (Current: [F.level])"
						break
			dat += "</UL>"
			dat += "<HR><A href='?src=\ref[src];deconstruct=1'>Deconstruct Item</A> || "
			dat += "<A href='?src=\ref[src];eject_item=1'>Eject Item</A> || "

		/////////////////////PROTOLATHE SCREENS/////////////////////////
		if(3.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "NO PROTOLATHE LINKED TO CONSOLE<BR><BR>"

		if(3.1)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.4'>View Queue</A> || "
			dat += "<A href='?src=\ref[src];menu=3.2'>Material Storage</A> || "
			dat += "<A href='?src=\ref[src];menu=3.3'>Chemical Storage</A><HR>"
			dat += "Protolathe Menu:<BR><BR>"
			dat += "<B>Material Amount:</B> [linked_lathe.TotalMaterials()] cm<sup>3</sup> (MAX: [linked_lathe.max_material_storage])<BR>"
			dat += "<B>Chemical Volume:</B> [linked_lathe.reagents.total_volume] (MAX: [linked_lathe.reagents.maximum_volume])<HR>"
			dat += "<UL>"
			dat += "<B>Filter:</B> <A href='?src=\ref[src];protofilter=1'>[protofilter ? protofilter : "None Set"]</A>"
			for(var/datum/design/D in files.known_designs)
				if(!D.build_path || !(D.build_type & PROTOLATHE))
					continue
				if(protofilter && findtext(D.name, protofilter) == 0)
					continue
				var/temp_dat
				for(var/M in D.materials)
					temp_dat += ", [D.materials[M]*linked_lathe.mat_efficiency] [CallMaterialName(M)]"
				for(var/T in D.chemicals)
					temp_dat += ", [D.chemicals[T]*linked_lathe.mat_efficiency] [CallReagentName(T)]"
				if(temp_dat)
					temp_dat = " \[[copytext(temp_dat, 3)]\]"
				if(linked_lathe.canBuild(D))
					dat += "<LI><B><A href='?src=\ref[src];build=[D.id]'>[D.name]</A></B>(<A href='?src=\ref[src];buildfive=[D.id]'>x5</A>)[temp_dat]"
				else
					dat += "<LI><B>[D.name]</B>[temp_dat]"
			dat += "</UL>"

		if(3.2) //Protolathe Material Storage Sub-menu
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.1'>Protolathe Menu</A><HR>"
			dat += "Material Storage<BR><HR>"
			dat += "<UL>"
			for(var/M in linked_lathe.materials)
				var/amount = linked_lathe.materials[M]
				var/hidden_mat = FALSE
				for(var/HM in linked_lathe.hidden_materials)
					if(M == HM && amount == 0)
						hidden_mat = TRUE
						break
				if(hidden_mat)
					continue
				dat += "<LI><B>[capitalize(M)]</B>: [amount] cm<sup>3</sup>"
				if(amount >= SHEET_MATERIAL_AMOUNT)
					dat += " || Eject "
					for (var/C in list(1, 3, 5, 10, 15, 20, 25, 30, 40))
						if(amount < C * SHEET_MATERIAL_AMOUNT)
							break
						dat += "[C > 1 ? ", " : ""]<A href='?src=\ref[src];lathe_ejectsheet=[M];amount=[C]'>[C]</A> "

					dat += " or <A href='?src=\ref[src];lathe_ejectsheet=[M];amount=50'>max</A> sheets"
				dat += ""
			dat += "</UL>"

		if(3.3) //Protolathe Chemical Storage Submenu
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.1'>Protolathe Menu</A><HR>"
			dat += "Chemical Storage:<BR><HR>"
			for(var/datum/reagent/R in linked_lathe.reagents.reagent_list)
				dat += "Name: [R.name] | Units: [R.volume] "
				dat += "<A href='?src=\ref[src];disposeP=[R.id]'>(Purge)</A><BR>"
				dat += "<A href='?src=\ref[src];disposeallP=1'><U>Disposal All Chemicals in Storage</U></A><BR>"

		if(3.4) // Protolathe queue
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.1'>Protolathe Menu</A><HR>"
			dat += "Protolathe Construction Queue:<BR><HR>"
			if(!linked_lathe.queue.len)
				dat += "Empty"
			else
				var/tmp = 1
				for(var/datum/design/D in linked_lathe.queue)
					if(tmp == 1)
						if(linked_lathe.busy)
							dat += "<B>1: [D.name]</B><BR>"
						else
							dat += "<B>1: [D.name]</B> (Awaiting materials) <A href='?src=\ref[src];removeP=[tmp]'>(Remove)</A><BR>"
					else
						dat += "[tmp]: [D.name] <A href='?src=\ref[src];removeP=[tmp]'>(Remove)</A><BR>"
					++tmp

		///////////////////CIRCUIT IMPRINTER SCREENS////////////////////
		if(4.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "NO CIRCUIT IMPRINTER LINKED TO CONSOLE<BR><BR>"

		if(4.1)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.4'>View Queue</A> || "
			dat += "<A href='?src=\ref[src];menu=4.3'>Material Storage</A> || "
			dat += "<A href='?src=\ref[src];menu=4.2'>Chemical Storage</A><HR>"
			dat += "Circuit Imprinter Menu:<BR><BR>"
			dat += "Material Amount: [linked_imprinter.TotalMaterials()] cm<sup>3</sup><BR>"
			dat += "Chemical Volume: [linked_imprinter.reagents.total_volume]<HR>"
			dat += "<UL>"
			dat += "<B>Filter:</B> <A href='?src=\ref[src];circuitfilter=1'>[circuitfilter ? circuitfilter : "None Set"]</A>"
			for(var/datum/design/D in files.known_designs)
				if(!D.build_path || !(D.build_type & IMPRINTER))
					continue
				if(circuitfilter && findtext(D.name, circuitfilter) == 0)
					continue
				var/temp_dat
				for(var/M in D.materials)
					temp_dat += ", [D.materials[M]*linked_imprinter.mat_efficiency] [CallMaterialName(M)]"
				for(var/T in D.chemicals)
					temp_dat += ", [D.chemicals[T]*linked_imprinter.mat_efficiency] [CallReagentName(T)]"
				if(temp_dat)
					temp_dat = " \[[copytext(temp_dat,3)]\]"
				if(linked_imprinter.canBuild(D))
					dat += "<LI><B><A href='?src=\ref[src];imprint=[D.id]'>[D.name]</A></B>[temp_dat]"
				else
					dat += "<LI><B>[D.name]</B>[temp_dat]"
			dat += "</UL>"

		if(4.2)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.1'>Imprinter Menu</A><HR>"
			dat += "Chemical Storage<BR><HR>"
			for(var/datum/reagent/R in linked_imprinter.reagents.reagent_list)
				dat += "Name: [R.name] | Units: [R.volume] "
				dat += "<A href='?src=\ref[src];disposeI=[R.id]'>(Purge)</A><BR>"
				dat += "<A href='?src=\ref[src];disposeallI=1'><U>Disposal All Chemicals in Storage</U></A><BR>"

		if(4.3)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.1'>Circuit Imprinter Menu</A><HR>"
			dat += "Material Storage<BR><HR>"
			dat += "<UL>"
			for(var/M in linked_imprinter.materials)
				var/amount = linked_imprinter.materials[M]
				var/hidden_mat = FALSE
				for(var/HM in linked_imprinter.hidden_materials)
					if(M == HM && amount == 0)
						hidden_mat = TRUE
						break
				if(hidden_mat)
					continue
				dat += "<LI><B>[capitalize(M)]</B>: [amount] cm<sup>3</sup>"
				if(amount >= SHEET_MATERIAL_AMOUNT)
					dat += " || Eject: "
					for (var/C in list(1, 3, 5, 10, 15, 20, 25, 30, 40))
						if(amount < C * SHEET_MATERIAL_AMOUNT)
							break
						dat += "[C > 1 ? ", " : ""]<A href='?src=\ref[src];imprinter_ejectsheet=[M];amount=[C]'>[C]</A> "

					dat += " or <A href='?src=\ref[src];imprinter_ejectsheet=[M];amount=50'>max</A> sheets"
				dat += ""
			dat += "</UL>"

		if(4.4)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.1'>Circuit Imprinter Menu</A><HR>"
			dat += "Queue<BR><HR>"
			if(linked_imprinter.queue.len == 0)
				dat += "Empty"
			else
				var/tmp = 1
				for(var/datum/design/D in linked_imprinter.queue)
					if(tmp == 1)
						dat += "<B>1: [D.name]</B><BR>"
					else
						dat += "[tmp]: [D.name] <A href='?src=\ref[src];removeI=[tmp]'>(Remove)</A><BR>"
					++tmp

		///////////////////Research Information Browser////////////////////
		if(5.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];print=2'>Print This Page</A><HR>"
			dat += "List of Researched Technologies and Designs:"
			dat += GetResearchListInfo()

	return jointext(dat, null)



/obj/machinery/computer/rdconsole/proc/ui_deconstruct()		//Legacy code
	RDSCREEN_UI_DECONSTRUCT_CHECK
	var/list/l = list()
	if(!linked_destroy.loaded_item)
		l += "<div class='statusDisplay'>No item loaded. Standing-by...</div>"
	else
		l += "<div class='statusDisplay'>[RDSCREEN_NOBREAK]"
		l += "<table><tr><td>[bicon(linked_destroy.loaded_item)]</td><td><b>[linked_destroy.loaded_item.name]</b> <A href='?src=[REF(src)];eject_item=1'>Eject</A></td></tr></table>[RDSCREEN_NOBREAK]"
		l += "Select a node to boost by deconstructing this item. This item can boost:"

		var/anything = FALSE
		var/list/boostable_nodes = techweb_item_boost_check(linked_destroy.loaded_item)
		for(var/id in boostable_nodes)
			anything = TRUE
			var/list/worth = boostable_nodes[id]
			var/datum/techweb_node/N = SSresearch.techweb_node_by_id(id)

			l += "<div class='statusDisplay'>[RDSCREEN_NOBREAK]"
			if (stored_research.researched_nodes[N.id])  // already researched
				l += "<span class='linkOff'>[N.display_name]</span>"
				l += "This node has already been researched."
			else if(!length(worth))  // reveal only
				if (stored_research.hidden_nodes[N.id])
					l += "<A href='?src=[REF(src)];deconstruct=[N.id]'>[N.display_name]</A>"
					l += "This node will be revealed."
				else
					l += "<span class='linkOff'>[N.display_name]</span>"
					l += "This node has already been revealed."
			else  // boost by the difference
				var/list/differences = list()
				var/list/already_boosted = stored_research.boosted_nodes[N.id]
				for(var/i in worth)
					var/already_boosted_amount = already_boosted? stored_research.boosted_nodes[N.id][i] : 0
					var/amt = min(worth[i], N.research_costs[i]) - already_boosted_amount
					if(amt > 0)
						differences[i] = amt
				if (length(differences))
					l += "<A href='?src=[REF(src)];deconstruct=[N.id]'>[N.display_name]</A>"
					l += "This node will be boosted with the following:<BR>[techweb_point_display_generic(differences)]"
				else
					l += "<span class='linkOff'>[N.display_name]</span>"
					l += "This node has already been boosted.</span>"
			l += "</div>[RDSCREEN_NOBREAK]"

		// point deconstruction and material reclamation use the same ID to prevent accidentally missing the points
		var/list/point_values = techweb_item_point_check(linked_destroy.loaded_item)
		if(point_values)
			anything = TRUE
			l += "<div class='statusDisplay'>[RDSCREEN_NOBREAK]"
			if (stored_research.deconstructed_items[linked_destroy.loaded_item.type])
				l += "<span class='linkOff'>Point Deconstruction</span>"
				l += "This item's points have already been claimed."
			else
				l += "<A href='?src=[REF(src)];deconstruct=[RESEARCH_MATERIAL_RECLAMATION_ID]'>Point Deconstruction</A>"
				l += "This item is worth: <BR>[techweb_point_display_generic(point_values)]!"
			l += "</div>[RDSCREEN_NOBREAK]"

		else if(!(linked_destroy.loaded_item.unacidable))
			var/list/materials = linked_destroy.loaded_item.matter
			l += "<div class='statusDisplay'><A href='?src=[REF(src)];deconstruct=[RESEARCH_MATERIAL_RECLAMATION_ID]'>[LAZYLEN(materials)? "Material Reclamation" : "Destroy Item"]</A>"
			for (var/M in materials)
				l += "* [CallMaterialName(M)] x [materials[M]]"
			l += "</div>[RDSCREEN_NOBREAK]"
			anything = TRUE

		if (!anything)
			l += "Nothing!"

		l += "</div>"
	return l

/obj/machinery/computer/rdconsole/proc/ui_techweb()
	var/list/l = list()
	if(ui_mode != RDCONSOLE_UI_MODE_LIST)
		var/list/columns = list()
		var/max_tier = 0
		for (var/node_ in stored_research.tiers)
			var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_)
			var/tier = stored_research.tiers[node.id]
			LAZYINITLIST(columns["[tier]"])  // String hackery to make the numbers associative
			columns["[tier]"] += ui_techweb_single_node(node, minimal=(tier != 1))
			max_tier = max(max_tier, tier)

		l += "<table><tr><th align='left'>Researched</th><th align='left'>Available</th><th align='left'>Future</th></tr><tr>[RDSCREEN_NOBREAK]"
		if(max_tier)
			for(var/tier in 0 to max_tier)
				l += "<td valign='top'>[RDSCREEN_NOBREAK]"
				l += columns["[tier]"]
				l += "</td>[RDSCREEN_NOBREAK]"
		l += "</tr></table>[RDSCREEN_NOBREAK]"
	else
		var/list/avail = list()			//This could probably be optimized a bit later.
		var/list/unavail = list()
		var/list/res = list()
		for(var/v in stored_research.researched_nodes)
			res += SSresearch.techweb_node_by_id(v)
		for(var/v in stored_research.available_nodes)
			if(stored_research.researched_nodes[v] || stored_research.hidden_nodes[v])
				continue
			avail += SSresearch.techweb_node_by_id(v)
		for(var/v in stored_research.visible_nodes)
			if(stored_research.available_nodes[v])
				continue
			unavail += SSresearch.techweb_node_by_id(v)
		l += "<h2>Technology Nodes:</h2>[RDSCREEN_NOBREAK]"
		l += "<div><h3>Available for Research:</h3>"
		for(var/datum/techweb_node/N in avail)
			var/not_unlocked = (stored_research.available_nodes[N.id] && !stored_research.researched_nodes[N.id])
			var/has_points = (stored_research.can_afford(N.get_price(stored_research)))
			var/research_href = not_unlocked? (has_points? "<A href='?src=[REF(src)];research_node=[N.id]'>Research</A>" : "<span class='linkOff bad'>Not Enough Points</span>") : null
			l += "<A href='?src=[REF(src)];view_node=[N.id];back_screen=[screen]'>[N.display_name]</A>[research_href]"
		l += "</div><div><h3>Locked Nodes:</h3>"
		for(var/datum/techweb_node/N in unavail)
			l += "<A href='?src=[REF(src)];view_node=[N.id];back_screen=[screen]'>[N.display_name]</A>"
		l += "</div><div><h3>Researched Nodes:</h3>"
		for(var/datum/techweb_node/N in res)
			l += "<A href='?src=[REF(src)];view_node=[N.id];back_screen=[screen]'>[N.display_name]</A>"
		l += "</div>[RDSCREEN_NOBREAK]"
	return l


/obj/machinery/computer/rdconsole/proc/machine_icon(atom/item)
	return bicon(icon(initial(item.icon), icon_state=initial(item.icon_state), dir=SOUTH))

/obj/machinery/computer/rdconsole/proc/ui_techweb_single_node(datum/techweb_node/node, selflink=TRUE, minimal=FALSE)
	var/list/l = list()
	if (stored_research.hidden_nodes[node.id])
		return l
	var/display_name = node.display_name
	if (selflink)
		display_name = "<A href='?src=[REF(src)];view_node=[node.id];back_screen=[screen]'>[display_name]</A>"
	l += "<div class='statusDisplay technode'><b>[display_name]</b> [RDSCREEN_NOBREAK]"
	if(minimal)
		l += "<br>[node.description]"
	else
		if(stored_research.researched_nodes[node.id])
			l += "<span class='linkOff'>Researched</span>"
		else if(stored_research.available_nodes[node.id])
			if(stored_research.can_afford(node.get_price(stored_research)))
				l += "<BR><A href='?src=[REF(src)];research_node=[node.id]'>[node.price_display(stored_research)]</A>"
			else
				l += "<BR><span class='linkOff'>[node.price_display(stored_research)]</span>"  // gray - too expensive
		else
			l += "<BR><span class='linkOff bad'>[node.price_display(stored_research)]</span>"  // red - missing prereqs
		if(ui_mode == RDCONSOLE_UI_MODE_NORMAL)
			l += "[node.description]"
			for(var/i in node.design_ids)
				var/datum/design/D = SSresearch.techweb_design_by_id(i)
				l += "<span data-tooltip='[D.name]' onclick='location=\"?src=[REF(src)];view_design=[i];back_screen=[screen]\"'>[D.icon_html(usr)]</span>[RDSCREEN_NOBREAK]"
	l += "</div>[RDSCREEN_NOBREAK]"
	return l

/obj/machinery/computer/rdconsole/proc/ui_techweb_nodeview()
	var/datum/techweb_node/selected_node = SSresearch.techweb_node_by_id(selected_node_id)
	RDSCREEN_UI_SNODE_CHECK
	var/list/l = list()
	if(stored_research.hidden_nodes[selected_node.id])
		l += "<div><h3>ERROR: RESEARCH NODE UNKNOWN.</h3></div>"
		return

	l += "<table><tr>[RDSCREEN_NOBREAK]"
	if (length(selected_node.prereq_ids))
		l += "<th align='left'>Requires</th>[RDSCREEN_NOBREAK]"
	l += "<th align='left'>Current Node</th>[RDSCREEN_NOBREAK]"
	if (length(selected_node.unlock_ids))
		l += "<th align='left'>Unlocks</th>[RDSCREEN_NOBREAK]"

	l += "</tr><tr>[RDSCREEN_NOBREAK]"
	if (length(selected_node.prereq_ids))
		l += "<td valign='top'>[RDSCREEN_NOBREAK]"
		for (var/i in selected_node.prereq_ids)
			l += ui_techweb_single_node(SSresearch.techweb_node_by_id(i))
		l += "</td>[RDSCREEN_NOBREAK]"
	l += "<td valign='top'>[RDSCREEN_NOBREAK]"
	l += ui_techweb_single_node(selected_node, selflink=FALSE)
	l += "</td>[RDSCREEN_NOBREAK]"
	if (length(selected_node.unlock_ids))
		l += "<td valign='top'>[RDSCREEN_NOBREAK]"
		for (var/i in selected_node.unlock_ids)
			l += ui_techweb_single_node(SSresearch.techweb_node_by_id(i))
		l += "</td>[RDSCREEN_NOBREAK]"

	l += "</tr></table>[RDSCREEN_NOBREAK]"
	return l

/obj/machinery/computer/rdconsole/proc/ui_techweb_designview()	














/obj/machinery/computer/rdconsole/attack_hand(mob/user as mob)
	if((. = ..()))
		return
		
	var/datum/asset/iconsheet/sheet = get_asset_datum(/datum/asset/iconsheet/research_designs)
	sheet.send(user) // In case they don't have it!

	user.set_machine(src)
	var/datum/browser/popup = new(user, "rndconsole", "Research and Development Console", 900, 600)
	popup.add_stylesheet("techwebs", 'html/browser/techwebs.css')
	popup.add_head_content(icon_assets.css_tag())
	popup.set_content(generate_ui())
	popup.open()

/obj/machinery/computer/rdconsole/robotics
	name = "Robotics R&D Console"
	id = 2
	req_access = list(access_robotics)

/obj/machinery/computer/rdconsole/core
	name = "Core R&D Console"
	id = 1
