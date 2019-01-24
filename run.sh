#!/bin/bash

# SELECT TEST TO RUN
testParam="./specs/$1.spec.js"
test=""

if [ $# -lt 1 ]
then
    echo "Wrong amount of params"
    echo "Mandatory: [testName] Optional: [testGroups]"
    exit 1
elif [ $1 == "all" ]
then
    echo "Executing all test files in ./specs"
    testParam='./specs/*.spec.js'
    test="$1"
elif [ $# -lt 2 ]
then
    echo "Executing all tests of [$1]"
    test="$1"
else
    echo "Executing the tests of [$1] that match the group tag [$2]"
    testParam="./specs/$1.spec.js -f $2"
    test="$1_$2"
fi

# SYNC COMMANDS WITH SO
currentOS=$(uname)
sudoCommand="sudo "
if [[ $currentOS == *"MINGW64"* ]]; 
then
    echo $'\n'"Current OS is Windows, removing sudo"
    sudoCommand=""
else
    echo $'\n'"Current OS is Linux, adding sudo"
fi

# CLEAN PREVIOUS REPORTS
$sudoCommand rm -rf testOutput
$sudoCommand rm -rf mochawesome-report
$sudoCommand mkdir testOutput

# RUN TEST
./node_modules/.bin/mocha $testParam --timeout 60000  --reporter mocha-multi-reporters --reporter-options configFile=./utils/reporterConfig.json

# UPLOAD REPORTS
timestamp() {
  date "+%d_%m_%Y_%H_%M"
}

# GET ALL THE PARAMS FROM CONFIG FILE
s3Bucket=`node -p "require('./config.json').s3Bucket.bucketName"`
defaultRegion=`node -p "require('./config.json').s3Bucket.defaultRegion"`
accessKey=`node -p "require('./config.json').s3Bucket.accessKey"`
accessKeySecret=`node -p "require('./config.json').s3Bucket.accessKeySecret"`
qmetryProject=`node -p "require('./config.json').qmetry.jiraProject"`

# CONFIGURE AWS
aws configure set aws_access_key_id $accessKey
aws configure set aws_secret_access_key $accessKeySecret
aws configure set default.region $defaultRegion
echo $'\n'"Configured AWS with AccessKey -> $accessKey, Secret -> $accessKeySecret, Default Region -> $defaultRegion"

# UPLOAD REPORT TO S3
pwd=$(pwd)
IFS='/' read -ra ADDR <<< "$pwd"
pwdLength=${#ADDR[@]}
lenToGet=$(( pwdLength - 2 ))
folderName=${ADDR[$lenToGet]}

currentTime=$(timestamp)
testFolder="$folderName/$test/$currentTime"
testName="${folderName}_${test}_${currentTime}"

s3reportFolder="$s3Bucket/$testFolder"
s3reportLink="https://s3-$defaultRegion.amazonaws.com/$s3reportFolder/mochawesome.html"

echo "Uploading the report to the S3 Bucket [$s3Bucket]"$'\n'
aws s3 sync ./mochawesome-report s3://$s3reportFolder --acl public-read

echo $'\n'"Please check the report at: [$s3reportLink]"

# UPLOAD TEST TO JIRA'S QMETRY
echo $'\n'"Uploading the report to Jira's Qmetry. Project: [$qmetryProject] Task Name: [$testName]"
./node_modules/.bin/mocha ./utils/export-results-jira.js --timeout 60000 --testname $testName --testlink $s3reportLink