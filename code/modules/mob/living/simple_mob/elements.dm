/mob/living/simple_mob
	var/sm_element = "c"

/mob/living/simple_mob/vore/e/engine
	name = "Electric guy"
	desc = "It looks pretty fluffy!"

	sm_element = "e"
	var/energy_charge = 0
	var/discharge = FALSE

	var/datum/powernet/PN
	var/obj/structure/cable/attached


/mob/living/simple_mob/vore/e/engine/Life()
	. = ..()

	if(discharge)

	else if(nutrition >= 300)
		energy_charge += 100
		nutrition -= 1

	else if(energy_charge >= 1000)
		discharge = TRUE

/mob/living/simple_mob/vore/solargrub/Life()
	. = ..()
	if(!.) return

	if(!ai_holder.target)
			//first, check for potential cables nearby to powersink
		var/turf/S = loc
		attached = locate(/obj/structure/cable) in S
		if(attached)
			set_AI_busy(TRUE)
			if(prob(2))
				src.visible_message("<b>\The [src]</b> begins to sink power from the net.")
			if(prob(5))
				var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
				sparks.set_up(5, 0, get_turf(src))
				sparks.start()
			anchored = TRUE
			PN = attached.powernet
			PN.draw_power(100000) // previous value 150000
			var/apc_drain_rate = 750 //Going to see if grubs are better as a minimal bother. previous value : 4000
			for(var/obj/machinery/power/terminal/T in PN.nodes)
				if(istype(T.master, /obj/machinery/power/apc))
					var/obj/machinery/power/apc/A = T.master
					if(A.operating && A.cell)
						var/cur_charge = A.cell.charge / CELLRATE
						var/drain_val = min(apc_drain_rate, cur_charge)
						A.cell.use(drain_val * CELLRATE)
		else if(!attached && anchored)
			anchored = FALSE
			PN = null
