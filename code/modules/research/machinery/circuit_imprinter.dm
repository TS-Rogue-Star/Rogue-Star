/obj/machinery/rnd/production/circuit_imprinter
	name = "circuit imprinter"
	desc = "Manufactures circuit boards for the construction of machines."
	icon_state = "circuit_imprinter"
	circuit = /obj/item/weapon/circuitboard/circuit_imprinter
	idle_power_usage = 30
	active_power_usage = 2500
	categories = list(
								"AI Modules",
								"Computer Boards",
								"Teleportation Machinery",
								"Medical Machinery",
								"Engineering Machinery",
								"Exosuit Modules",
								"Hydroponics Machinery",
								"Subspace Telecomms",
								"Research Machinery",
								"Misc. Machinery",
								"Computer Parts"
								)
	production_animation = "circuit_imprinter_p"
	production_done_animation = "circuit_imprinter_ani"
	allowed_buildtypes = IMPRINTER

/obj/machinery/rnd/production/circuit_imprinter/disconnect_console()
	linked_console.linked_imprinter = null
	..()

/obj/machinery/rnd/production/circuit_imprinter/calculate_efficiency()
	. = ..()
	var/total_rating = 0
	for(var/obj/item/weapon/stock_parts/manipulator/M in component_parts)
		total_rating += M.rating // There is only one in imprinters
	efficiency_coeff = 1/max(1 - (total_rating - 1) / 4, 0.2)
	build_speed = total_rating
