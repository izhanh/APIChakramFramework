/ ================================================================================================================================================ //
// IMPORTS
// ================================================================================================================================================ //

const   fs = require("fs"),
	chakram = require('chakram'),
        expect = chakram.expect,
        localPath = require('path'),
        configFile = fs.readFileSync(localPath.resolve(__dirname, "../package.json")),
	jsonContent = JSON.parse(configFile).test_config;

var 	host = jsonContent.host,
        opts, chakramOpts, reusabelVar,
	protocol = jsonContent.protocol,
	mainPath = jsonContent.main_path,
	maxResponseTime = jsonContent.max_response_time,
	baseUrl = protocol + "://" + host + "/" + mainPath;

// ================================================================================================================================================ //
// TEST DATA
// ================================================================================================================================================ //

const   url = "http://httpbin.org/get";

// ================================================================================================================================================ //
// BEFORE & AFTER
// ================================================================================================================================================ //

before(function() {
	console.log("Do something before");
	this.timeout(30000);
	// before operations
	console.log("Before complete!");
});

after(function() {
	console.log("Do something after");
	// after operations
	console.log("After complete! Exiting...");
});

// ================================================================================================================================================ //
// TESTS
// ================================================================================================================================================ //

describe("[EXAMPLE_TESTS][EXAMPLE_PASS] Basic example test that always passes", function() {
	it("Example Pass Test", function() {
		return chakram.get(url, chakramOpts)
			.then(function(response) {
				expect(response).to.have.status(200);
				expect(response).to.have.responsetime(maxResponseTime);
			});
	});
});

describe("[EXAMPLE_TESTS][EXAMPLE_FAIL] Basic example test that always fails", function() {
	it("Example Pass Test", function() {
		return chakram.get(url, chakramOpts)
			.then(function(response) {
				expect(response).to.have.status(404);
				expect(response).to.have.responsetime(maxResponseTime);
			});
	});
});

// ================================================================================================================================================ //
// END OF FILE
// ================================================================================================================================================ //
