#define CABLE_LAYER_ALL (~0)
#define CABLE_LAYER_1 (1<<0)
	#define CABLE_LAYER_1_NAME "Red Power Line"
#define CABLE_LAYER_2 (1<<1)
	#define CABLE_LAYER_2_NAME "Yellow Power Line"
#define CABLE_LAYER_3 (1<<2)
	#define CABLE_LAYER_3_NAME "Blue Power Line"

#define SOLAR_TRACK_OFF 0
#define SOLAR_TRACK_TIMED 1
#define SOLAR_TRACK_AUTO 2

/// Converts cable layer to its human readable name
GLOBAL_LIST_INIT(cable_layer_to_name, list(
	"[CABLE_LAYER_1]" = CABLE_LAYER_1_NAME,
	"[CABLE_LAYER_2]" = CABLE_LAYER_2_NAME,
	"[CABLE_LAYER_3]" = CABLE_LAYER_3_NAME
))

/// Converts cable color name to its layer
GLOBAL_LIST_INIT(cable_name_to_layer, list(
	CABLE_LAYER_1_NAME = CABLE_LAYER_1,
	CABLE_LAYER_2_NAME = CABLE_LAYER_2,
	CABLE_LAYER_3_NAME = CABLE_LAYER_3
	))

/// Cable layer colors for easier editing later
/// IF YOU CHANGE THESE YOU NEED TO UPDATE THE RADIAL MENUS FOR RCL AND CABLES TO THOSE COLORS IN icons/hud/radial.dmi
/// Also update the names at the top of this file!
#define CABLELAYERONECOLOR		COLOR_RED
#define CABLELAYERTWOCOLOR		COLOR_YELLOW
#define CABLELAYERTHREECOLOR	COLOR_BLUE

#define MAXCOIL 30

var/global/defer_powernet_rebuild = 0      // True if net rebuild will be called manually after an event.

GLOBAL_LIST_INIT(possible_cable_coil_colours, list(
		"White" = COLOR_WHITE,
		"Silver" = COLOR_SILVER,
		"Gray" = COLOR_GRAY,
		"Black" = COLOR_BLACK,
		"Red" = COLOR_RED,
		"Maroon" = COLOR_MAROON,
		"Yellow" = COLOR_YELLOW,
		"Olive" = COLOR_OLIVE,
		"Lime" = COLOR_GREEN,
		"Green" = COLOR_LIME,
		"Cyan" = COLOR_CYAN,
		"Teal" = COLOR_TEAL,
		"Blue" = COLOR_BLUE,
		"Navy" = COLOR_NAVY,
		"Pink" = COLOR_PINK,
		"Purple" = COLOR_PURPLE,
		"Orange" = COLOR_ORANGE,
		"Beige" = COLOR_BEIGE,
		"Brown" = COLOR_BROWN
	))
///SMES Unit defines to avoid magic numbers
#define SMESMAXCHARGELEVEL	250 KILOWATTS
#define SMESSTARTCHARGELVL	50 KILOWATTS
#define SMESMAXOUTPUT		250 KILOWATTS
#define SMESSTARTOUTLVL		50 KILOWATTS
#define SMESHEALTHPOOL		500
#define SMESRATE			0.05	// rate of internal charge to external power
#define SMESMAXCOIL			6		//Maxmimum Coil number
#define SMESDEFAULTSTART	1		//Starting number of coils

///Power cell
#define CELLRATE 0.002 // Multiplier for watts per tick <> cell storage (e.g., 0.02 means if there is a load of 1000 watts, 20 units will be taken from a cell per second)
                       // It's a conversion constant. power_used*CELLRATE = charge_provided, or charge_used/CELLRATE = power_provided
#define CELLDEFAULTMAX 1 KILOWATTS
///Fancy maths with watts that doesn't really matter with some other people's weird as fuck math.
#define WATTS 		*1
#define KILOWATTS 	*1000
#define MEGAWATTS 	*1000000
#define GIGAWATTS 	*1000000000

///siemens_coefficient ratings to reduce confusing magic number values
#define SIEMENS_RESISTANCE_FULL				0
#define SIEMENS_RESISTANCE_THREEQUARTER		0.25
#define SIEMENS_RESISTANCE_HALF				0.5
#define SIEMENS_RESISTANCE_QUARTER			0.75
#define SIEMENS_RESISTANCE_TENTH			0.9
#define SIEMENS_RESISTANCE_NONE				1
#define SIEMENS_RESISTANCE_NONEPOINTFIVE	1.5
#define SIEMENS_RESISTANCE_NONEDOUBLE		2
#define SIEMENS_RESISTANCE_NONETRIPLE		3
