FROM ubuntu:14.04
MAINTAINER krystism "krystism@gmail.com"
# install packages
RUN set -x \
	&& echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" > /etc/apt/sources.list.d/juno.list \
	&& apt-get -y update \
	&& apt-get -y install ubuntu-cloud-keyring \
	&& apt-get -y update \
	&& apt-get -y install \
		mysql-client \
		python-keystoneclient \
		python-mysqldb \
		python-novaclient \
		nova-api \
		nova-cert \
		nova-conductor \
		nova-consoleauth \
		nova-novncproxy \
		nova-scheduler \
	&& apt-get -y clean \
	&& rm -f /var/lib/nova/nova.sqlite
EXPOSE 8773 8774 8775 6080
#copy sql script
COPY nova.sql /root/nova.sql

#copy nova config file
COPY nova.conf /etc/nova/nova.conf

# add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh && chmod 744 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
