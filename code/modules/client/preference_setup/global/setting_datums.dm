var/list/_client_preferences
var/list/_client_preferences_by_key
var/list/_client_preferences_by_type

/proc/get_client_preferences()
	if(!_client_preferences)
		_client_preferences = list()
		for(var/datum/client_preference/client_type as anything in subtypesof(/datum/client_preference))
			if(initial(client_type.description))
				_client_preferences += new client_type()
	return _client_preferences

/proc/get_client_preference(var/datum/client_preference/preference)
	if(istype(preference))
		return preference
	if(ispath(preference))
		return get_client_preference_by_type(preference)
	return get_client_preference_by_key(preference)

/proc/get_client_preference_by_key(var/preference)
	if(!_client_preferences_by_key)
		_client_preferences_by_key = list()
		for(var/datum/client_preference/client_pref as anything in get_client_preferences())
			_client_preferences_by_key[client_pref.key] = client_pref
	return _client_preferences_by_key[preference]

/proc/get_client_preference_by_type(var/preference)
	if(!_client_preferences_by_type)
		_client_preferences_by_type = list()
		for(var/datum/client_preference/client_pref as anything in get_client_preferences())
			_client_preferences_by_type[client_pref.type] = client_pref
	return _client_preferences_by_type[preference]

/datum/client_preference
	var/description
	var/key
	var/enabled_by_default = TRUE
	var/enabled_description = "Yes"
	var/disabled_description = "No"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	var/sound_panel_group
	var/sound_panel_sort_order = 0
	// RS Add End
	// RS Add Start: Preference settings panel (Lira, July 2026)
	var/settings_panel_group
	var/settings_panel_sort_order = 0
	var/settings_panel_tooltip
	// RS Add End

/datum/client_preference/proc/may_toggle(var/mob/preference_mob)
	return TRUE

/datum/client_preference/proc/toggled(var/mob/preference_mob, var/enabled)
	return

/*********************
* Player Preferences *
*********************/

/datum/client_preference/play_admin_midis
	description ="Play admin midis"
	key = "SOUND_MIDI"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_MUSIC
	sound_panel_sort_order = 30
	// RS Add End

/datum/client_preference/play_lobby_music
	description ="Play lobby music"
	key = "SOUND_LOBBY"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_MUSIC
	sound_panel_sort_order = 10
	// RS Add End

/datum/client_preference/play_lobby_music/toggled(var/mob/preference_mob, var/enabled)
	if(!preference_mob.client || !preference_mob.client.media)
		return

	if(enabled)
		preference_mob.client.playtitlemusic()
	else
		preference_mob.client.media.stop_music()

/datum/client_preference/play_ambiance
	description ="Play ambience"
	key = "SOUND_AMBIENCE"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_WORLD
	sound_panel_sort_order = 10
	// RS Add End

/datum/client_preference/play_ambiance/toggled(var/mob/preference_mob, var/enabled)
	if(!enabled)
		preference_mob << sound(null, repeat = 0, wait = 0, volume = 0, channel = 1)
		preference_mob << sound(null, repeat = 0, wait = 0, volume = 0, channel = 2)
//VOREStation Add - Need to put it here because it should be ordered riiiight here.
/datum/client_preference/play_jukebox
	description ="Play jukebox music"
	key = "SOUND_JUKEBOX"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_MUSIC
	sound_panel_sort_order = 20
	// RS Add End

/datum/client_preference/play_jukebox/toggled(var/mob/preference_mob, var/enabled)
	if(!enabled)
		preference_mob.stop_all_music()
	else
		preference_mob.update_music()

//RS ADD START
/datum/client_preference/food_eating_noises
	description = "Food Eating Noises"
	key = "FOOD EATING_NOISES"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	// Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_VORE
	sound_panel_sort_order = 10
//RS ADD END

/datum/client_preference/eating_noises
	description = "Eating Noises"
	key = "EATING_NOISES"
	enabled_description = "Noisy"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_VORE
	sound_panel_sort_order = 20
	// RS Add End

/datum/client_preference/digestion_noises
	description = "Digestion Noises"
	key = "DIGEST_NOISES"
	enabled_description = "Noisy"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_VORE
	sound_panel_sort_order = 30
	// RS Add End

/datum/client_preference/belch_noises // Belching noises - pref toggle for 'em
	description = "Burping"
	key = "BELCH_NOISES"
	enabled_description = "Noisy"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_VORE
	sound_panel_sort_order = 40
	// RS Add End

/datum/client_preference/smooch_noises // Smooching noises - pref toggle for 'em //RS Edit Start
	description = "Smooches"
	key = "SMOOCH_NOISES"
	enabled_description = "Noisy"
	disabled_description = "Silent" //RS Edit End
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_VORE
	sound_panel_sort_order = 50
	// RS Add End

/datum/client_preference/emote_noises
	description = "Emote Noises" //MERP
	key = "EMOTE_NOISES"
	enabled_description = "Noisy"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_VORE
	sound_panel_sort_order = 60
	// RS Add End
/datum/client_preference/whisubtle_vis
	description = "Whi/Subtles Ghost Visible"
	key = "WHISUBTLE_VIS"
	enabled_description = "Visible"
	disabled_description = "Hidden"
	enabled_by_default = FALSE
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 100
	settings_panel_tooltip = "Toggles ghosts being able to see your subtles/whispers."
	// RS Add End
//VOREStation Add End
/datum/client_preference/weather_sounds
	description ="Weather sounds"
	key = "SOUND_WEATHER"
	enabled_description = "Audible"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_WORLD
	sound_panel_sort_order = 20
	// RS Add End

/datum/client_preference/supermatter_hum
	description ="Supermatter hum"
	key = "SOUND_SUPERMATTER"
	enabled_description = "Audible"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_WORLD
	sound_panel_sort_order = 30
	// RS Add End

/datum/client_preference/ghost_ears
	description ="Ghost ears"
	key = "CHAT_GHOSTEARS"
	enabled_description = "All Speech"
	disabled_description = "Nearby"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 10
	settings_panel_tooltip = "Toggles between seeing all mob speech and only nearby mob speech as an observer."
	// RS Add End

/datum/client_preference/ghost_sight
	description ="Ghost sight"
	key = "CHAT_GHOSTSIGHT"
	enabled_description = "All Emotes"
	disabled_description = "Nearby"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 20
	settings_panel_tooltip = "Toggles between seeing all mob emotes and only nearby mob emotes as an observer."
	// RS Add End

/datum/client_preference/ghost_radio
	description ="Ghost radio"
	key = "CHAT_GHOSTRADIO"
	enabled_description = "All Chatter"
	disabled_description = "Nearby"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 30
	settings_panel_tooltip = "Toggles between seeing all radio chat and only nearby radio chatter as an observer."
	// RS Add End

/datum/client_preference/chat_tags
	description ="Chat tags"
	key = "CHAT_SHOWICONS"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 40
	settings_panel_tooltip = "Shows small icon tags for chat channels like OOC and LOOC. Turning it off uses plain text tags instead."
	// RS Add End

/datum/client_preference/air_pump_noise
	description ="Air Pump Ambient Noise"
	key = "SOUND_AIRPUMP"
	enabled_description = "Audible"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_WORLD
	sound_panel_sort_order = 40
	// RS Add End

/datum/client_preference/old_door_sounds
	description ="Old Door Sounds"
	key = "SOUND_OLDDOORS"
	enabled_description = "Old"
	disabled_description = "New"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_WORLD
	sound_panel_sort_order = 50
	// RS Add End

/datum/client_preference/department_door_sounds
	description ="Department-Specific Door Sounds"
	key = "SOUND_DEPARTMENTDOORS"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_WORLD
	sound_panel_sort_order = 60
	// RS Add End

/datum/client_preference/pickup_sounds
	description = "Picked Up Item Sounds"
	key = "SOUND_PICKED"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_ITEMS
	sound_panel_sort_order = 10
	// RS Add End

/datum/client_preference/drop_sounds
	description = "Dropped Item Sounds"
	key = "SOUND_DROPPED"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_ITEMS
	sound_panel_sort_order = 20
	// RS Add End

/datum/client_preference/mob_tooltips
	description ="Mob tooltips"
	key = "MOB_TOOLTIPS"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 10
	settings_panel_tooltip = "Toggles displaying name/species over mobs when they are moused over."
	// RS Add End

/datum/client_preference/inv_tooltips
	description ="Inventory tooltips"
	key = "INV_TOOLTIPS"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 20
	settings_panel_tooltip = "Toggles displaying name/desc over inventory items when they are moused over."
	// RS Add End

/datum/client_preference/attack_icons
	description ="Attack icons"
	key = "ATTACK_ICONS"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 30
	settings_panel_tooltip = "Shows floating attack or held-item icons on targets when attacks happen."
	// RS Add End

/datum/client_preference/precision_placement
	description ="Precision Placement"
	key = "PRECISE_PLACEMENT"
	enabled_description = "Active"
	disabled_description = "Inactive"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 15
	settings_panel_tooltip = "Toggles whether objects placed on table will be on cursor position or centered."
	// RS Add End

/datum/client_preference/hotkeys_default
	description ="Hotkeys Default"
	key = "HUD_HOTKEYS"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	enabled_by_default = FALSE // Backwards compatibility
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 5
	settings_panel_tooltip = "Starts in hotkey mode by default."
	// RS Add End

/datum/client_preference/show_typing_indicator
	description ="Typing indicator"
	key = "SHOW_TYPING"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 50
	settings_panel_tooltip = "Toggles you having the speech bubble typing indicator."
	// RS Add End

/datum/client_preference/show_typing_indicator/toggled(var/mob/preference_mob, var/enabled)
	if(!enabled)
		preference_mob.set_typing_indicator(FALSE)

/datum/client_preference/show_ooc
	description ="OOC chat"
	key = "CHAT_OOC"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 60
	settings_panel_tooltip = "Toggles visibility of global out of character chat."
	// RS Add End

/datum/client_preference/show_looc
	description ="LOOC chat"
	key = "CHAT_LOOC"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 70
	settings_panel_tooltip = "Toggles visibility of local out of character chat."
	// RS Add End

/datum/client_preference/show_dsay
	description ="Dead chat"
	key = "CHAT_DEAD"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 80
	settings_panel_tooltip = "Toggles visibility of dead chat."
	// RS Add End

/datum/client_preference/check_mention
	description ="Emphasize Name Mention"
	key = "CHAT_MENTION"
	enabled_description = "Emphasize"
	disabled_description = "Normal"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 90
	settings_panel_tooltip = "Emphasizes chat messages that mention your character name, nickname, or special mention terms such as AI."
	// RS Add End

/datum/client_preference/show_progress_bar
	description ="Progress Bar"
	key = "SHOW_PROGRESS"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 60
	settings_panel_tooltip = "Shows action progress bars when an interaction creates a visible progress indicator."
	// RS Add End

/datum/client_preference/safefiring
	description = "Safe Firing"
	key = "SAFE_FIRING"
	enabled_description = "Safe"
	disabled_description = "Dangerous"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 10
	settings_panel_tooltip = "When enabled, guns will not fire while your intent is set to Help."
	// RS Add End

/datum/client_preference/browser_style
	description = "Fake NanoUI Browser Style"
	key = "BROWSER_STYLED"
	enabled_description = "Fancy"
	disabled_description = "Plain"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 70
	settings_panel_tooltip = "Applies fancy layout to legacy browser windows."
	// RS Add End

/datum/client_preference/ambient_occlusion
	description = "Fake Ambient Occlusion"
	key = "AMBIENT_OCCLUSION_PREF"
	enabled_by_default = FALSE
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 80
	settings_panel_tooltip = "Adds fake shadowing around mobs and objects for depth."
	// RS Add End

/datum/client_preference/ambient_occlusion/toggled(var/mob/preference_mob, var/enabled)
	. = ..()
	if(preference_mob && preference_mob.plane_holder)
		var/datum/plane_holder/PH = preference_mob.plane_holder
		PH.set_ao(VIS_OBJS, enabled)
		PH.set_ao(VIS_MOBS, enabled)

/datum/client_preference/instrument_toggle
	description ="Hear In-game Instruments"
	key = "SOUND_INSTRUMENT"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_MUSIC
	sound_panel_sort_order = 40
	// RS Add End

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/client_preference/instrument_toggle/toggled(var/mob/preference_mob, var/enabled)
	. = ..()
	preference_mob?.client?.refresh_instrument_audio()

/datum/client_preference/vchat_enable
	description = "Enable/Disable VChat"
	key = "VCHAT_ENABLE"
	enabled_description =  "Enabled"
	disabled_description = "Disabled"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 110
	settings_panel_tooltip = "Toggles VChat."
	// RS Add End

/datum/client_preference/status_indicators
	description = "Status Indicators"
	key = "SHOW_STATUS"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_INTERFACE
	settings_panel_sort_order = 90
	settings_panel_tooltip = "Toggles seeing status indicators over peoples' heads."
	// RS Add End

/datum/client_preference/radio_sounds
	description = "Radio Sounds"
	key = "RADIO_SOUNDS"
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_CHAT
	sound_panel_sort_order = 10
	// RS Add End

/datum/client_preference/say_sounds
	description = "Say Sounds"
	key = "SAY_SOUNDS"
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_CHAT
	sound_panel_sort_order = 20
	// RS Add End

/datum/client_preference/emote_sounds
	description = "Me Sounds"
	key = "EMOTE_SOUNDS"
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_CHAT
	sound_panel_sort_order = 30
	// RS Add End

/datum/client_preference/whisper_sounds
	description = "Whisper Sounds"
	key = "WHISPER_SOUNDS"
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_CHAT
	sound_panel_sort_order = 40
	// RS Add End

/datum/client_preference/subtle_sounds
	description = "Subtle Sounds"
	key = "SUBTLE_SOUNDS"
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_CHAT
	sound_panel_sort_order = 50
	// RS Add End

//RS ADDITION
/datum/client_preference/looc_sounds
	description = "LOOC Sound"
	key = "LOOC_SOUNDS"
	enabled_description = "On"
	disabled_description = "Off"
	// Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_CHAT
	sound_panel_sort_order = 60

/datum/client_preference/emotes_from_beyond
	description = "Emotes from Beyond"
	key = "EMOTES_FROM_BEYOND"
	enabled_description = "On"
	disabled_description = "Off"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_CHAT
	settings_panel_sort_order = 120
	settings_panel_tooltip = "Toggle emotes and says from outside of the ship Z level from printing in your chat."
	// RS Add End

/datum/client_preference/vore_health_bars
	description = "Vore Health Bars"
	key = "VORE_HEALTH_BARS"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 20
	settings_panel_tooltip = "Toggle the display of vore related health bars"
	// RS Add End

/datum/client_preference/vore_damage_overlay
	description = "Vore Self Damage Overlay"
	key = "VORE_DAMAGE_OVERLAY"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 30
	settings_panel_tooltip = "Allows body damage overlays to appear while you are inside a belly that displays vore damage icons."
	// RS Add End

//RS ADDITION END

/datum/client_preference/runechat_mob
	description = "Runechat (Mobs)"
	key = "RUNECHAT_MOB"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_RUNECHAT
	settings_panel_sort_order = 10
	settings_panel_tooltip = "Shows runechat text above mob speakers for speech and emotes you can receive."
	// RS Add End

/datum/client_preference/runechat_obj
	description = "Runechat (Objs)"
	key = "RUNECHAT_OBJ"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_RUNECHAT
	settings_panel_sort_order = 20
	settings_panel_tooltip = "Shows runechat text above non-mob speakers, objects, and environmental message sources."
	// RS Add End

/datum/client_preference/runechat_border
	description = "Runechat Message Border"
	key = "RUNECHAT_BORDER"
	enabled_description = "Show"
	disabled_description = "Hide"
	enabled_by_default = TRUE
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_RUNECHAT
	settings_panel_sort_order = 30
	settings_panel_tooltip = "Adds a black outline to runechat text to make overhead messages easier to read."
	// RS Add End

/datum/client_preference/runechat_long_messages
	description = "Runechat Message Length"
	key = "RUNECHAT_LONG"
	enabled_description = "Long"
	disabled_description = "Short"
	enabled_by_default = FALSE
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_RUNECHAT
	settings_panel_sort_order = 40
	settings_panel_tooltip = "Allows longer runechat messages before they are clipped, using a wider overhead text bubble."
	// RS Add End

/datum/client_preference/status_indicators/toggled(mob/preference_mob, enabled)
	. = ..()
	if(preference_mob && preference_mob.plane_holder)
		var/datum/plane_holder/PH = preference_mob.plane_holder
		PH.set_vis(VIS_STATUS, enabled)

/datum/client_preference/show_lore_news
	description = "Lore News Popup"
	key = "NEWS_POPUP"
	enabled_by_default = TRUE
	enabled_description = "Popup New On Login"
	disabled_description = "Do Nothing"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 40
	settings_panel_tooltip = "Shows the lore news popup when you log in and there is unread station news."
	// RS Add End

/datum/client_preference/play_mentorhelp_ping
	description = "Mentorhelps"
	key = "SOUND_MENTORHELP"
	enabled_description = "Hear"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_STAFF
	sound_panel_sort_order = 10
	// RS Add End
/* Rs removal
/datum/client_preference/player_tips
	description = "Receive Tips Periodically"
	key = "RECEIVE_TIPS"
	enabled_description = "Enabled"
	disabled_description = "Disabled"
*/ // RS Removal
/datum/client_preference/pain_frequency
	description = "Pain Messages Cooldown"
	key = "PAIN_FREQUENCY"
	enabled_by_default = FALSE
	enabled_description = "Extended"
	disabled_description = "Default"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 50
	settings_panel_tooltip = "When toggled on, increases the cooldown of pain messages sent to chat for minor injuries"
	// RS Add End

//RS ADD START
/datum/client_preference/game_toggle
	description = "Game Participation"
	key = "GAME_PARTICIPATION"
	enabled_by_default = TRUE
	enabled_description = "Participate"
	disabled_description = "Sit out"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_GAMEPLAY
	settings_panel_sort_order = 60
	settings_panel_tooltip = "When toggled on, you will participate in a game, and may collect or count for points!"
	// RS Add End
//RS ADD END

/********************
* Staff Preferences *
********************/
/datum/client_preference/admin/may_toggle(var/mob/preference_mob)
	return check_rights(R_ADMIN|R_EVENT, 0, preference_mob)

/datum/client_preference/mod/may_toggle(var/mob/preference_mob)
	return check_rights(R_MOD|R_ADMIN, 0, preference_mob)

/datum/client_preference/debug/may_toggle(var/mob/preference_mob)
	return check_rights(R_DEBUG|R_ADMIN, 0, preference_mob)

/datum/client_preference/mod/show_attack_logs
	description = "Attack Log Messages"
	key = "CHAT_ATTACKLOGS"
	enabled_description = "Show"
	disabled_description = "Hide"
	enabled_by_default = FALSE
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 10
	settings_panel_tooltip = "Toggles seeing attack logs."
	// RS Add End

/datum/client_preference/debug/show_debug_logs
	description = "Debug Log Messages"
	key = "CHAT_DEBUGLOGS"
	enabled_description = "Show"
	disabled_description = "Hide"
	enabled_by_default = FALSE
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 20
	settings_panel_tooltip = "Toggles seeing debug logs."
	// RS Add End

/datum/client_preference/admin/show_chat_prayers
	description = "Chat Prayers"
	key = "CHAT_PRAYER"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 30
	settings_panel_tooltip = "Shows player prayer messages in staff chat."
	// RS Add End

/datum/client_preference/holder/may_toggle(var/mob/preference_mob)
	return preference_mob && preference_mob.client && preference_mob.client.holder

/datum/client_preference/holder/play_adminhelp_ping
	description = "Adminhelps"
	key = "SOUND_ADMINHELP"
	enabled_description = "Hear"
	disabled_description = "Silent"
	// RS Add Start: Sound preferences panel (Lira, June 2026)
	sound_panel_group = SOUND_PANEL_GROUP_STAFF
	sound_panel_sort_order = 20
	// RS Add End

/datum/client_preference/holder/hear_radio
	description = "Radio chatter"
	key = "CHAT_RADIO"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 40
	settings_panel_tooltip = "Lets staff receive the full radio chatter feed through telecomms. Turning it off hides that staff radio feed."
	// RS Add End

/datum/client_preference/holder/show_rlooc
	description ="Remote LOOC chat"
	key = "CHAT_RLOOC"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 50
	settings_panel_tooltip = "Toggles seeing LOOC messages outside your actual LOOC range."
	// RS Add End

/datum/client_preference/holder/show_staff_dsay
	description ="Staff Deadchat"
	key = "CHAT_ADSAY"
	enabled_description = "Show"
	disabled_description = "Hide"
	// RS Add Start: Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 60
	settings_panel_tooltip = "Toggles seeing deadchat while not observing."
	// RS Add End

//RS ADD START
/datum/client_preference/holder/show_staff_secrets
	description ="Staff Secrets"
	key = "STAFF_SECRETS"
	enabled_description = "Show"
	disabled_description = "Hide"
	enabled_by_default = FALSE
	// Preference settings panel (Lira, July 2026)
	settings_panel_group = PREFERENCE_SETTINGS_GROUP_STAFF
	settings_panel_sort_order = 70
	settings_panel_tooltip = "Shows staff-only secret or admin visual markers when your mob logs in."
//RS ADD END
