/mob/living/carbon/human/proc/update_vore_belly_sprite()
	if(QDESTROYING(src))
		return

	remove_layer(VORE_BELLY_LAYER)

	var/image/vore_belly_image = get_vore_belly_image()

	if(vore_belly_image)
		vore_belly_image.layer = BODY_LAYER+VORE_BELLY_LAYER
		overlays_standing[VORE_BELLY_LAYER] = vore_belly_image

	apply_layer(VORE_BELLY_LAYER)

/mob/living/carbon/human/proc/get_vore_belly_image()
	for(var/obj/item/clothing/C in list(wear_suit, w_uniform))
		if(istype(C) && (C.item_flags & THICKMATERIAL))
			return null

	if(!(wear_suit && wear_suit.flags_inv & HIDETAIL))
		var/vs_fullness = vore_fullness_ex["stomach"]
		var/icon/vorebelly_s = new/icon(icon = 'icons/mob/vore/Bellies.dmi', icon_state = "[species.vore_belly_default_variant]Belly[vs_fullness][struggle_anim_stomach ? "" : " idle"]")
		vorebelly_s.Blend(vore_sprite_color["stomach"], vore_sprite_multiply["stomach"] ? ICON_MULTIPLY : ICON_ADD)
		var/image/working = image(vorebelly_s)
		working.overlays += em_block_image_generic(working)
		return working
	return null

/mob/living/carbon/human/proc/vore_belly_animation()
	if(!struggle_anim_stomach)
		struggle_anim_stomach = TRUE
		update_vore_belly_sprite()
		spawn(12)
			struggle_anim_stomach = FALSE
			update_vore_belly_sprite()

/mob/living/carbon/human/proc/update_vore_tail_sprite()
	if(QDESTROYING(src))
		return

	remove_layer(VORE_TAIL_LAYER)

	var/image/vore_tail_image = get_vore_tail_image()
	if(vore_tail_image)
		vore_tail_image.layer = BODY_LAYER+VORE_TAIL_LAYER
		overlays_standing[VORE_TAIL_LAYER] = vore_tail_image

	apply_layer(VORE_TAIL_LAYER)

/mob/living/carbon/human/proc/get_vore_tail_image()
	if(tail_style && istaurtail(tail_style) && tail_style:vore_tail_sprite_variant)
		var/vs_fullness = vore_fullness_ex["taur belly"]
		var/loaf_alt = lying && tail_style:belly_variant_when_loaf
		var/fullness_icons = min(tail_style.fullness_icons, vs_fullness)
		var/icon/vorebelly_s = new/icon(icon = tail_style.bellies_icon_path, icon_state = "Taur[tail_style:vore_tail_sprite_variant]-Belly-[fullness_icons][loaf_alt ? " loaf" : (struggle_anim_taur ? "" : " idle")]")
		vorebelly_s.Blend(vore_sprite_color["taur belly"], vore_sprite_multiply["taur belly"] ? ICON_MULTIPLY : ICON_ADD)
		var/image/working = image(vorebelly_s)
		working.pixel_x = -16
		if(tail_style.em_block)
			working.overlays += em_block_image_generic(working)
		return working
	return null

/mob/living/carbon/human/proc/vore_tail_animation()
	if(tail_style.struggle_anim && !struggle_anim_taur)
		struggle_anim_taur = TRUE
		update_vore_tail_sprite()
		spawn(12)
			struggle_anim_taur = FALSE
			update_vore_tail_sprite()
