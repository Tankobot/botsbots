--Bot's Control Panel Starting System 
--Controls coroutines 

local front = loadfile("frontend.lua")
front = coroutine.create(front)

local back = loadfile("backend.lua")
back = coroutine.create(back)

--Main loop 
while true do
	break
end