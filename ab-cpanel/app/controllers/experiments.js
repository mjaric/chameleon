(function(){
	"use strict";
	var app = angular.module("abCPanel");
	app.controller("ExperimentsCtrl",["$scope", "$resource", function($scope,$resource){
		var Experiment = $resource("/ab-cpanel/api/experiments/:id", {} , {
			'get':    {method:'GET'},
			'save':   {method:'POST'},
			'update': {method:'PUT'},
			'query':  {method:'GET', isArray:true},
			'delete': {method:'DELETE'} 
		});

		$scope.experiments = Experiment.query();

		$scope.resetChanges = function (){
			$scope.experiments = Experiment.query();
		};

		$scope.sortingOptions = {
		    update: function(e, ui) { 
		    	console.log(e,ui); 
		    },
		    axis: 'y',
		    placeholder: "ui-state-highlight"
		};
		
	}]);

})();