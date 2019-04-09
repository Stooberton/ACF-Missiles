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

	local Attachment = Rack:GetAttachment(Attach)
	local Guns = list.Get("ACFEnts").Guns
	local Gun = Guns[Missile.BulletData.Id]

	if not Gun then return Attachment end

	local RackData = ACF.Weapons.Rack[Rack.Id]

	if not RackData then return Attachment end

	local Offset = (Gun.modeldiameter or Gun.caliber) / (2.54 * 2)
	local MountPoint = RackData.mountpoints[AttachName] or { offset = Vector(), scaledir = Vector(0, 0, -1) }

	if not IsValid(Rack:GetParent()) then
		local RackPos = Rack:GetPos()
		local AttachOffset = Rack:LocalToWorld(MountPoint.offset) - RackPos
		local AttachDir = Rack:LocalToWorld(MountPoint.scaledir) - RackPos

		Attachment.Pos = Attachment.Pos + AttachOffset + AttachDir * Offset
	else
		if #Rack:GetAttachments() ~= 1 then
			Offset = gun.modeldiameter or gun.caliber * 2
		end

		Attachment.Pos =  MountPoint.offset + MountPoint.scaledir * Offset
	end

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




function ENT:GetMuzzle( Shot, Missile )

	local Index = (Shot or 0) + 1
	local TryMissile = "missile" .. Index
	local Attach = self:LookupAttachment(TryMissile)

	if Attach ~= 0 then return Attach, GetMunitionAngPos(self, Missile, Attach, TryMissile) end

	TryMissile = "missile1"
	Attach = self:LookupAttachment(TryMissile)

	if Attach ~= 0 then return Attach, GetMunitionAngPos(self, Missile, Attach, TryMissile) end

	TryMissile = "muzzle"
	Attach = self:LookupAttachment(TryMissile)

	if Attach ~= 0 then return Attach, GetMunitionAngPos(self, Missile, Attach, TryMissile) end

	return 0, { Pos = self:GetPos(), Ang = self:GetAngles() }

end