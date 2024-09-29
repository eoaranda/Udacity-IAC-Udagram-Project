#!/bin/bash

# Check if stack name is provided
if [ -z "$1" ]; then
    echo "Error: Stack name is required as the first parameter."
    exit 1
fi

# Region setup
REGION_OPTION=""
if [ -n "$2" ]; then
    REGION_OPTION="--region $2"  # Region as the second parameter
else
    REGION_OPTION="--region us-east-1"  # Default to us-east-1 if not provided
fi

# Profile setup
PROFILE_OPTION=""
if [ -n "$3" ]; then
    PROFILE_OPTION="--profile $3"  # Profile as the third parameter
fi

# Extract the S3 bucket name from the stack outputs
S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $1 $REGION_OPTION $PROFILE_OPTION --query "Stacks[0].Outputs[?OutputKey=='S3BucketNameOutput'].OutputValue" --output text)

if [ -n "$S3_BUCKET_NAME" ]; then
    # Empty the S3 bucket
    echo "Emptying S3 bucket: $S3_BUCKET_NAME"
    aws s3 rm s3://$S3_BUCKET_NAME --recursive $REGION_OPTION $PROFILE_OPTION

    # Check if the empty command was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to empty S3 bucket: $S3_BUCKET_NAME"
        exit 1
    fi
else
    echo "Warning: No S3 bucket found for stack $1."
fi

# Delete the CloudFormation stack
echo "Deleting CloudFormation stack: $1"
aws cloudformation delete-stack --stack-name $1 $REGION_OPTION $PROFILE_OPTION

# Check if the delete command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to delete CloudFormation stack: $1"
    exit 1
fi

echo "CloudFormation stack $1 deleted successfully."