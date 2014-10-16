FROM ubuntu:14.04
#FROM ubuntu:12.04
#RUN apt-get update
## below installs add-apt-repository
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-software-properties
#RUN add-apt-repository cloud-archive:havana
ADD add-opencontrail-apt.sh /root/add-opencontrail-apt.sh
RUN /root/add-opencontrail-apt.sh
RUN rm /etc/apt/sources.list.d/proposed.list
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-database
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-config default-jre sysv-rc
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-control
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-analytics
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-webui nodejs=0.8.15-1contrail1

# extra things for docker env
RUN cp /etc/contrail/supervisord_openstack_files/* /etc/contrail/supervisord_config_files/
RUN cp /etc/contrail/supervisord_control_files/* /etc/contrail/supervisord_config_files/
RUN cp /etc/contrail/supervisord_webui_files/* /etc/contrail/supervisord_config_files/
RUN cp /etc/contrail/supervisord_analytics_files/* /etc/contrail/supervisord_config_files/
ADD rabbitmq.sh /etc/init/rabbitmq.sh
ADD supervisord-rabbitmq.ini /etc/contrail/supervisord_config_files/rabbitmq-server.ini
ADD supervisord-zookeeper.ini /etc/contrail/supervisord_config_files/supervisord-zookeeper.ini
ADD supervisord-cassandra.ini /etc/contrail/supervisord_config_files/supervisord-cassandra.ini
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes fabric openssh-server
ADD supervisord-sshd.ini /etc/contrail/supervisord_config_files/supervisord-sshd.ini
RUN mkdir -p /var/run/sshd

#ADD temp-key.pub /root/.ssh/authorized_keys

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes fabric contrail-fabric-utils

ENTRYPOINT /usr/bin/supervisord --nodaemon -c /etc/contrail/supervisord_config.conf
