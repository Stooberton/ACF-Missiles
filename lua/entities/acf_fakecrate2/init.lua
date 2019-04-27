-- init.lua
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self.SpecialDamage = true
	self.Owner = self:GetOwner()
	print("hi from fakecrate")
end

function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor)
	return {
		Damage = 0,
		Overkill = 0,
		Loss = 0,
		Kill = false
	}
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:RegisterTo(Bullet)
	if Bullet.BulletData then
		self:SetNWString("Sound", Bullet.Primary and Bullet.Primary.Sound or nil)
		self.Owner = Bullet:GetOwner()
		self:SetOwner(self.Owner)
	end

	local BulletColor = Bullet.Colour or self:GetColor()
	local ColorVector = Vector(BulletColor.r, BulletColor.g, BulletColor.b)

	self:SetNWInt("Caliber", Bullet.Caliber or 10)
	self:SetNWInt("ProjMass", Bullet.ProjMass or 10)
	self:SetNWInt("FillerMass", Bullet.FillerMass)
	self:SetNWInt("DragCoef", Bullet.DragCoef or 1)
	self:SetNWString("AmmoType", Bullet.Type or "AP")
	self:SetNWInt("Tracer", Bullet.Tracer)
	self:SetNWVector("Color", ColorVector)
	self:SetNWVector("TracerColour", ColorVector)
	self:SetColor(BulletColor)
end