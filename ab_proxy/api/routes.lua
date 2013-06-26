local render = ngx.say;
local log = ngx.log;
local balance = balance;
local ab_proxy = ab_proxy;
local serialize = cjson.encode;
local deserialize = cjson.decode;
local tonumber = tonumber;

local ERROR = ngx.ERR;
local WARNING = ngx.WARN;
local INFO = ngx.INFO;


module("ab_proxy.api.routes");

local routes = {
	{method= "GET", path = "/balance", action = function(params)		
		local json = serialize(balance.get_data());
		render(json);
	end},
	{method= "PUT", path = "/balance", action = function(params)
		balance.update(params);
		local json = serialize(balance.get_data());
		render(json);
	end},
	{method= "DELETE", path = "/balance", action = function(params)
		balance.reset();
		local json = serialize(balance.get_data());
		render(json);
	end},
	{method= "GET", path = "/experiments", action = function(params)
		local strategies = ab_proxy.get_strategies();
		local json = serialize(strategies);
		render(json);
	end},
	
	{method= "GET", path = "/experiments/:id", action = function(params)
		local strategy = ab_proxy.get_strategies()[tonumber(params.id)];
		local json = serialize(strategy);
		render(json);
	end},
	
	{method= "POST", path = "/experiments", action = function(params)
		-- save new experiment on top of list

	end},

	{method= "PUT", path = "/experiments/:id", action = function(params)

	end},
	{method= "DELETE", path = "/experiments/:id", action = function(params)

	end}
};

return routes;