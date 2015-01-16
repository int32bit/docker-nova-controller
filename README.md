# How to build ?
```
sudo docker  build --rm -t="krystism/openstack-nova-controller" .
```
# How to use ?
Before you start a nova-controller instance, you need these services running:
* mysql-server
* rabbitmq
* keystone
* glance-api & glance-reregistry

Both [mysql-server](https://registry.hub.docker.com/_/mysql/) and [rabbitmq](https://registry.hub.docker.com/_/rabbitmq/) images
are available, you can pull from docker hub. 

Of cource, you can replace mysql-server with [mariadb](https://registry.hub.docker.com/_/mariadb/).

To start mysql-server & rabbitmq, you just need run these scripts as follows:
```
docker run -d -e RABBITMQ_NODENAME=rabbitmq -h rabbitmq --name rabbitmq rabbitmq:latest
docker run -d -e MYSQL_ROOT_PASSWORD=MYSQL_DBPASS -h mysql --name mysql -d mariadb:latest
```
Then you should start a keystone service, you can use my keystone image to create a container with keystone to meet it:
```
docker run -d  --link mysql:mysql --name keystone -h keystone krystism/openstack-keystone:latest
```
The keystone service may take some time to start, you need wait for the service working before you do next.

Once the keystone service is running, you also need a glance service. if you just want to try openstack, fortunately, 
you can use my glance image to quickly deploy it:
```
docker run -d\
      	--link mysql:mysql \
       	--link keystone:keystone \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--name glance \
	-h glance \
	krystism/openstack-glance:latest
```
	
Lastly, let's begin our real work!
	
```
	docker run -d\
      	--link mysql:mysql \
       	--link keystone:keystone \
	--link rabbitmq:rabbitmq \
	--link glance:glance \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--privileged \
	--name controller \
	-h controller \
	krystism/openstack-nova-controller:latest
```
	
**Atention: The option *--privileged* is requited, or you can not update iptable in your container!**

It also may take some time, you can fetch logs to watch its process:
```
docker logs controller
```
Once complete, you can enter container using *exec* to check if the services work or not.
```
docker exec -t -i controller bash
cd /root
source admin-openrc.sh
nova service-list
```

# Possible Problem
I do not recommand you write a script to run all the command above or use fig, because different services to start may take
different time, you can not ensure the last service is running when you start current service. For example, if mysql
service does not work, the keystone service may fail to start, you must ensure mysql is running before create a keystone
instance.
