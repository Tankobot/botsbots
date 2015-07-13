return { --First the ui. 
	--i.e. the input nodes.
	{ --First Object
		type = "input",
		name = "switch",
		x = 2,
		y = 2,
		bool = false,
	},
	{
		type = "input",
		name = "switch",
		x = 2,
		y = 5,
		bool = true,
	},
	{
		type = "input",
		name = "field",
		x = 11,
		y = 2,
		length = 8,
		text = "HelloWorld",
	},
	{
		type = "input",
		name = "label",
		x = 2,
		y = 8,
		text = "Label\n"..
		"Test",
	},
},
{ --Second the nodes. 
--ids = #ui + table position. 
	{
		type = "logic",
		name = "and",
		in1 = {1, "bool"},
		in2 = {2, "bool"},
	},
	{
		type = "peripheral",
		name = "cofh_thermalexpansion_energycell_0",
		out_getEnergyStored = {},
		out_getMaxEnergyStored = {},
	},
}