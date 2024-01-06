/decl/webhook/staff_request
	id = WEBHOOK_STAFF_REQUEST

/decl/webhook/note_made/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_DEFAULT
	))
