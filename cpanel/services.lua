local cjson = require "cjson";
local redis = require "resty.redis";

ngx.header.content_type = 'application/json';
local function convertToRedis(val)
	if type(val) == "boolean" then
		return (a and "1" or "0" );
	else
		return tostring(val);
	end
end

local method = ngx.req.get_method();
local params = ngx.req.get_uri_args() or {};
ngx.req.read_body()
local post_args = ngx.req.get_post_args();
if post_args then
	for k, v in pairs(post_args) do 
		p = cjson.decode(k)
		for key,val in pairs(p) do
			params[key] = convertToRedis(val);
		end
	end
end

local response = {}

local action = string.gsub(ngx.var.uri, "/admin/api/", "");


local controller = require("cpanel/api/actions/" .. action);
response = controller[method:lower()](params);
ngx.say(cjson.encode({response = response}));