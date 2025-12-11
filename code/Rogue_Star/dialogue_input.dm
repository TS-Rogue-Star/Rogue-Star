#define DIALOGUE_PATH "/data/dialogue/"

//path = "[DIALOGUE_PATH][name].json"

/proc/dialogue_setup()
	set name = "Dialogue Setup"
	set desc = ""
	set category = "Fun"

	if(!check_rights(R_ADMIN, R_FUN))
		return

	var/choice = tgui_alert(usr,"Do you want to create a dialogue or select an existing one?","Dialogue Setup",list("Create", "Select"))

	if(choice == "Create")
		dialogue_input()
	if(choice == "Select")
		list_dialogues()

/proc/dialogue_input()
	set name = "Dialogue Input"
	set desc = ""
	set category = "Debug"

	if(!check_rights(R_ADMIN, R_FUN))
		return

	//Confirm association
	if(tgui_alert(usr,"You want to associate the dialogue with [src]?","Dialogue Association",list("Yes", "No")) != "Yes")
		return

	//Do we have a dialogue library?
	if(!src.dialogue_library)
		src.dialogue_library = list()	//No? Create one.

	//What's the dialogue?
	var/ourdialogue = tgui_input_text(usr,"What will \the [src] say?","Dialogue Input", multiline = TRUE, prevent_enter = TRUE)

	if(!ourdialogue)
		return
	//What's the title?
	var/ourtitle = tgui_input_text(usr,"What is the title?","Dialogue Title Input")
	if(!ourtitle)
		to_chat(usr,"No title recieved, cancelling title input: [ourdialogue]")
		return
	//Should there be an image associated with this?
	var/ouricon
	var/ouricon_state

	if(tgui_alert(usr,"Should there be an image associated with this?","Enable Portrait",list("Yes", "No")) == "Yes")
		//What icon should we use?
		ouricon = text2path(tgui_input_text(usr,"What is the icon?","Dialogue Icon Input"))

		//What icon state should we use?
		if(ouricon)
			ouricon_state = tgui_input_text(usr,"What is the icon_state?","Dialogue Icon State Input")

		if(!ouricon_state)
			ouricon = null

	//What options should be available?
	var/ouroptions = tgui_input_text(usr,"What are the options? Enter them on one line, and separate them with |. For example, Yes|No","Options Input")

	var/list/processed_options = splittext(ouroptions,"|")

	//Should we save this to be used in future rounds?
	if(tgui_alert(usr,"Should this be saved for just this round, or permanently?","Save Mode",list("This Round", "Permanently")) == "Permanently")

	var/ourname = tgui_input_text(usr,"What will you name this file? This is only used for the path so do not include spaces or strange characters.","Dialogue Name Input")

	var/ourpath = get_dialogue_path(ourname)

	//Confirm potential overwrite
	if(fexists(ourpath))
		if(tgui_alert(usr,"A dialogue path already exists for [src], are you sure you want to add to it?","Dialogue Overwrite",list("Yes", "No")) != "Yes")
		return


















/proc/savedialogue(input, path)
	if(!islist(input))
		return

	var/json_to_file
	try
		json_to_file = json_encode(input)
	catch
		error("Failed to encode dialogue json: [input]")

	if(!json_to_file)
		log_debug("DIALOGUE: Save failed - [input] - failed json encode.")
		return

	log_debug("DIALOGUE: save called on [ourmob]: [json_to_file]")

	try
		rustg_file_write(json_to_file, path)
	catch
		error("Dialogue failed to write to file for: [json_to_file] - [path]")

	if(!fexists(path))
		log_debug("Saving: [path] failed file write")

/proc/retrievedialogue(input)
	if(!fexists(input))
		return FALSE
	var/processed_input = json_decode(file2text(input))
	return processed_input

/proc/list_dialogues()
	set name = "Dialogue Input"
	set desc = ""
	set category = "Debug"

	var/list/dialogue_list = flist(DIALOGUE_PATH)
	if(!dialogue_list)
		to_chat(usr,SPAN_DANGER("The dialogue list is empty, you may want to write some dialogue instead."))
		return
	var/input = tgui_input_list(usr,"Which dialogue will you pick?","Dialogue Selection",dialogue_list)

	if(!input)
		return FALSE

	return input

/proc/get_dialogue_path(input)
	return "[DIALOGUE_PATH][input].json"

/atom
	var/alist/dialogue_library = null
