local ngx = ngx;
local cjson = require("cjson");
local utils = require("chameleon.utils");

local setmetatable = setmetatable;
local ipairs = ipairs;
local pairs = pairs;
local tonumber = tonumber;
local string = string;
local type = type;
local table = table;


module(...);

local path_match = "/([^/]+)";
local function get_request()
	local m = ngx.req.get_method();
	local p = ngx.req.get_uri_args() or {};
	-- capture route without parameters (parameters behind ? will be handled later)
	local a = string.gsub(ngx.var.uri, "/ab-cpanel/api(/[^%?%#]*)([%?%#]?)(.*)", "%1");
	ngx.req.read_body()
	-- TODO: check content type and accept headers so we know how to respond
	-- so far we will respond with application/json
	local request_body = ngx.req.get_body_data();
	local post_args = {};
	if request_body and string.len(request_body) > 0 then 
		post_args = cjson.decode(request_body);
	end
	if post_args then
		p = utils.extend(p, post_args);
	end	
	return {
		method = m,
		params = p,
		path = a,
		headers = ngx.req.get_headers()
	}
end

local Router = {
	routing_table = { GET = {} , POST = {} , PUT = {}, DELETE = {} };
};
local Router_mt = { __index = _M };

function create(self)
	return setmetatable(Router, Router_mt);
end

function load(self, routes)
	
	for i, r in ipairs(routes) do
		-- used in closure below
		local route = r;
		-- sets table like GET = {} or POST = {} ... prepared if they do not exists
		local method_table = self.routing_table[route.method];
		-- prepare matching string for route path with captures which will be concated into
		-- request parameters table
		local path_regex = "";
		local path_param_names = {};
		route.path:gsub(path_match, function(component)
			if component:sub(1, 1) == ":" then
				-- remove named parameter and add it to liast of param_names
				-- so later we can add them to reqest parameters table
				path_param_names[#path_param_names + 1] =  component:sub(2, component:len());
				-- replace match with path_match regular expression which is
				-- capture ... it will keep index to easy pull it out later
				path_regex = path_regex .. path_match;
			else 
				path_regex = path_regex .. "/" .. utils.escape_lua_pattern(component);
			end
		end);
		path_regex = "^" .. path_regex .. "$";

		-- this is dynamic request handler. It will return response if reqest
		-- match route path
		
		self.routing_table[route.method][path_regex] = function(req) 
			local match = path_regex;
			local param_names = path_param_names;
			local result = { req.path:find(match) };
			local temp = { };
			for i=3,#result do 
				temp[param_names[i - 2]] = result[i];
			end

			-- merge route key value pairs to reqest parameters
			utils.extend(req.params, temp);
			route.action(req.params);
		end;
	end
end

function handle_reqest(self)
	local request = get_request();
	local method_table = self.routing_table[request.method];
	local request_handled = false;
	for route_regex, route_handler in pairs(method_table) do
		if request.path:match(route_regex) then
			route_handler(request);
			request_handled = true;
			do break; end;
		end
	end
	if not request_handled then
		ngx.exit(ngx.HTTP_NOT_FOUND);
		ngx.log(ngx.WARN, "[".. request.method .."] " .. request.path .. " HTTP 404" );
	end
end

