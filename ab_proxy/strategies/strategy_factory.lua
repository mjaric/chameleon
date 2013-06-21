local BalanceStrategy = require("ab_proxy.strategies.balance_strategy");
local ANodeStrategy = require("ab_proxy.strategies.anode_strategy");
local BNodeStrategy = require("ab_proxy.strategies.bnode_strategy");
local DefaultStrategy = require("ab_proxy.strategies.default_strategy");
local config = config;
local ngx = ngx;
local utils = utils;
local db = db;
local ipairs = ipairs;
local rawget = rawget;
local rawset = rawset;
local cjson = cjson;


module("ab_proxy.strategies.strategy_factory");

-- this module wires all configured strategies into event table
-- where request url triggers specific strategy or just default
-- pass trough strategy which serves contnet from unchanged (non rewriten url)

local default = DefaultStrategy:create();
local strategies = {};
local factories = {
	balance = function(...) return BalanceStrategy:create(...); end,
	force_a = function(...) return ANodeStrategy:create(...); end,
	force_b = function(...) return BNodeStrategy:create(...); end
}

function load()
	local result = db.exec(function(red)
		return red:get("experiment_strategies");
	end);
	return result;
end

function save()
	db.exec(function(red)
		return red:set("experiment_strategies", cjson.encode(strategies));
	end);
end

local function build_from(data)
	local result = {};

	for i,v in ipairs(data) do
		local factory = factories[v.strategy_type];
		if not factory then
			ngx.log(ngx.WARN, "Strategy " .. v.strategy_type .. " is not recognised." );
		else
			result[#result + 1] = factory;
		end
	end
	if #result == 0 then
		result[#result + 1] = BalanceStrategy:create();
		result[#result + 1] = BNodeStrategy:create({
			handles_path = "^/web/groundlink/(.*)$", 
			a_route = "",
			b_route = "" 
		});
	end
	strategies = result;
end

function initialize()
	local t = {};
	local result = load();
	if not result or result == ngx.null then 
		t = {};
	else
		t = cjson.decode(result)
	end
	build_from(t);
end

function handle_url(url)
	local strategy = default;
	
	for i,s in ipairs(strategies) do
		ngx.log(ngx.INFO, "INDEX ............. " .. i)
		local first, last = s:is_match_of(url);
		if first and last then
			strategy = s;
			do break end
		end
	end
	ngx.log(ngx.INFO, "Strategy used for this request " .. strategy.strategy_type);
	strategy:execute();
end
