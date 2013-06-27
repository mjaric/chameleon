local config = config;
local utils = utils;
local balance = balance;
local ngx = ngx;
local type = type;
local setmetatable = setmetatable;

module("ab_proxy.strategies.bnode_strategy");


local BNodeStrategy_mt = { __index = _M };


function create(self, tbl)
	tbl = tbl or {};
	local t = {
		strategy_type = "force_b",
		handles_path = "/",
		a_route = "/",
		b_route = "/web/groundlink/",
		is_active = true
	};
	if type(tbl) == "table" then 
		utils.extend(t, tbl);
	end
	return setmetatable(t,BNodeStrategy_mt);
end

function is_match_of(self, url)
	local is_match = false;
	if self.is_active then
		local u = utils.unescape(url);
		-- todo: probably, there is need to have some escaping 
		-- for pattern matching string to make input much easier
		if u:find(self.handles_path) then
			is_match = true;
		end
	end
	return is_match;
end

function execute(self)
	local version = balance.get_test_version();
	local cookie_b = "2x-" .. version;
	local has_cookie = not ngx.var.cookie_ROUTE or ngx.var.cookie_ROUTE == ngx.null;
	
	if has_cookie or cookie_b ~= ngx.var.cookie_ROUTE then
		balance.inc_b();
	end

	ngx.header['Set-Cookie']= utils.build_cookie(cookie_b, "/");
	ngx.var.node_domain = config.beta_domain;
	ngx.var.node = "beta";
	if self.b_route ~= "" and ngx.var.uri ~= self.b_route then
		ngx.redirect(self.b_route);
	end
end

