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
			term.write(" ")
		end
	end
end

local function outline(x, y, l, h, outer, inner, text)
	assert(type(x)=="number", "Arg#1 must be number")
	assert(type(y)=="number", "Arg#2 must be number")
	assert(type(l)=="number", "Arg#3 must be number")
	assert(type(h)=="number", "Arg#4 must be number")
	assert(l>x, "Arg#3 must be greater than arg#1")
	assert(h>y, "Arg#4 must be greater than arg#2")
	--Definitely not adding this much error handling for others. 
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	for i=y, h do
		for j=x, l do
			term.setCursorPos(j, i)
			if ((i==y) or (i==h)) and ((j==x) or (j==l)) then
				term.setBackgroundColor(outer or colors.lightGray)
				term.write(text or "*")
			elseif (i==y) or (i==h) then
				term.setBackgroundColor(outer or colors.lightGray)
				term.write(text or "-")
			elseif (j==x) or (j==l) then
				term.setBackgroundColor(outer or colors.lightGray)
				term.write(text or "|")
			else
				term.setBackgroundColor(inner or colors.gray)
				term.write(" ")
			end
		end
	end
end



--Interface Pieces ////////////////////////////////////////////////////////////

local function label(x, y, length, text)
	local typed = {}
	for i=1, #text do
		typed[i] = text:sub(i, i)
	end
	
	return function() --draw
		
	end,
	function() --info/set
		
	end
	--No check function required
end

local function switch(x, y, bool)
	return function() --Draw Object
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
	function(set, N_x, N_y, N_bool) --Return Info / Set
		if set then
			x = N_x
			y = N_y
			bool = N_bool
		end
		return x, y, bool
	end,
	function(event) --Check Object
		
	end
end

local function field(x, y, length, text)
	text = text or  ""
	local typed = {}
	return function() --Draw Object
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
	function(set, N_x, N_y, N_length, N_text) --Return Info / Set
		if set then
			x = N_x
			y = N_y
			length = N_length
			text = N_text
		end
		return x, y, length, text
	end,
	function() --Capture Input
		
	end
end



--Interactivity (Input, Menus) ////////////////////////////////////////////////

local function popupMenu(x, y, menu)
	assert(type(menu)=="table", "Menu list is not a table")
	
	local length = 0
	for i=1, #menu do
		if length < #menu[i] then --Find longest field
			length = #menu[i]
		end
		
		menu[i] = menu[menu[i]] --Replace index with functions 
	end
	
	local pos = "tl"
	if x+length-1 > limX then
		pos = pos:sub(1, 1).."r"
		assert(x-length>=0, "Field is too long")
	end
	if y+#menu-1 > limY then
		pos = "b"..pos:sub(2, 2)
		assert(y-#menu>=0, "Menu is too tall")
	end
	
	local event = {os.pullEvent()}
	if (event[1]=="mouse_click") then
		
	end
end

local function buttonOk(x, y)
	term.setCursorPos(x, y)
	term.setBackgroundColor(colors.green)
	term.setTextColor(colors.white)
	term.write("OK")
end

local function buttonCancel(x, y)
	term.setCursorPos(x, y)
	term.setBackgroundColor(colors.red)
	term.setTextColor(colors.white)
	term.write("Cancel")
end

local function buttonClose(x, y)
	term.setCursorPos(x, y)
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.black)
	term.write("Close")
end

local function popupFail(msg)
	outline(4, 3, limX-3, limY-2, colors.pink, colors.red, " ")
	local textLimit = limX-10
	term.setBackgroundColor(colors.red)
	term.setTextColor(colors.white)
	
	--TODO separate msg into lines if necessary 
	
	term.setCursorPos(6, 5)
	term.write(msg)
	term.setBackgroundColor(colors.black)
	buttonClose(math.ceil(limX/2)-2, limY-4)
end

local function popupInputField(msg)
	
end

local function popupInputSelect(msg, list)
	
end

local function popupConfirm(msg)
	
end

--Test Code---------------------------------------------
background()
popupFail("Operation failed.")
term.setCursorPos(1, limY)