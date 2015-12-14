--[[
Name: Cog Graphical User Interface 
Outline: 
	Declare global variable 'cog'
	Store private frame table 
	Declare methods 
		Storing new frames 
		Create new widgets 
		Yield to cog interface 
		Refresh cog interface 
--]]

--Table to hold cog library
local cog = {}

--Table to hold default cog widget objects 
cog.widgets = {}

--Table to hold control functions such as yield 
cog.control = {}

--Table to contain all of the current program's frames 
local Gframe = {}

--Table to contain intermediate screen data 
local screen = {}

--String to contain past display state 
local oldScreen = ''

--String to contain new display state 
local newScreen = ''

-----------------------------
--[[  Cog Display Tools  ]]--
-----------------------------

--Table to hold cog version of 'term' api 
local cter = {}

--Hold options about widget position and size 
function cter.setOptions(xmin, ymin, xmax, ymax)
	cter.lim = {xmin, ymin, xmax, ymax}
end

function cter.write()
	
end

--------------------------
--[[  Frame Creation  ]]--
--------------------------

--Create new frame to hold widgets 
function cog.newFrame(widgets)
	--'widgets' argument temporary for loading previously saved frame
	local wrap = {}
	local frame = {}
	
	function wrap.new(widget)
		assert(widget.type == 'cog-widget', 
			'Invalid object type, expected "cog-widget"')
		
	end
end

--Export cog frame as table 
--Requires serial library 
function cog.exportFrame()
	assert(serial, "Serial library required for frame export")
end