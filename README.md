# Chameleon

ab-proxy is set of lua scrpits used to swap upstream servers so you can do A/B testing using 2 versions of same application. It is not simple A/B page testing tool. It should be used when you are mesuring overall user experiance between two aplications.

## Requirements

* Compiler for environement and dev tools 
* Openresty - http://openresty.org/
* Redis somwhere hosted - http://redis.io/
* 2 instances of webaplication you want to host

## Instalation

Please replace (VERSION) with one you downloaded from operesty website

```bash
$ tar xzvf ngx_openresty-(VERSION).tar.gz
$ cd ngx_openresty-(VERSION)/
$ ./configure --prefix=/opt/openresety --with-luajit -j2 --with-http_postgres_module --with-http_iconv_module --with-http_geoip_module --with-google_perftools_module
$ make
$ make install
```

If you are using MAC OS X you probably need to install pcre so using home broew before line above execute

```bash
$ brew install pcre
```

and then execute configure script

```bash
$ tar xzvf ngx_openresty-(VERSION).tar.gz
$ cd ngx_openresty-(VERSION)/
$ ./configure --prefix=/opt/openresety --with-luajit -j2 --with-http_postgres_module --with-http_iconv_module --with-http_geoip_module --with-google_perftools_module --with-cc-opt="-I/usr/local/Cellar/pcre/8.33/include" --with-ld-opt="-L/usr/local/Cellar/pcre/8.33/lib"
$ make
$ make install

```

The ```make install``` will copy binary to ```/opt/openresety``` optionaly you can change ```--prefix=...``` flag to any location you want.

## Simple Configuration

Simple configuration for nginx is like below

```nginx

upstream master {
    server www.qa.groundlink.us:80;
}
upstream ssl_master {
    server www.qa.groundlink.us:443;
}

upstream beta {
    server www2.qa.groundlink.us:80;
}
upstream ssl_beta {
    server www2.qa.groundlink.us:443;
}

init_by_lua_file /Users/miskovac/Projects/glink/ab_proxy/ab_proxy/bootstrap.lua;

server {
    listen       80;
    server_name  dev.qa.groundlink.us;
    error_log /var/log/nginx/ab_proxy.log debug;
    
    set $environment "dev";
    set $root_path /Users/miskovac/Projects/glink/ab_proxy;
    location / {
        set $node "master";
        set $node_domain "www.qa.groundlink.us";
        rewrite_by_lua_file $root_path/ab_proxy/process_request.lua;
        proxy_pass http://$node;
        proxy_set_header Host $node_domain;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }   
}

server {
    listen       	443 ssl;
    server_name 	dev.qa.groundlink.us; 
    error_log /var/log/nginx/ab_proxy.log debug;
    ssl_certificate      /Users/miskovac/config/groundlink-ssl/qa.groundlink.us.crt;
    ssl_certificate_key  /Users/miskovac/config/groundlink-ssl/nginx.qa.groundlink.us.key;
    set $environment "dev";
    set $root_path /Users/miskovac/Projects/glink/ab_proxy;
    location /ab-cpanel/api {
        # autoindex on;  
        # satisfy any;
        # # deny all;
        # allow 127.0.0.1/32;
        # auth_basic "GroundLink AB CPanel Login";
        # #auth_basic_user_file /var/www/vhost/groundlink.com/authfile;
        default_type application/json;
        content_by_lua_file $root_path/ab_proxy/api/app.lua;
    }
    location /ab-cpanel {
        # autoindex on;  
        # satisfy any;
        # # deny all;
        # allow 127.0.0.1/32;
        # auth_basic "GroundLink AB CPanel Login";
        # #auth_basic_user_file /var/www/vhost/groundlink.com/authfile;
        default_type text/html;
        root $root_path;
        index index.html;
    }
    location / {
        set $node "master";
        set $node_domain "www.qa.groundlink.us";
    	rewrite_by_lua_file $root_path/ab_proxy/process_request.lua;
        proxy_set_header Host $node_domain;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_pass https://ssl_$node;
        proxy_redirect  off;
    }
}
```

Where we can note 3 nginx directives

``` init_by_lua_file /Users/miskovac/Projects/glink/ab_proxy/ab_proxy/bootstrap.lua; ```

It will initialize/bootstrap internal lua modules and prepare what ever is needed to proces request (do rewrite)

Second is 

``` rewrite_by_lua_file $root_path/ab_proxy/process_request.lua; ```

which is processing request and rewrite headers. It will produce set 2 nginx variables ```$node``` and ```$node_domain`` which are used to swap upstream servers where your applications are served.

Third is

```content_by_lua_file $root_path/ab_proxy/api/app.lua;```

Which is there to serve API for UI. This api offers methods where you can change strategies for A/B trafic balancing or turn experiments off so all trafic go to default node ("master");

