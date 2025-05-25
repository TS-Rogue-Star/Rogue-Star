/obj/item/device/radio/phone
	subspace_transmission = 1
	canhear_range = 0
	adhoc_fallback = TRUE

/obj/item/device/radio/emergency
	name = "Medbay Emergency Radio Link"
	icon_state = "med_walkietalkie"
	frequency = MED_I_FREQ
	subspace_transmission = 1
	adhoc_fallback = TRUE

/obj/item/device/radio/emergency/New()
	..()
	internal_channels = default_medbay_channels.Copy()


/obj/item/device/bluespaceradio/station_prelinked	//RS EDIT START
	name = "bluespace radio"
	handset = /obj/item/device/radio/bluespacehandset/linked/station_prelinked

/obj/item/device/radio/bluespacehandset/linked/station_prelinked
	bs_tx_preload_id = "station_rx" //Transmit to a receiver
	bs_rx_preload_id = "station_tx" //Recveive from a transmitter	//RS EDIT END

/obj/item/device/bluespaceradio/talon_prelinked
	name = "bluespace radio (talon)"
	handset = /obj/item/device/radio/bluespacehandset/linked/talon_prelinked

/obj/item/device/radio/bluespacehandset/linked/talon_prelinked
	bs_tx_preload_id = "talon_aio" //Transmit to a receiver
	bs_rx_preload_id = "talon_aio" //Recveive from a transmitter

// #### Hub #### //RS EDIT START - Moved these from the map specific files
/obj/machinery/telecomms/hub/preset/station
	id = "Hub"
	network = "tcommsat"
	autolinkers = list("hub","s_relay",
		"station_relay", "c_relay", "m_relay", "r_relay",
		"science", "medical", "supply", "service", "common", "command", "engineering", "security", "Away Team", "unused",
		"hb_relay", "receiverA", "broadcasterA"
	)

/obj/machinery/telecomms/receiver/preset_right/station
	id = "station_rx"
	freq_listening = list(AI_FREQ, SCI_FREQ, MED_FREQ, SUP_FREQ, SRV_FREQ, COMM_FREQ, ENG_FREQ, SEC_FREQ, ENT_FREQ, EXP_FREQ)

/obj/machinery/telecomms/broadcaster/preset_right/station
	id = "station_tx"

/obj/machinery/telecomms/bus/preset_two/station
	freq_listening = list(SUP_FREQ, SRV_FREQ, EXP_FREQ)

/obj/machinery/telecomms/server/presets/service/station
	freq_listening = list(SRV_FREQ, EXP_FREQ)
	autolinkers = list("service", "Away Team")

/obj/item/device/multitool/station_buffered
	name = "pre-linked multitool"
	desc = "This multitool has already been linked to the station telecomms hub and can be used to configure one (1) relay."

/obj/item/device/multitool/station_buffered/Initialize()
	. = ..()
	buffer = locate(/obj/machinery/telecomms/hub/preset/station)

//RS EDIT END
