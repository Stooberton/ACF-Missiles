-- init.lua
DEFINE_BASECLASS("acf_explosive")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local function GetCrate(Gun)
	if not next(Gun.Crates) then return nil end -- No crates linked to this gun
	local Select = next(Gun.Crates, Gun.CurrentCrate) or next(Gun.Crates) -- Next crate from Start or, if at last crate, first crate
	local Start = Select
	repeat
		if Select.Load then return Select end
		Select = next(Gun.Crates, Select) or next(Gun.Crates)
	until Select == Start or Select.Load -- If we've looped back around to the start then there's nothing to use

	return Select.Load and Select or nil
end

local function SetLoadedWeight(Rack)
	local PhysObj = Rack:GetPhysicsObject()
	Rack.ACFLegalMass = Rack.EmptyMass

	for _, Missile in pairs(Rack.Missiles) do
		local PhysMissile = Missile:GetPhysicsObject()
		Rack.ACFLegalMass = Rack.ACFLegalMass + Missile.RoundWeight

		-- Will result in slightly heavier rack but is probably a good idea to have some mass for any damage calcs.
		if IsValid(PhysMissile) then
			PhysMissile:SetMass(5)
		end
	end

	if IsValid(PhysObj) then
		PhysObj:SetMass(Rack.ACFLegalMass)
	end
end

local function GetNextAttachmentName(Rack)
	if not next(Rack.AttachPoints) then return nil end

	local Name = next(Rack.AttachPoints)
	local Start = Name

	repeat
		Name = next(Rack.AttachPoints, Name) or next(Rack.AttachPoints)

		if not Rack.Missiles[Name] then
			return Name
		end
	until Name == Start

	return nil
end

local function GetMissileAngPos(Rack, Missile, AttachName)
	local Gun = list.Get("ACFEnts").Guns[Missile.BulletData.Id]
	local RackData = ACF.Weapons.Rack[Rack.Id]
	local Position = Rack.AttachPoints[AttachName]

	if Gun and RackData then
		local Offset = (Gun.modeldiameter or Gun.caliber) / (2.54 * 2)
		local MountPoint = RackData.mountpoints[AttachName]

		Position = Position + MountPoint.offset + MountPoint.scaledir * Offset
	end

	return Position, Rack:GetAngles()
end

local function AddMissile(Rack)
	local Crate = GetCrate(Rack)
	local Attach = GetNextAttachmentName(Rack)
	if Rack.AmmoCount >= Rack.MagSize then return false end
	if not Attach then return false end
	if not IsValid(Crate) then return false end
	local Owner = Rack.Owner
	local BulletData = ACFM_CompactBulletData(Crate)
	BulletData.IsShortForm = true
	BulletData.Owner = Owner
	local Missile = ents.Create("acf_missile")
	Missile.Owner = Owner
	Missile.DoNotDuplicate = true
	Missile.Launcher = Rack
	Missile.DisableDamage = Rack.ProtectMissile
	Missile.Attachment = Attach
	Missile:SetBulletData(BulletData)
	local RackModel = ACF_GetRackValue(Rack.Id, "rackmdl") or ACF_GetGunValue(BulletData.Id, "rackmdl")

	if RackModel then
		Missile:SetModelEasy(RackModel)
		Missile.RackModelApplied = true
	end

	local Pos, Angles = GetMissileAngPos(Rack, Missile, Attach)
	Missile:Spawn()
	Missile:SetParent(Rack)
	Missile:SetParentPhysNum(0)
	Missile:SetPos(Pos)
	Missile:SetAngles(Angles)

	if Rack.HideMissile then
		Missile:SetNoDraw(true)
	end

	Rack:EmitSound("acf_extra/tankfx/resupply_single.wav", 500, 100)
	Rack:UpdateAmmoCount(Attach, Missile)

	Crate.Ammo = Crate.Ammo - 1
	SetLoadedWeight(Rack)

	return Missile
end

local function Reload(Rack)
	if not Rack.Ready and not GetNextAttachmentName(Rack) then return end
	if Rack.AmmoCount >= Rack.MagSize then return false end
	if not IsValid(GetCrate(Rack)) then return false end
	if Rack.NextFire < 1 then return false end
	local Missile = AddMissile(Rack)
	Rack.NextFire = 0
	Rack.PostReloadWait = CurTime() + 5
	Rack.WaitFunction = Rack.GetReloadTime
	Rack.Ready = false
	Rack.ReloadTime = IsValid(Missile) and Rack:GetReloadTime(Missile) or 1
	Wire_TriggerOutput(Rack, "Ready", 0)
end

local function CheckLegal(Rack)
	-- Update the ancestor of the rack
	Rack.Physical = ACF_GetAncestor(Rack)

	return ACF_IsLegal(Rack) and Rack.Physical:IsSolid()
end

local function FireMissile(Rack)
	if CheckLegal(Rack) and Rack.Ready and Rack.PostReloadWait < CurTime() then
		local Attachment, Missile = next(Rack.Missiles)
		local ReloadTime = 0.5

		if IsValid(Missile) then
			if hook.Run("ACF_FireShell", Rack, Missile.BulletData) == false then return end

			ReloadTime = Rack:GetFireDelay(Missile)

			local Pos, Angles = GetMissileAngPos(Rack, Missile, Attachment)
			local MuzzleVec = Angles:Forward()
			local ConeAng = math.tan(math.rad(Rack.Inaccuracy * ACF.GunInaccuracyScale))
			local RandDirection = (Rack:GetUp() * math.Rand(-1, 1) + Rack:GetRight() * math.Rand(-1, 1)):GetNormalized()
			local Spread = RandDirection * ConeAng * (math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)))
			local ShootVec = (MuzzleVec + Spread):GetNormalized()

			Missile.Filter = {Rack}
			Missile:SetParent(nil)
			Missile:SetNoDraw(false)

			for _, Load in pairs(Rack.Missiles) do
				Missile.Filter[#Missile.Filter + 1] = Load
			end

			local BulletData = Missile.BulletData
			local BulletSpeed = BulletData.MuzzleVel or Missile.MinimumSpeed or 1

			if Missile.RackModelApplied then
				Missile:SetModelEasy(ACF_GetGunValue(BulletData.Id, "model"))
				Missile.RackModelApplied = nil
			end

			local PhysMissile = Missile:GetPhysicsObject()

			if IsValid(PhysMissile) then
				PhysMissile:SetMass(Missile.RoundWeight)

				BulletData.Flight = ShootVec * BulletSpeed

				if Rack.FireDelay and Rack.FireDelay > 0 then
					PhysMissile:EnableMotion(true)
					PhysMissile:EnableGravity(true)
					PhysMissile:SetVelocity(Rack.Physical:GetVelocity())

					timer.Simple(Rack.FireDelay, function()
						if not Missile.Disabled then
							BulletData.Flight = Missile:GetForward() * BulletSpeed

							PhysMissile:EnableMotion(false)
							PhysMissile:EnableGravity(false)

							Missile:DoFlight(Missile:GetPos(), BulletData.Flight:GetNormalized())
							Missile:Launch()
						end
					end)
				else
					Missile:DoFlight(Rack:LocalToWorld(Pos), ShootVec)
					Missile:Launch()
				end
			end

			if Rack.Sound and Rack.Sound ~= "" then
				Missile.BulletData.Sound = Rack.Sound
			end

			Rack:UpdateAmmoCount(Attachment)

			Missile:EmitSound("phx/epicmetal_hard.wav", 500, 100)
			SetLoadedWeight(Rack)
		else
			Rack:EmitSound("weapons/pistol/pistol_empty.wav", 500, 100)
		end

		Wire_TriggerOutput(Rack, "Ready", 0)
		Rack.Ready = false
		Rack.NextFire = 0
		Rack.WaitFunction = Rack.GetFireDelay
		Rack.ReloadTime = ReloadTime
	else
		Rack:EmitSound("weapons/pistol/pistol_empty.wav", 500, 100)
	end
end

local function CheckCrateDistance(Rack, Crate)
	if not IsValid(Rack) then return false end
	if not IsValid(Crate) then return false end

	return Rack:GetPos():Distance(Crate:GetPos()) >= 512
end

local function TrimDistantCrates(Rack)
	if not next(Rack.Crates) then return end

	for Crate in pairs(Rack.Crates) do
		if CheckCrateDistance(Rack, Crate) and Crate.Load then
			local SoundStr = "physics/metal/metal_box_impact_bullet" .. tostring(math.random(1, 3)) .. ".wav"
			Rack:EmitSound(SoundStr, 500, 100)
			Rack:Unlink(Crate)
		end
	end
end

local function UpdateRefillBonus(Rack)
	local TotalBonus = 0
	local SelfPos = Rack:GetPos()
	local Efficiency = 0.11 * ACF.AmmoMod -- Copied from acf_ammo, beware of changes!
	local MinFullEfficiency = 50000 * Efficiency -- The minimum crate volume to provide full efficiency bonus all by itself.
	local MaxDist = ACF.RefillDistance

	if next(ACF.AmmoCrates) then
		for Crate in pairs(ACF.AmmoCrates) do
			if Crate.RoundType == "Refill" and Crate.Ammo > 0 and Crate.Load then
				local CrateDist = SelfPos:Distance(Crate:GetPos())

				if CrateDist < MaxDist then
					CrateDist = math.max(0, CrateDist * 2 - MaxDist)
					local Bonus = (Crate.Volume / MinFullEfficiency) * (MaxDist - CrateDist) / MaxDist
					TotalBonus = TotalBonus + Bonus
				end
			end
		end
	end

	Rack.ReloadMultiplierBonus = math.min(TotalBonus, 1)
	Rack:SetNWFloat("ReloadBonus", Rack.ReloadMultiplierBonus)

	return Rack.ReloadMultiplierBonus
end

local function SetStatusString(Rack)
	local PhysObj = Rack:GetPhysicsObject()

	if not IsValid(PhysObj) then
		Rack:SetNWString("Status", "Something truly horrifying happened to this rack - it has no physics object.")

		return
	end

	local OpticalWeight = Rack.ACFLegalMass or Rack.EmptyMass

	if PhysObj:GetMass() < OpticalWeight then
		Rack:SetNWString("Status", "Underweight! (should be " .. tostring(OpticalWeight) .. " kg)")

		return
	end

	if not IsValid(GetCrate(Rack)) then
		Rack:SetNWString("Status", "Can't find ammo!")

		return
	end

	Rack:SetNWString("Status", "")
end

local function ACF_Rack_OnPhysgunDrop(Player, Ent)
	if Ent:GetClass() == "acf_rack" then
		timer.Simple(0.01, function()
			if IsValid(Ent) then
				SetLoadedWeight(Ent)
			end
		end)
	end
end

hook.Add("PhysgunDrop", "ACF_Rack_OnPhysgunDrop", ACF_Rack_OnPhysgunDrop)

function ENT:GetReloadTime(NextMissile)
	local ReloadMult = self.ReloadMultiplier or 1
	local ReloadBonus = self.ReloadMultiplierBonus or 0
	local MagSize = (self.MagSize or 1) ^ 1.1
	local DelayMult = (ReloadMult - (ReloadMult - 1) * ReloadBonus) / MagSize
	local ReloadTime = self:GetFireDelay(NextMissile) * DelayMult
	self:SetNWFloat("Reload", ReloadTime)

	return ReloadTime
end

function ENT:GetFireDelay(NextMissile)
	if not IsValid(NextMissile) then
		self:SetNWFloat("Interval", self.LastValidFireDelay or 1)

		return self.LastValidFireDelay or 1
	end

	local BulletData = NextMissile.BulletData
	local Gun = list.Get("ACFEnts").Guns[BulletData.Id]
	if not Gun then return self.LastValidFireDelay or 1 end
	local Class = list.Get("ACFClasses").GunClass[Gun.gunclass]
	local Interval = ((BulletData.RoundVolume / 500) ^ 0.60) * (Gun.rofmod or 1) * (Class.rofmod or 1)
	self.LastValidFireDelay = Interval
	self:SetNWFloat("Interval", Interval)

	return Interval
end

function ENT:ACF_Activate(Recalc)
	local EmptyMass = self.RoundWeight or self.EmptyMass or 10
	local PhysObj = self:GetPhysicsObject()
	self.ACF = self.ACF or {}

	if not self.ACF.Area then
		self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
	end

	if not self.ACF.Volume then
		self.ACF.Volume = PhysObj:GetVolume() * 16.38
	end

	local Armour = self.CustomArmour or (EmptyMass * 1000 / self.ACF.Area / 0.78) --So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
	local Health = self.ACF.Volume / ACF.Threshold --Setting the threshold of the prop Area gone
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Health = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type = nil
	self.ACF.Mass = self.EmptyMass
	self.ACF.Density = PhysObj:GetMass() * 1000 / self.ACF.Volume
	self.ACF.Type = "Prop"
end

function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor)
	if self.Exploded then
		return {
			Damage = 0,
			Overkill = 1,
			Loss = 0,
			Kill = false
		}
	end

	local HitRes = ACF_PropDamage(Entity, Energy, FrArea, Angle, Inflictor) --Calling the standard damage prop function

	-- If the rack is destroyed.
	if HitRes.Kill then
		-- Which bulletdata to use?! Let's let them figure that out.
		if hook.Run("ACF_AmmoExplode", self, nil) == false then return HitRes end
		self.Exploded = true

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		if next(self.Missiles) then
			for _, Missile in pairs(self.Missiles) do
				Missile:Detonate()
			end
		end
	end

	return HitRes -- This function needs to return HitRes
end

function ENT:CanLoadCaliber(Caliber)
	return ACF_RackCanLoadCaliber(self.Id, Caliber)
end

function ENT:Link(Crate)
	if not IsValid(Crate) then return false, "Invalid entity!" end
	if Crate:GetClass() ~= "acf_ammo" then return false, "Racks can only be linked to ammo crates!" end
	if self.Crates[Crate] then return false, "Crate is already linked to this gun!" end
	if Crate.RoundType == "Refill" then return false, "Refill crates cannot be linked!" end
	if Crate.Guns[self] then return false, "Crate is already linked to this gun!" end

	local BulletData = Crate.BulletData
	local GunClass = ACF_GetGunValue(BulletData, "gunclass")
	local Blacklist = ACF.AmmoBlacklist[Crate.RoundType] or {}

	if not GunClass or table.HasValue(Blacklist, GunClass) then return false, "That round type cannot be used with this gun!" end

	local Result, Message = ACF_CanLinkRack(self.Id, BulletData.Id, BulletData, self)
	if not Result then return Result, Message end

	self.Crates[Crate] = true
	Crate.Guns[self] = true

	return true, "Link successful!"
end

function ENT:Unlink(Target)
	if self.Crates[Target] then
		self.Crates[Target] = nil
		Target.Guns[self] = nil

		return true, "Unlink successful!"
	else
		return false, "That entity is not linked to this gun!"
	end
end

function ENT:UnloadAmmo()
	-- we're ok with mixed munitions.
end

local WireTable = {
	gmod_wire_adv_pod = true,
	gmod_wire_pod = true,
	gmod_wire_keyboard = true,
	gmod_wire_joystick = true,
	gmod_wire_joystick_multi = true
}

function ENT:GetUser(Input)
	if not Input then return nil end

	if Input:GetClass() == "gmod_wire_adv_pod" then
		if Input.Pod then return Input.Pod:GetDriver() end
	elseif Input:GetClass() == "gmod_wire_pod" then
		if Input.Pod then return Input.Pod:GetDriver() end
	elseif Input:GetClass() == "gmod_wire_keyboard" then
		if Input.ply then return Input.ply end
	elseif Input:GetClass() == "gmod_wire_joystick" then
		if Input.Pod then return Input.Pod:GetDriver() end
	elseif Input:GetClass() == "gmod_wire_joystick_multi" then
		if Input.Pod then return Input.Pod:GetDriver() end
	elseif Input:GetClass() == "gmod_wire_expression2" then
		if Input.Inputs.Fire then
			return self:GetUser(Input.Inputs.Fire.Src)
		elseif Input.Inputs.Shoot then
			return self:GetUser(Input.Inputs.Shoot.Src)
		elseif Input.Inputs then
			for _, v in pairs(Input.Inputs) do
				if not IsValid(v.Src) then return Input.Owner or Input:GetOwner() end
				if WireTable[v.Src:GetClass()] then return self:GetUser(v.Src) end
			end
		end
	end

	return Input.Owner or Input:GetOwner()
end

local Inputs = {
	Fire = function(Rack, Value)
		Rack.Firing = ACF.GunfireEnabled and Value ~= 0

		if Rack.Firing and Rack.NextFire >= 1 then
			Rack.User = Rack:GetUser(Rack.Inputs.Fire.Src)

			if not IsValid(Rack.User) then
				Rack.User = Rack.Owner
			end

			FireMissile(Rack)
		end
	end,
	["Fire Delay"] = function(Rack, Value)
		Rack.FireDelay = math.Clamp(Value, 0, 1)
	end,
	Reload = function(Rack, Value)
		if Value ~= 0 then
			Reload(Rack)
		end
	end,
	["Target Pos"] = function(Rack, Value)
		Wire_TriggerOutput(Rack, "Position", Value)
	end,
	["Target Ent"] = function(Rack, Value)
		Wire_TriggerOutput(Rack, "Target", Value)
	end,
}

function ENT:TriggerInput(Input, Value)
	if Inputs[Input] then
		Inputs[Input](self, Value)
	end
end

function ENT:UpdateAmmoCount(Attachment, Missile)
	self.Missiles[Attachment] = Missile
	self.AmmoCount = self.AmmoCount + (Missile and 1 or -1)
	self:SetNWInt("Ammo", self.AmmoCount)

	Wire_TriggerOutput(self, "Shots Left", self.AmmoCount)
end

function ENT:Think()
	local _, Missile = next(self.Missiles)
	local Time = CurTime()

	if self.LastSend + 1 <= Time then
		TrimDistantCrates(self)
		UpdateRefillBonus(self)
		self:GetReloadTime(Missile)
		SetStatusString(self)
		self.LastSend = Time
	end

	self.NextFire = math.min(self.NextFire + (Time - self.LastThink) / self:WaitFunction(Missile), 1)

	if self.NextFire >= 1 then
		if Missile then
			self.Ready = true
			Wire_TriggerOutput(self, "Ready", 1)

			if self.Firing then
				FireMissile(self)
			elseif self.Inputs.Reload and self.Inputs.Reload.Value ~= 0 then
				Reload(self)
			elseif self.ReloadTime and self.ReloadTime > 1 then
				self:EmitSound("acf_extra/airfx/weapon_select.wav", 500, 100)
				self.ReloadTime = nil
			end
		else
			if self.Inputs.Reload and self.Inputs.Reload.Value ~= 0 then
				Reload(self)
			end
		end
	end

	self:NextThink(Time + 0.5)
	self.LastThink = Time

	return true
end

function MakeACF_Rack(Owner, Pos, Angle, Id, MissileId)
	if not Owner:CheckLimit("_acf_gun") then return false end

	local Rack = ents.Create("acf_rack")
	local GunClass = ACF.Weapons.Guns[MissileId]

	if not IsValid(Rack) then return false end

	Id = Id or Rack.Id

	if not Id or not ACF.Weapons.Rack[Id] then

		if not GunClass then
			error("Couldn't spawn the missile rack: can't find the gun-class '" + tostring(MissileId) + "'.")
		elseif not GunClass.rack then
			error("Couldn't spawn the missile rack: '" + tostring(MissileId) + "' doesn't have a preferred missile rack.")
		end

		Id = GunClass.rack
	end

	local GunDef = ACF.Weapons.Rack[Id] or error("Couldn't find the " .. tostring(Id) .. " gun-definition!")
	local RackClass = ACF.Classes.Rack[GunDef.gunclass] or error("Couldn't find the " .. tostring(Rack.Class) .. " gun-class!")

	Rack:SetPlayer(Owner)
	Rack:SetModel(GunDef.model)
	Rack:SetAngles(Angle)
	Rack:SetPos(Pos)
	Rack:Spawn()

	Rack:PhysicsInit(SOLID_VPHYSICS)
	Rack:SetMoveType(MOVETYPE_VPHYSICS)

	Owner:AddCount("_acf_gun", Rack)
	Owner:AddCleanup("acfmenu", Rack)

	Rack.Owner				= Owner
	Rack.Id					= Id
	Rack.MissileId			= MissileId
	Rack.Model				= GunDef.model
	Rack.EmptyMass			= GunDef.weight
	Rack.ACFLegalMass		= Rack.EmptyMass
	Rack.Class				= GunDef.gunclass
	Rack.RoFmod				= RackClass.rofmod or 1
	Rack.PGRoFmod			= math.max(0, Rack.RoFmod) -- Custom BS for karbine. Per Rack ROF.
	Rack.MagSize			= GunDef.magsize and math.max(1, GunDef.magsize) or 1 -- Custom BS for karbine. Magazine Size, Mag reload Time
	Rack.MagReload			= GunDef.magreload and math.max(0, GunDef.magreload) or 0
	Rack.Sound				= GunDef.sound or RackClass.sound
	Rack.Inaccuracy			= RackClass.spread
	Rack.HideMissile		= ACF_GetRackValue(Id, "hidemissile")
	Rack.ProtectMissile		= GunDef.protectmissile or RackClass.protectmissile
	Rack.CustomArmour		= GunDef.armour or RackClass.armour
	Rack.ReloadMultiplier	= ACF_GetRackValue(Id, "reloadmul")
	Rack.WhitelistOnly		= ACF_GetRackValue(Id, "whitelistonly")
	Rack.SpecialHealth		= true -- If true needs a special ACF_Activate function
	Rack.SpecialDamage		= true -- If true needs a special ACF_OnDamage function
	Rack.ReloadTime			= 1
	Rack.Ready				= true
	Rack.NextFire			= 1
	Rack.PostReloadWait		= CurTime()
	Rack.WaitFunction		= Rack.GetFireDelay
	Rack.LastSend			= 0
	Rack.FireDelay			= GunClass and GunClass.CanDelay and 0
	Rack.IsMaster			= true
	Rack.LastThink			= CurTime()
	Rack.AmmoCount			= 0
	Rack.AttachPoints		= {}
	Rack.Missiles			= {}
	Rack.Crates				= Rack.Crates or {}

	Rack.BulletData = {
		Type = "Empty",
		PropMass = 0,
		ProjMass = 0
	}

	Rack.Inputs = Rack.FireDelay and WireLib.CreateInputs(Rack, {"Fire", "Fire Delay", "Reload", "Target Pos [VECTOR]", "Target Ent [ENTITY]"}) or WireLib.CreateInputs(Rack, {"Fire", "Reload", "Target Pos [VECTOR]", "Target Ent [ENTITY]"})
	Rack.Outputs = WireLib.CreateOutputs(Rack, {"Ready", "Entity [ENTITY]", "Shots Left", "Position [VECTOR]", "Target [ENTITY]"})

	Wire_TriggerOutput(Rack, "Entity", Rack)
	Wire_TriggerOutput(Rack, "Ready", 1)

	local MountPoints = ACF.Weapons.Rack[Rack.Id].mountpoints

	for _, Data in pairs(Rack:GetAttachments()) do
		local Attachment = Rack:GetAttachment(Data.id)

		if MountPoints[Data.name] then
			Rack.AttachPoints[Data.name] = Rack:WorldToLocal(Attachment.Pos)
		end
	end

	Rack:SetNWString("Class", Rack.Class)
	Rack:SetNWString("ID", Rack.Id)
	Rack:SetNWString("GunType", Rack.MissileId or Rack.Id)
	Rack:SetNWString("Sound", Rack.Sound)

	local PhysObj = Rack:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:SetMass(Rack.EmptyMass)
	end

	SetStatusString(Rack)

	return Rack
end

list.Set("ACFCvars", "acf_rack", {"data9", "id"})
duplicator.RegisterEntityClass("acf_rack", MakeACF_Rack, "Pos", "Angle", "Id", "MissileId")

function ENT:PreEntityCopy()
	if next(self.Crates) then
		local EntIds = {}

		-- Adding valid entities and cleaning invalid ones
		for Crate in pairs(self.Crates) do
			if IsValid(Crate) then
				table.insert(EntIds, Crate:EntIndex())
			end
		end

		if next(EntIds) then
			local Info = {
				entities = EntIds
			}

			duplicator.StoreEntityModifier(self, "ACFAmmoLink", Info)
		end
	end

	duplicator.StoreEntityModifier(self, "ACFRackInfo", {
		Id = self.Id,
		MissileId = self.MissileId
	})

	-- Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local AmmoLink = Ent.EntityMods.ACFAmmoLink
	local MissileId = Ent.EntityMods.ACFRackInfo.MissileId

	if MissileId then
		self.MissileId = MissileId
	end

	if AmmoLink and AmmoLink.entities then
		for _, Index in pairs(AmmoLink.entities) do
			local Ammo = CreatedEntities[Index]

			if IsValid(Ammo) and Ammo:GetClass() == "acf_ammo" then
				self:Link(Ammo)

				if not self.MissileId then
					self.MissileId = Ammo.RoundId
				end
			end
		end

		Ent.EntityMods.ACFAmmoLink = nil
	end

	-- Wire dupe info
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:OnRestore()
	Wire_Restored(self)
end