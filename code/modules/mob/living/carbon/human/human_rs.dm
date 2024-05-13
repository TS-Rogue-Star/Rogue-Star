/mob/living/carbon/human
	var/vore_capacity = 3
	var/vore_capacity_ex = list("stomach" = 3, "taur belly" = 3)
	var/vore_fullness_ex = list("stomach" = 0, "taur belly" = 0)
	var/vore_icon_bellies = list("stomach", "taur belly")
	var/struggle_anim_stomach = FALSE
	var/struggle_anim_taur = FALSE
	var/vore_sprite_color = list("stomach" = "#FFFFFF", "taur belly" = "#FFFFFF")
	var/vore_sprite_multiply = list("stomach" = TRUE, "taur belly" = TRUE)
	var/vore_fullness = 0
	var/allow_contaminate = TRUE
	var/allow_stripping = TRUE

/mob/living/carbon/human/proc/update_fullness()
	var/list/new_fullness = list()
	vore_fullness = 0
	for(var/belly_class in vore_icon_bellies)
		new_fullness[belly_class] = 0
	for(var/obj/belly/B as anything in vore_organs)
		new_fullness[B.belly_sprite_to_affect] += B.GetFullnessFromBelly()
	for(var/belly_class in vore_icon_bellies)
		new_fullness[belly_class] /= size_multiplier //Divided by pred's size so a macro mob won't get macro belly from a regular prey.
		new_fullness[belly_class] = round(new_fullness[belly_class], 1) // Because intervals of 0.25 are going to make sprite artists cry.
		vore_fullness_ex[belly_class] = min(vore_capacity_ex[belly_class], new_fullness[belly_class])
		vore_fullness += new_fullness[belly_class]
	vore_fullness = min(vore_capacity, vore_fullness)
	update_vore_belly_sprite()
	update_vore_tail_sprite()

/mob/living/carbon/human/proc/vs_animate(var/belly_to_animate)
	if(belly_to_animate == "stomach")
		vore_belly_animation()
	else if(belly_to_animate == "taur belly")
		vore_tail_animation()
	else
		return
