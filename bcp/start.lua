--Bot's Control Panel Starting System 
--Controls coroutines 

local front = loadfile("frontend.lua")
front = coroutine.create(front)

local back = loadfile("backend.lua")
back = coroutine.create(back)

local ui, nodes
do --Attempt to load previous setup.
	io.write("Layout name: ")
	local re = io.read() --Catch Response
	local file = io.open("layouts/"..re..".lua")
	if fs.exists("layouts/"..re..".lua") then
		ui, nodes = dofile("layouts/"..re..".lua")
	end
end

--Convert *ui* and *nodes* into usable function lists. 
if ui and nodes then
	
end

--Main loop 
while true do
	break
end