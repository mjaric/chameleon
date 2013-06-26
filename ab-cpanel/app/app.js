(function(){
	"use strict";
	var app = angular.module("abCPanel",["ngResource", "ui.sortable"]);

	app.config(function($routeProvider) {
			$routeProvider.when("/",{
				templateUrl: "/ab-cpanel/app/views/balance.html",
				controller: "BalanceCtrl"
			})
			.when("/experiments",{
				templateUrl: "/ab-cpanel/app/views/experiments.html",
				controller: "ExperimentsCtrl"
			})
			.otherwise({
				redirectTo: "/"
			});
		});

	app.controller("ApplicationCtrl",["$scope", "$location", function($scope, $location){

		$scope.isLocation = function(url){
			if(url == $location.path()){
				return true;
			}
			return false;
		}
	}]);

})();
