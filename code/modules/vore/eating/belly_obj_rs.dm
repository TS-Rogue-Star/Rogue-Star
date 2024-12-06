#define DM_FLAG_VORESPRITE_BELLY	0x1
#define DM_FLAG_VORESPRITE_TAIL     0x2
#define DM_FLAG_VORESPRITE_MARKING  0x4
#define DM_FLAG_VORESPRITE_ARTICLE	0x8

/obj/belly
	var/vore_sprite_flags = DM_FLAG_VORESPRITE_BELLY
	var/tmp/static/list/vore_sprite_flag_list= list(
		"Normal belly sprite" = DM_FLAG_VORESPRITE_BELLY,
		//"Tail adjustment" = DM_FLAG_VORESPRITE_TAIL,
		//"Marking addition" = DM_FLAG_VORESPRITE_MARKING
		)
	var/affects_vore_sprites = FALSE
	var/count_absorbed_prey_for_sprite = TRUE
	var/absorbed_multiplier = 1
	var/count_liquid_for_sprite = FALSE
	var/liquid_multiplier = 1
	var/count_items_for_sprite = FALSE
	var/item_multiplier = 1
	var/health_impacts_size = TRUE
	var/resist_triggers_animation = TRUE
	var/size_factor_for_sprite = 1
	var/belly_sprite_to_affect = "stomach"
	var/datum/sprite_accessory/tail/tail_to_change_to = FALSE
	var/tail_colouration = FALSE
	var/tail_extra_overlay = FALSE
	var/tail_extra_overlay2 = FALSE
	var/undergarment_chosen = "Underwear, bottom"

/obj/belly/proc/GetFullnessFromBelly()
	if(!affects_vore_sprites)
		return 0
	var/belly_fullness = 0
	for(var/mob/living/M in src)
		if(count_absorbed_prey_for_sprite || !M.absorbed)
			var/fullness_to_add = M.size_multiplier
			fullness_to_add *= M.mob_size / 20
			if(M.absorbed)
				fullness_to_add *= absorbed_multiplier
			if(health_impacts_size)
				fullness_to_add *= M.health / M.getMaxHealth()
			belly_fullness += fullness_to_add
	if(count_liquid_for_sprite)
		belly_fullness += (reagents.total_volume / 100) * liquid_multiplier
	if(count_items_for_sprite)
		for(var/obj/item/I in src)
			var/fullness_to_add = 0
			if(I.w_class == ITEMSIZE_TINY)
				fullness_to_add = ITEMSIZE_COST_TINY
			else if(I.w_class == ITEMSIZE_SMALL)
				fullness_to_add = ITEMSIZE_COST_SMALL
			else if(I.w_class == ITEMSIZE_NORMAL)
				fullness_to_add = ITEMSIZE_COST_NORMAL
			else if(I.w_class == ITEMSIZE_LARGE)
				fullness_to_add = ITEMSIZE_COST_LARGE
			else if(I.w_class == ITEMSIZE_HUGE)
				fullness_to_add = ITEMSIZE_COST_HUGE
			else
				fullness_to_add = ITEMSIZE_COST_NO_CONTAINER
			fullness_to_add /= 32
			belly_fullness += fullness_to_add * item_multiplier
	belly_fullness *= size_factor_for_sprite
	return belly_fullness
