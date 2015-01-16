FROM krystism/openstack_base:juno
MAINTAINER krystism "krystism@gmail.com"
# install packages
RUN apt-get -y install python-glanceclient python-keystoneclient python-novaclient
RUN apt-get -y install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler

# remove the SQLite database file
RUN rm -f /var/lib/nova/nova.sqlite

EXPOSE 8773 8774 8775 6080
#copy sql script
COPY nova.sql /root/nova.sql

#copy nova config file
COPY nova.conf /etc/nova/nova.conf

# add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 744 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
