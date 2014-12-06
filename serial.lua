-- table serialization code based on http://lua-users.org/wiki/TableUtils

local valToStr, keyToStr, pack, unpack, validate

function pack(tbl)
	local result, done = {}, {}
	for k, v in ipairs(tbl) do
		table.insert(result, valToStr(v))
		done[k] = true
	end
	for k, v in pairs(tbl) do
		if not done[k] then
			table.insert(result, keyToStr(k).."="..valToStr(v))
		end
	end
	return "{"..table.concat(result, ",").."}"
end

function valToStr(v)
	if type(v) == "string" then
		v = string.gsub(v, "\\", "\\\\")
		v = string.gsub(v, "\n", "\\n")
		return '"'..string.gsub(v, '"', '\\"')..'"'
	else
		return type(v) == "table" and pack(v) or tostring(v)
	end
end

function keyToStr(k)
	if type(k) == "string" and string.match(k, "^[_%a][_%a%d]*$") then
		return k
	else
		return "["..valToStr(k).."]"
	end
end


-- some makeshift validation
-- finds all non-string portions of the serialized table
-- scans them for forbidden patterns
-- should be enough to prevent malicious code
-- only double quotes ("") are allowed for string literals

local forbidden = {
	"[^%a]and[^%a]",
	"[^%a]break[^%a]",
	"[^%a]do[^%a]",
	"[^%a]else[^%a]",
	"[^%a]elseif[^%a]",
	"[^%a]end[^%a]",
	"[^%a]for[^%a]",
	"[^%a]function[^%a]",
	"[^%a]if[^%a]",
	"[^%a]local[^%a]",
	"[^%a]nil[^%a]",
	"[^%a]not[^%a]",
	"[^%a]or[^%a]",
	"[^%a]repeat[^%a]",
	"[^%a]return[^%a]",
	"[^%a]then[^%a]",
	"[^%a]until[^%a]",
	"[^%a]while[^%a]",
	"[^{}=,.%d%a%[%]]",       -- only these characters allowed outside strings
	"[^{,_%w]([_%a][_%w]*)",  -- identifiers can only come after { or ,
	"([_%a][_%w]*)[^_%w=]",   -- identifiers can only precede =
	-- note, if the match is 'true' or 'false' then it should still be allowed to pass
}

function validate(str)
	
	str = str:match("{.*}")
	if not str then
		return false
	end
	
	local parts = {}
	local i, j = 1, 1
	local char, prev
	
	while j <= #str do
		char = str:sub(j,j)
		if char=="\"" then
			-- strings may only begin after certain characters
			if prev:match("[^{=,%[]") then
				return false
			end
			
			table.insert(parts, str:sub(i, j-1))
			repeat
				prev = char
				j = j + 1
				char = str:sub(j,j)
			until char=="\"" and prev~="\\"
			i = j + 1
		end
		prev = char
		j = j + 1
	end
	
	table.insert(parts, str:sub(i, j))
	
	for _, part in ipairs(parts) do
		for _, pattern in ipairs(forbidden) do
			local match = part:match(pattern)
			if match and match ~= "true" and match ~= "false" then
				--print(part, pattern, part:match(pattern))
				return false
			end
		end
	end
	
	return true
end

function unpack(str)
	if not validate(str) then
		return nil, "Failed validation: "..str
	end
	
	local f, err = loadstring("return "..str)
	
	if not f then
		return nil, "Failed loadstring: "..err
	end
	
	local success, res = xpcall(f, debug.traceback)
	
	if success then
		return res -- the table
	end
	
	-- nil and an error message
	return nil, res
end

local function testsuite()
	assert(validate('{}'))
	assert(validate('{{}}'))
	assert(validate('{1,2,3}'))
	assert(validate('{"foo","bar"}'))
	assert(validate('{foo="bar",baz=1.2}'))
	assert(validate('{[true]=false}'))
	assert(validate('{foo={1,2,3,"hello world"}}'))
	assert(validate('{foo=1.2}'))
	assert(validate('{[1.5]="return the cheese"}'))
	assert(validate('{text="@:~{]"}'))
	assert(not validate('foo'))
	assert(not validate('foo()'))
	assert(not validate('{hax}'))
	assert(not validate('{foo=hax}'))
	assert(not validate('{[foo]=hax}'))
	assert(not validate('{foo=hax()}'))
	assert(not validate('{foo=return}'))
	assert(not validate('{[1]={self}}'))
	assert(not validate('{foo=require"bar"}'))
	assert(not validate('{require"bar"}'))
	print("Serial.lua - All tests completed")
end

--testsuite()



-- split a string into tokens (separating at whitespace or commas)
-- parameters enclosed in quotation marks are kept in their entirity
-- this is useful for handling console commands and the like
local function split(str)
	local parts = {}
	for s in str:gmatch('([^"]+)') do
		table.insert(parts, s)
	end
	
	local isQuote = str:match('^"') ~= nil
	local tokens = {}
	
	for i,v in ipairs(parts) do
		if isQuote then
			table.insert(tokens, v)
		else
			for word in v:gmatch("([^%s,]+)") do
				table.insert(tokens, word)
			end
		end
		isQuote = not isQuote
	end
	return tokens
end



local function parsecsv(str)
	local t = {}
	for val in str:gmatch("([^, \n]+)") do
		table.insert(t, tonumber(val))
	end
	return t
end


-- XML parser by Roberto Ierusalimschy
-- http://lua-users.org/wiki/LuaXml

local function parseargs(s)
	local arg = {}
	string.gsub(s, "([%-%w]+)=([\"'])(.-)%2", function (w, _, a)
		arg[w] = a
	end)
	return arg
end

local function parsexml(s)
	local stack = {}
	local top = {}
	table.insert(stack, top)
	local ni,c,label,xarg, empty
	local i, j = 1, 1
	while true do
		ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
		if not ni then break end
		local text = string.sub(s, i, ni-1)
		if not string.find(text, "^%s*$") then
			table.insert(top, text)
		end
		if empty == "/" then  -- empty element tag
			table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
		elseif c == "" then  -- start tag
			top = {label=label, xarg=parseargs(xarg)}
			table.insert(stack, top)  -- new level
		else  -- end tag
			local toclose = table.remove(stack)  -- remove top
			top = stack[#stack]
			if #stack < 1 then
				error("nothing to close with "..label)
			end
			if toclose.label ~= label then
				error("trying to close "..toclose.label.." with "..label)
			end
			table.insert(top, toclose)
		end
		i = j+1
	end
	local text = string.sub(s, i)
	if not string.find(text, "^%s*$") then
		table.insert(stack[#stack], text)
	end
	if #stack > 1 then
		error("unclosed "..stack[#stack].label)
	end
	return stack[1]
end



return {
	pack = pack,
	unpack = unpack,
	split = split,
	parsexml = parsexml,
	parsecsv = parsecsv
}
