local redis = require "resty.redis";
local cfg = require "cpanel/config";


local function redis_connect()
    local red = redis:new();
    red:set_timeout(1000);
    local res, err = red:connect(cfg.REDIS_HOST_NAME, 6379);
    if not res then
        ngx.log(ngx.ERR, "failed to connect: ", err);
        return;
    end
    res, err = red:select("2");
    if not res then
        ngx.log(ngx.ERR, "failed to switch database: ", err);
        return;
    end
    return red;
end


local commands =  { };

function commands.get(params)
	red = redis_connect();
	res, err = red:hgetall(cfg.key_name.URL_RULES);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HGETALL " .. cfg.key_name.URL_RULES .. "'", err);
	end
	res = red:array_to_hash(res);
	red:close();
	return res;
end

function commands.post(params)
	red = redis_connect();
	
	res, err = red:hset(cfg.key_name.URL_RULES, params["url"], params["value"]);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HSET " .. cfg.key_name.URL_RULES .. " " .. key .. "'", err);
	end

	red:close();
	return commands.get();
end

function commands.delete(params)
	red = redis_connect();
	
	res, err = red:hdel(cfg.key_name.URL_RULES, params["url"]);
	if not res then
		ngx.log(ngx.ERR, "failed to execute 'HDEL " .. cfg.key_name.URL_RULES .. " " .. key .. "'", err);
		return nil
	end

	red:close();
	return commands.get();
end

return commands;
