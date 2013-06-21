local cjson = cjson;
local utils = utils;
local os = os;
local ngx = ngx;
local db = db;
local pairs = pairs;
local math = math;
local setmetatable = setmetatable;

module("ab_proxy.balance");
-- Data structure of balancer configuration

local data = {
  master_user_count = 1,
  beta_user_count = 1,
  is_beta_off = true,
  keep_beta_under = 5,
  test_version = "13.071",
  updated_at = os.time({year=1901, month=1, day=1, hour=1})
};

function save()
	db.exec(function(red)
		data.updated_at = os.time(os.date("*t"));
		return red:set("experiment", cjson.encode(data));
	end);
end

function save_async()
	local time_span = os.difftime(os.time(os.date("*t")), data.updated_at);
	if time_span > 60 then
		-- data.updated_at = os.time(os.date("*t"));
		utils.async(save);
	end
end

function load()
	local cfg = db.exec(function(red)
		return red:get("experiment");
	end);
	if cfg == ngx.null or not cfg then
		-- this is case when no configuration is stored into database
		-- so we want to persist our configuration before we continue
		save();
	else
		data = utils.extend(data,cjson.decode(cfg));
	end
end

function inc_a()
	data.master_user_count = data.master_user_count + 1;
end

function inc_b()
	data.beta_user_count = data.beta_user_count + 1;
end

function get_balance()
	local total = data.beta_user_count + data.master_user_count;
	local balance = data.beta_user_count * 100 / total;
	return math.floor(balance);
end

function reset()
	cfg = {
	  master_user_count = 1,
	  beta_user_count = 1,
	  is_beta_off = true,
	  keep_beta_under = 5
	}
	data = utils.extend(data, cfg);
end

utils.build_accesors(_M, data);


local module_mt = { 
	-- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
};

setmetatable(_M, module_mt)

