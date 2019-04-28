-- cl_init.lua
include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	render.SetMaterial(Material("sprites/orangeflare1"))
	render.DrawSprite(self:GetAttachment(1).Pos, 50, 50, Color(255, 255, 255, 255))
end