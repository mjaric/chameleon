local utils = require("chameleon.utils");
local setmetatable = setmetatable;
local ngx = ngx;
local ipairs = ipairs;
local pairs = pairs;
local math = math;


module(...)
_VERSION = '0.1'

local shm_prefix = "balance.";
local Balance_mt = {
	__index = _M 
};
local data_template = {
	master_user_count = 1,
	beta_user_count = 1,
	percentage = 50,
	version = "0.0.1",
	status = 0
};


-- creates new instance of balancer
function initialize(version)
	for key, val in pairs(data_template) do
		ngx.shared.experiments:set( shm_prefix  .. key , val);
	end
	ngx.shared.experiments:set(shm_prefix  .. "version" , version);
end

-- build auto getters and setters for data which will be stored i shared memory dictionary
for key, val in pairs(data_template) do
	ngx.log(ngx.INFO, "building balancer shared dictionary accessors");
	-- getter
	_M["get_" .. key ] = function()
		return ngx.shared.experiments:get(shm_prefix .. key);
	end
	-- setter
	_M["set_" .. key] = function(value)
		ngx.shared.experiments:set(shm_prefix .. key, value);
	end
end

function is_off()
	return get_status() == 0;
end

function incr_a()
	ngx.shared.experiments:incr(shm_prefix .. "master_user_count", 1);
end

function incr_b()
	ngx.shared.experiments:incr(shm_prefix .. "beta_user_count", 1);
end

function get_hit_count()
	return get_beta_user_count() + get_master_user_count();
end

function get_b_percentage()
 	local current_balance = get_beta_user_count() * 100 / get_hit_count();
 	return utils.round(current_balance);
end

function get_a_percentage()
 	local current_balance = get_master_user_count() * 100 / get_hit_count();
 	return utils.round(current_balance);
end

function which_node()
	if(get_b_percentage() < get_percentage()) then
		return "beta"
	end
	return "master"
end