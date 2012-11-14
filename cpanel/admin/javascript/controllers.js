(function(){

	var app = angular.module("abCPApp")

	app.controller("DashboardCtrl", function DashboardCtrl($scope, $log, LoadBalanceService, UrlRulesService){
		$scope.url_rule = {};
		$scope.url_rules = {};
		$scope.loadBalance = {};
		

		function loadBalanceIndex_callback (data,status, headers, config){
			$scope.loadBalance = data.response;
			$scope.loadBalance.__defineGetter__("current_balance", function(){
				with ($scope.loadBalance){
					return Math.ceil((parseInt(beta_user_count) * 100) / (parseInt(master_user_count) + parseInt(beta_user_count)));
				} 
			});
		}

		function urlRulesIndex_callback (data,status, headers, config){
			$scope.url_rules = data.response;
		}

		LoadBalanceService.index(loadBalanceIndex_callback);
		UrlRulesService.index(urlRulesIndex_callback);

		$scope.saveAutoBalance = function(){
			LoadBalanceService.save($scope.loadBalance, loadBalanceIndex_callback);			
		}
		
		$scope.onUrlDelete = function(url){
			UrlRulesService.delete(url, urlRulesIndex_callback);
		};

		$scope.onEditUrlRule = function(key, value){
			$scope.url_rule = {
				url : key,
				value: value
			};
		};

		$scope.onUrlRuleSubmit = function(){
			UrlRulesService.save($scope.url_rule.url, $scope.url_rule.value, function(){
				$scope.url_rule = {};
				urlRulesIndex_callback.apply(this,arguments);
			});
			
		};
		
	});

	// app.controller("StatusCtrl", function StatusCtrl($scope, LoadBalanceService){
		
		
	// });

	

})();

