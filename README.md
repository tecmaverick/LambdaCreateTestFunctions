# AWS Lambda HyperPlane ENI Test
The script provisions multiple lambda functions within a VPC, to test HyperPlane ENI creation. During execution its creates VPC, Subnet and SecGroups, and then creates lambda functions.

Pre-req
1.AWS CLI configured
2.jq installed ( https://stedolan.github.io/jq/download/ )
3.Create an IAM role with the LambdaVPC policy attached, and set it in "lambda_execution_role" variable
4.Ensure the index.zip is placed in the same directory as CreateLambda.sh
5.Within the script replace the "profile_name" variable value "default" only if using a different profilename

Running the script
The script creates VPC, Subnet, SecGroup and Lambda functions. To create lambda functions
 un-comment "create_lambda_functions" and "audit_ENIs" towards the bottom of the script
 comment "delete_lambda_functions" towards the bottom of the script

To delete lambda functions
 comment "create_lambda_functions" and "audit_ENIs" towards the bottom of the script
 un-comment "delete_lambda_functions" towards the bottom of the script
