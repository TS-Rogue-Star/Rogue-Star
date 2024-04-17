/*
////////////////////////////
/  =--------------------=  /
/  == Tail Definitions ==  /
/  =--------------------=  /
////////////////////////////
*/
/datum/sprite_accessory/tail
	name = "You should not see this..."
	icon = 'icons/mob/vore/tails_vr.dmi'
	do_colouration = FALSE //Set to TRUE to enable coloration using the tail color.

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

	color_blend_mode = ICON_ADD // Only appliciable if do_coloration = 1
	em_block = TRUE
	var/extra_overlay // Icon state of an additional overlay to blend in.
	var/extra_overlay2 //Tertiary.
	var/show_species_tail = FALSE // If false, do not render species' tail.
	var/clothing_can_hide = TRUE // If true, clothing with HIDETAIL hides it
	var/ani_state // State when wagging/animated
	var/extra_overlay_w // Wagging state for extra overlay
	var/extra_overlay2_w // Tertiary wagging.
	var/icon/clip_mask_icon = null //Icon file used for clip mask.
	var/clip_mask_state = null //Icon state to generate clip mask. Clip mask is used to 'clip' off the lower part of clothing such as jumpsuits & full suits.
	var/icon/clip_mask = null //Instantiated clip mask of given icon and state

	// VOREStation Edit: Taur Loafing
	var/can_loaf = FALSE
	var/loaf_offset = 0
	var/list/lower_layer_dirs = list(SOUTH)
	var/icon_loaf = null

	var/offset_x = 0
	var/offset_y = 0
	var/mob_offset_x = 0
	var/mob_offset_y = 0

/datum/sprite_accessory/tail/New()
	. = ..()
	if(clip_mask_state)
		clip_mask = icon(icon = (clip_mask_icon ? clip_mask_icon : icon), icon_state = clip_mask_state)

// Species-unique tails

// Everyone tails

/datum/sprite_accessory/tail/invisible
	name = "hide species-sprite tail"
	icon = null
	icon_state = null

/datum/sprite_accessory/tail/squirrel
	name = "squirrel"
	icon_state = "squirrel"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"squirrel, colorable",
		"squirel, orange",
		"squirrel, red"
	)

/datum/sprite_accessory/tail/kitty
	name = "kitty, downwards"
	icon_state = "kittydown"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"kitty, colorable, downwards"
	)

/datum/sprite_accessory/tail/kittyup
	name = "kitty, upwards"
	icon_state = "kittyup"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"kitty, colorable, upwards"
	)

/datum/sprite_accessory/tail/tiger_white
	name = "tiger"
	icon_state = "tiger"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "tigerinnerwhite"
	backup_name = list(
		"tiger, colorable"
	)

/datum/sprite_accessory/tail/stripey
	name = "stripey taj"
	icon_state = "stripeytail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "stripeytail_mark"
	backup_name = list(
		"stripey taj, colorable",
		"stripey taj, brown"
	)

/datum/sprite_accessory/tail/chameleon
	name = "Chameleon"
	icon_state = "chameleon"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"Chameleon, colorable"
	)

/datum/sprite_accessory/tail/bunny
	name = "bunny"
	icon_state = "bunny"
	do_colouration = TRUE
	backup_name = list(
		"bunny, colorable"
	)

/datum/sprite_accessory/tail/bear
	name = "bear"
	icon_state = "bear"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"bear, colorable",
		"bear, brown"
	)

/datum/sprite_accessory/tail/dragon
	name = "dragon"
	icon_state = "dragon"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"dragon, colorable"
	)

/datum/sprite_accessory/tail/wolf
	name = "wolf"
	icon_state = "wolf"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
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
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"mouse, colorable",
		"mouse, pink"
	)

/datum/sprite_accessory/tail/horse
	name = "horse"
	icon_state = "horse"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"horse tail, colorable"
	)

/datum/sprite_accessory/tail/cow
	name = "cow tail"
	icon_state = "cow"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"cow tail, colorable"
	)

/datum/sprite_accessory/tail/fantail
	name = "avian fantail"
	icon_state = "fantail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"avian fantail, colorable"
	)

/datum/sprite_accessory/tail/wagtail
	name = "avian wagtail"
	icon_state = "wagtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"avian wagtail, colorable"
	)

/datum/sprite_accessory/tail/nevreandc
	name = "nevrean tail"
	icon_state = "nevreantail_dc"
	extra_overlay = "nevreantail_dc_tail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"nevrean tail, dual-color"
	)

/datum/sprite_accessory/tail/nevreanwagdc
	name = "nevrean wagtail"
	icon_state = "wagtail"
	extra_overlay = "wagtail_dc_tail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"nevrean wagtail, dual-color"
	)

/datum/sprite_accessory/tail/nevreanwagdc_alt
	name = "nevrean wagtail, marked"
	icon_state = "wagtail2_dc"
	extra_overlay = "wagtail2_dc_mark"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"nevrean wagtail, marked, dual-color"
	)

/datum/sprite_accessory/tail/crossfox
	name = "cross fox"
	icon_state = "crossfox"

/datum/sprite_accessory/tail/beethorax
	name = "bee thorax"
	icon_state = "beethorax"

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

/datum/sprite_accessory/tail/xenotail
	name = "xenomorph tail 2"
	icon_state = "xenotail"

/datum/sprite_accessory/tail/eboop
	name = "EGN mech tail (dual color)"
	icon_state = "eboop"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "eboop_mark"

/datum/sprite_accessory/tail/ketrai_wag
	name = "fennix tail (vwag)"
	icon_state = "ketraitail"
	ani_state = "ketraitail_w"

/datum/sprite_accessory/tail/ketrainew_wag
	name = "new fennix tail (vwag)"
	icon_state = "ketraitailnew"
	ani_state = "ketraitailnew_w"

/datum/sprite_accessory/tail/redpanda
	name = "red panda"
	icon_state = "redpanda"

/datum/sprite_accessory/tail/ringtail
	name = "ringtail"
	icon_state = "ringtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "ringtail_mark"
	backup_name = list(
		"ringtail, colorable"
	)

/datum/sprite_accessory/tail/ringtailwag
	name = "ringtail (vwag)"
	icon_state = "wah"
	ani_state = "wah_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "wah-stripes"
	extra_overlay_w = "wah-stripes_w"

/datum/sprite_accessory/tail/raccoon
	name = "raccoon tail (vwag)"
	icon_state = "raccoon"
	ani_state = "raccoon_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "raccoon-stripes"
	extra_overlay_w = "raccoon-stripes_w"

/datum/sprite_accessory/tail/tailmaw
	name = "tailmaw"
	icon_state = "tailmaw"
	color_blend_mode = ICON_MULTIPLY
	do_colouration = TRUE
	backup_name = list(
		"tailmaw, colorable"
	)

/datum/sprite_accessory/tail/curltail
	name = "curltail (vwag)"
	icon_state = "curltail"
	ani_state = "curltail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "curltail_mark"
	extra_overlay_w = "curltail_mark_w"

/datum/sprite_accessory/tail/shorttail
	name = "shorttail (vwag)"
	icon_state = "straighttail"
	ani_state = "straighttail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/sneptail
	name = "Snep/Furry Tail (vwag)"
	icon_state = "sneptail"
	ani_state = "sneptail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "sneptail_mark"
	extra_overlay_w = "sneptail_mark_w"

/datum/sprite_accessory/tail/tiger_new
	name = "tiger tail (vwag)"
	icon_state = "tigertail"
	ani_state = "tigertail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "tigertail_mark"
	extra_overlay_w = "tigertail_mark_w"

/datum/sprite_accessory/tail/vulp_new
	name = "new vulp tail (vwag)"
	icon_state = "vulptail"
	ani_state = "vulptail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "vulptail_mark"
	extra_overlay_w = "vulptail_mark_w"

/datum/sprite_accessory/tail/otietail
	name = "otie tail (vwag)"
	icon_state = "otie"
	ani_state = "otie_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/newtailmaw
	name = "new tailmaw (vwag)"
	icon_state = "newtailmaw"
	ani_state = "newtailmaw_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/ztail
	name = "jagged flufftail"
	icon_state = "ztail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/snaketail
	name = "snake tail"
	icon_state = "snaketail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"snake tail, colorable"
	)

/datum/sprite_accessory/tail/bigsnaketail
	name = "large snake tail (vwag)"
	icon_state = "bigsnaketail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ani_state = "bigsnaketail_w"

/datum/sprite_accessory/tail/bigsnaketailstripes
	name = "large snake tail, striped (vwag)"
	icon_state = "bigsnaketailstripes"
	extra_overlay = "bigsnaketailstripes-tips"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ani_state = "bigsnaketailstripes_w"
	extra_overlay_w = "bigsnaketailstripes-tips_w"

/datum/sprite_accessory/tail/bigsnaketailstripes_alt
	name = "large snake tail, striped, alt (vwag)"
	icon_state = "bigsnaketailstripesalt"
	extra_overlay = "bigsnaketailstripesalt-tips"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ani_state = "bigsnaketailstripesalt_w"
	extra_overlay_w = "bigsnaketailstripesalt-tips_w"

/datum/sprite_accessory/tail/bigsnaketaildual
	name = "large snake tail, dual color (vwag)"
	icon_state = "bigsnaketaildual"
	extra_overlay = "bigsnaketaildual-tips"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ani_state = "bigsnaketaildual_w"
	extra_overlay_w = "bigsnaketaildual-tips_w"

/datum/sprite_accessory/tail/bigsnaketailunder
	name = "large snake tail, under (vwag)"
	icon_state = "bigsnaketailunder"
	extra_overlay = "bigsnaketailunder-tips"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ani_state = "bigsnaketailunder_w"
	extra_overlay_w = "bigsnaketailunder-tips_w"

/datum/sprite_accessory/tail/vulpan_alt
	name = "vulpkanin alt style, colorable"
	icon_state = "vulptail_alt"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/sergaltaildc
	name = "sergal, dual-color"
	icon_state = "sergal"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "sergal_mark"

/datum/sprite_accessory/tail/skunktail
	name = "skunk, dual-color"
	icon_state = "skunktail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "skunktail_mark"

/datum/sprite_accessory/tail/deertail
	name = "deer, dual-color"
	icon_state = "deertail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "deertail_mark"

/datum/sprite_accessory/tail/teshari_fluffytail
	name = "Teshari alternative, colorable"
	icon_state = "teshari_fluffytail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshari_fluffytail_mark"

/datum/sprite_accessory/tail/tesh_pattern_male
	name = "Teshari male tail pattern"
	icon_state = "teshtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshpattern_male_tail"

/datum/sprite_accessory/tail/tesh_pattern_male_alt
	name = "Teshari male tail alt. pattern"
	icon_state = "teshtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshpattern_male_alt"

/datum/sprite_accessory/tail/tesh_pattern_fem
	name = "Teshari female tail pattern"
	icon_state = "teshtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshpattern_fem_tail"

/datum/sprite_accessory/tail/tesh_pattern_fem_alt
	name = "Teshari female tail alt. pattern"
	icon_state = "teshtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshpattern_fem_alt"

/datum/sprite_accessory/tail/nightstalker
	name = "Nightstalker"
	icon_state = "nightstalker"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"Nightstalker, colorable"
	)

/datum/sprite_accessory/tail/zenghu_taj
	name = "Zeng-Hu Tajaran Synth tail"
	desc = ""
	icon_state = "zenghu_taj"

/datum/sprite_accessory/tail/tail_smooth
	name = "Smooth Lizard Tail, colorable"
	icon_state = "tail_smooth"
	ani_state = "tail_smooth_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/fennec_tail
	name = "Fennec tail"
	icon_state = "fennec_tail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/fox_tail
	name = "Fox tail, colorable"
	icon_state = "fox_tail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/fox_tail_plain
	name = "Fox tail, colorable, plain"
	icon_state = "fox_tail_plain_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/foxtail
	name = "Fox tail, colourable (vwag)"
	icon_state = "foxtail"
	extra_overlay = "foxtail-tips"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ani_state = "foxtail_w"
	extra_overlay_w = "foxtail-tips_w"

/datum/sprite_accessory/tail/doublekitsune
	name = "Kitsune 2 tails, colorable"
	icon_state = "doublekitsune"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/doublekitsunealt
	name = "Kitsune 2 tails, colorable, alt"
	icon_state = "doublekitsunealt"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "doublekitsunealt-tips"

/datum/sprite_accessory/tail/triplekitsune_colorable
	name = "Kitsune 3 tails, colorable"
	icon_state = "triplekitsune"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "triplekitsune_tips"

/datum/sprite_accessory/tail/sevenkitsune_colorable
	name = "Kitsune 7 tails, colorable"
	icon_state = "sevenkitsune"
	extra_overlay = "sevenkitsune-tips"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/ninekitsune_colorable
	name = "Kitsune 9 tails, colorable"
	icon_state = "ninekitsune"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "ninekitsune-tips"

/datum/sprite_accessory/tail/hideableninetails
    name = "Kitsune 9-in-1 tail, colourable (vwag)"
    icon_state = "ninekitsune"
    extra_overlay = "ninekitsune-tips"
    do_colouration = TRUE
    color_blend_mode = ICON_MULTIPLY
    ani_state = "foxtail_w"
    extra_overlay_w = "foxtail-tips_w"

/datum/sprite_accessory/tail/shadekin_short
	name = "Shadekin Short Tail, colorable"
	icon_state = "shadekin-short"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/wartacosushi_tail
	name = "Ward-Takahashi Tail"
	icon_state = "wardtakahashi_vulp"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/wartacosushi_tail_dc
	name = "Ward-Takahashi Tail, dual-color"
	icon_state = "wardtakahashi_vulp_dc"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "wardtakahashi_vulp_dc_mark"

/datum/sprite_accessory/tail/zorgoia
	name = "Zorgoia tail, dual-color"
	icon = 'icons/mob/human_races/sprite_accessories/tails.dmi'
	icon_state = "zorgoia"
	extra_overlay = "zorgoia_fluff"
	extra_overlay2 = "zorgoia_fluff_top"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/Easterntail
	name = "Eastern Dragon (Animated)"
	desc = ""
	icon_state = "Easterntail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "EasterntailColorTip"
	ani_state = "Easterntail_w"
	extra_overlay_w = "EasterntailColorTip_w"

/datum/sprite_accessory/tail/synthtail_static
	name = "Synthetic lizard tail"
	desc = ""
	icon_state = "synthtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/synthtail_vwag
	name = "Synthetic lizard tail (vwag)"
	desc = ""
	icon_state = "synthtail"
	ani_state = "synthtail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/Plugtail
	name = "Synthetic plug tail"
	desc = ""
	icon_state = "Plugtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "PlugtailMarking"
	extra_overlay2 = "PlugtailMarking2"

/datum/sprite_accessory/tail/Segmentedtail
	name = "Segmented tail, animated"
	desc = ""
	icon_state = "Segmentedtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "Segmentedtailmarking"
	ani_state = "Segmentedtail_w"
	extra_overlay_w = "Segmentedtailmarking_w"

/datum/sprite_accessory/tail/Segmentedlights
	name = "Segmented tail, animated synth"
	desc = ""
	icon_state = "Segmentedtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "Segmentedlights"
	ani_state = "Segmentedtail_w"
	extra_overlay_w = "Segmentedlights_w"

/datum/sprite_accessory/tail/lizard_tail_smooth
	name = "Lizard Tail (Smooth)"
	desc = ""
	icon_state = "lizard_tail_smooth"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/lizard_tail_dark_tiger
	name = "Lizard Tail (Dark Tiger)"
	desc = ""
	icon_state = "lizard_tail_dark_tiger"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/lizard_tail_light_tiger
	name = "Lizard Tail (Light Tiger)"
	desc = ""
	icon_state = "lizard_tail_light_tiger"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/lizard_tail_spiked
	name = "Lizard Tail (Spiked)"
	desc = ""
	icon_state = "lizard_tail_spiked"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/xenotail_fullcolour
	name = "xenomorph tail (fully colourable)"
	desc = ""
	icon_state = "xenotail_fullcolour"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/xenotailalt_fullcolour
	name = "xenomorph tail alt. (fully colourable)"
	desc = ""
	icon_state = "xenotailalt_fullcolour"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/peacocktail_red //this is ckey locked for now, but prettiebyrd wants these tails to be unlocked at a later date
	name = "Peacock tail (vwag)"
	desc = ""
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "peacocktail_red"
	ani_state = "peacocktail_red_w"
	ckeys_allowed = list("prettiebyrd")

/datum/sprite_accessory/tail/peacocktail //ditto
	name = "Peacock tail, colorable (vwag)"
	desc = ""
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "peacocktail"
	ani_state = "peacocktail_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	ckeys_allowed = list("prettiebyrd")

/datum/sprite_accessory/tail/altevian
	name = "Altevian Tail"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "altevian"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	lower_layer_dirs = list(SOUTH, WEST)

/datum/sprite_accessory/tail/shark_finless
	name = "shark tail, finless (colorable)"
	desc = ""
	icon_state = "sharktail_finless"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/tentacle
	name = "Tentacle, colorable (vwag)"
	icon_state = "tentacle"
	ani_state = "tentacle_w"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/blade_like_tail
	name = "Blade-like Tail"
	icon_state = "blade-like-tail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/sectdrone_tail
	name = "Sect Drone Tail (To use with bodytype-marking)"
	icon_state = "sectdrone_tail"
	extra_overlay = "sectdrone_tail_mark"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/turkey //Would have been a really good thing for Thanksgiving probably but I'm not going to wait that long.
	name = "turkey"
	desc = ""
	icon_state = "turkey"

/datum/sprite_accessory/tail/shark_markings
	name = "akula tail, colorable, tail and fins"
	desc = ""
	icon_state = "sharktail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "sharktail_markings"

/datum/sprite_accessory/tail/shark_stripes
	name = "akula tail, colorable, stripe"
	desc = ""
	icon_state = "sharktail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "sharktail_stripemarkings"

/datum/sprite_accessory/tail/shark_tips
	name = "akula tail, colorable, tips"
	desc = ""
	icon_state = "sharktail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "sharktail_tipmarkings"

/datum/sprite_accessory/tail/narrow_tail
	name = "feathered narrow tail, colorable"
	desc = ""
	icon_state = "narrowtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/narrow_tail2
	name = "feathered narrow tail, 2 colors"
	desc = ""
	icon_state = "narrowtail_2color"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "narrowtail_2color-1"


// Dino Tails

/datum/sprite_accessory/tail/clubtail
	name = "dino clubtail, colorable"
	desc = ""
	icon_state = "clubtail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "clubtail-1"

/datum/sprite_accessory/tail/spiketail
	name = "dino spiketail, colorable"
	desc = ""
	icon_state = "spiketail"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "spiketail-1"

//For all species tails. Includes haircolored tails.
/datum/sprite_accessory/tail/special
	name = "Blank tail. Do not select."
	icon = 'icons/effects/species_tails.dmi'

/datum/sprite_accessory/tail/special/unathi
	name = "unathi tail"
	icon_state = "sogtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/tajaran
	name = "tajaran tail"
	icon_state = "tajtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/sergal
	name = "sergal tail"
	icon_state = "sergtail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/akula
	name = "akula tail"
	icon_state = "sharktail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/nevrean
	name = "nevrean tail"
	icon_state = "nevreantail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/armalis
	name = "armalis tail"
	icon_state = "armalis_tail_humanoid_s"

/datum/sprite_accessory/tail/special/xenodrone
	name = "xenomorph drone tail"
	icon_state = "xenos_drone_tail_s"

/datum/sprite_accessory/tail/special/xenosentinel
	name = "xenomorph sentinel tail"
	icon_state = "xenos_sentinel_tail_s"

/datum/sprite_accessory/tail/special/xenohunter
	name = "xenomorph hunter tail"
	icon_state = "xenos_hunter_tail_s"

/datum/sprite_accessory/tail/special/xenoqueen
	name = "xenomorph queen tail"
	icon_state = "xenos_queen_tail_s"

/datum/sprite_accessory/tail/special/monkey
	name = "monkey tail"
	icon_state = "chimptail_s"

/datum/sprite_accessory/tail/special/tesharitail
	name = "teshari tail"
	icon_state = "seromitail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/tesharitailfeathered
	name = "teshari tail w/ feathers"
	icon_state = "seromitail_s"
	extra_overlay = "seromitail_feathers_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/unathihc
	name = "unathi tail, colorable"
	icon_state = "sogtail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/tajaranhc
	name = "tajaran tail, colorable"
	icon_state = "tajtail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/sergalhc
	name = "sergal tail, colorable"
	icon_state = "sergtail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/akulahc
	name = "akula tail, colorable"
	icon_state = "sharktail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/nevreanhc
	name = "nevrean tail, colorable"
	icon_state = "nevreantail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/foxdefault
	name = "default zorren tail"
	icon = "icons/mob/human_races/r_fox_vr.dmi"
	icon_state = "tail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"default zorren tail, colorable"
	)

/datum/sprite_accessory/tail/special/foxhc
	name = "highlander zorren tail"
	icon_state = "foxtail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"highlander zorren tail, colorable"
	)

/datum/sprite_accessory/tail/special/fennechc
	name = "flatland zorren tail"
	icon_state = "fentail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	backup_name = list(
		"flatland zorren tail, colorable"
	)

/datum/sprite_accessory/tail/special/armalishc
	name = "armalis tail"
	icon_state = "armalis_tail_humanoid_hc_s"
	do_colouration = TRUE
	backup_name = list(
		"armalis tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenodronehc
	name = "xenomorph drone tail"
	icon_state = "xenos_drone_tail_hc_s"
	do_colouration = TRUE
	backup_name = list(
		"xenomorph drone tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenosentinelhc
	name = "xenomorph sentinel tail"
	icon_state = "xenos_sentinel_tail_hc_s"
	do_colouration = TRUE
	backup_name = list(
		"xenomorph sentinel tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenohunterhc
	name = "xenomorph hunter tail"
	icon_state = "xenos_hunter_tail_hc_s"
	do_colouration = TRUE
	backup_name = list(
		"xenomorph hunter tail, colorable"
	)

/datum/sprite_accessory/tail/special/xenoqueenhc
	name = "xenomorph queen tail"
	icon_state = "xenos_queen_tail_hc_s"
	do_colouration = TRUE
	backup_name = list(
		"xenomorph queen tail, colorable"
	)

/datum/sprite_accessory/tail/special/monkeyhc
	name = "monkey tail"
	icon_state = "chimptail_hc_s"
	do_colouration = TRUE
	backup_name = list(
		"monkey tail, colorable"
	)

/datum/sprite_accessory/tail/special/tesharitailhc
	name = "teshari tail, colorable"
	icon_state = "seromitail_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/tesharitailfeatheredhc
	name = "teshari tail w/ feathers, colorable"
	icon_state = "seromitail_feathers_hc_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/special/vulpan
	name = "vulpkanin, colorable"
	icon_state = "vulptail_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

//Buggo Abdomens!

/datum/sprite_accessory/tail/buggo
	name = "Bug abdomen, colorable"
	icon_state = "buggo_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/buggobee
	name = "Bug abdomen, bee top, dual-colorable"
	icon_state = "buggo_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobee_markings"

/datum/sprite_accessory/tail/buggobeefull
	name = "Bug abdomen, bee full, dual-colorable"
	icon_state = "buggo_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobeefull_markings"

/datum/sprite_accessory/tail/buggounder
	name = "Bug abdomen, underside, dual-colorable"
	icon_state = "buggo_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggounder_markings"

/datum/sprite_accessory/tail/buggofirefly
	name = "Bug abdomen, firefly, dual-colorable"
	icon_state = "buggo_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofirefly_markings"

/datum/sprite_accessory/tail/buggofat
	name = "Fat bug abdomen, colorable"
	icon_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/buggofatbee
	name = "Fat bug abdomen, bee top, dual-colorable"
	icon_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatbee_markings"

/datum/sprite_accessory/tail/buggofatbeefull
	name = "Fat bug abdomen, bee full, dual-colorable"
	icon_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatbeefull_markings"

/datum/sprite_accessory/tail/buggofatunder
	name = "Fat bug abdomen, underside, dual-colorable"
	icon_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatunder_markings"

/datum/sprite_accessory/tail/buggofatfirefly
	name = "Fat bug abdomen, firefly, dual-colorable"
	icon_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatfirefly_markings"

/datum/sprite_accessory/tail/buggowag
	name = "Bug abdomen, colorable, vwag change"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/buggobeewag
	name = "Bug abdomen, bee top, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobee_markings"
	extra_overlay_w = "buggofatbee_markings"

/datum/sprite_accessory/tail/buggobeefullwag
	name = "Bug abdomen, bee full, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobeefull_markings"
	extra_overlay_w = "buggofatbeefull_markings"

/datum/sprite_accessory/tail/buggounderwag
	name = "Bug abdomen, underside, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggounder_markings"
	extra_overlay_w = "buggofatunder_markings"

/datum/sprite_accessory/tail/buggofireflywag
	name = "Bug abdomen, firefly, dual color, vwag"
	icon_state = "buggo_s"
	ani_state = "buggofat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofirefly_markings"
	extra_overlay_w = "buggofatfirefly_markings"

//Vass buggo variants!

/datum/sprite_accessory/tail/buggovass
	name = "Bug abdomen, vass, colorable"
	icon_state = "buggo_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/buggovassbee
	name = "Bug abdomen, bee top, dc, vass"
	icon_state = "buggo_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobee_vass_markings"

/datum/sprite_accessory/tail/buggovassbeefull
	name = "Bug abdomen, bee full, dc, vass"
	icon_state = "buggo_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobeefull_vass_markings"

/datum/sprite_accessory/tail/buggovassunder
	name = "Bug abdomen, underside, dc, vass"
	icon_state = "buggo_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggounder_vass_markings"

/datum/sprite_accessory/tail/buggovassfirefly
	name = "Bug abdomen, firefly, dc, vass"
	icon_state = "buggo_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofirefly_vass_markings"

/datum/sprite_accessory/tail/buggovassfat
	name = "Fat bug abdomen, vass, colorable"
	icon_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/buggovassfatbee
	name = "Fat bug abdomen, bee top, dc, vass"
	icon_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatbee_vass_markings"

/datum/sprite_accessory/tail/buggovassfatbeefull
	name = "Fat bug abdomen, bee full, dc, vass"
	icon_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatbeefull_vass_markings"

/datum/sprite_accessory/tail/buggovassfatunder
	name = "Fat bug abdomen, underside, dc, vass"
	icon_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatunder_vass_markings"

/datum/sprite_accessory/tail/buggovassfatfirefly
	name = "Fat bug abdomen, firefly, dc, vass"
	icon_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofatfirefly_vass_markings"

/datum/sprite_accessory/tail/buggovasswag
	name = "Bug abdomen, vass, colorable, vwag change"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/buggovassbeewag
	name = "Bug abdomen, bee top, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobee_vass_markings"
	extra_overlay_w = "buggofatbee_vass_markings"

/datum/sprite_accessory/tail/buggovassbeefullwag
	name = "Bug abdomen, bee full, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggobeefull_vass_markings"
	extra_overlay_w = "buggofatbeefull_vass_markings"

/datum/sprite_accessory/tail/buggovassunderwag
	name = "Bug abdomen, underside, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggounder_vass_markings"
	extra_overlay_w = "buggofatunder_vass_markings"

/datum/sprite_accessory/tail/buggovassfireflywag
	name = "Bug abdomen, firefly, dc, vass, vwag"
	icon_state = "buggo_vass_s"
	ani_state = "buggofat_vass_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "buggofirefly_vass_markings"
	extra_overlay_w = "buggofatfirefly_vass_markings"

/***	Teshari Varient Buggos		***/
/datum/sprite_accessory/tail/teshbeethorax
	name = "Teshari bee thorax"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "beethorax_tesh"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggo
	name = "Teshari bug abdomen, colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbug_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggobee
	name = "Teshari bug abdomen, bee top, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbug_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshbee_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbeefull
	name = "Teshari bug abdomen, bee full, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbug_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshbeefull_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggounder
	name = "Teshari bug abdomen, underside, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbug_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshunder_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/teshbuggofirefly
	name = "Teshari bug abdomen, firefly, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbug_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshfirefly_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggo
	name = "Teshari fat bug abdomen, colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbugfat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggobee
	name = "Teshari fat bug abdomen, bee top, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbugfat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshfatbee_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbeefull
	name = "Teshari fat bug abdomen, bee full, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbugfat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshfatbeefull_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggounder
	name = "Teshari fat bug abdomen, underside, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbugfat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshfatunder_markings"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/tail/fatteshbuggofirefly
	name = "Teshari fat bug abdomen, firefly, dual-colorable"
	icon = 'icons/mob/vore/tails_vr.dmi'
	icon_state = "teshbugfat_s"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY
	extra_overlay = "teshfatfirefly_markings"
	species_allowed = list(SPECIES_TESHARI)

/***	Leg replacements but tails		***/

/datum/sprite_accessory/tail/satyr
	name = "goat legs, colorable"
	icon_state = "satyr"
	color_blend_mode = ICON_MULTIPLY
	do_colouration = TRUE
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT) //Exclude pelvis just in case.
	clip_mask_icon = 'icons/mob/human_races/sprite_accessories/taurs.dmi'
	clip_mask_state = "taur_clip_mask_def" //Used to clip off the lower part of suits & uniforms.

/datum/sprite_accessory/tail/satyrtail
	name = "goat legs with tail, colorable"
	icon_state = "satyr"
	color_blend_mode = ICON_MULTIPLY
	do_colouration = TRUE
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT) //Exclude pelvis just in case.
	clip_mask_icon = 'icons/mob/vore/taurs_vr.dmi'
	clip_mask_state = "taur_clip_mask_def" //Used to clip off the lower part of suits & uniforms.
	extra_overlay = "horse" //I can't believe this works.

/datum/sprite_accessory/tail/synthetic_stilt_legs
	name = "synthetic stilt-legs, colorable"
	icon_state = "synth_stilts"
	color_blend_mode = ICON_MULTIPLY
	do_colouration = TRUE
	extra_overlay = "synth_stilts_marking"
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT) //Exclude pelvis just in case.
	clip_mask_icon = 'icons/mob/vore/taurs_vr.dmi'
	clip_mask_state = "taur_clip_mask_def" //Used to clip off the lower part of suits & uniforms.

//LONG TAILS ARE NOT TAUR BUTTS >:O
/datum/sprite_accessory/tail/longtail
	name = "You should not see this..."
	icon = 'icons/mob/vore/taurs_vr.dmi'
	offset_x = -16
	do_colouration = TRUE // Yes color, using tail color
	color_blend_mode = ICON_MULTIPLY  // The sprites for taurs are designed for ICON_MULTIPLY

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
	icon = 'icons/mob/vore/taurs_vr.dmi'
	icon_state = "zaprat_s"
	extra_overlay = "zaprat_markings"
	do_colouration = TRUE
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/tail/longtail/zaprat/heart
	name = "heart-bolt-shaped tail, dual color"
	icon_state = "zaprat_heart_s"
	extra_overlay = "zaprat_heart_markings"
