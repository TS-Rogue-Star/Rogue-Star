/datum/power/shadekin/regenerate_other_lesser
	name = "Lesser Regenerate Other (25)"
	desc = "Spend energy to heal physical wounds in another creature."
	verbpath = /mob/living/carbon/human/proc/regenerate_other_lesser
	ability_icon_state = "tech_biomedaura"

/mob/living/carbon/human/proc/regenerate_other_lesser()
	set name = "Lesser Regenerate Other (25)"
	set desc = "Spend energy to heal physical wounds in another creature."
	set category = "Shadekin"

	var/ability_cost = 50

	var/datum/species/shadekin/SK = species
	if(!istype(SK))
		to_chat(src, "<span class='warning'>Only a shadekin can use that!</span>")
		return FALSE
	else if(stat)
		to_chat(src, "<span class='warning'>Can't use that ability in your state!</span>")
		return FALSE
	else if(shadekin_get_energy() < ability_cost)
		to_chat(src, "<span class='warning'>Not enough energy for that ability!</span>")
		return FALSE
	else if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, "<span class='warning'>You can't use that while phase shifted!</span>")
		return FALSE

	var/list/viewed = oview(1)
	var/list/targets = list()
	for(var/mob/living/L in viewed)
		targets += L
	if(!targets.len)
		to_chat(src,"<span class='warning'>Nobody nearby to mend!</span>")
		return FALSE

	var/mob/living/target = tgui_input_list(src,"Pick someone to mend:","Mend Other", targets)
	if(!target)
		return FALSE

	target.add_modifier(/datum/modifier/shadekin/heal_boop_lesser,1 MINUTE)
	playsound(src, 'sound/effects/EMPulse.ogg', 75, 1)
	shadekin_adjust_energy(-ability_cost)
	visible_message("<span class='notice'>\The [src] gently places a hand on \the [target]...</span>")
	face_atom(target)
	return TRUE

/datum/modifier/shadekin/heal_boop_lesser
	name = "Shadekin Regen (Lesser)"
	desc = "You feel serene and well rested."
	mob_overlay_state = "green_sparkles"

	on_created_text = "<span class='notice'>Sparkles begin to appear around you, and all your ills seem to fade away.</span>"
	on_expired_text = "<span class='notice'>The sparkles have faded, although you feel much healthier than before.</span>"
	stacks = MODIFIER_STACK_EXTEND

/datum/modifier/shadekin/heal_boop_lesser/tick()
	if(!holder.getBruteLoss() && !holder.getFireLoss() && !holder.getToxLoss() && !holder.getOxyLoss() && !holder.getCloneLoss()) // No point existing if the spell can't heal.
		expire()
		return
	holder.adjustBruteLoss(-0.5)
	holder.adjustFireLoss(-0.5)
	holder.adjustToxLoss(-0.5)
	holder.adjustOxyLoss(-0.5)
	holder.adjustCloneLoss(-0.5)
