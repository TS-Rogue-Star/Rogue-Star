
/*
VVVVVVVV           VVVVVVVV     OOOOOOOOO     RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEE
V::::::V           V::::::V   OO:::::::::OO   R::::::::::::::::R  E::::::::::::::::::::E
V::::::V           V::::::V OO:::::::::::::OO R::::::RRRRRR:::::R E::::::::::::::::::::E
V::::::V           V::::::VO:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEEE::::E
 V:::::V           V:::::V O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
  V:::::V         V:::::V  O:::::O     O:::::O  R::::R     R:::::R  E:::::E
   V:::::V       V:::::V   O:::::O     O:::::O  R::::RRRRRR:::::R   E::::::EEEEEEEEEE
    V:::::V     V:::::V    O:::::O     O:::::O  R:::::::::::::RR    E:::::::::::::::E
     V:::::V   V:::::V     O:::::O     O:::::O  R::::RRRRRR:::::R   E:::::::::::::::E
      V:::::V V:::::V      O:::::O     O:::::O  R::::R     R:::::R  E::::::EEEEEEEEEE
       V:::::V:::::V       O:::::O     O:::::O  R::::R     R:::::R  E:::::E
        V:::::::::V        O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
         V:::::::V         O:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEE:::::E
          V:::::V           OO:::::::::::::OO R::::::R     R:::::RE::::::::::::::::::::E
           V:::V              OO:::::::::OO   R::::::R     R:::::RE::::::::::::::::::::E
            VVV                 OOOOOOOOO     RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE

-Aro <3 */

#define VORE_VERSION	2	//This is a Define so you don't have to worry about magic numbers.

//
// Overrides/additions to stock defines go here, as well as hooks. Sort them by
// the object they are overriding. So all /mob/living together, etc.
//
/datum/configuration
	var/items_survive_digestion = TRUE	//For configuring if the important_items survive digestion

//
// The datum type bolted onto normal preferences datums for storing Virgo stuff
//
/client
	var/datum/vore_preferences/prefs_vr

/mob
	var/bellies_loaded = TRUE

/hook/client_new/proc/add_prefs_vr(client/C)
	C.prefs_vr = new/datum/vore_preferences(C)
	if(C.prefs_vr)
		return TRUE

	return FALSE

/datum/vore_preferences
	//Actual preferences
	var/digestable = TRUE
	var/devourable = TRUE
	var/absorbable = TRUE
	var/feeding = TRUE
	var/can_be_drop_prey = FALSE
	var/can_be_drop_pred = FALSE
	var/allow_inbelly_spawning = FALSE
	var/allow_spontaneous_tf = FALSE
	var/digest_leave_remains = FALSE
	var/allowmobvore = TRUE
	var/permit_healbelly = TRUE
	var/noisy = FALSE
	var/eating_privacy_global = FALSE //Makes eating attempt/success messages only reach for subtle range if true, overwritten by belly-specific var

	// These are 'modifier' prefs, do nothing on their own but pair with drop_prey/drop_pred settings.
	var/drop_vore = TRUE
	var/stumble_vore = TRUE
	var/buckle_vore = TRUE // RS Add: Split from stumble (Lira, January 2026)
	var/slip_vore = TRUE
	var/throw_vore = TRUE
	var/food_vore = TRUE
	var/emote_vore = TRUE // RS Add: New emote spont vore (Lira, February 2026)
	var/list/spont_belly_prefs = list() // RS Add: Add spont prefs (Lira, January 2026)

	var/resizable = TRUE
	var/show_vore_fx = TRUE
	var/step_mechanics_pref = FALSE
	var/pickup_pref = TRUE

	var/autotransferable = TRUE //RS Add || Chomp Port 3200

	var/vore_sprite_color = list("stomach" = "#000", "taur belly" = "#000") // RS edit
	var/allow_contaminate = TRUE	//RS EDIT
	var/allow_stripping = TRUE		//RS EDIT

	var/list/belly_prefs = list()
	var/vore_taste = "nothing in particular"
	var/vore_smell = "nothing in particular"
	var/glowy_belly = FALSE //RS Add

	var/selective_preference = DM_DEFAULT


	var/nutrition_message_visible = TRUE
	var/list/nutrition_messages = list(
							"They are starving! You can hear their stomach snarling from across the room!",
							"They are extremely hungry. A deep growl occasionally rumbles from their empty stomach.",
							"",
							"They have a stuffed belly, bloated fat and round from eating too much.",
							"They have a rotund, thick gut. It bulges from their body obscenely, close to sagging under its own weight.",
							"They are sporting a large, round, sagging stomach. It contains at least their body weight worth of glorping slush.",
							"They are engorged with a huge stomach that sags and wobbles as they move. They must have consumed at least twice their body weight. It looks incredibly soft.",
							"Their stomach is firmly packed with digesting slop. They must have eaten at least a few times worth their body weight! It looks hard for them to stand, and their gut jiggles when they move.",
							"They are so absolutely stuffed that you aren't sure how it's possible for them to move. They can't seem to swell any bigger. The surface of their belly looks sorely strained!",
							"They are utterly filled to the point where it's hard to even imagine them moving, much less comprehend it when they do. Their gut is swollen to monumental sizes and amount of food they consumed must be insane.")
	var/weight_message_visible = TRUE
	var/list/weight_messages = list(
							"They are terribly lithe and frail!",
							"They have a very slender frame.",
							"They have a lightweight, athletic build.",
							"They have a healthy, average body.",
							"They have a thick, curvy physique.",
							"They have a plush, chubby figure.",
							"They have an especially plump body with a round potbelly and large hips.",
							"They have a very fat frame with a bulging potbelly, squishy rolls of pudge, very wide hips, and plump set of jiggling thighs.",
							"They are incredibly obese. Their massive potbelly sags over their waistline while their fat ass would probably require two chairs to sit down comfortably!",
							"They are so morbidly obese, you wonder how they can even stand, let alone waddle around the station. They can't get any fatter without being immobilized.")


	//Mechanically required
	var/path
	var/slot
	var/client/client
	var/client_ckey

	var/ssd_vore = FALSE	//RS ADD
	var/list/vore_whitelist_toggles = list()	//RS ADD - A list of the prefs that are dictated by whitelist

/datum/vore_preferences/New(client/C)
	if(istype(C))
		client = C
		client_ckey = C.ckey
		var/success = load_vore()
		log_debug("Loaded vore preferences for [C] with [success]")

//
//	Check if an object is capable of eating things, based on vore_organs
//
/proc/is_vore_predator(mob/living/O)
	if(istype(O,/mob/living))
		if(!O.vore_organs)	//RS ADD - it will runtime
			return FALSE	//RS ADD
		if(O.vore_organs.len > 0)
			return TRUE

	return FALSE

//
//	Belly searching for simplifying other procs
//  Mostly redundant now with belly-objects and isbelly(loc)
//
/proc/check_belly(atom/movable/A)
	return isbelly(A.loc)

//
// Save/Load Vore Preferences
//
/datum/vore_preferences/proc/load_path(ckey, slot, filename="character", ext="json")
	if(!ckey || !slot)
		return
	path = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/vore/[filename][slot].[ext]"


/datum/vore_preferences/proc/load_vore()
	if(!client || !client_ckey)
		return FALSE //No client, how can we save?
	if(!client.prefs || !client.prefs.default_slot)
		return FALSE //Need to know what character to load!

	slot = client.prefs.default_slot

	load_path(client_ckey,slot)

	if(!path)
		return FALSE //Path couldn't be set?
	if(!fexists(path)) //Never saved before
		save_vore() //Make the file first
		return TRUE

	var/list/json_from_file = json_decode(file2text(path))
	if(!json_from_file)
		return FALSE //My concern grows

	var/version = json_from_file["version"]
	json_from_file = patch_version(json_from_file,version)

	digestable = json_from_file["digestable"]
	devourable = json_from_file["devourable"]
	resizable = json_from_file["resizable"]
	feeding = json_from_file["feeding"]
	absorbable = json_from_file["absorbable"]
	digest_leave_remains = json_from_file["digest_leave_remains"]
	allowmobvore = json_from_file["allowmobvore"]
	vore_taste = json_from_file["vore_taste"]
	vore_smell = json_from_file["vore_smell"]
	permit_healbelly = json_from_file["permit_healbelly"]
	noisy = json_from_file["noisy"]
	selective_preference = json_from_file["selective_preference"]
	show_vore_fx = json_from_file["show_vore_fx"]
	can_be_drop_prey = json_from_file["can_be_drop_prey"]
	can_be_drop_pred = json_from_file["can_be_drop_pred"]
	allow_inbelly_spawning = json_from_file["allow_inbelly_spawning"]
	allow_spontaneous_tf = json_from_file["allow_spontaneous_tf"]
	step_mechanics_pref = json_from_file["step_mechanics_pref"]
	pickup_pref = json_from_file["pickup_pref"]
	belly_prefs = json_from_file["belly_prefs"]
	drop_vore = json_from_file["drop_vore"]
	slip_vore = json_from_file["slip_vore"]
	food_vore = json_from_file["food_vore"]
	throw_vore = json_from_file["throw_vore"]
	stumble_vore = json_from_file["stumble_vore"]
	buckle_vore = json_from_file["buckle_vore"] // RS Add: Split from stumble (Lira, January 2026)
	emote_vore = json_from_file["emote_vore"] // RS Add: New emote spont vore (Lira, February 2026)
	spont_belly_prefs = json_from_file["spont_belly_prefs"] // RS Add: Add spont prefs (Lira, January 2026)
	nutrition_message_visible = json_from_file["nutrition_message_visible"]
	nutrition_messages = json_from_file["nutrition_messages"]
	weight_message_visible = json_from_file["weight_message_visible"]
	weight_messages = json_from_file["weight_messages"]
	eating_privacy_global = json_from_file["eating_privacy_global"]
	vore_sprite_color = json_from_file["vore_sprite_color"] // RS edit
	ssd_vore = json_from_file["ssd_vore"] // RS edit
	glowy_belly = json_from_file["glowy_belly"] //RS ADD
	allow_contaminate = json_from_file["allow_contaminate"] // RS edit
	allow_stripping = json_from_file["allow_stripping"] // RS edit
	vore_whitelist_toggles = json_from_file["vore_whitelist_toggles"]	//RS ADD
	autotransferable = json_from_file["autotransferable"] //RS Add || Chomp Port 3200

	//Quick sanitize
	if(isnull(digestable))
		digestable = TRUE
	if(isnull(devourable))
		devourable = TRUE
	if(isnull(resizable))
		resizable = TRUE
	if(isnull(feeding))
		feeding = TRUE
	if(isnull(absorbable))
		absorbable = TRUE
	if(isnull(digest_leave_remains))
		digest_leave_remains = FALSE
	if(isnull(allowmobvore))
		allowmobvore = TRUE
	if(isnull(permit_healbelly))
		permit_healbelly = TRUE
	if(isnull(selective_preference))
		selective_preference = DM_DEFAULT
	if (isnull(noisy))
		noisy = FALSE
	if(isnull(show_vore_fx))
		show_vore_fx = TRUE
	if(isnull(can_be_drop_prey))
		can_be_drop_prey = FALSE
	if(isnull(can_be_drop_pred))
		can_be_drop_pred = FALSE
	if(isnull(allow_inbelly_spawning))
		allow_inbelly_spawning = FALSE
	if(isnull(allow_spontaneous_tf))
		allow_spontaneous_tf = FALSE
	if(isnull(step_mechanics_pref))
		step_mechanics_pref = TRUE
	if(isnull(pickup_pref))
		pickup_pref = TRUE
	if(isnull(belly_prefs))
		belly_prefs = list()
	if(isnull(drop_vore))
		drop_vore = TRUE
	if(isnull(slip_vore))
		slip_vore = TRUE
	if(isnull(throw_vore))
		throw_vore = TRUE
	if(isnull(stumble_vore))
		stumble_vore = TRUE
	// RS Add: Split from stumble (Lira, January 2026)
	if(isnull(buckle_vore))
		buckle_vore = stumble_vore
	if(isnull(food_vore))
		food_vore = TRUE
	// RS Add: New emote spont vore (Lira, February 2026)
	if(isnull(emote_vore))
		emote_vore = TRUE
	// RS Add: Use spont belly (Lira, January 2026)
	if(!islist(spont_belly_prefs))
		spont_belly_prefs = list()
	if(isnull(autotransferable)) //RS Add || Port Chomp 3200
		autotransferable = TRUE
	if(isnull(nutrition_message_visible))
		nutrition_message_visible = TRUE
	if(isnull(weight_message_visible))
		weight_message_visible = TRUE
	if(isnull(eating_privacy_global))
		eating_privacy_global = FALSE
	if(isnull(nutrition_messages))
		nutrition_messages = list(
							"They are starving! You can hear their stomach snarling from across the room!",
							"They are extremely hungry. A deep growl occasionally rumbles from their empty stomach.",
							"",
							"They have a stuffed belly, bloated fat and round from eating too much.",
							"They have a rotund, thick gut. It bulges from their body obscenely, close to sagging under its own weight.",
							"They are sporting a large, round, sagging stomach. It contains at least their body weight worth of glorping slush.",
							"They are engorged with a huge stomach that sags and wobbles as they move. They must have consumed at least twice their body weight. It looks incredibly soft.",
							"Their stomach is firmly packed with digesting slop. They must have eaten at least a few times worth their body weight! It looks hard for them to stand, and their gut jiggles when they move.",
							"They are so absolutely stuffed that you aren't sure how it's possible for them to move. They can't seem to swell any bigger. The surface of their belly looks sorely strained!",
							"They are utterly filled to the point where it's hard to even imagine them moving, much less comprehend it when they do. Their gut is swollen to monumental sizes and amount of food they consumed must be insane.")
	else if(nutrition_messages.len < 10)
		while(nutrition_messages.len < 10)
			nutrition_messages.Add("")
	if(isnull(weight_messages))
		weight_messages = list(
							"They are terribly lithe and frail!",
							"They have a very slender frame.",
							"They have a lightweight, athletic build.",
							"They have a healthy, average body.",
							"They have a thick, curvy physique.",
							"They have a plush, chubby figure.",
							"They have an especially plump body with a round potbelly and large hips.",
							"They have a very fat frame with a bulging potbelly, squishy rolls of pudge, very wide hips, and plump set of jiggling thighs.",
							"They are incredibly obese. Their massive potbelly sags over their waistline while their fat ass would probably require two chairs to sit down comfortably!",
							"They are so morbidly obese, you wonder how they can even stand, let alone waddle around the station. They can't get any fatter without being immobilized.")
	else if(weight_messages.len < 10)
		while(weight_messages.len < 10)
			weight_messages.Add("")

	if(isnull(vore_sprite_color)) //RS edit
		vore_sprite_color = list("stomach" = "#000", "taur belly" = "#000") //RS edit
	if(isnull(ssd_vore))	//RS ADD
		ssd_vore = FALSE	//RS ADD
	if(isnull(allow_contaminate))	//RS ADD
		allow_contaminate = TRUE	//RS ADD
	if(isnull(allow_stripping))	//RS ADD
		allow_stripping = TRUE	//RS ADD
	if(isnull(glowy_belly)) //RS ADD
		glowy_belly =  FALSE //RS ADD
	if(isnull(vore_whitelist_toggles))	//RS ADD
		vore_whitelist_toggles = list()	//RS ADD
	return TRUE

/datum/vore_preferences/proc/save_vore()
	if(!path)
		return FALSE

	var/version = VORE_VERSION	//For "good times" use in the future
	var/list/settings_list = list(
			"version"				= version,
			"digestable"			= digestable,
			"devourable"			= devourable,
			"resizable"				= resizable,
			"absorbable"			= absorbable,
			"feeding"				= feeding,
			"digest_leave_remains"	= digest_leave_remains,
			"allowmobvore"			= allowmobvore,
			"vore_taste"			= vore_taste,
			"vore_smell"			= vore_smell,
			"permit_healbelly"		= permit_healbelly,
			"noisy" 				= noisy,
			"selective_preference"	= selective_preference,
			"show_vore_fx"			= show_vore_fx,
			"can_be_drop_prey"		= can_be_drop_prey,
			"can_be_drop_pred"		= can_be_drop_pred,
			"allow_inbelly_spawning"= allow_inbelly_spawning,
			"allow_spontaneous_tf"	= allow_spontaneous_tf,
			"step_mechanics_pref"	= step_mechanics_pref,
			"pickup_pref"			= pickup_pref,
			"belly_prefs"			= belly_prefs,
			"drop_vore"				= drop_vore,
			"slip_vore"				= slip_vore,
			"stumble_vore"			= stumble_vore,
			"buckle_vore"			= buckle_vore, // RS Add: Split from stumble (Lira, January 2026)
			"throw_vore" 			= throw_vore,
			"food_vore" 			= food_vore,
			"emote_vore"			= emote_vore, // RS Add: New emote spont vore (Lira, February 2026)
			"spont_belly_prefs"		= spont_belly_prefs, // RS Add: Use spont belly (Lira, January 2026)
			"nutrition_message_visible"	= nutrition_message_visible,
			"nutrition_messages"		= nutrition_messages,
			"weight_message_visible"	= weight_message_visible,
			"weight_messages"			= weight_messages,
			"eating_privacy_global"		= eating_privacy_global,
			"vore_sprite_color"		= vore_sprite_color, //RS edit
			"ssd_vore"				= ssd_vore,	//RS ADD
			"glowy_belly"			= glowy_belly, //RS ADD
			"allow_contaminate" 	= allow_contaminate, // RS edit
			"allow_stripping" 		= allow_stripping, // RS edit
			"vore_whitelist_toggles" = vore_whitelist_toggles, //RS ADD
			"autotransferable"		= autotransferable, //RS Add || Port Chomp 3200
		)

	//List to JSON
	var/json_to_file = json_encode(settings_list)
	if(!json_to_file)
		log_debug("Saving: [path] failed jsonencode")
		return FALSE

	//Write it out
	rustg_file_write(json_to_file, path)

	if(!fexists(path))
		log_debug("Saving: [path] failed file write")
		return FALSE

	return TRUE

//Can do conversions here
/datum/vore_preferences/proc/patch_version(var/list/json_from_file,var/version)
	return json_from_file

////////////////////////// Misc Drugs //////////////////////////

/datum/reagent/drugs/rainbow_toxin /// Replaces Space Drugs.
	name = "Rainbow Toxin"
	id = "rainbowtoxin"
	description = "Known for providing a euphoric high, this psychoactive drug is often injected into unknowing prey by serpents and other fanged beasts. Highly valuable and frequently sought after by hypno-enthusiasts and party-goers."
	taste_description = "mixed euphoria"
	taste_mult = 0.8 //You ARE going to taste this!
	scannable = 1	//Sure! If you manage to milk a snake for some of this, go ahead and scan it and mass produce it. Your local club will love you!

/datum/reagent/drugs/rainbow_toxin/affect_blood(mob/living/carbon/M, var/alien, var/removed)
	..()
	var/drug_strength = 20
	M.druggy = max(M.druggy, drug_strength)

/datum/reagent/drugs/bliss/overdose(var/mob/living/M as mob)
	if(prob_proc == TRUE && prob(20))
		M.hallucination = max(M.hallucination, 5)
		prob_proc = FALSE
	M.adjustBrainLoss(0.25*REM) //Too much isn't good for your long term health...
	M.adjustToxLoss(0.01*REM)	//Enough that it'll make your HUD dummy update, but not enough that you'll vomit mid scene. (Sorry emetophiliacs!)
	..()

/datum/reagent/paralysis_toxin
	name = "Tetrodotoxin"
	id = "paralysistoxin"
	description = "A potent toxin commonly found in a plethora of species. When exposed to the toxin, causes extreme, paralysis for a prolonged period, with only essential functions of the body being unhindered. Commonly used by covert operatives and used as a crowd control tool."
	taste_description = "bitterness"
	reagent_state = LIQUID
	color = "#37007f"
	metabolism = REM * 0.25
	overdose = REAGENTS_OVERDOSE
	scannable = 0 //YOU ARE NOT SCANNING THE FUNNY PARALYSIS TOXIN. NO. BAD. STAY AWAY.

/datum/reagent/paralysis_toxin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(M.weakened < 50) //Let's not leave them PERMA stuck, after all.
		M.AdjustWeakened(5) //Stand in for paralyze so you can still talk/emote/see

/datum/reagent/pain_enzyme
	name = "Pain Enzyme"
	id = "painenzyme"
	description = "An enzyme found in a variety of species. When exposed to the toxin, will cause severe, agonizing pain. The effects can last for hours depending on the dose. Only known cure is an equally strong painkiller or dialysis."
	taste_description = "sourness"
	reagent_state = LIQUID
	color = "#04b8fa" //Light blue in honor of Perry.
	metabolism = 0.1 //Lasts up to 50 seconds if you give 5 units.
	mrate_static = TRUE
	overdose = 100 //There is no OD. You already are taking the worst of it.
	scannable = 0 //Let's not have medical mechs able to make an extremely strong 'I hit you you fall down in agony' chem.

/datum/reagent/pain_enzyme/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	M.add_chemical_effect(CE_PAINKILLER, -200)
	if(prob(0.01)) //1 in 10000 chance per tick. Extremely rare.
		to_chat(M,"<span class='warning'>Your body feels as though it's on fire!</span>")
