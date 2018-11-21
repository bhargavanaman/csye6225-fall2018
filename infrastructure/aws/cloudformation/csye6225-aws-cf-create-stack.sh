
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
APP_DOMAIN_NAME="web-app."${DOMAIN_NAME%?}

PUBLIC_SUBNET=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PublicSubnet`][PhysicalResourceId]' --output text)
PUBLIC_SUBNET2=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PublicSubnet2`][PhysicalResourceId]' --output text)
SUBNET_ID_1=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PrivateSubnet1`][PhysicalResourceId]' --output text)
SUBNET_ID_2=$(aws cloudformation list-stack-resources --stack-name $1-networking --query 'StackResourceSummaries[?LogicalResourceId==`PrivateSubnet2`][PhysicalResourceId]' --output text)

SGID=$(aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=8080 --query 'SecurityGroups[*].{Name:GroupId}[0]' --output text)

DBSGID=$(aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=3306 --query 'SecurityGroups[*].{Name:GroupId}[0]' --output text)
echo $DBSGID

LBSG=$(aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=443 --query 'SecurityGroups[*].{Name:GroupId}[0]' --output text)

CERTIFICATE=$(aws acm list-certificates --query 'CertificateSummaryList[0].CertificateArn' --output text)


DBUser=root
DBPassword=masteruserpassword



CD_DOMAIN="code-deploy."${DOMAIN_NAME}
WEBAPP_DOMAIN="web-app."${DOMAIN_NAME}

BUCKETARN="arn:aws:s3:::"${DOMAIN_NAME}
echo "BUCKETARN is "$BUCKETARN
CDAPPNAME="CSYE6225"

echo "Starting cicd"
RC=$(aws cloudformation create-stack --stack-name $1-ci-cd --capabilities "CAPABILITY_NAMED_IAM" --template-body file://./csye6225-cf-ci-cd.json --parameters ParameterKey=CDARN,ParameterValue=arn:aws:s3:::$CD_DOMAIN/* ParameterKey=WEBAPPARN,ParameterValue=arn:aws:s3:::$WEBAPP_DOMAIN/* ParameterKey=CDOMAIN,ParameterValue=$CD_DOMAIN ParameterKey=CDAPPNAME,ParameterValue=$CDAPPNAME ParameterKey=LAMBDAUSERROLE,ParameterValue=LambdaExecutionRole ParameterKey=LOGROLEPOLICYNAME,ParameterValue=LogRolePolicy ParameterKey=BUCKETARN,ParameterValue=$BUCKETARN)

echo "CI stack creation in progress. Please wait"
aws cloudformation wait stack-create-complete --stack-name $1-ci-cd
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-ci-cd --query Stacks[0].StackId --output text)
echo "CI stack creation complete"
echo "CI Stack id: $STACKDETAILS"

echo "Fetching CodeDeployServiceRole Arn"
CDSR_ARN=$(aws iam get-role --role-name CodeDeployServiceRole --query Role.Arn --output text)

aws cloudformation create-stack --stack-name $1-application --template-body file://./csye6225-cf-auto-scaling-application.json --parameters ParameterKey=VPCID,ParameterValue=$VPC_ID ParameterKey=PUBLICSUBNETID,ParameterValue=$PUBLIC_SUBNET ParameterKey=PUBLICSUBNETID2,ParameterValue=$PUBLIC_SUBNET2 ParameterKey=SUBNETID1,ParameterValue=$SUBNET_ID_1 ParameterKey=SUBNETID2,ParameterValue=$SUBNET_ID_2 ParameterKey=DOMAIN,ParameterValue=$DOMAIN_NAME ParameterKey=APPDOMAIN,ParameterValue=$APP_DOMAIN_NAME ParameterKey=SGID,ParameterValue=$SGID ParameterKey=LBSG,ParameterValue=$LBSG ParameterKey=CERTIFICATE,ParameterValue=$CERTIFICATE ParameterKey=DBSGID,ParameterValue=$DBSGID ParameterKey=DBUser,ParameterValue=$DBUser ParameterKey=CDAPPNAME,ParameterValue=$CDAPPNAME ParameterKey=DBPassword,ParameterValue=$DBPassword ParameterKey=CDSRARN,ParameterValue=$CDSR_ARN 


aws cloudformation wait stack-create-complete --stack-name $1-application
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-application --query Stacks[0].StackId --output text)
echo "Application stack creation complete"
echo "Application Stack id: $STACKDETAILS"


LAMBDABUCKET="lambda.$DOMAIN_NAME"
echo "LAMBDA_BUCKET:- $LAMBDABUCKET"

AccountId=$(aws iam get-user|python -c "import json as j,sys;o=j.load(sys.stdin);print o['User']['Arn'].split(':')[4]")
echo "AccountId: $AccountId"

SNSTOPIC_ARN="arn:aws:sns:us-east-1:$AccountId:SNSTopicResetPassword"
echo "SNSTOPIC_ARN: $SNSTOPIC_ARN"

aws cloudformation create-stack --stack-name $1-serverless --capabilities "CAPABILITY_NAMED_IAM" --template-body file://./csye6225-cf-serverless.json --parameters ParameterKey=LAMBDABUCKET,ParameterValue=$LAMBDABUCKET ParameterKey=SNSTOPICARN,ParameterValue=$SNSTOPIC_ARN
aws cloudformation wait stack-create-complete --stack-name $1-serverless
STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-serverless --query Stacks[0].StackId --output text)


exit 0
