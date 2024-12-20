/mob/living/carbon/human
	vore_capacity = 3
	vore_capacity_ex = list("stomach" = 3, "taur belly" = 3)
	vore_fullness_ex = list("stomach" = 0, "taur belly" = 0)
	vore_icon_bellies = list("stomach", "taur belly")
	var/struggle_anim_stomach = FALSE
	var/struggle_anim_taur = FALSE
	vore_sprite_color = list("stomach" = "#FFFFFF", "taur belly" = "#FFFFFF")
	vore_sprite_multiply = list("stomach" = TRUE, "taur belly" = TRUE)
	vore_fullness = 0
	var/allow_contaminate = TRUE
	var/allow_stripping = TRUE

/mob/living/carbon/human/update_fullness(var/returning = FALSE)
	if(!returning)
		if(updating_fullness)
			return
	var/previous_stomach_fullness = vore_fullness_ex["stomach"]
	var/previous_taur_fullness = vore_fullness_ex["taur belly"]
	//update_vore_tail_sprite()
	//update_vore_belly_sprite()
	var/list/new_fullness = ..(TRUE)
	. = new_fullness
	for(var/datum/category_group/underwear/undergarment_class in global_underwear.categories) //RS note: I'm not too 100% sure on what this does. Our TGUI has an 'undergarment addition' in it at the time of porting this from CS but this isn't able to be enabled. From the looks of it, it has to do with PR #6096 on Chomp to allow underwear bulging out when prey are eaten...Very clever way of implying a /certain/ thing! Perhaps worth looking into in the future to give people a 'stomach' for THOSE TWO vore types without being overt or getting into trouble.
		if(!new_fullness[undergarment_class.name])
			continue
		new_fullness[undergarment_class.name] = -1 * round(-1 * new_fullness[undergarment_class.name]) // Doing a ceiling the only way BYOND knows how I guess
		new_fullness[undergarment_class.name] = (min(2, new_fullness[undergarment_class.name]) - 2) * -1 //Complicated stuff to get it correctly aligned with the expected TRUE/FALSE
		var/datum/category_item/underwear/UWI = all_underwear[undergarment_class.name]
		if(!UWI || UWI.name == "None")
			//Welllll okay then. If the former then something went wrong, if None was selected then...
			if(istype(undergarment_class.items_by_name[new_fullness[undergarment_class.name + "-ifnone"]], /datum/category_item/underwear))
				UWI = undergarment_class.items_by_name[new_fullness[undergarment_class.name + "-ifnone"]]
				all_underwear[undergarment_class.name] = UWI
		if(UWI && UWI.has_color && new_fullness[undergarment_class.name + "-color"])
			all_underwear_metadata[undergarment_class.name]["[gear_tweak_free_color_choice]"] = new_fullness[undergarment_class.name + "-color"]
		if(UWI && UWI.name != "None" && hide_underwear[undergarment_class.name] != new_fullness[undergarment_class.name])
			hide_underwear[undergarment_class.name] = new_fullness[undergarment_class.name]
			update_underwear(1)
	if(vore_fullness_ex["stomach"] != previous_stomach_fullness)
		update_vore_belly_sprite()
	if(vore_fullness_ex["taur belly"] != previous_taur_fullness)
		update_vore_tail_sprite()

/mob/living/carbon/human/proc/vs_animate(var/belly_to_animate)
	if(belly_to_animate == "stomach")
		vore_belly_animation()
	else if(belly_to_animate == "taur belly")
		vore_tail_animation()
	else
		return
