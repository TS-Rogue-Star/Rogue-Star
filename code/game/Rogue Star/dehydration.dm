//RS FILE
/datum/reagent/dry
	name = "dehydrated nutrint mix"
	id = "dryfood"
	description = "A specialised chemical mix that, once activated will expand into a prepared food item! Ingesting this before adding water is not advised, as the chemical reaction will take water from the body and dehydrate the imbiber."
	taste_description = "meat chalk"
	reagent_state = SOLID
	color = "#523026"

/datum/reagent/dry/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	. = ..()
	if(M.isSynthetic(M))
		return
	M.add_modifier(/datum/modifier/dehydrated)
	M.bloodstr.remove_reagent(id, volume)

/datum/modifier/dehydrated
	name = "dehydrated"
	desc = "You're all dried out! You really need some water!"

	on_created_text = "<span class='warning'><font size='3'>Your mouth and eyes are dry, and you can feel a headache forming! You feel so weak... you could really use a drink...</font></span>"
	on_expired_text = "<span class='notice'><font size='3'>That's it!!! The water was just what you needed! You're feeling much better now.</font></span>"

	incoming_damage_percent = 1.5
	incoming_healing_percent = 0.5
	outgoing_melee_damage_percent = 0.5
	slowdown = 4
	evasion = -50
	accuracy = -50
	accuracy_dispersion = 20
	metabolism_percent = 4.0
	attack_speed_percent = 4
	pulse_modifier = 1.5

/datum/modifier/dehydrated/New(new_holder, new_origin)
	. = ..()
	holder.throw_alert("dehydrated", /obj/screen/alert/dehydrated)
/datum/modifier/dehydrated/expire(silent)
	. = ..()
	holder.clear_alert("dehydrated")

/obj/screen/alert/dehydrated
	name = "Dehydrated"
	desc = "You could really use some water..."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "dehydrated"

/datum/reagent/water/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/datum/modifier/dehydrated/D = M.get_modifier_of_type(/datum/modifier/dehydrated)
	if(D)
		D.expire()
	else
		..()
