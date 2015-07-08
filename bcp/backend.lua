--BCP Backend 

local event
local sockets = sockets or {}

while true do
	event = {os.pullEvent()}
	
	--Control
	if event[1]=="recall" then
		
	end
	if event[1]=="connect" then
		
	end
	if event[1]=="break" then
		
	end
	if event[1]=="delete" then
		
	end
	if event[1]=="create" then
		
	end
	
	--Input
	if event[1]=="switch" then
		
	end
	if event[1]=="field" then
		
	end
	
	--Mod Specific
	pcall(sockets[event[1]], event)
end