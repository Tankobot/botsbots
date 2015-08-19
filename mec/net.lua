--Specialized Minecraft Electronic Currency Communication

local crypt = {}

function crypt.keyGen(length)
	local key = ""
	local function randomHex(prev)
		local ran = math.random(1, 15)
		local let = {"A", "B", "C", "D", "E", "F"}
		if ran>9 then
			ran = let[(ran%10)+1]
		end
		return ran
	end
	for i=0.5, length, 0.5 do
		key = key..randomHex()
	end
	return key
end
function crypt.crypt(str, key)
	assert(#key%2==0, "Incorrect key length.")
	local hex = {
		A = 10, B = 11, C = 12,
		D = 13, E = 14, F = 15,
	}
	--Setup key table
	local keyTab = {}
	for i=1, #key do
		if tonumber(key:sub(i, i)) then
			table.insert(keyTab, tonumber(key:sub(i, i)))
		else
			table.insert(keyTab, hex[key:sub(i, i)])
		end
	end
	--Byte rounds
	for i=1, #str do
		local strByte = str:sub(i, i)
		local keyByte = key:sub(i, i)
		--Hex rounds
		for i=1, 2 do
			--Bit rounds
			for i=1, 4 do
				
			end
		end
	end
end