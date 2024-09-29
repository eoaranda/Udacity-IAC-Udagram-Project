#!/bin/bash

REGION_OPTION=""
if [ -n "$4" ]; then
    REGION_OPTION="--region $4"  # Region as the fifth parameter, if provided
else
    REGION_OPTION="--region us-east-1"  # Default to us-east-1 if not provided
fi

PROFILE_OPTION=""
if [ -n "$5" ]; then
    PROFILE_OPTION="--profile $5"  # Profile as the fourth parameter
fi

aws cloudformation create-stack --stack-name $1 \
    --template-body file://$2 \
    --parameters file://$3 \
    --capabilities "CAPABILITY_NAMED_IAM" \
    $REGION_OPTION $PROFILE_OPTION 

# Wait for the stack to be created
aws cloudformation wait stack-create-complete --stack-name $1 $REGION_OPTION $PROFILE_OPTION

# Check the stack status
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $1 $REGION_OPTION $PROFILE_OPTION --query "Stacks[0].StackStatus" --output text)
echo "Stack status: $STACK_STATUS"

if [ "$STACK_STATUS" != "CREATE_COMPLETE" ]; then
    echo "Stack creation failed or is in an unexpected state: $STACK_STATUS"
    exit 1
fi

# Extract the S3 bucket name from the stack outputs
S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $1 $REGION_OPTION $PROFILE_OPTION --query "Stacks[0].Outputs[?OutputKey=='S3BucketNameOutput'].OutputValue" --output text)

# Check if the bucket name was retrieved successfully
if [ -n "$S3_BUCKET_NAME" ]; then
    # Copy files to the S3 bucket
    aws s3 cp html/ s3://$S3_BUCKET_NAME/ --recursive $REGION_OPTION $PROFILE_OPTION
    echo "Files copied to S3 bucket: $S3_BUCKET_NAME"
else
    echo "Failed to retrieve S3 bucket name from stack outputs."
    exit 1
fi