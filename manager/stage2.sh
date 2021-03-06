#! /bin/bash

echo "stage2 parameters"
echo $*

table_name=$1
region=$2
server_instance_number=$3
client_instance_number=$4
name_db=$5
count_per_user=$6
concurrent_number=$7
url_number=$8
interval=$9
shift 1
read_capacity_units=$9
shift 1
write_capacity_units=$9
shift 1
stack_name=$9
shift 1
bucket_name=$9

python re_generate_template.py $stack_name $bucket_name $region

if [ $? -ne 0 ]; then
	exit 1
fi

timeout_count=1200
i=0
((total_instance_number=server_instance_number+client_instance_number))
while true; do
	num=`salt-key -L | grep 'internal' | wc -l`
	if [ "$num" == "$total_instance_number" ]; then
		break
	fi
	((++i))
	if [ $i -gt $timeout_count ]; then
		echo "timeout1 $num $total_instance_number"
		exit 1
	fi
	sleep 1
done

salt-key -A -y

i=0
while true; do
	num=`salt '*' test.ping | grep 'internal' | wc -l`
	if [ "$num" == "$total_instance_number" ]; then
		break
	fi
	((++i))
	if [ $i -gt $timeout_count ]; then
		echo "timeout2 $num $total_instance_number"
		exit 1
	fi
	sleep 1
done

salt -G 'roles:server' test.ping | grep internal | awk -F . '{a=substr($1,4);gsub("-",".",a);print a}' > /tmp/server_ip
salt -G 'roles:client' test.ping | grep internal | awk -F . '{a=substr($1,4);gsub("-",".",a);print a}' > /tmp/client_ip
salt -G 'roles:server' cmd.run 'GET 169.254.169.254/latest/meta-data/instance-id' | grep -v internal > /tmp/server_id
salt -G 'roles:client' cmd.run 'GET 169.254.169.254/latest/meta-data/instance-id' | grep -v internal > /tmp/client_id

sed -i "s/replace_by_table_name/$table_name/g" manager_conf.yaml
sed -i "s/replace_by_region/$region/g" manager_conf.yaml
sed -i "s/replace_by_name_db/$name_db/g" manager_conf.yaml
sed -i "s/replace_by_count_per_user/$count_per_user/g" manager_conf.yaml
sed -i "s/replace_by_concurrent_number/$concurrent_number/g" manager_conf.yaml
sed -i "s/replace_by_url_number/$url_number/g" manager_conf.yaml
sed -i "s/replace_by_interval/$interval/g" manager_conf.yaml
sed -i "s/replace_by_read_capacity_units/$read_capacity_units/g" static/js/load_chart.js
sed -i "s/replace_by_write_capacity_units/$write_capacity_units/g" static/js/load_chart.js

./generate_url.py

lagest_index=`ls /srv/salt/url | grep download | wc -l`
sed -i "s/replace_by_lagest_index/$lagest_index/g" manager_conf.yaml

salt -t 50 -G 'roles:client' cp.get_dir salt://url /opt/dynamodb_demo/client

salt -G 'roles:client' cmd.run 'cd /opt/dynamodb_demo/client/http_load;make'

cp -f manager_nginx.conf /etc/nginx/nginx.conf

service nginx start
chkconfig nginx on

cmd="cd /opt/dynamodb_demo/manager; /usr/local/bin/uwsgi --socket 127.0.0.1:3031 --wsgi-file manager.py --callable app --processes 1 --threads 1 --stats 127.0.0.1:9191 -d /opt/dynamodb_demo/uwsgi.log"

echo "$cmd" > run.sh
echo "bash /opt/dynamodb_demo/manager/run.sh" >> /etc/rc.local
bash run.sh

salt '*' cmd.run 'reboot'

bash back_ground.sh

exit 0
