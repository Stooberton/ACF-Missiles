local ClassName = "Laser"
ACF = ACF or {}
ACF.Guidance = ACF.Guidance or {}
ACF.Guidance[ClassName] = ACF.Guidance[ClassName] or inherit.NewSubOf(ACF.Guidance.Wire)

local Guidance = ACF.Guidance[ClassName]
local MinimumDistance = 3150 * 3150 -- Minimum aiming distance (80m)

local function GetWireTarget(GuidanceData)
	local Outputs = GuidanceData.Source.Outputs
	local TargetOutput = Outputs.Target
	local PosOutput = Outputs.Position
	local TargetPos

	if TargetOutput and IsValid(TargetOutput.Value) then
		TargetPos = TargetOutput.Value:GetPos()
	elseif PosOutput and PosOutput.Value ~= Vector() then
		TargetPos = PosOutput.Value
	end

	return TargetPos
end

local function GetPositionDot(Missile, Position)
	local Direction = Missile:GetForward()
	local Dot = Direction.Dot
	local TargetPos = Position - Missile:GetPos()

	return Dot(Direction, TargetPos:GetNormalized())
end

local function GetTargetLOSDistance(Missile, Position)
	local TraceData = {
		start = Missile:GetPos(),
		endpos = Position,
		mask = MASK_SOLID_BRUSHONLY,
		filter = {Missile}
	}

	local Trace = util.TraceLine(TraceData)
	local TraceDist = Trace.StartPos:DistToSqr(Trace.HitPos)

	return Trace.Hit and TraceDist >= MinimumDistance
end

function Guidance:Init()
	self.Name = ClassName
	self.ViewCone = 30 -- Cone to retain targets within.
	self.desc = "This guidance package reads a target-position from the launcher and guides the munition towards it."
end

function Guidance:Configure(Missile)
	self:super().Configure(self, Missile)
	self.ViewCone = ACF_GetGunValue(Missile.BulletData, "viewcone") or self.ViewCone
	self.ViewConeCos = math.cos(math.rad(self.ViewCone))
end

function Guidance:GetGuidance(Missile)
	local AimPos = GetWireTarget(self)
	local TargetPos

	if AimPos then
		local AimPosDot = GetPositionDot(Missile, AimPos)
		local OnDistance = GetTargetLOSDistance(Missile, AimPos)

		if AimPosDot >= self.ViewConeCos and OnDistance then
			TargetPos = AimPos
		end
	end

	self.TargetPos = TargetPos

	return {
		TargetPos = TargetPos,
		ViewCone = TargetPos and self.ViewCone or nil
	}
end

function Guidance:GetDisplayConfig()
	return {
		Tracking = math.Round(self.ViewCone * 2, 1) .. " deg"
	}
end