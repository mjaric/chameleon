(function(){
	"use strict";
	var app = angular.module("abCPanel");

	app.factory("Balance", ["$resource", function($resource){

		return $resource("/ab-cpanel/api/balance", {}, {
			'get':    {method:'GET'},
			'save':   {method:'POST'},
			'update': {method:'PUT'},
			'query':  {method:'GET', isArray:false},
			'delete': {method:'DELETE'} 
		});
	}]);

})();
		