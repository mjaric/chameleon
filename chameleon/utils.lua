local cjson = require("cjson");
local pairs = pairs;
local ipairs = ipairs;
local type = type;
local rawset = rawset;
local rawget = rawget;
local ngx = ngx;
local string = string;
local os = os;
local tonumber = tonumber;

module(...);

-- private
  local lua_special_pattern_chars = {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  };


-- public
function round(num) return math.floor(num+.5) end

function build_cookie(routeid, path)
    path= path or "/";
    local date= os.date("*t");
    local time= os.time({year=date.year+1, month=date.month, day=date.day, hour=0});
    local expires = os.date("%A, %d-%b-%Y %X GMT", time);
    return "ROUTE=" .. routeid .. "; Expires=" .. expires .. "; Path=" .. path;
end

---Checks if a table is used as an array. That is: the keys start with one and are sequential numbers
-- @param t table
-- @return nil,error string if t is not a table
-- @return true/false if t is an array/isn't an array
-- NOTE: it returns true for an empty table
function is_array(t)
    if type(t)~="table" then return nil,"Argument is not a table! It is: "..type(t) end
    --check if all the table keys are numerical and count their number
    local count=0
    for k,v in pairs(t) do
        if type(k)~="number" then 
        	return false 
        else 
        	count=count+1 
        end
    end
    -- all keys are numerical. now let's see if they are sequential and start with 1
    for i=1,count do
        -- Hint: the VALUE might be "nil", in that case "not t[i]" 
        -- isn't enough, that's why we check the type
        if not t[i] and type(t[i])~="nil" then 
        	return false 
        end
    end
    return true
end

function extend(dst, src, exclude)
	if not src then 
		return dst;
	end
    local excluded = exclude or {};
	for k, v in pairs(src) do
        if not excluded[k] then
    		if type(v) == "table" then
    			if not rawget(dst, k) then
    				rawset(dst, k, {});
    			end
    			extend(dst[k], v);
    		else
                local value = tonumber(v);
                if not value then
                    value = v;
                end 
    			rawset(dst, k, value);
    		end
        end
	end
	
	return dst;
end


function async(fn, ...)
	--ngx.thread.spawn(fn, ...);
    fn(...);
end
-- this function should build getter and setter pairs for
-- any object which wants to hide specific data/table
-- first parameter is table which should provide getters and setters 
-- second parameter is actual data table
function build_accesors(m, t)
	local mod = m;
	local lua_table = t;
	for k,v in pairs(lua_table) do
		local getter_name = "get_"..k;
		local setter_name = "set_"..k;
		local key = k;
		mod[getter_name] = function ()
			return lua_table[key];
		end;

		mod[setter_name] = function(v)
			lua_table[key] = v;
		end;
	end
end

----------------------------------------------------------------------------
-- Decode an URL-encoded string (see RFC 2396)
----------------------------------------------------------------------------
function unescape (str)
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end

----------------------------------------------------------------------------
-- URL-encode a string (see RFC 2396)
----------------------------------------------------------------------------
function escape (str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^0-9a-zA-Z ])", -- locale independent
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
    return str
end

----------------------------------------------------------------------------
-- Insert a (name=value) pair into table [[args]]
-- @param args Table to receive the result.
-- @param name Key for the table.
-- @param value Value for the key.
-- Multi-valued names will be represented as tables with numerical indexes
--  (in the order they came).
----------------------------------------------------------------------------
function insertfield (args, name, value)
    if not args[name] then
        args[name] = value
    else
        local t = type (args[name])
        if t == "string" then
            args[name] = {
                args[name],
                value,
            }
        elseif t == "table" then
            table.insert (args[name], value)
        else
            error ("CGILua fatal error (invalid args table)!")
        end
    end
end

----------------------------------------------------------------------------
-- Parse url-encoded request data 
--   (the query part of the script URL or url-encoded post data)
--
--  Each decoded (name=value) pair is inserted into table [[args]]
-- @param query String to be parsed.
-- @param args Table where to store the pairs.
----------------------------------------------------------------------------
function parsequery (query, args)
    if type(query) == "string" then
        local insertfield, unescape = insertfield, unescape
        string.gsub (query, "([^&=]+)=([^&=]*)&?",
            function (key, val)
                insertfield (args, unescape(key), unescape(val))
            end)
    end
end

----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
--   URL for passing data/parameters to another script
-- @param args Table where to extract the pairs (name=value).
-- @return String with the resulting encoding.
----------------------------------------------------------------------------
function encodetable (args)
  if args == nil or next(args) == nil then   -- no args or empty args?
    return ""
  end
  local strp = ""
 for key, vals in pairs(args) do
    if type(vals) ~= "table" then
      vals = {vals}
    end
    for i,val in ipairs(vals) do
      strp = strp.."&"..escape(key).."="..escape(val)
    end
  end
  -- remove first & 
  return string.sub(strp,2)
end

function escape_lua_pattern(s)
    return (s:gsub(".", lua_special_pattern_chars))
end

-- use it in combination with find
-- EXAMPLE:
-- capture_matches(a:find("^/some/([^/.]+)/another/([^/.]+)$"));
-- it returns the array of captured values
function capture_matches(...)
    local values = {};
    
    if arg ~= nil then 
        for i,v in ipairs(arg) do 
            if i > 2 then
                ngx.say(v);
                -- check if we need to convert value into number
                -- dates in lua are numbers :) yay!!!
                local val = tonumber(v);
                if not val then

                    values[#values + 1] = v;
                else
                    values[#values + 1] = val;
                end
            end
        end 
    end 
    return values;
end

