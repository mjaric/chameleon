local redis = require "resty.redis";

function protect_table (tbl)
  return setmetatable ({}, 
    {
    __index = tbl, 
    __newindex = function (t, n, v)
       error ("attempting to change constant " .. 
             tostring (n) .. " to " .. tostring (v), 2)
      end
    })

end 

local cfg = {

    key_name = {
        LOAD_BALANCE = "groundlink_ab_test",
        IS_BETA_OFF = "is_beta_off",
        URL_RULES = "ab_url_tests",
        MASTER_COUNTER = "master_user_count",
        BETA_COUNTER = "beta_user_count"
    }


};
if ngx.var.staging == "production" then
    cfg["REDIS_HOST_NAME"] = "10.56.85.22";
    cfg["BETA_HOST_NAME"] = "preview.groundlink.com";
    cfg["MASTER_HOST_NAME"] = "www.groundlink.com";
else
    cfg["REDIS_HOST_NAME"] = "stream1.qa.towncar.us";
    cfg["BETA_HOST_NAME"] = "www2.qa.groundlink.us";
    cfg["MASTER_HOST_NAME"] = "www.qa.groundlink.us";
end

cfg = protect_table(cfg)



ngx.var.ab_backend = "master";
ngx.var.ab_hostname = cfg.MASTER_HOST_NAME;




local cookie_value = nil;
if ngx.var.cookie_ROUTEID then
	cookie_value = ngx.var.cookie_ROUTEID;
end
ngx.log(ngx.INFO, "ROUTEID = ", cookie_value);

function setRouteCookie(backend)
	local expires = os.date("%A, %d-%b-%Y %X GTM", os.time{year=2013, month=1, day=10, hour=0});
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


res, err = red:hget(cfg.key_name.LOAD_BALANCE, cfg.key_name.IS_BETA_OFF)
if not res then
    ngx.log(ngx.ERR, "failed to get ab_url_tests hash: ", err);
    return;
end

if res == "off" then
    ngx.log(ngx.WARN, "Please note that A/B testing is : ", res);
    return;
end


res, err = red:hgetall(cfg.key_name.URL_RULES);
if not res then
    ngx.log(ngx.ERR, "failed to get ab_url_tests hash: ", err);
    return;
end
local url_test = red:array_to_hash(res);

if url_test[uri] then
	cookie_value = url_test[uri];
end

if not cookie_value then
    res, err = red:hgetall(cfg.key_name.LOAD_BALANCE);
    if not res then
        ngx.log(ngx.ERR, "failed to get groundlink_ab_test hash: ", err);
        return;
    end
    local lb_status = red:array_to_hash(res);
    local beta_percentage =  lb_status.beta_user_count * 100 / (lb_status.master_user_count + lb_status.beta_user_count);
    local master_percentage = lb_status.master_user_count * 100 / (lb_status.master_user_count + lb_status.beta_user_count);

    if(beta_percentage >= (lb_status.keep_beta_under * 1) ) then
    	res, err = red:hincrby(cfg.key_name.LOAD_BALANCE, cfg.key_name.MASTER_COUNTER, 1);
	    if not res then
	        ngx.log(ngx.ERR, "failed to increment groundlink_ab_test master_user_count: ", err);
	        return;
	    end
    	cookie_value = "master";
    else
    	res, err = red:hincrby(cfg.key_name.LOAD_BALANCE, cfg.key_name.BETA_COUNTER, 1);
	    if not res then
	        ngx.log(ngx.ERR, "failed to increment groundlink_ab_test beta_user_count: ", err);
	        return;
	    end
    	cookie_value = "beta";
    end
    
    
end

setRouteCookie(cookie_value);


red:close();

ngx.var.ab_backend =  cookie_value ;
if cookie_value == "beta" then
    ngx.var.ab_hostname = cfg.BETA_HOST_NAME;
    return ngx.redirect("https://" .. cfg.BETA_HOST_NAME .. "/", 302)
else
    ngx.var.ab_hostname = cfg.MASTER_HOST_NAME;
end


