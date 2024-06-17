// BUILDABLE SMES(Superconducting Magnetic Energy Storage) UNIT
//
// Last Change 2.8.2018 by Neerti. Also signing this is still dumb.
// Power System Overhaul by Poojawa 5/2024. Yes it was that long.
// These subtypes of SMES are for mapping helping. The real SMES unit is buildable. Why would you have a subtype for a single machine...


//MAGNETIC COILS - These things actually store and transmit power within the SMES. Different types have different effects.
//Also the math is just completely fucked. Good luck - Pooj
/obj/item/weapon/smes_coil
	name = "superconductive magnetic coil"
	desc = "The standard superconductive magnetic coil, with average capacity and I/O rating."
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "smes_coil"			// Just few icons patched together. If someone wants to make better icon, feel free to do so!
	w_class = ITEMSIZE_LARGE 						// It's LARGE (backpack size)
	var/ChargeCapacity = 6 MEGAWATTS		// 100 kWh was 6000000
	var/IOCapacity = 250 KILOWATTS				// 250 kW

// 20% Charge Capacity, 60% I/O Capacity. Used for substation/outpost SMESs.
/obj/item/weapon/smes_coil/weak
	name = "basic superconductive magnetic coil"
	desc = "A cheaper model of superconductive magnetic coil. Its capacity and I/O rating are considerably lower."
	icon_state = "smes_coil_weak"
	ChargeCapacity = 1.2 MEGAWATTS		// 20 kWh was 1200000
	IOCapacity = 150 KILOWATTS			// 150 kW

// x10 Charge Capacity, 20% I/O Capacity
/obj/item/weapon/smes_coil/super_capacity
	name = "superconductive capacitance coil"
	desc = "A specialised type of superconductive magnetic coil with a significantly stronger containment field, allowing for larger power storage. Its IO rating is much lower, however."
	icon_state = "smes_coil_capacitance"
	ChargeCapacity = 60 MEGAWATTS		// 1000 kWh was 60000000
	IOCapacity = 50 KILOWATTS			// 50 kW

// 10% Charge Capacity, 400% I/O Capacity. Technically turns SMES into large super capacitor.Ideal for shields.
/obj/item/weapon/smes_coil/super_io
	name = "superconductive transmission coil"
	desc = "A specialised type of superconductive magnetic coil with reduced storage capabilites but vastly improved power transmission capabilities, making it useful in systems which require large throughput."
	icon_state = "smes_coil_transmission"
	ChargeCapacity = 600 KILOWATTS		// 10 kWh was 600000
	IOCapacity = 1 MEGAWATTS			// 1000 kW


// SMES SUBTYPES - THESE ARE MAPPED IN AND CONTAIN DIFFERENT TYPES OF COILS
// Generics for Station Mapping
/obj/machinery/power/smes/preset
	input_level = SMESSTARTCHARGELVL	//50kW
	output_level = SMESSTARTOUTLVL		//50kW
	charge = 0							//Give the engine reason to be started

/obj/machinery/power/smes/preset/engine
	name = "Engine Core SMES"
	charge = 3 MEGAWATTS
	RCon_tag = "Engine - Core"
	input_level = SMESMAXCHARGELEVEL
	output_level = SMESMAXOUTPUT

/obj/machinery/power/smes/preset/engine/Initialize()
	. = ..()
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil/super_capacity(src)
	recalc_coils()

/obj/machinery/power/smes/preset/mains
	name = "Main Power SMES"
	input_attempt = FALSE
	inputting = FALSE	//To prevent the mains from draining all of the engine power prior to engine setup
	charge = 20 MEGAWATTS
	RCon_tag = "Power - Main"
	output_level = 1 MEGAWATTS

// Mains gets a little extra snowflake to help early rounds when no engineers are around, mostly for outputting
// This is about the same amount with previous dirty var editing.
/obj/machinery/power/smes/preset/mains/Initialize()
	. = ..()
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil/super_capacity(src)
	recalc_coils()

/obj/machinery/power/smes/preset/ai_tcomm
	name = "AI-TCOMM SMES"
	charge = 50 MEGAWATTS	//maximum charge for AI/TComms to account for previous changes
	inputting = TRUE
	input_level = SMESMAXCHARGELEVEL
	outputting = TRUE
	output_level = SMESMAXOUTPUT
	RCon_tag = "Substation - AI/Telecomms"

/obj/machinery/power/smes/preset/ai_tcomm/Initialize()
	. = ..()
	component_parts += new /obj/item/weapon/smes_coil/super_capacity(src)
	component_parts += new /obj/item/weapon/smes_coil(src)
	component_parts += new /obj/item/weapon/smes_coil(src)
	component_parts += new /obj/item/weapon/smes_coil(src)
	recalc_coils()

/obj/machinery/power/smes/preset/substation
	input_attempt = FALSE
	inputting = FALSE
	output_attempt = FALSE
	outputting = FALSE
	max_coils = 3	//half as many as a regular SMES, so people can upgrade them but the mains are still better.

//Generic Shuttle SMES
/obj/machinery/power/smes/preset/shuttle
	charge = 1 MEGAWATTS	//enough to get started, but preflight should include topping off the reserves
	input_attempt = FALSE
	inputting = FALSE
	output_attempt = FALSE
	outputting = FALSE

//Creative mode infinite memes
/obj/machinery/power/smes/magical
	name = "Redspace Conductive SMES"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit. Magically produces power."
	capacity = 9 MEGAWATTS
	output_level = SMESMAXOUTPUT
	should_be_mapped = FALSE

/obj/machinery/power/smes/magical/Initialize()
	. = ..()
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil/super_capacity(src)
	recalc_coils()

/obj/machinery/power/smes/magical/process()
	charge = 9 MEGAWATTS
	..()

// These are used on individual outposts as backup should power line be cut, or engineering outpost lost power.
// 1M Charge, 150K I/O
/obj/machinery/power/smes/outpost_substation/Initialize()
	. = ..()
	component_parts += new /obj/item/weapon/smes_coil/weak(src)
	recalc_coils()

// This one is pre-installed on engineering shuttle. Allows rapid charging/discharging for easier transport of power to outpost
// 11M Charge, 2.5M I/O
/obj/machinery/power/smes/power_shuttle/Initialize()
	. = ..()
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil/super_io(src)
	component_parts += new /obj/item/weapon/smes_coil(src)
	recalc_coils()

// Pre-installed and pre-charged SMES hidden from the station, for use in submaps.
/obj/machinery/power/smes/point_of_interest/Initialize()
	. = ..()
	charge = capacity // Should be enough for an individual POI.
	RCon = FALSE
	input_level = input_level_max
	output_level = output_level_max
	input_attempt = TRUE

//snowflake SMES that could do with actual alien sprites
/obj/machinery/power/smes/hybrid
	name = "Redspace Conductive SMES"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit, modified with alien technology to generate small amounts of power from seemingly nowhere."
	var/recharge_rate = 10 KILOWATTS

/obj/machinery/power/smes/hybrid/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(W.is_screwdriver() || W.is_wirecutter())
		to_chat(user,"<span class='warning'>\The [src] full of weird alien technology that's best not messed with.</span>")
		return FALSE

/obj/machinery/power/smes/hybrid/process()
	charge += min(recharge_rate, capacity - charge)
	..()

// END SMES SUBTYPES
