--[[
Minecraft Electronic Currency, Server Side
Note: SSL not yet implemented
Data pipelines implemented with Stepper Encryption Algorithm. 
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

local function deepcopy(orig) --Lua-Users DeepCopy
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
	assert(acctIndex[name], "Account with that name already exists.")
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
	acctIndexFile:close()
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
		__newindex = function(temp)
			error("Cannot index with get call.", 2)
		end,
		__call = function(temp, ...)
			if not temp then
				return deepcopy(fileTable)
			end
			local arg = {...}
			local selected = temp
			for i=1, #arg do
				selected = selected[arg[i]]
				if not (type(selected)=="table") then
					break
				end
			end
			return selected
		end
	}
	setmetatable(handle.get, handle.get.meta)
	
	--Same as get, except here we set. 
	handle.set = {}
	handle.set.meta = {
		__index = function(temp, index)
			fileChanged = true
			return fileTable[index]
		end,
		__newindex = function(temp, newindex, value)
			fileChanged = true
			fileTable[newindex] = value
		end,
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

--Load network functions
local net = dofile("net.lua")

--Declare Server Commands
local openAccts = {}
local currAcct
local cmds = {
	--Admin functionality
	admin = function(auth, cmd, ...)
		--Check admin authentication. 
		assert(config.adminKey == key, "Key does not match.")
		--Declare possible admin commands. 
		local F = {
			create = createAccount,
			delete = function(accountNumber)
				local acct = openAccount(accountNumber)
				local name = acct.get.name
				acct.close()
				local log = io.open("log.dat")
				log:write("Closed account, id:"..accountNumber..
					" name:"..name)
				log:close()
				os.remove = os.remove or fs.delete
				os.remove("accounts/"..accountNumber..".dat")
			end,
			chkey = function(newKey)
				config.adminKey = newKey
				local file = io.open("config.dat", "w")
				writeTable(file, config, 0)
				file:close()
			end,
			open = function(accountNumber)
				local acct = openAccount(accountNumber)
				openAccts[accountNumber] = acct
			end,
			shell = function()
				dofile("rom/programs/shell")
			end,
		}
		--Execute given command with arguments.
		if cmd == "stop" then
			error("Stopping Server", 0)
		end
		assert(F[cmd], "Command does not exist.")
		F[cmd](...)
	end,
	open = function(accountNumber, keyName, auth)
		local acct = openAccount(accountNumber)
		if not (acct.get.keys[keyName] == auth) then
			acct:close()
			error("Authentication error", 1)
		end
		openAccts[accountNumber] = acct
	end,
	select = function(accountNumber)
		assert(openAccts[accountNumber], "Account:"..accountNumber..
			" is not open.")
		currAcct = accountNumber
	end,
	close = function(accountNumber)
		assert(openAccts[accountNumber], "Account: "..accountNumber..
			" is not open.")
		openAccts[accountNumber].close()
		if currAcct == accountNumber then
			currAcct = nil
		end
	end,
	translate = function(accountName)
		assert(acctIndex[accountName], "Account does not exist.")
		net.reply(acctIndex[accountName])
	end,
	--Setup commands that require account to be selected first. 
	transfer = function(...)
		assert(openAccts[currAcct], "No account selected.")
		net.confirm(math.random(99999), "Transfer aborted.")
		openAccts[currAcct].transferMecs(...)
	end,
	balance = function()
		assert(openAccts[currAcct], "No account selected.")
		return openAccts[currAcct].balance
	end,
	set = function()
		error("Please edit file manually.")
	end,
}

local function parse(str)
	--NOTE Add argument parser
end

while true do
	--NOTE Add server shutdown method. 
	--NOTE Add account session timeout method. 
	--NOTE Add timer to trigger interest. 
end