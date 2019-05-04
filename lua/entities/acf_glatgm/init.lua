-- init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	if self.BulletData.Caliber == 12.0 then
		self:SetModel("models/missiles/glatgm/9m112.mdl")
	elseif self.BulletData.Caliber > 12.0 then
		self:SetModel("models/missiles/glatgm/mgm51.mdl")
	else
		self:SetModel("models/missiles/glatgm/9m117.mdl")
		self:SetModelScale(self.BulletData.Caliber * 0.1, 0)
	end

	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	timer.Simple(0.1, function()
		ParticleEffectAttach("Rocket_Smoke_Trail", 4, self, 1)
	end)

	local PhysObj = self:GetPhysicsObject()
	PhysObj:EnableGravity(false)
	PhysObj:EnableMotion(false)
	self.KillTime = CurTime() + 20
	self.Time = CurTime()
	self.Filter = {self, self.Guidance}

	for k, v in pairs(ents.FindInSphere(self.Guidance:GetPos(), 250)) do
		if v:GetClass() == "acf_opticalcomputer" and v:CPPIGetOwner() == self.Owner then
			self.Guidance = v
			self.Optic = true
		end
	end

	self.SubCaliber = self.BulletData.Caliber < 10
	self.Velocity = self.SubCaliber and 2500 or 5000 -- Velocity of the missile per second
	self.SecondsOffset = self.SubCaliber and 0.25 or 0.5 -- seconds of forward flight to aim towards, to affect the beam-riding simulation

	if self.SubCaliber then
		self.SpiralAm = (10 - self.BulletData.Caliber) * 0.5 -- amount of artifical spiraling for <100 shells, caliber in acf is in cm
	end

	self.OffsetLength = self.Velocity * self.SecondsOffset --how far off the forward offset is for the targeting position
end

function ENT:Think()
	if not IsValid(self) then return end

	if self.KillTime < CurTime() then
		self:Detonate()
	end

	local TimeNew = CurTime()
	local d = Vector()
	local dir = AngleRand() * 0.01
	local Dist = 0.01

	if IsValid(self.Guidance) and self.Guidance:GetPos():Distance(self:GetPos()) < self.Distance then
		local di = self.Guidance:WorldToLocalAngles((self:GetPos() - self.Guidance:GetPos()):Angle())

		if di.p < 15 and di.p > -15 and di.y < 15 and di.y > -15 then
			local glpos = self.Guidance:GetPos() + self.Guidance:GetForward()

			if not self.Optic then
				glpos = self.Guidance:GetAttachment(1).Pos + self.Guidance:GetForward() * 20
			end

			local tr = util.QuickTrace(glpos, self.Guidance:GetForward() * (self.Guidance:GetPos():Distance(self:GetPos()) + self.OffsetLength), {self.Guidance, self})
			d = tr.HitPos - self:GetPos()
			dir = self:WorldToLocalAngles(d:Angle()) * 0.02 --0.01 controls agility but is not scaled to timestep; bug poly
			Dist = self.Guidance:GetPos():Distance(self:GetPos()) / 39.37 / 10000
		end
	end

	local Spiral = d:Length() / 39370 or 0.5

	if self.SubCaliber then
		Spiral = self.SpiralAm + math.random(-self.SpiralAm * 0.5, self.SpiralAm) --Spaghett
	end

	local Inacc = math.random(-1, 1) * Dist
	self:SetAngles(self:LocalToWorldAngles(dir + Angle(Inacc, -Inacc, 5)))
	self:SetPos(self:LocalToWorld(Vector(self.Velocity * (TimeNew - self.Time), Spiral, 0)))
	local tr = util.QuickTrace(self:GetPos() + self:GetForward() * -28, self:GetForward() * (self.Velocity * (TimeNew - self.Time) + 300), self.Filter)
	self.Time = TimeNew

	if tr.Hit then
		self:Detonate()
	end

	self:NextThink(CurTime() + 0.0001) -- What the FUCK

	return true
end

function ENT:Detonate()
	if not IsValid(self) or self.Detonated then return end
	self.Detonated = true
	local Flash = EffectData()
	Flash:SetOrigin(self:GetPos())
	Flash:SetNormal(self:GetForward())
	Flash:SetRadius(self.BulletData.FillerMass ^ 0.33 * 8 * 39.37 / 5)
	util.Effect("ACF_Scaled_Explosion", Flash)

	BulletData = {
		Type = "HEAT",
		Accel = self.BulletData.Accel,
		BoomPower = self.BulletData.BoomPower,
		Caliber = self.BulletData.Caliber,
		Crate = self.BulletData.Crate,
		DragCoef = self.BulletData.DragCoef,
		FillerMass = self.BulletData.FillerMass,
		Filter = {self},
		Flight = self.BulletData.Flight,
		FlightTime = 0,
		FrArea = self.BulletData.FrArea,
		FuseLength = 0,
		Gun = self,
		Id = self.BulletData.Id,
		KETransfert = self.BulletData.KETransfert,
		LimitVel = 100,
		MuzzleVel = self.BulletData.MuzzleVel,
		Owner = self.BulletData.Owner,
		PenArea = self.BulletData.PenArea,
		Pos = self.BulletData.Pos,
		ProjLength = self.BulletData.ProjLength,
		ProjMass = self.BulletData.ProjMass,
		PropLength = self.BulletData.PropLength,
		PropMass = self.BulletData.PropMass,
		Ricochet = self.BulletData.Ricochet,
		DetonatorAngle = self.BulletData.DetonatorAngle,
		RoundVolume = self.BulletData.RoundVolume,
		ShovePower = self.BulletData.ShovePower,
		Tracer = self.BulletData.Tracer,
		SlugMass = self.BulletData.SlugMass,
		SlugCaliber = self.BulletData.SlugCaliber,
		SlugDragCoef = self.BulletData.SlugDragCoef,
		SlugMV = self.BulletData.SlugMV,
		SlugPenArea = self.BulletData.SlugPenArea,
		SlugRicochet = self.BulletData.SlugRicochet,
		ConeVol = self.BulletData.ConeVol,
		CasingMass = self.BulletData.CasingMass,
		BoomFillerMass = self.BulletData.BoomFillerMass
	}

	self.FakeCrate = ents.Create("acf_fakecrate2")
	self.FakeCrate:RegisterTo(BulletData)
	self:DeleteOnRemove(self.FakeCrate)
	BulletData.Crate = self.FakeCrate:EntIndex()
	BulletData.Flight = self:GetForward():GetNormalized() * BulletData.MuzzleVel * 39.37
	BulletData.Pos = self:GetPos()
	self.CreateShell = ACF.RoundTypes[BulletData.Type].create
	self:CreateShell(BulletData)

	timer.Simple(0.1, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end