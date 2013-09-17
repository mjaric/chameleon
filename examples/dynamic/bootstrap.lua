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

