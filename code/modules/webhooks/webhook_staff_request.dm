// Command

/decl/webhook/cmdstaff_request
	id = WEBHOOK_CMDSTAFF_REQUEST

/decl/webhook/cmdstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Security

/decl/webhook/secstaff_request
	id = WEBHOOK_SECSTAFF_REQUEST

/decl/webhook/secstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Engineering

/decl/webhook/engstaff_request
	id = WEBHOOK_ENGSTAFF_REQUEST

/decl/webhook/engstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Medical

/decl/webhook/medstaff_request
	id = WEBHOOK_MEDSTAFF_REQUEST

/decl/webhook/medstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Research

/decl/webhook/resstaff_request
	id = WEBHOOK_RESSTAFF_REQUEST

/decl/webhook/resstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Supply

/decl/webhook/supstaff_request
	id = WEBHOOK_SUPSTAFF_REQUEST

/decl/webhook/supstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Service

/decl/webhook/serstaff_request
	id = WEBHOOK_SERSTAFF_REQUEST

/decl/webhook/serstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Explo

/decl/webhook/expstaff_request
	id = WEBHOOK_EXPSTAFF_REQUEST

/decl/webhook/expstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))

// Silicon

/decl/webhook/silstaff_request
	id = WEBHOOK_SILSTAFF_REQUEST

/decl/webhook/silstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = data["color"] || COLOR_WEBHOOK_DEFAULT
	))
