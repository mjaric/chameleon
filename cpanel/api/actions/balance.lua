require "cjson";
local redis = require "resty.redis";

local config = {
	root = "groundlink_ab_test",
	balnce = "keep_beta_under"
}

local red = redis:new();


local function cmd()
	local red = redis:new();
	red:set_timeout(1000);
	local res, err = red:connect("stream1.qa.towncar.us", 6379);
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
	res, err = red:hgetall(config.root);
	res = red:array_to_hash(res);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HGETALL " .. config.root .. "'", err);
	end
	red:close();
	return res;
end

function commands.post(params)
	red = cmd();
	for k,v in pairs(params) do
		res, err = red:hset(config.root, k, v);
		if not res then
			ngx.log(ngx.ERR, "failed to execute 'HSET " .. config.root .. " " .. config.balnce .. "'", err);
		end
	end
	red:close();
	return commands.get({});
end



return commands;