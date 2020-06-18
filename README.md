# BACKEND API TEST FRAMEWORK

## API Testing Framework with Chakram + Mocha (Node.js)

### Prerequsites:
    - NodeJS (8.10+)
    - npm (6.0+)

### Installation:
    npm run build

### Usage:
    npm test
        Mandatory Params: {test_tag} {environment}
        Optional Params: {no clean: no-clean} {send sonarqube report: sonar} {send reports to s3: s3}

    example: npm test all local

### Linter:
    npm run lint
    npm run lintfix

### Test Reports (will install Allure if not in /node_modules yet):
	npm run report
	
This command will read the 'test_output' folder that is generated automatically upon running tests, load a webserver and open a page (in your default browser) with the test results:

![Allure test report](https://i.imgur.com/c20APkn.png)
