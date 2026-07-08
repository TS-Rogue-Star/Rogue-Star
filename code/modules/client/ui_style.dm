

/var/all_ui_styles = list(
	"Midnight"     = 'icons/mob/screen/midnight.dmi',
	"Orange"       = 'icons/mob/screen/orange.dmi',
	"old"          = 'icons/mob/screen/old.dmi',
	"White"        = 'icons/mob/screen/white.dmi',
	"old-noborder" = 'icons/mob/screen/old-noborder.dmi',
	"minimalist"   = 'icons/mob/screen/minimalist.dmi',
	"Hologram"     = 'icons/mob/screen/holo.dmi'
	)

/var/all_ui_styles_robot = list(
	"Midnight"     = 'icons/mob/screen1_robot.dmi',
	"Orange"       = 'icons/mob/screen1_robot.dmi',
	"old"          = 'icons/mob/screen1_robot.dmi',
	"White"        = 'icons/mob/screen1_robot.dmi',
	"old-noborder" = 'icons/mob/screen1_robot.dmi',
	"minimalist"   = 'icons/mob/screen1_robot_minimalist.dmi',
	"Hologram"     = 'icons/mob/screen1_robot_minimalist.dmi'
	)

var/global/list/all_tooltip_styles = list(
	"Midnight",		//Default for everyone is the first one,
	"Plasmafire",
	"Retro",
	"Slimecore",
	"Operative",
	"Clockwork"
	)

/proc/ui_style2icon(ui_style)
	if(ui_style in all_ui_styles)
		return all_ui_styles[ui_style]
	return all_ui_styles["White"]

// RS Add: Preference settings panel (Lira, July 2026)
/mob/proc/get_ui_style_icon_for_mob(var/ui_style)
	if(isrobot(src))
		if(ui_style in all_ui_styles_robot)
			return all_ui_styles_robot[ui_style]
		return all_ui_styles_robot["White"]

	return ui_style2icon(ui_style)

// RS Add: Preference settings panel (Lira, July 2026)
/mob/proc/apply_ui_preferences_to_hud()
	if(!client?.prefs)
		return FALSE

	return apply_ui_style_to_hud(client.prefs.UI_style, client.prefs.UI_style_color, client.prefs.UI_style_alpha)

// RS Add: Preference settings panel (Lira, July 2026)
/mob/proc/apply_ui_style_to_hud(var/ui_style, var/ui_color, var/ui_alpha)
	if(!hud_used)
		return FALSE
	if(!ishuman(src) && !isrobot(src))
		return FALSE

	var/icon/new_ui_style = get_ui_style_icon_for_mob(ui_style)
	if(!new_ui_style)
		return FALSE

	var/icon/old_ui_style = hud_used.ui_style
	var/list/new_ui_states = icon_states(new_ui_style)
	hud_used.ui_style = new_ui_style
	hud_used.ui_color = ui_color
	hud_used.ui_alpha = ui_alpha

	var/list/screen_objects = list()
	if(hud_used.adding)
		screen_objects |= hud_used.adding
	if(hud_used.other)
		screen_objects |= hud_used.other
	if(hud_used.other_important)
		screen_objects |= hud_used.other_important
	if(hud_used.hotkeybuttons)
		screen_objects |= hud_used.hotkeybuttons
	if(zone_sel)
		screen_objects |= zone_sel
	if(gun_setting_icon)
		screen_objects |= gun_setting_icon
	if(item_use_icon)
		screen_objects |= item_use_icon
	if(gun_move_icon)
		screen_objects |= gun_move_icon
	if(radio_use_icon)
		screen_objects |= radio_use_icon
	if(healths)
		screen_objects |= healths
	if(internals)
		screen_objects |= internals
	if(pullin)
		screen_objects |= pullin
	if(throw_icon)
		screen_objects |= throw_icon
	if(hands)
		screen_objects |= hands

	var/list/intent_names = list(I_HELP, I_HURT, I_DISARM, I_GRAB)
	for(var/obj/screen/screen_object in screen_objects)
		if(screen_object.name in intent_names)
			continue
		if(screen_object.icon != old_ui_style)
			continue
		if(screen_object.icon_state && !(screen_object.icon_state in new_ui_states))
			continue
		screen_object.icon = new_ui_style
		screen_object.color = ui_color
		screen_object.alpha = ui_alpha

	if(zone_sel)
		zone_sel.cut_overlays()
		zone_sel.update_icon()

	return TRUE


/client/verb/change_ui()
	set name = "Change UI"
	set category = "Preferences"
	set desc = "Configure your user interface"

	if(!ishuman(usr))
		if(!isrobot(usr))
			to_chat(usr, "<span class='warning'>You must be a human or a robot to use this verb.</span>")
			return

	var/UI_style_new = tgui_input_list(usr, "Select a style. White is recommended for customization", "UI Style Choice", all_ui_styles)
	if(!UI_style_new) return

	var/UI_style_alpha_new = tgui_input_number(usr, "Select a new alpha (transparency) parameter for your UI, between 50 and 255", null, null, 255, 50)
	if(!UI_style_alpha_new || !(UI_style_alpha_new <= 255 && UI_style_alpha_new >= 50)) return

	var/UI_style_color_new = input(usr, "Choose your UI color. Dark colors are not recommended!") as color|null
	if(!UI_style_color_new) return

	usr.apply_ui_style_to_hud(UI_style_new, UI_style_color_new, UI_style_alpha_new) // RS Edit: Preference settings panel (Lira, July 2026)

	if(tgui_alert(usr, "Like it? Save changes?","Save?",list("Yes", "No")) == "Yes")
		prefs.UI_style = UI_style_new
		prefs.UI_style_alpha = UI_style_alpha_new
		prefs.UI_style_color = UI_style_color_new
		SScharacter_setup.queue_preferences_save(prefs)
		to_chat(usr, "UI was saved")
