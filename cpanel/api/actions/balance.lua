local cfg = require("../config");
local redis = require "resty.redis";

local config = {
	root = "groundlink_ab_test",
	balnce = "keep_beta_under"
}

local red = redis:new();


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




local commands =  { }
function commands.get(params)
	red = cmd();
	res, err = red:hgetall(cfg.key_name.LOAD_BALANCE);
	res = red:array_to_hash(res);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HGETALL " .. cfg.key_name.LOAD_BALANCE .. "'", err);
	end
	red:close();
	return res;
end

function commands.post(params)
	red = cmd();
	for k,v in pairs(params) do
		res, err = red:hset(cfg.key_name.LOAD_BALANCE, k, v);
		if not res then
			ngx.log(ngx.ERR, "failed to execute 'HSET " .. cfg.key_name.LOAD_BALANCE .. " " .. cfg.key_name.KEEP_BETA_UNDER .. "'", err);
		end
	end
	red:close();
	return commands.get({});
end



return commands;