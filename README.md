# Chameleon

Chameleon is set of lua scrpits used to swap upstream servers so you can do A/B(/C/D...) testing using 2+ different versions of same application. It is not simple A/B content testing tool. It should be used when you are mesuring overall user experiance between two aplications or you are doing simple lean starup and you want to experiment with features.

## Requirements

-   Compiler for environement and dev tools (check openresty website for detailss)

-   Openresty - <http://openresty.org>

-   Redis somwhere hosted - <http://redis.io/>

-   2 instances of webaplication you want develop and host (ip addresses or hosnames are required)

## Instalation

Please replace **(VERSION)** with one you downloaded from operesty website

    $ tar xzvf ngx_openresty-(VERSION).tar.gz
    $ cd ngx_openresty-(VERSION)/
    $ ./configure --prefix=/opt/openresety --with-luajit -j2 --with-http_postgres_module --with-http_iconv_module --with-http_geoip_module --with-google_perftools_module
    $ make
    $ make install

If you are using MAC OS X you probably need to install pcre so use brew before line above

    $ brew install pcre

and then execute configure script

    $ tar xzvf ngx_openresty-(VERSION).tar.gz $ cd ngx_openresty-(VERSION)/ 
    $ ./configure --prefix=/opt/openresety --with-luajit -j2 --with-http_postgres_module --with-http_iconv_module --with-http_geoip_module --with-google_perftools_module --with-cc-opt="-I/usr/local/Cellar/pcre/8.33/include" --with-ld-opt="/usr/local/Cellar/pcre/8.33/lib" 
    $ make 
    $ make install

The **make install** will copy binary to **/opt/openresety**, optionaly you can change **--prefix=...** flag to specify any installation location of your choice. Also note tahat we are using luajit which is faster way to execute your lua scripts.

## Minimal NGINX Configuration

Before you continue seting up our experiments, make sure that lua knows where to lookup for your scripts. You can do this simply by amending your nginx.config file like below

    http {  
        ... 
        lua_package_path '/opt/openresety/lualib/?.lua;<PATH_TO_CHAMELEON_SCRIPTS>/?.lua;;'; 
        ... 
    }

This will tell luajit where to lookup for lua scripts. Checkout chameleon code from git and replace above \\ with correct path (for this exercise that is root path of chameleon repository but you can play with if you want)

Next, we need to setup nginx upstreams and location "/" of our virtual host. To be clear what we are doing here checkout network diagram below.

![][]

It looks like NGINX balancer diagram and basicaly we do use this feature with expetion that we gona use chameleon to dynamicaly swap app-01 and app-02 hosts for us and in way how we want it.

Above shouldn't be hard to achieve just with NGINX upstream configuration. So lets add this to our configuration, so far it should look like this

    upstream A-NODE {
        server app-01.local:8080;
    }
    upstream B-NODE {
        server app-02.local:8081;
    }
    lua_code_cache off;
    lua_shared_dict experiments 10m;
    server {
        listen       80;
        # replace this line with your domain
        server_name  yourdomain.local;
        error_log /var/log/nginx/chameleon.log info;
        location / {
            default_type "text/html";
            proxy_redirect off;
            set $node "A-NODE";
            
            proxy_pass http://$node;
            proxy_set_header        Host            $host;
            # Below is some proxy configuration which is recommended but not required
            proxy_set_header        X-Real-IP       $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            client_max_body_size    10m;
            client_body_buffer_size 128k;
            proxy_connect_timeout   90;
            proxy_send_timeout      90;
            proxy_read_timeout      90;
            proxy_buffers           32 4k;
        }
    }

With this we are setup for experimenting, next chapter will show you options which chameleon can offer. Each has its own use case.

## Getting Familiar With Chameleon Strategies

Before we explian what strategies are comming with Chameleon, you should know that Chameleon uses *ROUTE* cooke to keep track what version of application visitor should see. If this cookie is set, Chameleon will respect it. Of course if we increment test version (we will see this later) Chameleon will know how to ignore old cookies and start over with A/B testing. 

Also Chameleon contains `Balance` counter module (chameleon/blanace.lua) which is built to keep track of A or B version entrances by new visitors and it calculates what is current balance between those two versions. On NGINX stratup we need to set what is desired percentage of entrances under which we want to keep B version entrance percentage. This module is required to be initialized as soon as possible and before we use any strategy.

**Strategies** are lua modules which are built to setup entry points and/or "switches" to one of website versions. By closely analyzed possible use cases in terms of A/B testing we built few strategies which should be enough for head start if not completely cover all scenarios you need in this journey.

Each website has home page, landing pages, pages linked in email or text messages and so on. Chameleon should see those pages as entry points to your A/B test. If HTTP request URL match to strategy entry point, Chameleon will execute strategy so it determine which version should be presented to visitor by respecting either set A:B balance or forcing one of versions to appear. Chameleon has 3 strategies which you can combine:

-   `BalanceStrategy` (chameleon/strategies/balance\_strategy.lua) which will allways respect balance of how many version entrances was till moment of next new visit of A or B version. If `BALANCE =  (B_ENTRENCE_COUNT / (A_ENTRENCE_COUNT + B_ENTRENCE_COUNT) ) * 100` is greather than percentage set in Balance module (chameleon/balance) instance

-   `ANodeStrategy` (chameleon/strategies/anode\_strategy.lua) which will allways force A version when accessed link match criteria set in this strategy

-   `BNodeStrategy` (chameleon/strategies/bnode\_strategy.lua) which is created for same purpose as ANodeStragey but it will always preset ROUTE cookie to B version and visitor will continue with new user experiance with each new request

Alongside with entry point strategies Chameleon contains also so called `DefaultStrategy` which has only one simple task and that is to ensure that wisitor always see version of your application which is set in browser cookie.

  []: http://s6.postimg.org/v5hs2g029/Chameleon_Network_Diagram.png
