--[[
Minecraft Electronic Currency, Server Side
Note: SSL not yet implemented
--]]

local function openAccount(accountNumber)
	assert(accountNumber, "Expected account number.")
	local fileRead, errorMsg = io.open("accounts/"..accountNumber, "r")
	if errorMsg then
		error(errorMsg, 0)
	end
	
	--Retrieve file information
	local fileTable = {}
	for lineData in fileRead:lines() do
		local key
		local value
		local characterPos = string.find(lineData, "//")
		local endPos = string.find(lineData, characterPos+2, "/")
		local valueMod = string.sub(lineData, characterPos+2, endPos-1)
		if characterPos and endPos then
			key = string.sub(lineData, 1, characterPos-1)
			value = string.sub(lineData, endPos+1)
		end
		if valueMod == "n" then
			value = tonumber(value)
		end
		if key then
			fileTable[key] = value
		end
	end
	fileRead:close()
	
	local fileChanged = false
	local handle = {}
	
	--Close account handle, writing any changes if necessary. 
	function handle.close()
		if fileChanged then
			local fileWrite = io.open("accounts/"..accountNumber, "w")
			for i, v in pairs(fileTable) do
				local mod
				if type(v)=="number" then
					mod = "//n/"
				else
					mod = "//s/"
				end
				fileWrite:write(i..mod..v.."\n")
			end
			fileWrite:close()
			handle = nil
		else
			handle = nil
		end
	end
	
	function handle.transferMecs(recipientNumber, amount, reason)
		local recipient = openAccount(recipientNumber)
		fileTable.balance = fileTable.balance-amount
		fileChanged = true
		
		recipient.set.balance = recipient.set.balance+amount
		
		--TODO Transaction reason
		
		recipient.close()
	end
	
	return handle
end