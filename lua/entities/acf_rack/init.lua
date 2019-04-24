-- init.lua

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include("shared.lua")




DEFINE_BASECLASS("acf_explosive")




local WireTable = {
	gmod_wire_adv_pod = true,
	gmod_wire_pod = true,
	gmod_wire_keyboard = true,
	gmod_wire_joystick = true,
	gmod_wire_joystick_multi = true
}




local function TrimNullMissiles( Rack ) -- Missiles should clean themselves after being destroyed

	for i = #Rack.Missiles, 1, -1 do
		if not IsValid(Rack.Missiles[i]) then
			table.remove(Rack.Missiles, i)
		end
	end

end




local function FindNextCrate( Rack )

	local Link = Rack.AmmoLink

	if not next(Link) then return nil end

	for i = 1, #Link do
		Rack.Sequence = Rack.Sequence % #Link + 1

		local Crate = Link[Rack.Sequence]

		if Crate.Ammo > 0 and Crate.Load then return Crate end
	end

	return nil
end




local function CanReload( Rack )

	if #Rack.Missiles >= Rack.MagSize then return false end
	if not IsValid(FindNextCrate(Rack)) then return false end
	if Rack.NextFire < 1 then return false end

	return true

end




local function MuzzleEffect( Missile )

	Missile:EmitSound( "phx/epicmetal_hard.wav", 500, 100 )

end




local function SetLoadedWeight( Rack )

	local PhysObj = Rack:GetPhysicsObject()

	Rack.LegalWeight = Rack.Mass

	TrimNullMissiles(Rack)

	for i = 1, #Rack.Missiles do
		local Missile = Rack.Missiles[i]
		local PhysMissile = Missile:GetPhysicsObject()

		Rack.LegalWeight = Rack.LegalWeight + Missile.RoundWeight

		-- Will result in slightly heavier rack but is probably a good idea to have some mass for any damage calcs.
		if IsValid(PhysMissile) then
			PhysMissile:SetMass( 5 )
		end
	end

	if IsValid(PhysObj) then
		PhysObj:SetMass( Rack.LegalWeight )
	end

end




local function AddMissile( Rack )

	TrimNullMissiles(Rack)

	local Index = #Rack.Missiles
	local Crate = FindNextCrate(Rack)

	if Index >= Rack.MagSize then return false end
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

	Missile:SetBulletData(BulletData)

	local RackModel = ACF_GetRackValue(Rack.Id, "rackmdl") or ACF_GetGunValue(BulletData.Id, "rackmdl")

	if RackModel then
		Missile:SetModelEasy( RackModel )
		Missile.RackModelApplied = true
	end

	Missile:SetParent(Rack)
	Missile:SetParentPhysNum(0)

	timer.Simple(0.02, function()
		if not IsValid(Missile) then return end

		local _, Muzzle = Rack:GetMuzzle(Index, Missile)

		if IsValid(Rack:GetParent()) then
			Missile:SetPos(Muzzle.Pos)
			Missile:SetAngles(Rack:GetAngles())
		else
			Missile:SetPos(Rack:WorldToLocal(Muzzle.Pos))
			Missile:SetAngles(Muzzle.Ang)
		end
	end)

	if Rack.HideMissile then Missile:SetNoDraw(true) end

	Missile:Spawn()

	Rack:EmitSound( "acf_extra/tankfx/resupply_single.wav", 500, 100 )

	Rack.Missiles[Index + 1] = Missile

	Crate.Ammo = Crate.Ammo - 1

	SetLoadedWeight(Rack)

	return Missile

end




local function PeekMissile( Rack )

	TrimNullMissiles(Rack)

	local Index = #Rack.Missiles

	if Index == 0 then return false end

	return Rack.Missiles[Index], Index

end




local function LoadAmmo( Rack )

	if not CanReload(Rack) then return false end

	local Missile = AddMissile(Rack)

	TrimNullMissiles(Rack)
	Rack:SetNWInt( "Ammo", #Rack.Missiles )

	Rack.NextFire = 0
	Rack.PostReloadWait = CurTime() + 5
	Rack.WaitFunction = Rack.GetReloadTime

	Rack.Ready = false
	Rack.ReloadTime = IsValid(Missile) and Rack:GetReloadTime(Missile) or 1

	Wire_TriggerOutput(Rack, "Ready", 0)

	Rack:Think()

	return true

end




local function Reload( Rack )

	if Rack.Ready or not IsValid(PeekMissile(Rack)) then
		LoadAmmo(Rack)
	end

end




local function CheckLegal( Rack )

	--make sure it's not invisible to traces
	if not Rack:IsSolid() then return false end

	-- make sure weight is not below stock
	if Rack:GetPhysicsObject():GetMass() < (Rack.LegalWeight or Rack.Mass) then return false end

	-- update the acfphysparent
	ACF_GetPhysicalAncestor(Rack)

	return Rack.acfphysparent:IsSolid()

end




local function PopMissile( Rack )

	local Missile, Index = PeekMissile(Rack)

	if not Missile then return false end

	table.remove(Rack.Missiles, Index)

	return Missile, Index

end




local function GetInaccuracy( Rack )

	return Rack.Inaccuracy * ACF.GunInaccuracyScale

end




local function FireMissile( Rack )

	if CheckLegal(Rack) and Rack.Ready and Rack.PostReloadWait < CurTime() then

		local NextMissile = PeekMissile(Rack)
		local CanFire = NextMissile and hook.Run("ACF_FireShell", Rack, NextMissile.BulletData ) or true

		if not CanFire then return end

		local ReloadTime = 0.5
		local Missile, Index = PopMissile(Rack)

		if IsValid(Missile) then

			ReloadTime = Rack:GetFireDelay(Missile)

			local _, Muzzle = Rack:GetMuzzle(Index - 1, Missile)

			local MuzzlePos = Muzzle.Pos
			local MuzzleVec = Muzzle.Ang:Forward()

			local ConeAng = math.tan(math.rad(GetInaccuracy(Rack)))
			local RandDirection = (Rack:GetUp() * math.Rand(-1, 1) + Rack:GetRight() * math.Rand(-1, 1)):GetNormalized()
			local Spread = RandDirection * ConeAng * (math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)))
			local ShootVec = (MuzzleVec + Spread):GetNormalized()

			local Filter = {
				Rack,
				Missile
			}
			table.Add(Filter, Rack.Missiles)

			Missile.Filter = Filter
			Missile.DisableDamage = false

			Missile:SetParent(nil)
			Missile:SetNoDraw(false)

			local BulletData = Missile.BulletData
			local BulletSpeed = BulletData.MuzzleVel or Missile.MinimumSpeed or 1

			if not IsValid(Rack:GetParent()) then
				BulletData.Pos = MuzzlePos
				BulletData.Flight = ShootVec * BulletSpeed
			else
				BulletData.Pos = Rack:LocalToWorld(MuzzlePos)
				BulletData.Flight = (Rack:GetAngles():Forward() + Spread):GetNormalized() * BulletSpeed
			end

			if Missile.RackModelApplied then
				Missile:SetModelEasy( ACF_GetGunValue(BulletData.Id, "model") )
				Missile.RackModelApplied = nil
			end

			local PhysMissile = Missile:GetPhysicsObject()

			if IsValid(PhysMissile) then
				PhysMissile:SetMass( Missile.RoundWeight )
			end

			if Rack.Sound and Rack.Sound ~= "" then
				Missile.BulletData.Sound = Rack.Sound
			end

			Missile:DoFlight(BulletData.Pos, ShootVec)
			Missile:Launch()

			MuzzleEffect( Rack )
			SetLoadedWeight(Rack)

			Rack:SetNWInt("Ammo", #Rack.Missiles)

		else
			Rack:EmitSound("weapons/pistol/pistol_empty.wav", 500, 100)
		end

		Wire_TriggerOutput(Rack, "Ready", 0)

		Rack.Ready = false
		Rack.NextFire = 0
		Rack.WaitFunction = Rack.GetFireDelay
		Rack.ReloadTime = ReloadTime

	else
		Rack:EmitSound("weapons/pistol/pistol_empty.wav",500,100)
	end

end




local function CheckCrateDistance( Rack, Crate )

	if not IsValid(Rack) then return false end
	if not IsValid(Crate) then return false end

	return Rack:GetPos():Distance(Crate:GetPos()) >= 512

end




local function TrimDistantCrates( Rack )

	if not next(Rack.AmmoLink) then return end

	for k, Crate in pairs(Rack.AmmoLink) do
		if CheckCrateDistance( Rack, Crate ) and Crate.Load then
			local SoundStr = "physics/metal/metal_box_impact_bullet" .. tostring(math.random(1, 3)) .. ".wav"

			Rack:EmitSound(SoundStr, 500, 100)
			Rack:Unlink( Crate )
		end
	end

end




local function UpdateRefillBonus( Rack )

	local TotalBonus = 0
	local SelfPos = Rack:GetPos()

	local Efficiency = 0.11 * ACF.AmmoMod			-- Copied from acf_ammo, beware of changes!
	local MinFullEfficiency = 50000 * Efficiency	-- The minimum crate volume to provide full efficiency bonus all by itself.
	local MaxDist = ACF.RefillDistance

	if ACF.AmmoCrates and next(ACF.AmmoCrates) then
		for k, v in pairs(ACF.AmmoCrates) do

			if v.RoundType == "Refill" and v.Ammo > 0 and v.Load then
				local CrateDist = SelfPos:Distance(v:GetPos())

				if CrateDist < MaxDist then

					CrateDist = math.max(0, CrateDist * 2 - MaxDist)

					local Bonus = ( v.Volume / MinFullEfficiency ) * ( MaxDist - CrateDist ) / MaxDist

					TotalBonus = TotalBonus + Bonus
				end
			end
		end
	end

	Rack.ReloadMultiplierBonus = math.min(TotalBonus, 1)
	Rack:SetNWFloat("ReloadBonus", Rack.ReloadMultiplierBonus)

	return Rack.ReloadMultiplierBonus

end




local function SetStatusString( Rack )

	local PhysObj = Rack:GetPhysicsObject()

	if not IsValid(PhysObj) then
		Rack:SetNWString("Status", "Something truly horrifying happened to this rack - it has no physics object.")
		return
	end

	local OpticalWeight = Rack.LegalWeight or Rack.Mass

	if PhysObj:GetMass() < OpticalWeight then
		Rack:SetNWString("Status", "Underweight! (should be " .. tostring(OpticalWeight) .. " kg)")
		return
	end

	if not IsValid(FindNextCrate(Rack)) then
		Rack:SetNWString("Status", "Can't find ammo!")
		return
	end

	Rack:SetNWString("Status", "")

end




local function ACF_Rack_OnPhysgunDrop( Player, Ent )

	if Ent:GetClass() == "acf_rack" then
		timer.Simple(0.01, function() if IsValid(Ent) then SetLoadedWeight(Ent) end end)
	end

end

hook.Add("PhysgunDrop", "ACF_Rack_OnPhysgunDrop", ACF_Rack_OnPhysgunDrop)




function ENT:GetReloadTime( NextMissile )

	local ReloadMult = self.ReloadMultiplier or 1
	local ReloadBonus = self.ReloadMultiplierBonus or 0
	local MagSize = (self.MagSize or 1) ^ 1.1
	local DelayMult = (ReloadMult - (ReloadMult - 1) * ReloadBonus) / MagSize
	local ReloadTime = self:GetFireDelay(NextMissile) * DelayMult

	self:SetNWFloat( "Reload", ReloadTime )

	return ReloadTime

end




function ENT:GetFireDelay( NextMissile )

	if not IsValid( NextMissile ) then
		self:SetNWFloat( "Interval", self.LastValidFireDelay or 1 )

		return self.LastValidFireDelay or 1
	end

	local BulletData = NextMissile.BulletData
	local Gun = list.Get("ACFEnts").Guns[BulletData.Id]

	if not Gun then return self.LastValidFireDelay or 1 end

	local Class = list.Get("ACFClasses").GunClass[Gun.gunclass]
	local Interval = ((BulletData.RoundVolume / 500) ^ 0.60) * (Gun.rofmod or 1) * (Class.rofmod or 1)

	self.LastValidFireDelay = Interval
	self:SetNWFloat( "Interval", Interval )

	return Interval

end




function ENT:Initialize()

	self.BaseClass.Initialize(self)

	self.SpecialHealth = true	--If true needs a special ACF_Activate function
	self.SpecialDamage = true	--If true needs a special ACF_OnDamage function --NOTE: you can't "fix" missiles with setting this to false, it acts like a prop!!!!
	self.ReloadTime = 1
	self.Ready = true
	self.Firing = nil
	self.NextFire = 1
	self.PostReloadWait = CurTime()
	self.WaitFunction = self.GetFireDelay
	self.LastSend = 0
	self.Owner = self

	self.IsMaster = true
	self.Sequence = 1
	self.LastThink = CurTime()

	self.BulletData = {
		Type = "Empty",
		PropMass = 0,
		ProjMass = 0
	}

	self.Inaccuracy = 1

	self.Inputs = WireLib.CreateSpecialInputs( self, { "Fire",      "Reload",   "Target Pos",   "Target Ent" },
													 { "NORMAL",    "NORMAL",   "VECTOR",       "ENTITY"    } )

	self.Outputs = WireLib.CreateSpecialOutputs( self, 	{ "Ready",	"Entity",	"Shots Left",  "Position",  "Target" },
														{ "NORMAL",	"ENTITY",	"NORMAL",      "VECTOR",    "ENTITY" } )

	Wire_TriggerOutput(self, "Entity", self)
	Wire_TriggerOutput(self, "Ready", 1)
	self.WireDebugName = "ACF Rack"

	self.Missiles = {}

	self.AmmoLink = {}

end




function ENT:ACF_Activate( Recalc )

	local EmptyMass = self.RoundWeight or self.Mass or 10
	local PhysObj = self:GetPhysicsObject()

	self.ACF = self.ACF or {}

	if not self.ACF.Area then
		self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
	end

	if not self.ACF.Volume then
		self.ACF.Volume = PhysObj:GetVolume() * 16.38
	end

	local Armour = self.CustomArmour or (EmptyMass * 1000 / self.ACF.Area / 0.78) --So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
	local Health = self.ACF.Volume / ACF.Threshold								--Setting the threshold of the prop Area gone
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Health = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type = nil
	self.ACF.Mass = self.Mass
	self.ACF.Density = PhysObj:GetMass() * 1000 / self.ACF.Volume
	self.ACF.Type = "Prop"

end




function ENT:ACF_OnDamage( Entity , Energy , FrArea , Angle , Inflictor )

	if self.Exploded then
		return { Damage = 0, Overkill = 1, Loss = 0, Kill = false }
	end

	local HitRes = ACF_PropDamage( Entity , Energy , FrArea , Angle , Inflictor )	--Calling the standard damage prop function

	-- If the rack is destroyed.
	if HitRes.Kill then
		-- Which bulletdata to use?! Let's let them figure that out.
		if hook.Run( "ACF_AmmoExplode", self, nil ) == false then return HitRes end

		TrimNullMissiles(self)

		self.Exploded = true

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		local Missiles = self.Missiles

		if next(Missiles) then
			for i = #Missiles, 1, -1 do
				Missiles[i]:Detonate()
			end
		end
	end

	return HitRes --This function needs to return HitRes

end




function ENT:CanLoadCaliber( Caliber )

	return ACF_RackCanLoadCaliber( self.Id, Caliber )

end




function ENT:Link( Crate )

	-- Don't link if it's not an ammo crate
	if not IsValid(Crate) or Crate:GetClass() ~= "acf_ammo" then
		return false, "Racks can only be linked to ammo crates!"
	end

	local BulletData = Crate.BulletData
	local BulletType = BulletData.RoundType or BulletData.Type

	-- Don't link if it's a refill crate
	if BulletType == "Refill" then
		return false, "Refill crates cannot be linked!"
	end

	-- Don't link if it's a blacklisted round type for this gun
	local GunClass = ACF_GetGunValue(BulletData, "gunclass")
	local Blacklist = ACF.AmmoBlacklist[BulletType] or {}

	if not GunClass or table.HasValue( Blacklist, GunClass ) then
		return false, "That round type cannot be used with this gun!"
	end

	-- Don't link if it's not a missile.
	local Result, Message = ACF_CanLinkRack(self.Id, BulletData.Id, BulletData, self)
	if not Result then return Result, Message end

	-- Don't link if it's already linked
	for k, v in pairs( self.AmmoLink ) do
		if v == Crate then
			return false, "That crate is already linked to this gun!"
		end
	end

	table.insert( self.AmmoLink, Crate )
	table.insert( Crate.Master, self )

	return true, "Link successful!"

end




function ENT:Unlink( Target )

	for k, v in pairs(self.AmmoLink) do
		if v == Target then
			table.remove(self.AmmoLink, k)

			return true, "Unlink successful!"
		end
	end

	return false, "That entity is not linked to this gun!"

end




function ENT:UnloadAmmo()
	-- we're ok with mixed munitions.
end




function ENT:GetUser( Input )
	if not Input then return nil end

	if Input:GetClass() == "gmod_wire_adv_pod" then
		if Input.Pod then
			return Input.Pod:GetDriver()
		end
	elseif Input:GetClass() == "gmod_wire_pod" then
		if Input.Pod then
			return Input.Pod:GetDriver()
		end
	elseif Input:GetClass() == "gmod_wire_keyboard" then
		if Input.ply then
			return Input.ply
		end
	elseif Input:GetClass() == "gmod_wire_joystick" then
		if Input.Pod then
			return Input.Pod:GetDriver()
		end
	elseif Input:GetClass() == "gmod_wire_joystick_multi" then
		if Input.Pod then
			return Input.Pod:GetDriver()
		end
	elseif Input:GetClass() == "gmod_wire_expression2" then
		if Input.Inputs.Fire then
			return self:GetUser(Input.Inputs.Fire.Src)
		elseif Input.Inputs.Shoot then
			return self:GetUser(Input.Inputs.Shoot.Src)
		elseif Input.Inputs then
			for _, v in pairs(Input.Inputs) do
				if not IsValid(v.Src) then return Input.Owner or Input:GetOwner() end
				if WireTable[v.Src:GetClass()] then
					return self:GetUser(v.Src)
				end
			end
		end
	end

	return Input.Owner or Input:GetOwner()

end




function ENT:TriggerInput( InputName, Value )

	if InputName == "Fire" then
		local Firing = ACF.GunfireEnabled and Value ~= 0

		if Firing and self.NextFire >= 1 then
			self.User = self:GetUser(self.Inputs.Fire.Src)
			if not IsValid(self.User) then self.User = self.Owner end
			FireMissile(self)
			self:Think()
		end

		self.Firing = Firing
	elseif InputName == "Reload" and Value ~= 0 then
		Reload(self)
	elseif InputName == "Target Pos" then
		Wire_TriggerOutput(self, "Position", Value)
	elseif InputName == "Target Ent" then
		Wire_TriggerOutput(self, "Target", Value)
	end

end




function ENT:Think()

	local Ammo = #self.Missiles
	local Time = CurTime()

	if self.LastSend + 1 <= Time then

		TrimDistantCrates(self)
		UpdateRefillBonus(self)

		TrimNullMissiles(self)
		Wire_TriggerOutput(self, "Shots Left", Ammo)

		self:SetNWString( "GunType", self.Id )
		self:SetNWInt( "Ammo", Ammo )

		self:GetReloadTime(PeekMissile(self))
		SetStatusString(self)

		self.LastSend = Time

	end

	self.NextFire = math.min(self.NextFire + (Time - self.LastThink) / self:WaitFunction(PeekMissile(self)), 1)

	if self.NextFire >= 1 and Ammo > 0 and Ammo <= self.MagSize then
		self.Ready = true
		Wire_TriggerOutput(self, "Ready", 1)

		if self.Firing then
			self.ReloadTime = nil
			FireMissile(self)
		elseif self.Inputs.Reload and self.Inputs.Reload.Value ~= 0 and CanReload(self) then
			self.ReloadTime = nil
			Reload(self)
		elseif self.ReloadTime and self.ReloadTime > 1 then
			self:EmitSound( "acf_extra/airfx/weapon_select.wav", 500, 100 )
			self.ReloadTime = nil
		end
	elseif self.NextFire >= 1 and Ammo == 0 then
		if self.Inputs.Reload and self.Inputs.Reload.Value ~= 0 and CanReload(self) then
			self.ReloadTime = nil
			Reload(self)
		end
	end

	self:NextThink(Time + 0.5)

	self.LastThink = Time

	return true

end




function MakeACF_Rack (Owner, Pos, Angle, Id, UpdateRack)

	if not Owner:CheckLimit("_acf_gun") then return false end

	local Rack = UpdateRack or ents.Create("acf_rack")

	if not IsValid(Rack) then return false end

	local List = ACF.Weapons.Rack
	local Classes = ACF.Classes.Rack

	Rack:SetAngles(Angle)
	Rack:SetPos(Pos)

	if not UpdateRack then
		Rack:Spawn()
		Owner:AddCount("_acf_gun", Rack)
		Owner:AddCleanup( "acfmenu", Rack )
	end

	Id = Id or Rack.Id

	Rack:SetPlayer(Owner)
	Rack.Owner = Owner
	Rack.Id = Id

	local GunDef = List[Id] or error("Couldn't find the " .. tostring(Id) .. " gun-definition!")

	Rack.MinCaliber  = GunDef.mincaliber
	Rack.MaxCaliber  = GunDef.maxcaliber
	Rack.caliber	 = GunDef.caliber
	Rack.Model		 = GunDef.model
	Rack.Mass		 = GunDef.weight
	Rack.LegalWeight = Rack.Mass
	Rack.Class		 = GunDef.gunclass

	-- Custom BS for karbine. Per Rack ROF.
	Rack.PGRoFmod = GunDef.rofmod and math.max(0, GunDef.rofmod) or 1

	-- Custom BS for karbine. Magazine Size, Mag reload Time
	Rack.MagSize = GunDef.magsize and math.max(1, GunDef.magsize) or 1
	Rack.MagReload = GunDef.magreload and math.max(0, GunDef.magreload) or 0

	local GunClass = Classes[Rack.Class] or error("Couldn't find the " .. tostring(Rack.Class) .. " gun-class!")

	Rack.Muzzleflash 	  = GunDef.muzzleflash or GunClass.muzzleflash or ""
	Rack.RoFmod			  = GunClass.rofmod
	Rack.Sound			  = GunDef.sound or GunClass.sound
	Rack.Inaccuracy		  = GunClass.spread
	Rack.HideMissile	  = ACF_GetRackValue(Id, "hidemissile")
	Rack.ProtectMissile   = GunDef.protectmissile or GunClass.protectmissile
	Rack.CustomArmour	  = GunDef.armour or GunClass.armour
	Rack.ReloadMultiplier = ACF_GetRackValue(Id, "reloadmul")
	Rack.WhitelistOnly	  = ACF_GetRackValue(Id, "whitelistonly")

	Rack:SetNWString( "Class",	Rack.Class )
	Rack:SetNWString( "ID",		Rack.Id )
	Rack:SetNWString( "Sound",	Rack.Sound )

	if not UpdateRack or Rack.Model ~= Rack:GetModel() then
		Rack:SetModel( Rack.Model )
		Rack:PhysicsInit( SOLID_VPHYSICS )
		Rack:SetMoveType( MOVETYPE_VPHYSICS )
		Rack:SetSolid( SOLID_VPHYSICS )
	end

	local PhysRack = Rack:GetPhysicsObject()

	if IsValid(PhysRack) then
		PhysRack:SetMass(Rack.Mass)
	end

	hook.Call("ACF_RackCreate", nil, Rack)

	undo.Create( "acf_rack" )
	undo.AddEntity( Rack )
	undo.SetPlayer( Owner )
	undo.Finish()

	return Rack

end

list.Set( "ACFCvars", "acf_rack" , {"id"} )
duplicator.RegisterEntityClass("acf_rack", MakeACF_Rack, "Pos", "Angle", "Id")




function ENT:PreEntityCopy()

	if next(self.AmmoLink) then
		local EntIds = {}

		for i = #self.AmmoLink, 1, -1 do				-- Adding valid entities and cleaning invalid ones
			local Ammo = self.AmmoLink[i]

			if IsValid(Ammo) then
				table.insert(EntIds, Ammo:EntIndex())
			else
				table.remove(self.AmmoLink, Ammo)
			end
		end

		if next(EntIds) then
			local Info = {
				entities = EntIds
			}

			duplicator.StoreEntityModifier( self, "ACFAmmoLink", Info )
		end
	end

	duplicator.StoreEntityModifier( self, "ACFRackInfo", {Id = self.Id} )

	-- Wire dupe info
	self.BaseClass.PreEntityCopy( self )

end




function ENT:PostEntityPaste( Player, Ent, CreatedEntities )

	self.Id = Ent.EntityMods.ACFRackInfo.Id

	MakeACF_Rack(self.Owner, self:GetPos(), self:GetAngles(), self.Id, self)

	if Ent.EntityMods and Ent.EntityMods.ACFAmmoLink then
		local AmmoLink = Ent.EntityMods.ACFAmmoLink

		if AmmoLink.entities and next(AmmoLink.entities) then

			for _, v in pairs(AmmoLink.entities) do
				local Ammo = CreatedEntities[v]

				if IsValid(Ammo) and Ammo:GetClass() == "acf_ammo" then
					self:Link( Ammo )
				end
			end
		end

		Ent.EntityMods.ACFAmmoLink = nil
	end

	-- Wire dupe info
	self.BaseClass.PostEntityPaste( self, Player, Ent, CreatedEntities )

end




function ENT:OnRemove()
	Wire_Remove(self)
end




function ENT:OnRestore()
	Wire_Restored(self)
end