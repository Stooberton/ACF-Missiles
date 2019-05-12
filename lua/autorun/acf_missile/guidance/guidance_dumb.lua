local ClassName = "Dumb"
ACF = ACF or {}
ACF.Guidance = ACF.Guidance or {}
ACF.Guidance[ClassName] = ACF.Guidance[ClassName] or inherit.NewBaseClass()

local Guidance = ACF.Guidance[ClassName]

function Guidance:Init()
	self.Name = ClassName
	self.desc = "This guidance package is empty and provides no control."
end

function Guidance:Configure(Missile)
end

function Guidance:GetGuidance(Missile)
	self:PreGuidance(Missile)

	return self:ApplyOverride(Missile) or {}
end

function Guidance:PreGuidance(Missile)
	if not self.AppliedSpawnCountermeasures then
		ACFM_ApplySpawnCountermeasures(Missile, self)
		self.AppliedSpawnCountermeasures = true
	end

	ACFM_ApplyCountermeasures(Missile, self)
end

function Guidance:ApplyOverride(Missile)
end

function Guidance:GetDisplayConfig()
	return {}
end