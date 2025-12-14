//////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Loading screen for the custom marking designer //
//////////////////////////////////////////////////////////////////////////////////////////////////

#define CUSTOM_MARKING_DESIGNER_UI_WIDTH 1720
#define CUSTOM_MARKING_DESIGNER_UI_HEIGHT 950

/datum/tgui_module/custom_marking_designer_loading
	name = "Custom Marking Designer"
	tgui_id = "CustomMarkingDesignerLoading"

	var/datum/preferences/prefs

/datum/tgui_module/custom_marking_designer_loading/New(datum/preferences/pref)
	..()
	prefs = pref

/datum/tgui_module/custom_marking_designer_loading/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/tgui_module/custom_marking_designer_loading/tgui_data(mob/user)
	var/list/data = list()
	data["width"] = CUSTOM_MARKING_DESIGNER_UI_WIDTH
	data["height"] = CUSTOM_MARKING_DESIGNER_UI_HEIGHT
	return data

/datum/tgui_module/custom_marking_designer_loading/tgui_close(mob/user)
	if(prefs)
		prefs.custom_marking_designer_loading_ui = null
	return ..()

#undef CUSTOM_MARKING_DESIGNER_UI_WIDTH
#undef CUSTOM_MARKING_DESIGNER_UI_HEIGHT
