/*
////////////////////////////
/  =--------------------=  /
/  == Ear Definitions  ==  /
/  =--------------------=  /
////////////////////////////
*/
/datum/sprite_accessory/ears
	name = "You should not see this..."
	icon = 'icons/mob/human_races/sprite_accessories/ears.dmi'
	do_colouration = FALSE // Set to TRUE to blend (ICON_ADD) hair color
	species_allowed = list(
			SPECIES_HUMAN,			SPECIES_SKRELL,
			SPECIES_UNATHI,			SPECIES_TAJ,
			SPECIES_TESHARI,		SPECIES_NEVREAN,
			SPECIES_AKULA,			SPECIES_SERGAL,
			SPECIES_FENNEC,			SPECIES_ZORREN_HIGH,
			SPECIES_VULPKANIN,		SPECIES_XENOCHIMERA,
			SPECIES_XENOHYBRID,		SPECIES_VASILISSAN,
			SPECIES_RAPALA,			SPECIES_PROTEAN,
			SPECIES_ALRAUNE,		SPECIES_WEREBEAST,
			SPECIES_SHADEKIN,		SPECIES_SHADEKIN_CREW,
			SPECIES_ALTEVIAN
			) //This lets all races use
	color_blend_mode = ICON_ADD // Only appliciable if do_coloration = TRUE
	var/extra_overlay // Icon state of an additional overlay to blend in.
	var/extra_overlay2
	em_block = TRUE

/***	Mundane Critters	***/
/datum/sprite_accessory/ears/taj_ears
	name = "Tajaran Ears"
	icon_state = "ears_plain"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "ears_plain-inner"
	backup_name = list(
		"tajaran, colorable (old)"
	)

/datum/sprite_accessory/ears/taj_ears_tall
	name = "Tajaran Tall Ears"
	icon_state = "msai_plain"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "msai_plain-inner"
	backup_name = list(
		"tajaran tall, colorable (old)"
	)

/datum/sprite_accessory/ears/alt_ram_horns
	name = "Solid ram horns"
	icon_state = "ram_horns_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/hyena
	name = "hyena ears, dual-color"
	icon_state = "hyena"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "hyena-inner"

/datum/sprite_accessory/ears/foxearshc
	name = "highlander zorren ears"
	icon_state = "foxearshc"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"highlander zorren ears, colorable"
	)

/datum/sprite_accessory/ears/fenearshc
	name = "flatland zorren ears"
	icon_state = "fenearshc"
	extra_overlay = "fenears-inner"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"flatland zorren ears, colorable"
	)

/datum/sprite_accessory/ears/sergalhc
	name = "Sergal ears"
	icon_state = "serg_plain_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"Sergal ears, colorable"
	)

/datum/sprite_accessory/ears/mousehc
	name = "mouse"
	icon_state = "mouse"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "mouseinner"
	backup_name = list(
		"mouse, colorable",
	)

/datum/sprite_accessory/ears/mousehcno
	name = "mouse, no inner"
	icon_state = "mouse"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"mouse, colorable, no inner",
		"mouse-grey"
	)

/datum/sprite_accessory/ears/wolfhc
	name = "wolf"
	icon_state = "wolf"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "wolfinner"
	backup_name = list(
		"wolf, colorable",
		"wolf, grey",
		"wolf, green",
		"wolf, wise"
	)

/datum/sprite_accessory/ears/bearhc
	name = "bear"
	icon_state = "bear"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"bear, colorable",
		"bear, brown",
		"bear, panda"
	)

/datum/sprite_accessory/ears/smallbear
	name = "small bear"
	icon_state = "smallbear"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/squirrelhc
	name = "squirrel"
	icon_state = "squirrel"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"squirrel, colorable",
		"squirrel-orange",
		"squirrel, red"
	)

/datum/sprite_accessory/ears/kittyhc
	name = "kitty"
	icon_state = "kitty"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "kittyinner"
	backup_name = list(
		"kitty, colorable"
	)

/datum/sprite_accessory/ears/bunnyhc
	name = "bunny"
	icon_state = "bunny"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"bunny, colorable",
		"bunny, white"
	)

/datum/sprite_accessory/ears/antlers
	name = "antlers"
	icon_state = "antlers"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/antlers_e
	name = "antlers with ears"
	icon_state = "cow-nohorns"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "antlers_mark"

/datum/sprite_accessory/ears/smallantlers
	name = "small antlers"
	icon_state = "smallantlers"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/smallantlers_e
	name = "small antlers with ears"
	icon_state = "smallantlers"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "deer"

/datum/sprite_accessory/ears/deer
	name = "deer ears"
	icon_state = "deer"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/cowc
	name = "cow, horns"
	icon_state = "cow-c"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"cow, horns, colorable"
	)

/datum/sprite_accessory/ears/cow_nohorns
	name = "cow, no horns"
	icon_state = "cow-nohorns"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/caprahorns
	name = "caprine horns"
	icon_state = "caprahorns"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/otie
	name = "otie"
	icon_state = "otie"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "otie-inner"
	backup_name = list(
		"otie, colorable"
	)

/datum/sprite_accessory/ears/donkey
	name = "donkey"
	icon_state = "donkey"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "otie-inner"
	backup_name = list(
		"donkey, colorable"
	)

/datum/sprite_accessory/ears/zears
	name = "jagged ears"
	icon_state = "zears"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/vulp
	name = "vulpkanin, dual-color"
	icon_state = "vulp"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "vulp-inner"

/datum/sprite_accessory/ears/vulp_short
	name = "vulpkanin short"
	icon_state = "vulp_terrier"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/vulp_short_dc
	name = "vulpkanin short, dual-color"
	icon_state = "vulp_terrier"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "vulp_terrier-inner"

/datum/sprite_accessory/ears/vulp_jackal
	name = "vulpkanin thin, dual-color"
	icon_state = "vulp_jackal"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "vulp_jackal-inner"

/datum/sprite_accessory/ears/bunny_floppy
	name = "floopy bunny ears"
	icon_state = "floppy_bun"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"floopy bunny ears (colorable)"
	)

/datum/sprite_accessory/ears/shark
	name = "shark ears"
	icon_state = "shark_ears"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"shark ears (Colorable)"
	)

/datum/sprite_accessory/ears/sharkhigh
	name = "shark upper ears"
	icon_state = "shark_ears_upper"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"shark upper ears (Colorable)"
	)

/datum/sprite_accessory/ears/sharklow
	name = "shark lower ears"
	icon_state = "shark_ears_lower"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"shark lower ears (Colorable)"
	)

/datum/sprite_accessory/ears/sharkfin
	name = "shark fin"
	icon_state = "shark_fin"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"shark fin (Colorable)"
	)

/datum/sprite_accessory/ears/sharkfinalt
	name = "shark fin alt"
	icon_state = "shark_fin_alt"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"shark fin alt style (Colorable)"
	)

/datum/sprite_accessory/ears/sharkboth
	name = "shark ears and fin"
	icon_state = "shark_ears"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "shark_fin"
	backup_name = list(
		"shark ears and fin (Colorable)"
	)

/datum/sprite_accessory/ears/sharkbothalt
	name = "shark ears and fin alt"
	icon_state = "shark_ears"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "shark_fin_alt"
	backup_name = list(
		"shark ears and fin alt style (Colorable)"
	)

/datum/sprite_accessory/ears/sharkhighboth
	name = "shark upper ears and fin"
	icon_state = "shark_ears_upper"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "shark_fin"
	backup_name = list(
		"shark upper ears and fin (Colorable)"
	)

/datum/sprite_accessory/ears/sharkhighbothalt
	name = "shark upper ears and fin alt"
	icon_state = "shark_ears_upper"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "shark_fin_alt"
	backup_name = list(
		"shark upper ears and fin alt style (Colorable)"
	)

/datum/sprite_accessory/ears/sharklowboth
	name = "shark lower ears and fin"
	icon_state = "shark_ears_lower"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "shark_fin"
	backup_name = list(
		"shark lower ears and fin (Colorable)"
	)

/datum/sprite_accessory/ears/sharklowbothalt
	name = "shark lower ears and fin alt"
	icon_state = "shark_ears_lower"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "shark_fin_alt"
	backup_name = list(
		"shark lower ears and fin alt style (Colorable)"
	)

/datum/sprite_accessory/ears/wilddog
	name = "Wild Dog Ears"
	icon_state = "wild_dog"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "wild_doginner"

/datum/sprite_accessory/ears/singlesidehorn
	name = "Single Side Horn"
	icon_state = "single-side-horn"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/feather_fan_ears
	name = "feather fan avian ears"
	icon_state = "feather_fan_ears"
	extra_overlay = "feather_fan_ears-outer"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/kittyr
	name = "kitty right only"
	icon = 'icons/mob/vore/ears_uneven.dmi'
	icon_state = "kittyrinner"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "kittyr"
	backup_name = list(
		"kitty right only, colorable"
	)

/datum/sprite_accessory/ears/cobra_hood
	name = "Cobra hood (large)"
	icon_state = "cobra_hood"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "cobra_hood-inner"

/***	Exotic Critters		***/
/datum/sprite_accessory/ears/alien_slug
	name = "Alien slug antennae"
	icon_state = "alien_slug"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/moth
	name = "moth antennae"
	icon_state = "moth"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/bee
	name = "bee antennae"
	icon_state = "bee"

/datum/sprite_accessory/ears/antennae
	name = "antennae, colorable"
	icon_state = "antennae"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/antennae_eye
	name = "antennae eye, colorable"
	icon_state = "antennae"
	extra_overlay = "antennae_eye_1"
	extra_overlay2 = "antennae_eye_2"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/curly_bug
	name = "curly antennae, colorable"
	icon_state = "curly_bug"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/inkling
	name = "colorable mature inkling hair"
	icon = 'icons/mob/human_face_alt.dmi'
	icon_state = "inkling-colorable"
	color_blend_mode = ICON_MULTIPLY
	do_colouration = TRUE

/datum/sprite_accessory/ears/teshari
	name = "Teshari regular ears"
	icon_state = "teshari"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshariinner"
	backup_name = list(
		"Teshari (colorable fluff)"
	)

/datum/sprite_accessory/ears/tesharihigh
	name = "Teshari upper ears"
	icon_state = "tesharihigh"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "tesharihighinner"
	backup_name = list(
		"Teshari upper ears (colorable fluff)"
	)

/datum/sprite_accessory/ears/tesharilow
	name = "Teshari lower ears"
	icon_state = "tesharilow"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "tesharilowinner"
	backup_name = list(
		"Teshari lower ears (colorable fluff)"
	)

/datum/sprite_accessory/ears/tesh_pattern_ear_male
	name = "Teshari male ear pattern"
	icon_state = "teshari"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshari_male_pattern"
	backup_name = list(
		"Teshari male ear pattern (colorable)"
	)

/datum/sprite_accessory/ears/tesh_pattern_ear_female
	name = "Teshari female ear pattern"
	icon_state = "teshari"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshari_female_pattern"
	backup_name = list(
		"Teshari female ear pattern (colorable)"
	)

/datum/sprite_accessory/ears/teshbeeantenna
	name = "Teshari bee antenna"
	icon_state = "teshbee"

/datum/sprite_accessory/ears/teshantenna
	name = "Teshari antenna, colorable"
	icon_state = "teshantenna"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/curlyteshantenna
	name = "Teshari curly antenna, colorable"
	icon_state = "curly_bug_tesh"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/dino_frills
	name = "triceratops frills"
	icon_state = "triceratops_frill"
	extra_overlay = "triceratops_frill_spikes"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/***	Synthetic Critters			***/
/datum/sprite_accessory/ears/dual_robot
	name = "synth antennae, colorable"
	icon_state = "dual_robot_antennae"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/right_robot
	name = "right synth, colorable"
	icon_state = "right_robot_antennae"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/left_robot
	name = "left synth, colorable"
	icon_state = "left_robot_antennae"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/***		Fey/Demon Critters		***/
/datum/sprite_accessory/ears/oni_h1_c
	name = "oni horns"
	icon_state = "oni-h1_c"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"oni horns, colorable"
	)

/datum/sprite_accessory/ears/demon_horns1_c
	name = "demon horns"
	icon_state = "demon-horns1_c"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"demon horns, colorable"
	)

/datum/sprite_accessory/ears/demon_horns2
	name = "demon horns, outward color"
	icon_state = "demon-horns2"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"demon horns, colorable(outward)"
	)

/datum/sprite_accessory/ears/dragon_horns
	name = "dragon horns"
	icon_state = "dragon-horns"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"dragon horns, colorable"
	)

/datum/sprite_accessory/ears/elfs1
	name = "pointed ears (tall)"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/elfs2
	name = "pointed ears"
	icon_state = "ears_pointy"
	do_colouration = TRUE

/datum/sprite_accessory/ears/elfs3
	name = "pointed ears (down)"
	icon_state = "ears_pointy_down"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/elfs4
	name = "pointed ears (long)"
	icon_state = "ears_pointy_long"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/elfs5
	name = "pointed ears (long, down)"
	icon_state = "ears_pointy_long_down"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/sleek
	name = "sleek ears"
	icon_state = "sleek"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/drake
	name = "drake frills"
	icon_state = "drake"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/large_dragon
	name = "Large dragon horns"
	icon_state = "big_liz"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/elf_caprine_colorable
	name = "Caprine horns with pointy ears"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "caprahorns"
	backup_name = list(
		"Caprine horns with pointy ears, colorable"
	)

/datum/sprite_accessory/ears/elf_oni_colorable
	name = "oni horns with pointy ears"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "oni-h1_c"
	backup_name = list(
		"oni horns with pointy ears, colorable"
	)

/datum/sprite_accessory/ears/elf_demon_colorable
	name = "Demon horns with pointy ears"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "demon-horns1_c"
	backup_name = list(
		"Demon horns with pointy ears, colorable"
	)

/datum/sprite_accessory/ears/elf_demon_outwards_colorable
	name = "Demon horns with pointy ears, outwards"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "demon-horns2"
	backup_name = list(
		"Demon horns with pointy ears, outwards, colourable"
	)

/datum/sprite_accessory/ears/elf_dragon_colorable
	name = "Dragon horns with pointy ears"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "dragon-horns"
	backup_name = list(
		"Dragon horns with pointy ears, colourable"
	)

/datum/sprite_accessory/ears/forward_curled_demon_horns_bony
	name = "Succubus horns, colourable"
	icon_state = "succu-horns_b"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/forward_curled_demon_horns_bony_with_colorable_ears
	name = "Succubus horns with pointy ears, colourable"
	icon_state = "elfs"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "succu-horns_b"

/datum/sprite_accessory/ears/zorgoia
	name = "Zorgoia ears"
	icon_state = "zorgoia"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "zorgoia_inner"
	extra_overlay2 = "zorgoia_tips"

/datum/sprite_accessory/ears/synthhorns_plain
	name = "Synth horns, plain"
	icon_state = "synthhorns_plain"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "synthhorns_plain_light"

/datum/sprite_accessory/ears/synthhorns_thick
	name = "Synth horns, thick"
	icon_state = "synthhorns_thick"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "synthhorns_thick_light"

/datum/sprite_accessory/ears/synthhorns_curly
	name = "Synth horns, curly"
	icon_state = "synthhorns_curled"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/chorns_nubbydogs
	name = "Nubby Chorns"
	icon_state = "chorn_nubby"

/datum/sprite_accessory/ears/chorns_herk
	name = "Herk Chorns"
	icon_state = "chorn_herk"

/datum/sprite_accessory/ears/chorns_bork
	name = "Bork Chorns"
	icon_state = "chorn_bork"

/datum/sprite_accessory/ears/chorns_bull
	name = "Bull Chorns"
	icon_state = "chorn_bull"

/datum/sprite_accessory/ears/chorns_bicarrot
	name = "Bicarrot Chorns"
	icon_state = "chorn_bicarrot"

/datum/sprite_accessory/ears/chorns_longcarrot
	name = "Long Carrot Chorns"
	icon_state = "chorn_longcarrot"

/datum/sprite_accessory/ears/chorns_shortcarrot
	name = "Short Carrot Chorns"
	icon_state = "chorn_shortcarrot"

/datum/sprite_accessory/ears/chorns_scorp
	name = "Scorp Chorns"
	icon_state = "chorn_scorp"

/datum/sprite_accessory/ears/chorns_ocean
	name = "Ocean Chorns"
	icon_state = "chorn_ocean"

/datum/sprite_accessory/ears/chorns_chub
	name = "Chub Chorns"
	icon_state = "chorn_chub"

/datum/sprite_accessory/ears/altevian
	name = "Altevian Ears"
	icon_state = "altevian"
	extra_overlay = "altevian-inner"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/ears/syrishroom
	name = "Orange Mushroom Cap"
	icon_state = "syrishroom"


// Special snowflake ears go below here.
