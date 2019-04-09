include("shared.lua")




function ENT:Draw()

	local Index = self:EntIndex()
	local LightSize = self:GetNWFloat("LightSize", 0) * 175
	local Colour = Color(255, 128, 48)
	local LightPos = self:GetPos() - self:GetForward() * 64

	ACFM_RenderLight( Index, LightSize, Colour, LightPos )

	self:DrawModel()

end