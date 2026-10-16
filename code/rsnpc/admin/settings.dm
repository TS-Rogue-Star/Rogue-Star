GLOBAL_LIST_INIT(npc_setting_defaults, list(
	"trace_all" = 0,
	"path_person_cost" = 15,
	"path_person_range" = 8,
	"rest_start" = 70,
	"rest_setpoint" = 70,
	"rest_loss_per_minute" = 1.4,
	"rest_gain_per_minute" = 30,
	"break_seconds" = 90,
	"hunger_setpoint" = 150,
	"starving_threshold" = 0.5,
	"boredom_per_task" = 1,
	"typing_seconds_per_word" = 0.5,
	"emote_reply_seconds" = 12,
	"social_floor" = -20,
	"opinion_liked_at" = 30,
	"opinion_disliked_at" = -30,
	"opinion_loved_at" = 60,
	"opinion_hated_at" = -60,
	"opinion_loss_scale" = 1,
	"delivered" = 15,
	"failed_to_deliver" = 10,
	"attacked_opinion" = 20,
	"manhandle_shoves" = 3,
	"manhandle_remembered_seconds" = 45,
	"protest_delay_seconds" = 8,
	"stuck_before_call" = 4,
	"call_interlude" = 30,
	"attack_call_interlude" = 20,
	"remember_attacker_time" = 20,
	"flee_health" = 0.35,
	"panic_damage" = 20,
	"medic_call_threshold" = 0.75,
	"witness_range" = 7,
	"witness_speech_gap" = 30,
	"witness_body_gap" = 5,
	"witness_attack_opinion" = 8,
	"friend_attack_penalty" = 0.2,
	"witness_speak_chance" = 50,
	"violence_excuse_share" = 1,
	"witness_memory_minutes" = 30,
	"danger_soft_points" = 10,
	"danger_halving_minutes" = 10,
	"danger_permanent_points" = 100,
	"report_points" = 20,
	"friend_ignores_claims_at" = 30,
	"friend_ignores_blows_at" = 60,
	"friend_ignores_all_at" = 90,
	"obedience_base" = 20,
	"obedience_opinion_weight" = 0.5,
	"obedience_department_head" = 40,
	"obedience_other_head" = 15,
	"obedience_trusted_job" = 20,
	"follow_minutes" = 10,
	"hold_still_minutes" = 2,
	"stop_work_minutes" = 5,
	"come_to_wait_minutes" = 3,
	"talk_opinion" = 5,
	"talk_remarks" = 3,
	"talk_silence_seconds" = 50,
	"talk_again_minutes" = 5,
	"talk_gap_seconds" = 60,
	"prey_agree_threshold" = 0.25,
	"prey_inside_enjoyment" = 0.25,
	"prey_desire" = 0,
	"heal_belly_opinion_per_minute" = 6,
	"held_digest_reluctance" = 0.4,
	"held_betrayed_opinion" = 40,
	"digest_needed_trust" = 30,
	"pred_hunger_motive" = 0.3,
	"pred_feelings_motive" = 1,
	"pred_threat_motive" = 1,
	"pred_force_line" = 1.25,
	"pred_ask_line" = 0.5,
	"pred_accept_line" = 0.6,
	"pred_digest_line" = 1.5,
	"pred_offer_line" = 0,
	"pred_release_margin" = 0.8,
	"pred_capacity" = 2,
))

GLOBAL_LIST_EMPTY(npc_settings)

/proc/npc_setting(key)
	if(key in GLOB.npc_settings)
		return GLOB.npc_settings[key]
	return GLOB.npc_setting_defaults[key]

/hook/startup/proc/load_npc_settings()
	npc_load_settings()
	return TRUE

/proc/log_npc_config(path, text)
	var/line = "NPC CONFIG: [path]: [text]"
	log_world(line)
	log_debug(line)

/proc/npc_load_settings()
	var/list/loaded = list()
	for(var/file in npc_config_files("settings"))
		var/list/data = npc_read_json(file)
		for(var/key in data)
			if(!(key in GLOB.npc_setting_defaults))
				log_npc_config(file, "\"[key]\" is not a setting.")
				continue
			if(key in loaded)
				log_npc_config(file, "duplicate \"[key]\", ignoring this one.")
				continue
			var/value = data[key]
			var/default = GLOB.npc_setting_defaults[key]
			if(isnum(default) && !isnum(value))
				log_npc_config(file, "setting \"[key]\" is not a number.")
				continue
			if(islist(default) && !islist(value))
				log_npc_config(file, "setting \"[key]\" is not a list.")
				continue
			loaded[key] = value
	GLOB.npc_settings = loaded

/proc/npc_config_files(prefix)
	. = list()
	for(var/name in flist(NPC_CONFIG_DIR))
		if(findtext(name, prefix) == 1 && copytext(name, -5) == ".json")
			. += "[NPC_CONFIG_DIR][name]"

/proc/npc_read_json(path)
	var/text = trim(file2text(path))
	if(!length(text))
		log_npc_config(path, "missing or empty.")
		return null
	if(copytext(text, 1, 2) != "{")
		log_npc_config(path, "no object.")
		return null
	var/list/data
	try
		data = json_decode(text)
	catch(var/exception/E)
		log_npc_config(path, "could not be read: [E.name]")
		return null
	return data
