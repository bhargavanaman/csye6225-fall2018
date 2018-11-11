#!/bin/bash

if [ -z "$1" ]
then
	echo "No command line argument provided for stack STACK_NAME"
	exit 1
else
	echo "Stack name present. Checking for CIDRBlock"
fi

#if [ -z "$2" ]
#then
	#echo "No command line argument provided for CIDRBlock"
	#exit 1
#else
	#echo "CIDRBlock address provided."
#fi
cidr=10.0.0.0/16

echo "Validating template"
RC=$(aws cloudformation validate-template --template-body file://./csye6225-cf-networking.json)
echo "Template is valid"

if [ $? -eq 0 ]
then
	echo "Success: validate template"
else
	echo "Fail validate template"
	exit 1
fi

echo "Started with creating networking stack using cloud formation"
RC=$(aws cloudformation create-stack --stack-name $1-networking --template-body file://./csye6225-cf-networking.json --parameters ParameterKey=VPCNAME,ParameterValue=$1-csye6225-vpc ParameterKey=IGWNAME,ParameterValue=$1-csye6225-InternetGateway ParameterKey=PUBLICROUTETABLENAME,ParameterValue=$1-csye6225-public-route-table ParameterKey=PRIVATEROUTETABLENAME,ParameterValue=$1-csye6225-private-route-table  ParameterKey=CIDRBLOCK,ParameterValue=$cidr)

echo "Networking stack creation in progress. Please wait"
aws cloudformation wait stack-create-complete --stack-name $1-networking
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-networking --query Stacks[0].StackId --output text)
echo "Networking stack creation complete"
echo "Networking Stack id: $STACKDETAILS"

echo "Creating application stack"

echo "Fetching VPC details"
VPC_ID=$(aws ec2 describe-vpcs --query Vpcs[0].VpcId --output text)

echo "Fetching domain name from Route 53"
DOMAIN_NAME=$(aws route53 list-hosted-zones --query HostedZones[0].Name --output text)
DOMAIN_NAME="${DOMAIN_NAME%?}"
echo "$DOMAIN_NAME"
#DOMAIN_NAME="csye6225-fall2018-bhargavan.me"

PUBLIC_SUBNET=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PublicSubnet`][PhysicalResourceId]' --output text)
SUBNET_ID_1=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PrivateSubnet1`][PhysicalResourceId]' --output text)
SUBNET_ID_2=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PrivateSubnet2`][PhysicalResourceId]' --output text)

SGID=$(aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=22 --query 'SecurityGroups[*].{Name:GroupId}[0]' --output text)

DBSGID=$(aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=3306 --query 'SecurityGroups[*].{Name:GroupId}[0]' --output text)
echo $DBSGID

DBUser=root
DBPassword=masteruserpassword

CD_DOMAIN="code-deploy."${DOMAIN_NAME}
WEBAPP_DOMAIN="web-app."${DOMAIN_NAME}
BUCKETARN="arn:aws:s3:::"${DOMAIN_NAME}

echo "Starting cicd"
RC=$(aws cloudformation create-stack --stack-name $1-ci-cd --capabilities "CAPABILITY_NAMED_IAM" --template-body file://./csye6225-cf-ci-cd.json --parameters ParameterKey=CDARN,ParameterValue=arn:aws:s3:::$CD_DOMAIN/* ParameterKey=WEBAPPARN,ParameterValue=arn:aws:s3:::$WEBAPP_DOMAIN/* ParameterKey=CDAPPNAME,ParameterValue=CSYE6225 ParameterKey=CDOMAIN,ParameterValue=$CD_DOMAIN ParameterKey=BUCKETARN,ParameterValue=$BUCKETARN ParameterKey=LAMBDAUSERROLE,ParameterValue=LambdaExecutionRole ParameterKey=LOGROLEPOLICYNAME,ParameterValue=LogRolePolicy)

echo "CI stack creation in progress. Please wait"
aws cloudformation wait stack-create-complete --stack-name $1-ci-cd
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-ci-cd --query Stacks[0].StackId --output text)
echo "CI stack creation complete"
echo "CI Stack id: $STACKDETAILS"



aws cloudformation create-stack --stack-name $1-application --template-body file://./csye6225-cf-application.json --parameters ParameterKey=PUBLICSUBNETID,ParameterValue=$PUBLIC_SUBNET ParameterKey=SUBNETID1,ParameterValue=$SUBNET_ID_1 ParameterKey=SUBNETID2,ParameterValue=$SUBNET_ID_2 ParameterKey=DOMAIN,ParameterValue=$DOMAIN_NAME ParameterKey=SGID,ParameterValue=$SGID ParameterKey=DBSGID,ParameterValue=$DBSGID ParameterKey=DBUser,ParameterValue=$DBUser ParameterKey=DBPassword,ParameterValue=$DBPassword


aws cloudformation wait stack-create-complete --stack-name $1-application
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-application --query Stacks[0].StackId --output text)
echo "Application stack creation complete"
echo "Application Stack id: $STACKDETAILS"

<<<<<<< HEAD
=======

>>>>>>> 34a9e1e4993ab6566b57b35f2ef294361c284917
LAMBDABUCKET="lambda.$DOMAIN_NAME"
echo "LAMBDA_BUCKET:- $LAMBDABUCKET"

AccountId=$(aws iam get-user|python -c "import json as j,sys;o=j.load(sys.stdin);print o['User']['Arn'].split(':')[4]")
echo "AccountId: $AccountId"

SNSTOPIC_ARN="arn:aws:sns:us-east-1:$AccountId:SNSTopicResetPassword"
echo "SNSTOPIC_ARN: $SNSTOPIC_ARN"

aws cloudformation create-stack --stack-name $1-serverless --capabilities "CAPABILITY_NAMED_IAM" --template-body file://./csye6225-cf-serverless.json --parameters ParameterKey=LAMBDABUCKET,ParameterValue=$LAMBDABUCKET ParameterKey=SNSTOPICARN,ParameterValue=$SNSTOPIC_ARN
aws cloudformation wait stack-create-complete --stack-name $1-serverless
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-serverless --query Stacks[0].StackId --output text)

<<<<<<< HEAD
=======

>>>>>>> 34a9e1e4993ab6566b57b35f2ef294361c284917
exit 0
