#!/bin/bash

## Refresh config
cp -R /opt/postal/config-original/* /opt/postal/config

## Generate keys
/opt/postal/bin/postal initialize-config

if [[ $(cat /opt/postal/config/postal.yml| grep -i web_server |wc -l) == 0 ]]; then
cat >> /opt/postal/config/postal.yml << EOF
web_server:
  bind_address: 0.0.0.0
EOF
fi

# Set host
sed -i -e '/web:/!b' -e ':a' -e "s/host.*/host: ${VIRTUAL_HOST:-postal.example.com}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml

## Set MySQL/RabbitMQ usernames/passwords
### MySQL Main DB
sed -i -e '/main_db:/!b' -e ':a' -e "s/host:.*/host: ${DATABASE_HOST}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e'/main_db:/!b' -e ':a' -e "s/username:.*/username: ${DATABASE_USERNAME}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e'/main_db:/!b' -e ':a' -e "s/password:.*/password: ${DATABASE_PASSWORD//\//\\/}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e'/main_db:/!b' -e ':a' -e "s/database:.*/database: ${DATABASE_NAME}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
### MySQL Message DB
sed -i -e '/message_db:/!b' -e ':a' -e "s/host.*/host: ${DATABASE_HOST}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e'/message_db:/!b' -e ':a' -e "s/username:.*/username: ${DATABASE_USERNAME}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e'/message_db:/!b' -e ':a' -e "s/password:.*/password: ${DATABASE_PASSWORD//\//\\/}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e'/message_db:/!b' -e ':a' -e "s/database:.*/database: ${DATABASE_NAME}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
### RabbitMQ
sed -i -e '/rabbitmq:/!b' -e ':a' -e "s/host:.*/host: ${RABBITMQ_HOST}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e '/rabbitmq:/!b' -e ':a' -e "s/username:.*/username: ${RABBITMQ_USERNAME}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e '/rabbitmq:/!b' -e ':a' -e "s/password:.*/password: ${RABBITMQ_PASSWORD//\//\\/}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml
sed -i -e '/rabbitmq:/!b' -e ':a' -e "s/vhost:.*/vhost: ${RABBITMQ_VHOST//\//\\/}/;t trail" -e 'n;ba' -e ':trail' -e 'n;btrail' /opt/postal/config/postal.yml

## Clean Up
rm -rf /opt/postal/tmp/pids/*

## Initialize DB
echo "== Waiting for MySQL to start up =="
while ! mysqladmin ping -h ${DATABASE_HOST} --silent; do
    sleep 1
done
if [[ $(mysql -h ${DATABASE_HOST} -u${DATABASE_USERNAME} -p${DATABASE_PASSWORD} -s --skip-column-names -e "SELECT COUNT(DISTINCT table_name) FROM information_schema.columns WHERE table_schema = '${DATABASE_NAME}'") == 0 ]]; then
	/opt/postal/bin/postal initialize
else
	/opt/postal/bin/postal upgrade
fi

## Run
/opt/postal/bin/postal run
