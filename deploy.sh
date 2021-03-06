#! /bin/bash

source conf.sh

if [ "$1" == "" ]; then
	echo "specific a stack name"
	exit 1
fi

stack_name="$1"

aws cloudformation create-stack --stack-name $stack_name --template-body file://dynamodb_demo.json --parameters ParameterKey="KeyName",ParameterValue="$key_name" ParameterKey="ResourceLink",ParameterValue="$resource_link" ParameterKey="ReadCapacityUnits",ParameterValue="$read_capacity_units" ParameterKey="WriteCapacityUnits",ParameterValue="$write_capacity_units" ParameterKey="ServerInstanceType",ParameterValue="$server_instance_type" ParameterKey="ClientInstanceType",ParameterValue="$client_instance_type" ParameterKey="ManagerInstanceType",ParameterValue="$manager_instance_type" ParameterKey="ServerInstanceNumber",ParameterValue="$server_instance_number" ParameterKey="ClientInstanceNumber",ParameterValue="$client_instance_number" ParameterKey="NameDB",ParameterValue="$name_db" ParameterKey="CountPerUser",ParameterValue="$count_per_user" ParameterKey="ConcurrentNumber",ParameterValue="$concurrent_number" ParameterKey="UrlNumber",ParameterValue="$url_number" ParameterKey="Interval",ParameterValue=$interval --capabilities CAPABILITY_IAM --region $region
