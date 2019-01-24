const   aws4  = require('aws4'),
        chakram = require('chakram'),
        expect = chakram.expect,
        path = require('path'),
        fs = require("fs"),
        configFile = fs.readFileSync(path.resolve(__dirname, "../config.json")),
		jsonContent = JSON.parse(configFile),
		apiKey = jsonContent.qmetry.apiKey;
		format = jsonContent.qmetry.reportFormat,
		reportFile = jsonContent.qmetry.reportFile,
		testName = process.argv[process.argv.length - 3];
		testLink = process.argv[process.argv.length - 1];

var		reportContent = fs.readFileSync(path.resolve(__dirname, reportFile)).toString('utf-8'),
		options = { headers: { 'Content-Type': 'multipart/form-data' }, json: false },
		url;


describe("Export test results to Jira", function() {

	it("Update report to include S3 Bucket Link", function() {
		oldStr = "</testsuites>";
		newStr = "  <testsuite name=\"S3 Report Link: " + testLink + "\" tests=\"1\" failures=\"0\">" +
    			"\n    <testcase name=\"" + testLink + "\" classname=\"S3 Report Link: " + testLink + "\"/>" + 
    			"\n  </testsuite>" + 
    			"\n</testsuites>";

    	reportContent = reportContent.replace(oldStr, newStr);
	});

	it("Get upload file URL", function() {
		let params = {
				    	headers: {
				        	name: 'content-type',
				        	value: 'application/json' 
				      	}
					}

		var body = { 'apiKey': apiKey, 'format': format, 'testRunName': testName, 'testAssetHierarchy': 'TestScenario-TestCase' };

		return chakram.post("https://importresults.qmetry.com/prod/importresults-qtm4j", body, params)
			.then(function(response) {	
				expect(response.body.isSuccess).to.eql(true)
				url = response.body.url;
			});
	});

	it("Upload report file to Jira", function() {
		return chakram.put(url, reportContent, options)
			.then(function(response) {
			
				console.log(response.body)
				expect(response).to.have.status(200);
			});	
	});

});