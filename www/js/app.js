// For any third party dependencies, like jQuery, place them in the lib folder.
// Configure loading modules from the lib directory,
// except for 'app' ones, which are in a sibling
// directory.
requirejs.config({
	// by default load any module IDs from www/js/lib
	baseUrl: 'www/js/lib',
	paths: {
		// except, if the module ID starts with "app", load it from the baseUrl/../app directory
		app: '../app',
		// or if module ID is "jquery", load it from the cdn 
		jquery: '//ajax.googleapis.com/ajax/libs/jquery/2.0.0/jquery.min',
		// or if module ID is "bootstrap" . . . 
		bootstrap: '//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js'
	},
	shim: {
		/* set bootstrap dependencies (just jQuery) */
		'bootstrap': ['jquery']
	}	
});

// Start loading the main app file. Put all of
// your application logic in there.
requirejs(['app/main']);
