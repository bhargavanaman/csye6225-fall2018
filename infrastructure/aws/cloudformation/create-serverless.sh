<<<<<<< HEAD
#aws cloudformation create-stack --stack-name $1-serverless --capabilities "CAPABILITY_NAMED_IAM" --template-body file://./csye6225-cf-serverless.json
#aws cloudformation wait stack-create-complete --stack-name $1-serverless
#AccountId=$(aws iam get-user|python -c "import json as j,sys;o=j.load(sys.stdin);print o['User']['Arn'].split(':')[4]")
#echo "AccountId: $AccountId"
#STACKDETAILS=$(aws cloudformation describe-stacks --stack-name $1-serverless --query Stacks[0].StackId --output text)

=======
>>>>>>> 34a9e1e4993ab6566b57b35f2ef294361c284917
echo "Fetching domain name from Route 53"
DOMAIN_NAME=$(aws route53 list-hosted-zones --query HostedZones[0].Name --output text)
DOMAIN_NAME="${DOMAIN_NAME%?}"
echo "DOMAIN_NAME:- $DOMAIN_NAME"

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
