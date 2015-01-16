#!/bin/bash
# create database for glance
export MYSQL_ROOT_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}
export MYSQL_HOST=${MYSQL_HOST:-mysql}
SQL_SCRIPT=/root/nova.sql
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST <$SQL_SCRIPT

# To create the Identity service credentials
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
GLANCE_HOST=${GLANCE_HOST:-glance}
NOVA_USER_NAME=${NOVA_USER_NAME:-nova}
NOVA_PASSWORD=${NOVA_PASSWORD:-NOVA_PASS}
NOVA_HOST=${NOVA_HOST:-$HOSTNAME}
export OS_USERNAME=${OS_USERNAME:-admin}
export OS_PASSWORD=${OS_PASSWORD:-ADMIN_PASS}
export OS_TENANT_NAME=${OS_TENANT_NAME:-admin}
export OS_AUTH_URL=${OS_AUTH_URL:-http://${KEYSTONE_HOST}:35357/v2.0}
keystone user-create --name $NOVA_USER_NAME --pass $NOVA_PASSWORD
keystone user-role-add --user $NOVA_USER_NAME --tenant service --role admin
keystone service-create --name nova --type compute --description "OpenStack Compute"
keystone endpoint-create \
	--service-id $(keystone service-list | awk '/ compute / {print $2}') \
	--publicurl http://${NOVA_HOST}:8774/v2/%\(tenant_id\)s \
	--internalurl http://${NOVA_HOST}:8774/v2/%\(tenant_id\)s \
	--adminurl http://${NOVA_HOST}:8774/v2/%\(tenant_id\)s \
	--region regionOne

# update nova.conf
CONFIG_FILE=/etc/nova/nova.conf
sed -i "s#^connection.*=.*#connection = mysql://nova:NOVA_DBPASS@${MYSQL_HOST}/nova#" $CONFIG_FILE
sed -i "s#^auth_uri.*=.*#auth_uri = http://${KEYSTONE_HOST}:5000/v2.0#" $CONFIG_FILE
sed -i "s#^identity_uri.*=.*#identity_uri = http://${KEYSTONE_HOST}:35357#" $CONFIG_FILE
sed -i "s#^admin_user.*=.*#admin_user = ${NOVA_USER_NAME}#" $CONFIG_FILE
sed -i "s#^admin_password.*=.*#admin_password = ${NOVA_PASSWORD}#" $CONFIG_FILE
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
RABBITMQ_USER=${RABBITMQ_USER:-guest}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-guest}
sed -i "s#^rabbit_host.*=.*#rabbit_host = ${RABBITMQ_HOST}#" $CONFIG_FILE
sed -i "s#^rabbit_password.*=.*#rabbit_password = ${RABBITMQ_PASSWORD}#" $CONFIG_FILE
MY_IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
sed -i "s#^my_ip.*=.*#my_ip = ${MY_IP}#" $CONFIG_FILE
sed -i "s#^vncserver_listen.*=.*#vncserver_listen = ${MY_IP}#" $CONFIG_FILE
sed -i "s#^vncserver_proxyclient_address*=.*#vncserver_proxyclient_address = ${MY_IP}#" $CONFIG_FILE
cat >>$CONFIG_FILE <<EOF
[glance]
host = $GLANCE_HOST
EOF

# sync the database
su -s /bin/sh -c "nova-manage db sync" nova

# create a admin-openrc.sh file
ADMIN_OPENRC=/root/admin-openrc.sh
cat >$ADMIN_OPENRC <<EOF
export OS_TENANT_NAME=$OS_TENANT_NAME
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$OS_PASSWORD
export OS_AUTH_URL=$OS_AUTH_URL
EOF

#start nova service
nova-api &
nova-cert &
nova-consoleauth &
nova-scheduler &
nova-conductor &
nova-novncproxy
