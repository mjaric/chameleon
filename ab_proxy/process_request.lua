--ngx.header.content_type = 'text/plain';
initialize();

balance.load_shered_dictionary();
ab_proxy.handle_url(ngx.var.uri);
-- save last 60 seconds increments of A and B node visit counters. If last save was before 60 seconds
-- save will be skipped (don't worry, all is kept in ngx memory)
balance.save_async();