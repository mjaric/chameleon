--ngx.header.content_type = 'text/plain';
-- reload any routes which may be stored last time server was running
-- since routes are persisted in db while they are changed in control panel 
-- we don't need to save them. this is only for initial request
balance.load();
ab_proxy.initialize();
ab_proxy.handle_url(ngx.var.uri);
