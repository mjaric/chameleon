local utils = require('chameleon.utils');
local config = require('chameleon.config');
local balance = balance;
local ngx = ngx;
local type = type;
local setmetatable = setmetatable;

module(...);

local ANodeStrategy_mt = { __index = _M };

function create(self, tbl)
	tbl = tbl or {};
	local t = {
		strategy_type = "force_a",
		handles_path = "^/$",
		a_route = "/",
		b_route = "/web/groundlink/",
		is_active = true
	};
	if type(tbl) == "table" then 
		utils.extend(t, tbl);
	end
	return setmetatable(t,ANodeStrategy_mt);
end

function is_match_of(self, url)
	local is_match = false;
	if self.is_active then
		local u = utils.unescape(url);
		-- todo: probably, there is need to have some escaping 
		-- for pattern matching string to make input much easier
		if u:match(self.handles_path) then
			is_match = true;
		end
	end
	return is_match;
end

function execute(self)
	local version = balance.get_version();
	local cookie_value = ngx.var.cookie_ROUTE;
	local cookie_a = "1x-" .. version;
	

	if not cookie_value or cookie_value ~= cookie_a then
		balance.incr_a();
	end

	ngx.header['Set-Cookie'] = utils.build_cookie(cookie_a, "/");
	ngx.var.node_domain = config.master_domain;
	ngx.var.node = "master";
	if self.a_route ~= "" and ngx.var.uri ~= self.a_route then
		-- in case route is not same as Url, redirect to a_route
		-- otherwise just pass request to upstream
		ngx.redirect(self.a_route);
	end
end

