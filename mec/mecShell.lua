--Minecraft Electronic Currency, Shell

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

local index = {}
local indexFile = io.open("acctIndex.dat", "r")
fileToTable(1, 0, index, indexFile)
indexFile:close()


local mecServer = coroutine.create(loadfile("mecServer.lua"))
local cmds = {
	create = function(name)
		return "createAccount", name
	end,
	open = {
		function(accountName)
			return "openAccount", index.accountName
		end,
		
	}
}

while true do --Main Loop
	
end