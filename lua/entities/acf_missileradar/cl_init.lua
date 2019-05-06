-- cl_init.lua
include("shared.lua")

function ENT:Draw()
	self:DoNormalDraw()
	self:DrawModel()
	Wire_Render(self)
end

function ENT:DoNormalDraw()
	local SelfPos = self:GetPos()

	if not self:GetNWBool("VisInfo") then return end
	if LocalPlayer():GetEyeTrace().Entity ~= self or EyePos():Distance(SelfPos) > 256 then return end
	local OverlayText = self:GetOverlayText()

	if OverlayText ~= "" then
		AddWorldTip(self:EntIndex(), OverlayText, 0.5, SelfPos, self)
	end
end

function ENT:GetOverlayText()
	local Name = self:GetNWString("Id")
	local ConeDegs = math.Round(self:GetNWFloat("ConeDegs") * 2, 2)
	local Range = math.Round(self:GetNWFloat("Range") / 39.37, 2)
	local Status = self:GetNWString("Status")
	local Text = Name .. (ConeDegs > 0 and ("\nScanning angle: " .. ConeDegs .. " degrees") or "") .. (Range > 0 and ("\nDetection range: " .. Range .. " m") or "") .. (Status ~= "" and ("\n(" .. Status .. ")") or "")

	return Text
end

function ACFRadarGUICreate(Table)
	acfmenupanel:CPanelText("Name", Table.name)
	acfmenupanel.CData.DisplayModel = vgui.Create("DModelPanel", acfmenupanel.CustomDisplay)
	acfmenupanel.CData.DisplayModel:SetModel(Table.model)
	acfmenupanel.CData.DisplayModel:SetCamPos(Vector(250, 500, 250))
	acfmenupanel.CData.DisplayModel:SetLookAt(Vector())
	acfmenupanel.CData.DisplayModel:SetFOV(20)
	acfmenupanel.CData.DisplayModel:SetSize(acfmenupanel:GetWide(), acfmenupanel:GetWide())
	acfmenupanel.CData.DisplayModel.LayoutEntity = function(panel, entity) end
	acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.DisplayModel)
	acfmenupanel:CPanelText("ClassDesc", ACF.Classes.Radar[Table.class].desc)
	acfmenupanel:CPanelText("GunDesc", Table.desc)
	acfmenupanel:CPanelText("ViewCone", "View cone : " .. ((Table.viewcone or 180) * 2) .. " degs")
	acfmenupanel:CPanelText("ViewRange", "View range : " .. (Table.range and (math.Round(Table.range / 39.37, 1) .. " m") or "unlimited"))
	acfmenupanel:CPanelText("Weight", "Weight : " .. Table.weight .. " kg")

	if Table.canparent then
		acfmenupanel:CPanelText("GunParentable", "\nThis radar can be parented.")
	end

	acfmenupanel.CustomDisplay:PerformLayout()
end