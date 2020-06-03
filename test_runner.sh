#!/bin/bash

# ================================================================================================================================================ #
# AUXILIAR FUNCTIONS
# ================================================================================================================================================ #

# Get the OS value
sysName=$(uname -a | tr '[:upper:]' '[:lower:]')

# Print titles
function printTitle() {
	echo $'\n'"=============================================================================================="
	echo "$1"$'\n'"=============================================================================================="
}

# Send the report to SonarQube
function sendSonarReport() {
	${SONAR_COMMAND} \
		-Dsonar.host.url=${SONAR_HOST_URL} \
		-Dsonar.login=${SONAR_TOKEN} \
		-Dsonar.projectKey=${SONAR_PROJECT} \
		-Dsonar.testExecutionReportPaths=${REPORT} \
		-Dsonar.tests=${TESTS_FOLDER} \
		#-Dsonar.projectVersion=$(git_build)
}

# ================================================================================================================================================ #
# MAIN FUNCTION
# ================================================================================================================================================ #

# Constants
REPORT="./xunit.xml"
TESTS_FOLDER="./tests"
CONFIG_FILE="./package.json"
SONAR_FOLDER="./.scannerwork"
OUTPUT_FOLDER="./test_output"
CONFIG_DATA=$(cat "./package.json")
REPORTER_TYPE="mocha-multi-reporters"
ALLURE_REPORT_FOLDER="./allure-results"
MOCHA_REPORT_FOLDER="./mochawesome-report"
SONAR_REPORT="${OUTPUT_FOLDER}/sonar-report.xml"
SONAR_COMMAND="./node_modules/.bin/sonar-scanner"

# Parse Test config
TIMEOUT=$(node -pe "JSON.parse(process.argv[1]).sonar_config.max_timeout" "${CONFIG_DATA}")
SONAR_TOKEN=$(node -pe "JSON.parse(process.argv[1]).sonar_config.sonar_token" "${CONFIG_DATA}")
SONAR_HOST_URL=$(node -pe "JSON.parse(process.argv[1]).sonar_config.sonar_url" "${CONFIG_DATA}")
SONAR_PROJECT=$(node -pe "JSON.parse(process.argv[1]).sonar_config.sonar_project" "${CONFIG_DATA}")

# Check the paremeters
if [[ $# -lt 2 ]]; then
	instructions="Wrong amount of paramenters:"$'\n'"    Mandatory: test_run.sh {test_tag} {environment}"$'\n'
	instructions="$instructions    Optional: {no-clean} {sonar-report}"
	printTitle "$instructions"
	echo ""
	exit -1
fi

# If the first arg == 'report' then we serve the Allure server (installing dependencies if necessary)
if [[ $1 == *"report"* ]]; then
	printTitle "Running the Allure Test Report tool"
	# Install 'allure-commandline' if not present
	if [[ ! -d "./node_modules/allure-commandline" ]]; then
		echo "Installing Allure test reporting tool"
		npm install allure-commandline --save-dev
	fi
	npx allure serve ${OUTPUT_FOLDER}

# If the first arg == 'clean' then the 'output' folder is cleaned before testing
elif [[ $1 == *"clean"* ]]; then
	printTitle "Cleaning [${OUTPUT_FOLDER}] folder before testing"
	echo ""
	rm -rf ${SONAR_FOLDER}
	rm -rf ${OUTPUT_FOLDER}

# If the first arg == 'sonar' then we upload the test report into SonarQube server
elif [[ $1 == *"sonar"* ]]; then
	message="Sending the Sonar Report to the server."$'\n'
	message="$message    Sonar URL: [$SONAR_HOST_URL]"$'\n'
	message="$message    Sonar Project: [$SONAR_PROJECT]"
	printTitle "$message"
	echo ""
	sendSonarReport
	rm -rf ${SONAR_FOLDER}

# Else run the tests
else
	# EXECUTE THE TESTS. If tes_tag == 'all', all tests are executed except the "EXAMPLE" ones
	printTitle "BACKEND API TEST RUNNER"
	
	# Install the Node dependencies if the /node_modules folder is not present
	if [[ ! -d "./node_modules" ]]; then
		printTitle "Installing the npm dependencies"
		npm run build
	fi

	# Clean the output folder first if no 'no-clean' param is in the optional arguments
	if [[ ! " $@ " =~ " no-clean " ]]; then npm run clean; fi

	# Run the tests. If testag == 'all', all tests are executed except the "EXAMPLE" ones
	tty=$(tty)

	# Loop over all the '.spec.js' files in the 'specs' folder
	for filename in ./tests/*.spec.js; do
		# If the test_tag is 'all', execute all the tests except the 'EXAMPLE' ones
    	if [[ $1 == *"all"* ]]; then testParam="$filename"; else testParam="$filename -f $1"; fi

		# If the test_tag is 'all', skip the 'exampleTest' files
    	if [[ $1 == *"all"* ]] && [[ $filename == *"exampleTest"* ]]; then continue; fi

		# Only execute the tests if the file contains the test_tag (if not 'all')
		if [[ $1 == *"all"* ]] || grep -q $1 "$filename"; then
			resultOutput=$(./node_modules/.bin/mocha $testParam --timeout ${TIMEOUT}  --reporter ${REPORTER_TYPE} --reporter-options configFile=${CONFIG_FILE} 2>&1 | tee $tty)
		fi

		# If we are running in a not TTY environment, just print the output in the default console
		if [[ $tty == *"not a tty"* ]]; then echo "$resultOutput"; fi
	done

	# If the parameters include 'sonar-report', send the Sonar Report to the SonarQube Server
    if [[ " $@ " =~ " sonar-report " ]]; then npm run sonar; fi

	# Modify the Output folders
	if [[ ! -d "${OUTPUT_FOLDER}" ]]; then mkdir ${OUTPUT_FOLDER}; fi
	if [[ -d "${MOCHA_REPORT_FOLDER}" ]]; then cp -r ${MOCHA_REPORT_FOLDER}/* ${OUTPUT_FOLDER}/; rm -rf ${MOCHA_REPORT_FOLDER}; fi
	if [[ -d "${ALLURE_REPORT_FOLDER}" ]]; then cp -r ${ALLURE_REPORT_FOLDER}/* ${OUTPUT_FOLDER}/; rm -rf ${ALLURE_REPORT_FOLDER}; fi
	if [[ -f "${REPORT}" ]]; then mv ${REPORT} ${SONAR_REPORT}; sed -i 's!="tests/!="../tests/!g' ${SONAR_REPORT}; sed -i 's!="tests\\!="..\\tests\\!g' ${SONAR_REPORT}; fi

	# Determine the exit code. If the latest part of the script contains 'FAIL', return a negative exit code
	if [[ $resultOutput == *" failing"* ]]; then
		printTitle "The testrun contains FAILED Scenarios, returning fail code [-1]"; exit -1;
	else
		printTitle "The testrun only contains PASS Scenarios, returning success code [0]"; exit 0;
	fi
fi

# ================================================================================================================================================ #
# END OF SCRIPT
# ================================================================================================================================================ #
