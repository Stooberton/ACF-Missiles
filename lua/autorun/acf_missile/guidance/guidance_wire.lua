local ClassName = "Wire"
ACF = ACF or {}
ACF.Guidance = ACF.Guidance or {}
ACF.Guidance[ClassName] = ACF.Guidance[ClassName] or inherit.NewSubOf(ACF.Guidance.Dumb)

local Guidance = ACF.Guidance[ClassName]
local WireLength = 31496 * 31496 -- Length of the guidance wire (800m)

local function GetWireTarget(GuidanceData)
	local Outputs = GuidanceData.Source.Outputs
	local TargetOutput = Outputs.Target
	local PosOutput = Outputs.Position
	local TargetPos

	if PosOutput and PosOutput.Value ~= Vector() then
		TargetPos = PosOutput.Value
	elseif TargetOutput and IsValid(TargetOutput.Value) then
		TargetPos = TargetOutput.Value:GetPos()
	end

	return TargetPos
end

local function GetRackAimPos(Launcher, Missile)
	local Trace = util.QuickTrace(
		Launcher:GetPos(),
		Launcher:GetForward() * 50000,
		{Launcher, Missile}
	)

	return Trace.HitPos
end

function Guidance:Init()
	self.Name = ClassName
	self.desc = "This guidance package is controlled by the Launcher, which reads a target-position and steers the munition towards it."
end

function Guidance:Configure(Missile)
	self.Source = Missile.Launcher
end

function Guidance:GetGuidance(Missile)
	if not IsValid(self.Source) then return {} end
	if Missile.WireSnapped then return {} end
	local Launcher = self.Source
	local SourcePos = Launcher:GetPos()
	local MissileDist = Missile:GetPos():DistToSqr(SourcePos) -- We're using squared distance to optimise

	if MissileDist > WireLength then
		local SoundName = "physics/shield/bullet_hit_shield_0" .. math.random(7) .. ".wav"
		sound.Play(SoundName, SourcePos, 75, 100, 1)

		Missile.WireSnapped = true

		return {
			TargetPos = nil
		}
	end

	local AimPos = GetWireTarget(self) or GetRackAimPos(Launcher, Missile)
	local AimDist = AimPos:DistToSqr(SourcePos)
	local TargetPos = MissileDist <= AimDist and AimPos or nil

	self.TargetPos = TargetPos

	return {
		TargetPos = TargetPos
	}
end

function Guidance:GetDisplayConfig()
	return {
		["Wire Length"] = math.Round(WireLength ^ 0.5 * 0.0254, 1) .. " m"
	}
end