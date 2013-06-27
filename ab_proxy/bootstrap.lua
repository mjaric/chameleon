cjson = require('cjson');
config = require('ab_proxy.config');
db = require('ab_proxy.db');
utils = require('ab_proxy.utils');
balance = require('ab_proxy.balance');
ab_proxy = require('ab_proxy.strategies.strategy_factory');

-- needed for UI and management API
rack = require('ab_proxy.api.rack'):create();
routes = require('ab_proxy.api.routes');

-- initialization for api and control-panel ui  
rack:load(routes);
-- initialization true/false flag for balancer and strategies for ab_proxy

local initialized = false;

function initialize()
	-- while all modules are initialized in bootstap.lua module last global which is set is
	-- initialized = false so we can load all configurations on first request
	if not initialized then
		initialized = true;
		-- load last counters from db, and some configuration related to it.
		balance.load();
		-- reload any routes which may be stored last time server was running
		-- since routes are persisted in db while they are changed in control panel 
		-- we don't need to save them. this is only for initial request
		ab_proxy.initialize();
	end
end

