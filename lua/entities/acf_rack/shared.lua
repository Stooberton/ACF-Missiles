-- shared.lua

DEFINE_BASECLASS("base_wire_entity")




ENT.Type        	= "anim"
ENT.Base        	= "base_wire_entity"
ENT.PrintName 		= "ACF Rack"
ENT.Author 			= "Bubbus"
ENT.Contact 		= "splambob@googlemail.com"
ENT.Purpose		 	= "Because launch tubes aren't cool enough."
ENT.Instructions 	= "Point towards face for removal of face.  Point away from face for instant fake tan (then removal of face)."

ENT.Spawnable 		= false
ENT.AdminOnly		= false
ENT.AdminSpawnable 	= false




local function GetMunitionAngPos( Rack, Missile, Attach, AttachName )

	local Parent = Rack:GetParent()

	Rack:SetParent()

	local Attachment = Rack:GetAttachment(Attach)
	local Gun = list.Get("ACFEnts").Guns[Missile.BulletData.Id]
	local RackData

	if Gun then
		RackData = ACF.Weapons.Rack[Rack.Id]
	end

	if RackData then
		local Offset = (Gun.modeldiameter or Gun.caliber) / (2.54 * 2)
		local MountPoint = RackData.mountpoints[AttachName] or { offset = Vector(), scaledir = Vector(0, 0, -1) }

		Attachment.Pos = Rack:WorldToLocal(Attachment.Pos) + MountPoint.offset + MountPoint.scaledir * Offset
		Attachment.Ang = Rack:GetAngles()
	end

	Rack:SetParent(Parent)

	return Attachment

end




function ENT:GetOverlayText()

	local WireName 		= self:GetNWString("WireName")
	local GunType 		= self:GetNWString("GunType")
	local Ammo 			= self:GetNWInt("Ammo")
	local FireRate 		= math.Round(self:GetNWFloat("Interval"), 2)
	local Reload 		= math.Round(self:GetNWFloat("Reload"), 2)
	local ReloadBonus	= math.floor(self:GetNWFloat("ReloadBonus") * 100)
	local Status		= self:GetNWString("Status")

	local Text = (WireName ~= "" and "- " .. WireName .. " -\n" or "") ..
				GunType .. " (" .. Ammo .. " left) \n" ..
				"Fire interval: " .. FireRate .. " sec\n" ..
				"Reload interval: " .. Reload .. " sec" ..
				(ReloadBonus > 0 and " (-" .. ReloadBonus .. "%)" or "") ..
				(Status ~= "" and "\n - " .. Status .. " - " or "")

	if not game.SinglePlayer() then
		Text = Text .. "\n(" .. self:GetPlayerName() .. ")"
	end

	return Text

end




function ENT:GetMuzzle( Missile, Shot )

	local AttachName = "missile" .. (Shot or 0) + 1
	local Attach = self:LookupAttachment(AttachName)

	if Attach ~= 0 then return GetMunitionAngPos(self, Missile, Attach, AttachName) end

	AttachName = "missile1"
	Attach = self:LookupAttachment(AttachName)

	if Attach ~= 0 then return GetMunitionAngPos(self, Missile, Attach, AttachName) end

	AttachName = "muzzle"
	Attach = self:LookupAttachment(AttachName)

	if Attach ~= 0 then return GetMunitionAngPos(self, Missile, Attach, AttachName) end

	return { Pos = self:GetPos(), Ang = self:GetAngles() }

end