#! /bin/bash

bucket_name='jenny-test'
region='ap-northeast-1'
dir_name='dynamodb_demo'
stack_name="test1"
key_name="penyu1"
resource_link="https://s3-ap-southeast-1.amazonaws.com/jenny-test/dynamodb_demo.zip"
read_capacity_units="1000"
write_capacity_units="1000"
server_instance_type="m1.small"
client_instance_type="m1.small"
manager_instance_type="m1.small"
server_instance_number="1"
client_instance_number="1"
name_db="name_20K.db"
count_per_user="1"
concurrent_number="500"
url_number="2000"
