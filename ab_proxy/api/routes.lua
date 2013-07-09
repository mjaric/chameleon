local render = ngx.say;
local log = ngx.log;
local ngx = ngx;
local balance = balance;
local ab_proxy = ab_proxy;
local serialize = cjson.encode;
local deserialize = cjson.decode;
local tonumber = tonumber;
local table = table;
local ipairs = ipairs;

local ERROR = ngx.ERR;
local WARNING = ngx.WARN;
local INFO = ngx.INFO;



module("ab_proxy.api.routes");

local routes = {
	{method= "GET", path = "/balance", action = function(params)		
		local data = balance.load();
		local json = serialize(data);
		render(json);
	end},
	{method= "PUT", path = "/balance", action = function(params)
		balance.update(params);
		local data = balance.load();
		local json = serialize(data);
		render(json);
	end},
	{method= "DELETE", path = "/balance", action = function(params)
		balance.reset();
		local data = balance.load();
		local json = serialize(data);
		render(json);
	end},
	{method= "GET", path = "/experiments", action = function(params)
		local strategies = ab_proxy.get_strategies();
		local json = serialize(strategies);
		render(json);
	end},
	
	-- {method= "GET", path = "/experiments/:id", action = function(params)
		
	-- 	local strategy = ab_proxy.get_strategies()[params.id];
	-- 	local json = serialize(strategy);
	-- 	render(json);
	-- end},
	
	{method= "POST", path = "/experiments", action = function(params)
		-- Bulk save
		local s = ab_proxy.build_strategies_from_table(params);
		ab_proxy.replace_and_save(s);
		-- local strategies = ab_proxy.get_strategies();
		local json = serialize(s);
		log(INFO, "/experiments");
		render(json);
	end},

	{method= "DELETE", path = "/experiments/:id", action = function(params)
		local strategies = ab_proxy.get_strategies();
		local path = ngx.unescape_uri(params.id);
		-- ngx.log(ngx.NOTICE, path .. " ====== " .. params.id);
		for i,v in ipairs(strategies) do 
			if v.handles_path == path then
				table.remove(strategies, i);
				ab_proxy.replace_and_save(strategies);
				do return; end
			end
		end
	end}
};

return routes;