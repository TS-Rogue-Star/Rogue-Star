//////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star April 2026: New instrument sounds //
//////////////////////////////////////////////////////////////////////

/datum/instrument/chromatic
	name = "Generic chromatic percussion instrument"
	category = "Chromatic percussion"
	instrument_type = /datum/instrument/chromatic

/datum/instrument/chromatic/vibraphone1
	name = "Crisis Vibraphone"
	id = "crvibr"
	real_samples = list("36"='sound/instruments/synthesis_samples/chromatic/vibraphone1/c2.ogg',
				   "48"='sound/instruments/synthesis_samples/chromatic/vibraphone1/c3.ogg',
				   "60"='sound/instruments/synthesis_samples/chromatic/vibraphone1/c4.ogg',
				   "72"='sound/instruments/synthesis_samples/chromatic/vibraphone1/c5.ogg')

/datum/instrument/chromatic/musicbox1
	name = "SGM Music Box"
	id = "sgmmbox"
	real_samples = list("36"='sound/instruments/synthesis_samples/chromatic/sgmbox/c2.ogg',
				   "48"='sound/instruments/synthesis_samples/chromatic/sgmbox/c3.ogg',
				   "60"='sound/instruments/synthesis_samples/chromatic/sgmbox/c4.ogg',
				   "72"='sound/instruments/synthesis_samples/chromatic/sgmbox/c5.ogg')

// RS Edit: Linux Fix (Lira, March 2026)
/datum/instrument/chromatic/fluid_celeste
	name = "FluidR3 Celeste"
	id = "r3celeste"
	real_samples = list("36"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C2.ogg',
				   "48"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C3.ogg',
				   "60"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C4.ogg',
				   "72"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C5.ogg',
				   "84"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C6.ogg',
				   "96"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C7.ogg',
				   "108"='sound/instruments/synthesis_samples/chromatic/fluid_celeste/C8.ogg')

// RS Add: New instruments (Lira, April 2026)
/datum/instrument/chromatic/fluid_xylophone
	name = "FluidR3 Xylophone"
	id = "r3xylo"
	real_samples = list("54"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/fs3.ogg',
				   "60"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/c4.ogg',
				   "66"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/fs4.ogg',
				   "72"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/c5.ogg',
				   "78"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/fs5.ogg',
				   "84"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/c6.ogg',
				   "90"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/fs6.ogg',
				   "96"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/c7.ogg',
				   "102"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/fs7.ogg',
				   "108"='sound/instruments/synthesis_samples/chromatic/fluid_xylophone/c8.ogg')
