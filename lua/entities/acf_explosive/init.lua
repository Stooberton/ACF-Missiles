-- init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
CreateConVar("sbox_max_acf_explosive", 20)

function ENT:Initialize()
    self.BulletData = self.BulletData or {}
    self.SpecialDamage = true --If true needs a special ACF_OnDamage function
    self.ShouldTrace = false
    self.Inputs = Wire_CreateInputs(self, {"Detonate"})
    self.Outputs = Wire_CreateOutputs(self, {})
    self.ThinkDelay = 0.1
    self.TraceFilter = {self}
end

local NullHit = {
    Damage = 0,
    Overkill = 1,
    Loss = 0,
    Kill = false
}

function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor)
    self.ACF.Armour = 0.1
    if self.Detonated or self.DisableDamage then return table.Copy(NullHit) end
    if hook.Run("ACF_AmmoExplode", self, self.BulletData) == false then return table.Copy(NullHit) end
    self:Detonate()
    --This function needs to return HitRes

    return table.Copy(NullHit)
end

function ENT:TriggerInput(Input, Value)
    if Input == "Detonate" and Value ~= 0 then
        self:Detonate()
    end
end

function MakeACF_Explosive(Owner, Pos, Angle, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10, Model)
    if not Owner:CheckLimit("_acf_explosive") then return false end
    local Bomb = ents.Create("acf_explosive")
    if not IsValid(Bomb) then return false end
    Bomb:SetAngles(Angle)
    Bomb:SetPos(Pos)
    Bomb:Spawn()
    Bomb:SetPlayer(Owner)

    if CPPI then
        Bomb:CPPISetOwner(Owner)
    end

    Bomb.Owner = Owner
    Model = Model or ACF.Weapons.Guns[Id].model
    Bomb.Id = Id
    Bomb:CreateBomb(Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10, Model)
    Owner:AddCount("_acf_explosive", Bomb)
    Owner:AddCleanup("acfmenu", Bomb)

    return Bomb
end

list.Set("ACFCvars", "acf_explosive", {"id", "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10", "mdl"})
duplicator.RegisterEntityClass("acf_explosive", MakeACF_Explosive, "Pos", "Angle", "RoundId", "RoundType", "RoundPropellant", "RoundProjectile", "RoundData5", "RoundData6", "RoundData7", "RoundData8", "RoundData9", "RoundData10", "Model")

function ENT:CreateBomb(Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10, Model, BulletData)
    self:SetModelEasy(Model)
    --Data 1 to 4 are should always be Round ID, Round Type, Propellant lenght, Projectile lenght
    self.RoundId = Data1 --Weapon this round loads into, ie 140mmC, 105mmH ...
    self.RoundType = Data2 --Type of round, IE AP, HE, HEAT ...
    self.RoundPropellant = Data3 --Lenght of propellant
    self.RoundProjectile = Data4 --Lenght of the projectile
    self.RoundData5 = Data5 or 0
    self.RoundData6 = Data6 or 0
    self.RoundData7 = Data7 or 0
    self.RoundData8 = Data8 or 0
    self.RoundData9 = Data9 or 0
    self.RoundData10 = Data10 or 0
    local PlayerData = BulletData or ACFM_CompactBulletData(self)
    self:ConfigBulletDataShortForm(PlayerData)
end

function ENT:SetModelEasy(Model)
    local CurModel = self:GetModel()

    if not Model or CurModel == Model then
        self.Model = CurModel

        return
    end

    self:SetModel(Model)
    self.Model = Model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    local PhysObj = self:GetPhysicsObject()

    if IsValid(PhysObj) then
        PhysObj:Wake()
        PhysObj:EnableMotion(true)
        PhysObj:SetMass(10)
    end
end

function ENT:SetBulletData(BulletData)
    if not (BulletData.IsShortForm or BulletData.Data5) then
        error("acf_explosive requires short-form bullet-data but was given expanded bullet-data.")
    end

    BulletData = ACFM_CompactBulletData(BulletData)
    self:CreateBomb(BulletData.Data1 or BulletData.Id, BulletData.Type or BulletData.Data2, BulletData.PropLength or BulletData.Data3, BulletData.ProjLength or BulletData.Data4, BulletData.Data5, BulletData.Data6, BulletData.Data7, BulletData.Data8, BulletData.Data9, BulletData.Data10, nil, BulletData)
    self:ConfigBulletDataShortForm(BulletData)
end

function ENT:ConfigBulletDataShortForm(BulletData)
    BulletData = ACFM_ExpandBulletData(BulletData)
    self.BulletData = BulletData
    self.BulletData.Entity = self
    self.BulletData.Crate = self:EntIndex()
    self.BulletData.Owner = self.BulletData.Owner or self.Owner
    local PhysObj = self:GetPhysicsObject()

    if IsValid(PhysObj) then
        PhysObj:SetMass(BulletData.ProjMass or BulletData.RoundMass or BulletData.Mass or 10)
    end

    self:RefreshClientInfo()
end

function ENT:TraceFunction()
    local SelfPos = self:GetPos()

    local Trace = {
        start = SelfPos,
        endpos = SelfPos + self:GetVelocity() * self.ThinkDelay,
        filter = self.TraceFilter
    }

    local TraceData = util.TraceEntity(Trace, self)

    if TraceData.Hit then
        self:OnTraceContact(TraceData)
    end
end

function ENT:Think()
    if self.ShouldTrace then
        self:TraceFunction()
    end

    self:NextThink(CurTime() + self.ThinkDelay)

    return true
end

function ENT:Detonate(OverrideBulletData)
    if self.Detonated then return end
    self.Detonated = true
    local BulletData = OverrideBulletData or self.BulletData
    local PhysObj = self:GetPhysicsObject()
    local PhysVel = PhysObj and PhysObj:GetVelocity() or Vector(0, 0, 1000)
    BulletData.Flight = BulletData.Flight or PhysVel

    timer.Simple(3, function()
        if IsValid(self) then
            if IsValid(self.FakeCrate) then
                self.FakeCrate:Remove()
            end

            self:Remove()
        end
    end)

    self:SetNoDraw(true)

    if not BulletData.Entity.Fuse or not BulletData.Entity.Fuse.Cluster then
        BulletData.Owner = BulletData.Owner or self.Owner
        BulletData.Pos = self:GetPos() + (self.DetonateOffset or BulletData.Flight:GetNormalized())
        BulletData.NoOcc = self
        BulletData.Gun = self
        debugoverlay.Line(BulletData.Pos, BulletData.Pos + BulletData.Flight, 10, Color(255, 128, 0))

        if BulletData.Filter then
            BulletData.Filter[#BulletData.Filter + 1] = self
        else
            BulletData.Filter = {self}
        end

        BulletData.RoundMass = BulletData.RoundMass or BulletData.ProjMass
        BulletData.ProjMass = BulletData.ProjMass or BulletData.RoundMass
        BulletData.HandlesOwnIteration = nil
        ACFM_BulletLaunch(BulletData)
        PhysObj:EnableMotion(false)
        self:SetSolid(SOLID_NONE)
        self:DoReplicatedPropHit(BulletData)
    else
        self:ClusterNew(BulletData)
    end
end

local Types = {
    HEAT = true,
    AP = true,
    SM = true,
    HE = true,
    APHE = true
}

function ENT:ClusterNew(BulletData)
    local Bomblets = math.Clamp(math.Round(BulletData.FillerMass * 0.5), 3, 30)
    local MuzzleVec = self:GetForward()

    if BulletData.Type == "HEAT" then
        Bomblets = math.Clamp(Bomblets, 3, 25)
    end

    self.BulletData = {
        Accel = Vector(0, 0, -600),
        BoomPower = BulletData.BoomPower,
        Caliber = math.Clamp(BulletData.Caliber / Bomblets * 10, 0.05, BulletData.Caliber * 0.8), --Controls visual size, does nothing else
        Crate = BulletData.Crate,
        DragCoef = BulletData.DragCoef / Bomblets / 2,
        FillerMass = BulletData.FillerMass / Bomblets,
        Filter = {self},
        Flight = BulletData.Flight,
        FlightTime = 0,
        FrArea = BulletData.FrArea,
        FuseLength = 0,
        Gun = self,
        Id = BulletData.Id,
        KETransfert = BulletData.KETransfert,
        LimitVel = 700,
        MuzzleVel = BulletData.MuzzleVel * 20,
        Owner = BulletData.Owner,
        PenArea = BulletData.PenArea,
        Pos = BulletData.Pos,
        ProjLength = BulletData.ProjLength / Bomblets / 2,
        ProjMass = BulletData.ProjMass / Bomblets / 2,
        PropLength = BulletData.PropLength,
        PropMass = BulletData.PropMass,
        Ricochet = BulletData.Ricochet,
        RoundVolume = BulletData.RoundVolume,
        ShovePower = BulletData.ShovePower,
        Tracer = 0,
        Type = Types[BulletData.Type] and BulletData.Type or "AP"
    }

    if self.BulletData.Type == "HEAT" then
        self.BulletData.SlugMass = BulletData.SlugMass / (Bomblets / 6)
        self.BulletData.SlugCaliber = BulletData.SlugCaliber / (Bomblets / 6)
        self.BulletData.SlugDragCoef = BulletData.SlugDragCoef / (Bomblets / 6)
        self.BulletData.SlugMV = BulletData.SlugMV / (Bomblets / 6)
        self.BulletData.SlugPenArea = BulletData.SlugPenArea / (Bomblets / 6)
        self.BulletData.SlugRicochet = BulletData.SlugRicochet
        self.BulletData.ConeVol = BulletData.SlugMass * 1000 / 7.9 / (Bomblets / 6)
        self.BulletData.CasingMass = self.BulletData.ProjMass + self.BulletData.FillerMass + (self.BulletData.ConeVol * 1000 / 7.9)
        self.BulletData.BoomFillerMass = self.BulletData.FillerMass / 1.5
    end

    self.FakeCrate = ents.Create("acf_fakecrate2")
    self.FakeCrate:RegisterTo(self.BulletData)
    self.BulletData.Crate = self.FakeCrate:EntIndex()
    local Radius = self.BulletData.FillerMass ^ 0.33 * 8 * 39.37 * 2 --Explosion effect radius.
    local Flash = EffectData()
    Flash:SetOrigin(self:GetPos())
    Flash:SetNormal(self:GetForward())
    Flash:SetRadius(math.max(Radius, 1))
    util.Effect("ACF_Scaled_Explosion", Flash)

    for I = 1, Bomblets do
        timer.Simple(0.01 * I, function()
            if IsValid(self) then
                local Spread = ((self:GetUp() * (2 * math.random() - 1)) + (self:GetRight() * (2 * math.random() - 1))) * (I - 1) / 40
                local MuzzlePos = self:LocalToWorld(Vector(100 - (I * 20), ((Bomblets / 2) - I) * 2, 0) * 0.5)
                self.BulletData.Flight = (MuzzleVec + (Spread * 2)):GetNormalized() * self.BulletData.MuzzleVel * 39.37 + BulletData.Flight
                self.BulletData.Pos = MuzzlePos
                self.CreateShell = ACF.RoundTypes[self.BulletData.Type].create
                self:CreateShell(self.BulletData)
            end
        end)
    end
end

function ENT:CreateShell()
    --You overwrite this with your own function, defined in the ammo definition file
end

function ENT:DoReplicatedPropHit(Bullet)
    local FlightRes = {
        Entity = self,
        HitNormal = Bullet.Flight,
        HitPos = Bullet.Pos,
        HitGroup = HITGROUP_GENERIC
    }

    local Index = Bullet.Index
    ACF_BulletPropImpact = ACF.RoundTypes[Bullet.Type].propimpact
    local Retry = ACF_BulletPropImpact(Index, Bullet, FlightRes.Entity, FlightRes.HitNormal, FlightRes.HitPos, FlightRes.HitGroup) --If we hit stuff then send the resolution to the damage function	

    --If we should do the same trace again, then do so
    if Retry == "Penetrated" then
        ACFM_ResetVelocity(Bullet)

        if Bullet.OnPenetrated then
            Bullet.OnPenetrated(Index, Bullet, FlightRes)
        end

        ACF_BulletClient(Index, Bullet, "Update", 2, FlightRes.HitPos)
        ACF_CalcBulletFlight(Index, Bullet, true)
    elseif Retry == "Ricochet" then
        ACFM_ResetVelocity(Bullet)

        if Bullet.OnRicocheted then
            Bullet.OnRicocheted(Index, Bullet, FlightRes)
        end

        ACF_BulletClient(Index, Bullet, "Update", 3, FlightRes.HitPos)
        ACF_CalcBulletFlight(Index, Bullet, true)
    else --Else end the flight here
        if Bullet.OnEndFlight then
            Bullet.OnEndFlight(Index, Bullet, FlightRes)
        end

        ACF_BulletClient(Index, Bullet, "Update", 1, FlightRes.HitPos)
        ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type].endflight
        ACF_BulletEndFlight(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)
    end
end

function ENT:OnTraceContact(trace)
end

function ENT:EnableClientInfo(Bool)
    self.ClientInfo = Bool
    self:SetNWBool("VisInfo", Bool)

    if Bool then
        self:RefreshClientInfo()
    end
end

function ENT:RefreshClientInfo()
    ACFM_MakeCrateForBullet(self, self.BulletData)
end