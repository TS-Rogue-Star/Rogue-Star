/datum/job/centcom_journalist
	title = "CentCom Journalist"
	departments = list("Central Command")
	sorting_order = 4
	department_accounts = list(DEPARTMENT_COMMAND, DEPARTMENT_ENGINEERING, DEPARTMENT_MEDICAL, DEPARTMENT_RESEARCH, DEPARTMENT_SECURITY, DEPARTMENT_CARGO, DEPARTMENT_PLANET, DEPARTMENT_CIVILIAN)
	faction = "Station"
	total_positions = 2
	spawn_positions = 1
	supervisors = "truth"
	selection_color = "#1D1D4F"
	access = list()
	minimal_access = list()
	minimal_player_age = 14
	economic_modifier = 20
	whitelist_only = 1
	latejoin_only = 1
	outfit_type = /decl/hierarchy/outfit/job/centcom_officer
	job_description = "A seeker of the truth.  They document the facts."

	minimum_character_age = 25
	ideal_character_age = 40

	pto_type = PTO_CIVILIAN

/datum/job/centcom_officer/get_access()
	return get_all_accesses().Copy()
