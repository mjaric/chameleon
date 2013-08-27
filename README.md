# Chameleon

Chameleon is set of lua scrpits used to swap upstream servers so you can do A/B(/C/D...) testing using 2+ versions of same application. It is not simple A/B content testing tool. It should be used when you are mesuring overall user experiance between two aplications or you are doing simply doing lean starup and you want to experiment with features.

## Requirements

* Compiler for environement and dev tools 
* Openresty - http://openresty.org/
* Redis somwhere hosted - http://redis.io/
* 2 or more instances of webaplication you want to host

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

Before you continue with configuration, make shure that lua script paths are correct. You can do this simply by amending your nginx.config file like below:

```
http {
    
    ...
    lua_package_path '/opt/openresety/lualib/?.lua;<PATH_TO_CHAMELEON_SCRIPTS>/?.lua;;';
    ...

}
```

This will tell luajit where too lookup for lua lua script you are requiring

So, we are finaly at point where we can setup our virtual host and enhance it with chameleon

```nginx

 # Master is your A version
upstream master {
    server a-node.yourdomain.com:80;
}

 # beta is your B version
upstream beta {
    server b-node.yourdomain.com:80;
}

init_by_lua_file <PATH_TO_CHAMELEON_SCRIPTS>/ab_proxy/bootstrap.lua;

server {
    listen       80;
    server_name  yourdomain.local;
    error_log /var/log/nginx/chameleon.log debug;
    set $environment "dev";
    set $root_path <PATH_TO_CHAMELEON_SCRIPTS>;

    # extendable api used for managing chameleon at runtim (changin its dynamic configuration)
    location /ab-cpanel/api {
        # Consider to add authorization
        default_type application/json;
        content_by_lua_file $root_path/ab_proxy/api/app.lua;
    }

    # UI for chameleon
    location /ab-cpanel {
        # Consider to add authorization
        default_type text/html;
        root $root_path;
        index index.html;
    }

    # all request are proxied here, chameleon will capture cookie and decide 
    # which upstream will be set in $hode variable
    location / {
        set $node "master";
        set $node_domain "yourdomain.local"; #change this with your default domain
        rewrite_by_lua_file $root_path/ab_proxy/process_request.lua;
        proxy_pass http://$node;
        proxy_set_header Host $node_domain;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }   
}


```

Where we can note 3 nginx directives

``` init_by_lua_file $root_path/ab_proxy/bootstrap.lua; ```

It will initialize/bootstrap internal lua modules and prepare what ever is needed to proces request (do rewrite)

Second is 

``` rewrite_by_lua_file $root_path/ab_proxy/process_request.lua; ```

which is processing request and rewrite headers. It will produce set 2 nginx variables ```$node``` and ```$node_domain`` which are used to swap upstream servers where your applications are served.

Third is

```content_by_lua_file $root_path/ab_proxy/api/app.lua;```

Which is there to serve API for UI. This api offers methods where you can change strategies for A/B trafic balancing or turn experiments off so all trafic go to default node ("master");

