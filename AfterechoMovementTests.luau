-- Deterministic regression checks, independent from Roblox's dynamic solver.
return function(M)
	local C=M.Config;local U=C.Unit;local checks={}
	local function check(name,condition,value)
		table.insert(checks,{name=name,passed=condition,value=value})
	end
	local function near(a,b) return math.abs(a-b)<0.0001 end
	local plane={clear=function() return true end}
	function plane.cast(pos,height,d)
		if d.Y<0 and pos.Y+d.Y<=0 then
			return {Distance=d.Magnitude*math.max(0,pos.Y/-d.Y),Normal=Vector3.yAxis,SurfaceFriction=1}
		end
	end
	local run={direction=Vector3.xAxis,amount=1,maxSpeed=250}
	local s=M.new(Vector3.zero)
	M.tick(s,run,plane)
	check('first ground tick = 18.75 u/s',near(s.velocity.X/U,18.75),s.velocity.X/U)
	for _=1,200 do M.tick(s,run,plane) end
	check('run speed = 250 u/s',near(s.velocity.X/U,250),s.velocity.X/U)
	local friction=M.friction(Vector3.xAxis*250*U,C.Tick,1)
	check('one friction tick = 235 u/s',near(friction.X/U,235),friction.X/U)
	local function stopTicks(reverse)
		local state=M.new(Vector3.zero);state.velocity=Vector3.xAxis*250*U
		for i=1,200 do
			M.tick(state,{direction=-Vector3.xAxis,amount=reverse and 1 or 0},plane)
			if state.velocity.X<=0.001 then return i end
		end
		return 200
	end
	local counter,coast=stopTicks(true),stopTicks(false)
	check('counterstrafe brakes faster than release',counter<coast,{counter=counter,coast=coast})
	local air=M.accelerate(Vector3.xAxis*350*U,Vector3.zAxis,250*U,10,C.Tick,1,30*U)
	check('air cap is a projection, preserves perpendicular speed',near(air.X/U,350) and near(air.Z/U,30),air.Magnitude/U)
	local dead=M.accelerate(Vector3.zero,Vector3.xAxis,250*U,10,C.Tick,0.25,30*U)
	check('air surface friction scales acceleration',near(dead.X/U,9.375),dead.X/U)
	for _,spec in ipairs({{'walk',0.52},{'duck',0.34}}) do
		local state=M.new(Vector3.zero)
		for _=1,200 do M.tick(state,{direction=Vector3.xAxis,amount=1,walk=spec[1]=='walk',duck=spec[1]=='duck'},plane) end
		check(spec[1]..' speed',near(state.velocity.X/U,250*spec[2]),state.velocity.X/U)
	end
	local jump=M.new(Vector3.zero);local peak=0
	for _=1,180 do M.tick(jump,{jump=true},plane);peak=math.max(peak,jump.position.Y/U) end
	check('jump apex near 57 Hammer units',math.abs(peak-57)<0.1,peak)
	check('held jump does not autobhop',jump.jumpCount==1,jump.jumpCount)
	check('jump lands',jump.grounded and math.abs(jump.position.Y)<0.01,jump.position.Y)
	local expected
	for _,fps in ipairs({30,60,144,240}) do
		local state=M.new(Vector3.zero)
		for _=1,fps*3 do M.advance(state,1/fps,run,plane) end
		expected=expected or state.position
		check('fixed ticks at '..fps..' render fps',state.ticks==200 and (state.position-expected).Magnitude<1e-5,{ticks=state.ticks,x=state.position.X})
	end
	local duck=M.new(Vector3.zero)
	for _=1,40 do M.tick(duck,{duck=true},plane) end
	local low={cast=plane.cast,clear=function() return false end}
	M.tick(duck,{},low)
	check('cannot stand through a low ceiling',duck.ducked,duck.ducked)
	M.tick(duck,{},plane)
	check('stands when clearance is available',not duck.ducked,duck.ducked)
	local diagonal=M.new(Vector3.zero)
	for _=1,200 do M.tick(diagonal,{direction=Vector3.new(1,0,1).Unit,amount=1},plane) end
	check('diagonal speed has no input boost',near(diagonal.velocity.Magnitude/U,250),diagonal.velocity.Magnitude/U)
	local fail=0;for _,v in ipairs(checks) do if not v.passed then fail+=1 end end
	return {passed=#checks-fail,failed=fail,checks=checks}
end
