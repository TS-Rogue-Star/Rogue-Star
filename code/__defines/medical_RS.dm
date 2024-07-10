/*
	These Variables are used for easily rebalancing surgery surfaces, if you wish to make a surface capable of surgery, provide the following to the object's class definition;
	surgery_mult = SURGERY_MULT_GOOD // Just replace SURGERY_MULT_GOOD with whichever variable you want.
	You can also manually set the variable to any number you want if you desire it be a special case.
*/

#define SURGERY_MULT_BEST 	2 		// For Surgery Tables
#define SURGERY_MULT_BETTER 0.75	// This is used for Advanced Roller Beds
#define SURGERY_MULT_GOOD 	0.5		// This is used for Regular Roller Beds
#define SURGERY_MULT_BAD 	0.25	// This is used for tables
