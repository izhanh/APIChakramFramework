const   aws4  = require('aws4'),
        chakram = require('chakram'),
        expect = chakram.expect,
        localPath = require('path'),
        fs = require("fs"),
        configFile = fs.readFileSync(localPath.resolve(__dirname, "../config.json")),
		jsonContent = JSON.parse(configFile);

var 	host = jsonContent.host,
		protocol = jsonContent.protocol,
		mainPath = jsonContent.mainPath,
	 	awsProperties = jsonContent.awsProperties,
	 	maxResponseTime = jsonContent.maxResponseTime,
	 	baseUrl = protocol + "://" + host + "/" + mainPath,
	 	path = "users",
	 	url = baseUrl + path,
	 	opts, chakramOpts, reusabelVar;

function getAWSAuthorization(body, path) {

	awsUri = baseUrl + path;
	awsPath = mainPath + path;

    opts = { service: awsProperties.service, region: awsProperties.region, path: awsPath, host: host, uri: awsUri };
    credentialsOpts = { accessKeyId: awsProperties.AccessKey, secretAccessKey: awsProperties.SecretKey };

    opts.body = body;
    opts.headers = { "Content-Type": "application/json" };

    aws4.sign(opts, credentialsOpts);
    chakramOpts = { json: false, headers: opts.headers };
};

function getSampleBody() {
	var body = {
	    "key": "value"
	};

	return body;
}

before(function() {
	console.log("Do something before");
	this.timeout(30000);

	//before operations

	console.log("Before complete!");
});

describe("[SMOKE] Basic Monitoring Tests", function() {

	it("Example Monitoring Test", function() {
		let path = "ping";
		let url = baseUrl + path;

		body = "";
        getAWSAuthorization(body, path);

		return chakram.get(url, chakramOpts)
			.then(function(response) {
				expect(response).to.have.status(200);
				expect(response).to.have.responsetime(maxResponseTime);
			});
	});

});

describe("[REGRESSION] Username Field tests", function() {

	it("Valid Post example", function() {
		let body = getSampleBody();

		var bodyStr = JSON.stringify(body);
        getAWSAuthorization(bodyStr, path);

		return chakram.post(url, bodyStr, chakramOpts)
			.then(function(response) {
				expect(response).to.have.status(200);
				expect(response).to.have.responsetime(maxResponseTime);
				expect(response.body).to.contain(customUsername);
			});
	});

	it("Invalid Post Example", function() {
		let body = getSampleBody();

		var bodyStr = JSON.stringify(body);
        getAWSAuthorization(bodyStr, path);

		return chakram.post(url, bodyStr, chakramOpts)
			.then(function(response) {
				expect(response).to.not.have.status(200);
				expect(response.body).to.contain("Whatever error");
			});
	});
	
});