REGION_OPTION=""
if [ -n "$2" ]; then
    REGION_OPTION="--region $2"  # Region as the fifth parameter, if provided
else
    REGION_OPTION="--region us-east-1"  # Default to us-east-1 if not provided
fi

PROFILE_OPTION=""
if [ -n "$3" ]; then
    PROFILE_OPTION="--profile $3"  # Profile as the fourth parameter
fi

aws cloudformation delete-stack \
   --stack-name $1 \
    $REGION_OPTION $PROFILE_OPTION