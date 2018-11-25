## Amazon Cloud Formation Scripts

* csye-cf-networking.yaml - YAML template defining the resources necessary for cration of stack

* csye6225-aws-cf-create-stack.sh - This script uses `startmyinstance-parameters.json` which defines the parameters and `csye-cf-networking.yaml` which defines the stack template.

* csye6225-aws-cf-terminate-stack.sh - This script deletes the stack which is created using above code.

* csye6225-cf-application.yml - YAML template defining the resources necessary for creation of application

* csye6225-cf-create-application-stack.sh - This script is used to launch `EC2` instance with specific security groups

* csye6225-cf-terminate-application-stack.sh - This script is used to teardown `EC2` which is created using above script

**To create Stack**

Run commands: Open terminal and run the following commands
To launch : ./csye6225-aws-cf-create-stack.sh 'stackName' where stackname needs to passed through command lime

**To termiante Stack**

Run commands: Open terminal and run the following commands
To launch : ./csye6225-aws-cf-terminate-stack.sh 'stackName' where stackname needs to passed through command lime

**To create application**

Run commands: Open terminal and run the following commands
To launch : ./csye6225-aws-cf-terminate-stack.sh 'stackName' where stackname needs to passed through command lime

**To teardown application**

Run commands: Open terminal and run the following commands
To launch : ./csye6225-aws-cf-terminate-stack.sh 'stackName' where stackname needs to passed through command lime
***


