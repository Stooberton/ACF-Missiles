-- cl_init.lua
include("shared.lua")

function ENT:Draw()
	self:DoNormalDraw()
	self:DrawModel()
	Wire_Render(self)
end

function ENT:DoNormalDraw()
	if not self:GetNWBool("VisInfo") then return end
	if not LocalPlayer():GetEyeTrace().Entity == self and EyePos():Distance(self:GetPos()) < 256 then return end
	local OverlayText = self:GetOverlayText()

	if OverlayText ~= "" then
		AddWorldTip(self:EntIndex(), OverlayText, 0.5, self:GetPos(), self)
	end
end

function ENT:GetOverlayText()
	local RoundID = self:GetNWString("RoundId", "Unknown ID")
	local RoundType = self:GetNWString("RoundType", "Unknown Type")
	local Filler = self:GetNWFloat("FillerVol")
	local Blast = (Filler * 0.5) ^ 0.33 * 5 * 10 * 0.2
	local Text = RoundID .. " (" .. RoundType .. ")\n" .. Filler .. " cm^3 HE Filler\n" .. Blast .. " m Blast Radius"

	return Text
end