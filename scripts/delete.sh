REGION=${4:-us-east-1}

aws cloudformation delete-stack \
   --stack-name $1 \
    --region $REGION