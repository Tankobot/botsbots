--Specialized Minecraft Electronic Currency Communication

local crypt = {}

local function hex(num)
	return string.format("%X", num)
end

function crypt.hash(str)
	
end

function crypt.keyGen(seed)
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
