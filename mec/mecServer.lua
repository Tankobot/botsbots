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
	indent = indent or 0
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
local configFile = io.open("config.dat", "r")
fileToTable(1, 0, config, configFile)
configFile:close()

--Load account index. 
local acctIndex = {}
local acctIndexFile = io.open("acctIndex.dat", "r")
fileToTable(1, 0, acctIndex, acctIndexFile)
acctIndexFile:close()

-------------------------------------------------------------------------------

local function createAccount(name)
	local fileTable = {}
	fileTable.name = name
	fileTable.balance = 0
	fileTable.trans = {}
	fileTable.keys = {}
	fileTable.strikes = 0
	fileTable.strikeAdd = {}
	fileTable.strikeRem = {}
	local file = io.open("accounts/"..(config.lastId+1)..".dat", "w")
	acctIndex[name] = (config.lastId+1).."/s/"..name
	local acctIndexFile = io.open("acctIndex.dat", "w")
	writeTable(acctIndexFile, acctIndex)
	writeTable(file, fileTable)
	file:close()
end

local openAccount
function openAccount(accountNumber)
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
			writeTable(fileWrite, fileTable)
			fileWrite:close()
		else
			handle = nil
		end
	end
	
	--Transfer mecs out of the current account and into another. 
	function handle.transferMecs(recipientNumber, amount, reason)
		fileChanged = true
		assert(amount%0.01==0, "Amount is more precise than one hundredth.")
		local recipient = openAccount(recipientNumber)
		local reciTable = recipient.get()
		local transFee = amount*config.transRate
		local bank = openAccount("bank")
		local bankTable = bank.get()
		
		fileTable.balance = fileTable.balance-amount
		reciTable.balance = reciTable.balance+amount-transFee
		bankTable.balance = bankTable.balance+transFee
		
		local time = ":"..os.day().."/"..os.time()..":"
		
		table.insert(fileTable.trans, 1, amount.." > "..reciTable.name..
			time..reason)
		table.insert(reciTable.trans, 1, amount.." < "..fileTable.name..
			time..reason)
		table.insert(bankTable.trans, 1, amount.." < "..time..
			fileTable.name.." > "..reciTable.name)
		
		recipient.close()
		bank.close()
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
		table.insert(fileTable.strikeAdd, 1, reason)
	end
	function handle.remStrike(reason)
		fileChanged = true
		fileTable.strikes = fileTable.strikes-1
		table.insert(fileTable.strikeRem, 1, reason)
	end
	
	--Find and apply the savings interest on an account as credit.
	function handle.calcInterest()
		fileChanged = true
		local interest = fileTable.balance*config.interest
		fileTable.balance = fileTable.balance + interest
		table.insert(fileTable.trans, 1, interest..
			" < Bank:Monthly interest payment.")
	end
	
	function handle.findTransaction(pattern)
		local result
		for i, v in ipairs(fileTable.trans) do
			if string.find(v, pattern) then
				table.insert(result, v)
			end
		end
		return result
	end
	
	return handle
end

--Main Loop
local cmds = {
	createAccount = createAccount,
	openAccount = openAccount,
}
while true do
	local args = {coroutine.yield()}
	local cmd = table.remove(args, 1)
	cmds[cmd](unpack(args))
end