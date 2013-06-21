local ngx = ngx;

module("ab_proxy.config");

local dev = {
	redis_ip = "127.0.0.1",
	redis_port = "6379",
	redis_db = "0",
	master_domain = "www.qa.groundlink.us",
  	beta_domain = "www2.qa.groundlink.us"
};

local qa = {
	redis_ip = "10.54.184.167",
	redis_port = "6379",
	redis_db = "2",
	master_domain = "www.qa.groundlink.us",
  	beta_domain = "www2.qa.groundlink.us"
};


local prod = {
	redis_ip = "stream1.sl.towncar.us",
	redis_port = "6379",
	redis_db = "2",
	master_domain = "www.groundlink.com",
  	beta_domain = "preview.groundlink.com"
};

local cfg = {
	dev = dev,
	qa = qa,
	prod = prod
}

function get()
	return cfg[ngx.var.environment];
end