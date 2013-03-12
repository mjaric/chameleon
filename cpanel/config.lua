local cfg = {

    key_name = {
        LOAD_BALANCE = "groundlink_ab_test",
        IS_BETA_OFF = "is_beta_off",
        URL_RULES = "ab_url_tests",
        MASTER_COUNTER = "master_user_count",
        BETA_COUNTER = "beta_user_count",
        KEEP_BETA_UNDER = "keep_beta_under",
        BETA_ROUTE_ID = "beta_route_id",
        MASTER_ROUTE_ID = "master_route_id",
        OLD_ROUTE_GOES_TO_MASTER = "old_route_goes_to_master"
    },

    


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

return cfg;