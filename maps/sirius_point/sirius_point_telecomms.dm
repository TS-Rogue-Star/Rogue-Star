// ### Preset machines  ###

// #### Relays ####
// Telecomms doesn't know about connected z-levels, so we need relays even for the other surface levels.
/obj/machinery/telecomms/relay/preset/station
	id = "SP Relay"
	autolinkers = list("sp_relay")

// #### Hub ####
/obj/machinery/telecomms/hub/preset/sp
	id = "Hub"
	network = "tcommsat"
	autolinkers = list("hub",
		"sp_relay", "c_relay", "m_relay", "r_relay",
		"science", "medical", "supply", "service", "common", "command", "engineering", "security", "Away Team", "unused",
		"hb_relay", "receiverA", "broadcasterA"
	)

/obj/machinery/telecomms/receiver/preset_right/sp
	id = "sp_rx"
	freq_listening = list(AI_FREQ, SCI_FREQ, MED_FREQ, SUP_FREQ, SRV_FREQ, COMM_FREQ, ENG_FREQ, SEC_FREQ, ENT_FREQ, EXP_FREQ)

/obj/machinery/telecomms/broadcaster/preset_right/sp
	id = "sp_tx"

/obj/machinery/telecomms/bus/preset_two/sp
	freq_listening = list(SUP_FREQ, SRV_FREQ, EXP_FREQ)

/obj/machinery/telecomms/server/presets/service/sp
	freq_listening = list(SRV_FREQ, EXP_FREQ)
	autolinkers = list("service", "Away Team")

// Telecommunications Satellite
/area/sp/surfacebase/tcomms
	name = "\improper Telecomms"
	ambience = list('sound/ambience/ambisin2.ogg', 'sound/ambience/signal.ogg', 'sound/ambience/signal.ogg')

/area/sp/surfacebase/tcomms/entrance
	name = "\improper Telecomms Teleporter"
	icon_state = "tcomsatentrance"

/area/sp/surfacebase/tcomms/foyer
	name = "\improper Telecomms Foyer"
	icon_state = "tcomsatfoyer"

/area/sp/surfacebase/tcomms/storage
	name = "\improper Telecomms Storage"
	icon_state = "tcomsatwest"

/area/sp/surfacebase/tcomms/computer
	name = "\improper Telecomms Control Room"
	icon_state = "tcomsatcomp"

/area/sp/surfacebase/tcomms/chamber
	name = "\improper Telecomms Central Compartment"
	icon_state = "tcomsatcham"
	flags = BLUE_SHIELDED

/area/maintenance/substation/tcomms
	name = "\improper Telecomms Substation"

/area/maintenance/station/tcomms
	name = "\improper Telecoms Maintenance"

/datum/map/sp/default_internal_channels()
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

/obj/item/device/multitool/moonbase_buffered
	name = "pre-linked multitool (sp hub)"
	desc = "This multitool has already been linked to the SP telecomms hub and can be used to configure one (1) relay."

/obj/item/device/multitool/station_buffered/Initialize()
	. = ..()
	buffer = locate(/obj/machinery/telecomms/hub/preset/sp)

/obj/item/device/bluespaceradio/sp_prelinked
	name = "bluespace radio (Stellar Delight)"
	handset = /obj/item/device/radio/bluespacehandset/linked/sp_prelinked

/obj/item/device/radio/bluespacehandset/linked/sp_prelinked
	bs_tx_preload_id = "sp_rx" //Transmit to a receiver
	bs_rx_preload_id = "sp_tx" //Recveive from a transmitter
