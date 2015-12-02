local serial = {}

--Strings (Not really necessary) 

function serial.StoS(str)
	return str
end

--Numbers (Not really necessary) 

function serial.NtoS(num)
	return tostring(num)
end

function serial.StoN(str)
	return tonumber(str)
end

--Booleans (and nil) 

function serial.BtoS(bool)
	if bool == true then
		bool = "true"
	elseif bool == false then 
		bool = "false"
	elseif bool == nil then
		bool = "nil"
	else 
		error("Expected arg1 to be bool ", 2)
	end
	return bool
end

function serial.StoB(str)
	if str == "true" then
		str = true
	elseif str == "false" then
		str = false
	else 
		error("Expected string to be 'true' or 'false' ", 2)
	end
	return str
end

--Tables 

local function indent(num)
	return string.rep("\t", num)
end

local function bracket(pos)
	if type(pos) == "string" then 
		return "['"..pos.."'] = "
	elseif type(pos) == "number" then 
		return "["..pos.."] = "
	else 
		error("Unexpected index type ", 3)
	end
end

function serial.TtoS(tab, overflow)
	local str = "{\n"
	local stack = {tab}
	while #stack > 0 do
		if #stack >= (overflow or 10) then 
			error("Table depth overflow at "..overflow, 2)
		end
		stack[stack[#stack]] = stack[stack[#stack]] or {next=1}
		local currTab = stack[#stack]
		local currInd = stack[stack[#stack]]
		if #currInd == 0 then
			for i, v in pairs(currTab) do
				table.insert(currInd, i)
			end
		end
		for i=currInd.next, #currInd+1 do
			--Table is finished
			if (i >= #currInd+1) and (#stack == 1) then
				str = str.."}\n"
				stack[currTab] = nil
				table.remove(stack)
				break
			elseif i == #currInd+1 then
				str = str..indent(#stack-1).."},\n"
				stack[currTab] = nil
				table.remove(stack)
				break
			end
			local piece = currTab[currInd[i]]
			--Index
			currInd[i] = string.gsub(currInd[i], "'", "\\'")
			str = str..indent(#stack)..bracket(currInd[i])
			--Data
			if type(piece) == "string" then
				piece = string.gsub(piece, "'", "\\'")
				str = str.."'"..piece.."',\n"
			elseif type(piece) == "number" then
				str = str..piece..",\n"
			elseif type(piece) == "boolean" then
				str = str..tostring(piece)..",\n"
			elseif type(piece) == "table" then
				str = str.."{\n"
				currInd.next = i+1
				table.insert(stack, piece)
				break
			else 
				error("Unexpected data type ", 2)
			end
		end
	end
	return str
end

function serial.StoT(str)
	local f = load("return "..str)
	return f()
end

--Return 

return serial