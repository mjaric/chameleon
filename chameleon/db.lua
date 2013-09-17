local config = require("chameleon.config");
local redis= require("resty.redis");

local ngx = ngx;
local pairs= pairs;

module(...);
-- executes redis command
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