/mob/living/silicon/robot/Login()
	..()
	regenerate_icons()
	update_hud()

	show_laws(0)

	// Override the DreamSeeker macro with the borg version!
	client.set_hotkeys_macro("borgmacro", "borghotkeymode")

	// Forces synths to select an icon relevant to their module
	if(!icon_selected)
		icon_selection_tries = SSrobot_sprites.get_module_sprites_len(modtype, src) + 1
		choose_icon(icon_selection_tries)

		// RS Edit: Robot Glamour fix (Lira, June 2026)
		if(icon_selected)
			apply_sprite_equipment_glamour()

	plane_holder.set_vis(VIS_AUGMENTED, TRUE)
