//////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star April 2026: New instrument sounds //
//////////////////////////////////////////////////////////////////////

/datum/instrument/guitar
	name = "Generic guitar-like instrument"
	category = "Guitar"
	instrument_type = /datum/instrument/guitar

/datum/instrument/guitar/steel_crisis
	name = "Crisis Steel String Guitar"
	id = "csteelgt"
	real_samples = list("36"='sound/instruments/synthesis_samples/guitar/crisis_steel/c2.ogg',
				   "48"='sound/instruments/synthesis_samples/guitar/crisis_steel/c3.ogg',
				   "60"='sound/instruments/synthesis_samples/guitar/crisis_steel/c4.ogg',
				   "72"='sound/instruments/synthesis_samples/guitar/crisis_steel/c5.ogg')

/datum/instrument/guitar/nylon_crisis
	name = "Crisis Nylon String Guitar"
	id = "cnylongt"
	real_samples = list("36"='sound/instruments/synthesis_samples/guitar/crisis_nylon/c2.ogg',
				   "48"='sound/instruments/synthesis_samples/guitar/crisis_nylon/c3.ogg',
				   "60"='sound/instruments/synthesis_samples/guitar/crisis_nylon/c4.ogg',
				   "72"='sound/instruments/synthesis_samples/guitar/crisis_nylon/c5.ogg')

// RS Edit: Linux Fix (Lira, March 2026)
/datum/instrument/guitar/clean_crisis
	name = "Crisis Clean Guitar"
	id = "ccleangt"
	real_samples = list("36"='sound/instruments/synthesis_samples/guitar/crisis_clean/C2.ogg',
				   "48"='sound/instruments/synthesis_samples/guitar/crisis_clean/C3.ogg',
				   "60"='sound/instruments/synthesis_samples/guitar/crisis_clean/C4.ogg',
				   "72"='sound/instruments/synthesis_samples/guitar/crisis_clean/C5.ogg')

// RS Edit: Linux Fix (Lira, March 2026)
/datum/instrument/guitar/muted_crisis
	name = "Crisis Muted Guitar"
	id = "cmutedgt"
	real_samples = list("36"='sound/instruments/synthesis_samples/guitar/crisis_muted/C2.ogg',
				   "48"='sound/instruments/synthesis_samples/guitar/crisis_muted/C3.ogg',
				   "60"='sound/instruments/synthesis_samples/guitar/crisis_muted/C4.ogg',
				   "72"='sound/instruments/synthesis_samples/guitar/crisis_muted/C5.ogg')

// RS Add: New instruments (Lira, April 2026)
/datum/instrument/guitar/harmonics_fluid
	name = "FluidR3 Electric Guitar Harmonics"
	id = "r3harmgt"
	real_samples = list("28"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/e1.ogg',
				   "33"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/a1.ogg',
				   "38"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/d2.ogg',
				   "40"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/e2.ogg',
				   "43"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/g2.ogg',
				   "45"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/a2.ogg',
				   "47"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/b2.ogg',
				   "50"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/d3.ogg',
				   "55"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/g3.ogg',
				   "59"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/b3.ogg',
				   "64"='sound/instruments/synthesis_samples/guitar/fluid_harmonics/e4.ogg')

// RS Add: New instruments (Lira, April 2026)
/datum/instrument/guitar/jazz_fluid
	name = "FluidR3 Jazz Guitar"
	id = "r3jazzgt"
	real_samples = list("40"='sound/instruments/synthesis_samples/guitar/fluid_jazz/e2.ogg',
				   "43"='sound/instruments/synthesis_samples/guitar/fluid_jazz/g2.ogg',
				   "45"='sound/instruments/synthesis_samples/guitar/fluid_jazz/a2.ogg',
				   "48"='sound/instruments/synthesis_samples/guitar/fluid_jazz/c3.ogg',
				   "50"='sound/instruments/synthesis_samples/guitar/fluid_jazz/d3.ogg',
				   "54"='sound/instruments/synthesis_samples/guitar/fluid_jazz/fs3.ogg',
				   "55"='sound/instruments/synthesis_samples/guitar/fluid_jazz/g3.ogg',
				   "59"='sound/instruments/synthesis_samples/guitar/fluid_jazz/b3.ogg',
				   "64"='sound/instruments/synthesis_samples/guitar/fluid_jazz/e4.ogg',
				   "69"='sound/instruments/synthesis_samples/guitar/fluid_jazz/a4.ogg',
				   "74"='sound/instruments/synthesis_samples/guitar/fluid_jazz/d5.ogg',
				   "79"='sound/instruments/synthesis_samples/guitar/fluid_jazz/g5.ogg')

// RS Add: New instruments (Lira, April 2026)
/datum/instrument/guitar/overdrive_fluid
	name = "FluidR3 Overdriven Guitar"
	id = "r3overgt"
	real_samples = list("40"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/e2.ogg',
				   "45"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/a2.ogg',
				   "50"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/d3.ogg',
				   "55"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/g3.ogg',
				   "59"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/b3.ogg',
				   "64"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/e4.ogg',
				   "69"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/a4.ogg',
				   "71"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/b4.ogg',
				   "76"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/e5.ogg',
				   "79"='sound/instruments/synthesis_samples/guitar/fluid_overdrive/g5.ogg')

// RS Add: New instruments (Lira, April 2026)
/datum/instrument/guitar/distortion_fluid
	name = "FluidR3 Distortion Guitar"
	id = "r3distgt"
	real_samples = list("40"='sound/instruments/synthesis_samples/guitar/fluid_distortion/e2.ogg',
				   "45"='sound/instruments/synthesis_samples/guitar/fluid_distortion/a2.ogg',
				   "50"='sound/instruments/synthesis_samples/guitar/fluid_distortion/d3.ogg',
				   "55"='sound/instruments/synthesis_samples/guitar/fluid_distortion/g3.ogg',
				   "59"='sound/instruments/synthesis_samples/guitar/fluid_distortion/b3.ogg',
				   "64"='sound/instruments/synthesis_samples/guitar/fluid_distortion/e4.ogg',
				   "69"='sound/instruments/synthesis_samples/guitar/fluid_distortion/a4.ogg',
				   "71"='sound/instruments/synthesis_samples/guitar/fluid_distortion/b4.ogg',
				   "76"='sound/instruments/synthesis_samples/guitar/fluid_distortion/e5.ogg',
				   "79"='sound/instruments/synthesis_samples/guitar/fluid_distortion/g5.ogg')
