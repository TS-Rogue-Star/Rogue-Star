#define VORE_SOUND_FALLOFF 0.1
#define VORE_SOUND_RANGE 3
#define belly_fullscreen_alpha 100 // RS Add || Chomp Port || KH We don't have an ability to set this at the moment but it's outside the scope of what I'm doing

//
//  Belly system 2.0, now using objects instead of datums because EH at datums.
//	How many times have I rewritten bellies and vore now? -Aro
//

// If you change what variables are on this, then you need to update the copy() proc.

//
// Parent type of all the various "belly" varieties.
//
/obj/belly
	name = "belly"							// Name of this location
	desc = "It's a belly! You're in it!"	// Flavor text description of inside sight/sound/smells/feels.
	var/vore_sound = "Gulp"					// Sound when ingesting someone
	var/vore_verb = "ingest"				// Verb for eating with this in messages
	var/release_verb = "expels"				// Verb for releasing something from a stomach
	var/human_prey_swallow_time = 100		// Time in deciseconds to swallow /mob/living/carbon/human
	var/nonhuman_prey_swallow_time = 30		// Time in deciseconds to swallow anything else
	var/nutrition_percent = 100				// Nutritional percentage per tick in digestion mode
	var/digest_brute = 0.5					// Brute damage per tick in digestion mode
	var/digest_burn = 0.5					// Burn damage per tick in digestion mode
	var/digest_oxy = 0						// Oxy damage per tick in digestion mode
	var/digest_tox = 0						// Toxins damage per tick in digestion mode
	var/digest_clone = 0					// Clone damage per tick in digestion mode
	var/immutable = FALSE					// Prevents this belly from being deleted
	var/escapable = FALSE					// Belly can be resisted out of at any time
	var/escapetime = 20 SECONDS				// Deciseconds, how long to escape this belly
	var/selectchance = 0					// % Chance of stomach switching to selective mode if prey struggles // RS add
	var/digestchance = 0					// % Chance of stomach beginning to digest if prey struggles
	var/absorbchance = 0					// % Chance of stomach beginning to absorb if prey struggles
	var/escapechance = 0 					// % Chance of prey beginning to escape if prey struggles.
	var/escapechance_absorbed = 0			// % Chance of absorbed prey finishing an escape. Requires a successful escape roll against the above as well.  //RS edit - copy from virgo
	var/escape_stun = 0						// AI controlled mobs with a number here will be weakened by the provided var when someone escapes, to prevent endless nom loops
	var/transferchance = 0 					// % Chance of prey being trasnsfered, goes from 0-100%
	var/transferchance_secondary = 0 		// % Chance of prey being transfered to transferchance_secondary, also goes 0-100%
	var/save_digest_mode = TRUE				// Whether this belly's digest mode persists across rounds
	var/can_taste = FALSE					// If this belly prints the flavor of prey when it eats someone.
	var/bulge_size = 0.25					// The minimum size the prey has to be in order to show up on examine.
	var/display_absorbed_examine = FALSE	// Do we display absorption examine messages for this belly at all?
	var/absorbed_desc						// Desc shown to absorbed prey. Defaults to regular if left empty.
	var/shrink_grow_size = 1				// This horribly named variable determines the minimum/maximum size it will shrink/grow prey to.
	var/transferlocation					// Location that the prey is released if they struggle and get dropped off.
	var/transferlocation_secondary			// Secondary location that prey is released to.
	var/transferlocation_absorb				// Location that prey is moved to if they get absorbed. //RS add
	var/release_sound = "Splatter"			// Sound for letting someone out. Replaced from True/false
	var/mode_flags = 0						// Stripping, numbing, etc.
	var/fancy_vore = FALSE					// Using the new sounds?
	var/is_wet = TRUE						// Is this belly's insides made of slimy parts?
	var/wet_loop = TRUE						// Does the belly have a fleshy loop playing?
	var/obj/item/weapon/storage/vore_egg/ownegg	// Is this belly creating an egg?
	var/egg_type = "Egg"					// Default egg type and path.
	var/egg_path = /obj/item/weapon/storage/vore_egg
	var/list/list/emote_lists = list()			// Idle emotes that happen on their own, depending on the bellymode. Contains lists of strings indexed by bellymode
	var/emote_time = 60						// How long between stomach emotes at prey (in seconds)
	var/emote_active = TRUE					// Are we even giving emotes out at all or not?
	var/next_emote = 0						// When we're supposed to print our next emote, as a world.time
	var/selective_preference = DM_DIGEST	// Which type of selective bellymode do we default to?
	var/eating_privacy_local = "default"	//Overrides eating_privacy_global if not "default". Determines if attempt/success messages are subtle/loud
	var/silicon_belly_overlay_preference = "Sleeper" //Selects between placing belly overlay in sleeper or normal vore mode. Exclusive
	var/visible_belly_minimum_prey = 1 //What LAZYLEN(vore_selected.contents) we require to show the belly. Customizable
	var/overlay_min_prey_size	= 0 	//Minimum prey size for belly overlay to show. 0 to disable
	var/override_min_prey_size = FALSE	//If true, exceeding override prey number will override minimum size requirements
	var/override_min_prey_num	= 1		//We check belly contents against this to override min size
	var/belly_overall_mult = 1	//Multiplier applied ontop of any other specific multipliers //RS Edit. Added from VS.
	//RS Edit: Ports Slow Body Digestion, CHOMPStation PR 5161
	var/slow_digestion = FALSE
	var/slow_brutal = FALSE
	//RS Edit end

	// Generally just used by AI
	var/autotransferchance = 0 				// % Chance of prey being autotransferred to transfer location
	var/autotransferwait = 10 				// Time between trying to transfer.
	var/autotransferlocation				// Place to send them
	var/autotransferchance_secondary = 0 	// % Chance of prey being autotransferred to secondary transfer location || RS Add || Port Chomp 6155
	var/autotransferlocation_secondary		// Second place to send them || RS Add || Port Chomp 6155
	var/autotransfer_enabled = FALSE		//RS Add Start || Port Chomp 2821, 2979
	var/autotransfer_min_amount = 0			// Minimum amount of things to pass at once.
	var/autotransfer_max_amount = 0			// Maximum amount of things to pass at once.
	var/tmp/list/autotransfer_queue = list()// RS Add End || Reserve for above things.

	//I don't think we've ever altered these lists. making them static until someone actually overrides them somewhere.
	//Actual full digest modes
	var/tmp/static/list/digest_modes = list(DM_HOLD,DM_DIGEST,DM_ABSORB,DM_DRAIN,DM_SELECT,DM_UNABSORB,DM_HEAL,DM_SHRINK,DM_GROW,DM_SIZE_STEAL,DM_EGG)
	//drain modes // RS Edit: Ports VOREStation PR15876
	var/tmp/static/list/drainmodes = list(DR_NORMAL,DR_SLEEP,DR_FAKE,DR_WEIGHT)
	//Digest mode addon flags
	var/tmp/static/list/mode_flag_list = list("Numbing" = DM_FLAG_NUMBING, "Stripping" = DM_FLAG_STRIPPING, "Leave Remains" = DM_FLAG_LEAVEREMAINS, "Muffles" = DM_FLAG_THICKBELLY, "Affect Worn Items" = DM_FLAG_AFFECTWORN, "Jams Sensors" = DM_FLAG_JAMSENSORS, "Complete Absorb" = DM_FLAG_FORCEPSAY, "Slow Body Digestion" = DM_FLAG_SLOWBODY, "Gradual Body Digestion" = DM_FLAG_SLOWBRUTAL)
	//Item related modes
	var/tmp/static/list/item_digest_modes = list(IM_HOLD,IM_DIGEST_FOOD,IM_DIGEST)

	//List of slots that stripping handles strips
	var/tmp/static/list/slots = list(slot_back,slot_handcuffed,slot_l_store,slot_r_store,slot_wear_mask,slot_l_hand,slot_r_hand,slot_wear_id,slot_glasses,slot_gloves,slot_head,slot_shoes,slot_belt,slot_wear_suit,slot_w_uniform,slot_s_store,slot_l_ear,slot_r_ear)

	var/tmp/mob/living/owner					// The mob whose belly this is.
	var/tmp/digest_mode = DM_HOLD				// Current mode the belly is set to from digest_modes (+transform_modes if human)
	var/tmp/list/items_preserved = list()		// Stuff that wont digest so we shouldn't process it again.
	var/tmp/recent_sound = FALSE				// Prevent audio spam
	var/tmp/drainmode = DR_NORMAL				// Simply drains the prey and does nothing // RS Edit || VOREStation PR15876

	// Don't forget to watch your commas at the end of each line if you change these.
	var/list/struggle_messages_outside = list(
		"%pred's %belly wobbles with a squirming meal.",
		"%pred's %belly jostles with movement.",
		"%pred's %belly briefly swells outward as someone pushes from inside.",
		"%pred's %belly fidgets with a trapped victim.",
		"%pred's %belly jiggles with motion from inside.",
		"%pred's %belly sloshes around.",
		"%pred's %belly gushes softly.",
		"%pred's %belly lets out a wet squelch.")

	var/list/struggle_messages_inside = list(
		"Your useless squirming only causes %pred's slimy %belly to squelch over your body.",
		"Your struggles only cause %pred's %belly to gush softly around you.",
		"Your movement only causes %pred's %belly to slosh around you.",
		"Your motion causes %pred's %belly to jiggle.",
		"You fidget around inside of %pred's %belly.",
		"You shove against the walls of %pred's %belly, making it briefly swell outward.",
		"You jostle %pred's %belly with movement.",
		"You squirm inside of %pred's %belly, making it wobble around.")

	var/list/absorbed_struggle_messages_outside = list(
		"%pred's %belly wobbles, seemingly on its own.",
		"%pred's %belly jiggles without apparent cause.",
		"%pred's %belly seems to shake for a second without an obvious reason.")

	var/list/absorbed_struggle_messages_inside = list(
		"You try and resist %pred's %belly, but only cause it to jiggle slightly.",
		"Your fruitless mental struggles only shift %pred's %belly a tiny bit.",
		"You can't make any progress freeing yourself from %pred's %belly.")

	//RS edit start - ports from virgo
	var/list/escape_attempt_messages_owner = list(
		"%prey is attempting to free themselves from your %belly!")

	var/list/escape_attempt_messages_prey = list(
		"You start to climb out of %pred's %belly.")

	var/list/escape_messages_owner = list(
		"%prey climbs out of your %belly!")

	var/list/escape_messages_prey = list(
		"You climb out of %pred's %belly.")

	var/list/escape_messages_outside = list(
		"%prey climbs out of %pred's %belly!")

	var/list/escape_item_messages_owner = list(
		"%item suddenly slips out of your %belly!")

	var/list/escape_item_messages_prey = list(
		"Your struggles successfully cause %pred to squeeze your %item out of their %belly.")

	var/list/escape_item_messages_outside = list(
		"%item suddenly slips out of %pred's %belly!")

	var/list/escape_fail_messages_owner = list(
		"%prey's attempt to escape from your %belly has failed!")

	var/list/escape_fail_messages_prey = list(
		"Your attempt to escape %pred's %belly has failed!")

	var/list/escape_attempt_absorbed_messages_owner = list(
		"%prey is attempting to free themselves from your %belly!")

	var/list/escape_attempt_absorbed_messages_prey = list(
		"You try to force yourself out of %pred's %belly.")

	var/list/escape_absorbed_messages_owner = list(
		"%prey forces themselves free of your %belly!")

	var/list/escape_absorbed_messages_prey = list(
		"You manage to free yourself from %pred's %belly.")

	var/list/escape_absorbed_messages_outside = list(
		"%prey climbs out of %pred's %belly!")

	var/list/escape_fail_absorbed_messages_owner = list(
		"%prey's attempt to escape form your %belly has failed!")

	var/list/escape_fail_absorbed_messages_prey = list(
		"Before you manage to reach freedom, you feel yourself getting dragged back into %pred's %belly!")

	var/list/primary_transfer_messages_owner = list(
		"%prey slid into your %dest due to their struggling inside your %belly!")

	var/list/primary_transfer_messages_prey = list(
		"Your attempt to escape %pred's %belly has failed and your struggles only results in you sliding into pred's %dest!")

	var/list/secondary_transfer_messages_owner = list(
		"%prey slid into your %dest due to their struggling inside your %belly!")

	var/list/secondary_transfer_messages_prey = list(
		"Your attempt to escape %pred's %belly has failed and your struggles only results in you sliding into pred's %dest!")

	var/list/digest_chance_messages_owner = list(
		"You feel your %belly beginning to become active!")

	var/list/digest_chance_messages_prey = list(
		"In response to your struggling, %pred's %belly begins to get more active...")

	var/list/absorb_chance_messages_owner = list(
		"You feel your %belly start to cling onto its contents...")

	var/list/absorb_chance_messages_prey = list(
		"In response to your struggling, %pred's %belly begins to cling more tightly...")
	//RS EDIT END
	var/list/select_chance_messages_owner = list(
		"You feel your %belly beginning to become active!")

	var/list/select_chance_messages_prey = list(
		"In response to your struggling, %pred's %belly begins to get more active...")
	//RS edit end

	var/list/digest_messages_owner = list(
		"You feel %prey's body succumb to your digestive system, which breaks it apart into soft slurry.",
		"You hear a lewd glorp as your %belly muscles grind %prey into a warm pulp.",
		"Your %belly lets out a rumble as it melts %prey into sludge.",
		"You feel a soft gurgle as %prey's body loses form in your %belly. They're nothing but a soft mass of churning slop now.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your thighs.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your rump.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your belly.",
		"Your %belly groans as %prey falls apart into a thick soup. You can feel their remains soon flowing deeper into your body to be absorbed.",
		"Your %belly kneads on every fiber of %prey, softening them down into mush to fuel your next hunt.",
		"Your %belly churns %prey down into a hot slush. You can feel the nutrients coursing through your digestive track with a series of long, wet glorps.")

	var/list/digest_messages_prey = list(
		"Your body succumbs to %pred's digestive system, which breaks you apart into soft slurry.",
		"%pred's %belly lets out a lewd glorp as their muscles grind you into a warm pulp.",
		"%pred's %belly lets out a rumble as it melts you into sludge.",
		"%pred feels a soft gurgle as your body loses form in their %belly. You're nothing but a soft mass of churning slop now.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's thighs.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's rump.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's belly.",
		"%pred's %belly groans as you fall apart into a thick soup. Your remains soon flow deeper into %pred's body to be absorbed.",
		"%pred's %belly kneads on every fiber of your body, softening you down into mush to fuel their next hunt.",
		"%pred's %belly churns you down into a hot slush. Your nutrient-rich remains course through their digestive track with a series of long, wet glorps.")

	var/list/absorb_messages_owner = list(
		"You feel %prey becoming part of you.")

	var/list/absorb_messages_prey = list(
		"You feel yourself becoming part of %pred's %belly!")

	var/list/unabsorb_messages_owner = list(
		"You feel %prey reform into a recognizable state again.")

	var/list/unabsorb_messages_prey = list(
		"You are released from being part of %pred's %belly.")

	var/list/examine_messages = list(
		"They have something solid in their %belly!",
		"It looks like they have something in their %belly!")

	var/list/examine_messages_absorbed = list(
		"Their body looks somewhat larger than usual around the area of their %belly.",
		"Their %belly looks larger than usual.")

	var/item_digest_mode = IM_DIGEST_FOOD	// Current item-related mode from item_digest_modes
	var/contaminates = FALSE					// Whether the belly will contaminate stuff
	var/contamination_flavor = "Generic"	// Determines descriptions of contaminated items
	var/contamination_color = "green"		// Color of contamination overlay

	// Lets you do a fullscreen overlay. Set to an icon_state string.
	var/belly_fullscreen = ""
	var/disable_hud = FALSE
	var/colorization_enabled = FALSE
	var/belly_fullscreen_color = "#823232"
	var/belly_fullscreen_color_secondary = "#428242"
	var/belly_fullscreen_color_trinary = "#f0f0f0"

	var/belly_healthbar_overlay_theme	//RS ADD
	var/belly_healthbar_overlay_color	//RS ADD

//For serialization, keep this updated, required for bellies to save correctly.
/obj/belly/vars_to_save()
	var/list/saving = list(
	"name",
	"desc",
	"absorbed_desc",
	"vore_sound",
	"vore_verb",
	"release_verb",
	"human_prey_swallow_time",
	"nonhuman_prey_swallow_time",
	"emote_time",
	"nutrition_percent",
	"digest_brute",
	"digest_burn",
	"digest_oxy",
	"digest_tox",
	"digest_clone",
	"immutable",
	"can_taste",
	"escapable",
	"escapetime",
	"digestchance",
	"absorbchance",
	"escapechance",
	"transferchance",
	"transferchance_secondary",
	"transferlocation",
	"transferlocation_secondary",
	"bulge_size",
	"display_absorbed_examine",
	"shrink_grow_size",
	"struggle_messages_outside",
	"struggle_messages_inside",
	"absorbed_struggle_messages_outside",
	"absorbed_struggle_messages_inside",
	"digest_messages_owner",
	"digest_messages_prey",
	"absorb_messages_owner",
	"absorb_messages_prey",
	"unabsorb_messages_owner",
	"unabsorb_messages_prey",
	"examine_messages",
	"examine_messages_absorbed",
	"emote_lists",
	"emote_time",
	"emote_active",
	"selective_preference",
	"mode_flags",
	"item_digest_mode",
	"contaminates",
	"contamination_flavor",
	"contamination_color",
	"release_sound",
	"fancy_vore",
	"is_wet",
	"wet_loop",
	"belly_fullscreen",
	"disable_hud",
	"belly_fullscreen_color",
	"belly_fullscreen_color_secondary",
	"belly_fullscreen_color_trinary",
	"colorization_enabled",
	"egg_type",
	"save_digest_mode",
	"eating_privacy_local",
	"silicon_belly_overlay_preference",
	"visible_belly_minimum_prey",
	"overlay_min_prey_size",
	"override_min_prey_size",
	"override_min_prey_num",
	"vore_sprite_flags", 						//RS edit
	"affects_vore_sprites", 					//RS edit
	"count_absorbed_prey_for_sprite", 			//RS edit
	"resist_triggers_animation", 				//RS edit
	"size_factor_for_sprite", 					//RS edit
	"belly_sprite_to_affect", 					//RS edit
	"health_impacts_size", 						//RS edit
	"count_items_for_sprite", 					//RS edit
	"item_multiplier", 							//RS edit
	"drainmode",								//RS edit || Ports VOREStation PR15876
	"slow_digestion",							//RS Edit || Ports CHOMPStation PR 5161
	"slow_brutal",								//RS Edit || Ports CHOMPStation Pr 5161
	"reagent_mode_flags",	// Begin reagent bellies || RS Add || Chomp Port
	"show_liquids",
	"reagentbellymode",
	"count_liquid_for_sprite",
	"liquid_multiplier",
	"liquid_fullness1_messages",
	"liquid_fullness2_messages",
	"liquid_fullness3_messages",
	"liquid_fullness4_messages",
	"liquid_fullness5_messages",
	"reagent_name",
	"reagent_chosen",
	"reagentid",
	"reagentcolor",
	"gen_cost",
	"gen_amount",
	"gen_time",
	"gen_time_display",
	"custom_max_volume",
	"generated_reagents",
	"vorefootsteps_sounds",
	"liquid_overlay",
	"max_liquid_level",
	"reagent_touches",
	"mush_overlay",
	"mush_color",
	"mush_alpha",
	"max_mush",
	"min_mush",
	"show_fullness_messages",
	"custom_reagentcolor",
	"custom_reagentalpha",
	"fullness1_messages",
	"fullness2_messages",
	"fullness3_messages",
	"fullness4_messages",
	"fullness5_messages",	// End reagent bellies
	"autotransferchance",  //RS Add Start || Port Chop 2821, 2979, 6155
	"autotransferwait",
	"autotransferlocation",
	"autotransfer_enabled",
	"autotransferchance_secondary",
	"autotransferlocation_secondary",
	"autotransfer_min_amount",
	"autotransfer_max_amount",
	"belly_healthbar_overlay_theme",
	"belly_healthbar_overlay_color"		//RS ADD END
	)

	if (save_digest_mode == 1)
		return ..() + saving + list("digest_mode")

	return ..() + saving

/obj/belly/Initialize()
	. = ..()
	//If not, we're probably just in a prefs list or something.
	if(ismob(loc))
		owner = loc
		owner.vore_organs |= src
		if(isliving(loc))
			START_PROCESSING(SSbellies, src)
	create_reagents(300)	// Begin reagent bellies || RS Add || Chomp Port
	flags |= NOREACT	// End reagent bellies

/obj/belly/Destroy()
	STOP_PROCESSING(SSbellies, src)
	owner?.vore_organs?.Remove(src)
	owner = null
	for(var/mob/observer/G in src)
		G.forceMove(get_turf(src)) //RSEdit: Ports kicking ghosts out of deleted vorgans, CHOMPStation PR#7132
	return ..()

// Called whenever an atom enters this belly
/obj/belly/Entered(atom/movable/thing, atom/OldLoc)

	thing.belly_cycles = 0 //RS Add || Chomp port 2934 || reset cycle count

	if(istype(thing, /mob/observer)) //RSEdit: Ports keeping a ghost in a vorebelly, CHOMPStation PR#3072
		if(desc) //RSEdit: Ports letting ghosts see belly descriptions on transfer, CHOMPStation PR#4772
			//Allow ghosts see where they are if they're still getting squished along inside.
			var/formatted_desc
			formatted_desc = replacetext(desc, "%belly", lowertext(name)) //replace with this belly's name
			formatted_desc = replacetext(formatted_desc, "%pred", owner) //replace with this belly's owner
			formatted_desc = replacetext(formatted_desc, "%prey", thing) //replace with whatever mob entered into this belly
			to_chat(thing, "<span class='notice'><B>[formatted_desc]</B></span>")

	if(owner && istype(owner.loc,/turf/simulated) && !cycle_sloshed && reagents.total_volume > 0) // Begin reagent bellies || RS Add || Chomp Port
		var/turf/simulated/T = owner.loc
		var/S = pick(T.vorefootstep_sounds["human"])
		if(S)
			playsound(T, S, 50 * (reagents.total_volume / custom_max_volume), FALSE, preference = /datum/client_preference/digestion_noises)
			cycle_sloshed = TRUE // End reagent bellies

	if(OldLoc in contents)
		return //Someone dropping something (or being stripdigested)

	//Generic entered message
	to_chat(owner,"<span class='notice'>[thing] slides into your [lowertext(name)].</span>")

	//Sound w/ antispam flag setting
	if(vore_sound && !recent_sound && !istype(thing, /mob/observer)) //RSEdit: Ports VOREStation PR15918 || does not play vorebelly insertion sound upon ghost entering
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_vore_sounds[vore_sound]
		else
			soundfile = fancy_vore_sounds[vore_sound]
		if(soundfile)
			playsound(src, soundfile, vol = 100, vary = 1, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/eating_noises, volume_channel = VOLUME_CHANNEL_VORE)
			recent_sound = TRUE

	if(reagents.total_volume >= 5 && !isliving(thing)) // Reagent bellies || RS Add || Chomp Port
		reagents.trans_to(thing, reagents.total_volume, 0.1 / (LAZYLEN(contents) ? LAZYLEN(contents) : 1), FALSE)
		to_chat(thing, "<span class='warning'><B>You splash into a pool of [reagent_name]!</B></span>") // End reagent bellies

	//Messages if it's a mob
	if(isliving(thing))
		var/mob/living/M = thing
		M.updateVRPanel()
		var/raw_desc //Let's use this to avoid needing to write the reformat code twice
		if(absorbed_desc && M.absorbed)
			raw_desc = absorbed_desc
		else if(desc)
			raw_desc = desc

		//Was there a description text? If so, it's time to format it!
		if(raw_desc)
			//Replace placeholder vars
			var/formatted_desc
			formatted_desc = replacetext(raw_desc, "%belly", lowertext(name)) //replace with this belly's name
			formatted_desc = replacetext(formatted_desc, "%pred", owner) //replace with this belly's owner
			formatted_desc = replacetext(formatted_desc, "%prey", M) //replace with whatever mob entered into this belly
			to_chat(M, "<span class='notice'><B>[formatted_desc]</B></span>")

		var/taste
		if(can_taste && (taste = M.get_taste_message(FALSE)))
			to_chat(owner, "<span class='notice'>[M] tastes of [taste].</span>")
		vore_fx(M)
		//Stop AI processing in bellies
		if(M.ai_holder)
			M.ai_holder.handle_eaten()

		if(reagents.total_volume >= 5 && M.digestable) // Reagent bellies || RS Add || Chomp Port
			if(digest_mode == DM_DIGEST)
				reagents.trans_to(M, reagents.total_volume * 0.1, 1 / max(LAZYLEN(contents), 1), FALSE)
			to_chat(M, "<span class='warning'><B>You splash into a pool of [reagent_name]!</B></span>") // End reagent bellies

		// Begin RS edit
		if (istype(owner, /mob/living/carbon/human))
			owner:update_fullness()

		if(owner.client)
			if(owner.client.is_preference_enabled(/datum/client_preference/vore_health_bars))
				new /obj/screen/movable/rs_ui/healthbar(owner,M,owner)
		if(M.client)
			if(M.client.is_preference_enabled(/datum/client_preference/vore_health_bars))
				new /obj/screen/movable/rs_ui/healthbar(M,M,M)

		// End RS edit

	/*/ Intended for simple mobs  //RS Add || Chomp Port 2934 || Counting belly cycles now.
	if(!owner.client || autotransfer_enabled && autotransferlocation && autotransferchance > 0)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/belly, check_autotransfer), thing, autotransferlocation), autotransferwait) */

// Called whenever an atom leaves this belly
/obj/belly/Exited(atom/movable/thing, atom/OldLoc)
	. = ..()
	if(isliving(thing) && !isbelly(thing.loc))
		var/mob/living/L = thing
		L.clear_fullscreen("belly")
		L.clear_fullscreen("belly2")
		L.clear_fullscreen("belly3")
		L.clear_fullscreen("belly4")
		L.clear_fullscreen("belly5") // Reagent bellies || RS Add || Chomp Port
		if(L.hud_used)
			if(!L.hud_used.hud_shown)
				L.toggle_hud_vis()
		if((L.stat != DEAD) && L.ai_holder)
			L.ai_holder.go_wake()

	// Begin RS edit
	if (istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/hum = owner
		hum.update_fullness()
	// End RS edit

/obj/belly/proc/vore_fx(mob/living/L)
	if(!istype(L))
		return
	if(!L.client)
		return
	if(!L.show_vore_fx)
		L.clear_fullscreen("belly")
		return

	var/image/ReagentImages = null //Reagent bellies || RS Add || Chomp Port

	if(belly_fullscreen)
		if(colorization_enabled)
			var/obj/screen/fullscreen/F = L.overlay_fullscreen("belly", /obj/screen/fullscreen/belly/colorized)
			F.icon_state = belly_fullscreen
			F.color = belly_fullscreen_color
			if("[belly_fullscreen]_l1" in icon_states('icons/mob/screen_full_colorized_vore_overlays.dmi'))
				var/obj/screen/fullscreen/F2 = L.overlay_fullscreen("belly2", /obj/screen/fullscreen/belly/colorized/overlay)
				F2.icon_state = "[belly_fullscreen]_l1"
				F2.color = belly_fullscreen_color_secondary
			else
				L.clear_fullscreen("belly2")
			if("[belly_fullscreen]_l2" in icon_states('icons/mob/screen_full_colorized_vore_overlays.dmi'))
				var/obj/screen/fullscreen/F3 = L.overlay_fullscreen("belly3", /obj/screen/fullscreen/belly/colorized/overlay)
				F3.icon_state = "[belly_fullscreen]_l2"
				F3.color = belly_fullscreen_color_trinary
			else
				L.clear_fullscreen("belly3")
			if("[belly_fullscreen]_nc" in icon_states('icons/mob/screen_full_colorized_vore_overlays.dmi'))
				var/obj/screen/fullscreen/F4 = L.overlay_fullscreen("belly4", /obj/screen/fullscreen/belly/colorized/overlay)
				F4.icon_state = "[belly_fullscreen]_nc"
			else
				L.clear_fullscreen("belly4")
			var/obj/screen/fullscreen/F5 = L.overlay_fullscreen("belly5", /obj/screen/fullscreen/belly/colorized/overlay) // Reagent bellies || RS Add || Chomp Port
			F5.icon_state = belly_fullscreen //Reagent bellies || RS Add || Chomp Port
			if(L.liquidbelly_visuals && mush_overlay && (owner.nutrition > 0 || max_mush == 0 || min_mush > 0)) // Reagent bellies start || RS Add || Chomp Port
				ReagentImages = image('icons/mob/vore/bubbles.dmi', "mush")
				ReagentImages.color = mush_color
				ReagentImages.alpha = mush_alpha
				ReagentImages.pixel_y = -450 + (450 / max(max_mush, 1) * max(min(max_mush, owner.nutrition), 1))
				if(ReagentImages.pixel_y < -450 + (450 / 100 * min_mush))
					ReagentImages.pixel_y = -450 + (450 / 100 * min_mush)
				F5.add_overlay(ReagentImages)
			if(L.liquidbelly_visuals && liquid_overlay && reagents.total_volume)
				if(digest_mode == DM_HOLD && item_digest_mode == IM_HOLD)
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "calm")
				else
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "bubbles")
				if(custom_reagentcolor)
					ReagentImages.color = custom_reagentcolor
				else
					ReagentImages.color = reagentcolor
				if(custom_reagentalpha)
					ReagentImages.alpha = custom_reagentalpha
				else
					ReagentImages.alpha = max(150, min(custom_max_volume, 255)) - (255 - belly_fullscreen_alpha)
				ReagentImages.pixel_y = -450 + min((450 / custom_max_volume * reagents.total_volume), 450 / 100 * max_liquid_level)
				F5.add_overlay(ReagentImages) // End reagent bellies
		else
			var/obj/screen/fullscreen/F = L.overlay_fullscreen("belly", /obj/screen/fullscreen/belly)
			var/obj/screen/fullscreen/F5 = L.overlay_fullscreen("belly5", /obj/screen/fullscreen/belly/colorized/overlay) //Reagent bellies || RS Add || Chomp Port
			F.icon_state = belly_fullscreen
			F5.icon_state = belly_fullscreen //Reagent bellies || RS Add || Chomp Port
			if(L.liquidbelly_visuals && mush_overlay && (owner.nutrition > 0 || max_mush == 0 || min_mush > 0)) // Reagent bellies start || RS Add || Chomp Port
				ReagentImages = image('icons/mob/vore/bubbles.dmi', "mush")
				ReagentImages.color = mush_color
				ReagentImages.alpha = mush_alpha
				ReagentImages.pixel_y = -450 + (450 / max(max_mush, 1) * max(min(max_mush, owner.nutrition), 1))
				if(ReagentImages.pixel_y < -450 + (450 / 100 * min_mush))
					ReagentImages.pixel_y = -450 + (450 / 100 * min_mush)
				F5.add_overlay(ReagentImages)
			if(L.liquidbelly_visuals && liquid_overlay && reagents.total_volume)
				if(digest_mode == DM_HOLD && item_digest_mode == IM_HOLD)
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "calm")
				else
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "bubbles")
				if(custom_reagentcolor)
					ReagentImages.color = custom_reagentcolor
				else
					ReagentImages.color = reagentcolor
				if(custom_reagentalpha)
					ReagentImages.alpha = custom_reagentalpha
				else
					ReagentImages.alpha = max(150, min(custom_max_volume, 255)) - (255 - belly_fullscreen_alpha)
				ReagentImages.pixel_y = -450 + min((450 / custom_max_volume * reagents.total_volume), 450 / 100 * max_liquid_level)
				F5.add_overlay(ReagentImages) // End reagent bellies
	else
		L.clear_fullscreen("belly")
		L.clear_fullscreen("belly2")
		L.clear_fullscreen("belly3")
		L.clear_fullscreen("belly4")
		L.clear_fullscreen("belly5") // Reagent bellies || RS Add || Chomp Port

	if(disable_hud)
		if(L?.hud_used?.hud_shown)
			to_chat(L, "<span class='notice'>((Your pred has disabled huds in their belly. Turn off vore FX and hit F12 to get it back; or relax, and enjoy the serenity.))</span>")
			L.toggle_hud_vis(TRUE)

/obj/belly/proc/vore_preview(mob/living/L)
	if(!istype(L))
		return
	if(!L.client)
		return

	var/image/ReagentImages = null //Reagent bellies || RS Add || Chomp Port

	if(belly_fullscreen)
		if(colorization_enabled)
			var/obj/screen/fullscreen/F = L.overlay_fullscreen("belly", /obj/screen/fullscreen/belly/colorized)
			F.icon_state = belly_fullscreen
			F.color = belly_fullscreen_color
			if("[belly_fullscreen]_l1" in icon_states('icons/mob/screen_full_colorized_vore_overlays.dmi'))
				var/obj/screen/fullscreen/F2 = L.overlay_fullscreen("belly2", /obj/screen/fullscreen/belly/colorized/overlay)
				F2.icon_state = "[belly_fullscreen]_l1"
				F2.color = belly_fullscreen_color_secondary
			if("[belly_fullscreen]_l2" in icon_states('icons/mob/screen_full_colorized_vore_overlays.dmi'))
				var/obj/screen/fullscreen/F3 = L.overlay_fullscreen("belly3", /obj/screen/fullscreen/belly/colorized/overlay)
				F3.icon_state = "[belly_fullscreen]_l2"
				F3.color = belly_fullscreen_color_trinary
			if("[belly_fullscreen]_nc" in icon_states('icons/mob/screen_full_colorized_vore_overlays.dmi'))
				var/obj/screen/fullscreen/F4 = L.overlay_fullscreen("belly4", /obj/screen/fullscreen/belly/colorized/overlay)
				F4.icon_state = "[belly_fullscreen]_nc"
			var/obj/screen/fullscreen/F5 = L.overlay_fullscreen("belly5", /obj/screen/fullscreen/belly/colorized/overlay)  //Reagent bellies || RS Add || Chomp Port
			F5.icon_state = belly_fullscreen //Reagent bellies || RS Add || Chomp Port
			if(L.liquidbelly_visuals && mush_overlay && (owner.nutrition > 0 || max_mush == 0 || min_mush > 0)) // Reagent bellies start || RS Add || Chomp Port
				ReagentImages = image('icons/mob/vore/bubbles.dmi', "mush")
				ReagentImages.color = mush_color
				ReagentImages.alpha = mush_alpha
				ReagentImages.pixel_y = -450 + (450 / max(max_mush, 1) * max(min(max_mush, owner.nutrition), 1))
				if(ReagentImages.pixel_y < -450 + (450 / 100 * min_mush))
					ReagentImages.pixel_y = -450 + (450 / 100 * min_mush)
				F5.add_overlay(ReagentImages)
			if(L.liquidbelly_visuals && liquid_overlay && reagents.total_volume)
				if(digest_mode == DM_HOLD && item_digest_mode == IM_HOLD)
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "calm")
				else
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "bubbles")
				if(custom_reagentcolor)
					ReagentImages.color = custom_reagentcolor
				else
					ReagentImages.color = reagentcolor
				if(custom_reagentalpha)
					ReagentImages.alpha = custom_reagentalpha
				else
					ReagentImages.alpha = max(150, min(custom_max_volume, 255)) - (255 - belly_fullscreen_alpha)
				ReagentImages.pixel_y = -450 + min((450 / custom_max_volume * reagents.total_volume), 450 / 100 * max_liquid_level)
				F5.add_overlay(ReagentImages) // End reagent bellies
		else
			var/obj/screen/fullscreen/F = L.overlay_fullscreen("belly", /obj/screen/fullscreen/belly)
			var/obj/screen/fullscreen/F5 = L.overlay_fullscreen("belly5", /obj/screen/fullscreen/belly/colorized/overlay) //Reagent bellies || RS Add || Chomp Port
			F.icon_state = belly_fullscreen
			F5.icon_state = belly_fullscreen //Reagent bellies || RS Add || Chomp Port
			if(L.liquidbelly_visuals && mush_overlay && (owner.nutrition > 0 || max_mush == 0 || min_mush > 0)) // Reagent bellies start || RS Add || Chomp Port
				ReagentImages = image('icons/mob/vore/bubbles.dmi', "mush")
				ReagentImages.color = mush_color
				ReagentImages.alpha = mush_alpha
				ReagentImages.pixel_y = -450 + (450 / max(max_mush, 1) * max(min(max_mush, owner.nutrition), 1))
				if(ReagentImages.pixel_y < -450 + (450 / 100 * min_mush))
					ReagentImages.pixel_y = -450 + (450 / 100 * min_mush)
				F5.add_overlay(ReagentImages)
			if(L.liquidbelly_visuals && liquid_overlay && reagents.total_volume)
				if(digest_mode == DM_HOLD && item_digest_mode == IM_HOLD)
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "calm")
				else
					ReagentImages = image('icons/mob/vore/bubbles.dmi', "bubbles")
				if(custom_reagentcolor)
					ReagentImages.color = custom_reagentcolor
				else
					ReagentImages.color = reagentcolor
				if(custom_reagentalpha)
					ReagentImages.alpha = custom_reagentalpha
				else
					ReagentImages.alpha = max(150, min(custom_max_volume, 255)) - (255 - belly_fullscreen_alpha)
				ReagentImages.pixel_y = -450 + min((450 / custom_max_volume * reagents.total_volume), 450 / 100 * max_liquid_level)
				F5.add_overlay(ReagentImages) // End reagent bellies
	else
		L.clear_fullscreen("belly")
		L.clear_fullscreen("belly2")
		L.clear_fullscreen("belly3")
		L.clear_fullscreen("belly4")
		L.clear_fullscreen("belly5") // Reagent bellies || RS Add || Chomp Port

/obj/belly/proc/clear_preview(mob/living/L)
	L.clear_fullscreen("belly")
	L.clear_fullscreen("belly2")
	L.clear_fullscreen("belly3")
	L.clear_fullscreen("belly4")
	L.clear_fullscreen("belly5") // Reagent bellies || RS Add || Chomp Port



// Release all contents of this belly into the owning mob's location.
// If that location is another mob, contents are transferred into whichever of its bellies the owning mob is in.
// Returns the number of mobs so released.
/obj/belly/proc/release_all_contents(include_absorbed = FALSE, silent = FALSE, include_bones = FALSE)	//RS EDIT
	//Don't bother if we don't have contents
	if(!contents.len)
		return FALSE

	//Find where we should drop things into (certainly not the owner)
	var/count = 0

	//Iterate over contents and move them all
	for(var/atom/movable/AM as anything in contents)
		if(isliving(AM))
			var/mob/living/L = AM
			if(L.stat) //RS Edit || Ports VOREStation PR 15876
				L.SetSleeping(min(L.sleeping,20)) //RS Edit End
			if(L.absorbed && !include_absorbed)
				continue
		if(istype(AM, /obj/item/weapon/digestion_remains) && !include_bones)	// RS ADD
			continue	//RS ADD
		count += release_specific_contents(AM, silent = TRUE)

	//Clean up our own business
	items_preserved.Cut()
	if(!ishuman(owner))
		owner.update_icons()

	//Determines privacy
	var/privacy_range = world.view
	var/privacy_volume = 100
	switch(eating_privacy_local) //Third case of if("loud") not defined, as it'd just leave privacy_range and volume untouched
		if("default")
			if(owner.eating_privacy_global)
				privacy_range = 1
				privacy_volume = 25
		if("subtle")
			privacy_range = 1
			privacy_volume = 25

	//Print notifications/sound if necessary
	if(!silent && count)
		owner.visible_message("<font color='green'><b>[owner] [release_verb] everything from their [lowertext(name)]!</b></font>", range = privacy_range)
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_release_sounds[release_sound]
		else
			soundfile = fancy_release_sounds[release_sound]
		if(soundfile)
			playsound(src, soundfile, vol = privacy_volume, vary = 1, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/eating_noises, volume_channel = VOLUME_CHANNEL_VORE)

	return count

// Release a specific atom from the contents of this belly into the owning mob's location.
// If that location is another mob, the atom is transferred into whichever of its bellies the owning mob is in.
// Returns the number of atoms so released.
/obj/belly/proc/release_specific_contents(atom/movable/M, silent = FALSE)
	if (!(M in contents))
		return 0 // They weren't in this belly anyway

	if(istype(M, /mob/living/simple_mob/vore/morph/dominated_prey))
		var/mob/living/simple_mob/vore/morph/dominated_prey/p = M
		p.undo_prey_takeover(FALSE)
		return 0
	for(var/mob/living/L in M.contents)
		L.muffled = FALSE
		L.forced_psay = FALSE

	for(var/obj/item/weapon/holder/H in M.contents)
		H.held_mob.muffled = FALSE
		H.held_mob.forced_psay = FALSE

	if(isliving(M))
		var/mob/living/slip = M
		slip.slip_protect = world.time + 25 // This is to prevent slipping back into your pred if they stand on soap or something.
	//Place them into our drop_location
	M.forceMove(drop_location())
	if(ismob(M))
		var/mob/ourmob = M
		ourmob.reset_view(null)
	items_preserved -= M

	//Special treatment for absorbed prey
	if(isliving(M))
		var/mob/living/ML = M
		var/mob/living/OW = owner
		if(ML.client)
			ML.stop_sound_channel(CHANNEL_PREYLOOP) //Stop the internal loop, it'll restart if the isbelly check on next tick anyway
		if(ML.muffled)
			ML.muffled = FALSE
		if(ML.forced_psay)
			ML.forced_psay = FALSE
		if(ML.absorbed)
			ML.absorbed = FALSE
			handle_absorb_langs(ML, owner)
			if(ishuman(M) && ishuman(OW))
				var/mob/living/carbon/human/Prey = M
				var/mob/living/carbon/human/Pred = OW
				var/absorbed_count = 2 //Prey that we were, plus the pred gets a portion
				for(var/mob/living/P in contents)
					if(P.absorbed)
						absorbed_count++
				Pred.bloodstr.trans_to(Prey, Pred.reagents.total_volume / absorbed_count)

	//RS Edit || Ports VOREStation PR15876
	//Makes it so that if prey are heavily asleep, they will wake up shortly after release
	if(isliving(M))
		var/mob/living/ML = M
		if(ML.stat)
			ML.SetSleeping(min(ML.sleeping,20))
	//RS Edit End

	//Clean up our own business
	if(!ishuman(owner))
		owner.update_icons()

	//Determines privacy
	var/privacy_range = world.view
	var/privacy_volume = 100
	switch(eating_privacy_local) //Third case of if("loud") not defined, as it'd just leave privacy_range and volume untouched
		if("default")
			if(owner.eating_privacy_global)
				privacy_range = 1
				privacy_volume = 25
		if("subtle")
			privacy_range = 1
			privacy_volume = 25

	//Print notifications/sound if necessary
	if(!silent && !isobserver(M)) //RSEdit: Ports VOREStation PR15918 | Don't display release message for ghosts
		owner.visible_message("<font color='green'><b>[owner] [release_verb] [M] from their [lowertext(name)]!</b></font>",range = privacy_range)
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_release_sounds[release_sound]
		else
			soundfile = fancy_release_sounds[release_sound]
		if(soundfile)
			playsound(src, soundfile, vol = privacy_volume, vary = 1, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/eating_noises, volume_channel = VOLUME_CHANNEL_VORE)

	if(!owner.ckey && escape_stun)
		owner.Weaken(escape_stun)
	if(istype(M,/obj/effect/overmap/visitable/ship))	// RS EDIT START
		var/obj/effect/overmap/visitable/ship/S = M
		SSskybox.rebuild_skyboxes(S.map_z)	// RS EDIT END
	return 1

// Actually perform the mechanics of devouring the tasty prey.
// The purpose of this method is to avoid duplicate code, and ensure that all necessary
// steps are taken.
/obj/belly/proc/nom_mob(mob/prey, mob/user)
	if(owner.stat == DEAD)
		return
	if(prey.buckled)
		prey.buckled.unbuckle_mob()

	prey.forceMove(src)
	if(ismob(prey))
		var/mob/ourmob = prey
		ourmob.reset_view(owner)
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()

	for(var/mob/living/M in contents)
		M.updateVRPanel()

	if(prey.ckey)
		GLOB.prey_eaten_roundstat++
		if(owner.mind)
			owner.mind.vore_prey_eaten++

	//RS ADD START
	if(GLOB.vore_game)
		vore_game(owner,prey)
	//RS ADD END

// Get the line that should show up in Examine message if the owner of this belly
// is examined.   By making this a proc, we not only take advantage of polymorphism,
// but can easily make the message vary based on how many people are inside, etc.
// Returns a string which shoul be appended to the Examine output.
/obj/belly/proc/get_examine_msg()
	if(!(contents.len) || !(examine_messages.len))
		return ""

	var/formatted_message
	var/raw_message = pick(examine_messages)
	var/total_bulge = 0

	var/living_count = 0
	for(var/mob/living/L in contents)
		living_count++

	//RSEdit Start || Ports fixes from VOREStation PR#15918
	var/count_total = contents.len
	for(var/mob/observer/C in contents)
		count_total-- //Exclude any ghosts from %count

	var/list/vore_contents = list()
	for(var/G in contents)
		if(!isobserver(G))
			vore_contents += G //Exclude any ghosts from %prey
	//RSEdit end

	for(var/mob/living/P in contents)
		if(!P.absorbed) //This is required first, in case there's a person absorbed and not absorbed in a stomach.
			total_bulge += P.size_multiplier

	if(total_bulge < bulge_size || bulge_size == 0)
		return ""

	formatted_message = replacetext(raw_message, "%belly", lowertext(name))
	formatted_message = replacetext(formatted_message, "%pred", owner)
	formatted_message = replacetext(formatted_message, "%prey", english_list(vore_contents))
	formatted_message = replacetext(formatted_message, "%countprey", living_count)
	formatted_message = replacetext(formatted_message, "%count", count_total)

	return("<span class='warning'>[formatted_message]</span>")

/obj/belly/proc/get_examine_msg_absorbed()
	if(!(contents.len) || !(examine_messages_absorbed.len) || !display_absorbed_examine)
		return ""

	var/formatted_message
	var/raw_message = pick(examine_messages_absorbed)

	var/absorbed_count = 0
	var/list/absorbed_victims = list()
	for(var/mob/living/L in contents)
		if(L.absorbed)
			absorbed_victims += L
			absorbed_count++

	if(!absorbed_count)
		return ""

	formatted_message = replacetext(raw_message, "%belly", lowertext(name))
	formatted_message = replacetext(formatted_message, "%pred", owner)
	formatted_message = replacetext(formatted_message, "%prey", english_list(absorbed_victims))
	formatted_message = replacetext(formatted_message, "%countprey", absorbed_count)

	return("<span class='warning'>[formatted_message]</span>")

// The next function gets the messages set on the belly, in human-readable format.
// This is useful in customization boxes and such. The delimiter right now is \n\n so
// in message boxes, this looks nice and is easily delimited.
/obj/belly/proc/get_messages(type, delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "asmo" || type == "asmi" || type == "dmo" || type == "dmp" || type == "amo" || type == "amp" || type == "uamo" || type == "uamp" || type == "em" || type == "ema" || type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb")

	var/list/raw_messages
	switch(type)
		if("smo")
			raw_messages = struggle_messages_outside
		if("smi")
			raw_messages = struggle_messages_inside
		if("asmo")
			raw_messages = absorbed_struggle_messages_outside
		if("asmi")
			raw_messages = absorbed_struggle_messages_inside
		if("dmo")
			raw_messages = digest_messages_owner
		if("dmp")
			raw_messages = digest_messages_prey
		if("em")
			raw_messages = examine_messages
		if("ema")
			raw_messages = examine_messages_absorbed
		if("amo")
			raw_messages = absorb_messages_owner
		if("amp")
			raw_messages = absorb_messages_prey
		if("uamo")
			raw_messages = unabsorb_messages_owner
		if("uamp")
			raw_messages = unabsorb_messages_prey
		if("im_digest")
			raw_messages = emote_lists[DM_DIGEST]
		if("im_hold")
			raw_messages = emote_lists[DM_HOLD]
		if("im_holdabsorbed")
			raw_messages = emote_lists[DM_HOLD_ABSORBED]
		if("im_absorb")
			raw_messages = emote_lists[DM_ABSORB]
		if("im_heal")
			raw_messages = emote_lists[DM_HEAL]
		if("im_drain")
			raw_messages = emote_lists[DM_DRAIN]
		if("im_steal")
			raw_messages = emote_lists[DM_SIZE_STEAL]
		if("im_egg")
			raw_messages = emote_lists[DM_EGG]
		if("im_shrink")
			raw_messages = emote_lists[DM_SHRINK]
		if("im_grow")
			raw_messages = emote_lists[DM_GROW]
		if("im_unabsorb")
			raw_messages = emote_lists[DM_UNABSORB]
	var/messages = null
	if(raw_messages)
		messages = raw_messages.Join(delim)
	return messages

// The next function sets the messages on the belly, from human-readable var
// replacement strings and linebreaks as delimiters (two \n\n by default).
// They also sanitize the messages.
/obj/belly/proc/set_messages(raw_text, type, delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "asmo" || type == "asmi" || type == "dmo" || type == "dmp" || type == "amo" || type == "amp" || type == "uamo" || type == "uamp" || type == "em" || type == "ema" || type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb")

	var/list/raw_list = splittext(html_encode(raw_text),delim)
	if(raw_list.len > 10)
		raw_list.Cut(11)
		log_debug("[owner] tried to set [lowertext(name)] with 11+ messages")

	for(var/i = 1, i <= raw_list.len, i++)
		if((length(raw_list[i]) > 160 || length(raw_list[i]) < 10) && !(type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb")) //160 is fudged value due to htmlencoding increasing the size
			raw_list.Cut(i,i)
			log_debug("[owner] tried to set [lowertext(name)] with >121 or <10 char message")
		else if((type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb") && (length(raw_list[i]) > 510 || length(raw_list[i]) < 10))
			raw_list.Cut(i,i)
			log_debug("[owner] tried to set [lowertext(name)] idle message with >501 or <10 char message")
		else if((type == "em" || type == "ema") && (length(raw_list[i]) > 260 || length(raw_list[i]) < 10))
			raw_list.Cut(i,i)
			log_debug("[owner] tried to set [lowertext(name)] examine message with >260 or <10 char message")
		else
			raw_list[i] = readd_quotes(raw_list[i])
			//Also fix % sign for var replacement
			raw_list[i] = replacetext(raw_list[i],"&#37;","%")

	ASSERT(raw_list.len <= 10) //Sanity

	switch(type)
		if("smo")
			struggle_messages_outside = raw_list
		if("smi")
			struggle_messages_inside = raw_list
		if("asmo")
			absorbed_struggle_messages_outside = raw_list
		if("asmi")
			absorbed_struggle_messages_inside = raw_list
		if("dmo")
			digest_messages_owner = raw_list
		if("dmp")
			digest_messages_prey = raw_list
		if("amo")
			absorb_messages_owner = raw_list
		if("amp")
			absorb_messages_prey = raw_list
		if("uamo")
			unabsorb_messages_owner = raw_list
		if("uamp")
			unabsorb_messages_prey = raw_list
		if("em")
			examine_messages = raw_list
		if("ema")
			examine_messages_absorbed = raw_list
		if("im_digest")
			emote_lists[DM_DIGEST] = raw_list
		if("im_hold")
			emote_lists[DM_HOLD] = raw_list
		if("im_holdabsorbed")
			emote_lists[DM_HOLD_ABSORBED] = raw_list
		if("im_absorb")
			emote_lists[DM_ABSORB] = raw_list
		if("im_heal")
			emote_lists[DM_HEAL] = raw_list
		if("im_drain")
			emote_lists[DM_DRAIN] = raw_list
		if("im_steal")
			emote_lists[DM_SIZE_STEAL] = raw_list
		if("im_egg")
			emote_lists[DM_EGG] = raw_list
		if("im_shrink")
			emote_lists[DM_SHRINK] = raw_list
		if("im_grow")
			emote_lists[DM_GROW] = raw_list
		if("im_unabsorb")
			emote_lists[DM_UNABSORB] = raw_list

	return

// Handle the death of a mob via digestion.
// Called from the process_Life() methods of bellies that digest prey.
// Default implementation calls M.death() and removes from internal contents.
// Indigestable items are removed, and M is deleted.
/obj/belly/proc/digestion_death(mob/living/M)
	add_attack_logs(owner, M, "Digested in [lowertext(name)]")

	// If digested prey is also a pred... anyone inside their bellies gets moved up.
	if(is_vore_predator(M))
		M.release_vore_contents(include_absorbed = TRUE, silent = TRUE)

	//Drop all items into the belly.
	if(config.items_survive_digestion)
		for(var/obj/item/W in M)
			if(istype(W, /obj/item/organ/internal/mmi_holder/posibrain))
				var/obj/item/organ/internal/mmi_holder/MMI = W
				var/obj/item/device/mmi/brainbox = MMI.removed()
				if(brainbox)
					items_preserved += brainbox
			for(var/slot in slots)
				var/obj/item/I = M.get_equipped_item(slot = slot)
				if(I)
					M.unEquip(I,force = TRUE)
					if(contaminates)
						I.gurgle_contaminate(contents, contamination_flavor, contamination_color) //We do an initial contamination pass to get stuff like IDs wet.
					if(item_digest_mode == IM_HOLD)
						items_preserved |= I
					else if(item_digest_mode == IM_DIGEST_FOOD && !(istype(I,/obj/item/weapon/reagent_containers/food) || istype(I,/obj/item/organ)))
						items_preserved |= I

	//Reagent transfer
	if(ishuman(owner))
		var/mob/living/carbon/human/Pred = owner
		if(ishuman(M))
			var/mob/living/carbon/human/Prey = M
			Prey.bloodstr.del_reagent("numbenzyme")
			// Begin reagent bellies || RS Add || Chomp Port
			Prey.bloodstr.trans_to_holder(Pred.ingested, Prey.bloodstr.total_volume, 0.5, TRUE) // Copy=TRUE because we're deleted anyway //CHOMPEdit Start
			Prey.ingested.trans_to_holder(Pred.ingested, Prey.ingested.total_volume, 0.5, TRUE) // Therefore don't bother spending cpu
			Prey.touching.del_reagent("stomacid") //Don't need this stuff in our bloodstream.
			Prey.touching.del_reagent("cleaner") //Don't need this stuff in our bloodstream.
			Prey.touching.trans_to_holder(Pred.ingested, Prey.touching.total_volume, 0.5, TRUE) // On updating the prey's reagents
		else if(M.reagents)
			M.reagents.del_reagent("stomacid") //Don't need this stuff in our bloodstream.
			M.reagents.del_reagent("cleaner") //Don't need this stuff in our bloodstream.
			M.reagents.trans_to_holder(Pred.ingested, M.reagents.total_volume, 0.5, TRUE) // End reagent bellies

	//Incase they have the loop going, let's double check to stop it.
	M.stop_sound_channel(CHANNEL_PREYLOOP)
	// Delete the digested mob
	var/mob/observer/G = M.ghostize() //RSEdit start || Ports keeping a ghost in a vorebelly, CHOMPStation PR#3074 || Make sure they're out, so we can copy attack logs and such.
	if(G)
		G.forceMove(src) //RSEdit end.
	qdel(M)

// Handle a mob being absorbed
/obj/belly/proc/absorb_living(mob/living/M)
	var/absorb_alert_owner = pick(absorb_messages_owner)
	var/absorb_alert_prey = pick(absorb_messages_prey)

	var/absorbed_count = 0
	for(var/mob/living/L in contents)
		if(L.absorbed)
			absorbed_count++

	//Replace placeholder vars
	absorb_alert_owner = replacetext(absorb_alert_owner, "%pred", owner)
	absorb_alert_owner = replacetext(absorb_alert_owner, "%prey", M)
	absorb_alert_owner = replacetext(absorb_alert_owner, "%belly", lowertext(name))
	absorb_alert_owner = replacetext(absorb_alert_owner, "%countprey", absorbed_count)

	absorb_alert_prey = replacetext(absorb_alert_prey, "%pred", owner)
	absorb_alert_prey = replacetext(absorb_alert_prey, "%prey", M)
	absorb_alert_prey = replacetext(absorb_alert_prey, "%belly", lowertext(name))
	absorb_alert_prey = replacetext(absorb_alert_prey, "%countprey", absorbed_count)

	M.absorbed = TRUE
	if(M.ckey)
		handle_absorb_langs(M, owner)

		GLOB.prey_absorbed_roundstat++

	to_chat(M, "<span class='notice'>[absorb_alert_prey]</span>")
	to_chat(owner, "<span class='notice'>[absorb_alert_owner]</span>")
	if(M.noisy) //Mute drained absorbee hunger if enabled.
		M.noisy = FALSE

	if(ishuman(M) && ishuman(owner))
		var/mob/living/carbon/human/Prey = M
		var/mob/living/carbon/human/Pred = owner
		//Reagent sharing for absorbed with pred - Copy so both pred and prey have these reagents.
		Prey.bloodstr.trans_to_holder(Pred.ingested, Prey.bloodstr.total_volume, copy = TRUE)
		Prey.ingested.trans_to_holder(Pred.ingested, Prey.ingested.total_volume, copy = TRUE)
		Prey.touching.trans_to_holder(Pred.ingested, Prey.touching.total_volume, copy = TRUE)
		Prey.touching.del_reagent("stomacid") // Reagent bellies || RS Add || Chomp Port
		Prey.touching.del_reagent("cleaner") // Reagent bellies || RS Add || Chomp Port
		// TODO - Find a way to make the absorbed prey share the effects with the pred.
		// Currently this is infeasible because reagent containers are designed to have a single my_atom, and we get
		// problems when A absorbs B, and then C absorbs A,  resulting in B holding onto an invalid reagent container.

	//This is probably already the case, but for sub-prey, it won't be.
	if(M.loc != src)
		M.forceMove(src)

	if(ismob(M))
		var/mob/ourmob = M
		ourmob.reset_view(owner)

	//Seek out absorbed prey of the prey, absorb them too.
	//This in particular will recurse oddly because if there is absorbed prey of prey of prey...
	//it will just move them up one belly. This should never happen though since... when they were
	//absobred, they should have been absorbed as well!
	for(var/obj/belly/B as anything in M.vore_organs)
		for(var/mob/living/Mm in B)
			if(Mm.absorbed)
				absorb_living(Mm)


	if(absorbed_desc)
		//Replace placeholder vars
		var/formatted_abs_desc
		formatted_abs_desc = replacetext(absorbed_desc, "%belly", lowertext(name)) //replace with this belly's name
		formatted_abs_desc = replacetext(formatted_abs_desc, "%pred", owner) //replace with this belly's owner
		formatted_abs_desc = replacetext(formatted_abs_desc, "%prey", M) //replace with whatever mob entered into this belly
		to_chat(M, "<span class='notice'><B>[formatted_abs_desc]</B></span>")

	//Update owner
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()
	//RS edit start
	// Finally, if they're to be sent to a special pudge belly, send them there
	if(transferlocation_absorb)
		var/obj/belly/dest_belly
		for(var/obj/belly/B as anything in owner.vore_organs)
			if(B.name == transferlocation_absorb)
				dest_belly = B
				break
		if(!dest_belly)
			to_chat(owner, "<span class='warning'>Something went wrong with your belly transfer settings. Your <b>[lowertext(name)]</b> has had its transfer location cleared as a precaution.</span>")	//RS EDIT
			transferlocation_absorb = null
			return

		transfer_contents(M, dest_belly)
	//RS edit end

// Handle a mob being unabsorbed
/obj/belly/proc/unabsorb_living(mob/living/M)
	var/unabsorb_alert_owner = pick(unabsorb_messages_owner)
	var/unabsorb_alert_prey = pick(unabsorb_messages_prey)

	var/absorbed_count = 0
	for(var/mob/living/L in contents)
		if(L.absorbed)
			absorbed_count++

	//Replace placeholder vars
	unabsorb_alert_owner = replacetext(unabsorb_alert_owner, "%pred", owner)
	unabsorb_alert_owner = replacetext(unabsorb_alert_owner, "%prey", M)
	unabsorb_alert_owner = replacetext(unabsorb_alert_owner, "%belly", lowertext(name))
	unabsorb_alert_owner = replacetext(unabsorb_alert_owner, "%countprey", absorbed_count)

	unabsorb_alert_prey = replacetext(unabsorb_alert_prey, "%pred", owner)
	unabsorb_alert_prey = replacetext(unabsorb_alert_prey, "%prey", M)
	unabsorb_alert_prey = replacetext(unabsorb_alert_prey, "%belly", lowertext(name))
	unabsorb_alert_prey = replacetext(unabsorb_alert_prey, "%countprey", absorbed_count)

	M.absorbed = FALSE
	handle_absorb_langs(M, owner)
	to_chat(M, "<span class='notice'>[unabsorb_alert_prey]</span>")
	to_chat(owner, "<span class='notice'>[unabsorb_alert_owner]</span>")

	if(desc)
		to_chat(M, "<span class='notice'><B>[desc]</B></span>")

	//Update owner
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()

/////////////////////////////////////////////////////////////////////////
/obj/belly/proc/handle_absorb_langs()
	owner.absorb_langs()

////////////////////////////////////////////////////////////////////////


//Digest a single item
//Receives a return value from digest_act that's how much nutrition
//the item should be worth
/obj/belly/proc/digest_item(obj/item/item)
	var/digested = item.digest_act(src)
	if(!digested)
		items_preserved |= item
	else
		owner.adjust_nutrition((nutrition_percent / 100) * 15 * digested)
		if(isrobot(owner))
			var/mob/living/silicon/robot/R = owner
			R.cell.charge += ((nutrition_percent / 100) * 50 * digested)
	return digested

//Determine where items should fall out of us into.
//Typically just to the owner's location.
/obj/belly/drop_location()
	//Should be the case 99.99% of the time
	if(owner)
		return owner.drop_location()
	//Sketchy fallback for safety, put them somewhere safe.
	else
		log_debug("[src] (\ref[src]) doesn't have an owner, and dropped someone at a latespawn point!")
		var/fallback = pick(latejoin)
		return get_turf(fallback)

//Yes, it's ""safe"" to drop items here
/obj/belly/AllowDrop()
	return TRUE

/obj/belly/onDropInto(atom/movable/AM)
	return null

//Handle a mob struggling
// Called from /mob/living/carbon/relaymove()
/obj/belly/proc/relay_resist(mob/living/R, obj/item/C)
	if (!(R in contents))
		if(!C)
			return  // User is not in this belly

	R.setClickCooldown(50)

	// RS edit start - port virgo 15559
	var/living_count = 0
	for(var/mob/living/L in contents)
		living_count++

	var/escape_attempt_owner_message = pick(escape_attempt_messages_owner)
	var/escape_attempt_prey_message = pick(escape_attempt_messages_prey)
	var/escape_fail_owner_message = pick(escape_fail_messages_owner)
	var/escape_fail_prey_message = pick(escape_fail_messages_prey)

	escape_attempt_owner_message = replacetext(escape_attempt_owner_message, "%pred", owner)
	escape_attempt_owner_message = replacetext(escape_attempt_owner_message, "%prey", R)
	escape_attempt_owner_message = replacetext(escape_attempt_owner_message, "%belly", lowertext(name))
	escape_attempt_owner_message = replacetext(escape_attempt_owner_message, "%countprey", living_count)
	escape_attempt_owner_message = replacetext(escape_attempt_owner_message, "%count", contents.len)

	escape_attempt_prey_message = replacetext(escape_attempt_prey_message, "%pred", owner)
	escape_attempt_prey_message = replacetext(escape_attempt_prey_message, "%prey", R)
	escape_attempt_prey_message = replacetext(escape_attempt_prey_message, "%belly", lowertext(name))
	escape_attempt_prey_message = replacetext(escape_attempt_prey_message, "%countprey", living_count)
	escape_attempt_prey_message = replacetext(escape_attempt_prey_message, "%count", contents.len)

	escape_fail_owner_message = replacetext(escape_fail_owner_message, "%pred", owner)
	escape_fail_owner_message = replacetext(escape_fail_owner_message, "%prey", R)
	escape_fail_owner_message = replacetext(escape_fail_owner_message, "%belly", lowertext(name))
	escape_fail_owner_message = replacetext(escape_fail_owner_message, "%countprey", living_count)
	escape_fail_owner_message = replacetext(escape_fail_owner_message, "%count", contents.len)

	escape_fail_prey_message = replacetext(escape_fail_prey_message, "%pred", owner)
	escape_fail_prey_message = replacetext(escape_fail_prey_message, "%prey", R)
	escape_fail_prey_message = replacetext(escape_fail_prey_message, "%belly", lowertext(name))
	escape_fail_prey_message = replacetext(escape_fail_prey_message, "%countprey", living_count)
	escape_fail_prey_message = replacetext(escape_fail_prey_message, "%count", contents.len)

	escape_attempt_owner_message = "<span class='warning'>[escape_attempt_owner_message]</span>"
	escape_attempt_prey_message = "<span class='warning'>[escape_attempt_prey_message]</span>"
	escape_fail_owner_message = "<span class='warning'>[escape_fail_owner_message]</span>"
	escape_fail_prey_message = "<span class='notice'>[escape_fail_prey_message]</span>"


	if(owner.stat) //If owner is stat (dead, KO) we can actually escape
		escape_attempt_prey_message = replacetext(escape_attempt_prey_message, new/regex("^(<span(?: \[^>]*)?>.*)(</span>)$", ""), "$1 (This will take around [escapetime/10] seconds.)$2")
		to_chat(R, escape_attempt_prey_message)
		to_chat(owner, escape_attempt_owner_message)
	// RS edit end

		if(do_after(R, escapetime, owner, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
			if((owner.stat || escapable)) //Can still escape?
				if(C)
					release_specific_contents(C)
					return
				if(R.loc == src)
					release_specific_contents(R)
					return
			else if(R.loc != src) //Aren't even in the belly. Quietly fail.
				return
			else //Belly became inescapable or mob revived
				to_chat(R, escape_fail_prey_message) //RS edit - VS 15559
				to_chat(owner, escape_fail_owner_message) //RS edit - VS 15559
				return
			return
	var/struggle_outer_message = pick(struggle_messages_outside)
	var/struggle_user_message = pick(struggle_messages_inside)

	// RS remove - VS 15559 port (definition moved elsewhere)
	//var/living_count = 0
	//for(var/mob/living/L in contents)
	//	living_count++

	struggle_outer_message = replacetext(struggle_outer_message, "%pred", owner)
	struggle_outer_message = replacetext(struggle_outer_message, "%prey", R)
	struggle_outer_message = replacetext(struggle_outer_message, "%belly", lowertext(name))
	struggle_outer_message = replacetext(struggle_outer_message, "%countprey", living_count)
	struggle_outer_message = replacetext(struggle_outer_message, "%count", contents.len)

	struggle_user_message = replacetext(struggle_user_message, "%pred", owner)
	struggle_user_message = replacetext(struggle_user_message, "%prey", R)
	struggle_user_message = replacetext(struggle_user_message, "%belly", lowertext(name))
	struggle_user_message = replacetext(struggle_user_message, "%countprey", living_count)
	struggle_user_message = replacetext(struggle_user_message, "%count", contents.len)

	struggle_outer_message = "<span class='alert'>[struggle_outer_message]</span>"
	struggle_user_message = "<span class='alert'>[struggle_user_message]</span>"

	for(var/mob/M in hearers(4, owner))
		M.show_message(struggle_outer_message, 2) // hearable
	//to_chat(R, struggle_user_message)  RS remove - moved to bottom of proc

	var/sound/struggle_snuggle
	var/sound/struggle_rustle = sound(get_sfx("rustle"))

	// Begin RS edit
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/howner = owner
		if ((howner.vore_capacity_ex["stomach"] >= 1))
			howner.vs_animate(belly_sprite_to_affect)
	// End RS edit

	if(is_wet)
		if(!fancy_vore)
			struggle_snuggle = sound(get_sfx("classic_struggle_sounds"))
		else
			struggle_snuggle = sound(get_sfx("fancy_prey_struggle"))
		playsound(src, struggle_snuggle, vary = 1, vol = 75, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/digestion_noises, volume_channel = VOLUME_CHANNEL_VORE)
	else
		playsound(src, struggle_rustle, vary = 1, vol = 75, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/digestion_noises, volume_channel = VOLUME_CHANNEL_VORE)

	if(escapable) //If the stomach has escapable enabled.
		if(prob(escapechance)) //Let's have it check to see if the prey escapes first.
			to_chat(R, escape_attempt_prey_message) // RS edit - VS 15559
			to_chat(owner, escape_attempt_owner_message) // RS edit - VS 15559
			if(do_after(R, escapetime))
				if(escapable && C)
					//RS edit start - VS 15559
					var/escape_item_owner_message = pick(escape_item_messages_owner)
					var/escape_item_prey_message = pick(escape_item_messages_prey)
					var/escape_item_outside_message = pick(escape_item_messages_outside)

					escape_item_owner_message = replacetext(escape_item_owner_message, "%pred", owner)
					escape_item_owner_message = replacetext(escape_item_owner_message, "%prey", R)
					escape_item_owner_message = replacetext(escape_item_owner_message, "%belly", lowertext(name))
					escape_item_owner_message = replacetext(escape_item_owner_message, "%countprey", living_count)
					escape_item_owner_message = replacetext(escape_item_owner_message, "%count", contents.len)
					escape_item_owner_message = replacetext(escape_item_owner_message, "%item", C)

					escape_item_prey_message = replacetext(escape_item_prey_message, "%pred", owner)
					escape_item_prey_message = replacetext(escape_item_prey_message, "%prey", R)
					escape_item_prey_message = replacetext(escape_item_prey_message, "%belly", lowertext(name))
					escape_item_prey_message = replacetext(escape_item_prey_message, "%countprey", living_count)
					escape_item_prey_message = replacetext(escape_item_prey_message, "%count", contents.len)
					escape_item_prey_message = replacetext(escape_item_prey_message, "%item", C)

					escape_item_outside_message = replacetext(escape_item_outside_message, "%pred", owner)
					escape_item_outside_message = replacetext(escape_item_outside_message, "%prey", R)
					escape_item_outside_message = replacetext(escape_item_outside_message, "%belly", lowertext(name))
					escape_item_outside_message = replacetext(escape_item_outside_message, "%countprey", living_count)
					escape_item_outside_message = replacetext(escape_item_outside_message, "%count", contents.len)
					escape_item_outside_message = replacetext(escape_item_outside_message, "%item", C)

					escape_item_owner_message = "<span class='warning'>[escape_item_owner_message]</span>"
					escape_item_prey_message = "<span class='warning'>[escape_item_prey_message]</span>"
					escape_item_outside_message = "<span class='warning'>[escape_item_outside_message]</span>"
					//RS edit end

					release_specific_contents(C)
					to_chat(R, escape_item_prey_message) //RS edit
					to_chat(owner, escape_item_owner_message) //RS edit
					for(var/mob/M in hearers(4, owner))
						M.show_message(escape_item_outside_message, 2) //RS edit
					return
				if(escapable && (R.loc == src) && !R.absorbed) //Does the owner still have escapable enabled?
					//RS edit start - VS 15559
					var/escape_owner_message = pick(escape_messages_owner)
					var/escape_prey_message = pick(escape_messages_prey)
					var/escape_outside_message = pick(escape_messages_outside)

					escape_owner_message = replacetext(escape_owner_message, "%pred", owner)
					escape_owner_message = replacetext(escape_owner_message, "%prey", R)
					escape_owner_message = replacetext(escape_owner_message, "%belly", lowertext(name))
					escape_owner_message = replacetext(escape_owner_message, "%countprey", living_count)
					escape_owner_message = replacetext(escape_owner_message, "%count", contents.len)

					escape_prey_message = replacetext(escape_prey_message, "%pred", owner)
					escape_prey_message = replacetext(escape_prey_message, "%prey", R)
					escape_prey_message = replacetext(escape_prey_message, "%belly", lowertext(name))
					escape_prey_message = replacetext(escape_prey_message, "%countprey", living_count)
					escape_prey_message = replacetext(escape_prey_message, "%count", contents.len)

					escape_outside_message = replacetext(escape_outside_message, "%pred", owner)
					escape_outside_message = replacetext(escape_outside_message, "%prey", R)
					escape_outside_message = replacetext(escape_outside_message, "%belly", lowertext(name))
					escape_outside_message = replacetext(escape_outside_message, "%countprey", living_count)
					escape_outside_message = replacetext(escape_outside_message, "%count", contents.len)

					escape_owner_message = "<span class='warning'>[escape_owner_message]</span>"
					escape_prey_message = "<span class='warning'>[escape_prey_message]</span>"
					escape_outside_message = "<span class='warning'>[escape_outside_message]</span>"
					//RS edit end
					release_specific_contents(R)
					to_chat(R, escape_prey_message) //RS edit
					to_chat(owner, escape_owner_message) //RS edit
					for(var/mob/M in hearers(4, owner))
						M.show_message(escape_outside_message, 2) // RS edit
					return
				else if(!(R.loc == src)) //Aren't even in the belly. Quietly fail.
					return
				else //Belly became inescapable.
					to_chat(R, escape_fail_prey_message) //RS edit
					to_chat(owner, escape_fail_owner_message) //RS edit
					return

		else if(prob(transferchance) && transferlocation) //Next, let's have it see if they end up getting into an even bigger mess then when they started.
			var/obj/belly/dest_belly
			for(var/obj/belly/B as anything in owner.vore_organs)
				if(B.name == transferlocation)
					dest_belly = B
					break

			if(!dest_belly)
				to_chat(owner, "<span class='warning'>Something went wrong with your belly transfer settings. Your <b>[lowertext(name)]</b> has had it's transfer chance and transfer location cleared as a precaution.</span>")
				transferchance = 0
				transferlocation = null
				return
			// RS edit start - port VS 15559
			var/primary_transfer_owner_message = pick(primary_transfer_messages_owner)
			var/primary_transfer_prey_message = pick(primary_transfer_messages_prey)

			primary_transfer_owner_message = replacetext(primary_transfer_owner_message, "%pred", owner)
			primary_transfer_owner_message = replacetext(primary_transfer_owner_message, "%prey", R)
			primary_transfer_owner_message = replacetext(primary_transfer_owner_message, "%belly", lowertext(name))
			primary_transfer_owner_message = replacetext(primary_transfer_owner_message, "%countprey", living_count)
			primary_transfer_owner_message = replacetext(primary_transfer_owner_message, "%count", contents.len)
			primary_transfer_owner_message = replacetext(primary_transfer_owner_message, "%dest", transferlocation)

			primary_transfer_prey_message = replacetext(primary_transfer_prey_message, "%pred", owner)
			primary_transfer_prey_message = replacetext(primary_transfer_prey_message, "%prey", R)
			primary_transfer_prey_message = replacetext(primary_transfer_prey_message, "%belly", lowertext(name))
			primary_transfer_prey_message = replacetext(primary_transfer_prey_message, "%countprey", living_count)
			primary_transfer_prey_message = replacetext(primary_transfer_prey_message, "%count", contents.len)
			primary_transfer_prey_message = replacetext(primary_transfer_prey_message, "%dest", transferlocation)

			primary_transfer_owner_message = "<span class='warning'>[primary_transfer_owner_message]</span>"
			primary_transfer_prey_message = "<span class='warning'>[primary_transfer_prey_message]</span>"

			to_chat(R, primary_transfer_prey_message)
			to_chat(owner, primary_transfer_owner_message)
			//RS edit end
			if(C)
				transfer_contents(C, dest_belly)
				return
			transfer_contents(R, dest_belly)
			return

		else if(prob(transferchance_secondary) && transferlocation_secondary) //After the first potential mess getting into, run the secondary one which might be even bigger of a mess.
			var/obj/belly/dest_belly
			for(var/obj/belly/B as anything in owner.vore_organs)
				if(B.name == transferlocation_secondary)
					dest_belly = B
					break

			if(!dest_belly)
				to_chat(owner, "<span class='warning'>Something went wrong with your belly transfer settings. Your <b>[lowertext(name)]</b> has had it's transfer chance and transfer location cleared as a precaution.</span>")
				transferchance_secondary = 0
				transferlocation_secondary = null
				return
			// RS edit start - VS 15559
			var/secondary_transfer_owner_message = pick(secondary_transfer_messages_owner)
			var/secondary_transfer_prey_message = pick(secondary_transfer_messages_prey)

			secondary_transfer_owner_message = replacetext(secondary_transfer_owner_message, "%pred", owner)
			secondary_transfer_owner_message = replacetext(secondary_transfer_owner_message, "%prey", R)
			secondary_transfer_owner_message = replacetext(secondary_transfer_owner_message, "%belly", lowertext(name))
			secondary_transfer_owner_message = replacetext(secondary_transfer_owner_message, "%countprey", living_count)
			secondary_transfer_owner_message = replacetext(secondary_transfer_owner_message, "%count", contents.len)
			secondary_transfer_owner_message = replacetext(secondary_transfer_owner_message, "%dest", transferlocation_secondary)

			secondary_transfer_prey_message = replacetext(secondary_transfer_prey_message, "%pred", owner)
			secondary_transfer_prey_message = replacetext(secondary_transfer_prey_message, "%prey", R)
			secondary_transfer_prey_message = replacetext(secondary_transfer_prey_message, "%belly", lowertext(name))
			secondary_transfer_prey_message = replacetext(secondary_transfer_prey_message, "%countprey", living_count)
			secondary_transfer_prey_message = replacetext(secondary_transfer_prey_message, "%count", contents.len)
			secondary_transfer_prey_message = replacetext(secondary_transfer_prey_message, "%dest", transferlocation_secondary)

			secondary_transfer_owner_message = "<span class='warning'>[secondary_transfer_owner_message]</span>"
			secondary_transfer_prey_message = "<span class='warning'>[secondary_transfer_prey_message]</span>"

			to_chat(R, secondary_transfer_prey_message)
			to_chat(owner, secondary_transfer_owner_message)
			//RS edit end
			if(C)
				transfer_contents(C, dest_belly)
				return
			transfer_contents(R, dest_belly)
			return

		else if(prob(absorbchance) && digest_mode != DM_ABSORB) //After that, let's have it run the absorb chance.
			//RS edit start - vs 15559
			var/absorb_chance_owner_message = pick(absorb_chance_messages_owner)
			var/absorb_chance_prey_message = pick(absorb_chance_messages_prey)

			absorb_chance_owner_message = replacetext(absorb_chance_owner_message, "%pred", owner)
			absorb_chance_owner_message = replacetext(absorb_chance_owner_message, "%prey", R)
			absorb_chance_owner_message = replacetext(absorb_chance_owner_message, "%belly", lowertext(name))
			absorb_chance_owner_message = replacetext(absorb_chance_owner_message, "%countprey", living_count)
			absorb_chance_owner_message = replacetext(absorb_chance_owner_message, "%count", contents.len)

			absorb_chance_prey_message = replacetext(absorb_chance_prey_message, "%pred", owner)
			absorb_chance_prey_message = replacetext(absorb_chance_prey_message, "%prey", R)
			absorb_chance_prey_message = replacetext(absorb_chance_prey_message, "%belly", lowertext(name))
			absorb_chance_prey_message = replacetext(absorb_chance_prey_message, "%countprey", living_count)
			absorb_chance_prey_message = replacetext(absorb_chance_prey_message, "%count", contents.len)

			absorb_chance_owner_message = "<span class='warning'>[absorb_chance_owner_message]</span>"
			absorb_chance_prey_message = "<span class='warning'>[absorb_chance_prey_message]</span>"

			to_chat(R, absorb_chance_prey_message)
			to_chat(owner, absorb_chance_owner_message)
			//RS edit end
			digest_mode = DM_ABSORB
			return

		else if(prob(digestchance) && digest_mode != DM_DIGEST) //Next, let's see if it should run the digest chance.
			// RS edit start - vs 15559
			var/digest_chance_owner_message = pick(digest_chance_messages_owner)
			var/digest_chance_prey_message = pick(digest_chance_messages_prey)

			digest_chance_owner_message = replacetext(digest_chance_owner_message, "%pred", owner)
			digest_chance_owner_message = replacetext(digest_chance_owner_message, "%prey", R)
			digest_chance_owner_message = replacetext(digest_chance_owner_message, "%belly", lowertext(name))
			digest_chance_owner_message = replacetext(digest_chance_owner_message, "%countprey", living_count)
			digest_chance_owner_message = replacetext(digest_chance_owner_message, "%count", contents.len)

			digest_chance_prey_message = replacetext(digest_chance_prey_message, "%pred", owner)
			digest_chance_prey_message = replacetext(digest_chance_prey_message, "%prey", R)
			digest_chance_prey_message = replacetext(digest_chance_prey_message, "%belly", lowertext(name))
			digest_chance_prey_message = replacetext(digest_chance_prey_message, "%countprey", living_count)
			digest_chance_prey_message = replacetext(digest_chance_prey_message, "%count", contents.len)

			digest_chance_owner_message = "<span class='warning'>[digest_chance_owner_message]</span>"
			digest_chance_prey_message = "<span class='warning'>[digest_chance_prey_message]</span>"

			to_chat(R, digest_chance_prey_message)
			to_chat(owner, digest_chance_owner_message)
			//RS edit end
			digest_mode = DM_DIGEST
			return
		//RS edit start
		else if(prob(selectchance) && digest_mode != DM_SELECT) //Finally, let's see if it should run the selective mode chance.
			var/select_chance_owner_message = pick(select_chance_messages_owner)
			var/select_chance_prey_message = pick(select_chance_messages_prey)

			select_chance_owner_message = replacetext(select_chance_owner_message, "%pred", owner)
			select_chance_owner_message = replacetext(select_chance_owner_message, "%prey", R)
			select_chance_owner_message = replacetext(select_chance_owner_message, "%belly", lowertext(name))
			select_chance_owner_message = replacetext(select_chance_owner_message, "%countprey", living_count)
			select_chance_owner_message = replacetext(select_chance_owner_message, "%count", contents.len)

			select_chance_prey_message = replacetext(select_chance_prey_message, "%pred", owner)
			select_chance_prey_message = replacetext(select_chance_prey_message, "%prey", R)
			select_chance_prey_message = replacetext(select_chance_prey_message, "%belly", lowertext(name))
			select_chance_prey_message = replacetext(select_chance_prey_message, "%countprey", living_count)
			select_chance_prey_message = replacetext(select_chance_prey_message, "%count", contents.len)

			select_chance_owner_message = "<span class='warning'>[select_chance_owner_message]</span>"	//RS EDIT
			select_chance_prey_message = "<span class='warning'>[select_chance_prey_message]</span>"	//RS EDIT

			to_chat(R, select_chance_prey_message)
			to_chat(owner, select_chance_owner_message)
			digest_mode = DM_SELECT
		//RS edit end
		else //Nothing interesting happened.
			to_chat(R, struggle_user_message) //RS edit
			to_chat(owner, "<span class='warning'>Your prey appears to be unable to make any progress in escaping your [lowertext(name)].</span>")
			return
	to_chat(R, struggle_user_message) //RS add

/obj/belly/proc/relay_absorbed_resist(mob/living/R)
	if (!(R in contents) || !R.absorbed)
		return  // User is not in this belly or isn't actually absorbed

	R.setClickCooldown(50)

	var/struggle_outer_message = pick(absorbed_struggle_messages_outside)
	var/struggle_user_message = pick(absorbed_struggle_messages_inside)

	var/absorbed_count = 0
	for(var/mob/living/L in contents)
		if(L.absorbed)
			absorbed_count++

	struggle_outer_message = replacetext(struggle_outer_message, "%pred", owner)
	struggle_outer_message = replacetext(struggle_outer_message, "%prey", R)
	struggle_outer_message = replacetext(struggle_outer_message, "%belly", lowertext(name))
	struggle_outer_message = replacetext(struggle_outer_message, "%countprey", absorbed_count)

	struggle_user_message = replacetext(struggle_user_message, "%pred", owner)
	struggle_user_message = replacetext(struggle_user_message, "%prey", R)
	struggle_user_message = replacetext(struggle_user_message, "%belly", lowertext(name))
	struggle_user_message = replacetext(struggle_user_message, "%countprey", absorbed_count)

	struggle_outer_message = "<span class='alert'>[struggle_outer_message]</span>"
	struggle_user_message = "<span class='alert'>[struggle_user_message]</span>"

	for(var/mob/M in hearers(4, owner))
		M.show_message(struggle_outer_message, 2) // hearable
	//to_chat(R, struggle_user_message) RS remove - moved to bottom of proc

	var/sound/struggle_snuggle
	var/sound/struggle_rustle = sound(get_sfx("rustle"))

	if(is_wet)
		if(!fancy_vore)
			struggle_snuggle = sound(get_sfx("classic_struggle_sounds"))
		else
			struggle_snuggle = sound(get_sfx("fancy_prey_struggle"))
		playsound(src, struggle_snuggle, vary = 1, vol = 75, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/digestion_noises, volume_channel = VOLUME_CHANNEL_VORE)
	else
		playsound(src, struggle_rustle, vary = 1, vol = 75, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/digestion_noises, volume_channel = VOLUME_CHANNEL_VORE)

	//RS Edit Start - virgo port
	//absorb resists
	if(escapable || owner.stat) //If the stomach has escapable enabled or the owner is dead/unconscious
		if(prob(escapechance) || owner.stat) //Let's have it check to see if the prey's escape attempt starts.
			//RS edit start - vs 15559
			var/living_count = 0
			for(var/mob/living/L in contents)
				living_count++

			var/escape_attempt_absorbed_owner_message = pick(escape_attempt_absorbed_messages_owner)
			var/escape_attempt_absorbed_prey_message = pick(escape_attempt_absorbed_messages_prey)

			escape_attempt_absorbed_owner_message = replacetext(escape_attempt_absorbed_owner_message, "%pred", owner)
			escape_attempt_absorbed_owner_message = replacetext(escape_attempt_absorbed_owner_message, "%prey", R)
			escape_attempt_absorbed_owner_message = replacetext(escape_attempt_absorbed_owner_message, "%belly", lowertext(name))
			escape_attempt_absorbed_owner_message = replacetext(escape_attempt_absorbed_owner_message, "%countprey", living_count)
			escape_attempt_absorbed_owner_message = replacetext(escape_attempt_absorbed_owner_message, "%count", contents.len)

			escape_attempt_absorbed_prey_message = replacetext(escape_attempt_absorbed_prey_message, "%pred", owner)
			escape_attempt_absorbed_prey_message = replacetext(escape_attempt_absorbed_prey_message, "%prey", R)
			escape_attempt_absorbed_prey_message = replacetext(escape_attempt_absorbed_prey_message, "%belly", lowertext(name))
			escape_attempt_absorbed_prey_message = replacetext(escape_attempt_absorbed_prey_message, "%countprey", living_count)
			escape_attempt_absorbed_prey_message = replacetext(escape_attempt_absorbed_prey_message, "%count", contents.len)

			escape_attempt_absorbed_owner_message = "<span class='warning'>[escape_attempt_absorbed_owner_message]</span>"
			escape_attempt_absorbed_prey_message = "<span class='warning'>[escape_attempt_absorbed_prey_message]</span>"

			to_chat(R, escape_attempt_absorbed_prey_message)
			to_chat(owner, escape_attempt_absorbed_owner_message)
			//RS edit end
			if(do_after(R, escapetime))
				if((escapable || owner.stat) && (R.loc == src) && prob(escapechance_absorbed)) //Does the escape attempt succeed?
					//RS edit start
					var/escape_absorbed_owner_message = pick(escape_absorbed_messages_owner)
					var/escape_absorbed_prey_message = pick(escape_absorbed_messages_prey)
					var/escape_absorbed_outside_message = pick(escape_absorbed_messages_outside)

					escape_absorbed_owner_message = replacetext(escape_absorbed_owner_message, "%pred", owner)
					escape_absorbed_owner_message = replacetext(escape_absorbed_owner_message, "%prey", R)
					escape_absorbed_owner_message = replacetext(escape_absorbed_owner_message, "%belly", lowertext(name))
					escape_absorbed_owner_message = replacetext(escape_absorbed_owner_message, "%countprey", living_count)
					escape_absorbed_owner_message = replacetext(escape_absorbed_owner_message, "%count", contents.len)

					escape_absorbed_prey_message = replacetext(escape_absorbed_prey_message, "%pred", owner)
					escape_absorbed_prey_message = replacetext(escape_absorbed_prey_message, "%prey", R)
					escape_absorbed_prey_message = replacetext(escape_absorbed_prey_message, "%belly", lowertext(name))
					escape_absorbed_prey_message = replacetext(escape_absorbed_prey_message, "%countprey", living_count)
					escape_absorbed_prey_message = replacetext(escape_absorbed_prey_message, "%count", contents.len)

					escape_absorbed_outside_message = replacetext(escape_absorbed_outside_message, "%pred", owner)
					escape_absorbed_outside_message = replacetext(escape_absorbed_outside_message, "%prey", R)
					escape_absorbed_outside_message = replacetext(escape_absorbed_outside_message, "%belly", lowertext(name))
					escape_absorbed_outside_message = replacetext(escape_absorbed_outside_message, "%countprey", living_count)
					escape_absorbed_outside_message = replacetext(escape_absorbed_outside_message, "%count", contents.len)

					escape_absorbed_owner_message = "<span class='warning'>[escape_absorbed_owner_message]</span>"
					escape_absorbed_prey_message = "<span class='warning'>[escape_absorbed_prey_message]</span>"
					escape_absorbed_outside_message = "<span class='warning'>[escape_absorbed_outside_message]</span>"
					//RS edit end
					release_specific_contents(R)
					to_chat(R, escape_absorbed_prey_message) //RS edit
					to_chat(owner, escape_absorbed_owner_message) //RS edit
					for(var/mob/M in hearers(4, owner))
						M.show_message(escape_absorbed_outside_message, 2)//RS edit
					return
				else if(!(R.loc == src)) //Aren't even in the belly. Quietly fail.
					return
				else //Belly became inescapable or you failed your roll.
					//RS edit start - VS 15559

					var/escape_fail_absorbed_owner_message = pick(escape_fail_absorbed_messages_owner)
					var/escape_fail_absorbed_prey_message = pick(escape_fail_absorbed_messages_prey)

					escape_fail_absorbed_owner_message = replacetext(escape_fail_absorbed_owner_message, "%pred", owner)
					escape_fail_absorbed_owner_message = replacetext(escape_fail_absorbed_owner_message, "%prey", R)
					escape_fail_absorbed_owner_message = replacetext(escape_fail_absorbed_owner_message, "%belly", lowertext(name))
					escape_fail_absorbed_owner_message = replacetext(escape_fail_absorbed_owner_message, "%countprey", living_count)
					escape_fail_absorbed_owner_message = replacetext(escape_fail_absorbed_owner_message, "%count", contents.len)

					escape_fail_absorbed_prey_message = replacetext(escape_fail_absorbed_prey_message, "%pred", owner)
					escape_fail_absorbed_prey_message = replacetext(escape_fail_absorbed_prey_message, "%prey", R)
					escape_fail_absorbed_prey_message = replacetext(escape_fail_absorbed_prey_message, "%belly", lowertext(name))
					escape_fail_absorbed_prey_message = replacetext(escape_fail_absorbed_prey_message, "%countprey", living_count)
					escape_fail_absorbed_prey_message = replacetext(escape_fail_absorbed_prey_message, "%count", contents.len)

					escape_fail_absorbed_owner_message = "<span class='warning'>[escape_fail_absorbed_owner_message]</span>"
					escape_fail_absorbed_prey_message = "<span class='notice'>[escape_fail_absorbed_prey_message]</span>"

					to_chat(R, escape_fail_absorbed_prey_message)
					to_chat(owner, escape_fail_absorbed_owner_message)
					//RS edit end
					return
	to_chat(R, struggle_user_message)
	//RS edit end


/obj/belly/proc/get_mobs_and_objs_in_belly()
	var/list/see = list()
	var/list/belly_mobs = list()
	see["mobs"] = belly_mobs
	var/list/belly_objs = list()
	see["objs"] = belly_objs
	for(var/mob/living/L in loc.contents)
		belly_mobs |= L
	for(var/obj/O in loc.contents)
		belly_objs |= O

	return see

//Transfers contents from one belly to another
/obj/belly/proc/transfer_contents(atom/movable/content, obj/belly/target, silent = 0)
	if(!(content in src) || !istype(target))
		return
	content.forceMove(target)
	if(ismob(content) && !isobserver(content)) //RSEdit: Ports VOREStation PR15918 | Fixes bug where camera is not set to follow the ghost
		var/mob/ourmob = content
		ourmob.reset_view(owner)
	if(isitem(content))
		var/obj/item/I = content
		if(istype(I,/obj/item/weapon/card/id))
			I.gurgle_contaminate(target.contents, target.contamination_flavor, target.contamination_color)
		if(I.gurgled && target.contaminates)
			I.decontaminate()
			I.gurgle_contaminate(target.contents, target.contamination_flavor, target.contamination_color)
	items_preserved -= content
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()
	for(var/mob/living/M in contents)
		M.updateVRPanel()
	owner.update_icon()

//Autotransfer callback || RS Edit Start || Chomp Port 6155
/obj/belly/proc/check_autotransfer(var/atom/movable/prey)
	if(!(prey in contents) || !prey.autotransferable) return
	var/dest_belly_name
	if(autotransferlocation_secondary && prob(autotransferchance_secondary))
		dest_belly_name = autotransferlocation_secondary
	if(autotransferlocation && prob(autotransferchance))
		dest_belly_name = autotransferlocation
	if(!dest_belly_name) // Didn't transfer, so wait before retrying
		prey.belly_cycles = 0
		return
	var/obj/belly/dest_belly
	for(var/obj/belly/B in owner.vore_organs)
		if(B.name == dest_belly_name)
			dest_belly = B
			break
	if(!dest_belly) return
	transfer_contents(prey, dest_belly)
	return TRUE //RS Edit End || Chomp Port 6155

// Belly copies and then returns the copy
// Needs to be updated for any var changes
/obj/belly/proc/copy(mob/new_owner)
	var/obj/belly/dupe = new /obj/belly(new_owner)

	//// Non-object variables
	dupe.name = name
	dupe.desc = desc
	dupe.absorbed_desc = absorbed_desc
	dupe.vore_sound = vore_sound
	dupe.vore_verb = vore_verb
	dupe.release_verb = release_verb
	dupe.human_prey_swallow_time = human_prey_swallow_time
	dupe.nonhuman_prey_swallow_time = nonhuman_prey_swallow_time
	dupe.emote_time = emote_time
	dupe.nutrition_percent = nutrition_percent
	dupe.digest_brute = digest_brute
	dupe.digest_burn = digest_burn
	dupe.digest_oxy = digest_oxy
	dupe.digest_tox = digest_tox
	dupe.digest_clone = digest_clone
	dupe.immutable = immutable
	dupe.can_taste = can_taste
	dupe.escapable = escapable
	dupe.escapetime = escapetime
	dupe.selectchance = selectchance // RS add
	dupe.digestchance = digestchance
	dupe.absorbchance = absorbchance
	dupe.escapechance = escapechance
	dupe.escapechance_absorbed = escapechance_absorbed // RS edit - VS 15559
	dupe.transferchance = transferchance
	dupe.transferchance_secondary = transferchance_secondary
	dupe.transferlocation = transferlocation
	dupe.transferlocation_secondary = transferlocation_secondary
	dupe.bulge_size = bulge_size
	dupe.shrink_grow_size = shrink_grow_size
	dupe.mode_flags = mode_flags
	dupe.item_digest_mode = item_digest_mode
	dupe.contaminates = contaminates
	dupe.contamination_flavor = contamination_flavor
	dupe.contamination_color = contamination_color
	dupe.release_sound = release_sound
	dupe.fancy_vore = fancy_vore
	dupe.is_wet = is_wet
	dupe.wet_loop = wet_loop
	dupe.belly_fullscreen = belly_fullscreen
	dupe.disable_hud = disable_hud
	dupe.belly_fullscreen_color = belly_fullscreen_color
	dupe.belly_fullscreen_color_secondary = belly_fullscreen_color_secondary
	dupe.belly_fullscreen_color_trinary = belly_fullscreen_color_trinary
	dupe.colorization_enabled = colorization_enabled
	dupe.belly_healthbar_overlay_theme = belly_healthbar_overlay_theme	//RS ADD
	dupe.belly_healthbar_overlay_color = belly_healthbar_overlay_color	//RS ADD
	dupe.egg_type = egg_type
	dupe.emote_time = emote_time
	dupe.emote_active = emote_active
	dupe.selective_preference = selective_preference
	dupe.save_digest_mode = save_digest_mode
	dupe.eating_privacy_local = eating_privacy_local
	dupe.silicon_belly_overlay_preference = silicon_belly_overlay_preference
	dupe.visible_belly_minimum_prey	= visible_belly_minimum_prey
	dupe.overlay_min_prey_size	= overlay_min_prey_size
	dupe.override_min_prey_size = override_min_prey_size
	dupe.override_min_prey_num	= override_min_prey_num
	// Begin RS edit
	dupe.vore_sprite_flags = vore_sprite_flags
	dupe.affects_vore_sprites = affects_vore_sprites
	dupe.count_absorbed_prey_for_sprite = count_absorbed_prey_for_sprite
	dupe.resist_triggers_animation = resist_triggers_animation
	dupe.size_factor_for_sprite = size_factor_for_sprite
	dupe.belly_sprite_to_affect = belly_sprite_to_affect
	dupe.health_impacts_size = health_impacts_size
	dupe.count_items_for_sprite = count_items_for_sprite
	dupe.item_multiplier = item_multiplier
	// Reagent bellies || RS Add || Chomp Port
	dupe.count_liquid_for_sprite = count_liquid_for_sprite
	dupe.liquid_multiplier = liquid_multiplier
	dupe.liquid_overlay = liquid_overlay
	dupe.max_liquid_level = max_liquid_level
	dupe.reagent_touches = reagent_touches
	dupe.mush_overlay = mush_overlay
	dupe.mush_color = mush_color
	dupe.mush_alpha = mush_alpha
	dupe.max_mush = max_mush
	dupe.min_mush = min_mush
	dupe.custom_reagentcolor = custom_reagentcolor
	dupe.custom_reagentalpha = custom_reagentalpha
	// End reagent bellies
	//RS Edit || Ports CHOMPStation PR 5161
	dupe.slow_digestion = slow_digestion
	dupe.slow_brutal = slow_brutal
	//RS Edit End

	// Begin reagent bellies || RS Add || Chomp Port
	dupe.show_liquids = show_liquids
	dupe.reagent_mode_flags = reagent_mode_flags
	dupe.reagentid = reagentid
	dupe.reagentcolor = reagentcolor
	dupe.liquid_fullness1_messages = liquid_fullness1_messages
	dupe.liquid_fullness2_messages = liquid_fullness2_messages
	dupe.liquid_fullness3_messages = liquid_fullness3_messages
	dupe.liquid_fullness4_messages = liquid_fullness4_messages
	dupe.liquid_fullness5_messages = liquid_fullness5_messages
	dupe.reagent_name = reagent_name
	dupe.reagent_chosen = reagent_chosen
	dupe.gen_cost = gen_cost
	dupe.gen_amount = gen_amount
	dupe.gen_time = gen_time
	dupe.gen_time_display = gen_time_display
	dupe.custom_max_volume = custom_max_volume
	dupe.show_fullness_messages = show_fullness_messages
	// End reagent bellies

	dupe.autotransferchance = autotransferchance  //RS ADD Start || Port Chomp 2821, 2979, 6155
	dupe.autotransferwait = autotransferwait
	dupe.autotransferlocation = autotransferlocation
	dupe.autotransfer_enabled = autotransfer_enabled
	dupe.autotransferchance_secondary = autotransferchance_secondary
	dupe.autotransferlocation_secondary = autotransferlocation_secondary
	dupe.autotransfer_min_amount = autotransfer_min_amount
	dupe.autotransfer_max_amount = autotransfer_max_amount  //RS Add End


	//// Object-holding variables
	//struggle_messages_outside - strings
	dupe.struggle_messages_outside.Cut()
	for(var/I in struggle_messages_outside)
		dupe.struggle_messages_outside += I

	//struggle_messages_inside - strings
	dupe.struggle_messages_inside.Cut()
	for(var/I in struggle_messages_inside)
		dupe.struggle_messages_inside += I

	//absorbed_struggle_messages_outside - strings
	dupe.absorbed_struggle_messages_outside.Cut()
	for(var/I in absorbed_struggle_messages_outside)
		dupe.absorbed_struggle_messages_outside += I

	//absorbed_struggle_messages_inside - strings
	dupe.absorbed_struggle_messages_inside.Cut()
	for(var/I in absorbed_struggle_messages_inside)
		dupe.absorbed_struggle_messages_inside += I
	//RS edit start - port VS 15559
	//escape_attempt_messages_owner - strings
	dupe.escape_attempt_messages_owner.Cut()
	for(var/I in escape_attempt_messages_owner)
		dupe.escape_attempt_messages_owner += I

	//escape_attempt_messages_prey - strings
	dupe.escape_attempt_messages_prey.Cut()
	for(var/I in escape_attempt_messages_prey)
		dupe.escape_attempt_messages_prey += I

	//escape_messages_owner - strings
	dupe.escape_messages_owner.Cut()
	for(var/I in escape_messages_owner)
		dupe.escape_messages_owner += I

	//escape_messages_prey - strings
	dupe.escape_messages_prey.Cut()
	for(var/I in escape_messages_prey)
		dupe.escape_messages_prey += I

	//escape_messages_outside - strings
	dupe.escape_messages_outside.Cut()
	for(var/I in escape_messages_outside)
		dupe.escape_messages_outside += I

	//escape_item_messages_owner - strings
	dupe.escape_item_messages_owner.Cut()
	for(var/I in escape_item_messages_owner)
		dupe.escape_item_messages_owner += I

	//escape_item_messages_prey - strings
	dupe.escape_item_messages_prey.Cut()
	for(var/I in escape_item_messages_prey)
		dupe.escape_item_messages_prey += I

	//escape_item_messages_outside - strings
	dupe.escape_item_messages_outside.Cut()
	for(var/I in escape_item_messages_outside)
		dupe.escape_item_messages_outside += I

	//escape_fail_messages_owner - strings
	dupe.escape_fail_messages_owner.Cut()
	for(var/I in escape_fail_messages_owner)
		dupe.escape_fail_messages_owner += I

	//escape_fail_messages_prey - strings
	dupe.escape_fail_messages_prey.Cut()
	for(var/I in escape_fail_messages_prey)
		dupe.escape_fail_messages_prey += I

	//escape_attempt_absorbed_messages_owner - strings
	dupe.escape_attempt_absorbed_messages_owner.Cut()
	for(var/I in escape_attempt_absorbed_messages_owner)
		dupe.escape_attempt_absorbed_messages_owner += I

	//escape_attempt_absorbed_messages_prey - strings
	dupe.escape_attempt_absorbed_messages_prey.Cut()
	for(var/I in escape_attempt_absorbed_messages_prey)
		dupe.escape_attempt_absorbed_messages_prey += I

	//escape_absorbed_messages_owner - strings
	dupe.escape_absorbed_messages_owner.Cut()
	for(var/I in escape_absorbed_messages_owner)
		dupe.escape_absorbed_messages_owner += I

	//escape_absorbed_messages_prey - strings
	dupe.escape_absorbed_messages_prey.Cut()
	for(var/I in escape_absorbed_messages_prey)
		dupe.escape_absorbed_messages_prey += I

	//escape_absorbed_messages_outside - strings
	dupe.escape_absorbed_messages_outside.Cut()
	for(var/I in escape_absorbed_messages_outside)
		dupe.escape_absorbed_messages_outside += I

	//escape_fail_absorbed_messages_owner - strings
	dupe.escape_fail_absorbed_messages_owner.Cut()
	for(var/I in escape_fail_absorbed_messages_owner)
		dupe.escape_fail_absorbed_messages_owner += I

	//escape_fail_absorbed_messages_prey - strings
	dupe.escape_fail_absorbed_messages_prey.Cut()
	for(var/I in escape_fail_absorbed_messages_prey)
		dupe.escape_fail_absorbed_messages_prey += I

	//primary_transfer_messages_owner - strings
	dupe.primary_transfer_messages_owner.Cut()
	for(var/I in primary_transfer_messages_owner)
		dupe.primary_transfer_messages_owner += I

	//primary_transfer_messages_prey - strings
	dupe.primary_transfer_messages_prey.Cut()
	for(var/I in primary_transfer_messages_prey)
		dupe.primary_transfer_messages_prey += I

	//secondary_transfer_messages_owner - strings
	dupe.secondary_transfer_messages_owner.Cut()
	for(var/I in secondary_transfer_messages_owner)
		dupe.secondary_transfer_messages_owner += I

	//secondary_transfer_messages_prey - strings
	dupe.secondary_transfer_messages_prey.Cut()
	for(var/I in secondary_transfer_messages_prey)
		dupe.secondary_transfer_messages_prey += I

	//digest_chance_messages_owner - strings
	dupe.digest_chance_messages_owner.Cut()
	for(var/I in digest_chance_messages_owner)
		dupe.digest_chance_messages_owner += I

	//digest_chance_messages_prey - strings
	dupe.digest_chance_messages_prey.Cut()
	for(var/I in digest_chance_messages_prey)
		dupe.digest_chance_messages_prey += I

	//absorb_chance_messages_owner - strings
	dupe.absorb_chance_messages_owner.Cut()
	for(var/I in absorb_chance_messages_owner)
		dupe.absorb_chance_messages_owner += I

	//absorb_chance_messages_prey - strings
	dupe.absorb_chance_messages_prey.Cut()
	for(var/I in absorb_chance_messages_prey)
		dupe.absorb_chance_messages_prey += I

	//select_chance_messages_owner - strings
	dupe.select_chance_messages_owner.Cut()
	for(var/I in select_chance_messages_owner)
		dupe.select_chance_messages_owner += I

	//select_chance_messages_prey - strings
	dupe.select_chance_messages_prey.Cut()
	for(var/I in select_chance_messages_prey)
		dupe.select_chance_messages_prey += I
	//RS edit end

	//digest_messages_owner - strings
	dupe.digest_messages_owner.Cut()
	for(var/I in digest_messages_owner)
		dupe.digest_messages_owner += I

	//digest_messages_prey - strings
	dupe.digest_messages_prey.Cut()
	for(var/I in digest_messages_prey)
		dupe.digest_messages_prey += I

	//absorb_messages_owner - strings
	dupe.absorb_messages_owner.Cut()
	for(var/I in absorb_messages_owner)
		dupe.absorb_messages_owner += I

	//absorb_messages_prey - strings
	dupe.absorb_messages_prey.Cut()
	for(var/I in absorb_messages_prey)
		dupe.absorb_messages_prey += I

	//unabsorb_messages_owner - strings
	dupe.unabsorb_messages_owner.Cut()
	for(var/I in unabsorb_messages_owner)
		dupe.unabsorb_messages_owner += I

	//unabsorb_messages_prey - strings
	dupe.unabsorb_messages_prey.Cut()
	for(var/I in unabsorb_messages_prey)
		dupe.unabsorb_messages_prey += I

	//examine_messages - strings
	dupe.examine_messages.Cut()
	for(var/I in examine_messages)
		dupe.examine_messages += I

	//examine_messages_absorbed - strings
	dupe.examine_messages_absorbed.Cut()
	for(var/I in examine_messages_absorbed)
		dupe.examine_messages_absorbed += I

	// Begin reagent bellies || RS Add || Chomp Port
	//generated_reagents - strings
	dupe.generated_reagents.Cut()
	for(var/I in generated_reagents)
		dupe.generated_reagents += I

	// CHOMP fullness messages stage 1
	//fullness1_messages - strings
	dupe.fullness1_messages.Cut()
	for(var/I in fullness1_messages)
		dupe.fullness1_messages += I

	// CHOMP fullness messages stage 2
	//fullness2_messages - strings
	dupe.fullness2_messages.Cut()
	for(var/I in fullness2_messages)
		dupe.fullness2_messages += I

	// CHOMP fullness messages stage 3
	//fullness3_messages - strings
	dupe.fullness3_messages.Cut()
	for(var/I in fullness3_messages)
		dupe.fullness3_messages += I

	// CHOMP fullness messages stage 4
	//fullness4_messages - strings
	dupe.fullness4_messages.Cut()
	for(var/I in fullness4_messages)
		dupe.fullness4_messages += I

	// CHOMP fullness messages stage 5
	//generated_reagents - strings
	dupe.fullness5_messages.Cut()
	for(var/I in fullness5_messages)
		dupe.fullness5_messages += I
	// End reagent bellies

	//emote_lists - index: digest mode, key: list of strings
	dupe.emote_lists.Cut()
	for(var/K in emote_lists)
		dupe.emote_lists[K] = list()
		for(var/I in emote_lists[K])
			dupe.emote_lists[K] += I

	return dupe

/obj/belly/container_resist(mob/M)
	return relay_resist(M)

/mob/living/proc/post_digestion()	//In case we want to have a mob do anything after a digestion concludes	//RS ADD
	return	//RS ADD

//RS ADD START - Moved and generalized the selectable actions for bellies so they can be called from different kinds of things!
/obj/belly/proc/check_belly_access(var/user,var/mob/living/our_prey,var/consider_stat = TRUE)
	if(user && user != owner)
		return FALSE
	if(our_prey.loc != src)
		to_chat(owner, "[our_prey] is not inside of \the [src]!")
		return FALSE
	if(owner.stat && consider_stat)
		to_chat(owner,"<span class='warning'>You can't do that in your state!</span>")
		return FALSE
	return TRUE

/obj/belly/proc/examine_target(var/mob/living/our_prey,var/mob/living/user)
	to_chat(user, jointext(our_prey.examine(user), "<br>"))

/obj/belly/proc/eject_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey)) return
	release_specific_contents(our_prey)

/obj/belly/proc/move_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey)) return

	var/list/choices = owner.vore_organs.Copy()

	choices -= src

	var/obj/belly/choice = tgui_input_list(usr, "Move [our_prey] where?","Select Belly", owner.vore_organs)
	if(!choice || !(our_prey in src.contents))
		return
	to_chat(our_prey,"<span class='warning'>You're squished from [owner]'s [lowertext(src.name)] to their [lowertext(choice.name)]!</span>")
	transfer_contents(our_prey, choice)

/obj/belly/proc/transfer_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey)) return

	if(isliving(our_prey))
		if(!our_prey.ssd_vore_check(owner))
			return

	if(tgui_alert(owner, "Do you want to transfer between your own bellies, or someone else's?", "Belly Transfer", list("Mine", "Someone Else's")) == "Mine")
		move_target(our_prey)
		return

	var/list/viable_candidates = list()
	for(var/mob/living/candidate in range(1, owner))
		if(istype(candidate) && !(candidate == owner))
			if(candidate.vore_organs.len && candidate.feeding && !candidate.no_vore)
				viable_candidates += candidate
	if(!viable_candidates.len)
		to_chat(owner, "<span class='notice'>There are no viable candidates around you!</span>")
		return
	var/mob/living/belly_owner = tgui_input_list(owner, "Who do you want to receive [our_prey]?", "Select Predator", viable_candidates)

	if(!belly_owner || !(belly_owner in range(1, owner)))
		return

	var/obj/belly/choice = tgui_input_list(owner, "Move [our_prey] where?","Select Belly", belly_owner.vore_organs)
	if(!choice)
		return
	if(our_prey.loc != src)
		to_chat(owner,SPAN_WARNING("\The [our_prey] is not inside your [src] anymore."))
		return
	if(!(belly_owner in range(1, owner)))
		to_chat(owner,SPAN_WARNING("\The [belly_owner] is no longer in range!"))
		return
	to_chat(owner, "<span class='notice'>Transfer offer sent. Await their response.</span>")
	var/accepted = tgui_alert(belly_owner, "[owner] is trying to transfer [our_prey] from their [lowertext(name)] into your [lowertext(choice.name)]. Do you accept?", "Feeding Offer", list("Yes", "No"))
	if(accepted != "Yes")
		to_chat(owner, "<span class='warning'>[belly_owner] refused the transfer!!</span>")
		return
	if(!(belly_owner in range(1, owner)))
		to_chat(owner,SPAN_WARNING("\The [belly_owner] is no longer in range!"))
		return
	if(our_prey.loc != src)
		to_chat(owner,SPAN_WARNING("\The [our_prey] is not inside your [src] anymore."))
		return
	to_chat(our_prey,"<span class='warning'>You're squished from [owner]'s [lowertext(name)] to [belly_owner]'s [lowertext(choice.name)]!</span>")
	to_chat(belly_owner,"<span class='warning'>[our_prey] is squished from [owner]'s [lowertext(name)] to your [lowertext(choice.name)]!</span>")
	transfer_contents(our_prey, choice)

/obj/belly/proc/transform_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey)) return

	var/mob/living/carbon/human/H = our_prey
	if(!istype(H))
		return

	var/datum/tgui_module/appearance_changer/vore/V = new(owner, H)
	V.tgui_interact(owner)
	return

/obj/belly/proc/process_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey)) return

	if(!our_prey.client)
		to_chat(owner, "<span class= 'warning'>You cannot instantly process [our_prey].</span>")
		return

	var/list/process_options = list()

	if(our_prey.digestable)
		process_options += "Digest"

	if(our_prey.absorbable)
		process_options += "Absorb"

	process_options += "Knockout" //Can't think of any mechanical prefs that would restrict this. // RS Edit || Ports VOREStation PR15876

	if(process_options.len)
		process_options += "Cancel"

	else
		to_chat(owner, "<span class= 'warning'>You cannot instantly process [our_prey].</span>")
		return

	var/ourchoice = tgui_input_list(owner, "How would you prefer to process \the [our_prey]? This will perform the given action instantly if the prey accepts.","Instant Process", process_options)
	if(!ourchoice)
		return
	if(!our_prey.client)
		to_chat(owner, "<span class= 'warning'>You cannot instantly process [our_prey].</span>")
		return
	switch(ourchoice)
		if("Digest")
			if(our_prey.absorbed)
				to_chat(owner, "<span class= 'warning'>\The [our_prey] is absorbed, and cannot presently be digested.</span>")
				return
			if(tgui_alert(our_prey, "\The [owner] is attempting to instantly digest you. Is this something you are okay with happening to you?","Instant Digest", list("No", "Yes")) != "Yes")
				to_chat(owner, "<span class= 'warning'>\The [our_prey] declined your digest attempt.</span>")
				to_chat(our_prey, "<span class= 'warning'>You declined the digest attempt.</span>")
				return
			if(our_prey.loc != src)
				to_chat(owner, "<span class= 'warning'>\The [our_prey] is no longer in \the [src].</span>")
				return
			if(isliving(owner))
				var/mob/living/l = owner
				var/thismuch = our_prey.health + 100
				if(ishuman(l))
					var/mob/living/carbon/human/h = l
					thismuch = thismuch * h.species.digestion_nutrition_modifier
				l.adjust_nutrition(thismuch)
			our_prey.mind?.vore_death = TRUE
			our_prey.death()		// To make sure all on-death procs get properly called
			if(our_prey) //RS Edit start || Ports CHOMPStation 7158
				if(our_prey.is_preference_enabled(/datum/client_preference/digestion_noises))
					SEND_SOUND(our_prey, sound(get_sfx("fancy_death_prey")))
				handle_digestion_death(our_prey) // RS Edit end
		if("Absorb")
			if(tgui_alert(our_prey, "\The [owner] is attempting to instantly absorb you. Is this something you are okay with happening to you?","Instant Absorb", list("No", "Yes")) != "Yes")
				to_chat(owner, "<span class= 'warning'>\The [our_prey] declined your absorb attempt.</span>")
				to_chat(our_prey, "<span class= 'warning'>You declined the absorb attempt.</span>")
				return
			if(our_prey.loc != src)
				to_chat(owner, "<span class= 'warning'>\The [our_prey] is no longer in \the [src].</span>")
				return
			if(isliving(owner))
				var/mob/living/l = owner
				l.adjust_nutrition(our_prey.nutrition)
				var/n = 0 - our_prey.nutrition
				our_prey.adjust_nutrition(n)
			absorb_living(our_prey)
		//RS Edit || Ports VOREStation PR15876
		if("Knockout")
			if(tgui_alert(our_prey, "\The [owner] is attempting to instantly make you unconscious, you will be unable until ejected from the pred. Is this something you are okay with happening to you?","Instant Knockout", list("No", "Yes")) != "Yes")
				to_chat(owner, "<span class= 'vwarning'>\The [our_prey] declined your knockout attempt.</span>")
				to_chat(our_prey, "<span class= 'vwarning'>You declined the knockout attempt.</span>")
				return
			if(our_prey.loc != src)
				to_chat(owner, "<span class= 'vwarning'>\The [our_prey] is no longer in \the [src].</span>")
				return
			our_prey.AdjustSleeping(500000)
			to_chat(our_prey, "<span class= 'vwarning'>\The [owner] has put you to sleep, you will remain unconscious until ejected from the belly.</span>")
		if("Cancel")
			return
		//RS Edit || Ports VOREStation PR15876

/obj/belly/proc/advance_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey)) return
	var/list/choices = list()
	var/obj/belly/choice
	for(var/obj/belly/b in owner.vore_organs)
		if(b.name == transferlocation || b.name == transferlocation_secondary)
			choices += b
	if(!choices.len)
		to_chat(owner,"<span class='warning'>You haven't configured any transfer locations for your [lowertext(name)]. Please configure at least one transfer location in order to advance your [lowertext(name)]'s contents.</span>")
		return
	choice = tgui_input_list(owner, "Advance your [lowertext(name)]'s contents to which belly?","Select Belly", choices)
	if(!choice)
		return
	if(our_prey.loc != src)
		to_chat(owner,"<span class='warning'>\The [our_prey] is not in \the [src] anymore!</span>")
		return
	to_chat(our_prey,"<span class='warning'>You're squished from [owner]'s [lowertext(name)] to their [lowertext(choice.name)]!</span>")
	for(var/obj/belly/b in owner.vore_organs)
		if(b.name == choice)
			choice = b
	transfer_contents(our_prey, choice)

/obj/belly/proc/healthbar_target(var/mob/living/our_prey)
	if(!check_belly_access(usr,our_prey,FALSE)) return
	new /obj/screen/movable/rs_ui/healthbar(owner,our_prey,owner)

/obj/belly/proc/return_effective_d_mode(var/mob/living/ourmob)
	if(!isliving(ourmob))
		return FALSE
	if(digest_mode == DM_SELECT)
		switch(ourmob.selective_preference)
			if(DM_DIGEST)
				return DM_DIGEST
			if(DM_ABSORB)
				return DM_ABSORB
			if(DM_DRAIN)
				return DM_DRAIN
			if(DM_DEFAULT)
				switch(selective_preference)
					if(DM_DIGEST)
						return DM_DIGEST
					if(DM_ABSORB)
						return DM_ABSORB
					if(DM_DRAIN)
						return DM_DRAIN
	else
		return digest_mode

//RS ADD END
