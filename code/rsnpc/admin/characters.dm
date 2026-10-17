GLOBAL_LIST_EMPTY(npc_characters)
GLOBAL_VAR_INIT(npc_characters_loaded, FALSE)
GLOBAL_VAR_INIT(npc_character_problems, 0)

/datum/npc_character
	var/id
	var/path
	var/job
	var/alt_title
	var/name
	var/list/body
	var/list/personality = list()
	var/list/numbers = list()
	var/list/say = list()
	var/list/vore = list()
	var/list/bellies

/proc/npc_characters()
	if(!GLOB.npc_characters_loaded)
		GLOB.npc_characters_loaded = TRUE
		npc_load_characters()
	return GLOB.npc_characters

/proc/npc_load_characters()
	for(var/file in flist(NPC_CHARACTER_DIR))
		if(copytext(file, -5) != ".json")
			continue
		var/path = "[NPC_CHARACTER_DIR][file]"
		var/list/data = npc_read_json(path)
		if(!data)
			GLOB.npc_character_problems++
			continue
		if(!("job" in data) && !("body" in data))
			continue
		var/datum/npc_character/C = npc_read_character(copytext(file, 1, -5), path, data)
		if(C)
			GLOB.npc_characters[C.id] = C
		else
			GLOB.npc_character_problems++

/proc/npc_read_character(id, path, list/data)
	var/datum/npc_character/C = new
	C.id = id
	C.path = path
	var/datum/job/J = istext(data["job"]) && find_npc_job(data["job"])
	if(!J)
		log_npc_config(path, "\"job\" is not a job or job title this round has; not loaded.")
		return null
	C.job = J.title
	if(data["job"] != J.title)
		C.alt_title = data["job"]
	C.body = npc_read_body(path, data["body"])
	if(!C.body)
		return null
	var/list/identity = C.body["identity"]
	C.name = (islist(identity) && istext(identity["real_name"])) ? identity["real_name"] : id
	for(var/key in data)
		if(copytext(key, 1, 2) == "_" || (key in list("job", "body", "appearance", "temperament", "traits")))
			continue
		var/value = data[key]
		switch(key)
			if("personality")
				C.personality = npc_read_personality(path, value)
			if("speech")
				C.say = npc_read_speech(path, value)
			if("vore")
				C.vore = npc_read_vore(path, value)
			if("bellies")
				C.bellies = npc_read_bellies(path, value)
			if("name", "species", "gender", "languages", "flavor", "flavour", "ooc_notes", "ooc_notes_likes", "ooc_notes_dislikes", "custom_link", "autohiss")
				log_npc_config(path, "\"[key]\" comes from the body file; ignored.")
			else
				if(!(key in GLOB.npc_setting_defaults))
					log_npc_config(path, "\"[key]\" is not a setting; ignored.")
				else if(isnum(GLOB.npc_setting_defaults[key]) && !isnum(value))
					log_npc_config(path, "setting \"[key]\" is not a number; ignored.")
				else
					C.numbers[key] = value
	return C

/proc/find_npc_job(title)
	. = SSjob.get_job(title)
	if(.)
		return
	for(var/datum/job/J as anything in SSjob.occupations)
		if(J.alt_titles && (title in J.alt_titles))
			return J

/proc/npc_read_body(path, list/body)
	var/list/data = body
	if(istext(body))
		data = npc_read_json("[NPC_CHARACTER_DIR][body]")
		if(!data)
			log_npc_config(path, "body file [body] could not be read; not loaded.")
			return null
	if(!islist(data) || data["format"] != "rogue-star-character" || !islist(data["character"]) || !islist(data["character"]["species"]))
		log_npc_config(path, "\"body\" is not a character designer export; not loaded.")
		return null
	return data["character"]

/proc/npc_read_personality(path, list/words)
	. = list()
	if(!islist(words))
		log_npc_config(path, "\"personality\" is not a list; ignored.")
		return
	for(var/word in words)
		if(!istext(word) || !(word in GLOB.npc_personalities))
			log_npc_config(path, "\"[word]\" is not a personality word; ignored.")
			continue
		var/datum/npc_personality/P = GLOB.npc_personalities[word]
		if(P.opposite in .)
			log_npc_config(path, "\"[word]\" is the opposite of \"[P.opposite]\"; ignored.")
			continue
		. |= word

/proc/npc_read_speech(path, list/speech)
	. = list()
	if(!islist(speech))
		log_npc_config(path, "\"speech\" is not an object; ignored.")
		return
	for(var/part in speech)
		if(part != "say")
			log_npc_config(path, "speech \"[part]\" is not read; ignored.")
	var/list/groups = speech["say"]
	if(!islist(groups))
		return
	for(var/group in groups)
		if(!(group in GLOB.npc_say_lines))
			log_npc_config(path, "say group \"[group]\" is not a line group; ignored.")
			continue
		var/list/lines = groups[group]
		if(!islist(lines))
			log_npc_config(path, "say group \"[group]\" is not a list; ignored.")
			continue
		var/list/good = list()
		for(var/line in lines)
			if(!istext(line))
				log_npc_config(path, "say group \"[group]\" has a line that is not text; dropped.")
				continue
			var/why = npc_line_fault(line, group)
			if(why)
				log_npc_config(path, "line '[line]' [why]; dropped.")
				continue
			good += line
		if(length(good))
			.[group] = good

/proc/npc_read_vore(path, list/vore)
	. = list()
	if(!islist(vore))
		log_npc_config(path, "\"vore\" is not an object; ignored.")
		return
	var/datum/vore_preferences/V = new
	for(var/key in vore)
		var/value = vore[key]
		if(!(key in V.vars) || (key in list("path", "slot", "client", "client_ckey", "belly_prefs", "vore_whitelist_toggles")))
			log_npc_config(path, "vore \"[key]\" is not a vore preference; ignored.")
			continue
		var/default = V.vars[key]
		if((isnum(default) && !isnum(value)) || (istext(default) && !istext(value)) || (islist(default) && !islist(value)))
			log_npc_config(path, "vore \"[key]\" has the wrong kind of value; ignored.")
			continue
		.[key] = value
	qdel(V)

/proc/npc_read_bellies(path, list/bellies)
	if(islist(bellies))
		return bellies
	if(!istext(bellies))
		log_npc_config(path, "\"bellies\" is neither bellies nor a file name; ignored.")
		return null
	var/list/data = npc_read_json("[NPC_CHARACTER_DIR][bellies]")
	if(!data)
		log_npc_config(path, "belly file [bellies] could not be read; no bellies.")
	return data

/mob/living/carbon/human/ai_controlled/rsnpc/station/proc/npc_vore_from(datum/npc_character/C)
	for(var/key in C.vore)
		if(!(key in vars))
			log_npc_config(C.path, "vore \"[key]\" does not apply to a body; ignored.")
			continue
		vars[key] = C.vore[key]
	if(!C.bellies)
		return
	var/list/found = vore_belly_lists_from(src, C.bellies, FALSE, null)
	if(!islist(found))
		log_npc_config(C.path, "\"bellies\" has none the game can use; no bellies.")
		return
	vore_apply_belly_data(src, found["lists"], null, found["allownpcvore"])
	if(LAZYLEN(vore_organs))
		vore_selected = vore_organs[1]
		bellies_loaded = TRUE

/mob/living/carbon/human/ai_controlled/rsnpc/station/proc/npc_body_from(datum/npc_character/C)
	var/list/body = C.body
	var/datum/preferences/P = new
	var/datum/tgui_module/custom_marking_designer/D = new(P, null, "body", TRUE)
	var/list/species = body["species"]
	if(!(species["species"] in GLOB.all_species))
		log_npc_config(C.path, "body species \"[species["species"]]\" is not a species; left as [P.species].")
	else
		P.species = species["species"]
		if(istext(species["icon_base"]))
			P.custom_base = species["icon_base"]
		if(istext(species["custom_species"]))
			P.custom_species = species["custom_species"]
		P.sanitize_body_styles()
	var/list/appearance = body["appearance"]
	if(islist(appearance))
		var/list/params = appearance.Copy()
		for(var/key in list("ear_colors", "tail_colors", "wing_colors"))
			var/list/colors = params[key]
			if(islist(colors) && length(colors) < 3)
				colors = colors.Copy()
				colors.len = 3
				params[key] = colors
		if(!D.apply_basic_appearance_payload(params))
			log_npc_config(C.path, "body looks were refused; left as default.")
		if(isnum(appearance["skin_tone"]))
			P.s_tone = appearance["skin_tone"]
		npc_limbs_from(C, P, appearance["limbs"])
	var/list/markings = body["body_markings"]
	if(islist(markings) && !D.apply_body_marking_payload(markings))
		log_npc_config(C.path, "body markings were refused; left out.")
	if(islist(body["custom_markings"]))
		npc_drawn_marking(P, body["custom_markings"])
	var/list/traits = body["traits"]
	if(islist(traits))
		if(islist(traits["selected_traits"]))
			var/list/params = traits.Copy()
			params -= "languages"
			params["revision"] = D.traits_revision
			var/list/why = list()
			if(!D.apply_character_traits_payload(params, why))
				log_npc_config(C.path, "body traits were refused: [jointext(why, "; ")]")
		npc_languages_from(P, traits["languages"])
	var/list/identity = body["identity"]
	if(islist(identity))
		var/list/params = D.build_identity_payload(null)
		for(var/key in identity)
			params[key] = identity[key]
		params["revision"] = D.identity_revision
		var/list/why = list()
		if(!D.apply_identity_payload(params, why))
			log_npc_config(C.path, "body identity was refused: [jointext(why, "; ")]")
	var/list/equipment = body["equipment"]
	if(islist(equipment))
		D.apply_equipment_values(equipment)
	var/list/loadout = body["loadout"]
	var/list/slots = islist(loadout) && loadout["slots"]
	if(islist(slots))
		P.gear = list()
		var/list/items = slots["[loadout["active"]]"]
		for(var/list/item in items)
			if(!gear_datums[item["id"]])
				log_npc_config(C.path, "loadout item \"[item["id"]]\" is not an item; left out.")
				continue
			P.gear[item["id"]] = islist(item["tweaks"]) ? item["tweaks"] : list()
	P.be_random_name = FALSE
	P.resleeve_scan = FALSE
	P.reconcile_languages_for_species()
	qdel(D)
	P.copy_to(src)
	name = real_name
	dna.ready_dna(src)
	dna.b_type = P.b_type
	sync_organ_dna()
	for(var/lang in P.alternate_languages)
		if(GLOB.all_languages[lang])
			add_language(lang)
	for(var/key in P.language_custom_keys)
		var/datum/language/L = GLOB.all_languages[P.language_custom_keys[key]]
		if(L)
			language_keys[key] = L
	if(GLOB.all_languages[P.preferred_language])
		default_language = GLOB.all_languages[P.preferred_language]
	force_update_limbs()
	update_icons_body()
	update_transform()
	npc_prefs = P

/mob/living/carbon/human/ai_controlled/rsnpc/station/proc/npc_limbs_from(datum/npc_character/C, datum/preferences/P, list/limbs)
	if(!islist(limbs))
		return
	var/list/external = limbs["external"]
	if(islist(external))
		for(var/part in list(BP_TORSO, BP_GROIN, BP_L_LEG, BP_R_LEG, BP_L_ARM, BP_R_ARM, BP_L_FOOT, BP_R_FOOT, BP_L_HAND, BP_R_HAND, BP_HEAD))
			var/list/limb = external[part]
			if(!islist(limb))
				continue
			var/done = TRUE
			if(limb["status"] == "cyborg")
				done = P.apply_chargen_limb_operation(part, "prosthesis", limb["model"])
			else if(limb["status"] == "amputated")
				done = P.apply_chargen_limb_operation(part, "amputated")
			if(!done)
				log_npc_config(C.path, "body [part] could not be made [limb["status"]][limb["model"] ? " ([limb["model"]])" : ""]; left as it was.")
	var/list/internal = limbs["internal"]
	if(islist(internal))
		for(var/organ in internal)
			var/list/entry = internal[organ]
			if(!islist(entry) || (entry["status"] in list(null, "normal", "native")))
				continue
			if(!P.apply_chargen_internal_organ_operation(organ, entry["status"]))
				log_npc_config(C.path, "body [organ] could not be made [entry["status"]]; left as it was.")

/proc/npc_languages_from(datum/preferences/P, list/languages)
	if(!islist(languages))
		return
	if(islist(languages["alternate_languages"]))
		P.alternate_languages = list()
		for(var/lang in languages["alternate_languages"])
			if(istext(lang))
				P.alternate_languages += lang
	if(istext(languages["preferred_language"]))
		P.preferred_language = languages["preferred_language"]
	var/list/keys = languages["custom_keys"]
	if(islist(keys))
		P.language_custom_keys = list()
		for(var/lang in keys)
			if(istext(keys[lang]) && character_language_custom_key_is_valid(keys[lang]))
				P.language_custom_keys[keys[lang]] = lang
	var/list/prefixes = languages["language_prefixes"]
	if(islist(prefixes))
		P.language_prefixes = list()
		for(var/prefix in prefixes)
			if(istext(prefix) && character_language_prefix_is_valid(prefix))
				P.language_prefixes += prefix

/proc/npc_drawn_marking(datum/preferences/P, list/drawn)
	var/list/large = islist(drawn["part_canvas_size"]) ? drawn["part_canvas_size"] : list()
	var/width = isnum(drawn["width"]) ? drawn["width"] : 32
	var/height = isnum(drawn["height"]) ? drawn["height"] : 32
	var/base_width = width
	var/base_height = height
	for(var/part in large)
		if(large[part])
			base_width = 32
			base_height = 32
	var/list/frames = list()
	var/list/grids = drawn["frames"]
	if(!islist(grids))
		return FALSE
	for(var/key in grids)
		var/list/grid = grids[key]
		var/list/bits = splittext(key, "|")
		if(!islist(grid) || length(bits) < 2)
			continue
		var/list/columns = list()
		for(var/x in 1 to width)
			var/list/column = list()
			column.len = height
			var/list/source = x <= length(grid) ? grid[x] : null
			for(var/y in 1 to height)
				var/row = height - y + 1
				var/pixel = (islist(source) && row <= length(source)) ? source[row] : null
				if(istext(pixel) && pixel != "#00000000")
					column[y] = pixel
			columns += list(column)
		var/datum/custom_marking_frame/F = new(width, height)
		F.layers = list(columns)
		if(!large[bits[2]])
			F.resize(base_width, base_height)
		frames[key] = F.to_save()
	var/list/data = list(
		"id" = drawn["id"],
		"name" = drawn["name"],
		"body_parts" = drawn["body_parts"],
		"options" = list("replace_parts" = drawn["part_replacements"], "render_priority_parts" = drawn["part_render_priority"], "large_canvas_parts" = large),
		"width" = base_width,
		"height" = base_height,
		"frames" = frames,
	)
	P.load_custom_markings_from_payload(list("[drawn["id"]]" = data))
	return length(P.custom_markings) > 0
