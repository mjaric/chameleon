local config = config;
local ngx = ngx;
local pairs= pairs;

local redis= require("resty.redis");

module("ab_proxy.db");

function exec(fn)

	local const = config.get();

	local red = redis:new();
	red:set_timeout(1000);
	local ok, err = red:connect(const.redis_ip, const.redis_port);
	if not ok then
		ngx.log(ngx.ERR, err);
		return nil;
	end

	local ok, err = red:select(const.redis_db);
	if not ok then
		ngx.log(ngx.ERR, err);
		return nil;
	end

	local res, err = fn(red);
	if not res then
		ngx.log(ngx.ERR, err);
		return nil;
	end
	red:close();
	return res;
end