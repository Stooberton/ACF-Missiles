-- cl_init.lua
include("shared.lua")

function ENT:Draw()
    local Pos = self:GetPos()
    local TraceEnt = LocalPlayer():GetEyeTrace().Entity

    if TraceEnt == self and EyePos():Distance(Pos) < 256 and self:GetOverlayText() ~= "" then
        AddWorldTip(self:EntIndex(), self:GetOverlayText(), 0.5, Pos, self)
    end

    self:DrawModel()
    Wire_Render(self)
end