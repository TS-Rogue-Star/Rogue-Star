/decl/webhook/note_made
	id = WEBHOOK_NOTE_MADE

/decl/webhook/note_made/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Note Made",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_DEFAULT
	))
