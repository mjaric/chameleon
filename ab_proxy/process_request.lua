--ngx.header.content_type = 'text/plain';

-- while all modules are initialized in bootstap.lua module last global which is set is
-- initialized = false so we can load all configurations on first request
if not initialized then
	-- load last counters from db, and some configuration related to it.
	balance.load();
	-- reload any routes which may be stored last time server was running
	-- since routes are persisted in db while they are changed in control panel 
	-- we don't need to save them. this is only for initial request
	router.initialize();

	-- finaly set global to true so no more load requests is performed later	
	initialized = true;
end



router.handle_request();


-- save last 60 seconds increments of A and B node visit counters. If last save was before 60 seconds
-- save will be skipped (don't worry, all is kept in ngx memory)
balance.save_async();