-- Roblox collision adapter for the axis-aligned Source player hull.
local C=require(script.Parent.AfterechoSourceConfig)
local World={}
function World.new(character)
	local ray=RaycastParams.new()
	ray.FilterType=Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances={character,workspace.CurrentCamera}
	ray.RespectCanCollide=true
	ray.IgnoreWater=true
	local overlap=OverlapParams.new()
	overlap.FilterType=Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances={character,workspace.CurrentCamera}
	overlap.RespectCanCollide=true
	overlap.MaxParts=1
	local probe=Instance.new('Part')
	probe.Name='AfterechoHullClearance';probe.Anchored=true
	probe.Transparency=1;probe.CanCollide=false;probe.CanTouch=false;probe.CanQuery=false
	probe.Parent=workspace.CurrentCamera
	local adapter={}
	local skin=C.Skin*C.Unit
	local function box(position,height)
		return CFrame.new(position+Vector3.yAxis*(height/2+skin)),
			Vector3.new(C.HullWidth*C.Unit-2*skin,height-2*skin,C.HullWidth*C.Unit-2*skin)
	end
	function adapter.cast(position,height,delta)
		if delta.Magnitude<1e-8 then return nil end
		local cf,size=box(position,height)
		local hit=workspace:Blockcast(cf,size,delta,ray)
		if not hit then return nil end
		local friction=hit.Instance:GetAttribute('SourceFriction')
		return {Distance=hit.Distance,Normal=hit.Normal,Position=hit.Position,Instance=hit.Instance,
			Material=hit.Material,SurfaceFriction=type(friction)=='number' and math.clamp(friction,0,1) or 1}
	end
	function adapter.clear(position,height)
		local cf,size=box(position,height)
		probe.Size=size;probe.CFrame=cf
		return #workspace:GetPartsInPart(probe,overlap)==0
	end
	function adapter.destroy() probe:Destroy() end
	return adapter
end
return World
