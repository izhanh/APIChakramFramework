#!/bin/bash

# ================================================================================================================================================ #
# BACKEND API TEST RUNNER
#      Date: 27/05/2020
#      Author: Izhan Hernández
#      Description: Runner Script for Backend API Tests
# ================================================================================================================================================ #

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

# ================================================================================================================================================ #
# MAIN FUNCTION
# ================================================================================================================================================ #

# Check the paremeters
if [[ $# -lt 2 ]]; then
	instructions="Wrong amount of paramenters:"$'\n'"    Mandatory: test_run.sh {test_tag} {environment}"$'\n'
	instructions="$instructions    Optional: {-no-clean}"
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
	npx allure serve test_output

# If the first arg == 'clean' then the 'output' folder is cleaned before testing
elif [[ $1 == *"clean"* ]]; then
	printTitle "Cleaning [./output] folder before testing"
	echo ""
	rm -rf ./test_output/*

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

	# Run the tests. If @testag == 'all', all tests are executed except the "EXAMPLE" ones
	tty=$(tty)

	# Loop over all the '.spec.js' files in the 'specs' folder
	for filename in ./tests/*.spec.js; do
		# If the test_tag is 'all', execute all the tests except the 'EXAMPLE' ones
    	if [[ $1 == *"all"* ]]; then testParam="$filename"; else testParam="$filename -f $1"; fi

		# If the test_tag is 'all', skip the 'exampleTest' files
    	if [[ $1 == *"all"* ]] && [[ $filename == *"exampleTest"* ]]; then continue; fi

		# Only execute the tests if the file contains the test_tag (if not 'all')
		if [[ $1 == *"all"* ]] || grep -q $1 "$filename"; then
			resultOutput=$(./node_modules/.bin/mocha $testParam --timeout 60000  --reporter mocha-multi-reporters --reporter-options configFile=./package.json 2>&1 | tee $tty)
		fi

		# If we are running in a not TTY environment, just print the output in the default console
		if [[ $tty == *"not a tty"* ]]; then echo "$resultOutput"; fi
	done

	# Modify the Output folders
	if [[ ! -d "./test_output" ]]; then mkdir ./test_output/; fi
	if [[ -d "./allure-results" ]]; then cp -r ./allure-results/* ./test_output/; rm -rf ./allure-results; fi
	if [[ -d "./mochawesome-report" ]]; then cp -r ./mochawesome-report/* ./test_output/; rm -rf ./mochawesome-report; fi

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