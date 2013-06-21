local config = config;
local utils = utils;
local ngx = ngx;
local balance = balance;
local setmetatable = setmetatable;
local type = type;

module("ab_proxy.strategies.default_strategy");
local Strategy = { strategy_type = "default" };
local DefaultStrategy_mt = { __index = _M };

function create(self, tbl)
	tbl = tbl or {};
	local t = Strategy;
	if type(tbl) == "table" then 
		utils.extend(t, tbl);
	end
	return setmetatable(t, DefaultStrategy_mt);
end

function execute(self)
	ngx.req.set_header('X-Real-IP',  ngx.var.remote_addr);
	local const = config.get();
	local cookie_value = ngx.var.cookie_ROUTE;
	local version = balance.get_test_version();
	local cookie = "";
	local node = "master";
	if not cookie_value then
		-- no cookie is found and
		-- no A/B test strategy has been identified in routing table
		-- so we are forcing A node
		balance.inc_a();
		cookie = utils.build_cookie("1x-" .. version, "/");
	else
		-- stay on the same route, we are serving both websites in "/" location
		-- also extend expiration date for cookie
		cookie = utils.build_cookie(cookie_value, "/");
		if cookie_value ~= "1x-" .. version then
			node = "beta";			
		else
			node = "master";
		end
	end
	ngx.header["Set-Cookie"] = cookie;
	ngx.var.node = node;
	-- seting correct host name so upstream knows which vhost should respond
	-- in case www.groundlink.com domain it will be same, but here 
	-- we ensure that correct one is sent to upstream
	ngx.var.node_domain = const[node .. "_domain"];
	
end