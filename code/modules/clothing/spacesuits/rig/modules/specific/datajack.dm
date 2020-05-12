/obj/item/rig_module/datajack

	name = "datajack module"
	desc = "A simple induction datalink module."
	icon_state = "datajack"
	toggleable = 1
	activates_on_touch = 1
	usable = 0

	activate_string = "Enable Datajack"
	deactivate_string = "Disable Datajack"

	interface_name = "contact datajack"
	interface_desc = "An induction-powered high-throughput datalink suitable for hacking encrypted networks."
	var/datum/techweb/stored_research

/obj/item/rig_module/datajack/New()
	..()
	stored_research = new()

/obj/item/rig_module/datajack/engage(atom/target)

	if(!..())
		return 0

	if(target)
		var/mob/living/carbon/human/H = holder.wearer
		if(!accepts_item(target,H))
			return 0
	return 1

/obj/item/rig_module/datajack/accepts_item(var/obj/item/input_device, var/mob/living/user)

	if(istype(input_device,/obj/item/weapon/disk/tech_disk))
		var/obj/item/weapon/disk/tech_disk/TD = input_device
		var/has_research = FALSE
		for(var/node in TD.stored_research.researched_nodes)
			if(!stored_research.researched_nodes[node])
				has_research = TRUE
				break
		if(has_research)//If it has something on it.
			to_chat(user, "<span class='notice'>Research information detected, processing...</span>")
			if(do_after(user, 2 SECONDS, target = src))
				TD.stored_research.copy_research_to(stored_research)
				qdel(TD.stored_research)
				TD.stored_research = new
				to_chat(user, "<span class='notice'>Data analyzed and updated. Disk erased.</span>")
			else
				to_chat(user, "<span class='userdanger'>ERROR</span>: Procedure interrupted. Process terminated.")
		else
			to_chat(user, "<span class='notice'>No new research information detected.</span>")
		return 1

	// // I fucking hate R&D code. This typecheck spam would be totally unnecessary in a sane setup. Sanity? This is BYOND.
	// else if(istype(input_device,/obj/machinery))
	// 	var/datum/research/incoming_files
	// 	if(istype(input_device,/obj/machinery/computer/rdconsole) ||\
	// 		istype(input_device,/obj/machinery/rnd/server) ||\
	// 		istype(input_device,/obj/machinery/mecha_part_fabricator))

	// 		incoming_files = input_device:files

	// 	if(!incoming_files || !incoming_files.known_tech || !incoming_files.known_tech.len)
	// 		to_chat(user, "<span class='warning'>Memory failure. There is nothing accessible stored on this terminal.</span>")
	// 	else
	// 		// Maybe consider a way to drop all your data into a target repo in the future.
	// 		if(load_data(incoming_files.known_tech))
	// 			to_chat(user, "<font color='blue'>Download successful; local and remote repositories synchronized.</font>")
	// 		else
	// 			to_chat(user, "<span class='warning'>Scan complete. There is nothing useful stored on this terminal.</span>")
	// 	return 1
	return 0
