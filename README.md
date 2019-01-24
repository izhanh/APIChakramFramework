# API Testing Framework with Chakram + Mocha (Node.js)

This is NodeJS project for API auto tests using Mocha as test runner and Chrakram as an API testing library. Requirements:

* Latest version of NodeJS
* Run:

```
    npm install
```

## How to run tests

First you need to update config.json configuration:

* {Host} - your test environment host (Example: api.dev123.ohpen.com)

Then to start test execute run.sh or run:

```
    ./run.sh [TESTNAME]* [TESTGROUP]**
```

( * ) Test name is mandatory
( ** ) Test group tag is optional

For running every single test in all test files run:

```
    ./run.sh all
```