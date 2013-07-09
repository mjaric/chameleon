local cjson = cjson;
local utils = utils;
local os = os;
local ngx = ngx;
local db = db;
local pairs = pairs;
local math = math;
local setmetatable = setmetatable;
local print = print;
local type = type;

module("ab_proxy.balance");
-- Data structure of balancer configuration

local balancer = {};
local data = {
  master_user_count = 1,
  beta_user_count = 1,
  is_beta_off = "true",
  keep_beta_under = 5,
  test_version = "13.071"
};

balancer = utils.extend(balancer, data);

local function to_lua(tab)
	local t = {};
	t = utils.extend(t, tab);	
	if t.is_beta_off == "false" then
		t.is_beta_off = false;
	else
		t.is_beta_off = true;
	end
	return t;
end

local function to_redis(tab)
	local t = {};
	t = utils.extend(t, tab);	
	if not t.is_beta_off then
		t.is_beta_off = "false";
	else
		t.is_beta_off = "true";
	end
	return t;
end

local function get_balancer()
	return db.exec(function(red)
		local res, err = red:hgetall("balancer");
		res = red:array_to_hash(res);
		if not res or not res.test_version then 
			red:hmset("balancer", to_redis(balancer));
		end 
		
		return to_lua(res), err; 
	end);
end

function get_data()
	return balancer;
end

function save(t)
	db.exec(function(red)
		red:hmset("balancer", to_redis(t));
	end);
end


function load()
	return utils.extend(balancer, get_balancer());
end

function update(t)
	save(t);
end

function inc_a()
	db.exec(function(red)
		return red:hincrby("balancer", "master_user_count", 1);
	end);
end

function inc_b()
	balancer.beta_user_count = db.exec(function(red)
		return red:hincrby("balancer", "beta_user_count", 1);
	end);
end

function get_balance()
	local total = balancer.beta_user_count + balancer.master_user_count;
	local balance = balancer.beta_user_count * 100 / total;
	return math.floor(balance);
end

function is_off()
	return balancer.is_beta_off;
end

function reset()
	  balancer.master_user_count = 1;
	  balancer.beta_user_count = 1;
	  balancer.is_beta_off = true;
	  balancer.keep_beta_under = 5;
	  save(balancer);
	  load();
end

utils.build_accesors(_M, balancer);


local module_mt = { 
	-- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
};

setmetatable(_M, module_mt)

