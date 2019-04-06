include("shared.lua")




function ENT:Draw()

	local LightSize = self:GetNWFloat("LightSize")

	self:DrawModel()
	
	if LightSize then	
		local Index = self:EntIndex()
		local Colour = Color(255, 128, 48)
		local LightPos = self:GetPos() - self:GetForward() * 64
		
		ACFM_RenderLight( Index, LightSize * 175, Colour, LightPos )
	end
	
end