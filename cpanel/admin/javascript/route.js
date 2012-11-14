(function(){
	var abCPApp = angular.module("abCPApp");

	abCPApp.config(['$routeProvider', "$locationProvider", function routes($routeProvider, $locationProvider) {

	    $routeProvider.when('/admin/', {
	        controller:'DashboardCtrl',
	        templateUrl:'/admin/views/dashboard.html'
	    });

	    $routeProvider.when('/admin/stauts', {
	        controller:'StatusCtrl',
	        templateUrl:'/admin/views/status.html'
	    });

	    // $routeProvider.when('/movies/:movie_id', {
	    //     templateUrl:'<%= asset_path("movies/show.html") %>',
	    //     controller:'MovieDetailCtrl'
	    // });

	    // $routeProvider.when('/movies/:movie_id/similar', {
	    //     templateUrl:'<%= asset_path("movies/similar.html") %>',
	    //     controller:'MovieSimilarCtrl'
	    // });

	    // $routeProvider.when('/login', {
	    //     templateUrl:'<%= asset_path("login.html") %>',
	    //     controller: 'LoginCtrl'
	    // });

	    $routeProvider.otherwise({redirectTo:"/admin/"});

	    //$locationProvider.html5Mode(true);

	}]);

})();