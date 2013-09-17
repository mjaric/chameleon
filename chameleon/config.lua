local ngx = ngx;

module(...);

local dev = {
	redis_ip = "127.0.0.1",
	redis_port = "6379",
	redis_db = "0",
	master_domain = "a-node.chameleon.local",
	beta_domain = "b-node.chameleon.local"
};

-- local prod = {
-- 	redis_ip = "127.0.0.1",
-- 	redis_port = "6379",
-- 	redis_db = "2",
-- 	master_domain = "a-node.yourdomain.com",
--   	beta_domain = "b-node.yourdomain.com"
-- };

-- add any configuration profile here if you need it
-- but dont forget to update nginx setver section and set var $environment = "your_profile";
local cfg = {
	-- production = prod,
	dev = dev
}

function get()
	return cfg[ngx.var.environment];
end