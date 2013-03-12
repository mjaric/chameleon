(function(){
	var serviceUrl = "/admin/api",
		app = angular.module("abCPApp");

	app.factory("LoadBalanceService", ["$http", "$log", function LoadBalanceService($http, $log) {
		var self = this;

		function onError(data, status, headers, config) {
			alert("We are sorry but server returned error with status: " + status + ".");
			$log.info("Server returned Error with status: " + status + ":\n", data);
		}

		return {
        	index: function (callback,error) {
            	
	            var o = $http({
	                method:'GET',
	                url: serviceUrl + "/balance"
	            });
	            o.success(callback);
	            o.error(error || onError);
	        },

	        save: function(value, callback) {
	        	var ajax = $http.post(serviceUrl + "/balance", { 
	        		"is_beta_off": value.is_beta_off,
	        		"keep_beta_under": value.keep_beta_under,
	        		"beta_route_id": value.beta_route_id,
	        		"master_route_id": value.master_route_id,
	        		"old_route_goes_to_master": value.old_route_goes_to_master || "true"
	        	});
	        	ajax.success(callback);
	        	ajax.error(onError);
	        	
	        },

	        startOver: function(callback){
	        	var ajax = $http.post(serviceUrl + "/balance", { 
	        		"master_user_count": 1,
	        		"beta_user_count": 1
	        	});
	        	ajax.success(callback);
	        	ajax.error(onError);
	        }
    	};

	}]);

	app.factory("UrlRulesService", ["$http", "$log", function UrlRulesService($http, $log) {
		function onError(data, status, headers, config) {
			alert("We are sorry but server returned error with status: " + status + ".");
			$log.info("Server returned Error with status: " + status + ":\n", data);
		}

		return {
			index: function(callback, error){
				var o = $http({
	        		method: 'GET',
	        		url: serviceUrl + "/url_rules"
	        	});
	        	o.success(callback);
	        	o.error(error || onError);
			},

			save: function(url, value, callback){
				var o = $http({
	        		method: 'POST',
	        		url: serviceUrl + "/url_rules",
	        		data: { url: url, value: value }
	        	});
	        	o.success(callback);
	        	o.error(onError);
			},

			delete: function(url, callback){
				var o = $http.delete(serviceUrl + "/url_rules?url="+ url);
				var self = this;
	        	o.success(callback);

	        	o.error(onError);
			}
		};
	}]);

})();