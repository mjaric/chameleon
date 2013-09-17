local utils = require('chameleon.utils');
local config = require('chameleon.config');
local balance = balance;
local ngx = ngx;
local type = type;
local setmetatable = setmetatable;

module(...);


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
	if self.is_active and not balance.is_off() then
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
	local cookie_b = "2x-" .. version;
	
	if not cookie_value or cookie_value ~= cookie_b then
		balance.incr_b();
	end

	ngx.header['Set-Cookie']= utils.build_cookie(cookie_b, "/");
	ngx.var.node_domain = config.beta_domain;
	ngx.var.node = "beta";
	if self.b_route ~= "" and ngx.var.uri ~= self.b_route then
		ngx.redirect(self.b_route);
	end
end

