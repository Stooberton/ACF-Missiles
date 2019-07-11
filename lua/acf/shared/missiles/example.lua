--[[
-- We're gonna be removing all comments from missile, bomb, rack and pod definitions and leave them here instead
-- Don't forget to remove the comments if you ever use something from this file too

-- NOTE: If your gun-class/gun doesn't use a propierty (or optionally it's false by default) you can just remove that field
--		 Fields that are "nil" will be also considered as false when the code is running
--		 There's no need to keep an unused propierty floating around



-- Whenever you need to setup a new gun class (bombs and missiles) you'll need to call this

ACF_defineGunClass("ClassID", {								-- Don't forget to change the ID of your class
	type			= "missile",							-- Type of entity we're gonna be using
	spread			= 1, 									-- Spread multiplier for the class
	name			= "Name of your class",
	desc			= "Short description of your class",
	muzzleflash		= "40mm_muzzleflash_noscale", 			-- Muzzleflash effect used when your missiles are fired
	rofmod			= 1, 									-- Rate of fire multiplier for the class
	sound			= "acf_extra/airfx/rocket_fire2.wav",	-- Default sound used when firing any missile from this class
	soundDistance	= " ",									-- Compatibility with distance sounds mod
	soundNormal		= " ",									-- Compatibility with distance sounds mod
	effect			= "Rocket Motor",						-- Effect used when your missile has fuel
	reloadmul		= 8,									-- Reload multiplier for the class
	ammoBlacklist	= {"AP", "APHE", "FL", "HEAT", "SM"}	-- Ammo this class won't use. For the moment, always include FL
})



ACF_defineGun("GunID", { --id
	name		= "AIM-9 Missile",
	desc		= "The gold standard in airborne jousting sticks. Agile and reliable with a rather underwhelming effective range, this homing missile is the weapon of choice for dogfights.\nSeeks 20 degrees, so well suited to dogfights.",
	model		= "models/missiles/aim9m.mdl",
	gunclass	= "AAM",
	rack		= "RK_1xRack", -- Which rack to spawn this missile on?
	length		= 200,
	caliber		= 12.7,
	weight		= 85, -- Don't scale down the weight though!
	rofmod		= 0.5,
	year		= 1982,
	ent			= "acf_rack", -- Entity where this missile/bomb will be spawned
	seekcone	= 10, -- getting inside this cone will get you locked. Divided by 2 ('seekcone = 40' means 80 degrees total.)	--was 25
	viewcone	= 30, -- getting outside this cone will break the lock. Divided by 2.		--was 30
	agility		= 5, -- multiplier for missile turn-rate.
	armdelay	= 0.2, -- minimum fuse arming delay		--was 0.4
	guidance	= {"Dumb", "Radar"},
	fuses		= {"Contact", "Radio"},
	racks		= {RK_1xRack = true, RK_2xRack = true, RK_3xRack = true, RK_1xRack_Small = true}, -- a whitelist for racks that this missile can load into. can also be a 'function(bulletData, rackEntity) return boolean end'

	round = {
		model			= "models/missiles/aim9m.mdl",
		rackmdl			= "models/missiles/aim9m.mdl",
		maxlength		= 35,
		casing			= 0.1,		-- thickness of missile casing, cm
		armour			= 15,		-- effective armour thickness of casing, in mm
		propweight		= 1,		-- motor mass - motor casing
		thrust			= 20000,	-- average thrust - kg*in/s^2		--was 100000
		burnrate		= 500,		-- cm^3/s at average chamber pressure	--was 350
		starterpct		= 0.1,		-- percentage of the propellant consumed in the starter motor.	--was 0.2
		minspeed		= 3000,		-- minimum speed beyond which the fins work at 100% efficiency
		dragcoef		= 0.002,	-- drag coefficient while falling
		dragcoefflight	= 0.03,		-- drag coefficient during flight
		finmul			= 0.025		-- fin multiplier (mostly used for unpropelled guidance)
	},
})
]]