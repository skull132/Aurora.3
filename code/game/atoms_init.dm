/atom
	var/initialized = FALSE

/atom/New(loc, ...)
	//. = ..() //uncomment if you are dumb enough to add a /datum/New() proc

	var/do_initialize = SSatoms.initialized
	if(do_initialize > INITIALIZATION_INSSATOMS)
		args[1] = do_initialize == INITIALIZATION_INNEW_MAPLOAD
		if(SSatoms.InitAtom(src, args))
			//we were deleted
			return
	
	var/list/created = SSatoms.created_atoms
	if(created)
		created += src

/atom/proc/Initialize(mapload, ...)
	if(initialized)
		crash_with("Warning: [src]([type]) initialized multiple times!")
	initialized = TRUE

	if (light_power && light_range)
		update_light()

	if (opacity && isturf(loc))
		var/turf/T = loc
		T.has_opaque_atom = TRUE // No need to recalculate it in this case, it's guaranteed to be on afterwards anyways.

	return INITIALIZE_HINT_NORMAL

//called if Initialize returns INITIALIZE_HINT_LATELOAD
//This version shouldn't be called
/atom/proc/LateInitialize()
	var/static/list/warned_types = list()
	if(!warned_types[type])
		WARNING("Old style LateInitialize behaviour detected in [type]!")
		warned_types[type] = TRUE
	Initialize(FALSE)
