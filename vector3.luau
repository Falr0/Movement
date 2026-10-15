-- Small CLI-only Vector3 test double. Roblox uses its native Vector3 type.
local Vector3={}
local meta={}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},meta) end
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__unm(a) return Vector3.new(-a.X,-a.Y,-a.Z) end
function meta.__mul(a,b)
	if type(a)=='number' then a,b=b,a end
	return Vector3.new(a.X*b,a.Y*b,a.Z*b)
end
function meta.__div(a,b) return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
function meta.__index(v,k)
	if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
	if k=='Unit' then return v.Magnitude>0 and v/v.Magnitude or Vector3.zero end
	if k=='Dot' then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
	if k=='Cross' then return function(a,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
end
Vector3.zero=Vector3.new(0,0,0)
Vector3.xAxis=Vector3.new(1,0,0)
Vector3.yAxis=Vector3.new(0,1,0)
Vector3.zAxis=Vector3.new(0,0,1)
return Vector3
