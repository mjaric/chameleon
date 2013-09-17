local cjson = require('cjson');
--local db = require('chameleon.db');

balance = require('chameleon.balance');
balance.initialize("version-1.0.1");
balance.set_status(1);



local ANodeRoute = require('chameleon.strategies.anode_strategy');
local BNodeRoute = require('chameleon.strategies.bnode_strategy');
local BalancedRoute = require('chameleon.strategies.balance_strategy');
local DefaultRoute = require('chameleon.strategies.default_strategy');


-- Add all reoute handlers which should initiate experiment
local default = DefaultRoute:create();
local routes = {
	BalancedRoute:create{
		handles_path = "^/my%-experiment%-page",
		a_route = "",
		b_route = ""
	}
} 

-- this method will find stategy which satisfies routing criteria (url match)
-- and executes it... if no custom strategy is found in table then default one will be
-- executed
function handle_url(url)
	local route_strategy = default;
	
	for i,s in ipairs(routes) do
		
		
		if s:is_match_of(url) then
			ngx.log(ngx.NOTICE, "Using strategy [" .. s.strategy_type:upper() .."]");
			s:execute();
			return;
		end
	end
	ngx.log(ngx.NOTICE, "Using strategy [" .. route_strategy.strategy_type:upper() .."]");
	route_strategy:execute();
end


