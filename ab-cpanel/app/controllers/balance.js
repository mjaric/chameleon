(function(){
	"use strict";
	var app = angular.module("abCPanel");
	app.controller("BalanceCtrl",["$scope", "Balance", function($scope, Balance){
		// $scope.balance = { 
		// 	master_user_count: 10,
		// 	beta_user_count: 3,
		// 	is_beta_off: true,
		// 	keep_beta_under: 5,
		// 	test_version: "13.071"
		// }
		
		$scope.balance = Balance.get();

		$scope.__defineGetter__("current_balance", function(){
			if($scope.balance) {
				var b = $scope.balance;
				var traffic_count = b.master_user_count + b.beta_user_count;
				return Math.ceil(b.beta_user_count * 100 / traffic_count);
			}
			return 0;
		});

		$scope.save = function(){
			$scope.balance.$update();
		};

		$scope.reset = function() {
			$scope.balance.$delete();
		};
	}]);

})();