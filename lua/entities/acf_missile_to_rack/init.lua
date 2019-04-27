-- init.lua
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self.CacheRackSpawn = true
end

function ENT:Think()
	if self.CacheRackSpawn then
		local SelfPos = self:GetPos()
		local SelfAng = self:GetAngles()
		local RackId = self.RackID
		self:Remove()

		if not (RackID and ACF.Weapons.Rack[RackID]) then
			local GunClass = ACF.Weapons.Guns[self.Id]

			if not GunClass then
				error("Couldn't spawn the missile rack: can't find the gun-class '" + tostring(self.Id) + "'.")
			end

			if not GunClass.rack then
				error("Couldn't spawn the missile rack: '" + tostring(self.Id) + "' doesn't have a preferred missile rack.")
			end

			RackId = GunClass.rack
		end

		MakeACF_Rack(self.Owner, SelfPos, SelfAng, RackId)
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end

function MakeACF_MissileToRack(Owner, Pos, Ang, Id, RackId)
	if not Owner:CheckLimit("_acf_gun") then return false end
	local Converter = ents.Create("acf_missile_to_rack")
	if not IsValid(Converter) then return false end
	Converter:SetAngles(Ang)
	Converter:SetPos(Pos)
	Converter.Id = Id
	Converter.Owner = Owner
	Converter.RackID = RackId
	Converter:Spawn()
	-- Requires physics so acfmenu doesn't break.  Otherwise this could be a point entity.
	Converter:SetModel("models/props_junk/popcan01a.mdl")
	Converter:PhysicsInit(SOLID_VPHYSICS)
	Converter:SetMoveType(MOVETYPE_VPHYSICS)
	Converter:SetSolid(SOLID_VPHYSICS)

	return Converter
end

list.Set("ACFCvars", "acf_missile_to_rack", {"id", "data9"})
duplicator.RegisterEntityClass("acf_missile_to_rack", MakeACF_MissileToRack, "Pos", "Angle", "Id")