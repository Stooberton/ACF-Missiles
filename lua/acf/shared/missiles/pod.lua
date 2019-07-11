--define the class
ACF_DefineRackClass("POD", {
	spread			= 0.5,
	name			= "Rocket Pod",
	desc			= "An accurate, lightweight rocket launcher which can explode if its armour is pierced.",
	muzzleflash		= "40mm_muzzleflash_noscale",
	rofmod			= 2,
	sound			= "acf_extra/airfx/rocket_fire2.wav",
	soundDistance	= " ",
	soundNormal		= " ",
	hidemissile		= true,
	protectmissile	= true,
	armour			= 15,
	reloadmul		= 8,
})

ACF_DefineRack("POD_7x40mm", {
	name			= "7x FFAR Pod (40mm)",
	desc			= "A lightweight pod for small rockets which is vulnerable to shots and explosions.",
	model			= "models/missiles/launcher7_40mm.mdl",
	gunclass		= "POD",
	weight			= 20,
	year			= 1940,
	magsize			= 7,
	armour			= 15,
	caliber			= 4,
	hidemissile		= false,
	protectmissile 	= true,
	whitelistonly	= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()},
		missile3 = {offset = Vector(), scaledir = Vector()},
		missile4 = {offset = Vector(), scaledir = Vector()},
		missile5 = {offset = Vector(), scaledir = Vector()},
		missile6 = {offset = Vector(), scaledir = Vector()},
		missile7 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_7x70mm", {
	name			= "7x FFAR Pod (70mm)",
	desc			= "A lightweight pod for rockets which is vulnerable to shots and explosions.",
	model			= "models/missiles/launcher7_70mm.mdl",
	gunclass		= "POD",
	weight			= 40,
	year			= 1940,
	magsize			= 7,
	armour			= 24,
	caliber			= 7,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()},
		missile3 = {offset = Vector(), scaledir = Vector()},
		missile4 = {offset = Vector(), scaledir = Vector()},
		missile5 = {offset = Vector(), scaledir = Vector()},
		missile6 = {offset = Vector(), scaledir = Vector()},
		missile7 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_1xTOW", {
	name			= "Single BGM-71E Rack",
	desc			= "A single BGM-71E round.",
	model			= "models/missiles/bgm_71e_round.mdl",
	gunclass		= "POD",
	weight			= 10,
	year			= 1970,
	magsize			= 1,
	armour			= 18,
	caliber			= 13,
	whitelistonly	= true,
	protectmissile 	= true,
	hidemissile		= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_2xTOW", {
	name			= "Dual BGM-71E Rack",
	desc			= "A BGM-71E rack designed to carry 2 rounds.",
	model			= "models/missiles/bgm_71e_2xrk.mdl",
	gunclass		= "POD",
	weight			= 60,
	year			= 1970,
	magsize			= 2,
	armour			= 18,
	caliber 		= 13,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_4xTOW", {
	name			= "Quad BGM-71E Rack",
	desc			= "A BGM-71E rack designed to carry 4 rounds.",
	model			= "models/missiles/bgm_71e_4xrk.mdl",
	gunclass		= "POD",
	weight			= 100,
	year			= 1970,
	magsize			= 4,
	armour			= 24,
	caliber			= 13,
	whitelistonly	= true,
	protectmissile 	= true,
	hidemissile		= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()},
		missile3 = {offset = Vector(), scaledir = Vector()},
		missile4 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_RW61", {
	name			= "380mm RW61 Launcher",
	desc			= "A lightweight pod for rocket-asisted mortars which is vulnerable to shots and explosions.",
	model			= "models/launcher/RW61.mdl",
	gunclass		= "POD",
	weight			= 600,
	year			= 1945,
	magsize			= 1,
	armour			= 24,
	caliber			= 38,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
	}
})

ACF_DefineRack("POD_3xUARRK", {
	name			= "Triple HVAR Rack",
	desc			= "A lightweight rack for bombs which is vulnerable to shots and explosions.",
	model			= "models/missiles/rk3uar.mdl",
	gunclass		= "POD",
	weight			= 150,
	year			= 1941,
	armour			= 30,
	magsize			= 3,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()},
		missile3 = {offset = Vector(), scaledir = Vector()},
	}
})

ACF_DefineRack("POD_6xUARRK", {
	name			= "Hexa S24 Rack",
	desc			= "6-pack of death, used to efficiently carry artillery rockets",
	model			= "models/missiles/6pod_rk.mdl",
	rackmdl			= "models/missiles/6pod_cover.mdl",
	gunclass		= "POD",
	weight			= 600,
	year			= 1980,
	armour			= 45,
	magsize			= 6,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(3.075,-0.1,0), scaledir = Vector()},
		missile2 = {offset = Vector(3.075,-0.1,0), scaledir = Vector()},
		missile3 = {offset = Vector(3.075,-0.1,0), scaledir = Vector()},
		missile4 = {offset = Vector(3.075,-0.1,0), scaledir = Vector()},
		missile5 = {offset = Vector(3.075,-0.1,0), scaledir = Vector()},
		missile6 = {offset = Vector(3.075,-0.1,0), scaledir = Vector()},
	}
})

ACF_DefineRack("POD_1xStinger", {
	name			= "Single FIM-92 Rack",
	desc			= "A FIM-92 rack designed to carry 1 missile.",
	model			= "models/missiles/fim_92_1xrk.mdl",
	gunclass		= "POD",
	weight			= 10,
	year			= 1984,
	magsize			= 1,
	armour			= 12,
	caliber			= 7,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_2xStinger", {
	name			= "Double FIM-92 Rack",
	desc			= "A FIM-92 rack designed to carry 2 missiles.",
	model			= "models/missiles/fim_92_2xrk.mdl",
	gunclass		= "POD",
	weight			= 30,
	year			= 1984,
	magsize			= 2,
	armour			= 16,
	caliber			= 7,
	rofmod			= 3,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_4xStinger", {
	name			= "Quad FIM-92 Rack",
	desc			= "A FIM-92 rack designed to carry 4 missiles.",
	model			= "models/missiles/fim_92_4xrk.mdl",
	gunclass		= "POD",
	weight			= 30,
	year			= 1984,
	magsize			= 4,
	armour			= 20,
	caliber			= 7,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()},
		missile3 = {offset = Vector(), scaledir = Vector(0,0,-1)},
		missile4 = {offset = Vector(), scaledir = Vector(0,0,-1)}
	}
})


ACF_DefineRack("POD_1xStrela", {
	name			= "Single Strela-1 Rack",
	desc			= "A 9M31 rack designed to carry 1 missile.",
	model			= "models/missiles/9m31_rk1.mdl",
	gunclass		= "POD",
	weight			= 10,
	year			= 1968,
	magsize			= 1,
	armour			= 50,
	caliber			= 8,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_2xStrela", {
	name			= "Double Strela-1 Rack",
	desc			= "A 9M31 rack designed to carry 2 missiles.",
	model			= "models/missiles/9m31_rk2.mdl",
	gunclass		= "POD",
	weight			= 30,
	year			= 1968,
	magsize			= 2,
	armour			= 80,
	caliber			= 8,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()},
		missile2 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_4xStrela", {
	name			= "Quad Strela-1 Rack",
	desc			= "A 9M31 rack designed to carry 4 missiles.",
	model			= "models/missiles/9m31_rk4.mdl",
	gunclass		= "POD",
	weight			= 50,
	year			= 1968,
	magsize			= 4,
	armour			= 100,
	caliber			= 8,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(0.5,0,0), scaledir = Vector()},
		missile2 = {offset = Vector(0.5,0,0), scaledir = Vector()},
		missile3 = {offset = Vector(0.5,0,0), scaledir = Vector()},
		missile4 = {offset = Vector(0.5,0,0), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_1xAtaka", {
	name			= "Single Ataka Rack",
	desc			= "A 9M120 rack designed to carry 1 missile.",
	model			= "models/missiles/9m120_rk1.mdl",
	gunclass		= "POD",
	weight			= 10,
	year			= 1968,
	magsize			= 1,
	armour			= 50,
	caliber			= 13,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_1xSPG9", {
	name			= "SPG-9 Launch Tube",
	desc			= "Launch tube for SPG-9 recoilless rocket.",
	model			= "models/spg9/spg9.mdl",
	gunclass		= "POD",
	weight			= 90,
	year			= 1968,
	magsize			= 1,
	armour			= 30,
	caliber			= 7.3,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_1xKornet", {
	name			= "Single Kornet Rack",
	desc			= "Launch tube for Kornet antitank missile.",
	model			= "models/kali/weapons/kornet/parts/9m133 kornet tube.mdl",
	gunclass		= "POD",
	weight			= 30,
	year			= 1994,
	magsize			= 1,
	armour			= 20,
	caliber			= 15.2,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= true,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector()}
	}
})

ACF_DefineRack("POD_4xZuni", {
	name			= "Zuni Pod",
	desc			= "LAU-10/A Pod for the Zuni rocket.",
	model			= "models/ghosteh/lau10.mdl",
	gunclass		= "POD",
	weight			= 100,
	year			= 1957,
	magsize			= 4,
	armour			= 40,
	caliber			= 12.7,
	whitelistonly	= true,
	protectmissile	= true,
	hidemissile		= false,

	mountpoints = {
		missile1 = {offset = Vector(5.2,2.75,2.65), scaledir = Vector()},
		missile2 = {offset = Vector(5.2,-2.75,2.65), scaledir = Vector()},
		missile3 = {offset = Vector(5.2,2.75,-2.83), scaledir = Vector()},
		missile4 = {offset = Vector(5.2,-2.75,-2.83), scaledir = Vector()}
	}
})