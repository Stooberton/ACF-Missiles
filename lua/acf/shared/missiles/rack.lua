--define the class
ACF_DefineRackClass("RK", {
	spread		= 1,
	name		= "Munitions Rack",
	desc		= "A lightweight rack for rockets and bombs which is vulnerable to shots and explosions.",
	muzzleflash	= "40mm_muzzleflash_noscale",
	rofmod		= 1,
	reloadmul	= 8,
})

ACF_DefineRack("RK_1xRack", {
	name		= "Single Munition Rack",
	desc		= "A lightweight rack for rockets and bombs which is vulnerable to shots and explosions.",
	model		= "models/missiles/rkx1.mdl",
	gunclass	= "RK",
	weight		= 50,
	rofmod		= 2,
	year		= 1915,
	magsize		= 1,
	armour		= 20,

	mountpoints = {
		missile1 = {offset = Vector(0, 0, 2),	scaledir = Vector(0, 0, -1)}
	}
})

ACF_DefineRack("RK_1xRack_Small", {
	name		= "Small Single Munition Rack",
	desc		= "A lightweight rack for rockets and bombs which is vulnerable to shots and explosions.",
	model		= "models/missiles/rkx1_sml.mdl",
	gunclass	= "RK",
	weight		= 50,
	rofmod		= 2,
	year		= 1915,
	magsize		= 1,
	armour		= 20,

	mountpoints = {
		missile1 = {offset = Vector(0, 0, 2),	scaledir = Vector(0, 0, -1)}
	}
})

ACF_DefineRack("RK_2xRack", {
	name		= "Dual Munitions Rack",
	desc		= "A lightweight rack for rockets and bombs which is vulnerable to shots and explosions.",
	model		= "models/missiles/rack_double.mdl",
	gunclass	= "RK",
	weight		= 75,
	year		= 1915,
	magsize		= 2,
	armour		= 20,

	mountpoints = {
		missile1 = {offset = Vector(4, -1.5, -1.7),	scaledir = Vector(0, -1, 0)},
		missile2 = {offset = Vector(4, 1.5, -1.7),	scaledir = Vector(0, 1, 0)}
	}
})

ACF_DefineRack("RK_3xRack", {
	name		= "Triple Munitions Rack",
	desc		= "A lightweight rack for bombs which is vulnerable to shots and explosions.",
	model		= "models/missiles/bomb_3xrk.mdl",
	gunclass	= "RK",
	weight		= 100,
	year		= 1936,
	armour		= 20,
	magsize		= 3,

	mountpoints = {
		missile1 = {offset = Vector(5.5,0,-4.5), scaledir = Vector(-0.2,0,-0.3)},
		missile2 = {offset = Vector(5.5,3,0), scaledir = Vector(-0.2,0.3,-0.1)},
		missile3 = {offset = Vector(5.5,-3,0), scaledir = Vector(-0.2,-0.3,-0.1)},
	}
})

ACF_DefineRack("RK_4xRack", {
	name		= "Quad Munitions Rack",
	desc		= "A lightweight rack for rockets and bombs which is vulnerable to shots and explosions.",
	model		= "models/missiles/rack_quad.mdl",
	gunclass	= "RK",
	weight		= 125,
	year		= 1936,
	armour		= 20,
	magsize		= 4,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector(0,1,0)},
		missile2 = {offset = Vector(), scaledir = Vector(0,-1,0)},
		missile3 = {offset = Vector(), scaledir = Vector(0,0,-1)},
		missile4 = {offset = Vector(), scaledir = Vector(0,0,-1)}
	}
})

ACF_DefineRack("RK_2xHellfire", {
	name		= "Dual Hellfire Rack",
	desc		= "An AGM-114 rack designed to carry 2 missiles.",
	model		= "models/missiles/agm_114_2xrk.mdl",
	gunclass	= "RK",
	weight		= 50,
	year		= 1984,
	magsize		= 2,
	armour		= 20,
	caliber		= 16,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector(0,0,-1)},
		missile2 = {offset = Vector(), scaledir = Vector(0,0,-1)},
	}
})

ACF_DefineRack("RK_4xHellfire", {
	name		= "Quad Hellfire Rack",
	desc		= "An AGM-114 rack designed to carry 4 missiles.",
	model		= "models/missiles/agm_114_4xrk.mdl",
	gunclass	= "RK",
	weight		= 100,
	year		= 1984,
	magsize		= 4,
	armour		= 20,
	caliber		= 16,

	mountpoints = {
		missile1 = {offset = Vector(), scaledir = Vector(0,0,-1)},
		missile2 = {offset = Vector(), scaledir = Vector(0,0,-1)},
		missile3 = {offset = Vector(), scaledir = Vector(0,0,-1)},
		missile4 = {offset = Vector(), scaledir = Vector(0,0,-1)}
	}
})

ACF_DefineRack("RK_1xAT3", {
	name		= "Single AT-3 Rack",
	desc		= "An AT-3 anti tank missile handheld rack",
	model		= "models/missiles/at3rk.mdl",
	gunclass	= "RK",
	weight		= 30,
	rofmod		= 1.4,
	year		= 1969,
	magsize		= 1,
	armour		= 15,

	mountpoints = {
		missile1 = {offset = Vector(3.2, 0, 1),	scaledir = Vector(0, 0, -1)}
	}
})

ACF_DefineRack("RK_1xAT3_Small", {
	name		= "Small Single AT-3 Rack",
	desc		= "An AT-3 anti tank missile handheld rack",
	model		= "models/missiles/at3rs.mdl",
	gunclass	= "RK",
	weight		= 40,
	rofmod		= 1.0,
	year		= 1972,
	magsize		= 1,
	armour		= 15,

	mountpoints = {
		missile1 = {offset = Vector(21, 0, 6.2),	scaledir = Vector(0, 0, -1)}
	}
})