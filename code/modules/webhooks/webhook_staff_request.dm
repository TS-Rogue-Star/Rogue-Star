// Command

/decl/webhook/cmdstaff_request
	id = WEBHOOK_CMDSTAFF_REQUEST

/decl/webhook/cmdstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_CMD
	))

// Security

/decl/webhook/secstaff_request
	id = WEBHOOK_SECSTAFF_REQUEST

/decl/webhook/secstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_SEC
	))

// Engineering

/decl/webhook/engstaff_request
	id = WEBHOOK_ENGSTAFF_REQUEST

/decl/webhook/engstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_ENG
	))

// Medical

/decl/webhook/medstaff_request
	id = WEBHOOK_MEDSTAFF_REQUEST

/decl/webhook/medstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_MEDICAL
	))

// Research

/decl/webhook/resstaff_request
	id = WEBHOOK_RESSTAFF_REQUEST

/decl/webhook/resstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_SCIENCE
	))

// Supply

/decl/webhook/supstaff_request
	id = WEBHOOK_SUPSTAFF_REQUEST

/decl/webhook/supstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_SUPPLY
	))

// Service

/decl/webhook/serstaff_request
	id = WEBHOOK_SERSTAFF_REQUEST

/decl/webhook/serstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_SERVICE
	))

// Explo

/decl/webhook/expstaff_request
	id = WEBHOOK_EXPSTAFF_REQUEST

/decl/webhook/expstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_EXPLO
	))

// Silicon

/decl/webhook/silstaff_request
	id = WEBHOOK_SILSTAFF_REQUEST

/decl/webhook/silstaff_request/get_message(var/list/data)
	.= ..()
	.["embeds"] = list(list(
		"title" = "Staff Request",
		"description" = data["info"],
		"color" = COLOR_WEBHOOK_AI
	))
