#define TALLY_OBJECTS = 1
#define TALLY_INT = 2

/obj/structure/tally_box
	name = "Tally Box"
	desc = "A box for taking tallys!"
	icon = 'icons/obj/boxes.dmi'
	icon_state = "box"

	var/static/list/global_tallied = list()
	var/list/local_tallied = list()
	var/allow_multiple = FALSE
	var/static/list/tally_boxes = list()
	var/accept_objects = null
	var/tallies = 0
	var/configured = FALSE
	var/report_name

/obj/structure/tally_box/Initialize()
	. = ..()
	tally_boxes += src
	if(!accept_objects && !report_name)
		configured = FALSE
	else
		configured = TRUE

/obj/structure/tally_box/Destroy()
	. = ..()
	tally_boxes -= src

/obj/structure/tally_box/verb/report_tally()
	set name = "Report Tally"
	set category = "Object"
	set desc = "Report the present tally!"
	set src in view(7)

	if(!ismob(usr))
		return

	var/mob/user = usr

	if(!user.client.holder)
		to_chat(user,SPAN_WARNING("No peeking!"))
		return
	var/list/origin = list(tally_boxes)
	var/list/report = list()
	var/obj/structure/tally_box/max = src
	var/skipped = 0
	if(!global_tallied.len)
		to_chat(user,SPAN_WARNING("No one has voted."))
		return
	while(report.len + skipped < origin.len)
		for(var/obj/structure/tally_box/box in origin)
			if(!box.local_tallied.len || !configured)
				skipped ++
				to_chat(user,"Skipping [box.report_name]: configure is set to [box.configured]. This box has [box.local_tallied.len] votes registered.")
				continue
			if(!max)
				max = box
				to_chat(user,"set initial max [max.local_tallied.len]")
				continue
			if(box.local_tallied.len > max.local_tallied.len)
				to_chat(user,"Found higher max - old: [max.local_tallied.len] - new: [box.local_tallied.len]")

				max = box

		if(!max)
			to_chat(user,"There seem to be no valid tally boxes!")
			for(var/obj/structure/tally_box/ebox in tally_boxes)
				to_chat(user,"[ebox] configure is set to [ebox.configured], and the report name is set to [ebox.report_name]. This box has [ebox.local_tallied.len] votes registered.")
			return
		origin -= max
		report[max.report_name] = max.local_tallied.len
		max = null


	var/winner
	var/winner_score
	var/winmsg
	to_chat(user,SPAN_DANGER("A total of [global_tallied.len] people have voted."))
	for(var/box in report)
		to_chat(user,SPAN_NOTICE("[box] has a tally total of [report[box]]"))
		if(!winner)
			winner = box
			winmsg = winner
			winner_score = report[box]
		else if(winner_score == report[box])
			winmsg = "[winmsg] and [box]"

	if(winner)
		to_chat(user, SPAN_DANGER("The winner is [winmsg], with a total of [winner_score]!"))
	else
		to_chat(user, "There are [tally_boxes.len] tally boxes, and there is [global_tallied.len] votes between them. No winner was resolved from this data.")

/obj/structure/tally_box/attack_hand(mob/user)
	. = ..()
	if(!configured && !accept_objects)
		if(tgui_alert(user,"Would you like to register this [src] to accept votes for you?","Tally Box",list("No","Yes")) == "Yes")
			if(!configured)
				report_name = user.real_name
				configured = TRUE
				to_chat(user,SPAN_NOTICE("You configured the tally box to accept votes for yourself!"))
				return
			else
				to_chat(user,SPAN_WARNING("Someone else already registered this box!"))
				return
		return

	if(!isliving(user))
		to_chat(user,"You can't vote!")
		return
	if(accept_objects)
		to_chat(user,"You need to submit the appropriate item!")
		return

	if(tgui_alert(user,"Would you like to vote for [report_name]?","Tally Box",list("Yes","No")) == "Yes")
		for(var/obj/structure/tally_box/box in tally_boxes)
			if(user.name in box.local_tallied)
				box.local_tallied -= user.name


		local_tallied |= user.real_name
		global_tallied |= user.real_name
		to_chat(user,SPAN_NOTICE("You have registered your tally vote for [report_name]!"))
