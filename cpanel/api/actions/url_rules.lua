local cfg = require("../config");
local redis = require "resty.redis";

local function cmd()
	
	local red = redis:new();
	red:set_timeout(1000);
	local res, err = red:connect(cfg.REDIS_HOST_NAME, 6379);
	if not res then
	    ngx.log(ngx.ERR, "failed to connect: ", err);
	    return;
	end
	res, err = red:select("2");
	return red;
end


local commands =  { };

function commands.get(params)
	red = cmd();
	res, err = red:hgetall(cfg.key_name.IS_BETA_OFF);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HGETALL " .. cfg.key_name.IS_BETA_OFF .. "'", err);
	end
	res = red:array_to_hash(res);
	red:close();
	return res;
end

function commands.post(params)
	red = cmd();
	
	res, err = red:hset(cfg.key_name.IS_BETA_OFF, params["url"], params["value"]);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HSET " .. cfg.key_name.IS_BETA_OFF .. " " .. key .. "'", err);
	end

	red:close();
	return commands.get();
end

function commands.delete(params)
	red = cmd();
	
	res, err = red:hdel(cfg.key_name.IS_BETA_OFF, params["url"]);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HDEL " .. cfg.key_name.IS_BETA_OFF .. " " .. key .. "'", err);
		return nil
	end

	red:close();
	return commands.get();
end

return commands;