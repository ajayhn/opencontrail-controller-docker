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
RUN cd /etc/init.d && sed -i 's/9010/9004/' *
RUN cd /etc/init.d && sed -i 's/9003/9004/' *
RUN cd /etc/init.d && sed -i 's/9002/9004/' *
RUN cd /etc/init.d && sed -i 's/9007/9004/' *
RUN cd /etc/init.d && sed -i 's/9008/9004/' *
RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9010/9004/' *
RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9003/9004/' *
RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9002/9004/' *
RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9007/9004/' *
RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9008/9004/' *
ADD rabbitmq.sh /etc/init/rabbitmq.sh
ADD supervisord-rabbitmq.ini /etc/contrail/supervisord_config_files/rabbitmq-server.ini
ADD supervisord-zookeeper.ini /etc/contrail/supervisord_config_files/supervisord-zookeeper.ini
ADD supervisord-cassandra.ini /etc/contrail/supervisord_config_files/supervisord-cassandra.ini
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes fabric openssh-server
ADD supervisord-sshd.ini /etc/contrail/supervisord_config_files/supervisord-sshd.ini
RUN mkdir -p /var/run/sshd

ADD temp-key.pub /root/.ssh/authorized_keys

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes fabric contrail-fabric-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes strace lsof

# temporary fixups (later in prov)
RUN sed -i 's/-Xss180k/-Xss280k/' /etc/cassandra/cassandra-env.sh
RUN sed -i 's/self.setup_crashkernel_params()/pass/' /opt/contrail/contrail_installer/contrail_setup_utils/setup.py
ADD dummy-database-server-setup.sh /opt/contrail/contrail_installer/contrail_setup_utils/database-server-setup.sh
RUN sed -i "s/execute('add_openstack_reserverd_ports')//" /opt/contrail/utils/fabfile/tasks/provision.py

# workaround till 5903 is in https://github.com/docker/docker/pull/5903
RUN sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd

#ENTRYPOINT /usr/bin/supervisord --nodaemon -c /etc/contrail/supervisord_config.conf
ONBUILD RUN ssh-keygen -t rsa -f /root/.ssh/id_rsa
ONBUILD RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
ONBUILD ADD testbed.py /opt/contrail/utils/fabfile/testbeds/testbed.py
#ONBUILD RUN cd /opt/contrail/utils && /usr/sbin/sshd && fab setup_database
#ONBUILD ENTRYPOINT /usr/bin/supervisord --nodaemon -c /etc/contrail/supervisord_config.conf
