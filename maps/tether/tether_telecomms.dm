// ### Preset machines  ###


// #### Relays ####
// Telecomms doesn't know about connected z-levels, so we need relays even for the other surface levels.

// Telecommunications Satellite
/area/tether/surfacebase/tcomms
	name = "\improper Telecomms"
	ambience = list('sound/ambience/ambisin2.ogg', 'sound/ambience/signal.ogg', 'sound/ambience/signal.ogg')

/area/tether/surfacebase/tcomms/entrance
	name = "\improper Telecomms Teleporter"
	icon_state = "tcomsatentrance"

/area/tether/surfacebase/tcomms/foyer
	name = "\improper Telecomms Foyer"
	icon_state = "tcomsatfoyer"

/area/tether/surfacebase/tcomms/storage
	name = "\improper Telecomms Storage"
	icon_state = "tcomsatwest"

/area/tether/surfacebase/tcomms/computer
	name = "\improper Telecomms Control Room"
	icon_state = "tcomsatcomp"

/area/tether/surfacebase/tcomms/chamber
	name = "\improper Telecomms Central Compartment"
	icon_state = "tcomsatcham"
	flags = BLUE_SHIELDED

/area/maintenance/substation/tcomms
	name = "\improper Telecomms Substation"

/area/maintenance/station/tcomms
	name = "\improper Telecoms Maintenance"

/datum/map/tether/default_internal_channels()
	return list(
		num2text(PUB_FREQ) = list(),
		num2text(AI_FREQ)  = list(access_synth),
		num2text(ENT_FREQ) = list(),
		num2text(ERT_FREQ) = list(access_cent_specops),
		num2text(COMM_FREQ)= list(access_heads),
		num2text(ENG_FREQ) = list(access_engine_equip, access_atmospherics),
		num2text(MED_FREQ) = list(access_medical_equip),
		num2text(MED_I_FREQ)=list(access_medical_equip),
		num2text(SEC_FREQ) = list(access_security),
		num2text(SEC_I_FREQ)=list(access_security),
		num2text(SCI_FREQ) = list(access_tox,access_robotics,access_xenobiology),
		num2text(SUP_FREQ) = list(access_cargo),
		num2text(SRV_FREQ) = list(access_janitor, access_hydroponics),
		num2text(EXP_FREQ) = list(access_explorer)
	)
