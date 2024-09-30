#!/bin/bash

# Parameter to determine behavior
ACTION_TYPE=$1  # New parameter for branching logic (e.g., "delete-network" or "delete-app")

# Check if stack name is provided
if [ -z "$2" ]; then
    echo "Error: Stack name is required as the second parameter."
    exit 1
fi

REGION_OPTION=""
if [ -n "$3" ]; then
    REGION_OPTION="--region $3"  # Region as the 3rd parameter, if provided
else
    REGION_OPTION="--region us-east-1"  # Default to us-east-1 if not provided
fi

PROFILE_OPTION=""
if [ -n "$4" ]; then
    PROFILE_OPTION="--profile $4"  # Profile as the fourth parameter
fi


# Branch logic based on ACTION_TYPE
if [[ "$ACTION_TYPE" == "delete-network" ]]; then

    # Delete the CloudFormation Network stack
    echo "Deleting CloudFormation stack: ${2}-network"
    aws cloudformation delete-stack --stack-name ${2}-network $REGION_OPTION $PROFILE_OPTION

    # Check if the delete command was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete CloudFormation stack: ${2}-network"
        exit 1
    fi

elif [[ "$ACTION_TYPE" == "delete-app" ]]; then

    # Extract the S3 bucket name from the stack outputs
    S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name ${2}-s3 $REGION_OPTION $PROFILE_OPTION --query "Stacks[0].Outputs[?OutputKey=='S3BucketNameOutput'].OutputValue" --output text)

    if [ -n "$S3_BUCKET_NAME" ]; then
        # Empty the S3 bucket
        echo "Emptying S3 bucket: $S3_BUCKET_NAME"
        aws s3 rm s3://$S3_BUCKET_NAME --recursive $REGION_OPTION $PROFILE_OPTION

        # Check if the empty command was successful
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to empty S3 bucket: $S3_BUCKET_NAME"
        fi

        # Delete the S3 bucket
        echo "Deleting S3 bucket: $S3_BUCKET_NAME"
        aws s3api delete-bucket --bucket $S3_BUCKET_NAME $REGION_OPTION $PROFILE_OPTION

        # Check if the delete command was successful
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to delete S3 bucket: $S3_BUCKET_NAME"
        fi

        # Delete the CloudFormation stack
        echo "Deleting CloudFormation stack: ${2}-s3"
        aws cloudformation delete-stack --stack-name ${2}-s3 $REGION_OPTION $PROFILE_OPTION

        # Check if the delete command was successful
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to delete CloudFormation stack: ${2}-s3"
            exit 1
        fi

        echo "CloudFormation stack ${2}-s3 deleted successfully."

    else
        echo "Warning: No S3 bucket found for stack ${2}-s3"
    fi

    # Delete the CloudFormation stack
    echo "Deleting CloudFormation stack: $2-app"
    aws cloudformation delete-stack --stack-name ${2}-app $REGION_OPTION $PROFILE_OPTION

    # Check if the delete command was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete CloudFormation stack: ${2}-app"
        exit 1
    fi

    echo "CloudFormation stack ${2}-app deleted successfully."

else
    echo "Invalid action type specified. Please use 'delete-network' or 'delete-app'."
    exit 1
fi
