-- init.lua

function EFFECT:Init( Data )

	local Gun = Data:GetEntity()
	local Sound = Gun:GetNWString("Sound")
	local Propellant = Data:GetScale()
	local Class = Gun:GetNWString("Class")
	local GunClass = ACF.Classes.GunClass[Class]

	if CLIENT and not IsValidSound( Sound ) then
		Sound = GunClass.sound
	end

	if IsValid(Gun) and Propellant > 0 then
		local Attachment = Data:GetAttachment()
		local SoundPressure = (Propellant * 1000) ^ 0.5
		local GunPos = Gun:GetPos()

		-- wiki documents level tops out at 180, but seems to fall off past 127
		sound.Play(Sound, GunPos, math.Clamp(SoundPressure, 75, 127), 100)

		if not (Class == "MG" or Class == "RAC") and SoundPressure > 127 then
			sound.Play(Sound, GunPos , math.Clamp(SoundPressure - 127, 1, 127), 100)
		end

		local Muzzle = Gun:GetAttachment(Attachment) or { Pos = GunPos, Ang = Gun:GetAngles() }
		Muzzle.Ang = (-Muzzle.Ang:Forward()):Angle()

		ParticleEffect(GunClass.muzzleflash, Muzzle.Pos, Muzzle.Ang, Gun)
	end

end

function EFFECT:Think( )

	return false

end