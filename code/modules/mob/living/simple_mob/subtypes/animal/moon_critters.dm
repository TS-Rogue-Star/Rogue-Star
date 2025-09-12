/mob/living/simple_mob/vore/deer/moon_deer
	name = "moon deer"
	desc = "Deer from the moon, who would have guessed?"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "moon_deer"
	icon_living = "moon_deer"

	say_list_type = /datum/say_list/deer/moon

	var/list/overlays_cache = list()
	var/crystal_color

	vore_capacity = 1

/mob/living/simple_mob/vore/deer/moon_deer/New()
	color = pick(list("#FFFFFF","#fff9d9","#d9fbff","#f1d9ff","#ffd9d9","#3b3b3b"))
	. = ..()
	crystal_color = random_color()
	update_icon()

/mob/living/simple_mob/vore/deer/moon_deer/update_icon()
	. = ..()

	var/combine_key = "crystal-[crystal_color]"
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_deer_crystal")
		our_image.color = crystal_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

	combine_key = "shine"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_deer_shine")
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

/datum/say_list/deer/moon
	speak = list("Rooohhh...","Rrrrhhh...","Wooooohhhh...","Wrooh.","Hroh.")






























/mob/living/simple_mob/vore/moon_skitterer
	name = "skitterer"
	desc = "A creature covered in sharp looking plates. It has at least four legs, and a long, hard pointy tail."
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "skitterer"
	icon_living = "skitterer"

/mob/living/simple_mob/vore/moon_skitterer/New()
	color = pick(list("#FFFFFF","#fff9d9","#a89153","#56758f","#625569","#382d1f","#3b3b3b"))
	. = ..()

/mob/living/simple_mob/vore/moon_ray
	name = "moon ray"
	desc = "A large, somewhat flat kind of creature that has adapted to float above the ground!"
	icon = 'icons/rogue-star/mobx64.dmi'
	icon_state = "moon_ray"
	icon_living = "moon_ray"

	pixel_x = -16
	default_pixel_x = -16

	var/list/overlays_cache = list()
	var/marking_color
	var/eye_color

	vore_active = TRUE
	vore_capacity = 1

/mob/living/simple_mob/vore/moon_ray/New()
	color = pick(list("#FFFFFF","#fff9d9","#d9fbff","#f1d9ff","#ffd9d9","#3b3b3b"))
	. = ..()
	marking_color = random_color()
	eye_color = pick(list("#e100ff","#ff0000"))
	update_icon()

/mob/living/simple_mob/vore/moon_ray/update_icon()
	. = ..()

	var/our_state = "moon_ray_marking"
	if(vore_fullness)
		our_state = "[our_state]-[vore_fullness]"
	//	icon_state = "[icon_living]-[vore_fullness]"
	var/combine_key = "marking-[marking_color]-[vore_fullness]"
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,our_state)
		our_image.color = marking_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

	combine_key = "eye-[eye_color]"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_ray_eyes")
		our_image.color = eye_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		our_image.plane = PLANE_LIGHTING_ABOVE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

/mob/living/simple_mob/vore/moon_dragon
	name = "moon dragon"
	desc = "A dragon from the moon, can't get much more obvious than that! Does it have three eyes?"
