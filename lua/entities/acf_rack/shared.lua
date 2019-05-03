-- shared.lua
DEFINE_BASECLASS("base_wire_entity")
ENT.Type = "anim"
ENT.PrintName = "ACF Rack"
ENT.Author = "Bubbus"
ENT.Contact = "splambob@googlemail.com"
ENT.Purpose = "Because launch tubes aren't cool enough."
ENT.Instructions = "Point towards face for removal of face.  Point away from face for instant fake tan (then removal of face)."
ENT.WireDebugName = "ACF Rack"

function ENT:GetOverlayText()
	local WireName = self:GetNWString("WireName")
	local GunType = self:GetNWString("GunType")
	local Ammo = self:GetNWInt("Ammo")
	local FireRate = math.Round(self:GetNWFloat("Interval"), 2)
	local Reload = math.Round(self:GetNWFloat("Reload"), 2)
	local ReloadBonus = math.floor(self:GetNWFloat("ReloadBonus") * 100)
	local Status = self:GetNWString("Status")
	local Text = (WireName ~= "" and "- " .. WireName .. " -\n" or "") .. GunType .. " (" .. Ammo .. " left) \n" .. "Fire interval: " .. FireRate .. " sec\n" .. "Reload interval: " .. Reload .. " sec" .. (ReloadBonus > 0 and " (-" .. ReloadBonus .. "%)" or "") .. (Status ~= "" and "\n - " .. Status .. " - " or "")

	if not game.SinglePlayer() then
		Text = Text .. "\n(" .. self:GetPlayerName() .. ")"
	end

	return Text
end

function ENT:GetMuzzle(Missile, AttachName)
	local Attach = self:LookupAttachment(AttachName)
	local Parent = self:GetParent()

	if Parent then
		self:SetParent(nil)
	end

	local Gun = list.Get("ACFEnts").Guns[Missile.BulletData.Id]
	local RackData = ACF.Weapons.Rack[self.Id]
	local Attachment = self:GetAttachment(Attach)

	Attachment.Ang = self:GetAngles()

	if Gun and RackData then
		local Offset = (Gun.modeldiameter or Gun.caliber) / (2.54 * 2)

		local MountPoint = RackData.mountpoints[AttachName] or {
			offset = Vector(),
			scaledir = Vector(0, 0, -1)
		}

		Attachment.Pos = self:WorldToLocal(Attachment.Pos) + MountPoint.offset + MountPoint.scaledir * Offset
	end

	if Parent then
		self:SetParent(Parent)
	end

	return Attachment
end