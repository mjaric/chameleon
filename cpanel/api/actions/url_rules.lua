local redis = require "resty.redis";

local config = {
	root = "ab_url_tests"
}


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


local commands =  { };

function commands.get(params)
	red = cmd();
	res, err = red:hgetall(config.root);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HGETALL " .. config.root .. "'", err);
	end
	res = red:array_to_hash(res);
	red:close();
	return res;
end

function commands.post(params)
	red = cmd();
	
	res, err = red:hset(config.root, params["url"], params["value"]);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HSET " .. config.root .. " " .. key .. "'", err);
	end

	red:close();
	return commands.get();
end

function commands.delete(params)
	red = cmd();
	
	res, err = red:hdel(config.root, params["url"]);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HDEL " .. config.root .. " " .. key .. "'", err);
		return nil
	end

	red:close();
	return commands.get();
end

return commands;