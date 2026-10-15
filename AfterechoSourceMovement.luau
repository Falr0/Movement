-- Original Luau implementation of Source movement equations.
-- All simulation runs at Config.Tick. Physics is independent of the renderer and Humanoid motor.
-- Collision adapter contract: cast(feet, height, displacement), clear(feet, height).
local C = require(script.Parent.AfterechoSourceConfig)
local M = {Config = C}
local U, UP = C.Unit, Vector3.yAxis
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
M.flat = flat

function M.friction(v, dt, surface)
	local speed = flat(v).Magnitude
	if speed < C.StopEpsilon * U then return Vector3.new(0, v.Y, 0) end
	local nextSpeed = math.max(0, speed - math.max(speed, C.StopSpeed * U) * C.Friction * surface * dt)
	local h = flat(v) * (nextSpeed / speed)
	return Vector3.new(h.X, v.Y, h.Z)
end

function M.accelerate(v, direction, wishSpeed, acceleration, dt, surface, cap)
	-- Limit the projected component, never the magnitude of the whole velocity.
	local remaining = math.min(wishSpeed, cap or wishSpeed) - v:Dot(direction)
	if remaining <= 0 then return v end
	return v + direction * math.min(remaining, acceleration * wishSpeed * dt * surface)
end

function M.clip(v, normal)
	local result = v - normal * v:Dot(normal)
	return Vector3.new(math.abs(result.X) < C.StopEpsilon*U and 0 or result.X,
		math.abs(result.Y) < C.StopEpsilon*U and 0 or result.Y,
		math.abs(result.Z) < C.StopEpsilon*U and 0 or result.Z)
end

function M.new(feet)
	return {position=feet, previous=feet, velocity=Vector3.zero, grounded=false, ground=nil,
		ducked=false, duckFraction=0, jumpHeld=false, stamina=0, surface=1,
		ticks=0, jumpCount=0, landCount=0, landingSpeed=0, accumulator=0}
end

function M.slide(position, velocity, height, dt, world)
	local remaining, original, planes, blocked = dt, velocity, {}, false
	for _ = 1, 4 do
		if velocity.Magnitude < 1e-7 then break end
		local displacement = velocity * remaining
		local hit = world.cast(position, height, displacement)
		if not hit then position += displacement; break end
		blocked = true
		local travel = math.max(0, hit.Distance - C.Skin*U)
		local fraction = math.clamp(travel / displacement.Magnitude, 0, 1)
		position += displacement * fraction
		if fraction > 0 then planes = {}; original = velocity end
		remaining *= 1-fraction
		table.insert(planes, hit.Normal)
		local candidate
		for _, plane in ipairs(planes) do
			local clipped = M.clip(original, plane)
			local valid = true
			for _, other in ipairs(planes) do
				if clipped:Dot(other) < -1e-6 then valid=false; break end
			end
			if valid then candidate=clipped; break end
		end
		if candidate then velocity=candidate
		elseif #planes==2 then
			local crease=planes[1]:Cross(planes[2])
			velocity=crease.Magnitude>1e-6 and crease.Unit*original:Dot(crease.Unit) or Vector3.zero
		else velocity=Vector3.zero end
		if velocity:Dot(original) <= 0 then velocity=Vector3.zero; break end
	end
	return position, velocity, blocked
end

local function move(s, dt, world)
	local height=(s.ducked and C.DuckHeight or C.StandHeight)*U
	local start, velocity=s.position,s.velocity
	local low,lowV,blocked=M.slide(start,velocity,height,dt,world)
	if not s.grounded or not blocked then s.position=low;s.velocity=lowV;return end
	-- Compare sliding against stepping, keeping whichever advances farther horizontally.
	local rise=UP*C.StepHeight*U
	local upHit=world.cast(start,height,rise)
	local upDistance=upHit and math.max(0,upHit.Distance-C.Skin*U) or rise.Magnitude
	local high,highV=M.slide(start+UP*upDistance,velocity,height,dt,world)
	local down=world.cast(high,height,-UP*(upDistance+C.GroundProbe*U))
	if down and down.Normal.Y>=C.GroundNormal then
		high-=UP*math.max(0,down.Distance-C.Skin*U)
		if flat(high-start).Magnitude>flat(low-start).Magnitude then
			s.position=high;s.velocity=Vector3.new(highV.X,lowV.Y,highV.Z);return
		end
	end
	s.position=low;s.velocity=lowV
end

local function categorize(s, world, snapDistance)
	local oldGround=s.grounded
	s.grounded=false;s.ground=nil
	if s.velocity.Y>C.NonJumpVelocity*U then s.surface=1;return end
	local height=(s.ducked and C.DuckHeight or C.StandHeight)*U
	local hit=world.cast(s.position,height,-UP*snapDistance)
	if hit and hit.Normal.Y>=C.GroundNormal then
		s.grounded=true;s.ground=hit
		s.position-=UP*math.max(0,hit.Distance-C.Skin*U)
		s.surface=hit.SurfaceFriction or 1
		if not oldGround then s.landingSpeed=math.max(0,-s.velocity.Y);s.landCount+=1 end
		s.velocity=flat(s.velocity)
	else
		-- Source's reduced surface friction near the rising jump apex (dead-strafe).
		s.surface=(s.velocity.Y>0 and s.velocity.Y<C.NonJumpVelocity*U) and 0.25 or 1
	end
end

local function duck(s, requested, dt, world)
	local change=(C.StandHeight-C.DuckHeight)*U
	if requested then
		s.duckFraction=math.min(1,s.duckFraction+dt/C.DuckTime)
		if not s.ducked and (not s.grounded or s.duckFraction>=1) then
			if not s.grounded then s.position+=UP*change end -- keep head fixed while tucking feet
			s.ducked=true;s.duckFraction=1
		end
	else
		local target=s.position-(not s.grounded and s.ducked and UP*change or Vector3.zero)
		if not s.ducked or world.clear(target,C.StandHeight*U) then
			if s.ducked then s.position=target;s.ducked=false end
			s.duckFraction=math.max(0,s.duckFraction-dt/C.UnduckTime)
		else s.duckFraction=1 end
	end
end

function M.tick(s, command, world)
	local dt=C.Tick
	s.previous=s.position;s.landingSpeed=0;s.ticks+=1
	s.stamina=math.max(0,s.stamina-dt*1000)
	categorize(s,world,C.GroundProbe*U)
	duck(s,command.duck==true,dt,world)
	local top=math.clamp(command.maxSpeed or C.MaxSpeed,1,C.MaxVelocity)*U
	local jump=command.jump==true and (not s.jumpHeld or C.AutoBunnyhop)
	s.jumpHeld=command.jump==true
	local jumped=false
	if jump and s.grounded and not command.blocked then
		local cap=top*C.BunnyhopLimit
		local speed=flat(s.velocity).Magnitude
		if speed>cap then s.velocity=flat(s.velocity)*(cap/speed) end
		local factor=math.clamp(1-(s.stamina/1000*C.StaminaRecover)/100,0,1)
		s.velocity=flat(s.velocity)+UP*(C.JumpImpulse*U*factor)
		s.stamina=1000*C.StaminaJumpCost/C.StaminaRecover
		s.grounded=false;s.ground=nil;s.surface=1;s.jumpCount+=1;jumped=true
	end
	local direction=flat(command.direction or Vector3.zero)
	if direction.Magnitude>0 then direction=direction.Unit end
	local amount=math.clamp(command.amount or 0,0,1)
	if command.blocked then direction=Vector3.zero;amount=0 end
	local wish=top*amount
	if s.ducked then wish*=C.DuckMultiplier elseif command.walk then wish*=C.WalkMultiplier end
	if s.grounded then
		if s.stamina>0 then
			local ratio=math.clamp(1-(s.stamina/1000*C.StaminaRecover)/100,0,1)
			s.velocity*=ratio^(dt*C.StaminaReferenceHz)
		end
		s.velocity=M.friction(flat(s.velocity),dt,s.surface)
		s.velocity=M.accelerate(s.velocity,direction,wish,C.GroundAccelerate,dt,s.surface)
	else
		s.velocity-=UP*(C.Gravity*U*dt*0.5)
		s.velocity=M.accelerate(s.velocity,direction,wish,C.AirAccelerate,dt,s.surface,C.AirWishCap*U)
	end
	local wasGround=s.grounded
	local max=C.MaxVelocity*U
	s.velocity=Vector3.new(math.clamp(s.velocity.X,-max,max),math.clamp(s.velocity.Y,-max,max),math.clamp(s.velocity.Z,-max,max))
	local falling=math.max(0,-s.velocity.Y)
	move(s,dt,world)
	local snap=(wasGround and C.StepHeight or C.GroundProbe)*U
	-- Never snap an ascending jump back to the floor.
	if jumped or s.velocity.Y>0 then snap=C.Skin*U end
	categorize(s,world,snap)
	if s.grounded then
		if not wasGround and not jumped then s.landingSpeed=falling end
		s.velocity=flat(s.velocity)
	else s.velocity-=UP*(C.Gravity*U*dt*0.5) end
	return s
end

function M.advance(s, elapsed, command, world)
	s.accumulator+=math.max(0,elapsed)
	local count=0
	while s.accumulator+1e-9>=C.Tick and count<32 do
		M.tick(s,command,world);s.accumulator-=C.Tick;count+=1
	end
	-- Retain fractional time. Bound backlog after a debugger pause without a huge teleport.
	if s.accumulator>C.Tick*32 then s.accumulator=C.Tick*32 end
	return count,math.clamp(s.accumulator/C.Tick,0,1)
end
return M
