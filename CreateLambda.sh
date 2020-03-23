#Pre-req
# 1.AWS CLI configured
# 2.jq installed ( https://stedolan.github.io/jq/download/ )
# 3.Create an IAM role with the LambdaVPC policy attached, and set it in "lambda_execution_role" variable
# 4.Ensure the index.zip is placed in the same directory as CreateLambda.sh
# 5.Within the script replace the "profile_name" variable value "default" only if using a different profilename 

# Running the script
# The script creates VPC, Subnet, SecGroup and Lambda functions. To create lambda functions 
#  un-comment "create_lambda_functions" and "audit_ENIs" towards the bottom of the script
#  comment "delete_lambda_functions" towards the bottom of the script

# To delete lambda functions
#  comment "create_lambda_functions" and "audit_ENIs" towards the bottom of the script
#  un-comment "delete_lambda_functions" towards the bottom of the script

#------------------------------------------------------------------------------------------------------------------------

total_lambda_functions=260
lambda_execution_role="arn:aws:iam::857980770372:role/lambda_role"
lambda_source_code_zip_file_name="index.zip"
profile_name="burner"

#------------------------------------------------------------------------------------------------------------------------
function create_lambda_functions()
{
    echo "Creating VPC"
    vpcId=`aws ec2 create-vpc --cidr-block "10.168.0.0/16" --region us-east-1 --profile $profile_name | jq -r ".Vpc.VpcId"`
    echo "Created VPC $vpcId"

    echo "Creating Subnet1"
    subnet1=`aws ec2 create-subnet --vpc-id $vpcId --availability-zone "us-east-1a" --cidr-block "10.168.100.0/22" --profile $profile_name | jq -r ".Subnet.SubnetId" `
    echo "Created Subnet $subnet1"

    echo "Creating Subnet2"
    subnet2=`aws ec2 create-subnet --vpc-id $vpcId --availability-zone "us-east-1b" --cidr-block "10.168.0.10/22" --profile $profile_name | jq -r ".Subnet.SubnetId" `
    echo "Created Subnet $subnet2"

    secgroup=()

    for i in $(seq 0 $total_lambda_functions)
    do
        echo "Creating Security Group $i of $total_lambda_functions"
        secgroup+=(`aws ec2 create-security-group --vpc-id $vpcId --description "subnet $i" --group-name "group $i" --profile $profile_name | jq -r ".GroupId" `)
        echo "Creating Security Group $i of $total_lambda_functions complete"
    done

    counter=0
    for i in "${secgroup[@]}"
    do   
        echo "Creating Lambda function $counter of $total_lambda_functions"

            #Un-comment to provision lambda function with *ONE* subnet
            fn_name=$(aws lambda create-function --function-name "test-$counter" \
                                        --runtime "python2.7" \
                                        --role $lambda_execution_role \
                                        --handler "index.handler" \
                                        --zip-file fileb://$lambda_source_code_zip_file_name \
                                        --vpc-config SubnetIds=$subnet1,SecurityGroupIds=${secgroup[$counter]} \
                                        --profile $profile_name | jq -r ".FunctionName")

            #Un-comment to provision lambda function with *TWO* subnet
            # fn_name=$(aws lambda create-function --function-name "test-$counter" \
            #                             --runtime "python2.7" \
            #                             --role $lambda_execution_role \
            #                             --handler "index.handler" \
            #                             --zip-file fileb://$lambda_source_code_zip_file_name \
            #                             --vpc-config SubnetIds=$subnet1,$subnet2,SecurityGroupIds=${secgroup[$counter]} \
            #                             --profile $profile_name | jq -r ".FunctionName")

            echo "Created lambda function $fn_name"

        ((counter=counter+1))
    done
}

#------------------------------------------------------------------------------------------------------------------------

function delete_lambda_functions()
{
    #delete all lambda functions
    counter=0
    for i in $(seq 0 $total_lambda_functions)
    do   
    echo "Deleting Lambda function $counter of $total_lambda_functions"

        aws lambda delete-function --function-name "test-$counter" --profile $profile_name
        echo "Deleted lambda function"

    ((counter=counter+1))
    done
}

#------------------------------------------------------------------------------------------------------------------------

function audit_ENIs()
{
    eni_count=$(aws ec2 describe-network-interfaces  \
                            --filters "Name=description,Values='AWS Lambda VPC ENI-test-*'" "Name=status,Values='in-use'" \
                            --query "NetworkInterfaces[].[NetworkInterfaceId]"  \
                            --profile $profile_name | jq ".[][]" | wc -l)

    echo "ENI provisioned count: $eni_count"
}

#------------------------------------------------------------------------------------------------------------------------

create_lambda_functions
audit_ENIs

# delete_lambda_functions
