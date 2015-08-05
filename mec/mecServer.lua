--[[
Minecraft Electronic Currency, Server Side
Note: SSL not yet implemented
--]]

--Functions to replace escape characters. 
function string.rsub(str, repl, pattern)
	return string.gsub(str, pattern, repl)
end
local function replace(str, mode)
	if mode == "s" then
		str = string.gsub(str, [=[\[]=], "[bracket_open]")
		str = string.gsub(str, [=[\]]=], "[bracket_close]")
		str = string.gsub(str, [[\/]], "[slash]")
	elseif mode == "r" then
		str = string.rsub(str, [=[\[]=], "[bracket_open]")
		str = string.rsub(str, [=[\]]=], "[bracket_close]")
		str = string.rsub(str, [[\/]], "[slash]")
	elseif mode == "x" then
		str = string.gsub(str, "[", "\\[")
		str = string.gsub(str, "]", "\\]")
		str = string.gsub(str, "/", "\\/")
	end
	return str
end

--Define function to convert file to table.
local fileToTable
function fileToTable(lineNumber, tabAmount, subsetTable, fileRead)
	local lastLine
	local lineData = ""
	local linePull = fileRead:lines()
	while lineData do
		if lastLine then
			lineData = lastLine
			lastLine = nil
		else
			lineData = linePull()
		end
		if not lineData then
			break
		end
		lineNumber = lineNumber+1
		--Check for table location
		local tabCounter = 0
		while not (tabCounter == tabAmount) do
			if string.find(lineData, "\t") then
				tabCounter = tabCounter+1
				lineData = string.sub(lineData, 2)
			elseif tabCounter < tabAmount then
				return lineData
			elseif tabCounter > tabAmount then
				error("Syntax error on line "..lineNumber..".")
			end
		end
		
		--Replace escape characters
		replace(lineData, "s")
		
		--Check for key assignment
		local separator = string.find(lineData, "/")
		assert(string.sub(lineData, separator+2, separator+2)=="/",
			"Syntax error on line "..lineNumber)
		local action = string.sub(lineData, separator+1, separator+1)
		local key = string.sub(lineData, 1, separator-1)
		key = tonumber(key) or key
		local value = string.sub(lineData, separator+3)
		key = replace(key, "r")
		value = replace(value, "r")
		if action == "=" then
			subsetTable[key] = tonumber(value) or value
		elseif action == "t" then
			subsetTable[key] = {}
			lastLine = fileToTable(lineNumber, tabAmount+1, 
				subsetTable[key], fileRead)
		end
	end
end

local function writeTable(file, tab, indent)
	for i, v in pairs(tab) do
		i = replace(i, "x")
		v = replace(v, "x")
		if type(v) == "table" then
			file:write(("\t"):rep(indent)..i.."/t/"..v.."\n")
			writeTable(file, v, indent+1)
		else
			file:write(("\t"):rep(indent)..i.."/=/"..v.."\n")
		end
	end
end

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

--Load mec config file.
local config = {}
fileToTable(1, 0, config, io.open("config.dat", "r"))

--Load account index. 
local acctIndex = {}
fileToTable(1, 0, acctIndex, io.open("acctIndex.dat", "r"))

local function openAccount(accountNumber)
	assert(accountNumber, "Expected account number.")
	local fileRead, errorMsg = io.open("accounts/"..accountNumber..".dat", "r")
	if errorMsg then
		error(errorMsg, 2)
	end
	
	--Retrieve file information
	local fileTable = {}
	fileToTable(1, 0, fileTable, fileRead)
	fileRead:close()
	
	local fileChanged = false
	local handle = {}
	
	--Close account handle, writing any changes if necessary.
	function handle.close()
		if fileChanged then
			local fileWrite = io.open("accounts/"..accountNumber..".dat", "w")
			writeTable(fileWrite, fileTable, 0)
		else
			handle = nil
		end
	end
	
	--Transfer mecs out of the current account and into another. 
	function handle.transferMecs(recipientNumber, amount, reason)
		fileChanged = true
		local recipient = openAccount(recipientNumber)
		local reciTable = recipient.get()
		local taxTake = math.ceil(amount*config.taxdeflation)
		
		fileTable.balance = fileTable.balance-amount
		reciTable.balance = reciTable.balance+amount-taxTake
		fileTable.trans = fileTable.trans or {}
		
		table.insert(fileTable.trans, amount.." > "..reciTable.name..
			":"..reason)
		table.insert(reciTable.trans, amount.." < "..fileTable.name..
			":"..reason)
		
		recipient.close()
	end
	
	--Special command with meta table to get specific pieces of information 
	--from account.
	handle.get = {}
	handle.get.meta = {
		__index = function(temp, index)
			return fileTable[index]
		end,
		__call = function(temp)
			return deepcopy(fileTable)
		end
	}
	setmetatable(handle.get, handle.get.meta)
	
	--Same as get, except here we set. 
	handle.set = {}
	handle.set.meta = {
		__newindex = function(temp, newindex, value)
			fileChanged = true
			fileTable[newindex] = value
		end
	}
	setmetatable(handle.set, handle.set.meta)
	
	--Add & remove a strike to/from the account for management reasons. 
	function handle.addStrike(reason)
		fileChanged = true
		fileTable.strikes = fileTable.strikes+1
		table.insert(fileTable.strikeAdd, reason)
	end
	function handle.remStrike(reason)
		fileChanged = true
		fileTable.strikes = fileTable.strikes-1
		table.insert(fileTable.strikeRem, reason)
	end
	
	--Find and apply the savings interest on an account as credit.
	function handle.calcInterest()
		fileChanged = true
		local interest = math.floor(fileTable.balance*config.interest)
		--TODO
	end
	
	function handle.getTransaction(username)
		return deepcopy(fileTable.trans)
	end
	
	return handle
end
