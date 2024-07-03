/datum/sprite_accessory/tail
    var/vore_tail_sprite_variant = ""
    var/belly_variant_when_loaf = FALSE
    var/fullness_icons = 0
    var/struggle_anim = FALSE
    var/bellies_icon_path = 'icons/mob/vore/Taur_Bellies.dmi'

/datum/sprite_accessory/tail/taur/wolf
	vore_tail_sprite_variant = "N"
	fullness_icons = 3
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/naga/naga_2c
	vore_tail_sprite_variant = "Naga"
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/horse
	vore_tail_sprite_variant = "Horse"
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/cow
	vore_tail_sprite_variant = "Cow"
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/lizard
	vore_tail_sprite_variant = "Lizard"
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/lizard/synthlizard
	vore_tail_sprite_variant = "SynthLiz"
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/feline
	vore_tail_sprite_variant = "Feline"
	belly_variant_when_loaf = TRUE
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/slug
	vore_tail_sprite_variant = "Slug"
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/drake
	vore_tail_sprite_variant = "Drake"
	belly_variant_when_loaf = TRUE
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/otie
	vore_tail_sprite_variant = "Otie"
	belly_variant_when_loaf = TRUE
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/deer
	vore_tail_sprite_variant = "Deer"
	belly_variant_when_loaf = TRUE
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/skunk
	vore_tail_sprite_variant = "Skunk"
	belly_variant_when_loaf = TRUE
	fullness_icons = 1
	struggle_anim = TRUE

/datum/sprite_accessory/tail/taur/ch
	icon = 'icons/mob/vore/taurs_ch.dmi'//Parent which allows us to not need to set icon every time.

/datum/sprite_accessory/tail/taur/ch/bigleggy
	name = "Big Leggies"
	icon_state = "bigleggy"
	extra_overlay = "bigleggy_markings"
	vore_tail_sprite_variant = "bigleggy"
	fullness_icons = 3
	ani_state = "bigleggy_stanced"
	extra_overlay_w = "bigleggy_markings_stanced"

/datum/sprite_accessory/tail/taur/ch/bigleggy/canine
	name = "Big Leggies (Canine Tail)"
	extra_overlay2 = "bigleggy_canine"
	extra_overlay2_w = "bigleggy_canine"

/datum/sprite_accessory/tail/taur/ch/bigleggy/feline
	name = "Big Leggies (Feline Tail)"
	extra_overlay2 = "bigleggy_feline"
	extra_overlay2_w = "bigleggy_feline"

/datum/sprite_accessory/tail/taur/ch/bigleggy/reptile
	name = "Big Leggies (Reptile Tail)"
	extra_overlay2 = "bigleggy_reptile"
	extra_overlay2_w = "bigleggy_reptile"

/datum/sprite_accessory/tail/taur/ch/bigleggy/snake
	name = "Big Leggies (Snake Tail)"
	extra_overlay2 = "bigleggy_snake"
	extra_overlay2_w = "bigleggy_snake"

/datum/sprite_accessory/tail/taur/ch/bigleggy/fox
	name = "Big Leggies (Fox Tail)"
	extra_overlay2 = "bigleggy_vulpine"
	extra_overlay2_w = "bigleggy_vulpine"

/datum/sprite_accessory/tail/taur/ch/bigleggy/bird
	name = "Big Leggies (Bird)"
	icon_state = "bigleggy"
	extra_overlay = "bigleggy_m_bird"
	extra_overlay2 = "bigleggy_bird"
	extra_overlay_w = "bigleggy_m_bird_stanced"
	extra_overlay2_w = "bigleggy_bird"

/datum/sprite_accessory/tail/taur/ch/bigleggy/plug
	name = "Big Leggies (Plug Tail)"
	extra_overlay2 = "bigleggy_plug"
	extra_overlay2_w = "bigleggy_plug"

/datum/sprite_accessory/tail/taur/ch/bigleggy/AlienSlug
	name = "Big Leggies (Alien Slug Tail)"
	icon_state = "bigleggy_full_alienslug"
	extra_overlay = "bigleggy_alienslug"
	extra_overlay_w = "bigleggy_alienslug"
	extra_overlay2 = "bigleggy_alienslug_m"
	extra_overlay2_w = "bigleggy_alienslug_m"
