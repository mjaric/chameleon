(function(){
	"use strict";
	
	var app = angular.module("abCPanel");

	app.controller("ExperimentsCtrl",["$scope", "$resource", function($scope,$resource){
		var Experiment = $resource("/ab-cpanel/api/experiments/:handles_path", 
			{ },{
				'query':  	{method:'GET', isArray: true },
				'save':   	{method:'POST', url: "/ab-cpanel/api/experiments/new" },
				'update': 	{method:'PUT', params: {"handles_path": "@handles_path"} },
				'bulk_save':{method:'POST', isArray: true},
				'delete': 	{method:'DELETE', params: {"handles_path": "@handles_path"} } 
			}
		);
		// Scope attributes
		$scope.new_form_visible = false;
		$scope.new_experiment = { strategy_type: "balance" };
		$scope.experiments = Experiment.query();
		$scope.strategy_types = {
			"balance": "Balance nodes",
			"force_a": "Force A node",
			"force_b": "Froce B node"
		};
		$scope.sortingOptions = {
		    update: function(e, ui) { 
		    	console.log(e,ui); 
		    },
		    /* axis: 'y', */
		    placeholder: "ui-state-highlight"
		};
		// event handlers
		$scope.resetChanges = function (){
			$scope.experiments = Experiment.query();
		};
		// Bulk save for all in managed list which is loaded in scope
		$scope.saveAll = function(){
			$scope.experiments = Experiment.bulk_save($scope.experiments);
		};

		$scope.addNew = function(){
			var experiment = new Experiment($scope.new_experiment);
			$scope.experiments.unshift(experiment);
			$scope.experiments = Experiment.bulk_save($scope.experiments, function(){
				$scope.new_experiment = new Experiment({strategy_type: "balance"});
			});

		};

		$scope.remove = function(exp){
			exp.$delete({handles_path: encodeURIComponent(exp.handles_path)}, function(){
				$scope.experiments = Experiment.query();
			});
			
		};
		
	}]);

	app.controller("ExperimentsTestCtrl",["$scope", "$resource", function($scope,$resource){
		$scope.test_url = "";
		$scope.test=function(url){
			// ToDo: Make Test service call to validate all matches
		}
		
	}]);

})();