local ClassName = "Radar"
ACF = ACF or {}
ACF.Guidance = ACF.Guidance or {}
ACF.Guidance[ClassName] = ACF.Guidance[ClassName] or inherit.NewSubOf(ACF.Guidance.Wire)

local Guidance = ACF.Guidance[ClassName]
local SeekTolerance = math.cos(math.rad(2)) -- Targets this close to the front are good enough (2 degrees).
local MinimumDistance = 393.7 * 393.7 -- Minimum distance for a target to be considered (10m)

-- Entity class whitelist, thanks to Sestze for the listing.
local Whitelist = {
	prop_physics = true,
	gmod_wheel = true,
	gmod_hoverball = true,
	gmod_wire_expression2 = true,
	gmod_wire_thruster = true,
	gmod_thruster = true,
	gmod_wire_light = true,
	gmod_light = true,
	gmod_emitter = true,
	gmod_button = true,
	phys_magnet = true,
	prop_vehicle_jeep = true,
	prop_vehicle_airboat = true,
	prop_vehicle_prisoner_pod = true,
	acf_engine = true,
	acf_ammo = true,
	acf_gun = true,
	acf_gearbox = true,
}

local function HasLOSVisibility(Missile, Target)
	local TraceData = {
		start = Missile:GetPos(),
		endpos = Target:GetPos(),
		mask = MASK_SOLID_BRUSHONLY,
		filter = {Missile, Target}
	}

	return not util.TraceLine(TraceData).Hit
end

local function GetTargetData(Missile, Target)
	local Direction = Missile:GetForward()
	local Dot = Direction.Dot
	local TargetPos = Target:GetPos() - Missile:GetPos()
	local TargetDot = Dot(Direction, TargetPos:GetNormalized())

	return TargetDot, TargetPos
end

local function GetWireTarget(GuidanceData, Missile)
	if not IsValid(GuidanceData.Source) then return nil end
	local Outputs = GuidanceData.Source.Outputs
	local TargetOutput = Outputs.Target

	if TargetOutput and IsValid(TargetOutput.Value) then
		local Target = TargetOutput.Value
		local HasLOS = HasLOSVisibility(Missile, Target)
		local TargetDot = GetTargetData(Missile, Target)
		local SeekConeCos = GuidanceData.SeekConeCos

		if HasLOS and TargetDot >= SeekConeCos then
			return Target
		end
	end
end

-- ents.FindInCone() is not finding any prop_physics entity
local function GetEntitiesInCone(GuidanceData, Missile)
	local Entities = ents.FindInSphere(Missile:GetPos(), 50000)
	local Result = {}

	if next(Entities) then
		local SeekConeCos = GuidanceData.SeekConeCos

		for _, FoundEnt in pairs(Entities) do
			if IsValid(FoundEnt) and Whitelist[FoundEnt:GetClass()] then
				local FoundEntDot, FoundEntPos = GetTargetData(Missile, FoundEnt)
				local FoundEntDist = FoundEntPos:LengthSqr()

				if FoundEntDist >= MinimumDistance and FoundEntDot > SeekConeCos then
					Result[FoundEnt] = FoundEntDot
				end
			end
		end
	end

	return Result
end

-- Return the first entity found within the seek-tolerance, or the entity within the seek-cone closest to the seek-tolerance.
local function AcquireLock(GuidanceData, Missile)
	local Time = CurTime()

	if GuidanceData.NextWireSeek <= Time then
		local WireTarget = GetWireTarget(GuidanceData, Missile)

		GuidanceData.NextWireSeek = Time + GuidanceData.WireSeekDelay

		if WireTarget then
			return WireTarget
		end
	end

	if GuidanceData.NextSeek > Time then
		return nil
	end

	GuidanceData.NextSeek = Time + GuidanceData.SeekDelay

	local Entities = GetEntitiesInCone(GuidanceData, Missile)
	if not next(Entities) then return nil end

	local Ent, CurrentDot = next(Entities)
	local HighestDot = -1
	local MostCentralEnt

	repeat
		if CurrentDot > HighestDot and HasLOSVisibility(Missile, Ent) then
			HighestDot = CurrentDot
			MostCentralEnt = Ent

			if HighestDot >= SeekTolerance then
				return Ent
			end
		end

		Ent, CurrentDot = next(Entities, Ent)
	until not Ent

	return MostCentralEnt
end

local function CheckTarget(GuidanceData, Missile)
	if not (GuidanceData.Target or GuidanceData.Override) then
		local Target = AcquireLock(GuidanceData, Missile)

		if Target and Missile.Motor > 0 then
			GuidanceData.Target = Target
		end
	else
		local TargetDot = GetTargetData(Missile, GuidanceData.Target)
		local ViewConeCos = GuidanceData.ViewConeCos

		if TargetDot < ViewConeCos then
			GuidanceData.Target = nil
		end
	end
end

function Guidance:Init()
	self.Name = ClassName
	self.desc = "This guidance package detects a target-position infront of itself, and guides the munition towards it."
	self.SeekCone = 20 -- Cone to acquire targets within.
	self.ViewCone = 25 -- Cone to retain targets within.
	self.SeekDelay = 1 -- This instance must wait this long between target seeks.
	self.WireSeekDelay = 0.2 -- Delay between re-seeks if an entity is provided via wiremod.
	self.NextSeek = CurTime()
	self.NextWireSeek = CurTime()
end

function Guidance:Configure(Missile)
	self:super().Configure(self, Missile)
	self.ViewCone = ACF_GetGunValue(Missile.BulletData, "viewcone") or self.ViewCone
	self.ViewConeCos = math.cos(math.rad(self.ViewCone))
	self.SeekCone = ACF_GetGunValue(Missile.BulletData, "seekcone") or self.SeekCone
	self.SeekConeCos = math.cos(math.rad(self.SeekCone))
end

function Guidance:ApplyOverride(Missile)
	if self.Override then
		local Override = self.Override:GetGuidanceOverride(Missile, self)

		if Override then
			Override.ViewCone = self.ViewCone
			Override.ViewConeCos = self.ViewConeCos

			return Override
		end
	end
end

--TODO: still a bit messy, refactor this so we can check if a flare exits the viewcone too.
function Guidance:GetGuidance(Missile)
	self:PreGuidance(Missile)
	local Override = self:ApplyOverride(Missile)
	if Override then return Override end

	CheckTarget(self, Missile)
	if not IsValid(self.Target) then return {} end
	local TargetPos = self.Target:GetPos()

	self.TargetPos = TargetPos

	return {
		TargetPos = TargetPos,
		ViewCone = self.ViewCone
	}
end

function Guidance:GetDisplayConfig()
	return {
		Seeking = math.Round(self.SeekCone * 2, 1) .. " deg",
		Tracking = math.Round(self.ViewCone * 2, 1) .. " deg"
	}
end