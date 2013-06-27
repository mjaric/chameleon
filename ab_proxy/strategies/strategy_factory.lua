-- this module wires all configured strategies into event table
-- where request url triggers specific strategy or just default
-- pass trough strategy which serves contnet from unchanged (non rewriten url)
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
local tostring = tostring;
local table = table;


module("ab_proxy.strategies.strategy_factory");

local REDIS_KEY = "experiment_strategies";
local default = DefaultStrategy:create();
local strategies = {};

local factories = {
	balance = function(...) return BalanceStrategy:create(...); end,
	force_a = function(...) return ANodeStrategy:create(...); end,
	force_b = function(...) return BNodeStrategy:create(...); end
}

function build_strategy(t)
	local fun = factories[t.strategy_type];
	if not fun then
		ngx.log(ngx.WARN, "Strategy " .. t.strategy_type .. " is not recognised." );
		return nil;
	else
		return fun(t)
	end
end
function build_strategies_from_table(data)
	local result = {};

	for i, v in ipairs(data) do
		local s = build_strategy(v);
		if s ~= nil then
			result[#result + 1] = s;
		end
	end
	local count = #result;
	if  count < 1 then
		result[#result + 1] = BNodeStrategy:create({
			handles_path = "^/web/groundlink/(.*)$", 
			a_route = "",
			b_route = "" 
		});
		result[#result + 1] = BalanceStrategy:create();
	end
	return result;
end

-- Loads routings strategies from database
function load()
	local result = db.exec(function(red)
		return red:get(REDIS_KEY);
	end);
	return result;
end
-- Save routing strategies to database
function save()
	db.exec(function(red)
		return red:set(REDIS_KEY, cjson.encode(strategies));
	end);
end
function replace_and_save(s)
	
	strategies = s;
	save();
end
-- initializes routing strategy table and prepares default strategy when non of custom 
-- strategies is defined or they are not recognised as the one which should be executed
function initialize()
	ngx.log(ngx.NOTICE, "PLEASE NOTE, WE ARE RELOADING CONFIGURATION");
	local t = {};
	local result = load();
	if not result or result == ngx.null then 
		t = {};
	else
		t = cjson.decode(result)
	end
	strategies = build_strategies_from_table(t);
end
-- this method will find stategy which satisfies routing criteria (url match)
-- and executes it... if no custom strategy is found in table then default one will be
-- executed
function handle_url(url)
	local route_strategy = default;
	
	for i,s in ipairs(strategies) do
		
		if s:is_match_of(url) then
			route_strategy = s;
			do break end
		end
	end
	ngx.log(ngx.NOTICE, "Using strategy [" .. route_strategy.strategy_type:upper() .."]");
	route_strategy:execute();
end

function get_strategies()
	return strategies;
end

function prepand(strategy)
	local temp = { };
	temp[#temp + 1] = strategy;
	for i,v in ipairs(strategies) do
		temp[#temp + 1] = v;
	end
	strategies = temp;
	return strategy;
end
