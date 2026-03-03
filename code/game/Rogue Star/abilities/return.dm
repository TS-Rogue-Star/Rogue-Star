//RS FILE
/mob/living/proc/return_home()
	set name = "Return"
	set desc = "Allows you to return to a designated location."
	set category = "Abilities"

	var/datum/modifier/return_home/mod = get_modifier_of_type(/datum/modifier/return_home)

	if(!mod)
		register_home()
	else
		mod.home()

/mob/living/proc/return_home_aoe()
	set name = "Return (AOE)"
	set desc = "Allows you and anyone next to you to return to a designated location."
	set category = "Abilities"

	var/datum/modifier/return_home/mod = get_modifier_of_type(/datum/modifier/return_home)

	if(!mod)
		register_home()
	else
		mod.home_aoe()

/mob/living/proc/register_home()
	set name = "Return Register"
	set desc = "Allows you and anyone next to you to return to a designated location."
	set category = "Abilities"

	if(tgui_alert(usr,"Would you like to register this location as your return point?","Return configuration",list("No","Yes")) == "Yes")
		var/datum/modifier/return_home/mod = get_modifier_of_type(/datum/modifier/return_home)
		if(!mod)
			add_modifier(/datum/modifier/return_home)
			return
		mod.homeloc = get_turf(src)

/datum/modifier/return_home
	name = "Return"
	desc = "This allows you to return to a set location."
	var/turf/homeloc

/datum/modifier/return_home/expire(silent)
	homeloc = null
	holder.verbs.Remove(/mob/living/proc/return_home)
	holder.verbs.Remove(/mob/living/proc/return_home_aoe)
	. = ..()

/datum/modifier/return_home/New(new_holder, new_origin)
	. = ..()
	homeloc = get_turf(holder)
	holder.verbs.Add(/mob/living/proc/return_home)
	holder.verbs.Add(/mob/living/proc/return_home_aoe)

/datum/modifier/return_home/proc/home()
	holder.forceMove(homeloc)

/datum/modifier/return_home/proc/home_aoe()
	for(var/mob/living/L in view(1))
		if(!isliving(L))
			continue
		L.forceMove(homeloc)
