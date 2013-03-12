local redis = require "resty.redis";
local cfg = require "cpanel/config";

ngx.var.ab_backend = "master";
ngx.var.ab_hostname = cfg.MASTER_HOST_NAME;




local cookie_value = nil;
if ngx.var.cookie_ROUTEID then
	cookie_value = ngx.var.cookie_ROUTEID;
end
ngx.log(ngx.INFO, "ROUTEID = ", cookie_value);

function setRouteCookie(backend)
	local expires = os.date("%A, %d-%b-%Y %X GMT", os.time{year=2014, month=6, day=10, hour=0});
	ngx.header['Set-Cookie']= "ROUTEID=" .. backend .. "; Expires=" .. expires .. "; Path=/" ;
end

local uri = ngx.var.uri;


local red = redis:new();
red:set_timeout(1000);
local res, err = red:connect(cfg.REDIS_HOST_NAME, 6379);
if not res then
    ngx.log(ngx.ERR, "failed to connect: ", err);
    return;
end
res, err = red:select("2");
if not res then
    ngx.log(ngx.ERR, "failed to switch database: ", err);
    return;
end

res, err = red:hget(cfg.key_name.LOAD_BALANCE, cfg.key_name.IS_BETA_OFF)
if not res then
    ngx.log(ngx.ERR, "failed to get ab_url_tests hash, we will try to reset it to default 'off': ", err);
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.IS_BETA_OFF, "off")

    res, err = red:hget(cfg.key_name.LOAD_BALANCE, cfg.key_name.IS_BETA_OFF)
    return;
end

if not res or res == "off" then
    ngx.log(ngx.WARN, "Please note that A/B testing is : ", res);
    return;
end

local url_test = {}
res, err = red:hgetall(cfg.key_name.URL_RULES);
if res then
    url_test = red:array_to_hash(res);
end


if url_test[uri] then
	cookie_value = url_test[uri];
end

res, err = red:hgetall(cfg.key_name.LOAD_BALANCE);
if not res then
    ngx.log(ngx.ERR, "failed to get groundlink_ab_test hash: ", err);
    return;
end
local temp = red:array_to_hash(res);
if not temp or not temp.old_route_goes_to_master then
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.BETA_COUNTER, "1");
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.MASTER_COUNTER, "1");
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.KEEP_BETA_UNDER, "5");
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.BETA_ROUTE_ID, "beta");
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.MASTER_ROUTE_ID, "master");
    red:hset(cfg.key_name.LOAD_BALANCE, cfg.key_name.OLD_ROUTE_GOES_TO_MASTER, "true");
end
res, err = red:hgetall(cfg.key_name.LOAD_BALANCE);
if not res then
    ngx.log(ngx.ERR, "failed to get groundlink_ab_test hash: ", err);
    return;
end
local lb_status = red:array_to_hash(res);

if lb_status.old_route_goes_to_master ~= "true" and cookie_value ~= lb_status.beta_route_id then
    cookie_value = nil;
end

if not cookie_value then
    
    local beta_percentage =  lb_status.beta_user_count * 100 / (lb_status.master_user_count + lb_status.beta_user_count);
    local master_percentage = lb_status.master_user_count * 100 / (lb_status.master_user_count + lb_status.beta_user_count);

    if(beta_percentage >= (lb_status.keep_beta_under * 1) ) then
    	res, err = red:hincrby(cfg.key_name.LOAD_BALANCE, cfg.key_name.MASTER_COUNTER, 1);
	    if not res then
	        ngx.log(ngx.ERR, "failed to increment groundlink_ab_test master_user_count: ", err);
	        return;
	    end
    	cookie_value = lb_status.master_route_id;
    else
    	res, err = red:hincrby(cfg.key_name.LOAD_BALANCE, cfg.key_name.BETA_COUNTER, 1);
	    if not res then
	        ngx.log(ngx.ERR, "failed to increment groundlink_ab_test beta_user_count: ", err);
	        return;
	    end
    	cookie_value = lb_status.beta_route_id;
    end
    
    
end


res, err = red:hgetall(cfg.key_name.LOAD_BALANCE);
local redis_config = red:array_to_hash(res);
red:close();

setRouteCookie(cookie_value);


if cookie_value == redis_config.beta_route_id then
    ngx.var.ab_backend =  "beta";
    ngx.var.ab_hostname = cfg.BETA_HOST_NAME;
    return ngx.redirect("https://" .. cfg.BETA_HOST_NAME .. "/", 302)
else
    ngx.var.ab_backend =  "master";
    ngx.var.ab_hostname = cfg.MASTER_HOST_NAME;
end


