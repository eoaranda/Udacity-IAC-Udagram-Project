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

aws cloudformation update-stack --stack-name $1  \
    --template-body file://$2   \
    --parameters file://$3  \
    --capabilities "CAPABILITY_NAMED_IAM"  \
    $REGION_OPTION $PROFILE_OPTION