--BCP Frontend 

local limX, limY = term.getSize()

local function assert(bool, msg)
	if not bool then
		error(msg, 2)
	end
end

local function background()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.gray)
	for i=1, limX do
		for j=1, limY do
			term.setCursorPos(i, j)
			term.write("/")
		end
	end
end

local function outline(x, y, l, h)
	assert(type(x)=="number", "Arg#1 must be number")
	assert(type(y)=="number", "Arg#2 must be number")
	assert(type(l)=="number", "Arg#3 must be number")
	assert(type(h)=="number", "Arg#4 must be number")
	assert(l>x, "Arg#3 must be greater than arg#1")
	assert(h>y, "Arg#4 must be greater than arg#2")
	--Definitely not adding this much for others. 
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	for i=y, h do
		for j=x, l do
			term.setCursorPos(j, i)
			if ((i==y) or (i==h)) and ((j==x) or (j==l)) then
				term.setBackgroundColor(colors.lightGray)
				term.write("*")
			elseif (i==y) or (i==h) then
				term.setBackgroundColor(colors.lightGray)
				term.write("-")
			elseif (j==x) or (j==l) then
				term.setBackgroundColor(colors.lightGray)
				term.write("|")
			else
				term.setBackgroundColor(colors.gray)
				term.write(" ")
			end
		end
	end
end

local function switch(x, y)
	return function(bool) --Draw Object
		outline(x, y, x+2, y+2)
		term.setCursorPos(x+1, y+1)
		if bool then
			term.setBackgroundColor(colors.lime)
			term.setTextColor(colors.black)
			term.write("1")
		else
			term.setBackgroundColor(colors.red)
			term.setTextColor(colors.white)
			term.write("0")
		end
	end,
	function() --Return Info
		return x, y
	end,
	function(event) --Check Object
		
	end
end

local function field(x, y, length)
	local typed = {}
	return function(text) --Draw Object
		for i=1, #text do
			typed[i] = text:sub(i,i)
		end
		
		outline(x, y, x+length+1, y+2)
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
		local shift = 0
		if #typed>=length then
			shift = #typed-length+1
		end
		for i=x+1, x+length do
			term.setCursorPos(i, y+1)
			if (i==x+length) and (shift~=0) then
				term.write(">")
			else
				term.write(typed[i-x] or " ")
			end
		end
	end,
	function() --Return Info
		return x, y, length
	end,
	function() --Capture Input
		
	end
end

--Test Code---------------------------------------------
background()
sleep(1)
local a = switch(2, 2)
local a2 = switch(2, 5)
local b, c = field(11, 2, 8)
a(true)
a2(false)
b("HelloWorld")
outline(5, 2, 10, 6)
sleep(1)
a(false)
a2(true)
sleep(1)
term.setCursorPos(1, limY)