#!/bin/bash

if [ -z "$1" ]
then
	echo "No command line argument provided for stack STACK_NAME"
	exit 1
fi

echo "Validating template"
RC=$(aws cloudformation validate-template --template-body file://./csye6225-cf-ci-cd.json)
echo "Template is valid"

if [ $? -eq 0 ]
then
	echo "Success: validate template"
else
	echo "Fail validate template"
	exit 1
fi

# Domain name for ARN
echo "Fetching domain name from Route 53"
DOMAIN_NAME=$(aws route53 list-hosted-zones --query HostedZones[0].Name --output text)
WEBAPP_DOMAIN="web-app."${DOMAIN_NAME%?}

CD_DOMAIN="code-deploy."${DOMAIN_NAME%?}


# Account id for arn
echo "Fetching user's account id"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

RC=$(aws cloudformation create-stack --stack-name $1-ci-cd --capabilities "CAPABILITY_NAMED_IAM" --template-body file://./csye6225-cf-ci-cd.json --parameters ParameterKey=CDARN,ParameterValue=arn:aws:s3:::$CD_DOMAIN/* ParameterKey=WEBAPPARN,ParameterValue=arn:aws:s3:::$WEBAPP_DOMAIN/* ParameterKey=CDAPPNAME,ParameterValue=CSYE6225 ParameterKey=CDOMAIN,ParameterValue=$CD_DOMAIN)

echo "CI stack creation in progress. Please wait"
aws cloudformation wait stack-create-complete --stack-name $1-ci-cd
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-ci-cd --query Stacks[0].StackId --output text)
echo "CI stack creation complete"
echo "CI Stack id: $STACKDETAILS"