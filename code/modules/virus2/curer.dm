/////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star October 2026: Computer and Related Machinery Idle Processing //
/////////////////////////////////////////////////////////////////////////////////////////////////

/obj/machinery/computer/curer
	processing_enabled = TRUE // RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
	processing_on_demand = TRUE // RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
	name = "cure research machine"
	icon_keyboard = "med_key"
	icon_screen = "dna"
	circuit = /obj/item/weapon/circuitboard/curefab
	var/curing
	var/virusing

	var/obj/item/weapon/reagent_containers/container = null

/obj/machinery/computer/curer/attackby(var/obj/I as obj, var/mob/user as mob)
	if(istype(I,/obj/item/weapon/reagent_containers))
		var/mob/living/carbon/C = user
		if(!container)
			container = I
			C.drop_item()
			I.loc = src
		return
	if(istype(I,/obj/item/weapon/virusdish))
		if(virusing)
			to_chat(user, "<b>The pathogen materializer is still recharging..</b>")
			return
		var/obj/item/weapon/reagent_containers/glass/beaker/product = new(src.loc)

		var/list/data = list("donor"=null,"viruses"=null,"blood_DNA"=null,"blood_type"=null,"resistances"=null,"trace_chem"=null,"virus2"=list(),"antibodies"=list())
		data["virus2"] |= I:virus2
		product.reagents.add_reagent("blood",30,data)

		virusing = 1
		spawn(1200) virusing = 0

		state("The [src.name] Buzzes", "blue")
		return
	..()
	return

/obj/machinery/computer/curer/attack_ai(var/mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/curer/attack_hand(var/mob/user as mob)
	if(..())
		return
	user.machine = src
	var/dat
	if(curing)
		dat = "Antibody production in progress"
	else if(virusing)
		dat = "Virus production in progress"
	else if(container)
		// see if there's any blood in the container
		var/datum/reagent/blood/B = locate(/datum/reagent/blood) in container.reagents.reagent_list

		if(B)
			dat = "Blood sample inserted."
			dat += "<BR>Antibodies: [antigens2string(B.data["antibodies"])]"
			dat += "<BR><A href='?src=\ref[src];antibody=1'>Begin antibody production</a>"
		else
			dat += "<BR>Please check container contents."
		dat += "<BR><A href='?src=\ref[src];eject=1'>Eject container</a>"
	else
		dat = "Please insert a container."

	user << browse(dat, "window=computer;size=400x500")
	onclose(user, "computer")
	return

// RS Edit: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/curer/process()
	..()
	update_cure_power()
	if(stat & (NOPOWER|BROKEN) || !curing)
		return PROCESS_KILL

	if(curing)
		curing -= 1
		if(curing == 0)
			if(container)
				createcure(container)
	if(!curing)
		return PROCESS_KILL
	return

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/curer/proc/update_cure_power()
	var/extra_power = 500
	if(speed_process)
		extra_power *= SSmachines.wait / SSfastprocess.wait
	update_active_power_usage(idle_power_usage + extra_power)
	update_use_power(stat & (NOPOWER|BROKEN) ? USE_POWER_IDLE : USE_POWER_ACTIVE)

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/curer/power_change()
	. = ..()
	update_cure_power()

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/curer/set_broken()
	. = ..()
	update_cure_power()

// RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
/obj/machinery/computer/curer/set_processing_speed(new_speed)
	. = ..()
	update_cure_power()

/obj/machinery/computer/curer/Topic(href, href_list)
	if(..())
		return 1
	usr.machine = src

	if (href_list["antibody"])
		curing = 10
		wake_processing() // RS Add: Computer and Related Machinery Idle Processing (Lira, October 2026)
	else if(href_list["eject"])
		container.loc = src.loc
		container = null

	src.add_fingerprint(usr)
	src.updateUsrDialog()


/obj/machinery/computer/curer/proc/createcure(var/obj/item/weapon/reagent_containers/container)
	var/obj/item/weapon/reagent_containers/glass/beaker/product = new(src.loc)

	var/datum/reagent/blood/B = locate() in container.reagents.reagent_list

	var/list/data = list()
	data["antibodies"] = B.data["antibodies"]
	product.reagents.add_reagent("antibodies",30,data)

	state("\The [src.name] buzzes", "blue")
