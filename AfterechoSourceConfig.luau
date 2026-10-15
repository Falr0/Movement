-- CS:S default movement target. Dimensions are Hammer units; world scale stays compatible with After Echo.
return table.freeze({
	Profile = "Counter-Strike: Source / default", Unit = 0.08, Tick = 0.015,
	MaxSpeed = 250, GroundAccelerate = 5, AirAccelerate = 10,
	Friction = 4, StopSpeed = 75, AirWishCap = 30,
	Gravity = 800, JumpImpulse = math.sqrt(2 * 800 * 57), MaxVelocity = 3500,
	WalkMultiplier = 0.52, DuckMultiplier = 0.34,
	HullWidth = 32, StandHeight = 72, DuckHeight = 54,
	StandEye = 64, DuckEye = 46, DuckTime = 0.4, UnduckTime = 0.2,
	StepHeight = 18, GroundProbe = 2, GroundNormal = 0.7,
	Skin = 0.03125, StopEpsilon = 0.1, NonJumpVelocity = 140,
	BunnyhopLimit = 1.2, AutoBunnyhop = false,
	-- Legacy CS stamina is a timer, not GO's additive 80-point pool.
	StaminaJumpCost = 25, StaminaRecover = 19, StaminaReferenceHz = 70,
})
