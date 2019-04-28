-- init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("radar_types_support.lua")
CreateConVar("sbox_max_acf_missileradar", 6)

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Inputs = WireLib.CreateInputs(self, {"Active"})
	self.Outputs = WireLib.CreateOutputs(self, {"Detected", "ClosestDistance", "Entities [ARRAY]", "Position [ARRAY]", "Velocity [ARRAY]"})
	self.ThinkDelay = 0.1
	self.StatusUpdateDelay = 0.5
	self.LastStatusUpdate = CurTime()
	self.LegalMass = self.Weight or 0
	self.Active = false
	self.LastMissileCount = 0
	self:CreateRadar(self.ACFName or "Missile Radar", self.ConeDegs or 0)
	self:EnableClientInfo(true)
	self:ConfigureForClass()
	self:SetActive(false)
end

function ENT:ConfigureForClass()
	local Behavior = ACFM.RadarBehaviour[self.Class]
	if not Behavior then return end
	self.GetDetectedEnts = Behavior.GetDetectedEnts
end

function ENT:TriggerInput(Input, Value)
	if Input == "Active" then
		self:SetActive(Value ~= 0)
	end
end

function ENT:SetActive(Active)
	local SequenceName = Active and "active" or "idle" or 0
	local Sequence = self:LookupSequence(SequenceName)
	self:ResetSequence(Sequence)
	self.Active = Active
	self.AutomaticFrameAdvance = Active
end

function MakeACF_MissileRadar(Owner, Pos, Angle, Id)
	if not Owner:CheckLimit("_acf_missileradar") then return false end
	local RadarData = ACF.Weapons.Radar[Id]
	if not RadarData then return false end
	local Radar = ents.Create("acf_missileradar")
	if not IsValid(Radar) then return false end
	Radar:SetAngles(Angle)
	Radar:SetPos(Pos)
	Radar.Model = RadarData.model
	Radar.Weight = RadarData.weight
	Radar.ACFName = RadarData.name
	Radar.ConeDegs = RadarData.viewcone
	Radar.Range = RadarData.range
	Radar.Id = Id
	Radar.Class = RadarData.class
	Radar:Spawn()
	Radar:SetPlayer(Owner)

	if CPPI then
		Radar:CPPISetOwner(Owner)
	end

	Radar.Owner = Owner
	Radar:SetModelEasy(RadarData.model)
	Owner:AddCount("_acf_missileradar", Radar)
	Owner:AddCleanup("acfmenu", Radar)

	return Radar
end

list.Set("ACFCvars", "acf_missileradar", {"id"})
duplicator.RegisterEntityClass("acf_missileradar", MakeACF_MissileRadar, "Pos", "Angle", "Id")

function ENT:CreateRadar(ACFName, ConeDegs)
	self.ConeDegs = ConeDegs
	self.ACFName = ACFName
	self:RefreshClientInfo()
end

function ENT:RefreshClientInfo()
	self:SetNWFloat("ConeDegs", self.ConeDegs)
	self:SetNWFloat("Range", self.Range)
	self:SetNWString("Id", self.ACFName)
	self:SetNWString("Name", self.ACFName)
end

function ENT:SetModelEasy(Model)
	self:SetModel(Model)
	self.Model = Model
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:SetMass(self.Weight)
	end
end

function ENT:Think()
	if self.Inputs.Active.Value ~= 0 and self:AllowedToScan() then
		self:ScanForMissiles()
	else
		self:ClearOutputs()
	end

	local Time = CurTime()
	self:NextThink(Time + self.ThinkDelay)

	if self.LastStatusUpdate + self.StatusUpdateDelay < Time then
		self:UpdateStatus()
		self.LastStatusUpdate = Time
	end

	return true
end

--adapted from acf engine checks, thanks ferv
--returns if passes weldparent check.  True means good, false means bad
function ENT:CheckWeldParent()
	local Parent = self:GetParent()
	-- if it's not parented we're fine
	if not IsValid(Parent) then return true end

	--if welded to parent, it's ok
	for k, v in pairs(constraint.FindConstraints(self, "Weld")) do
		if v.Ent1 == Parent or v.Ent2 == Parent then return true end
	end

	return false
end

function ENT:UpdateStatus()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid(PhysObj) then
		self:SetNWString("Status", "Physics error, please respawn this")

		return
	end

	if PhysObj:GetMass() < self.LegalMass then
		self:SetNWString("Status", "Illegal mass, should be " .. self.LegalMass .. " kg")

		return
	end

	if not self:CheckWeldParent() then
		self:SetNWString("Status", "Deactivated: parenting is disallowed")

		return
	end

	if not self.Active then
		self:SetNWString("Status", "Inactive")
	elseif self.Outputs.Detected.Value > 0 then
		self:SetNWString("Status", self.Outputs.Detected.Value .. " objects detected!")
	else
		self:SetNWString("Status", "Active")
	end
end

function ENT:AllowedToScan()
	if not self.Active then return false end
	local PhysObj = self:GetPhysicsObject()

	if not IsValid(PhysObj) then
		print("Invalid Physical Object")

		return false
	end
	--TODO: replace self:getParent with a function check on if weldparent valid.

	return PhysObj:GetMass() == self.LegalMass and not IsValid(self:GetParent())
end

function ENT:GetDetectedEnts()
	print("reached base GetDetectedEnts")

	return {}
end

function ENT:ScanForMissiles()
	local Missiles = self:GetDetectedEnts()
	local Position = {}
	local Velocity = {}
	local Closest
	local ClosestDist = 999999
	local Count = #Missiles
	local SelfPos = self:GetPos()

	for k, v in pairs(Missiles) do
		Position[k] = v.CurPos
		Velocity[k] = v.LastVel
		local CurDist = SelfPos:DistToSqr(v.CurPos)

		if CurDist < ClosestDist then
			Closest = v.CurPos
			ClosestDist = CurDist
		end
	end

	if not Closest then
		ClosestDist = 0
	end

	WireLib.TriggerOutput(self, "Detected", Count)
	WireLib.TriggerOutput(self, "ClosestDistance", ClosestDist ^ 0.5)
	WireLib.TriggerOutput(self, "Entities", Missiles)
	WireLib.TriggerOutput(self, "Position", Position)
	WireLib.TriggerOutput(self, "Velocity", Velocity)

	if Count > self.LastMissileCount then
		self:EmitSound(self.Sound or ACFM.DefaultRadarSound, 500, 100)
	end

	self.LastMissileCount = Count
end

function ENT:ClearOutputs()
	if #self.Outputs.Entities.Value > 0 then
		WireLib.TriggerOutput(self, "ClosestDistance", 0)
		WireLib.TriggerOutput(self, "Entities", {})
		WireLib.TriggerOutput(self, "Position", {})
		WireLib.TriggerOutput(self, "Velocity", {})
	end
end

function ENT:EnableClientInfo(Bool)
	self.ClientInfo = Bool
	self:SetNWBool("VisInfo", Bool)

	if Bool then
		self:RefreshClientInfo()
	end
end