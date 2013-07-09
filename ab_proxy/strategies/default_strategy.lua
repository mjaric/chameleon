local config = config;
local utils = utils;
local ngx = ngx;
local balance = balance;
local setmetatable = setmetatable;
local type = type;
local tostring = tostring;

module("ab_proxy.strategies.default_strategy");

local DefaultStrategy_mt = { __index = _M };

function create(self, tbl)
	tbl = tbl or {};
	local t ={ 
		strategy_type = "default",
		handles_path = "^(.*)$",
		a_route = "^/",
		b_route = "^/web/groundlink/",
		is_active = true
	};
	if type(tbl) == "table" then 
		utils.extend(t, tbl);
	end
	return setmetatable(t, DefaultStrategy_mt);
end

local function execute_when_beta_is_off(self)
	
	local const = config.get();
	if ngx.var.uri:match(self.b_route) then
		ngx.redirect("/");
		do return; end;
	end
	ngx.var.node = "master";
	ngx.var.node_domain = const["master_domain"];
end

local function execute_when_beta_is_on(self)

	local const = config.get();
	local cookie_value = ngx.var.cookie_ROUTE;
	local version = balance.get_test_version();
	local cookie_a = "1x-" .. version;
	local cookie_b = "2x-" .. version;
	local node = "master";

	if cookie_value == ngx.null or not cookie_value then
		-- no cookie is found and
		-- no A/B test strategy has been identified in routing table
		-- so we are forcing A node
		balance.inc_a();
		ngx.header["Set-Cookie"] = utils.build_cookie(cookie_a, "/");
		node = "master";
	else
		-- stay on the same route, we are serving both websites in "/" location
		-- also extend expiration date for cookie
		if cookie_value == cookie_b then
			node = "beta";			
		else
			node = "master";
		end
	end
	
	ngx.var.node = node;
	-- seting correct host name so upstream knows which vhost should respond
	-- in case www.groundlink.com domain it will be same, but here 
	-- we ensure that correct one is sent to upstream
	ngx.var.node_domain = const[node .. "_domain"];
end


function execute(self)
	if balance.is_off() then 
		execute_when_beta_is_off(self);
	else
		execute_when_beta_is_on(self);
	end
end