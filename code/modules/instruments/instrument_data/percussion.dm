///////////////////////////////////////////////////////
// Created by Lira for Rogue Star June 2026: Drumkit //
///////////////////////////////////////////////////////

/datum/instrument/percussion
	name = "Generic percussion instrument"
	category = "Percussion"
	instrument_type = /datum/instrument/percussion
	instrument_flags = INSTRUMENT_DO_NOT_AUTOSAMPLE

/datum/instrument/percussion/fluid_standard
	name = "FluidR3 Drum Kit"
	id = "r3drums"

/datum/instrument/percussion/fluid_standard/Initialize()
	. = ..()
	samples = list(
		"27" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/27_high_q.wav', 27, 0, 1),
		"28" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/28_slap.wav', 28, 0, 1),
		"29" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/29_scratch_push.wav', 29, 0, 1),
		"30" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/30_scratch_pull.wav', 30, 0, 1),
		"31" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/31_sticks.wav', 31, 0, 1),
		"32" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/32_square_click.wav', 32, 0, 1),
		"33" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/33_metronome_click.wav', 33, 0, 1),
		"34" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/34_metronome_bell.wav', 34, 0, 1),
		"35" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/35_acoustic_bass_drum.wav', 35, 0, 1),
		"36" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/36_bass_drum_1.wav', 36, 0, 1),
		"37" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/37_side_stick.wav', 37, 0, 1),
		"38" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/38_acoustic_snare.wav', 38, 0, 1),
		"39" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/39_hand_clap.wav', 39, 0, 1),
		"40" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/40_electric_snare.wav', 40, 0, 1),
		"41" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/41_low_floor_tom.wav', 41, 0, 1),
		"42" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/42_closed_hihat.wav', 42, 0, 1),
		"43" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/43_high_floor_tom.wav', 43, 0, 1),
		"44" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/44_pedal_hihat.wav', 44, 0, 1),
		"45" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/45_low_tom.wav', 45, 0, 1),
		"46" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/46_open_hihat.wav', 46, 0, 1),
		"47" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/47_low_mid_tom.wav', 47, 0, 1),
		"48" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/48_hi_mid_tom.wav', 48, 0, 1),
		"49" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/49_crash_cymbal_1.wav', 49, 0, 1),
		"50" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/50_high_tom.wav', 50, 0, 1),
		"51" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/51_ride_cymbal_1.wav', 51, 0, 1),
		"52" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/52_chinese_cymbal.wav', 52, 0, 1),
		"53" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/53_ride_bell.wav', 53, 0, 1),
		"54" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/54_tambourine.wav', 54, 0, 1),
		"55" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/55_splash_cymbal.wav', 55, 0, 1),
		"56" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/56_cowbell.wav', 56, 0, 1),
		"57" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/57_crash_cymbal_2.wav', 57, 0, 1),
		"58" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/58_vibraslap.wav', 58, 0, 1),
		"59" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/59_ride_cymbal_2.wav', 59, 0, 1),
		"60" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/60_high_bongo.wav', 60, 0, 1),
		"61" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/61_low_bongo.wav', 61, 0, 1),
		"62" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/62_mute_high_conga.wav', 62, 0, 1),
		"63" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/63_open_high_conga.wav', 63, 0, 1),
		"64" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/64_low_conga.wav', 64, 0, 1),
		"65" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/65_high_timbale.wav', 65, 0, 1),
		"66" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/66_low_timbale.wav', 66, 0, 1),
		"67" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/67_high_agogo.wav', 67, 0, 1),
		"68" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/68_low_agogo.wav', 68, 0, 1),
		"69" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/69_cabasa.wav', 69, 0, 1),
		"70" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/70_maracas.wav', 70, 0, 1),
		"71" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/71_short_whistle.wav', 71, 0, 1),
		"72" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/72_long_whistle.wav', 72, 0, 1),
		"73" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/73_short_guiro.wav', 73, 0, 1),
		"74" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/74_long_guiro.wav', 74, 0, 1),
		"75" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/75_claves.wav', 75, 0, 1),
		"76" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/76_high_wood_block.wav', 76, 0, 1),
		"77" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/77_low_wood_block.wav', 77, 0, 1),
		"78" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/78_mute_cuica.wav', 78, 0, 1),
		"79" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/79_open_cuica.wav', 79, 0, 1),
		"80" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/80_mute_triangle.wav', 80, 0, 1),
		"81" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/81_open_triangle.wav', 81, 0, 1),
		"82" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/82_shaker.wav', 82, 0, 1),
		"83" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/83_jingle_bell.wav', 83, 0, 1),
		"84" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/84_bell_tree.wav', 84, 0, 1),
		"85" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/85_castanets.wav', 85, 0, 1),
		"86" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/86_short_taiko.wav', 86, 0, 1),
		"87" = new /datum/instrument_key('sound/instruments/synthesis_samples/percussion/fluid_standard/87_long_taiko.wav', 87, 0, 1)
	)
