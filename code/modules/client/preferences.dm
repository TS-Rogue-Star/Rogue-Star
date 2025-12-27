#define SAVE_RESET -1

var/list/preferences_datums = list()

/datum/preferences
	//doohickeys for savefiles
	var/path
	var/default_slot = 1				//Holder so it doesn't default to slot 1, rather the last one used
	var/savefile_version = 0

	//non-preference stuff
	var/warns = 0
	var/muted = 0
	var/last_ip
	var/last_id

	// RS Add: Track cooldowns for character setup reloads/marking selections (Lira, November 2025)
	var/next_charsetup_reload = 0	// world.time when reloading is allowed again
	var/next_marking_select = 0	// world.time when selecting markings is allowed again

	//game-preferences
	var/lastchangelog = ""				//Saved changlog filesize to detect if there was a change
	var/ooccolor = "#010000"			//Whatever this is set to acts as 'reset' color and is thus unusable as an actual custom color
	var/be_special = 0					//Special role selection
	var/UI_style = "Midnight"
	var/UI_style_color = "#ffffff"
	var/UI_style_alpha = 255
	var/tooltipstyle = "Midnight"		//Style for popup tooltips
	var/client_fps = 40
	//var/ambience_freq = 0				// How often we're playing repeating ambience to a client. //RS Edit. See PR #67. Handled in area/enter()
	var/ambience_chance = 35			// What's the % chance we'll play ambience (in conjunction with the above frequency)

	var/tgui_fancy = TRUE
	var/tgui_lock = FALSE
	var/tgui_input_mode = FALSE			// All the Input Boxes (Text,Number,List,Alert)
	var/tgui_input_lock = FALSE
	var/tgui_large_buttons = TRUE
	var/tgui_swapped_buttons = FALSE
	var/chat_timestamp = FALSE

	//character preferences
	var/real_name						//our character's name
	var/be_random_name = 0				//whether we are a random name every round
	var/nickname						//our character's nickname
	var/age = 30						//age of character
	var/bday_month = 0					//Birthday month
	var/bday_day = 0					//Birthday day
	var/last_birthday_notification = 0	//The last year we were notified about our birthday
	var/bday_announce = FALSE			//Public announcement for birthdays
	var/spawnpoint = "Arrivals Shuttle" //where this character will spawn (0-2).
	var/b_type = "A+"					//blood type (not-chooseable)
	var/blood_reagents = "iron"				//blood restoration reagents
	var/backbag = 2						//backpack type
	var/pdachoice = 1					//PDA type
	var/shoe_hater = FALSE				//RS ADD - if true, will spawn with no shoes
	var/h_style = "Bald"				//Hair type
	var/r_hair = 0						//Hair color
	var/g_hair = 0						//Hair color
	var/b_hair = 0						//Hair color
	var/grad_style = "none"				//Gradient style
	var/r_grad = 0						//Gradient color
	var/g_grad = 0						//Gradient color
	var/b_grad = 0						//Gradient color
	var/f_style = "Shaved"				//Face hair type
	var/r_facial = 0					//Face hair color
	var/g_facial = 0					//Face hair color
	var/b_facial = 0					//Face hair color
	var/s_tone = -75						//Skin tone
	var/r_skin = 238					//Skin color // Vorestation edit, so color multi sprites can aren't BLACK AS THE VOID by default.
	var/g_skin = 206					//Skin color // Vorestation edit, so color multi sprites can aren't BLACK AS THE VOID by default.
	var/b_skin = 179					//Skin color // Vorestation edit, so color multi sprites can aren't BLACK AS THE VOID by default.
	var/r_eyes = 0						//Eye color
	var/g_eyes = 0						//Eye color
	var/b_eyes = 0						//Eye color
	var/species = SPECIES_HUMAN         //Species datum to use.
	var/species_preview                 //Used for the species selection window.
	var/list/alternate_languages = list() //Secondary language(s)
	var/list/language_prefixes = list() //Language prefix keys
	var/list/language_custom_keys = list() //Language custom call keys
	var/list/gear						//Left in for Legacy reasons, will no longer save.
	var/list/gear_list = list()			//Custom/fluff item loadouts.
	var/gear_slot = 1					//The current gear save slot
	var/list/traits						//Traits which modifier characters for better or worse (mostly worse).
	var/synth_color	= 0					//Lets normally uncolorable synth parts be colorable.
	var/r_synth							//Used with synth_color to color synth parts that normaly can't be colored.
	var/g_synth							//Same as above
	var/b_synth							//Same as above
	var/synth_markings = 1				//Enable/disable markings on synth parts. //VOREStation Edit - 1 by default
	var/digitigrade = 0
	var/screamsound = 0					//RS ADD

		//Some faction information.
	var/home_system = "Unset"           //Current home or residence.
	var/birthplace = "Unset"           //Location of birth.
	var/citizenship = "None"            //Government or similar entity with which you hold citizenship.
	var/faction = "None"                //General associated faction.
	var/religion = "None"               //Religious association.
	var/antag_faction = "None"			//Antag associated faction.
	var/antag_vis = "Hidden"			//How visible antag association is to others.

		//Mob preview
	var/list/char_render_holders		//Should only be a key-value list of north/south/east/west = obj/screen.
	var/static/list/preview_screen_locs = list(
		"1" = "character_preview_map:2,7",
		"2" = "character_preview_map:2,5",
		"4"  = "character_preview_map:2,3",
		"8"  = "character_preview_map:2,1",
		"BG" = "character_preview_map:1,1 to 3,8",
		"PMH" = "character_preview_map:2,7"
	)

		//Jobs, uses bitflags
	var/job_civilian_high = 0
	var/job_civilian_med = 0
	var/job_civilian_low = 0

	var/job_medsci_high = 0
	var/job_medsci_med = 0
	var/job_medsci_low = 0

	var/job_engsec_high = 0
	var/job_engsec_med = 0
	var/job_engsec_low = 0

	//Keeps track of preferrence for not getting any wanted jobs
	var/alternate_option = 1

	var/used_skillpoints = 0
	var/skill_specialization = null
	var/list/skills = list() // skills can range from 0 to 3

	// maps each organ to either null(intact), "cyborg" or "amputated"
	// will probably not be able to do this for head and torso ;)
	var/list/organ_data = list()
	var/list/rlimb_data = list()
	var/list/player_alt_titles = new()		// the default name of a job like "Medical Doctor"

	var/list/body_markings = list() // "name" = "#rgbcolor" //VOREStation Edit: "name" = list(BP_HEAD = list("on" = <enabled>, "color" = "#rgbcolor"), BP_TORSO = ...)

	// RS Add Start: Custom markings support (Lira, September 2025)
	var/list/custom_markings = list() // Holds at most one entry: id = /datum/custom_marking
	var/datum/tgui_module/custom_marking_designer/custom_marking_designer_ui
	var/list/custom_marking_preview_overlays // Cached preview overlay images keyed by direction
	var/custom_marking_layer_refresh_pending = FALSE
	var/custom_markings_preview_ready = FALSE // Gate heavy preview work until lobby UI is ready (Lira, November 2025)
	var/list/custom_marking_reference_payload_cache // Cached mannequin reference payloads reused by the designer UI
	var/custom_marking_reference_signature // Signature of the mannequin cache payload currently stored
	var/custom_marking_reference_mannequin_signature // Tracks which signature is applied to the shared reference mannequin
	var/list/custom_marking_body_reference_payload_cache // Cached stripped mannequin reference payloads reused by body/basic tabs (Lira, December 2025)
	var/custom_marking_body_reference_signature // Signature of the stripped mannequin cache payload currently stored (Lira, December 2025)
	var/custom_marking_body_reference_mannequin_signature // Tracks which signature is applied to the stripped reference mannequin (Lira, December 2025)
	var/datum/custom_marking/pending_custom_marking_refresh // Queue a marking refresh until previews are ready (Lira, November 2025)
	var/pending_custom_marking_force_preview = FALSE // Force preview rebuild when deferred refresh fires (Lira, November 2025)
	var/pending_custom_marking_reset_cache = FALSE // Clear caches when deferred refresh fires (Lira, November 2025)
	var/skip_custom_marking_cache_invalidation_once = FALSE // One-shot skip for designer-driven preview updates (Lira, November 2025)
	var/datum/tgui_module/custom_marking_designer_loading/custom_marking_designer_loading_ui // Loading splash while the designer spins up (Lira, December 2025)
	var/custom_marking_ui_refresh_scheduled = FALSE // Collapse designer refreshes (Lira, December 2025)
	// RS Add End

	var/list/flavor_texts = list()
	var/list/flavour_texts_robot = list()
	var/custom_link = null

	var/list/body_descriptors = list()

	var/med_record = ""
	var/sec_record = ""
	var/gen_record = ""
	var/exploit_record = ""
	var/disabilities = 0

	var/economic_status = "Average"

	var/uplinklocation = "PDA"

	// OOC Metadata:
	var/metadata = ""
	var/metadata_likes = ""
	var/metadata_dislikes = ""
	var/list/ignored_players = list()

	var/client/client = null
	var/client_ckey = null

	// Communicator identity data
	var/communicator_visibility = 0

	var/datum/category_collection/player_setup_collection/player_setup
	var/datum/browser/panel

	var/lastnews // Hash of last seen lobby news content.
	var/lastlorenews //ID of last seen lore news article.

	var/examine_text_mode = 0 // Just examine text, include usage (description_info), switch to examine panel.
	var/multilingual_mode = 0 // Default behaviour, delimiter-key-space, delimiter-key-delimiter, off

	var/list/volume_channels = list()

	///If they are currently in the process of swapping slots, don't let them open 999 windows for it and get confused
	var/selecting_slots = FALSE

/datum/preferences/New(client/C)
	player_setup = new(src)
	set_biological_gender(pick(MALE, FEMALE))
	real_name = random_name(identifying_gender,species)
	b_type = RANDOM_BLOOD_TYPE

	gear = list()
	gear_list = list()
	gear_slot = 1
	custom_markings = list() // RS Add: Custom markings support (Lira, September 2025)

	if(istype(C))
		client = C
		client_ckey = C.ckey
		if(!IsGuestKey(C.key))
			load_path(C.ckey)
			if(load_preferences())
				load_character()

/datum/preferences/Destroy()
	. = ..()
	QDEL_LIST_ASSOC_VAL(char_render_holders)
	// RS Add Start: Clear cached custom marking references when preferences are deleted (Lira, September 2025)
	if(islist(custom_markings))
		for(var/id in custom_markings.Copy())
			remove_custom_marking(id)
	custom_markings = null
	custom_marking_preview_overlays = null
	QDEL_NULL(custom_marking_designer_ui)
	QDEL_NULL(custom_marking_designer_loading_ui)
	custom_marking_reference_payload_cache = null
	custom_marking_reference_signature = null
	custom_marking_reference_mannequin_signature = null
	custom_marking_body_reference_payload_cache = null
	custom_marking_body_reference_signature = null
	custom_marking_body_reference_mannequin_signature = null
	pending_custom_marking_refresh = null
	pending_custom_marking_force_preview = FALSE
	pending_custom_marking_reset_cache = FALSE
	// RS Add End

// RS Add Start: Custom markings support (Lira, September 2025)

// Disclaimer text for enabling custom markings (Lira, December 2025)
/datum/preferences/proc/get_custom_markings_enable_disclaimer()
	return "This is an advanced character editing tool that allows you to edit individual pixels on your character to adjust or create new markings.  Custom markings have the same standards as markings added to the RogueStar codebase.  They should make realistic sense and must be SFW.  If it wouldn't get approved to add to the code, it should not be done here.  If you are uncertain about something, please let us know and we're happy to chatter about it."

// Return custom marking
/datum/preferences/proc/get_primary_custom_marking()
	RETURN_TYPE(/datum/custom_marking)
	if(!islist(custom_markings))
		return null
	for(var/id in custom_markings)
		var/datum/custom_marking/mark = custom_markings[id]
		if(istype(mark))
			return mark
	return null

// Guarantee a custom marking exists for editing
/datum/preferences/proc/ensure_primary_custom_marking()
	var/datum/custom_marking/mark = get_primary_custom_marking()
	if(istype(mark))
		return mark
	var/owner = client_ckey || client?.ckey || "custom"
	var/id = generate_custom_marking_id(owner)
	mark = new(id, "Custom Marking", list(BP_TORSO), owner)
	mark.register()
	mark.ensure_sprite_accessory(TRUE)
	LAZYINITLIST(custom_markings)
	custom_markings[mark.id] = mark
	return mark

// Open loading window for the custom marking designer (Lira, December 2025)
/datum/preferences/proc/open_custom_marking_designer_loading(mob/user)
	if(!user)
		return
	if(custom_marking_designer_loading_ui && QDELETED(custom_marking_designer_loading_ui))
		custom_marking_designer_loading_ui = null
	if(!custom_marking_designer_loading_ui)
		custom_marking_designer_loading_ui = new(src)
	custom_marking_designer_loading_ui?.tgui_interact(user)

// Close the designer loading window (Lira, December 2025)
/datum/preferences/proc/close_custom_marking_designer_loading()
	if(!custom_marking_designer_loading_ui)
		return
	if(QDELETED(custom_marking_designer_loading_ui))
		custom_marking_designer_loading_ui = null
		return
	SStgui.close_uis(custom_marking_designer_loading_ui)
	if(custom_marking_designer_loading_ui && !QDELETED(custom_marking_designer_loading_ui))
		qdel(custom_marking_designer_loading_ui)
	custom_marking_designer_loading_ui = null

// Build the payload
/datum/preferences/proc/get_custom_markings_payload()
	var/list/out = list()
	if(!islist(custom_markings))
		return out
	var/datum/custom_marking/mark = get_primary_custom_marking()
	if(!istype(mark))
		return out
	if(!mark.owner_ckey && client_ckey)
		mark.owner_ckey = client_ckey
	out[mark.id] = mark.to_save()
	return out

// Load custom markings data
/datum/preferences/proc/load_custom_markings_from_payload(list/payload)
	reset_custom_marking_caches()
	if(islist(custom_markings))
		for(var/id in custom_markings.Copy())
			remove_custom_marking(id)
	custom_markings = list()
	if(!islist(payload))
		return
	var/loaded = FALSE
	var/datum/custom_marking/queued_mark = null
	for(var/id in payload)
		if(loaded)
			break
		var/list/data = payload[id]
		if(!islist(data))
			continue
		var/datum/custom_marking/mark = new
		mark.from_save(data)
		if(!mark.id)
			mark.id = id
		var/old_style_name = mark.get_style_name()
		var/has_legacy_entry = islist(body_markings) && old_style_name && (old_style_name in body_markings)
		var/current_owner = client_ckey || client?.ckey
		if(!mark.owner_ckey && current_owner)
			mark.owner_ckey = current_owner
		else if(mark.owner_ckey && current_owner && mark.owner_ckey != current_owner)
			// Slot copies inherit ownership so the accessor remains private to the new player
			mark.owner_ckey = current_owner
		var/owner_seed = mark.owner_ckey || current_owner
		var/id_changed = mark.reseed_identifier(owner_seed)
		if(id_changed && has_legacy_entry && islist(body_markings))
			var/new_style_name = mark.get_style_name()
			var/list/rebuilt_markings = list()
			for(var/key in body_markings)
				var/value = body_markings[key]
				if(key == old_style_name)
					rebuilt_markings[new_style_name] = value
				else
					rebuilt_markings[key] = value
			body_markings = rebuilt_markings
		mark.register()
		mark.ensure_sprite_accessory(TRUE)
		custom_markings[mark.id] = mark
		sync_loaded_custom_marking(mark)
		loaded = TRUE
		queued_mark = mark
	prune_disallowed_body_markings()
	if(queued_mark)
		defer_custom_marking_refresh(queued_mark, TRUE, TRUE)

// Centralized clearing of cached mannequin/preview state (Lira, November 2025)
/datum/preferences/proc/reset_custom_marking_caches(clear_preview_overlays = TRUE, purge_mannequins = TRUE)
	custom_marking_reference_payload_cache = null
	custom_marking_reference_signature = null
	custom_marking_reference_mannequin_signature = null
	custom_marking_body_reference_payload_cache = null
	custom_marking_body_reference_signature = null
	custom_marking_body_reference_mannequin_signature = null
	if(clear_preview_overlays)
		custom_marking_preview_overlays = null
	custom_marking_layer_refresh_pending = FALSE
	if(!purge_mannequins)
		return
	var/cache_ckey = client_ckey || client?.ckey
	if(!cache_ckey)
		return
	del_mannequin(cache_ckey)
	del_mannequin("[cache_ckey]-markref")

// Remove body marking assignments the current player shouldn't be able to use
/datum/preferences/proc/prune_disallowed_body_markings()
	if(!islist(body_markings) || !body_markings.len)
		return
	var/current_ckey = client_ckey || client?.ckey
	var/list/remove_queue = list()
	for(var/style_name in body_markings)
		if(!istext(style_name) || style_name == "color")
			continue
		var/list/mark_entry = body_markings[style_name]
		if(!islist(mark_entry))
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list?[style_name]
		if(!istype(style))
			continue
		if(style.ckeys_allowed && (!current_ckey || !(current_ckey in style.ckeys_allowed)))
			remove_queue += style_name
	if(!remove_queue.len)
		return
	for(var/key in remove_queue)
		body_markings -= key

// Apply markings
/datum/preferences/proc/apply_body_markings_to_mannequin(var/mob/living/carbon/human/mannequin)
	if(!istype(mannequin))
		return
	if(!islist(mannequin.organs_by_name))
		return
	for(var/name in mannequin.organs_by_name)
		var/obj/item/organ/external/O = mannequin.organs_by_name[name]
		if(O)
			O.markings.Cut()
	var/priority = 0
	if(!islist(body_markings) || !body_markings.len)
		mannequin.markings_len = priority
		return
	for(var/style_name in body_markings)
		if(!istext(style_name))
			continue
		var/list/style_entry = body_markings[style_name]
		if(!islist(style_entry))
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list?[style_name]
		if(!istype(style))
			continue
		priority++
		var/default_color = style_entry?["color"]
		if(!istext(default_color))
			default_color = style.do_colouration ? "#000000" : "#FFFFFF"
		for(var/BP in style.body_parts)
			var/obj/item/organ/external/O = mannequin.organs_by_name[BP]
			if(!O)
				continue
			var/list/details = islist(style_entry[BP]) ? style_entry[BP] : null
			var/part_color = default_color
			if(islist(details) && ("color" in details) && istext(details["color"]))
				part_color = details["color"]
			var/on = TRUE
			if(islist(details) && ("on" in details))
				on = !!details["on"]
			O.markings[style_name] = list("color" = part_color, "datum" = style, "priority" = priority, "on" = on)
	mannequin.markings_len = priority

// Open the editor UI targeting the specified marking id
/datum/preferences/proc/open_custom_marking_designer(mob/user, id)
	if(!user)
		return
	open_custom_marking_designer_loading(user)
	var/datum/custom_marking/mark = null
	if(id && custom_markings)
		mark = custom_markings[id]
	if(!id && !mark)
		mark = get_primary_custom_marking()
	if(id && !mark)
		close_custom_marking_designer_loading()
		return
	var/datum/tgui_module/custom_marking_designer/module = custom_marking_designer_ui
	if(module)
		if(QDELETED(module) || module.host != src)
			custom_marking_designer_ui = null
			module = null
		else if(mark && module.mark != mark)
			qdel(module)
			custom_marking_designer_ui = null
			module = null
	if(!module)
		module = new(src, mark)
		custom_marking_designer_ui = module
	module.tgui_interact(user)

// RS Add: Open the body markings gallery tab (Lira, December 2025)
/datum/preferences/proc/open_body_markings_designer(mob/user)
	if(!user)
		return
	var/datum/custom_marking/mark = get_primary_custom_marking()
	var/datum/tgui_module/custom_marking_designer/module = custom_marking_designer_ui
	if(module)
		if(QDELETED(module) || module.host != src)
			custom_marking_designer_ui = null
			module = null
		else if(mark && module.mark != mark)
			qdel(module)
			custom_marking_designer_ui = null
			module = null
	if(!module)
		module = new(src, mark, "basic", TRUE)
		custom_marking_designer_ui = module
	else
		module.initial_tab = "basic"
		module.active_tab = "basic"
		module.allow_custom_tab = !!mark
		SStgui.update_uis(module)
	module.tgui_interact(user)

// Provide a user-friendly label for a stored body marking key
/datum/preferences/proc/get_marking_display_name(marking_key)
	if(!istext(marking_key))
		return "Custom Marking Layer"
	var/datum/sprite_accessory/marking/style = body_marking_styles_list?[marking_key]
	if(istype(style))
		var/display = style.get_display_name()
		if(display)
			return display
	return marking_key

// Remove runtime registrations for an obsolete custom marking
/datum/preferences/proc/remove_custom_marking(id)
	if(!custom_markings || !(id in custom_markings))
		return
	var/datum/custom_marking/mark = custom_markings[id]
	var/style_name = mark ? mark.get_style_name() : null
	if(style_name && islist(body_markings))
		body_markings -= style_name
	if(custom_marking_designer_ui && !QDELETED(custom_marking_designer_ui))
		if(custom_marking_designer_ui.mark?.id == id)
			qdel(custom_marking_designer_ui)
			custom_marking_designer_ui = null
	custom_markings -= id
	unregister_custom_marking_style(id)
	GLOB.custom_markings_by_id -= id

// Close designer
/datum/preferences/proc/close_custom_marking_designer()
	if(!custom_marking_designer_ui)
		return
	if(QDELETED(custom_marking_designer_ui))
		custom_marking_designer_ui = null
		return
	SStgui.close_uis(custom_marking_designer_ui)
	if(custom_marking_designer_ui && !QDELETED(custom_marking_designer_ui))
		qdel(custom_marking_designer_ui)
	custom_marking_designer_ui = null
	close_custom_marking_designer_loading()

// Allow reopening the designer cleanly after cache resets (Lira, November 2025)
/datum/preferences/proc/restart_custom_marking_designer(mob/user, id)
	if(!user && client)
		user = client.mob
	close_custom_marking_designer()
	open_custom_marking_designer(user, id)

// Debounce designer refreshes so bursty wardrobe changes only trigger one update
/datum/preferences/proc/queue_custom_marking_designer_refresh()
	if(custom_marking_ui_refresh_scheduled)
		return
	custom_marking_ui_refresh_scheduled = TRUE
	addtimer(CALLBACK(src, .proc/flush_custom_marking_designer_refresh), 1)

// Clear refresh schedule (Lira, December 2025)
/datum/preferences/proc/flush_custom_marking_designer_refresh()
	custom_marking_ui_refresh_scheduled = FALSE
	if(custom_marking_designer_ui && QDELETED(custom_marking_designer_ui))
		custom_marking_designer_ui = null
	if(custom_marking_designer_ui)
		custom_marking_designer_ui.preview_revision++
		custom_marking_designer_ui.preview_refresh_token++
		SStgui.update_uis(custom_marking_designer_ui)

// Ensure saved custom markings keep their preference entry when loading slots
/datum/preferences/proc/sync_loaded_custom_marking(datum/custom_marking/mark)
	if(!istype(mark))
		return
	var/style_name = mark.get_style_name()
	if(!istext(style_name) || !length(style_name))
		return
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory(TRUE)
	if(!istype(style))
		return
	LAZYINITLIST(body_markings)
	var/list/current = islist(body_markings) ? body_markings[style_name] : null
	if(!islist(current))
		current = mass_edit_marking_list(style_name)
		if(!islist(current))
			current = list()
		body_markings[style_name] = current
	var/default_color = current["color"]
	if(!istext(default_color))
		default_color = style.do_colouration ? "#000000" : "#FFFFFF"
	current["color"] = default_color
	var/list/desired_parts = mark.body_parts?.Copy()
	if(!islist(desired_parts) || !desired_parts.len)
		desired_parts = list()
	for(var/part in desired_parts)
		var/list/details = current[part]
		if(!islist(details))
			details = list("on" = TRUE, "color" = default_color)
		else if(!istext(details["color"]))
			details["color"] = default_color
		details["datum"] = style
		current[part] = details
	var/list/remove_queue = list()
	for(var/existing in current)
		if(existing == "color" || existing == "datum")
			continue
		if(!(existing in desired_parts))
			remove_queue += existing
	for(var/existing in remove_queue)
		current -= existing
	current["datum"] = style
	if(islist(body_markings))
		var/list/custom_cleanup = list()
		for(var/key in body_markings)
			if(!istext(key) || key == "color" || key == style_name)
				continue
			var/datum/sprite_accessory/marking/entry_style = body_marking_styles_list?[key]
			if(!istype(entry_style))
				entry_style = body_markings[key]?["datum"]
			var/is_custom = istype(entry_style, /datum/sprite_accessory/marking/custom)
			if(!is_custom && findtext(key, " (Custom "))
				is_custom = TRUE
			if(is_custom)
				custom_cleanup += key
		for(var/key in custom_cleanup)
			body_markings -= key

// Allow queueing heavy marking refreshes through SScustom_marking (Lira, November 2025)
/datum/preferences/proc/refresh_custom_marking_assets(force_preview = TRUE, reset_cache = FALSE, datum/custom_marking/target_mark = null, use_queue = FALSE)
	if(use_queue && SScustom_marking)
		var/datum/callback/cb = CALLBACK(src, PROC_REF(_process_refresh_custom_marking_assets), force_preview, reset_cache, target_mark)
		if(SScustom_marking.queue_callback(cb))
			return
		var/log_ckey = client_ckey || client?.ckey || "unknown"
		var/fallback_mark = target_mark?.id || get_primary_custom_marking()?.id
		log_debug("CustomMarkings: Queue rejected for [log_ckey], running inline (mark=[fallback_mark])")
		qdel(cb)
	_process_refresh_custom_marking_assets(force_preview, reset_cache, target_mark)

// Support queued refreshes and cleaned preview overlays
/datum/preferences/proc/_process_refresh_custom_marking_assets(force_preview = TRUE, reset_cache = FALSE, datum/custom_marking/target_mark = null)
	if(QDELETED(src))
		return
	var/datum/custom_marking/mark = target_mark
	if(!istype(mark))
		mark = get_primary_custom_marking()
	if(!istype(mark))
		return
	if(QDELETED(mark))
		return
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory(TRUE)
	if(!style)
		return
	if(reset_cache)
		style.invalidate_cache()
	style.regenerate_if_needed()
	if(force_preview)
		var/has_pixels = style.source?.has_visible_pixels()
		if(islist(char_render_holders) && char_render_holders.len && custom_marking_preview_overlays && custom_marking_preview_overlays.len)
			for(var/key in custom_marking_preview_overlays)
				var/list/existing = custom_marking_preview_overlays[key]
				if(!islist(existing))
					continue
				var/obj/screen/setup_preview/holder = char_render_holders?[key]
				if(!holder)
					continue
				var/mutable_appearance/MA = holder.appearance ? new /mutable_appearance(holder.appearance) : new /mutable_appearance(holder)
				for(var/image/old_overlay in existing)
					if(old_overlay)
						MA.overlays -= old_overlay
				holder.appearance = MA
			custom_marking_preview_overlays = null
		if(!has_pixels)
			schedule_custom_marking_layer_refresh()
			return
		update_preview_icon(TRUE)

// Queue marking refresh when UI isn’t ready (Lira, November 2025)
/datum/preferences/proc/defer_custom_marking_refresh(datum/custom_marking/mark_to_refresh, force_preview = TRUE, reset_cache = FALSE)
	if(!istype(mark_to_refresh))
		return
	pending_custom_marking_refresh = mark_to_refresh
	pending_custom_marking_force_preview = force_preview
	pending_custom_marking_reset_cache = reset_cache
	if(custom_markings_preview_ready)
		process_pending_custom_marking_refresh()

// Drain deferred marking refresh once previews can render (Lira, November 2025)
/datum/preferences/proc/process_pending_custom_marking_refresh()
	if(!pending_custom_marking_refresh)
		return
	var/datum/custom_marking/target = pending_custom_marking_refresh
	var/force_preview = pending_custom_marking_force_preview || custom_markings_preview_ready
	var/reset_cache = pending_custom_marking_reset_cache
	pending_custom_marking_refresh = null
	pending_custom_marking_force_preview = FALSE
	pending_custom_marking_reset_cache = FALSE
	if(!istype(target) || QDELETED(target))
		return
	var/use_queue = !!SScustom_marking
	var/list/context = null
	if(!use_queue)
		context = custom_marking_begin_manual_yield()
	refresh_custom_marking_assets(force_preview, reset_cache, target, use_queue)
	if(context)
		custom_marking_end_manual_yield(context)

// Mark previews dirty and defer rendering to mannequin refresh
/datum/preferences/proc/apply_custom_marking_preview(datum/sprite_accessory/marking/custom/style)
	if(!style)
		return FALSE
	if(!islist(char_render_holders) || !char_render_holders.len)
		return FALSE
	if(!isicon(style.icon))
		return FALSE
	schedule_custom_marking_layer_refresh()
	return TRUE

// Always rebuild mannequin overlays asynchronously for custom markings
/datum/preferences/proc/schedule_custom_marking_layer_refresh()
	if(custom_marking_layer_refresh_pending)
		return
	custom_marking_layer_refresh_pending = TRUE
	INVOKE_ASYNC(src, /datum/preferences/proc/run_custom_marking_layer_refresh)

// Simplify mannequin refresh to rely on cached overlays
/datum/preferences/proc/run_custom_marking_layer_refresh()
	if(QDELETED(src))
		custom_marking_layer_refresh_pending = FALSE
		return
	custom_marking_layer_refresh_pending = FALSE
	var/mob/living/carbon/human/dummy/mannequin/mannequin = get_mannequin(client_ckey)
	if(!istype(mannequin))
		return
	if(!mannequin.dna)
		mannequin.dna = new /datum/dna(null)
	apply_body_markings_to_mannequin(mannequin)
	mannequin.update_icons_body()
	mannequin.update_skin()
	mannequin.update_mutations()
	mannequin.update_underwear()
	mannequin.update_hair()
	mannequin.update_tail_showing()
	mannequin.update_wing_showing()
	mannequin.update_transform(TRUE)
	mannequin.ImmediateOverlayUpdate()
	custom_marking_preview_overlays = null
	update_character_previews(new /mutable_appearance(mannequin))

// RS Add End

/datum/preferences/proc/ZeroSkills(var/forced = 0)
	for(var/V in SKILLS) for(var/datum/skill/S in SKILLS[V])
		if(!skills.Find(S.ID) || forced)
			skills[S.ID] = SKILL_NONE

/datum/preferences/proc/CalculateSkillPoints()
	used_skillpoints = 0
	for(var/V in SKILLS) for(var/datum/skill/S in SKILLS[V])
		var/multiplier = 1
		switch(skills[S.ID])
			if(SKILL_NONE)
				used_skillpoints += 0 * multiplier
			if(SKILL_BASIC)
				used_skillpoints += 1 * multiplier
			if(SKILL_ADEPT)
				// secondary skills cost less
				if(S.secondary)
					used_skillpoints += 1 * multiplier
				else
					used_skillpoints += 3 * multiplier
			if(SKILL_EXPERT)
				// secondary skills cost less
				if(S.secondary)
					used_skillpoints += 3 * multiplier
				else
					used_skillpoints += 6 * multiplier

/datum/preferences/proc/GetSkillClass(points)
	return CalculateSkillClass(points, age)

/proc/CalculateSkillClass(points, age)
	if(points <= 0) return "Unconfigured"
	// skill classes describe how your character compares in total points
	points -= min(round((age - 20) / 2.5), 4) // every 2.5 years after 20, one extra skillpoint
	if(age > 30)
		points -= round((age - 30) / 5) // every 5 years after 30, one extra skillpoint
	switch(points)
		if(-1000 to 3)
			return "Terrifying"
		if(4 to 6)
			return "Below Average"
		if(7 to 10)
			return "Average"
		if(11 to 14)
			return "Above Average"
		if(15 to 18)
			return "Exceptional"
		if(19 to 24)
			return "Genius"
		if(24 to 1000)
			return "God"

/datum/preferences/proc/ShowChoices(mob/user)
	if(!user || !user.client)	return

	if(!get_mob_by_key(client_ckey))
		to_chat(user, "<span class='danger'>No mob exists for the given client!</span>")
		return

	custom_markings_preview_ready = TRUE // RS Add: Custom markings supprt (Lira, November 2025)
	process_pending_custom_marking_refresh() // RS Add: Custom markings supprt (Lira, November 2025)
	if(!char_render_holders)
		update_preview_icon(TRUE) // RS Edit: Custom markings supprt (Lira, September 2025)
	show_character_previews()

	var/dat = "<html><body><center>"

	if(path)
		dat += "Slot - "
		dat += "<a href='?src=\ref[src];load=1'>Load slot</a> - "
		dat += "<a href='?src=\ref[src];save=1'>Save slot</a> - "
		dat += "<a href='?src=\ref[src];reload=1'>Reload slot</a> - "
		dat += "<a href='?src=\ref[src];resetslot=1'>Reset slot</a> - "
		dat += "<a href='?src=\ref[src];copy=1'>Copy slot</a>"

	else
		dat += "Please create an account to save your preferences."

	dat += "<br>"
	dat += player_setup.header()
	dat += "<br><HR></center>"
	dat += player_setup.content(user)

	dat += "</html></body>"
	//user << browse(dat, "window=preferences;size=635x736")
	winshow(user, "preferences_window", TRUE)
	var/datum/browser/popup = new(user, "preferences_browser", "Character Setup", 800, 800)
	popup.set_content(dat)
	popup.open(FALSE) // Skip registring onclose on the browser pane
	onclose(user, "preferences_window", src) // We want to register on the window itself

/datum/preferences/proc/update_character_previews(mutable_appearance/MA)
	if(!client)
		return

	var/obj/screen/setup_preview/pm_helper/PMH = LAZYACCESS(char_render_holders, "PMH")
	if(!PMH)
		PMH = new
		LAZYSET(char_render_holders, "PMH", PMH)
		client.screen |= PMH
	PMH.screen_loc = preview_screen_locs["PMH"]

	var/obj/screen/setup_preview/bg/BG = LAZYACCESS(char_render_holders, "BG")
	if(!BG)
		BG = new
		BG.plane = TURF_PLANE
		BG.icon = 'icons/effects/setup_backgrounds_vr.dmi'
		BG.pref = src
		LAZYSET(char_render_holders, "BG", BG)
		client.screen |= BG
	BG.icon_state = bgstate
	BG.screen_loc = preview_screen_locs["BG"]

	for(var/D in global.cardinal)
		var/obj/screen/setup_preview/O = LAZYACCESS(char_render_holders, "[D]")
		if(!O)
			O = new
			O.pref = src
			LAZYSET(char_render_holders, "[D]", O)
			client.screen |= O
		O.appearance = MA
		O.dir = D
		O.screen_loc = preview_screen_locs["[D]"]

/datum/preferences/proc/show_character_previews()
	if(!client || !char_render_holders)
		return
	for(var/render_holder in char_render_holders)
		client.screen |= char_render_holders[render_holder]

/datum/preferences/proc/clear_character_previews()
	for(var/index in char_render_holders)
		var/obj/screen/S = char_render_holders[index]
		client?.screen -= S
		qdel(S)
	char_render_holders = null

/datum/preferences/proc/process_link(mob/user, list/href_list)
	if(!user)	return

	if(!istype(user, /mob/new_player))	return

	if(href_list["preference"] == "open_whitelist_forum")
		if(config.forumurl)
			user << link(config.forumurl)
		else
			to_chat(user, "<span class='danger'>The forum URL is not set in the server configuration.</span>")
			return
	ShowChoices(usr)
	return 1

/datum/preferences/Topic(href, list/href_list)
	if(..())
		return 1

	if(href_list["save"])
		save_preferences()
		save_character()
	else if(href_list["reload"])
		// RS Add Start: Prevent reload spam (Lira, November 2025)
		if(world.time < next_charsetup_reload)
			to_chat(usr, "<span class='warning'>You can't reload a character slot more than once within [CHARSETUP_RELOAD_DELAY_SECONDS] seconds.</span>")
			log_debug("[key_name(usr)] hit the Character Setup reload guard.")
		else
			next_charsetup_reload = world.time + CHARSETUP_RELOAD_DELAY
		// RS Add End
			load_preferences()
			load_character()
			attempt_vr(client.prefs_vr,"load_vore","") //VOREStation Edit
			sanitize_preferences()
	else if(href_list["load"])
		if(!IsGuestKey(usr.key))
			open_load_dialog(usr)
			return 1
	else if(href_list["resetslot"])
		if("No" == tgui_alert(usr, "This will reset the current slot. Continue?", "Reset current slot?", list("No", "Yes")))
			return 0
		if("No" == tgui_alert(usr, "Are you completely sure that you want to reset this character slot?", "Reset current slot?", list("No", "Yes")))
			return 0
		load_character(SAVE_RESET)
		sanitize_preferences()
	else if(href_list["copy"])
		if(!IsGuestKey(usr.key))
			open_copy_dialog(usr)
			return 1
	else if(href_list["close"])
		// User closed preferences window, cleanup anything we need to.
		clear_character_previews()
		return 1
	else
		return 0

	ShowChoices(usr)
	return 1

// RS Add: Custom markings support (Lira, September 2025)
/datum/preferences/proc/build_trait_signature(list/traits)
	var/list/out = list()
	if(!islist(traits) || !traits.len)
		return out
	for(var/trait_key in traits)
		var/value = traits[trait_key]
		var/value_repr = islist(value) ? json_encode(value) : "[value]"
		out += "[trait_key]=[value_repr]"
	return sortList(out)

// RS Add: Custom markings support (Lira, September 2025)
/datum/preferences/proc/get_custom_trait_signature()
	if(species != SPECIES_CUSTOM)
		return null
	var/list/data = list(
		"base" = custom_base || "",
		"species" = custom_species || ""
	)
	data["pos"] = build_trait_signature(pos_traits)
	data["neu"] = build_trait_signature(neu_traits)
	data["neg"] = build_trait_signature(neg_traits)
	return md5(json_encode(data))

/datum/preferences/proc/copy_to(mob/living/carbon/human/character, icon_updates = TRUE, fast_preview = FALSE) //RS Edit: Custom markings support (Lira, September 2025)
	// Sanitizing rather than saving as someone might still be editing when copy_to occurs.
	player_setup.sanitize_setup()

	// This needs to happen before anything else becuase it sets some variables.
	// RS Add Start: Custom markings support (Lira, September 2025)
	if(fast_preview)
		character.preview_fast = TRUE
	else
		character.preview_fast = FALSE
		character.preview_trait_signature = null
	var/needs_species_update = TRUE
	if(fast_preview && character.species)
		if(character.species.name == species)
			needs_species_update = FALSE
			// Rebuild organs to stop sticky prosthetics and amputations (Lira, October 2025)
			character.species.create_organs(character)
	if(needs_species_update)
	// RS Add End
		character.set_species(species, null, TRUE, null, fast_preview) // RS Edit: Custom markings support (Lira, September 2025)
	// Special Case: This references variables owned by two different datums, so do it here.
	if(be_random_name)
		real_name = random_name(identifying_gender,species)

	// Ask the preferences datums to apply their own settings to the new mob
	player_setup.copy_to_mob(character)

	// VOREStation Edit - Sync up all their organs and species one final time
	character.force_update_organs()

	if(icon_updates)
		character.force_update_limbs()
		character.update_icons_body()
		character.update_mutations()
		character.update_underwear()
		character.update_hair()

	if(LAZYLEN(character.descriptors))
		for(var/entry in body_descriptors)
			character.descriptors[entry] = body_descriptors[entry]

/datum/preferences/proc/open_load_dialog(mob/user)
	if(selecting_slots)
		to_chat(user, "<span class='warning'>You already have a slot selection dialog open!</span>")
		return
	var/savefile/S = new /savefile(path)
	if(!S)
		error("Somehow missing savefile path?! [path]")
		return

	var/name
	var/nickname //vorestation edit - This set appends nicknames to the save slot
	var/list/charlist = list()
	var/default //VOREStation edit
	for(var/i=1, i<= config.character_slots, i++)
		S.cd = "/character[i]"
		S["real_name"] >> name
		S["nickname"] >> nickname //vorestation edit
		if(!name)
			name = "[i] - \[Unused Slot\]"
		else if(i == default_slot)
			name = "►[i] - [name]"
		else
			name = "[i] - [name]"
		if (i == default_slot) //VOREStation edit
			default = "[name][nickname ? " ([nickname])" : ""]"
		charlist["[name][nickname ? " ([nickname])" : ""]"] = i

	selecting_slots = TRUE
	var/choice = tgui_input_list(user, "Select a character to load:", "Load Slot", charlist, default)
	selecting_slots = FALSE
	if(!choice)
		return

	var/slotnum = charlist[choice]
	if(!slotnum)
		error("Player picked [choice] slot to load, but that wasn't one we sent.")
		return

	load_character(slotnum)
	attempt_vr(user.client?.prefs_vr,"load_vore","") //VOREStation Edit
	sanitize_preferences()
	ShowChoices(user)

/datum/preferences/proc/open_copy_dialog(mob/user)
	if(selecting_slots)
		to_chat(user, "<span class='warning'>You already have a slot selection dialog open!</span>")
		return
	var/savefile/S = new /savefile(path)
	if(!S)
		error("Somehow missing savefile path?! [path]")
		return

	var/name
	var/nickname //vorestation edit - This set appends nicknames to the save slot
	var/list/charlist = list()
	for(var/i=1, i<= config.character_slots, i++)
		S.cd = "/character[i]"
		S["real_name"] >> name
		S["nickname"] >> nickname //vorestation edit
		if(!name)
			name = "[i] - \[Unused Slot\]"
		if(i == default_slot)
			name = "►[i] - [name]"
		else
			name = "[i] - [name]"
		charlist["[name][nickname ? " ([nickname])" : ""]"] = i

	selecting_slots = TRUE
	var/choice = tgui_input_list(user, "Select a character to COPY TO:", "Copy Slot", charlist)
	selecting_slots = FALSE
	if(!choice)
		return

	var/slotnum = charlist[choice]
	if(!slotnum)
		error("Player picked [choice] slot to copy to, but that wasn't one we sent.")
		return

	overwrite_character(slotnum)
	sanitize_preferences()
	ShowChoices(user)
