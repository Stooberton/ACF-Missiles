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