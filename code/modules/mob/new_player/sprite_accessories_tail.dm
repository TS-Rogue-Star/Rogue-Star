/*
////////////////////////////
/  =--------------------=  /
/  == Tail Definitions ==  /
/  =--------------------=  /
////////////////////////////
*/
/datum/sprite_accessory/tail
	name = "You should not see this..."
	icon = 'icons/mob/vore/tails.dmi'
	do_colouration = TRUE //Set to FALSE to disable coloration using the tail color.

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

	color_blend_mode = ICON_MULTIPLY	// Only appliciable if do_coloration = TRUE //Multiply = white sprites, Add = black sprites
	em_block = TRUE						// Emissive overlay stuff. Synth glowing, etc.
	var/extra_overlay 					// Icon state of an additional overlay to blend in.
	var/extra_overlay2					// Tertiary.
	var/show_species_tail = FALSE		// If false, do not render species' tail.
	var/clothing_can_hide = TRUE		// If true, clothing with HIDETAIL hides it
	var/ani_state						// Icon State when wagging/animated
	var/extra_overlay_w					// Wagging state for extra overlay
	var/extra_overlay2_w				// Tertiary wagging.
	var/requires_clipping = FALSE		// Used for overcomplicated tails / taur bodies that don't work with suits. taursuits_unsuitable.dmi is where they get their tailsock
	var/icon/clip_mask_icon = null		// Icon file used for clip mask.
	var/clip_mask_state = null			// Icon state to generate clip mask. Clip mask is used to 'clip' off the lower part of clothing such as jumpsuits & full suits.
	var/icon/clip_mask = null			// Instantiated clip mask of given icon and state
	var/tailsock						// icon state needed for a complete tailsock item. defaults to icon_state. Override for cut-out overlay -> squished ones.
	var/tailsock_w						// for waggin' tailsocks. defaults to ani_state if there is one. Override for above issues.

	// Taur Loafing
	var/can_loaf = FALSE
	var/loaf_offset = 0
	var/list/lower_layer_dirs = list(SOUTH)
	var/icon_loaf = null

	//taur specific offsets for their bodies
	var/offset_x = 0
	//For taurs of unnatural scales (Teppi)
	var/offset_y = 0
	var/mob_offset_x = 0
	var/mob_offset_y = 0
	//what taur butt specific offsets there are (drake vs wolf, etc)
	var/taur_butt_x = 0
	var/taur_butt_y = 0
	//what it will take to align human-scaled tails to Tauric butts (Wolf is default)
	var/taur_tail_offset_Y = 0
	var/taur_tail_offset_E = 0
	var/taur_tail_offset_W = 32

	//Taur Belly overlay handling
	//Reduces headache from update_icons code by being above taurs. No 32x32 belly sprites exist tho, so...
	var/vore_tail_sprite_variant = ""
	var/belly_variant_when_loaf = FALSE
	var/fullness_icons = 0
	var/struggle_anim = FALSE
	var/bellies_icon_path = 'icons/mob/vore/Taur_Bellies.dmi'
	var/style = TAIL_HUMANOID		//Preference menu sorting, taur ones are TAIL_TAURIC

/datum/sprite_accessory/tail/New()
	. = ..()
	if(clip_mask_state)
		clip_mask = icon(icon = (clip_mask_icon ? clip_mask_icon : icon), icon_state = clip_mask_state)
	if(icon_state)
		tailsock = icon_state
	if(ani_state)
		tailsock_w = ani_state

/datum/sprite_accessory/tail/proc/get_taur_tail_offsets(pass_index) // list(dir = x, y, layer)
	var/list/values = list(
		"[NORTH]" = list(offset_x, taur_tail_offset_Y + taur_butt_y, TAIL_UPPER_LAYER),
		"[SOUTH]" = list(offset_x, taur_tail_offset_Y + taur_butt_y, TAIL_LOWER_LAYER),
		"[EAST]" = list(taur_tail_offset_E + taur_butt_x, taur_tail_offset_Y + taur_butt_y, TAIL_UPPER_LAYER),
		"[WEST]" = list(taur_tail_offset_W - taur_butt_x, taur_tail_offset_Y + taur_butt_y, TAIL_UPPER_LAYER))
	return values

/***		Tails are listed in order of placement in the tail listing			***/

// Everyone tails

/datum/sprite_accessory/tail/invisible
	name = "hide species-sprite tail"
	icon = null
	icon_state = null

/datum/sprite_accessory/tail/alien_slug
	name = "Alien slug tail"
	icon_state = "alien_slug"
	extra_overlay = "alien_slug_markings"

/datum/sprite_accessory/tail/squirrel
	name = "squirrel"
	icon_state = "squirrel"
	backup_name = list(
		"squirrel, colorable",
		"squirel, orange",
		"squirrel, red"
	)

/datum/sprite_accessory/tail/kitty
	name = "kitty, downwards"
	icon_state = "kittydown"
	backup_name = list(
		"kitty, colorable, downwards"
	)

/datum/sprite_accessory/tail/kittyup
	name = "kitty, upwards"
	icon_state = "kittyup"
	backup_name = list(
		"kitty, colorable, upwards"
	)

/datum/sprite_accessory/tail/tiger_new
	name = "tiger"
	icon_state = "tigertail"
	ani_state = "tigertail_w"
	extra_overlay = "tigertail_mark"
	extra_overlay_w = "tigertail_mark_w"
	backup_name = list(
		"tiger, colorable",
		"tiger tail (vwag)",
		"stripey taj",
		"stripey taj, colorable",
		"stripey taj, brown"
	)

/datum/sprite_accessory/tail/vulp_new
	name = "Vulp tail"
	icon_state = "vulptail"
	ani_state = "vulptail_w"
	extra_overlay = "vulptail_mark"
	extra_overlay_w = "vulptail_mark_w"
	backup_name = list("new vulp tail (vwag)")

/datum/sprite_accessory/tail/chameleon
	name = "Chameleon"
	icon_state = "chameleon"
	backup_name = list(
		"Chameleon, colorable"
	)

/datum/sprite_accessory/tail/bunny
	name = "bunny"
	icon_state = "bunny"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"bunny, colorable"
	)

/datum/sprite_accessory/tail/bear
	name = "bear"
	icon_state = "bear"
	backup_name = list(
		"bear, colorable",
		"bear, brown"
	)

/datum/sprite_accessory/tail/dragon
	name = "dragon"
	icon_state = "dragon"
	backup_name = list(
		"dragon, colorable"
	)

/datum/sprite_accessory/tail/wolf
	name = "wolf"
	icon_state = "wolf"
	extra_overlay = "wolfinner"
	backup_name = list(
		"wolf, colorable",
		"wolf, grey",
		"wolf, green",
		"wolf, wise",
		"wolf, black"
	)

/datum/sprite_accessory/tail/mouse
	name = "mouse"
	icon_state = "mouse"
	backup_name = list(
		"mouse, colorable",
		"mouse, pink"
	)

/datum/sprite_accessory/tail/horse
	name = "horse"
	icon_state = "horse"
	backup_name = list(
		"horse tail, colorable"
	)

/datum/sprite_accessory/tail/cow
	name = "cow tail"
	icon_state = "cow"
	backup_name = list(
		"cow tail, colorable"
	)

/datum/sprite_accessory/tail/fantail
	name = "avian fantail"
	icon_state = "fantail"
	backup_name = list(
		"avian fantail, colorable"
	)

/datum/sprite_accessory/tail/wagtail
	name = "avian wagtail"
	icon_state = "wagtail"
	backup_name = list(
		"avian wagtail, colorable"
	)

/datum/sprite_accessory/tail/nevreandc
	name = "nevrean tail"
	icon_state = "nevreantail_dc"
	extra_overlay = "nevreantail_dc_tail"
	backup_name = list(
		"nevrean tail, dual-color"
	)

/datum/sprite_accessory/tail/nevreanwagdc
	name = "nevrean wagtail"
	icon_state = "wagtail"
	extra_overlay = "wagtail_dc_tail"
	backup_name = list(
		"nevrean wagtail, dual-color"
	)

/datum/sprite_accessory/tail/nevreanwagdc_alt
	name = "nevrean wagtail, marked"
	icon_state = "wagtail2_dc"
	extra_overlay = "wagtail2_dc_mark"
	backup_name = list(
		"nevrean wagtail, marked, dual-color"
	)

/datum/sprite_accessory/tail/crossfox
	name = "cross fox"
	icon_state = "crossfox"
	do_colouration = FALSE
	tailsock = "wolf"

/datum/sprite_accessory/tail/beethorax
	name = "bee thorax"
	icon_state = "beethorax"
	do_colouration = FALSE
	tailsock = "beethoraxsock"

/datum/sprite_accessory/tail/spade_color
	name = "spade-tail"
	icon_state = "spadetail-black"
	do_colouration = TRUE
	backup_name = list(
		"spade-tail (colorable)"
	)

/datum/sprite_accessory/tail/snag
	name = "xenomorph tail 1"
	icon_state = "snag"
	do_colouration = FALSE
	tailsock = "snagsock"

/datum/sprite_accessory/tail/xenotail
	name = "xenomorph tail 2"
	icon_state = "xenotail"
	do_colouration = FALSE
	tailsock = "xenotailsock"

/datum/sprite_accessory/tail/eboop
	name = "EGN mech tail (dual color)"
	icon_state = "eboop"
	extra_overlay = "eboop_mark"

/datum/sprite_accessory/tail/ketrai_wag
	name = "fennix tail (vwag)"
	icon_state = "ketraitail"
	ani_state = "ketraitail_w"
	do_colouration = FALSE
	tailsock = "ketraitailsock"
	tailsock_w = "ketraitail_wsock"

/datum/sprite_accessory/tail/ketrainew_wag
	name = "new fennix tail (vwag)"
	icon_state = "ketraitailnew"
	ani_state = "ketraitailnew_w"
	do_colouration = FALSE
	tailsock = "ketraitailnewsock"
	tailsock_w = "ketraitailnew_wsock"

/datum/sprite_accessory/tail/ringtailwag
	name = "ringtail (vwag)"
	icon_state = "wah"
	ani_state = "wah_w"
	extra_overlay = "wah-stripes"
	extra_overlay_w = "wah-stripes_w"
	tailsock = "wahsock"
	tailsock_w = "wah_wsock"
	backup_name = list(
		"ringtail, colorable", "ringtail", "red panda"
	)

/datum/sprite_accessory/tail/raccoon
	name = "raccoon tail (vwag)"
	icon_state = "raccoon"
	ani_state = "raccoon_w"
	extra_overlay = "raccoon-stripes"
	extra_overlay_w = "raccoon-stripes_w"

/datum/sprite_accessory/tail/tailmaw
	name = "tailmaw"
	icon_state = "tailmaw"
	backup_name = list(
		"tailmaw, colorable"
	)

/datum/sprite_accessory/tail/curltail
	name = "curltail (vwag)"
	icon_state = "curltail"
	ani_state = "curltail_w"
	extra_overlay = "curltail_mark"
	extra_overlay_w = "curltail_mark_w"

/datum/sprite_accessory/tail/shorttail
	name = "shorttail (vwag)"
	icon_state = "straighttail"
	ani_state = "straighttail_w"

/datum/sprite_accessory/tail/sneptail
	name = "Snep/Furry Tail (vwag)"
	icon_state = "sneptail"
	ani_state = "sneptail_w"
	extra_overlay = "sneptail_mark"
	extra_overlay_w = "sneptail_mark_w"

/datum/sprite_accessory/tail/otietail
	name = "otie tail (vwag)"
	icon_state = "otie"
	ani_state = "otie_w"

/datum/sprite_accessory/tail/newtailmaw
	name = "new tailmaw (vwag)"
	icon_state = "newtailmaw"
	ani_state = "newtailmaw_w"

/datum/sprite_accessory/tail/ztail
	name = "jagged flufftail"
	icon_state = "ztail"

/datum/sprite_accessory/tail/snaketail
	name = "snake tail"
	icon_state = "snaketail"
	backup_name = list(
		"snake tail, colorable"
	)

/datum/sprite_accessory/tail/bigsnaketail
	name = "large snake tail (vwag)"
	icon_state = "bigsnaketail"
	ani_state = "bigsnaketail_w"

/datum/sprite_accessory/tail/bigsnaketailstripes
	name = "large snake tail, striped (vwag)"
	icon_state = "bigsnaketailstripes"
	extra_overlay = "bigsnaketailstripes-tips"
	ani_state = "bigsnaketailstripes_w"
	extra_overlay_w = "bigsnaketailstripes-tips_w"
	tailsock = "bigsnaketail"
	tailsock_w = "bigsnaketail_w"

/datum/sprite_accessory/tail/bigsnaketailstripes_alt
	name = "large snake tail, striped, alt (vwag)"
	icon_state = "bigsnaketailstripesalt"
	extra_overlay = "bigsnaketailstripesalt-tips"
	ani_state = "bigsnaketailstripesalt_w"
	extra_overlay_w = "bigsnaketailstripesalt-tips_w"
	tailsock = "bigsnaketail"
	tailsock_w = "bigsnaketail_w"

/datum/sprite_accessory/tail/bigsnaketaildual
	name = "large snake tail, dual color (vwag)"
	icon_state = "bigsnaketaildual"
	extra_overlay = "bigsnaketaildual-tips"
	ani_state = "bigsnaketaildual_w"
	extra_overlay_w = "bigsnaketaildual-tips_w"
	tailsock = "bigsnaketail"
	tailsock_w = "bigsnaketail_w"

/datum/sprite_accessory/tail/bigsnaketailunder
	name = "large snake tail, under (vwag)"
	icon_state = "bigsnaketailunder"
	extra_overlay = "bigsnaketailunder-tips"
	ani_state = "bigsnaketailunder_w"
	extra_overlay_w = "bigsnaketailunder-tips_w"
	tailsock = "bigsnaketail"
	tailsock_w = "bigsnaketail_w"

/datum/sprite_accessory/tail/vulpan_alt
	name = "vulpkanin alt style, colorable"
	icon_state = "vulptail_alt"

/datum/sprite_accessory/tail/sergaltaildc
	name = "sergal, dual-color"
	icon_state = "sergal"
	extra_overlay = "sergal_mark"

/datum/sprite_accessory/tail/skunktail
	name = "skunk, dual-color"
	icon_state = "skunktail"
	extra_overlay = "skunktail_mark"

/datum/sprite_accessory/tail/deertail
	name = "deer, dual-color"
	icon_state = "deertail"
	extra_overlay = "deertail_mark"

/datum/sprite_accessory/tail/tesh_feathered
	name = "Teshari tail"
	icon_state = "teshtail_s"
	extra_overlay = "teshtail_feathers_s"

/datum/sprite_accessory/tail/teshari_fluffytail
	name = "Teshari alternative, colorable"
	icon_state = "teshari_fluffytail"
	extra_overlay = "teshari_fluffytail_mark"

/datum/sprite_accessory/tail/tesh_pattern_male
	name = "Teshari male tail pattern"
	icon_state = "teshtail_s"
	extra_overlay = "teshpattern_male_tail"
	tailsock = "teshtail_s"

/datum/sprite_accessory/tail/tesh_pattern_male_alt
	name = "Teshari male tail alt. pattern"
	icon_state = "teshtail_s"
	extra_overlay = "teshpattern_male_alt"
	tailsock = "teshtail_s"

/datum/sprite_accessory/tail/tesh_pattern_fem
	name = "Teshari female tail pattern"
	icon_state = "teshtail_s"
	extra_overlay = "teshpattern_fem_tail"
	tailsock = "teshtail_s"

/datum/sprite_accessory/tail/tesh_pattern_fem_alt
	name = "Teshari female tail alt. pattern"
	icon_state = "teshtail_s"
	extra_overlay = "teshpattern_fem_alt"
	tailsock = "teshtail_s"

/datum/sprite_accessory/tail/nightstalker
	name = "Nightstalker"
	icon_state = "nightstalker"
	backup_name = list(
		"Nightstalker, colorable"
	)

/datum/sprite_accessory/tail/zenghu_taj
	name = "Zeng-Hu Tajaran Synth tail"
	icon_state = "zenghu_taj"
	do_colouration = FALSE
	tailsock = "stripeytail"

/datum/sprite_accessory/tail/tail_smooth
	name = "Smooth Lizard Tail"
	icon_state = "tail_smooth"
	ani_state = "tail_smooth_w"
	backup_name = list(
		"Smooth Lizard Tail, colorable"
	)

/datum/sprite_accessory/tail/fennec_tail
	name = "Fennec tail"
	icon_state = "fennec_tail_s"

/datum/sprite_accessory/tail/fox_tail
	name = "Fox tail"
	icon_state = "fox_tail_s"
	backup_name = list(
		"Fox tail, colorable"
	)

/datum/sprite_accessory/tail/fox_tail_plain
	name = "Fox tail, plain"
	icon_state = "fox_tail_plain_s"
	backup_name = list(
		"Fox tail, colorable, plain"
	)

/datum/sprite_accessory/tail/foxtail
	name = "Fox tail (vwag)"
	icon_state = "foxtail"
	extra_overlay = "foxtail-tips"
	ani_state = "foxtail_w"
	extra_overlay_w = "foxtail-tips_w"
	tailsock = "foxtailsock"
	tailsock_w = "foxtail_wsock"
	backup_name = list(
		"Fox tail, colorable (vwag)"
	)

/datum/sprite_accessory/tail/doublekitsune
	name = "Kitsune 2 tails"
	icon_state = "doublekitsune"
	extra_overlay = "doublekitsune-tips"
	backup_name = list(
		"Kitsune 2 tails, colorable"
	)


/datum/sprite_accessory/tail/doublekitsunealt
	name = "Kitsune 2 tails, alt"
	icon_state = "doublekitsunealt"
	extra_overlay = "doublekitsunealt-tips"
	tailsock = "doublekitsunealtsock"
	backup_name = list(
		"Kitsune 2 tails, colorable, alt"
	)

/datum/sprite_accessory/tail/triplekitsune_colorable
	name = "Kitsune 3 tails"
	icon_state = "triplekitsune"
	extra_overlay = "triplekitsune-tips"
	tailsock = "triplekitsunealtsock"
	backup_name = list(
		"Kitsune 3 tails, colorable"
	)

/datum/sprite_accessory/tail/fivekitsune_colorable
	name = "Kitsune 5 tails"
	icon_state = "fivekitsune"
	extra_overlay = "fivekitsune-tips"

/datum/sprite_accessory/tail/sevenkitsune_colorable
	name = "Kitsune 7 tails"
	icon_state = "sevenkitsune"
	extra_overlay = "sevenkitsune-tips"
	tailsock = "sevenkitsunealtsock"
	backup_name = list(
		"Kitsune 7 tails, colorable"
	)

/datum/sprite_accessory/tail/ninekitsune_colorable
	name = "Kitsune 9 tails"
	icon_state = "ninekitsune"
	extra_overlay = "ninekitsune-tips"
	tailsock = "ninekitsunealtsock"
	backup_name = list(
		"Kitsune 9 tails, colorable"
	)

/datum/sprite_accessory/tail/hideableninetails
	name = "Kitsune 9-in-1 tail (vwag)"
	icon_state = "ninekitsune"
	extra_overlay = "ninekitsune-tips"
	ani_state = "foxtail_w"
	extra_overlay_w = "foxtail-tips_w"
	tailsock = "ninekitsunealtsock"
	tailsock_w = "foxtail_wsock"
	backup_name = list(
		"Kitsune 9-in-1 tail, colourable (vwag)"
	)

/datum/sprite_accessory/tail/shadekin_short
	name = "Shadekin Short Tail"
	icon_state = "shadekin-short"
	backup_name = list(
		"Shadekin Short Tail, colorable"
	)

/datum/sprite_accessory/tail/wartacosushi_tail
	name = "Ward-Takahashi Tail"
	icon_state = "wardtakahashi_vulp"

/datum/sprite_accessory/tail/wartacosushi_tail_dc
	name = "Ward-Takahashi Tail, dual-color"
	icon_state = "wardtakahashi_vulp_dc"
	extra_overlay = "wardtakahashi_vulp_dc_mark"

/datum/sprite_accessory/tail/zorgoia
	name = "Zorgoia tail, dual-color"
	icon = 'icons/mob/human_races/sprite_accessories/tails.dmi'
	icon_state = "zorgoia"
	extra_overlay = "zorgoia_fluff"
	extra_overlay2 = "zorgoia_fluff_top"

/datum/sprite_accessory/tail/Easterntail
	name = "Eastern Dragon (Animated)"
	icon_state = "Easterntail"
	extra_overlay = "EasterntailColorTip"
	ani_state = "Easterntail_w"
	extra_overlay_w = "EasterntailColorTip_w"

/datum/sprite_accessory/tail/synthtail_static
	name = "Synthetic lizard tail"
	icon_state = "synthtail"

/datum/sprite_accessory/tail/synthtail_vwag
	name = "Synthetic lizard tail (vwag)"
	icon_state = "synthtail"
	ani_state = "synthtail_w"

/datum/sprite_accessory/tail/Plugtail
	name = "Synthetic plug tail"
	icon_state = "Plugtail"
	extra_overlay = "PlugtailMarking"
	extra_overlay2 = "PlugtailMarking2"

/datum/sprite_accessory/tail/Segmentedtail
	name = "Segmented tail, animated"
	icon_state = "Segmentedtail"
	extra_overlay = "Segmentedtailmarking"
	ani_state = "Segmentedtail_w"
	extra_overlay_w = "Segmentedtailmarking_w"

/datum/sprite_accessory/tail/Segmentedlights
	name = "Segmented tail, animated synth"
	icon_state = "Segmentedtail"
	extra_overlay = "Segmentedlights"
	ani_state = "Segmentedtail_w"
	extra_overlay_w = "Segmentedlights_w"

/datum/sprite_accessory/tail/lizard_tail_smooth
	name = "Lizard Tail (Smooth)"
	icon_state = "lizard_tail_smooth"

/datum/sprite_accessory/tail/lizard_tail_dark_tiger
	name = "Lizard Tail (Dark Tiger)"
	icon_state = "lizard_tail_dark_tiger"

/datum/sprite_accessory/tail/lizard_tail_light_tiger
	name = "Lizard Tail (Light Tiger)"
	icon_state = "lizard_tail_light_tiger"

/datum/sprite_accessory/tail/lizard_tail_spiked
	name = "Lizard Tail (Spiked)"
	icon_state = "lizard_tail_spiked"

/datum/sprite_accessory/tail/xenotail_fullcolour
	name = "xenomorph tail"
	icon_state = "xenotail_fullcolour"
	backup_name = list(
		"xenomorph tail (fully colourable)"
	)

/datum/sprite_accessory/tail/xenotailalt_fullcolour
	name = "xenomorph tail alt"
	icon_state = "xenotailalt_fullcolour"
	backup_name = list(
		"xenomorph tail alt. (fully colourable)"
	)

/datum/sprite_accessory/tail/peacocktail //this was ckey locked but the ckey user has their snowflake and it said they were gunna be unlocked eventually so... /shrug
	name = "Peacock tail"
	icon_state = "peacocktail"
	extra_overlay = "peacocktail_markings"
	ani_state = "peacocktail_w"
	extra_overlay_w = "peacocktail_markings_w"

/datum/sprite_accessory/tail/altevian
	name = "Altevian Tail"
	icon_state = "altevian"
	lower_layer_dirs = list(SOUTH, WEST)

/datum/sprite_accessory/tail/shark_finless
	name = "shark tail, finless"
	icon_state = "sharktail_finless"
	backup_name = list(
		"shark tail, finless (colorable)"
	)

/datum/sprite_accessory/tail/tentacle
	name = "Tentacle"
	icon_state = "tentacle"
	ani_state = "tentacle_w"
	backup_name = list(
		"Tentacle, colorable (vwag)"
	)

/datum/sprite_accessory/tail/blade_like_tail
	name = "Blade-like Tail"
	icon_state = "blade-like-tail"

/datum/sprite_accessory/tail/sectdrone_tail
	name = "Sect Drone Tail (To use with bodytype-marking)"
	icon_state = "sectdrone_tail"
	extra_overlay = "sectdrone_tail_mark"

/datum/sprite_accessory/tail/turkey //Would have been a really good thing for Thanksgiving probably but I'm not going to wait that long.
	name = "turkey"
	icon_state = "turkey"
	tailsock = "turkeysock"
	do_colouration = FALSE

/datum/sprite_accessory/tail/shark_markings
	name = "akula tail, tail and fins"
	icon_state = "sharktail"
	extra_overlay = "sharktail_markings"
	backup_name = list(
		"akula tail, colorable, tail and fins"
	)

/datum/sprite_accessory/tail/shark_stripes
	name = "akula tail, stripe"
	icon_state = "sharktail"
	extra_overlay = "sharktail_stripemarkings"
	backup_name = list(
		"akula tail, colorable, stripe"
	)

/datum/sprite_accessory/tail/shark_tips
	name = "akula tail, tips"
	icon_state = "sharktail"
	extra_overlay = "sharktail_tipmarkings"
	backup_name = list(
		"akula tail, colorable, tips"
	)

/datum/sprite_accessory/tail/narrow_tail
	name = "feathered narrow tail"
	icon_state = "narrowtail"
	backup_name = list(
		"feathered narrow tail, colorable"
	)

/datum/sprite_accessory/tail/narrow_tail2
	name = "feathered narrow tail, 2 colors"
	icon_state = "narrowtail_2color"
	extra_overlay = "narrowtail_2color-1"
	tailsock = "narrowtail"

// Dino Tails

/datum/sprite_accessory/tail/clubtail
	name = "dino clubtail"
	icon_state = "clubtail"
	extra_overlay = "clubtail-1"
	backup_name = list(
		"dino clubtail, colorable"
	)

/datum/sprite_accessory/tail/spiketail
	name = "dino spiketail"
	icon_state = "spiketail"
	extra_overlay = "spiketail-1"
	backup_name = list(
		"dino spiketail, colorable"
	)

/***	Leg replacements but tails		***/

/datum/sprite_accessory/tail/satyr
	name = "goat legs"
	icon_state = "satyr"
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT) //Exclude pelvis just in case.
	clip_mask_icon = 'icons/mob/vore/taurs.dmi'
	clip_mask_state = "taur_clip_mask_def" //Used to clip off the lower part of suits & uniforms.
	backup_name = list(
		"goat legs, colorable"
	)

/datum/sprite_accessory/tail/satyrtail
	name = "goat legs with tail"
	icon_state = "satyr"
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT) //Exclude pelvis just in case.
	clip_mask_icon = 'icons/mob/vore/taurs.dmi'
	clip_mask_state = "taur_clip_mask_def" //Used to clip off the lower part of suits & uniforms.
	extra_overlay = "horse" //I can't believe this works.
	backup_name = list(
		"goat legs with tail, colorable"
	)

/datum/sprite_accessory/tail/synthetic_stilt_legs
	name = "synthetic stilt-legs"
	icon_state = "synth_stilts"
	extra_overlay = "synth_stilts_marking"
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT) //Exclude pelvis just in case.
	clip_mask_icon = 'icons/mob/vore/taurs.dmi'
	clip_mask_state = "taur_clip_mask_def" //Used to clip off the lower part of suits & uniforms.
	backup_name = list(
		"synthetic stilt-legs, colorable"
	)

//LONG TAILS ARE NOT TAUR BUTTS >:O
/datum/sprite_accessory/tail/longtail
	name = "Fluffy Longtail"
	icon = 'icons/mob/vore/longtail.dmi'
	icon_state = "longflufftail"	//was otherwise unused
	offset_x = -16

/datum/sprite_accessory/tail/longtail/redpanda
	name = "Long Wah Tail"
	icon_state = "bigringtail"
	extra_overlay = "bigringtail_markings"
	tailsock = "bigringtailsock"

/datum/sprite_accessory/tail/longtail/long_lizard
	name = "Long Lizard Tail"
	icon_state = "lizardlongtail_s"

/datum/sprite_accessory/tail/longtail/nightstalker
	name = "Nightstalker Diamonback"
	icon_state = "nightstalker_diamondback"
	extra_overlay = "nightstalker_diamondback_markings"
	ani_state = "nightstalker_diamondback_w"
	extra_overlay_w = "nightstalker_diamondback_markings_w"
	tailsock = "nightstalker_diamondbackksock"
	tailsock = "nightstalker_diamondback_wsock"

/datum/sprite_accessory/tail/longtail/nightstalker/desert
	name = "Nightstalker Desert"
	icon_state = "nightstalker_desert"
	ani_state = "nightstalker_desert_w"
	do_colouration = FALSE

/datum/sprite_accessory/tail/longtail/shadekin_tail
	name = "Shadekin Tail"
	icon_state = "shadekin_s"

/datum/sprite_accessory/tail/longtail/shadekin_tail/shadekin_tail_2c
	name = "Shadekin Tail (dual color)"
	extra_overlay = "shadekin_markings"

/datum/sprite_accessory/tail/longtail/shadekin_tail/shadekin_tail_long
	name = "Shadekin Long Tail"
	icon_state = "shadekin_long_s"

/datum/sprite_accessory/tail/longtail/zaprat
	name = "bolt-shaped tail, dual color"
	icon_state = "zaprat_s"
	extra_overlay = "zaprat_markings"

/datum/sprite_accessory/tail/longtail/zaprat/heart
	name = "heart-bolt-shaped tail, dual color"
	icon_state = "zaprat_heart_s"
	extra_overlay = "zaprat_heart_markings"

//For all species tails. Includes haircolored tails.
/datum/sprite_accessory/tail/special
	name = "human tail (Invisible)"	//because humans don't actually have one, get it?
	icon = 'icons/effects/species_tails.dmi'

/datum/sprite_accessory/tail/special/unathi
	name = "unathi tail"
	icon_state = "sogtail_s"

/datum/sprite_accessory/tail/special/tajaran
	name = "tajaran tail"
	icon_state = "tajtail_s"

/datum/sprite_accessory/tail/special/sergal
	name = "sergal tail"
	icon_state = "sergtail_s"

/datum/sprite_accessory/tail/special/akula
	name = "akula tail"
	icon_state = "sharktail_s"

/datum/sprite_accessory/tail/special/nevrean
	name = "nevrean tail"
	icon_state = "nevreantail_s"

/datum/sprite_accessory/tail/special/armalis
	name = "armalis tail"
	icon_state = "armalis_tail_humanoid_s"
	do_colouration = FALSE

/datum/sprite_accessory/tail/special/xenodrone
	name = "xenomorph drone tail"
	icon_state = "xenos_drone_tail_s"
	do_colouration = FALSE

/datum/sprite_accessory/tail/special/xenosentinel
	name = "xenomorph sentinel tail"
	icon_state = "xenos_sentinel_tail_s"
	do_colouration = FALSE

/datum/sprite_accessory/tail/special/xenohunter
	name = "xenomorph hunter tail"
	icon_state = "xenos_hunter_tail_s"
	do_colouration = FALSE

/datum/sprite_accessory/tail/special/xenoqueen
	name = "xenomorph queen tail"
	icon_state = "xenos_queen_tail_s"
	do_colouration = FALSE

/datum/sprite_accessory/tail/special/monkey
	name = "monkey tail"
	icon_state = "chimptail_s"
	do_colouration = FALSE

/datum/sprite_accessory/tail/special/tesharitail
	name = "teshari tail"
	icon_state = "seromitail_s"

/datum/sprite_accessory/tail/special/tesharitailfeathered
	name = "teshari tail w/ feathers"
	icon_state = "seromitail_s"
	extra_overlay = "seromitail_feathers_s"

/datum/sprite_accessory/tail/special/unathihc
	name = "unathi tail, colorable"
	icon_state = "sogtail_hc_s"

/datum/sprite_accessory/tail/special/tajaranhc
	name = "tajaran tail, colorable"
	icon_state = "tajtail_hc_s"

/datum/sprite_accessory/tail/special/sergalhc
	name = "sergal tail, colorable"
	icon_state = "sergtail_hc_s"

/datum/sprite_accessory/tail/special/akulahc
	name = "akula tail, colorable"
	icon_state = "sharktail_hc_s"

/datum/sprite_accessory/tail/special/nevreanhc
	name = "nevrean tail, colorable"
	icon_state = "nevreantail_hc_s"

/datum/sprite_accessory/tail/special/foxdefault
	name = "default zorren tail"
	icon = "icons/mob/human_races/r_fox_vr.dmi"
	icon_state = "tail_s"
	backup_name = list(
		"default zorren tail, colorable"
	)

/datum/sprite_accessory/tail/special/foxhc
	name = "highlander zorren tail"
	icon_state = "foxtail_hc_s"
	backup_name = list(
		"highlander zorren tail, colorable"
	)

/datum/sprite_accessory/tail/special/fennechc
	name = "flatland zorren tail"
	icon_state = "fentail_hc_s"
	backup_name = list(
		"flatland zorren tail, colorable"
	)

/datum/sprite_accessory/tail/special/armalishc
	name = "armalis tail"
	icon_state = "armalis_tail_humanoid_hc_s"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"armalis tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenodronehc
	name = "xenomorph drone tail"
	icon_state = "xenos_drone_tail_hc_s"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"xenomorph drone tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenosentinelhc
	name = "xenomorph sentinel tail"
	icon_state = "xenos_sentinel_tail_hc_s"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"xenomorph sentinel tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenohunterhc
	name = "xenomorph hunter tail"
	icon_state = "xenos_hunter_tail_hc_s"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"xenomorph hunter tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenoqueenhc
	name = "xenomorph queen tail"
	icon_state = "xenos_queen_tail_hc_s"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"xenomorph queen tail, colorable"
	)

/datum/sprite_accessory/tail/special/monkeyhc
	name = "monkey tail"
	icon_state = "chimptail_hc_s"
	color_blend_mode = ICON_ADD
	backup_name = list(
		"monkey tail, colorable"
	)

/datum/sprite_accessory/tail/special/tesharitailhc
	name = "teshari tail, colorable"
	icon_state = "seromitail_hc_s"

/datum/sprite_accessory/tail/special/tesharitailfeatheredhc
	name = "teshari tail w/ feathers, colorable"
	icon_state = "seromitail_feathers_hc_s"

/datum/sprite_accessory/tail/special/vulpan
	name = "vulpkanin, colorable"
	icon_state = "vulptail_s"

//Buggo Abdomens!

/datum/sprite_accessory/tail/buggo
	name = "Bug abdomen, colorable"
	icon_state = "buggo_s"

/datum/sprite_accessory/tail/buggobee
	name = "Bug abdomen, bee top, dual-colorable"
	icon_state = "buggo_s"
	extra_overlay = "buggobee_markings"

/datum/sprite_accessory/tail/buggobeefull
	name = "Bug abdomen, bee full, dual-colorable"
	icon_state = "buggo_s"
	extra_overlay = "buggobeefull_markings"

/datum/sprite_accessory/tail/buggounder
	name = "Bug abdomen, underside, dual-colorable"
	icon_state = "buggo_s"
	extra_overlay = "buggounder_markings"

/datum/sprite_accessory/tail/buggofirefly
	name = "Bug abdomen, firefly, dual-colorable"
	icon_state = "buggo_s"
	extra_overlay = "buggofirefly_markings"

/datum/sprite_accessory/tail/buggofat
	name = "Fat bug abdomen, colorable"
	icon_state = "buggofat_s"

/datum/sprite_accessory/tail/buggofatbee
	name = "Fat bug abdomen, bee top, dual-colorable"
	icon_state = "buggofat_s"
	extra_overlay = "buggofatbee_markings"

/datum/sprite_accessory/tail/buggofatbeefull
	name = "Fat bug abdomen, bee full, dual-colorable"
	icon_state = "buggofat_s"
	extra_overlay = "buggofatbeefull_markings"

/datum/sprite_accessory/tail/buggofatunder
	name = "Fat bug abdomen, underside, dual-colorable"
	icon_state = "buggofat_s"
	extra_overlay = "buggofatunder_markings"

/datum/sprite_accessory/tail/buggofatfirefly
	name = "Fat bug abdomen, firefly, dual-colorable"
	icon_state = "buggofat_s"
	extra_overlay = "buggofatfirefly_markings"

/datum/sprite_accessory/tail/buggowag
	name = "Bug abdomen, colorable, vwag change"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"

/datum/sprite_accessory/tail/buggobeewag
	name = "Bug abdomen, bee top, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	extra_overlay = "buggobee_markings"
	extra_overlay_w = "buggofatbee_markings"

/datum/sprite_accessory/tail/buggobeefullwag
	name = "Bug abdomen, bee full, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	extra_overlay = "buggobeefull_markings"
	extra_overlay_w = "buggofatbeefull_markings"

/datum/sprite_accessory/tail/buggounderwag
	name = "Bug abdomen, underside, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	extra_overlay = "buggounder_markings"
	extra_overlay_w = "buggofatunder_markings"

/datum/sprite_accessory/tail/buggofireflywag
	name = "Bug abdomen, firefly, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	extra_overlay = "buggofirefly_markings"
	extra_overlay_w = "buggofatfirefly_markings"

//Vass buggo variants!

/datum/sprite_accessory/tail/buggovass
	name = "Bug abdomen, vass, colorable"
	icon_state = "buggo_vass_s"

/datum/sprite_accessory/tail/buggovassbee
	name = "Bug abdomen, bee top, dc, vass"
	icon_state = "buggo_vass_s"
	extra_overlay = "buggobee_vass_markings"

/datum/sprite_accessory/tail/buggovassbeefull
	name = "Bug abdomen, bee full, dc, vass"
	icon_state = "buggo_vass_s"
	extra_overlay = "buggobeefull_vass_markings"

/datum/sprite_accessory/tail/buggovassunder
	name = "Bug abdomen, underside, dc, vass"
	icon_state = "buggo_vass_s"
	extra_overlay = "buggounder_vass_markings"

/datum/sprite_accessory/tail/buggovassfirefly
	name = "Bug abdomen, firefly, dc, vass"
	icon_state = "buggo_vass_s"
	extra_overlay = "buggofirefly_vass_markings"

/datum/sprite_accessory/tail/buggovassfat
	name = "Fat bug abdomen, vass, colorable"
	icon_state = "buggofat_vass_s"

/datum/sprite_accessory/tail/buggovassfatbee
	name = "Fat bug abdomen, bee top, dc, vass"
	icon_state = "buggofat_vass_s"
	extra_overlay = "buggofatbee_vass_markings"

/datum/sprite_accessory/tail/buggovassfatbeefull
	name = "Fat bug abdomen, bee full, dc, vass"
	icon_state = "buggofat_vass_s"
	extra_overlay = "buggofatbeefull_vass_markings"

/datum/sprite_accessory/tail/buggovassfatunder
	name = "Fat bug abdomen, underside, dc, vass"
	icon_state = "buggofat_vass_s"
	extra_overlay = "buggofatunder_vass_markings"

/datum/sprite_accessory/tail/buggovassfatfirefly
	name = "Fat bug abdomen, firefly, dc, vass"
	icon_state = "buggofat_vass_s"
	extra_overlay = "buggofatfirefly_vass_markings"

/datum/sprite_accessory/tail/buggovasswag
	name = "Bug abdomen, vass, colorable, vwag change"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"

/datum/sprite_accessory/tail/buggovassbeewag
	name = "Bug abdomen, bee top, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	extra_overlay = "buggobee_vass_markings"
	extra_overlay_w = "buggofatbee_vass_markings"

/datum/sprite_accessory/tail/buggovassbeefullwag
	name = "Bug abdomen, bee full, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	extra_overlay = "buggobeefull_vass_markings"
	extra_overlay_w = "buggofatbeefull_vass_markings"

/datum/sprite_accessory/tail/buggovassunderwag
	name = "Bug abdomen, underside, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	extra_overlay = "buggounder_vass_markings"
	extra_overlay_w = "buggofatunder_vass_markings"

/datum/sprite_accessory/tail/buggovassfireflywag
	name = "Bug abdomen, firefly, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	extra_overlay = "buggofirefly_vass_markings"
	extra_overlay_w = "buggofatfirefly_vass_markings"

/***	Teshari Varient Buggos		***/
/datum/sprite_accessory/tail/teshbeethorax
	name = "Teshari bee thorax"
	icon_state = "beethorax_tesh"
	do_colouration = FALSE
	species_allowed = list(SPECIES_TESHARI)
	tailsock = "beethorax_teshsock"

/datum/sprite_accessory/tail/teshbuggo
	name = "Teshari bug abdomen, colorable"
	icon_state = "teshbug_s"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggobee
	name = "Teshari bug abdomen, bee top, dual-colorable"
	icon_state = "teshbug_s"
	extra_overlay = "teshbee_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbeefull
	name = "Teshari bug abdomen, bee full, dual-colorable"
	icon_state = "teshbug_s"
	extra_overlay = "teshbeefull_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggounder
	name = "Teshari bug abdomen, underside, dual-colorable"
	icon_state = "teshbug_s"
	extra_overlay = "teshunder_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggofirefly
	name = "Teshari bug abdomen, firefly, dual-colorable"
	icon_state = "teshbug_s"
	extra_overlay = "teshfirefly_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggo
	name = "Teshari fat bug abdomen, colorable"
	icon_state = "teshbugfat_s"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggobee
	name = "Teshari fat bug abdomen, bee top, dual-colorable"
	icon_state = "teshbugfat_s"
	extra_overlay = "teshfatbee_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbeefull
	name = "Teshari fat bug abdomen, bee full, dual-colorable"
	icon_state = "teshbugfat_s"
	extra_overlay = "teshfatbeefull_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggounder
	name = "Teshari fat bug abdomen, underside, dual-colorable"
	icon_state = "teshbugfat_s"
	extra_overlay = "teshfatunder_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggofirefly
	name = "Teshari fat bug abdomen, firefly, dual-colorable"
	icon_state = "teshbugfat_s"
	extra_overlay = "teshfatfirefly_markings"
	species_allowed = list(SPECIES_TESHARI)
