function parseUri(str) {
    var o = parseUri.options,
            m = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
            uri = {},
            i = 14;

    while (i--) uri[o.key[i]] = m[i] || "";

    uri[o.q.name] = {};
    uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
        if ($1) uri[o.q.name][$1] = $2;
    });

    return uri;
};

parseUri.options = {
    strictMode:false,
    key:["source", "protocol", "authority", "userInfo", "user", "password", "host", "port", "relative", "path", "directory", "file", "query", "anchor"],
    q:{
        name:"queryKey",
        parser:/(?:^|&)([^&=]*)=?([^&]*)/g
    },
    parser:{
        strict:/^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
        loose:/^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
    }
};
(function(){
	var abCPApp = angular.module('abCPApp', []);

	abCPApp.config(['$httpProvider', function httpConfiguration($httpProvider, $location) {
	    $httpProvider.defaults.headers.post['Content-Type'] = 'application/json'
	    $httpProvider.defaults.headers.put['Content-Type'] = 'application/json'

	    // assumes the presence of jQuery
	    // var token = $("meta[name='csrf-token']").attr("content");
	    // $httpProvider.defaults.headers.post['X-CSRF-Token'] = token;
	    // $httpProvider.defaults.headers.put['X-CSRF-Token'] = token;
	    // $httpProvider.defaults.headers['delete'] = {};
	    // $httpProvider.defaults.headers['delete']['X-CSRF-Token'] = token;

	    
	}]);

	abCPApp.run(['$rootScope', '$http', "$location", function (scope, $http, $location) {

	    

	}]);	
})();
