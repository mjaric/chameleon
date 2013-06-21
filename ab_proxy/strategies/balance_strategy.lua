local config = config;
local utils = utils;
local balance = balance;
local ngx = ngx;
local type = type;
local setmetatable = setmetatable;

module("ab_proxy.strategies.balance_strategy");

local Strategy = {
	strategy_type = "balance",
	handles_path = "^/$",
	a_route = "/",
	b_route = "/web/groundlink/"
};

local BalanceStrategy_mt = { __index = _M };


function create(self,tbl)
	tbl = tbl or {};
	local t = Strategy;
	if type(tbl) == "table" then 
		utils.extend(t, tbl);
	end
	return setmetatable(t, BalanceStrategy_mt);
end

function is_match_of(self, url)
	local u = utils.unescape(url);
	-- todo: probably, there is need to have some escaping 
	-- for pattern matching string to make input much easier
	return u:find(self.handles_path);
	-- return url == self.match_expression;
end

function execute(self)
	local version = balance.get_test_version();
	local cookie_value = ngx.var.cookie_ROUTE;
	local cookie_a = "1x-" .. version;
	local cookie_b = "2x-" .. version;
	local url = ngx.var.uri;

	
	-- validate cookie, create new one and increment countres
	if not cookie_value and cookie_value ~= cookie_a and cookie_value ~= cookie_b then
		if balance.get_balance() > balance.get_keep_beta_under() then 
			cookie_value = cookie_a;
			balance.inc_a();
		else
			cookie_value = cookie_b;
			balance.inc_b();
		end
	end
	-- route request
	if cookie_value == cookie_b then
		ngx.header['Set-Cookie']= utils.build_cookie(cookie_b, "/");
		ngx.var.node_domain = config.beta_domain;
		ngx.var.node = "beta";
		if self.b_route ~= "" and ngx.var.uri ~= self.b_route then
			ngx.redirect(self.b_route);
		end
	else
		ngx.header['Set-Cookie']= utils.build_cookie(cookie_a, "/");
		ngx.var.node_domain = config.master_domain;
		ngx.var.node = "master";
		if self.a_route ~= "" and self.a_route ~= url then
			ngx.redirect(self.a_route);
		end
	end

end

