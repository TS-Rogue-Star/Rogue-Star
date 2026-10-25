//////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Mob Deletion Optimization //
//////////////////////////////////////////////////////////////////////////////

/**
 * @file hooks.dm
 * Implements hooks, a simple way to run code on pre-defined events.
 */

/** @page hooks Code hooks
 * @section hooks Hooks
 * A hook is defined under /hook in the type tree.
 *
 * To add some code to be called by the hook, define a proc under the type, as so:
 * @code
/hook/foo/proc/bar()
	if(1)
		return 1 //Sucessful
	else
		return 0 //Error, or runtime.
 * @endcode
 * All hooks must return nonzero on success, as runtimes will force return null.
 */

/**
 * Calls a hook, executing every piece of code that's attached to it.
 * @param hook	Identifier of the hook to call.
 * @returns		1 if all hooked code runs successfully, 0 otherwise.
 */

// RS Edit: Mob Deletion Optimization (Lira, September 2026)
/proc/callHook(hook, list/args=null)
	var/hook_path = text2path("/hook/[hook]")
	if(!hook_path)
		error("Invalid hook '/hook/[hook]' called.")
		return 0

	var/hook_caller = new hook_path
	var/status = 1
	for(var/P in typesof("[hook_path]/proc"))
		var/result = callHookCallback(hook_caller, P, args)
		if(!result)
			error("Hook '[P]' failed or runtimed.")
			status = 0

	return status

// RS Edit: Mob Deletion Optimization (Lira, September 2026)
/proc/callHookCallback(hook_caller, callback, list/arguments)
	var/list/callback_arguments = arguments ? arguments.Copy() : list()
	try
		. = call(hook_caller, callback)(arglist(callback_arguments))
	catch(var/exception/E)
		callback_arguments.Cut()
		throw E
	callback_arguments.Cut()
