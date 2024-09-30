#!/bin/bash

# Parameter to determine behavior
ACTION_TYPE=$1  # New parameter for branching logic (e.g., "create-network" or "create-app")

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
if [[ "$ACTION_TYPE" == "create-network" ]]; then
    echo "Creating main infrastructure stack: ${2}-network"
    aws cloudformation create-stack --stack-name ${2}-network \
        --template-body file://network.yml \
        --parameters file://network-parameters.json \
        --capabilities "CAPABILITY_NAMED_IAM" \
        $REGION_OPTION $PROFILE_OPTION 

elif [[ "$ACTION_TYPE" == "create-app" ]]; then
    echo "Creating S3 Bucket stack: ${2}-s3"
    aws cloudformation create-stack --stack-name ${2}-s3 \
        --template-body file://s3-bucket.yml \
        --parameters file://s3-parameters.json \
        --capabilities "CAPABILITY_NAMED_IAM" \
        $REGION_OPTION $PROFILE_OPTION 

    # Wait for the S3 Bucket stack to complete
    aws cloudformation wait stack-create-complete --stack-name ${2}-s3 $REGION_OPTION $PROFILE_OPTION

    # Extract the S3 bucket name from the S3 Bucket stack outputs
    S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name ${2}-s3 $REGION_OPTION $PROFILE_OPTION --query "Stacks[0].Outputs[?OutputKey=='S3BucketNameOutput'].OutputValue" --output text)

    # Check if the bucket name was retrieved successfully
    if [ -n "$S3_BUCKET_NAME" ]; then
        # Copy files to the S3 bucket
        echo "Copying files to S3 bucket: $S3_BUCKET_NAME"
        aws s3 cp html/ s3://$S3_BUCKET_NAME/ --recursive $REGION_OPTION $PROFILE_OPTION

        echo "Files copied to S3 bucket: $S3_BUCKET_NAME"
    else
        echo "Failed to retrieve S3 bucket name from stack outputs."
        exit 1
    fi

    # Create the main infrastructure stack
    echo "Creating main infrastructure stack: ${2}-app"
    aws cloudformation create-stack --stack-name ${2}-app \
        --template-body file://udagram.yml \
        --parameters file://udagram-parameters.json \
        --capabilities "CAPABILITY_NAMED_IAM" \
        $REGION_OPTION $PROFILE_OPTION 

    # Wait for the main infrastructure stack to be created
    aws cloudformation wait stack-create-complete --stack-name ${2}-app $REGION_OPTION $PROFILE_OPTION

    # Final status check for the main stack
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${2}-app $REGION_OPTION $PROFILE_OPTION --query "Stacks[0].StackStatus" --output text)
    echo "Main stack status: $STACK_STATUS"

    if [ "$STACK_STATUS" != "CREATE_COMPLETE" ]; then
        echo "Main stack creation failed or is in an unexpected state: $STACK_STATUS"
        exit 1
    fi

else
    echo "Invalid action type specified. Please use 'create-network' or 'create-app'."
    exit 1
fi
