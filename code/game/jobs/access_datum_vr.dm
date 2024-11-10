//Moved from southern_cross_jobs.vr to fix a runtime
var/const/access_explorer = 43
/datum/access/explorer
	id = access_explorer
	desc = "Away Team"
	region = ACCESS_REGION_GENERAL
/*
/var/const/access_pathfinder = 44
/datum/access/pathfinder
	id = access_pathfinder
	desc = "Pathfinder"
	region = ACCESS_REGION_GENERAL
*/
var/const/access_pilot = 67
/datum/access/pilot
	id = access_pilot
	desc = "Pilot"
	region = ACCESS_REGION_GENERAL

/var/const/access_talon = 301
/datum/access/talon
	id = access_talon
	desc = "Talon General"
	access_type = ACCESS_TYPE_PRIVATE

/var/const/access_talon_bridge = 302
/datum/access/bridge
	id = access_bridge
	desc = "Talon Bridge"
	access_type = ACCESS_TYPE_PRIVATE

/var/const/access_talon_medical = 303
/datum/access/medical
	id = access_medical
	desc = "Talon Medical"
	access_type = ACCESS_TYPE_PRIVATE

/var/const/access_talon_engineer = 304
/datum/access/engineer
	id = access_engineer
	desc = "Talon Engineering"
	access_type = ACCESS_TYPE_PRIVATE

/var/const/access_talon_cargo = 305
/datum/access/cargo
	id = access_cargo
	desc = "Talon Cargo"
	access_type = ACCESS_TYPE_PRIVATE

/var/const/access_talon_sec = 306
/datum/access/security
	id = access_security
	desc = "Talon Security"
	access_type = ACCESS_TYPE_PRIVATE

/var/const/access_xenobotany = 77
/datum/access/xenobotany
	id = access_xenobotany
	desc = "Xenobotany Garden"
	region = ACCESS_REGION_RESEARCH

/var/const/access_entertainment = 72
/datum/access/entertainment
	id = access_entertainment
	desc = "Entertainment Backstage"
	region = ACCESS_REGION_GENERAL

/var/const/access_mime = 138
/datum/access/mime
	id = access_mime
	desc = "Mime Office"
	region = ACCESS_REGION_GENERAL

/var/const/access_clown = 136
/datum/access/clown
	id = access_clown
	desc = "Clown Office"
	region = ACCESS_REGION_GENERAL

/var/const/access_tomfoolery = 137
/datum/access/tomfoolery
	id = access_tomfoolery
	desc = "Tomfoolery Closet"
	region = ACCESS_REGION_GENERAL
