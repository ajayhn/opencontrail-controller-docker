FROM ubuntu:14.04
ADD add-opencontrail-apt.sh /root/add-opencontrail-apt.sh
RUN /root/add-opencontrail-apt.sh
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-database
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-config default-jre sysv-rc
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-control
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-analytics
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes contrail-openstack-webui nodejs=0.8.15-1contrail1
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes fabric contrail-fabric-utils
