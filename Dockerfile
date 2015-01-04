FROM ubuntu:14.04
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
#RUN cp /etc/contrail/supervisord_openstack_files/* /etc/contrail/supervisord_config_files/
#RUN cp /etc/contrail/supervisord_control_files/* /etc/contrail/supervisord_config_files/
#RUN cp /etc/contrail/supervisord_webui_files/* /etc/contrail/supervisord_config_files/
#RUN cp /etc/contrail/supervisord_analytics_files/* /etc/contrail/supervisord_config_files/
#RUN cd /etc/init.d && sed -i 's/9010/9004/' *
#RUN cd /etc/init.d && sed -i 's/9003/9004/' *
#RUN cd /etc/init.d && sed -i 's/9002/9004/' *
#RUN cd /etc/init.d && sed -i 's/9007/9004/' *
#RUN cd /etc/init.d && sed -i 's/9008/9004/' *
#RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9010/9004/' *
#RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9003/9004/' *
#RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9002/9004/' *
#RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9007/9004/' *
#RUN cd /opt/contrail/contrail_installer/contrail_setup_utils/ && sed -i 's/9008/9004/' *

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
#RUN sed -i 's/-Xss180k/-Xss280k/' /etc/cassandra/cassandra-env.sh
#RUN sed -i 's/self.setup_crashkernel_params()/pass/' /opt/contrail/contrail_installer/contrail_setup_utils/setup.py
RUN sed -i 's/self.setup_crashkernel_params()/pass/' /usr/local/lib/python2.7/dist-packages/contrail_provisioning/common/base.py
ADD dummy-database-server-setup.sh /opt/contrail/contrail_installer/contrail_setup_utils/database-server-setup.sh
RUN sed -i "s/execute('add_openstack_reserverd_ports')//" /opt/contrail/utils/fabfile/tasks/provision.py
RUN sed -i "s/nova.conf DEFAULT osapi_compute_workers 40/nova.conf DEFAULT osapi_compute_workers 1/" /usr/bin/nova-server-setup.sh
RUN sed -i "s/nova.conf conductor workers 40/nova.conf conductor workers 1/" /usr/bin/nova-server-setup.sh

## workaround till 5903 is in https://github.com/docker/docker/pull/5903
RUN sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd

##ENTRYPOINT /usr/bin/supervisord --nodaemon -c /etc/contrail/supervisord_config.conf
#ONBUILD RUN ssh-keygen -t rsa -f /root/.ssh/id_rsa
#ONBUILD RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
#ONBUILD ADD testbed.py /opt/contrail/utils/fabfile/testbeds/testbed.py
##ONBUILD RUN cd /opt/contrail/utils && /usr/sbin/sshd && fab setup_database
###ONBUILD ENTRYPOINT /usr/bin/supervisord --nodaemon -c /etc/contrail/supervisord_config.conf

ADD service-supervisor-support-service /etc/init.d/supervisor-support-service
ADD service-supervisor-config /etc/init.d/supervisor-config
ADD service-neutron-server /etc/init.d/neutron-server
ADD service-supervisor-database /etc/init.d/supervisor-database
ADD service-zookeeper /etc/init.d/zookeeper
ADD service-supervisor-openstack /etc/init.d/supervisor-openstack
ADD service-supervisor-control /etc/init.d/supervisor-control

ADD supervisord-neutron-server.ini /etc/contrail/supervisord_config_files/supervisord-neutron-server.ini

ADD testbed_singlebox_example.py /opt/contrail/utils/fabfile/testbeds/testbed.py

# temporary ***DO NOT PUBLISH IMAGE WITH THIS*** 
ADD temp-key /root/.ssh/id_rsa

RUN /usr/bin/supervisord -c /etc/contrail/supervisord_support_service.conf && \
    /usr/sbin/sshd && \
    cd /opt/contrail/utils && fab setup_rabbitmq_cluster -i /root/.ssh/id_rsa
RUN /usr/bin/supervisord -c /etc/contrail/supervisord_database.conf && \
    /usr/sbin/sshd && \
    cd /opt/contrail/utils && fab setup_database -i /root/.ssh/id_rsa
RUN /usr/bin/supervisord -c /etc/contrail/supervisord_openstack.conf && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_support_service.conf && \
    /usr/sbin/sshd && \
    cd /opt/contrail/utils && fab setup_orchestrator -i /root/.ssh/id_rsa
RUN /usr/bin/supervisord -c /etc/contrail/supervisord_config.conf && \
    service mysql start && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_openstack.conf && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_support_service.conf && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_database.conf && \
    /usr/sbin/sshd && \
    cd /opt/contrail/utils && fab setup_cfgm -i /root/.ssh/id_rsa

# Till recursive serve at any is removed from bind
RUN rm /etc/contrail/supervisord_control_files/contrail-named.ini
RUN rm /etc/contrail/supervisord_control_files/contrail-dns.ini
RUN /usr/bin/supervisord -c /etc/contrail/supervisord_control.conf && \
    service mysql start && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_openstack.conf && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_config.conf && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_support_service.conf && \
    /usr/bin/supervisord -c /etc/contrail/supervisord_database.conf && \
    /usr/sbin/sshd && \
    cd /opt/contrail/utils && fab setup_control -i /root/.ssh/id_rsa

RUN locale-gen en_US.UTF-8

ADD pre-start-fixups.sh /etc/contrail/pre-start-fixups.sh
ENTRYPOINT /etc/contrail/pre-start-fixups.sh && \
           service haproxy start && \
           service mysql start && \
           service memcached start && \
           /usr/bin/supervisord -c /etc/contrail/supervisord_openstack.conf && \
           /usr/bin/supervisord -c /etc/contrail/supervisord_support_service.conf && \
           /usr/bin/supervisord -c /etc/contrail/supervisord_config.conf && \
           /usr/bin/supervisord -c /etc/contrail/supervisord_database.conf && \
           tail -f /dev/null
