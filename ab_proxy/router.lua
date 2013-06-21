local Strategy = require("ab_proxy.strategies.strategy_factory");
local utils = utils;
local os = os;
local ngx = ngx;
local db = db;
local pairs = pairs;
local math = math;
local setmetatable = setmetatable;
local null = ngx.null;


module("ab_proxy.router");


function initialize()
	-- Make sure that only on first request this is initialized
	Strategy.initialize();
end

function handle_request()
	ngx.log(ngx.INFO, "URL ACCESS " .. ngx.var.uri);
	Strategy.handle_url(ngx.var.uri);
end