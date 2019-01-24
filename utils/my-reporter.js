// my-reporter.js
var mocha = require('mocha');
var fs = require('fs');
builder = require('xmlbuilder');
let testsuite, testcase,
xml = builder.create('testsuites', { encoding: 'utf-8' });

module.exports = MyReporter;

function MyReporter(runner) {
	mocha.reporters.Base.call(this, runner);
	var passes = 0;
	var failures = 0;
	var tests = 0;
	var currentTestSuite;

	runner.on('suite', function(test){
		if(test.title !== ''){
			currentTestSuite=test.title;
			testsuite = xml.ele('testsuite', {'name': currentTestSuite});
		}
	});

	runner.on('test', function(test){
		tests++;
		testcase = testsuite.ele('testcase', {'name': test.title, 'classname': currentTestSuite});
	});

	runner.on('pass', function(test){
		passes++;
	});

	runner.on('fail', function(test, err){
        failures++;
        error_message = err.message;
        url = err.actual.url;
        auto_test_code = test.body;
        if(typeof test.err.actual.response !== 'undefined') {
	        method = test.err.actual.response.request.method;
	        protocol = test.err.actual.response.request.uri.protocol;
	        port = test.err.actual.response.request.uri.port;
	        pathname = test.err.actual.response.request.uri.pathname;
	        query = test.err.actual.response.request.uri.query;
	        body = test.err.actual.response.request.body;
        } else {
            method="";
            protocol="";
            port="";
            pathname="";
            query="";
            body="";
        }
        //headers in test.err.actual.response.request.headers
        message = "\n Error message is: \n" + error_message + "\n\n"
        message += "Method: " + method +"\n"
        message += "Protocol: " + protocol +"\n"
        message += "Url: "+ url + "\n";
        message += "Port: " +port +"\n";
        message += "Path: " +pathname +"\n";
        message += "Query: " +query +"\n";
        message += "Body: " +body +"\n";
        message += "\n";
        message += "Code: \n" + auto_test_code.replace(/(\r\n)/gm,"\n");
        testcase = testcase.ele('failure', {'message': error_message}, message);
    });

	runner.on('suite end', function(test){
		if(test.title !== ''){
			testsuite.att('tests', tests);
			testsuite.att('failures', failures);
		}
		failures = 0;
		tests = 0;
		passes = 0;
	});

	runner.on('end', function(){
		fs.writeFile("./testOutput/ohp.report.xml", xml.end({ pretty: true}), function(err) {
			if(err) return console.log(err);	
		});
	});

}